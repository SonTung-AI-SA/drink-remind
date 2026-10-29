$ErrorActionPreference='Stop'
$projectRoot=Split-Path -Parent $PSScriptRoot
$cli=Join-Path $projectRoot '.tools/supabase/supabase.exe'
$raw=& $cli --workdir $projectRoot status --output json 2>$null
if($LASTEXITCODE -ne 0){throw 'Backend chưa chạy.'}
$status=$raw | ConvertFrom-Json
$api=$status.API_URL
$publicHeaders=@{apikey=$status.ANON_KEY}
$health=Invoke-WebRequest "$api/auth/v1/health" -Headers $publicHeaders -TimeoutSec 15
$studio=Invoke-WebRequest $status.STUDIO_URL -TimeoutSec 20
if($health.StatusCode -ne 200 -or $studio.StatusCode -ne 200){throw 'Health check failed'}
$testEmail="backend-test-$([guid]::NewGuid().ToString('N'))@example.invalid"
$testPassword=[guid]::NewGuid().ToString('N')+'aB!9'
$userId=$null
try {
  $signup=Invoke-RestMethod "$api/auth/v1/signup" -Method Post -Headers $publicHeaders -ContentType 'application/json' -Body (@{email=$testEmail;password=$testPassword}|ConvertTo-Json)
  $userId=$signup.user.id
  if(-not $signup.access_token -or -not $userId){throw 'Local test signup did not return a session.'}
  $userHeaders=@{apikey=$status.ANON_KEY;Authorization="Bearer $($signup.access_token)"}
  $profiles=Invoke-RestMethod "$api/rest/v1/profiles?select=user_id" -Headers $userHeaders
  if(@($profiles).Count -ne 1 -or $profiles[0].user_id -ne $userId){throw 'Profile creation or RLS failed.'}
  $intakeId=[guid]::NewGuid().ToString()
  $command=@{p_command_id=[guid]::NewGuid().ToString();p_operation='intake.upsert';p_payload=@{id=$intakeId;amount=250;occurred_at=[DateTime]::UtcNow.ToString('o');local_day='2026-10-28';offset_minutes=420;on_time=$false}}
  $body=$command|ConvertTo-Json -Depth 5
  $first=Invoke-RestMethod "$api/rest/v1/rpc/apply_intake_command" -Method Post -Headers $userHeaders -ContentType 'application/json' -Body $body
  $replay=Invoke-RestMethod "$api/rest/v1/rpc/apply_intake_command" -Method Post -Headers $userHeaders -ContentType 'application/json' -Body $body
  $rows=Invoke-RestMethod "$api/rest/v1/water_intakes?select=id,amount,revision" -Headers $userHeaders
  if(@($rows).Count -ne 1 -or $first.revision -ne 1 -or $replay.revision -ne 1 -or $rows[0].amount -ne 250){throw 'HTTP idempotency failed.'}
  [pscustomobject]@{AuthHealth=$health.StatusCode;Studio=$studio.StatusCode;Signup='passed';ProfileRLS='passed';IntakeRPC='passed';Replay='passed'}
} finally {
  if($userId){
    $adminHeaders=@{apikey=$status.SERVICE_ROLE_KEY;Authorization="Bearer $($status.SERVICE_ROLE_KEY)"}
    Invoke-RestMethod "$api/auth/v1/admin/users/$userId" -Method Delete -Headers $adminHeaders | Out-Null
    Write-Output 'Đã xóa tài khoản kiểm thử và dữ liệu liên quan.'
  }
}
