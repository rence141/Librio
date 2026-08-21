# Transfer GGUF models to Infinix-Note50 via ADB
# Usage: .\transfer_models.ps1

param(
    [string]$DeviceId = "adb-138097055K002303-DxquAm._adb-tls-connect._tcp",
    [string]$ModelsDir = "C:\dev\Librio\bench\models",
    [string]$DeviceDir = "/data/user/0/com.librio.librio/app_flutter/models"
)

# ADB path
$adbPath = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"

if (-not (Test-Path $adbPath)) {
    Write-Error "ADB not found at $adbPath"
    exit 1
}

Write-Host "=== Librio Model Transfer Script ===" -ForegroundColor Cyan
Write-Host "Device: $DeviceId"
Write-Host "Local models: $ModelsDir"
Write-Host "Device target: $DeviceDir"
Write-Host ""

# Check if device is connected
Write-Host "Checking device connection..." -ForegroundColor Yellow
$devices = & $adbPath devices
if ($devices -notmatch $DeviceId) {
    Write-Error "Device not found. Available devices:"
    Write-Host $devices
    exit 1
}
Write-Host "✓ Device connected" -ForegroundColor Green

# Check if models directory exists
if (-not (Test-Path $ModelsDir)) {
    Write-Error "Models directory not found: $ModelsDir"
    exit 1
}

# Get list of GGUF files
$models = Get-ChildItem -Path $ModelsDir -Filter "*.gguf" -ErrorAction SilentlyContinue
if ($models.Count -eq 0) {
    Write-Error "No GGUF files found in $ModelsDir"
    exit 1
}

Write-Host "Found $($models.Count) model(s):" -ForegroundColor Yellow
$models | ForEach-Object { Write-Host "  - $($_.Name) ($([math]::Round($_.Length / 1MB, 2)) MB)" }
Write-Host ""

# Create device directory
Write-Host "Creating device directory..." -ForegroundColor Yellow
& $adbPath -s $DeviceId shell mkdir -p $DeviceDir
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to create device directory"
    exit 1
}
Write-Host "✓ Directory created" -ForegroundColor Green

# Transfer each model
$totalSize = 0
$models | ForEach-Object {
    $modelName = $_.Name
    $modelPath = $_.FullName
    $modelSize = $_.Length
    $totalSize += $modelSize
    $sizeMB = [math]::Round($modelSize / 1MB, 2)
    
    Write-Host ""
    Write-Host "Transferring: $modelName ($sizeMB MB)" -ForegroundColor Cyan
    
    $startTime = Get-Date
    & $adbPath -s $DeviceId push $modelPath "$DeviceDir/$modelName"
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to transfer $modelName"
        exit 1
    }
    
    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalSeconds
    $speed = [math]::Round($modelSize / 1MB / $duration, 2)
    
    Write-Host "✓ Transferred: $modelName ($speed MB/s)" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== Transfer Complete ===" -ForegroundColor Green
Write-Host "Total transferred: $([math]::Round($totalSize / 1MB, 2)) MB"
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Open the Librio app on your phone"
Write-Host "2. Go to the Benchmark screen"
Write-Host "3. Tap 'Start Benchmark'"
Write-Host "4. Watch the logs as it loads and runs inference on the models"
Write-Host ""
