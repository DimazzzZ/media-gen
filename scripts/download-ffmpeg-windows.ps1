# Fast FFmpeg download script for Windows
# Optimized for GitHub Actions Windows runners

param(
    [string]$OutputDir = "src\vendor\ffmpeg\windows-x64",
    [switch]$Force
)

$ErrorActionPreference = "Stop"

Write-Host "[START] Fast FFmpeg download for Windows starting..." -ForegroundColor Green

# Create output directory
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

# Check if FFmpeg already exists
$ffmpegPath = Join-Path $OutputDir "ffmpeg.exe"
if ((Test-Path $ffmpegPath) -and -not $Force) {
    $fileSize = (Get-Item $ffmpegPath).Length
    Write-Host "[OK] FFmpeg already exists ($([math]::Round($fileSize / 1MB, 2)) MB)" -ForegroundColor Green
    exit 0
}

try {
    # Use faster download method
    $url = "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip"
    $tempZip = Join-Path $env:TEMP "ffmpeg-win64-fast.zip"
    $tempExtract = Join-Path $env:TEMP "ffmpeg-extract-fast"
    
    Write-Host "[DOWNLOAD] Downloading FFmpeg from GitHub releases..." -ForegroundColor Yellow
    
    # Use .NET WebClient for faster download
    $webClient = New-Object System.Net.WebClient
    $webClient.Headers.Add("User-Agent", "GitHub-Actions-FFmpeg-Downloader")
    
    # Download with progress
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $webClient.DownloadFile($url, $tempZip)
    $stopwatch.Stop()
    
    $downloadTime = $stopwatch.Elapsed.TotalSeconds
    $fileSize = (Get-Item $tempZip).Length
    Write-Host "[DOWN] Downloaded $([math]::Round($fileSize / 1MB, 2)) MB in $([math]::Round($downloadTime, 2))s" -ForegroundColor Green
    
    # Fast extraction
    Write-Host "[EXTRACT] Extracting archive..." -ForegroundColor Yellow
    $extractStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($tempZip, $tempExtract)
    
    $extractStopwatch.Stop()
    Write-Host "[FOLDER] Extracted in $([math]::Round($extractStopwatch.Elapsed.TotalSeconds, 2))s" -ForegroundColor Green
    
    # Find FFmpeg executable efficiently
    Write-Host "[SEARCH] Locating FFmpeg executable..." -ForegroundColor Yellow
    $ffmpegExe = Get-ChildItem -Path $tempExtract -Name "ffmpeg.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    
    if (-not $ffmpegExe) {
        throw "FFmpeg executable not found in archive"
    }
    
    $sourcePath = Get-ChildItem -Path $tempExtract -Filter "ffmpeg.exe" -Recurse | Select-Object -First 1
    
    # Copy with verification
    Copy-Item $sourcePath.FullName $ffmpegPath -Force
    
    # Verify the copy
    if (Test-Path $ffmpegPath) {
        $finalSize = (Get-Item $ffmpegPath).Length
        Write-Host "[OK] FFmpeg ready: $([math]::Round($finalSize / 1MB, 2)) MB" -ForegroundColor Green
        
        # Test FFmpeg
        Write-Host "[TEST] Testing FFmpeg..." -ForegroundColor Yellow
        $testOutput = & $ffmpegPath -version 2>&1 | Select-Object -First 1
        if ($testOutput -match "ffmpeg version") {
            Write-Host "[OK] FFmpeg test passed: $testOutput" -ForegroundColor Green
        } else {
            Write-Warning "[WARNING] FFmpeg test inconclusive"
        }
    } else {
        throw "Failed to copy FFmpeg executable"
    }
    
} catch {
    Write-Error "[ERROR] FFmpeg download failed: $($_.Exception.Message)"
    exit 1
} finally {
    # Cleanup
    if (Test-Path $tempZip) { Remove-Item $tempZip -Force -ErrorAction SilentlyContinue }
    if (Test-Path $tempExtract) { Remove-Item $tempExtract -Recurse -Force -ErrorAction SilentlyContinue }
}

Write-Host "[SUCCESS] FFmpeg download completed successfully!" -ForegroundColor Green