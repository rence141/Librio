#!/bin/bash
# Download candidate LLM models for Phase 0 benchmarking
# Models are stored in bench/models/ (not committed to git)
# Usage: bash bench/download_models.sh [model_id]

set -e

MODELS_DIR="models"
mkdir -p "$MODELS_DIR"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Model definitions (from bench/models.json)
declare -A MODELS=(
  ["gemma3-1b-q4"]="https://huggingface.co/bartowski/Gemma-3-1B-Instruct-GGUF/resolve/main/Gemma-3-1B-Instruct-Q4_K_M.gguf"
  ["llama32-1b-q4"]="https://huggingface.co/bartowski/Llama-3.2-1B-Instruct-GGUF/resolve/main/Llama-3.2-1B-Instruct-Q4_K_M.gguf"
  ["smollm3-1.7b-q4"]="https://huggingface.co/bartowski/SmolLM3-1.7B-Instruct-GGUF/resolve/main/SmolLM3-1.7B-Instruct-Q4_K_M.gguf"
  ["gemma3-4b-q4"]="https://huggingface.co/bartowski/Gemma-3-4B-Instruct-GGUF/resolve/main/Gemma-3-4B-Instruct-Q4_K_M.gguf"
  ["qwen3-3b-q4"]="https://huggingface.co/bartowski/Qwen2.5-3B-Instruct-GGUF/resolve/main/Qwen2.5-3B-Instruct-Q4_K_M.gguf"
)

download_model() {
  local model_id=$1
  local url=${MODELS[$model_id]}
  local filename="$MODELS_DIR/${model_id}.gguf"

  if [ -z "$url" ]; then
    echo -e "${RED}Error: Model '$model_id' not found${NC}"
    echo "Available models: ${!MODELS[@]}"
    return 1
  fi

  if [ -f "$filename" ]; then
    echo -e "${GREEN}✓ $model_id already downloaded${NC}"
    return 0
  fi

  echo -e "${YELLOW}Downloading $model_id...${NC}"
  echo "URL: $url"
  
  # Use curl with progress bar
  if curl -L --progress-bar -o "$filename" "$url"; then
    echo -e "${GREEN}✓ Downloaded: $filename${NC}"
    ls -lh "$filename"
  else
    echo -e "${RED}✗ Failed to download $model_id${NC}"
    rm -f "$filename"
    return 1
  fi
}

# Main
if [ $# -eq 0 ]; then
  echo "Librio Phase 0: Model Downloader"
  echo ""
  echo "Usage: bash download_models.sh [model_id | all]"
  echo ""
  echo "Available models (4GB tier):"
  echo "  gemma3-1b-q4    - Gemma 3 1B (Q4_K_M, ~600 MB)"
  echo "  llama32-1b-q4   - Llama 3.2 1B (Q4_K_M, ~800 MB)"
  echo "  smollm3-1.7b-q4 - SmolLM3 1.7B (Q4_K_M, ~1 GB)"
  echo ""
  echo "Available models (8GB tier):"
  echo "  gemma3-4b-q4    - Gemma 3 4B (Q4_K_M, ~2.3 GB)"
  echo "  qwen3-3b-q4     - Qwen3 3B (Q4_K_M, ~2 GB)"
  echo ""
  echo "Examples:"
  echo "  bash download_models.sh gemma3-1b-q4"
  echo "  bash download_models.sh all"
  exit 0
fi

if [ "$1" = "all" ]; then
  for model_id in "${!MODELS[@]}"; do
    download_model "$model_id"
  done
else
  download_model "$1"
fi

echo ""
echo -e "${GREEN}Done!${NC}"
echo "Models stored in: $MODELS_DIR/"
echo "Next: Run benchmark harness with --model <id>"
