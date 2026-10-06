$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing

$projectRoot = Split-Path -Parent $PSScriptRoot
$sourcePath = Join-Path $projectRoot 'assets\icons\app_icon.png'

if (-not (Test-Path $sourcePath)) {
    throw "Missing source icon: $sourcePath"
}

# Remove old adaptive-icon resources so Android uses the complete launcher artwork.
$adaptiveXml = Join-Path $projectRoot 'android\app\src\main\res\mipmap-anydpi-v26\ic_launcher.xml'
$adaptiveRoundXml = Join-Path $projectRoot 'android\app\src\main\res\mipmap-anydpi-v26\ic_launcher_round.xml'
$oldForeground = Join-Path $projectRoot 'android\app\src\main\res\drawable\ic_launcher_foreground.png'

Remove-Item $adaptiveXml -Force -ErrorAction SilentlyContinue
Remove-Item $adaptiveRoundXml -Force -ErrorAction SilentlyContinue
Remove-Item $oldForeground -Force -ErrorAction SilentlyContinue

$sizes = [ordered]@{
    'mipmap-mdpi' = 48
    'mipmap-hdpi' = 72
    'mipmap-xhdpi' = 96
    'mipmap-xxhdpi' = 144
    'mipmap-xxxhdpi' = 192
}

$source = [System.Drawing.Image]::FromFile($sourcePath)

try {
    foreach ($entry in $sizes.GetEnumerator()) {
        $folder = Join-Path $projectRoot ('android\app\src\main\res\' + $entry.Key)
        New-Item -ItemType Directory -Path $folder -Force | Out-Null

        $size = [int]$entry.Value
        $bitmap = [System.Drawing.Bitmap]::new(
            $size,
            $size,
            [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
        )

        try {
            $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
            try {
                $graphics.Clear([System.Drawing.Color]::Transparent)
                $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
                $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
                $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
                $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
                $graphics.DrawImage($source, 0, 0, $size, $size)
            }
            finally {
                $graphics.Dispose()
            }

            $outputPath = Join-Path $folder 'ic_launcher.png'
            $bitmap.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
            Write-Host "Generated $outputPath ($size x $size)"
        }
        finally {
            $bitmap.Dispose()
        }
    }
}
finally {
    $source.Dispose()
}

Write-Host ''
Write-Host 'Launcher icons rebuilt successfully as standard 32-bit PNG files.'
