param([ValidateSet('closed','reboot','timezone')][string]$Mode='closed',[string]$Device='emulator-5554',[switch]$SkipBuild)
$ErrorActionPreference='Stop'
if($Device -notmatch '^emulator-\d+$'){throw 'Chỉ chạy probe trên Android emulator dành cho kiểm thử.'}
$projectRoot=Split-Path -Parent $PSScriptRoot
$sdk=if($env:ANDROID_HOME){$env:ANDROID_HOME}else{Join-Path $env:LOCALAPPDATA 'Android/Sdk'}
$adb=Join-Path $sdk 'platform-tools/adb.exe'
$package='com.littleisland.little_island'
$qa=Join-Path $projectRoot '.tools/android-run'
New-Item -ItemType Directory -Force -Path $qa | Out-Null
$oldZone=(& $adb -s $Device shell getprop persist.sys.timezone).Trim()
$oldAutoZone=(& $adb -s $Device shell settings get global auto_time_zone).Trim()
Push-Location "$projectRoot/apps/mobile"
try {
  if(-not $SkipBuild){
    & "$projectRoot/.tools/flutter/bin/flutter.bat" build apk --debug --target-platform android-x64 --target integration_test/notification_probe.dart "--dart-define=PROBE_MODE=$Mode" *> "$qa/probe-build-$Mode.log"
    if($LASTEXITCODE -ne 0){throw "Probe build failed: $qa/probe-build-$Mode.log"}
  }
  & $adb -s $Device install -r -g build/app/outputs/flutter-apk/app-debug.apk | Out-Null
  if($LASTEXITCODE -ne 0){throw 'Probe install failed'}
  & $adb -s $Device logcat -c
  & $adb -s $Device shell am force-stop $package
  & $adb -s $Device shell am start -n "$package/.MainActivity" | Out-Null
  $ready=$false
  for($i=0;$i -lt 40;$i++){
    $log=(& $adb -s $Device logcat -d -s flutter) -join "`n"
    if($log.Contains("MIZU_PROBE_READY mode=$Mode")){$ready=$true;break}
    Start-Sleep -Seconds 1
  }
  if(-not $ready){throw 'Probe did not become ready'}
  & $adb -s $Device shell am start -a android.intent.action.MAIN -c android.intent.category.HOME | Out-Null
  Start-Sleep -Seconds 2
  & $adb -s $Device shell am kill $package
  Start-Sleep -Seconds 1
  $appPids=(& $adb -s $Device shell pidof $package)
  if($appPids){
    foreach($appPid in ($appPids -split '\s+')){
      if($appPid -match '^\d+$'){ & $adb -s $Device shell run-as $package kill -9 $appPid }
    }
  }
  if((& $adb -s $Device shell pidof $package)){throw 'App process still running; cannot verify closed-app behavior.'}
  if($Mode -eq 'closed'){
    $delivered=$false
    for($i=0;$i -lt 180;$i++){
      $state=(& $adb -s $Device shell dumpsys notification --noredact) -join "`n"
      if($state -match "NotificationRecord\([^\r\n]*pkg=$package[^\r\n]*id=9101"){$delivered=$true;break}
      Start-Sleep -Seconds 1
    }
    if(-not $delivered){throw 'No delivery observed within 3 minutes; inexact alarms can be delayed by Android.'}
    Write-Output 'PASS: notification delivered after app process was closed.'
  } elseif($Mode -eq 'reboot'){
    & $adb -s $Device reboot
    & $adb -s $Device wait-for-device
    $booted=$false
    for($i=0;$i -lt 150;$i++){
      if((& $adb -s $Device shell getprop sys.boot_completed).Trim() -eq '1'){$booted=$true;break}
      Start-Sleep -Seconds 1
    }
    if(-not $booted){throw 'Emulator did not boot in time'}
    $restored=$false
    for($i=0;$i -lt 60;$i++){
      $log=(& $adb -s $Device logcat -d -s MizuReminders) -join "`n"
      $alarms=(& $adb -s $Device shell dumpsys alarm) -join "`n"
      if($log -match 'Restored 1 slots after android.intent.action.BOOT_COMPLETED' -and $alarms -match "RTC_WAKEUP #[0-9]+: Alarm\{[^\r\n]*$package"){$restored=$true;break}
      Start-Sleep -Seconds 1
    }
    if(-not $restored){throw 'Reboot restore was not observed'}
    Write-Output 'PASS: boot receiver restored pending alarm without opening app.'
  } else {
    & $adb -s $Device shell settings put global auto_time_zone 0
    $target=if($oldZone -eq 'Asia/Tokyo'){'Asia/Bangkok'}else{'Asia/Tokyo'}
    & $adb -s $Device shell cmd alarm set-timezone $target
    $restored=$false
    for($i=0;$i -lt 60;$i++){
      $log=(& $adb -s $Device logcat -d -s MizuReminders) -join "`n"
      [xml]$cache=(& $adb -s $Device shell run-as $package cat shared_prefs/scheduled_notifications.xml) -join "`n"
      $items=($cache.map.string.'#text') | ConvertFrom-Json
      if($log -match "TIMEZONE_CHANGED in $target" -and @($items | Where-Object {$_.timeZoneName -eq $target}).Count -eq 1){$restored=$true;break}
      Start-Sleep -Seconds 1
    }
    if(-not $restored){throw 'Timezone reschedule was not observed'}
    Write-Output 'PASS: timezone change restored wall-clock reminder and updated cached timezone.'
  }
  $log=(& $adb -s $Device logcat -d -s MizuReminders flutter) -join "`n"
  Set-Content -LiteralPath "$qa/probe-$Mode.log" -Value $log
} finally {
  if($Mode -eq 'timezone'){
    & $adb -s $Device shell cmd alarm set-timezone $oldZone | Out-Null
    if($oldAutoZone -eq 'null'){ & $adb -s $Device shell settings delete global auto_time_zone | Out-Null }
    else { & $adb -s $Device shell settings put global auto_time_zone $oldAutoZone | Out-Null }
  }
  Pop-Location
}
