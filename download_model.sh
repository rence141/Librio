#!/bin/bash

# Librio Model Download Script
# Downloads Gemma 3 1B GGUF model from HuggingFace

set -e

echo "🤖 Librio Model Download Script"
echo "================================"
echo ""

# Model details
MODEL_NAME="gemma-3-1b-q4_k_m.gguf"
MODEL_URL="https://huggingface.co/google/gemma-3-1b-gguf/resolve/main/gemma-3-1b-q4_k_m.gguf"
MODEL_SIZE="650 MB"

echo "Model: Gemma 3 1B (Quantized)"
echo "Size: $MODEL_SIZE"
echo "URL: $MODEL_URL"
echo ""

# Check if model already exists
if [ -f "$MODEL_NAME" ]; then
    echo "⚠️  Model file already exists: $MODEL_NAME"
    read -p "Overwrite? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Cancelled."
        exit 1
    fi
    rm "$MODEL_NAME"
fi

# Download model
echo "📥 Downloading model..."
echo "This may take 10-30 minutes depending on internet speed"
echo ""

if command -v wget &> /dev/null; then
    echo "Using wget..."
    wget -c "$MODEL_URL" -O "$MODEL_NAME"
elif command -v curl &> /dev/null; then
    echo "Using curl..."
    curl -L -C - "$MODEL_URL" -o "$MODEL_NAME"
else
    echo "❌ Error: Neither wget nor curl found"
    echo "Please install wget or curl and try again"
    exit 1
fi

# Verify download
echo ""
echo "✅ Download complete!"
echo ""

if [ -f "$MODEL_NAME" ]; then
    SIZE=$(du -h "$MODEL_NAME" | cut -f1)
    echo "File: $MODEL_NAME"
    echo "Size: $SIZE"
    echo ""
    echo "📱 Next steps:"
    echo "1. Connect Android device via USB"
    echo "2. Run: adb push $MODEL_NAME /data/user/0/com.librio.librio/app_flutter/models/"
    echo "3. Restart the Librio app"
    echo ""
else
    echo "❌ Error: Download failed"
    exit 1
fi
