param([string]$ConfigPath='apps/mobile/release-config.json',[switch]$ValidateOnly)
$ErrorActionPreference='Stop'
$projectRoot=Split-Path -Parent $PSScriptRoot
$resolvedConfig=if([IO.Path]::IsPathRooted($ConfigPath)){$ConfigPath}else{Join-Path $projectRoot $ConfigPath}
$issues=[Collections.Generic.List[string]]::new()
if(-not(Test-Path -LiteralPath $resolvedConfig)){$issues.Add('Thiếu release-config.json: sao chép release-config.example.json và điền cấu hình thật.')}
else {
  $config=Get-Content -Raw -LiteralPath $resolvedConfig | ConvertFrom-Json
  foreach($name in @('SUPABASE_URL','PRIVACY_URL','TERMS_URL','DELETION_URL')){
    $uri=$null
    if(-not [Uri]::TryCreate([string]$config.$name,[UriKind]::Absolute,[ref]$uri) -or $uri.Scheme -ne 'https' -or $uri.Host -match 'example|localhost|127\.0\.0\.1'){$issues.Add("$name cần URL HTTPS production thật.")}
  }
  if(-not $config.SUPABASE_ANON_KEY -or $config.SUPABASE_ANON_KEY -match 'PUBLIC_|REPLACE'){$issues.Add('Thiếu public client key production.')}
  if(-not $config.PUBLISHER_NAME -or $config.PUBLISHER_NAME -match 'REPLACE'){$issues.Add('Thiếu tên đơn vị phát hành.')}
  if(-not $config.SUPPORT_EMAIL -or $config.SUPPORT_EMAIL -match 'YOUR-|example'){$issues.Add('Thiếu email hỗ trợ thật.')}
  if($config.ALLOW_LOCAL_AUTH -eq $true){$issues.Add('ALLOW_LOCAL_AUTH phải false cho release.')}
}
$signing=Join-Path $projectRoot 'apps/mobile/android/key.properties'
if(-not(Test-Path -LiteralPath $signing)){$issues.Add('Thiếu signing Android: android/key.properties và upload keystore của chủ dự án.')}
# Release gates reflect actual unimplemented scope, not values that can be bypassed in config.
$issues.Add('Chưa triển khai xóa tài khoản trong app theo phạm vi đã chốt; cần hoàn tất trước khi phát hành app có tài khoản.')
$issues.Add('Cần nghiệm thu OAuth thật, thiết bị thật, chính sách có chủ thể vận hành và iOS trên macOS/Xcode.')
if($issues.Count -gt 0){
  Write-Output 'Chưa đủ điều kiện phát hành:'
  foreach($issue in $issues){Write-Output "- $issue"}
  if($ValidateOnly){return}
  throw 'Release chưa được duyệt. Xem document/release-checklist.md.'
}
Push-Location "$projectRoot/apps/mobile"
try {
  & "$projectRoot/.tools/flutter/bin/flutter.bat" build appbundle --release "--dart-define-from-file=$resolvedConfig"
  if($LASTEXITCODE -ne 0){throw 'Release build failed.'}
} finally {Pop-Location}
