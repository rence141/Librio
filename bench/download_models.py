#!/usr/bin/env python3
"""
Download candidate GGUF models for Phase 0 benchmarking.
Models are stored in bench/models/ (not committed to git).

Usage:
  python download_models.py gemma3-1b-q4
  python download_models.py all
  python download_models.py --list
"""

import sys
import os
from pathlib import Path
from huggingface_hub import hf_hub_download

# Fix Unicode on Windows
if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8")

# Model definitions: (repo_id, filename)
MODELS = {
    "gemma3-1b-q4": (
        "bartowski/google_gemma-3-1b-it-GGUF",
        "google_gemma-3-1b-it-Q4_K_M.gguf",
        0.81,  # GB
    ),
    "llama32-1b-q4": (
        "bartowski/Llama-3.2-1B-Instruct-GGUF",
        "Llama-3.2-1B-Instruct-Q4_K_M.gguf",
        0.8,
    ),
    "smollm2-1.7b-q4": (
        "bartowski/SmolLM2-1.7B-Instruct-GGUF",
        "SmolLM2-1.7B-Instruct-Q4_K_M.gguf",
        1.06,
    ),
    "gemma3-4b-q4": (
        "bartowski/google_gemma-3-4b-it-GGUF",
        "google_gemma-3-4b-it-Q4_K_M.gguf",
        2.3,
    ),
    "qwen3-3b-q4": (
        "bartowski/Qwen2.5-3B-Instruct-GGUF",
        "Qwen2.5-3B-Instruct-Q4_K_M.gguf",
        2.0,
    ),
}

MODELS_DIR = Path("models")


def download_model(model_id: str) -> bool:
    """Download a single model."""
    if model_id not in MODELS:
        print(f"❌ Error: Model '{model_id}' not found")
        print(f"Available models: {', '.join(MODELS.keys())}")
        return False

    repo_id, filename, size_gb = MODELS[model_id]
    output_path = MODELS_DIR / f"{model_id}.gguf"

    # Create models directory
    MODELS_DIR.mkdir(exist_ok=True)

    # Check if already downloaded
    if output_path.exists():
        print(f"✓ {model_id} already downloaded ({output_path})")
        return True

    print(f"[*] Downloading {model_id}...")
    print(f"   Repo: {repo_id}")
    print(f"   File: {filename}")
    print(f"   Size: ~{size_gb} GB")
    print()

    try:
        path = hf_hub_download(
            repo_id=repo_id,
            filename=filename,
            local_dir=str(MODELS_DIR),
            local_dir_use_symlinks=False,
        )
        print(f"✓ Downloaded: {path}")
        return True
    except Exception as e:
        print(f"❌ Failed to download {model_id}: {e}")
        return False


def list_models():
    """List all available models."""
    print("Librio Phase 0: Available Models")
    print()
    print("4GB Tier (Minimum):")
    for model_id in ["gemma3-1b-q4", "llama32-1b-q4", "smollm2-1.7b-q4"]:
        _, _, size = MODELS[model_id]
        print(f"  {model_id:20} (~{size} GB)")
    print()
    print("8GB Tier (Optional):")
    for model_id in ["gemma3-4b-q4", "qwen3-3b-q4"]:
        _, _, size = MODELS[model_id]
        print(f"  {model_id:20} (~{size} GB)")


def main():
    if len(sys.argv) < 2 or sys.argv[1] in ["--help", "-h"]:
        print("Librio Phase 0: Model Downloader")
        print()
        print("Usage: python download_models.py [model_id | all | --list]")
        print()
        list_models()
        print()
        print("Examples:")
        print("  python download_models.py gemma3-1b-q4")
        print("  python download_models.py all")
        print("  python download_models.py --list")
        return 0

    if sys.argv[1] == "--list":
        list_models()
        return 0

    if sys.argv[1] == "all":
        print("Downloading all models...")
        print()
        success = True
        for model_id in MODELS.keys():
            if not download_model(model_id):
                success = False
            print()
        if success:
            print("✓ All models downloaded!")
        else:
            print("⚠ Some models failed to download")
        return 0 if success else 1

    # Download single model
    if download_model(sys.argv[1]):
        print()
        print("✓ Done!")
        print(f"Models stored in: {MODELS_DIR}/")
        print("Next: Run benchmark harness with --model <id>")
        return 0
    else:
        return 1


if __name__ == "__main__":
    sys.exit(main())
