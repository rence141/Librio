# Download candidate LLM models for Phase 0 benchmarking
# Models are stored in bench/models/ (not committed to git)
# Usage: .\download_models.ps1 -ModelId gemma3-1b-q4
# Usage: .\download_models.ps1 -All

param(
    [string]$ModelId,
    [switch]$All
)

$ModelsDir = "models"
if (-not (Test-Path $ModelsDir)) {
    New-Item -ItemType Directory -Path $ModelsDir | Out-Null
}

# Model definitions
$Models = @{
    "gemma3-1b-q4"    = "https://huggingface.co/bartowski/Gemma-3-1B-Instruct-GGUF/resolve/main/Gemma-3-1B-Instruct-Q4_K_M.gguf"
    "llama32-1b-q4"   = "https://huggingface.co/bartowski/Llama-3.2-1B-Instruct-GGUF/resolve/main/Llama-3.2-1B-Instruct-Q4_K_M.gguf"
    "smollm3-1.7b-q4" = "https://huggingface.co/bartowski/SmolLM3-1.7B-Instruct-GGUF/resolve/main/SmolLM3-1.7B-Instruct-Q4_K_M.gguf"
    "gemma3-4b-q4"    = "https://huggingface.co/bartowski/Gemma-3-4B-Instruct-GGUF/resolve/main/Gemma-3-4B-Instruct-Q4_K_M.gguf"
    "qwen3-3b-q4"     = "https://huggingface.co/bartowski/Qwen2.5-3B-Instruct-GGUF/resolve/main/Qwen2.5-3B-Instruct-Q4_K_M.gguf"
}

function Download-Model {
    param([string]$Id)
    
    $Url = $Models[$Id]
    $Filename = Join-Path $ModelsDir "$Id.gguf"
    
    if (-not $Url) {
        Write-Host "Error: Model '$Id' not found" -ForegroundColor Red
        Write-Host "Available models: $($Models.Keys -join ', ')"
        return $false
    }
    
    if (Test-Path $Filename) {
        Write-Host "✓ $Id already downloaded" -ForegroundColor Green
        return $true
    }
    
    Write-Host "Downloading $Id..." -ForegroundColor Yellow
    Write-Host "URL: $Url"
    
    $ProgressPreference = 'Continue'
    if (Invoke-WebRequest -Uri $Url -OutFile $Filename -UseBasicParsing -ErrorAction SilentlyContinue) {
        $Size = (Get-Item $Filename).Length / 1MB
        Write-Host "✓ Downloaded: $Filename ($([math]::Round($Size, 1)) MB)" -ForegroundColor Green
        return $true
    }
    else {
        Write-Host "✗ Failed to download $Id" -ForegroundColor Red
        Remove-Item $Filename -ErrorAction SilentlyContinue
        return $false
    }
}

# Main
if (-not $ModelId -and -not $All) {
    Write-Host "Librio Phase 0: Model Downloader"
    Write-Host ""
    Write-Host "Usage: .\download_models.ps1 -ModelId <id>"
    Write-Host "       .\download_models.ps1 -All"
    Write-Host ""
    Write-Host "Available models (4GB tier):"
    Write-Host "  gemma3-1b-q4    - Gemma 3 1B (Q4_K_M, ~600 MB)"
    Write-Host "  llama32-1b-q4   - Llama 3.2 1B (Q4_K_M, ~800 MB)"
    Write-Host "  smollm3-1.7b-q4 - SmolLM3 1.7B (Q4_K_M, ~1 GB)"
    Write-Host ""
    Write-Host "Available models (8GB tier):"
    Write-Host "  gemma3-4b-q4    - Gemma 3 4B (Q4_K_M, ~2.3 GB)"
    Write-Host "  qwen3-3b-q4     - Qwen3 3B (Q4_K_M, ~2 GB)"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\download_models.ps1 -ModelId gemma3-1b-q4"
    Write-Host "  .\download_models.ps1 -All"
    exit 0
}

if ($All) {
    foreach ($Id in $Models.Keys) {
        Download-Model -Id $Id
    }
}
else {
    Download-Model -Id $ModelId
}

Write-Host ""
Write-Host "Done!" -ForegroundColor Green
Write-Host "Models stored in: $ModelsDir/"
Write-Host "Next: Run benchmark harness with --model <id>"
