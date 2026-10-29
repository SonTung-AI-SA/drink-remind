param(
  [string]$Device='emulator-5554',
  [ValidateSet('android','web','ios')][string]$Platform='android',
  [string]$OAuthProviders='',
  [switch]$LocalAuth,
  [switch]$BuildOnly
)
$ErrorActionPreference='Stop'
$projectRoot=Split-Path -Parent $PSScriptRoot
$raw=& "$projectRoot/.tools/supabase/supabase.exe" --workdir $projectRoot status --output json 2>$null
if($LASTEXITCODE -ne 0){throw 'Chạy scripts/backend.ps1 Start trước.'}
$status=$raw|ConvertFrom-Json
$api=if($Platform -eq 'android'){'http://10.0.2.2:15421'}else{$status.API_URL}
$configPath=Join-Path $projectRoot ".tools/supabase/mobile-$Platform.json"
# Only public client configuration. Never copy service-role/signing secrets into an app.
@{SUPABASE_URL=$api;SUPABASE_ANON_KEY=$status.ANON_KEY;OAUTH_PROVIDERS=$OAuthProviders;ALLOW_LOCAL_AUTH=[bool]$LocalAuth} |
  ConvertTo-Json | Set-Content -LiteralPath $configPath -Encoding utf8
Push-Location "$projectRoot/apps/mobile"
try {
  if($BuildOnly){
    if($Platform -eq 'android'){
      & "$projectRoot/.tools/flutter/bin/flutter.bat" build apk --debug --target-platform android-x64 "--dart-define-from-file=$configPath"
    } elseif($Platform -eq 'web'){
      & "$projectRoot/.tools/flutter/bin/flutter.bat" build web --release "--dart-define-from-file=$configPath"
    } else {throw 'Build iOS cần macOS/Xcode.'}
  } else {
    & "$projectRoot/.tools/flutter/bin/flutter.bat" run -d $Device "--dart-define-from-file=$configPath"
  }
  if($LASTEXITCODE -ne 0){throw 'Flutter build/run failed.'}
} finally {Pop-Location}
