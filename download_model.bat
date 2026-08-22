@echo off
REM Librio Model Download Script for Windows
REM Downloads Gemma 3 1B GGUF model from HuggingFace

setlocal enabledelayedexpansion

echo.
echo 🤖 Librio Model Download Script
echo ================================
echo.

REM Model details
set MODEL_NAME=gemma-3-1b-q4_k_m.gguf
set MODEL_URL=https://huggingface.co/google/gemma-3-1b-gguf/resolve/main/gemma-3-1b-q4_k_m.gguf
set MODEL_SIZE=650 MB

echo Model: Gemma 3 1B (Quantized)
echo Size: %MODEL_SIZE%
echo URL: %MODEL_URL%
echo.

REM Check if model already exists
if exist "%MODEL_NAME%" (
    echo ⚠️  Model file already exists: %MODEL_NAME%
    set /p OVERWRITE="Overwrite? (y/n): "
    if /i not "!OVERWRITE!"=="y" (
        echo Cancelled.
        exit /b 1
    )
    del "%MODEL_NAME%"
)

REM Download model using PowerShell
echo 📥 Downloading model...
echo This may take 10-30 minutes depending on internet speed
echo.

powershell -Command ^
    "$ProgressPreference = 'Continue'; ^
    $url = '%MODEL_URL%'; ^
    $output = '%MODEL_NAME%'; ^
    Write-Host 'Downloading from HuggingFace...'; ^
    try { ^
        Invoke-WebRequest -Uri $url -OutFile $output -UseBasicParsing; ^
        Write-Host '✅ Download complete!'; ^
    } catch { ^
        Write-Host '❌ Download failed: $_'; ^
        exit 1; ^
    }"

if %ERRORLEVEL% neq 0 (
    echo.
    echo ❌ Download failed
    exit /b 1
)

REM Verify download
echo.
echo ✅ Download complete!
echo.

if exist "%MODEL_NAME%" (
    for %%A in ("%MODEL_NAME%") do set SIZE=%%~zA
    set /a SIZE_MB=!SIZE! / 1048576
    
    echo File: %MODEL_NAME%
    echo Size: !SIZE_MB! MB
    echo.
    echo 📱 Next steps:
    echo 1. Connect Android device via USB
    echo 2. Run: adb push %MODEL_NAME% /data/user/0/com.librio.librio/app_flutter/models/
    echo 3. Restart the Librio app
    echo.
) else (
    echo ❌ Error: Download failed
    exit /b 1
)

pause
