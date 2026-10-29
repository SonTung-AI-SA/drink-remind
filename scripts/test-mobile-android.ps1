param([string]$Device='emulator-5554')
$ErrorActionPreference='Stop'
if($Device -notmatch '^emulator-\d+$'){throw 'Script này chỉ dành cho Android emulator có dữ liệu thử.'}
$projectRoot=Split-Path -Parent $PSScriptRoot
$raw=& "$projectRoot/.tools/supabase/supabase.exe" --workdir $projectRoot status --output json 2>$null
if($LASTEXITCODE -ne 0){throw 'Supabase local chưa chạy.'}
$status=$raw|ConvertFrom-Json
$headers=@{apikey=$status.SERVICE_ROLE_KEY;Authorization="Bearer $($status.SERVICE_ROLE_KEY)"}
$userId=$null
$configPath=Join-Path $projectRoot '.tools/supabase/android-test.json'
try {
  $email="android-sync-$([guid]::NewGuid().ToString('N'))@example.invalid"
  $password=[guid]::NewGuid().ToString('N')+'aB!9'
  $fixture=Invoke-RestMethod "$($status.API_URL)/auth/v1/admin/users" -Method Post -Headers $headers -ContentType 'application/json' -Body (@{email=$email;password=$password;email_confirm=$true}|ConvertTo-Json)
  $userId=$fixture.id
  @{SUPABASE_URL='http://10.0.2.2:15421';SUPABASE_ANON_KEY=$status.ANON_KEY;ALLOW_LOCAL_AUTH=$true;TEST_EMAIL=$email;TEST_PASSWORD=$password} |
    ConvertTo-Json | Set-Content -LiteralPath $configPath -Encoding utf8
  Push-Location "$projectRoot/apps/mobile"
  try {
    & "$projectRoot/.tools/flutter/bin/flutter.bat" test integration_test/account_sync_test.dart -d $Device "--dart-define-from-file=$configPath" --reporter expanded
    if($LASTEXITCODE -ne 0){throw 'Android account/sync integration failed.'}
  } finally {Pop-Location}
} finally {
  if($userId){Invoke-RestMethod "$($status.API_URL)/auth/v1/admin/users/$userId" -Method Delete -Headers $headers | Out-Null}
  if(Test-Path -LiteralPath $configPath){Remove-Item -LiteralPath $configPath}
  Write-Output 'Đã dọn tài khoản và cấu hình kiểm thử Android.'
}
