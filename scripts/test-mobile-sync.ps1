$ErrorActionPreference='Stop'
$projectRoot=Split-Path -Parent $PSScriptRoot
$raw=& "$projectRoot/.tools/supabase/supabase.exe" --workdir $projectRoot status --output json 2>$null
if($LASTEXITCODE -ne 0){throw 'Supabase local chưa chạy.'}
$status=$raw | ConvertFrom-Json
$configPath=Join-Path $projectRoot '.tools/supabase/mobile-test.json'
@{SUPABASE_URL=$status.API_URL;SUPABASE_ANON_KEY=$status.ANON_KEY} | ConvertTo-Json | Set-Content -LiteralPath $configPath -Encoding utf8
$previousKey=$env:MIZU_TEST_SERVICE_KEY
try {
  $env:MIZU_TEST_SERVICE_KEY=$status.SERVICE_ROLE_KEY
  Push-Location "$projectRoot/apps/mobile"
  & "$projectRoot/.tools/flutter/bin/flutter.bat" test test/sync_integration_test.dart "--dart-define-from-file=$configPath" --reporter expanded
  if($LASTEXITCODE -ne 0){throw 'Mobile sync integration checks failed.'}
} finally {
  Pop-Location
  $env:MIZU_TEST_SERVICE_KEY=$previousKey
}
