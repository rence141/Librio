# PowerShell Commands Reference

**For Windows Users**

---

## 📥 Download Model File

### **PowerShell Syntax (Correct)**
```powershell
cd C:\dev\Librio\apps\mobile\assets\models

Invoke-WebRequest -Uri "https://huggingface.co/google/gemma-3-1b-gguf/resolve/main/gemma-3-1b-q4_k_m.gguf" `
  -OutFile "gemma-3-1b-q4_k_m.gguf" `
  -UseBasicParsing `
  -TimeoutSec 3600
```

### **Alternative: Using curl (if installed)**
```powershell
curl.exe -L -o gemma-3-1b-q4_k_m.gguf `
  https://huggingface.co/google/gemma-3-1b-gguf/resolve/main/gemma-3-1b-q4_k_m.gguf
```

**Note:** Use `curl.exe` (not `curl`) to avoid PowerShell alias

---

## ✅ Verify Download

```powershell
# Check if file exists
Test-Path "gemma-3-1b-q4_k_m.gguf"

# Get file size
(Get-Item "gemma-3-1b-q4_k_m.gguf").Length / 1GB

# Expected: ~2.5GB
```

---

## 🔍 Common PowerShell Commands

### **Directory Operations**
```powershell
# List files
Get-ChildItem
ls
dir

# Create directory
New-Item -ItemType Directory -Path "path/to/dir"
mkdir "path/to/dir"

# Change directory
Set-Location "path"
cd "path"

# Get current directory
Get-Location
pwd
```

### **File Operations**
```powershell
# Check if file exists
Test-Path "filename"

# Get file size
(Get-Item "filename").Length

# Get file size in GB
(Get-Item "filename").Length / 1GB

# Delete file
Remove-Item "filename"
rm "filename"

# Copy file
Copy-Item "source" "destination"
cp "source" "destination"
```

### **Network Operations**
```powershell
# Download file (recommended)
Invoke-WebRequest -Uri "url" -OutFile "filename" -UseBasicParsing

# Download with timeout
Invoke-WebRequest -Uri "url" -OutFile "filename" -UseBasicParsing -TimeoutSec 3600

# Download with progress
$ProgressPreference = 'Continue'
Invoke-WebRequest -Uri "url" -OutFile "filename"
```

---

## 🚀 Flutter Commands

```powershell
# Get dependencies
flutter pub get

# Run app
flutter run

# Run with specific device
flutter run -d <device-id>

# Run in profile mode
flutter run --profile

# Clean build
flutter clean

# Build APK
flutter build apk

# Build release APK
flutter build apk --release
```

---

## 📦 Node.js Commands

```powershell
# Install dependencies
npm install

# Run dev server
npm run dev

# Build
npm run build

# Start production
npm start

# Run tests
npm test

# Check version
node --version
npm --version
```

---

## 🔧 Git Commands

```powershell
# Check status
git status

# Add files
git add .
git add <file>

# Commit
git commit -m "message"

# View log
git log

# View diff
git diff

# Push
git push

# Pull
git pull
```

---

## ⚙️ Useful Tips

### **Line Continuation in PowerShell**
Use backtick (`) to continue long lines:
```powershell
Invoke-WebRequest -Uri "url" `
  -OutFile "file" `
  -UseBasicParsing
```

### **Escape Special Characters**
```powershell
# Use double quotes for variables
"$variable"

# Use single quotes for literal strings
'literal string'

# Escape special characters with backtick
`$literal_dollar_sign
```

### **Run Commands in Background**
```powershell
# Start background job
Start-Job -ScriptBlock { command }

# Get job output
Get-Job | Receive-Job

# Wait for job
Wait-Job -Id <id>
```

---

## 📞 Troubleshooting

### **"curl: command not found"**
**Solution:** Use `curl.exe` instead of `curl`
```powershell
curl.exe -L -o file.gguf https://...
```

### **"Parameter cannot be found"**
**Solution:** Use PowerShell syntax, not Unix syntax
```powershell
# Wrong:
curl -L -o file.gguf url

# Correct:
Invoke-WebRequest -Uri "url" -OutFile "file.gguf"
```

### **"Access denied"**
**Solution:** Run PowerShell as Administrator
```powershell
# Right-click PowerShell → Run as Administrator
```

### **Long download times**
**Solution:** Use `-TimeoutSec 3600` for 1-hour timeout
```powershell
Invoke-WebRequest -Uri "url" -OutFile "file" -TimeoutSec 3600
```

---

## 🎯 Quick Reference

| Task | Command |
|------|---------|
| Download file | `Invoke-WebRequest -Uri "url" -OutFile "file"` |
| Check file size | `(Get-Item "file").Length / 1GB` |
| List files | `Get-ChildItem` or `ls` |
| Create directory | `mkdir "path"` |
| Delete file | `rm "file"` |
| Run Flutter | `flutter run` |
| Run Node.js | `npm run dev` |
| Git commit | `git commit -m "msg"` |

---

Generated: 2026-08-22  
Status: Reference guide for Windows users
