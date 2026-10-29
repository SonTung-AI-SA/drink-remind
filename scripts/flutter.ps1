param(
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$FlutterArguments
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$localFlutter = Join-Path $projectRoot '.tools/flutter/bin/flutter.bat'
if (-not (Test-Path -LiteralPath $localFlutter)) {
  $flutterCommand = Get-Command flutter -ErrorAction SilentlyContinue
  if (-not $flutterCommand) { throw 'Cần Flutter SDK. Xem apps/mobile/README.md.' }
  $localFlutter = $flutterCommand.Source
}
Push-Location (Join-Path $projectRoot 'apps/mobile')
try {
  & $localFlutter @FlutterArguments
  exit $LASTEXITCODE
} finally { Pop-Location }
