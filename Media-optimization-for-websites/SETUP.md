# Environment Setup Guide

Complete setup instructions for all operating systems.

## System Requirements

- **Node.js:** 18.0.0 or higher
- **FFmpeg:** Latest stable version with libx264 and libvpx-vp9
- **Disk Space:** At least 2x the size of your media (for optimization scratch space)
- **RAM:** Minimum 2GB (4GB+ recommended for parallel processing)

---

## Windows Setup

### 1. Install Node.js

Download from https://nodejs.org/ (LTS version recommended)

Verify installation:
```powershell
node --version
npm --version
```

### 2. Install FFmpeg

**Option A: Using Chocolatey (Recommended)**

```powershell
# If you don't have Chocolatey installed
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install FFmpeg
choco install ffmpeg
```

**Option B: Using Scoop**

```powershell
# Install Scoop if needed
iwr -useb get.scoop.sh | iex

# Install FFmpeg
scoop install ffmpeg
```

**Option C: Manual Installation**

1. Download from https://ffmpeg.org/download.html
2. Extract to `C:\ffmpeg`
3. Add to PATH:
   - Press `Win + X`, select "System"
   - Click "Advanced system settings"
   - Click "Environment Variables"
   - Add `C:\ffmpeg\bin` to PATH

### 3. Verify Installation

```powershell
ffmpeg -version
ffprobe -version
```

### 4. Install Dependencies

```powershell
cd path\to\media-optimization-for-websites
npm install
```

---

## macOS Setup

### 1. Install Node.js

**Using Homebrew (Recommended):**

```bash
# Install Homebrew if needed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Node.js
brew install node
```

**Using MacPorts:**

```bash
# Install MacPorts from https://www.macports.org/install.php
sudo port install nodejs18
```

Verify:
```bash
node --version
npm --version
```

### 2. Install FFmpeg

```bash
brew install ffmpeg
```

Or with options:
```bash
brew install ffmpeg --with-libvpx --with-libx264
```

Verify:
```bash
ffmpeg -version
ffprobe -version
```

### 3. Install Dependencies

```bash
cd path/to/media-optimization-for-websites
npm install
```

---

## Linux Setup

### Ubuntu/Debian

**1. Update package manager:**
```bash
sudo apt-get update
sudo apt-get upgrade -y
```

**2. Install Node.js:**
```bash
# Using NodeSource repository (recommended)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Or using snap
sudo snap install node --classic
```

Verify:
```bash
node --version
npm --version
```

**3. Install FFmpeg:**
```bash
sudo apt-get install -y ffmpeg
```

Verify:
```bash
ffmpeg -version
ffprobe -version
```

**4. Install dependencies:**
```bash
cd path/to/media-optimization-for-websites
npm install
```

### Fedora/CentOS/RHEL

**1. Install Node.js:**
```bash
# Using dnf (Fedora 22+)
sudo dnf install nodejs

# Or using yum (CentOS/RHEL)
sudo yum install nodejs
```

**2. Install FFmpeg:**
```bash
# Fedora
sudo dnf install ffmpeg

# CentOS/RHEL (might need EPEL)
sudo yum install epel-release
sudo yum install ffmpeg
```

**3. Install dependencies:**
```bash
cd path/to/media-optimization-for-websites
npm install
```

### Alpine Linux

```bash
apk add --no-cache nodejs npm ffmpeg
cd path/to/media-optimization-for-websites
npm install
```

---

## Docker Setup

If you prefer containerized execution:

```dockerfile
FROM node:18-alpine

# Install FFmpeg
RUN apk add --no-cache ffmpeg

WORKDIR /app

# Copy files
COPY package*.json ./
RUN npm ci --only=production

COPY . .

# Run optimization
CMD ["node", "convert-media.js"]
```

Build and run:
```bash
docker build -t media-optimizer .
docker run -v /path/to/media:/app/public media-optimizer
```

---

## Troubleshooting

### FFmpeg Not Found

**Windows:**
```powershell
# Check FFmpeg is in PATH
where ffmpeg

# If not found, verify installation and restart terminal
```

**macOS/Linux:**
```bash
# Check FFmpeg location
which ffmpeg

# If not found, reinstall
brew install ffmpeg  # macOS
sudo apt-get install ffmpeg  # Ubuntu
```

### Permission Errors

**macOS/Linux:**
```bash
# Grant execute permissions
chmod +x convert-media.js
chmod +x generate-*.js

# Fix ownership if needed
sudo chown $USER:$GROUP /path/to/scripts
```

### Out of Memory

If you get memory errors:

```bash
# Increase Node.js heap size
node --max-old-space-size=4096 convert-media.js

# Or reduce parallel workers
node convert-media.js --parallel 2
```

### Path Issues

**Windows:**
```powershell
# Test FFmpeg is accessible
ffmpeg -version

# If error, check Environment Variables (Win+R, type 'sysdm.cpl')
```

**macOS/Linux:**
```bash
# Add to shell profile (~/.bash_profile, ~/.zshrc)
export PATH="/usr/local/bin:$PATH"
source ~/.bashrc
```

---

## Performance Tuning

### For Slow Systems
```bash
node convert-media.js --parallel 2 --image-quality 70 --video-quality 32
```

### For High-End Systems
```bash
node convert-media.js --parallel 8 --image-quality 85 --video-quality 26
```

### Monitor Resource Usage

**Windows (PowerShell):**
```powershell
Get-Process node | Select-Object ProcessName, @{Name="Memory(MB)"; Expression={$_.WS/1MB}} -First 5
```

**macOS/Linux:**
```bash
ps aux | grep node
top -p [PID]  # Monitor specific process
```

---

## Network Setup (Optional)

If behind a corporate proxy:

```bash
npm config set proxy http://[user:passwd@]proxy.company.com:8080
npm config set https-proxy http://[user:passwd@]proxy.company.com:8080
npm config set strict-ssl false
```

---

## Node.js Version Management

For managing multiple Node.js versions:

### Using nvm (macOS/Linux)

```bash
# Install nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# Install Node 18
nvm install 18
nvm use 18
nvm alias default 18
```

### Using nvm-windows (Windows)

Download from: https://github.com/coreybutler/nvm-windows

```powershell
nvm install 18.0.0
nvm use 18.0.0
```

---

## Verification Checklist

After setup, verify everything works:

```bash
# Check Node.js
node --version          # Should show v18+
npm --version           # Should show 9+

# Check FFmpeg
ffmpeg -version         # Should show version info
ffprobe -version        # Should show version info

# Check script is executable
ls -l convert-media.js  # macOS/Linux
dir convert-media.js    # Windows

# Test run dry-run
npm run optimize:dry    # Should show preview without errors
```

---

## Disk Space Requirements

Estimate needed space:

| Project Size | Scratch Space Needed |
|--------------|----------------------|
| 500 MB       | 1 GB                 |
| 1 GB         | 2 GB                 |
| 5 GB         | 10 GB                |
| 10 GB+       | 20 GB+               |

Check available space:

**Windows:**
```powershell
Get-Volume C | Select-Object SizeRemaining, Size
```

**macOS/Linux:**
```bash
df -h
```

---

## Next Steps

1. ✅ Verify all installations
2. ✅ Run `npm run optimize:dry` to test
3. ✅ Check [QUICK_START.md](./QUICK_START.md) for first run
4. ✅ See [README.md](./README.md) for full documentation

---

## Support

- **FFmpeg Docs:** https://ffmpeg.org/documentation.html
- **Node.js Docs:** https://nodejs.org/docs/
- **Sharp (Image):** https://sharp.pixelplumbing.com/
- **Fluent-FFmpeg:** https://github.com/fluent-ffmpeg/node-fluent-ffmpeg
