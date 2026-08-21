#!/bin/bash
# Transfer GGUF models to Infinix-Note50 via ADB
# Usage: ./transfer_models.sh

DEVICE_ID="adb-138097055K002303-DxquAm._adb-tls-connect._tcp"
MODELS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/models"
DEVICE_DIR="/data/user/0/com.librio.librio/app_flutter/models"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}=== Librio Model Transfer Script ===${NC}"
echo "Device: $DEVICE_ID"
echo "Local models: $MODELS_DIR"
echo "Device target: $DEVICE_DIR"
echo ""

# Check if adb is available
if ! command -v adb &> /dev/null; then
    echo -e "${RED}ERROR: adb not found. Please install Android SDK Platform Tools.${NC}"
    exit 1
fi

# Check if device is connected
echo -e "${YELLOW}Checking device connection...${NC}"
if ! adb devices | grep -q "$DEVICE_ID"; then
    echo -e "${RED}ERROR: Device not found.${NC}"
    echo "Available devices:"
    adb devices
    exit 1
fi
echo -e "${GREEN}✓ Device connected${NC}"

# Check if models directory exists
if [ ! -d "$MODELS_DIR" ]; then
    echo -e "${RED}ERROR: Models directory not found: $MODELS_DIR${NC}"
    exit 1
fi

# Get list of GGUF files
MODELS=($(find "$MODELS_DIR" -maxdepth 1 -name "*.gguf" -type f))
if [ ${#MODELS[@]} -eq 0 ]; then
    echo -e "${RED}ERROR: No GGUF files found in $MODELS_DIR${NC}"
    exit 1
fi

echo -e "${YELLOW}Found ${#MODELS[@]} model(s):${NC}"
for model in "${MODELS[@]}"; do
    size=$(du -h "$model" | cut -f1)
    echo "  - $(basename "$model") ($size)"
done
echo ""

# Create device directory
echo -e "${YELLOW}Creating device directory...${NC}"
adb -s "$DEVICE_ID" shell mkdir -p "$DEVICE_DIR"
if [ $? -ne 0 ]; then
    echo -e "${RED}ERROR: Failed to create device directory${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Directory created${NC}"

# Transfer each model
TOTAL_SIZE=0
for model in "${MODELS[@]}"; do
    model_name=$(basename "$model")
    model_size=$(stat -f%z "$model" 2>/dev/null || stat -c%s "$model" 2>/dev/null)
    TOTAL_SIZE=$((TOTAL_SIZE + model_size))
    size_mb=$(echo "scale=2; $model_size / 1048576" | bc)
    
    echo ""
    echo -e "${CYAN}Transferring: $model_name ($size_mb MB)${NC}"
    
    start_time=$(date +%s)
    adb -s "$DEVICE_ID" push "$model" "$DEVICE_DIR/$model_name"
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}ERROR: Failed to transfer $model_name${NC}"
        exit 1
    fi
    
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    speed=$(echo "scale=2; $model_size / 1048576 / $duration" | bc)
    
    echo -e "${GREEN}✓ Transferred: $model_name ($speed MB/s)${NC}"
done

echo ""
echo -e "${GREEN}=== Transfer Complete ===${NC}"
total_mb=$(echo "scale=2; $TOTAL_SIZE / 1048576" | bc)
echo "Total transferred: $total_mb MB"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Open the Librio app on your phone"
echo "2. Go to the Benchmark screen"
echo "3. Tap 'Start Benchmark'"
echo "4. Watch the logs as it loads and runs inference on the models"
echo ""
