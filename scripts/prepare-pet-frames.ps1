$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$root = Split-Path -Parent $PSScriptRoot
$cuts = @{ 'nemo' = @(0,355,710,1024); 'corgi' = @(0,375,725,1024); 'meo-cam' = @(0,370,715,1024) }
foreach ($pet in @('nemo','corgi','meo-cam')) {
  $source = [System.Drawing.Bitmap]::new((Join-Path $root "assets/pets/storyboard-v1/$pet-keyposes.png"))
  $out = Join-Path $root "apps/mobile/assets/pets/storyboard-v1/$pet"
  New-Item -ItemType Directory -Path $out -Force | Out-Null
  $bounds = @()
  $ys = @(0,384,744,1110,1536)
  for ($row=0; $row -lt 4; $row++) {
    for ($col=0; $col -lt 3; $col++) {
      $minX=$cuts[$pet][$col+1]; $maxX=0; $minY=$ys[$row+1]; $maxY=0
      for ($y=$ys[$row]; $y -lt $ys[$row+1]; $y++) {
        for ($x=$cuts[$pet][$col]; $x -lt $cuts[$pet][$col+1]; $x++) {
          if ($source.GetPixel($x,$y).A -gt 16) {
            $minX=[Math]::Min($minX,$x); $maxX=[Math]::Max($maxX,$x)
            $minY=[Math]::Min($minY,$y); $maxY=[Math]::Max($maxY,$y)
          }
        }
      }
      $bounds += [System.Drawing.Rectangle]::new($minX,$minY,$maxX-$minX+1,$maxY-$minY+1)
    }
  }
  $largest = ($bounds | ForEach-Object { [Math]::Max($_.Width,$_.Height) } | Measure-Object -Maximum).Maximum
  $scale = 450.0 / $largest
  for ($i=0; $i -lt 12; $i++) {
    $frame = [System.Drawing.Bitmap]::new(512,512,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($frame)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $b=$bounds[$i]; $w=[int]($b.Width*$scale); $h=[int]($b.Height*$scale)
    $dest=[System.Drawing.Rectangle]::new([int]((512-$w)/2),480-$h,$w,$h)
    $g.DrawImage($source,$dest,$b,[System.Drawing.GraphicsUnit]::Pixel)
    $frame.Save((Join-Path $out "$i.png"),[System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $frame.Dispose()
  }
  $source.Dispose()
  Write-Output "$pet : 12 frames prepared"
}
