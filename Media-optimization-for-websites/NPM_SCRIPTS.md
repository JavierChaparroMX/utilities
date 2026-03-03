# NPM Scripts Reference

Quick reference for all available npm scripts for media optimization.

## 🔥 Quick Start

```bash
# GPU Mode (Recommended for AMD GPUs) - FASTEST
npm run optimize:gpu              # Full optimization
npm run optimize:gpu:dry          # Preview what would happen
npm run optimize:gpu:images-only  # Process images only
npm run optimize:gpu:videos-only  # Process videos only

# CPU Mode - More Compatible
npm run optimize:cpu              # Full optimization
npm run optimize:cpu:dry          # Preview what would happen
npm run optimize:cpu:images-only  # Process images only
npm run optimize:cpu:videos-only  # Process videos only

# Default Mode (Original Script)
npm run optimize                  # Full optimization
npm run optimize:dry              # Preview what would happen
npm run optimize:images-only      # Process images only
npm run optimize:videos-only      # Process videos only
```

---

## 📊 Complete Scripts List

### GPU Mode Scripts (AMD HEVC - Fastest)

| Script | Description | Speed |
|--------|-------------|-------|
| `npm run optimize:gpu` | Full media optimization on GPU | ⚡⚡ |
| `npm run optimize:gpu:dry` | Preview without converting | ⚡ |
| `npm run optimize:gpu:continue` | Resume interrupted batch | ⚡⚡ |
| `npm run optimize:gpu:images-only` | Optimize images only | ⚡ |
| `npm run optimize:gpu:videos-only` | Optimize videos only | ⚡⚡⚡ |

### CPU Mode Scripts (libx264 - Compatible)

| Script | Description | Speed |
|--------|-------------|-------|
| `npm run optimize:cpu` | Full media optimization on CPU | ⚡ |
| `npm run optimize:cpu:dry` | Preview without converting | ⚡ |
| `npm run optimize:cpu:continue` | Resume interrupted batch | ⚡ |
| `npm run optimize:cpu:images-only` | Optimize images only | ⚡ |
| `npm run optimize:cpu:videos-only` | Optimize videos only | ⚡ |

### Original/Default Scripts

| Script | Description |
|--------|-------------|
| `npm run optimize` | Full media optimization (default codecs) |
| `npm run optimize:dry` | Preview without converting |
| `npm run optimize:continue` | Resume interrupted batch |
| `npm run optimize:images-only` | Optimize images only |
| `npm run optimize:videos-only` | Optimize videos only |
| `npm start` | Alias for `convert-media.js` |

---

## 🎯 Common Commands

```bash
# AMD GPU Acceleration (HEVC 5-10x faster)
npm run optimize:gpu
npm run optimize:gpu:dry

# CPU Processing (Universal Compatibility)
npm run optimize:cpu
npm run optimize:cpu:dry

# Batch Resume (Continue from last file if interrupted)
npm run optimize:gpu:continue
npm run optimize:cpu:continue

# Separate Image/Video Processing
npm run optimize:gpu:images-only
npm run optimize:gpu:videos-only

# Custom directories (All scripts)
node convert-media-gpu.js --source ./custom --output ./optimized
node convert-media-cpu.js --source ./custom --output ./optimized
node convert-media.js --source ./custom --output ./optimized
```

---

## ⚙️ Custom Options for Any Script

All scripts support these parameters:

```bash
node convert-media-gpu.js [options]
node convert-media-cpu.js [options]
node convert-media.js [options]

# Options:
  -s, --source <path>      Source directory
  -o, --output <path>      Output directory
  --dry-run                Preview only
  --continue               Resume from last file
  --skip-images            Skip image processing
  --skip-videos            Skip video processing
  --image-quality 0-100    Image quality (default: 80)
  --video-quality 0-51     Video quality (default: 28)
  -p, --parallel <num>     Parallel workers (default: 4)
  -v, --verbose            Detailed logging
  -h, --help               Show help
```

---

## 🚀 Example Commands

### Standard Quality (Recommended)
```bash
# GPU mode (fastest)
npm run optimize:gpu

# CPU mode (most compatible)
npm run optimize:cpu
```

### High Quality Output
```bash
node convert-media-gpu.js --image-quality 90 --video-quality 20
node convert-media-cpu.js --image-quality 90 --video-quality 20
```

### Aggressive Compression (Smaller Files)
```bash
node convert-media-gpu.js --image-quality 65 --video-quality 35
node convert-media-cpu.js --image-quality 65 --video-quality 35
```

### Custom Directories
```bash
node convert-media-gpu.js --source ./website/assets --output ./dist/optimized
node convert-media-cpu.js --source ./photos --output ./compressed
```

### Parallel Processing Control
```bash
# Use only 2 workers (good for older hardware)
node convert-media-gpu.js --parallel 2

# Use 8 workers (for powerful systems)
node convert-media-gpu.js --parallel 8
```

### Dry-Run Preview
```bash
npm run optimize:gpu:dry
npm run optimize:cpu:dry
```

### Resume Interrupted Job
```bash
npm run optimize:gpu:continue
npm run optimize:cpu:continue
```

---

## 📈 Performance Expectations

### GPU Mode (AMD HEVC)
- **Images**: 2-5s per image (depends on size)
- **Videos**: 2-10 minutes per 1GB of video
- **Typical reduction**: 85-90% size reduction

### CPU Mode (libx264)
- **Images**: 2-5s per image (same as GPU)
- **Videos**: 20-50 minutes per 1GB of video
- **Typical reduction**: 80-85% size reduction

---

## 📊 Output Files

Each run creates in the output directory:
- `images-optimized/` - Optimized images
- `videos-optimized/` - Original quality optimized videos
- `videos-optimized/mobile/` - Mobile quality videos
- `conversion-report.json` - Detailed results and statistics
- `conversion.log` - Processing logs

---

## ✅ Checklist Before Running

- [ ] Source directory exists and contains media files
- [ ] Output directory has enough free space (2x input size)
- [ ] For GPU mode: FFmpeg installed with AMF support (`ffmpeg -encoders | grep -i amf`)
- [ ] For GPU mode: AMD GPU drivers are up-to-date
- [ ] Run dry-run first: `npm run optimize:gpu:dry`
- [ ] Check the preview looks correct

---

## 🆘 Troubleshooting

```bash
# Check FFmpeg version and GPU support
ffmpeg -version
ffmpeg -encoders | grep -i amf    # For GPU mode
ffmpeg -encoders | grep -i libx264 # For CPU mode

# Check available GPUs
dxdiag

# Reinstall FFmpeg
winget install --force ffmpeg

# Check Node.js version
node --version

# Verify script files exist
ls -la convert-media*.js

# List all npm scripts
npm run
```

---

## 📝 Mode Selection Guide

| Your Situation | Recommended | Command |
|---|---|---|
| Have AMD GPU (Radeon 780M/6700/7900) | GPU | `npm run optimize:gpu` |
| No GPU / CPU only | CPU | `npm run optimize:cpu` |
| Large batch (100+ files) | GPU | `npm run optimize:gpu` |
| CI/CD pipeline | CPU | `npm run optimize:cpu` |
| Want best compression | GPU | `npm run optimize:gpu` |
| Want universal compatibility | CPU | `npm run optimize:cpu` |
| Testing / experimenting | Either, use dry-run | `npm run optimize:xxx:dry` |

---

**Pro Tip:** Start with Git version control:
```bash
git init
git add .
git commit -m "Before media optimization"
npm run optimize:gpu
git add . && git commit -m "After GPU optimization - 90% size reduction"
```

Then you can easily compare before and after in version control!
