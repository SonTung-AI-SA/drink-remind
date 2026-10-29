param([ValidateSet('Start','Stop','Status','Test','Migrate')][string]$Action='Status')
$ErrorActionPreference='Stop'
$projectRoot=Split-Path -Parent $PSScriptRoot
$cli=Join-Path $projectRoot '.tools/supabase/supabase.exe'
$runtime=Join-Path $projectRoot '.tools/supabase'
if(-not(Test-Path -LiteralPath $cli)){throw 'Chưa có Supabase CLI. Xem supabase/README.md để tải bản đã pin.'}
Push-Location $projectRoot
try {
  switch($Action){
    'Start' {
      docker info --format '{{.ServerVersion}}' | Out-Null
      if($LASTEXITCODE -ne 0){throw 'Cần bật Docker Desktop Linux engine.'}
      docker network inspect little-island-local *> $null
      if($LASTEXITCODE -ne 0){
        docker network create -o 'com.docker.network.bridge.host_binding_ipv4=127.0.0.1' little-island-local | Out-Null
        if($LASTEXITCODE -ne 0){throw 'Không tạo được network dự án.'}
      }
      & $cli start --network-id little-island-local -x realtime,storage-api,imgproxy,edge-runtime,logflare,vector,supavisor *> "$runtime/start.log"
      if($LASTEXITCODE -ne 0){throw "Không khởi động được. Xem $runtime/start.log (có thể chứa credential local, không chia sẻ)."}
      Write-Output 'Supabase local đã chạy.'
    }
    'Stop' {
      & $cli stop *> "$runtime/stop.log"
      if($LASTEXITCODE -ne 0){throw 'Không dừng được Supabase. Xem .tools/supabase/stop.log.'}
      Write-Output 'Đã dừng Supabase, giữ dữ liệu. Không dùng --no-backup nếu cần giữ dữ liệu.'
    }
    'Migrate' {
      & $cli migration up --local
      if($LASTEXITCODE -ne 0){throw 'Migration thất bại.'}
    }
    'Test' {
      Get-Content -Raw supabase/tests/backend.sql | docker exec -i supabase_db_drink-water-remind psql -X -v ON_ERROR_STOP=1 -U postgres -d postgres
      if($LASTEXITCODE -ne 0){throw 'Backend integration checks failed.'}
      Get-Content -Raw supabase/tests/settings-sync.sql | docker exec -i supabase_db_drink-water-remind psql -X -v ON_ERROR_STOP=1 -U postgres -d postgres
      if($LASTEXITCODE -ne 0){throw 'Settings sync integration checks failed.'}
    }
  }
  if($Action -in @('Start','Status')){
    & $cli status --output json 2> "$runtime/status-stderr.log" | Set-Content "$runtime/status.json" -Encoding utf8
    if($LASTEXITCODE -ne 0){throw 'Backend chưa chạy. Dùng ./scripts/backend.ps1 Start.'}
    $status=Get-Content -Raw "$runtime/status.json" | ConvertFrom-Json
    [pscustomobject]@{API=$status.API_URL;Studio=$status.STUDIO_URL;EmailTest=$status.MAILPIT_URL;DatabasePort=15422}
  }
} finally {Pop-Location}
