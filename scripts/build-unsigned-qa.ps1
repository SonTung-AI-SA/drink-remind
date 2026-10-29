# Compilation check only: no production config, signing, upload or publishing.
$ErrorActionPreference='Stop'
$projectRoot=Split-Path -Parent $PSScriptRoot
Push-Location "$projectRoot/apps/mobile"
try {
  # Flutter regenerates the release registrant, excluding dev-only plugins.
  & "$projectRoot/.tools/flutter/bin/flutter.bat" build appbundle --release --target-platform android-arm64 --android-project-arg=allowUnsignedRelease=true
  if($LASTEXITCODE -ne 0){throw 'Unsigned QA compilation failed.'}
  $qa=Join-Path $projectRoot '.tools/android-run'
  New-Item -ItemType Directory -Force -Path $qa | Out-Null
  Copy-Item -LiteralPath build/app/outputs/bundle/release/app-release.aab -Destination "$qa/little-island-UNSIGNED-QA.aab"
  $archive=[IO.Compression.ZipFile]::OpenRead("$qa/little-island-UNSIGNED-QA.aab")
  try {
    if(@($archive.Entries | Where-Object {$_.FullName -match '^META-INF/.*\.(RSA|DSA|EC|SF)$'}).Count -gt 0){throw 'QA artifact unexpectedly contains a signature.'}
  } finally {$archive.Dispose()}
  Write-Output 'Đã biên dịch AAB unsigned cho QA; không có cấu hình production và không dùng để phát hành.'
} finally {
  Pop-Location
}
