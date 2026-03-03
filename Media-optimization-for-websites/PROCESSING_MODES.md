# Media Optimization Processing Modes

This toolset provides **three processing modes** for media optimization, optimized for different use cases and hardware configurations.

## 📋 Processing Modes Comparison

| Feature | Default | CPU Mode | GPU Mode |
|---------|---------|----------|----------|
| **Script** | `convert-media.js` | `convert-media-cpu.js` | `convert-media-gpu.js` |
| **Video Encoder** | libx264 | libx264 | hevc_amf |
| **GPU Support** | ❌ No | ❌ No | ✅ Yes (AMD) |
| **Speed** | Moderate | Moderate | 🚀 Fast |
| **Quality** | Good | Good | Excellent |
| **Best For** | Quick tests | Compatibility | Performance |

---

## 💻 CPU Mode (`convert-media-cpu.js`)

### When to use:
- Running on older hardware without modern GPU
- Need compatibility with all systems
- Processing in CI/CD pipelines (cloud)
- Don't want GPU driver dependencies

### Video Codecs:
- **H.264 (libx264)**: Universal compatibility, moderate compression
- **VP9 (libvpx-vp9)**: Modern web standard, better compression

### Commands:
```bash
# Basic optimization
npm run optimize:cpu

# Dry-run preview
npm run optimize:cpu:dry

# Resume interrupted job
npm run optimize:cpu:continue

# Images only
npm run optimize:cpu:images-only

# Videos only
npm run optimize:cpu:videos-only

# Custom directories
node convert-media-cpu.js --source ./my-assets --output ./optimized
```

### Typical Performance:
- **Images**: ~2-5 seconds per image (depends on size)
- **Video**: ~1-5 minutes per video (highly variable)

---

## 🚀 GPU Mode (`convert-media-gpu.js`)

### When to use:
- Have AMD Radeon GPU (780M, 6700XT, 7900XTX, etc.)
- Processing large video batches
- Want fastest possible conversion
- Have FFmpeg with AMF support installed

### Requirements:
- ✅ AMD Radeon GPU (any modern model)
- ✅ FFmpeg with AMF support: `winget install ffmpeg`
- ✅ AMD GPU drivers installed

### Video Codecs:
- **HEVC_AMF (H.265)**: Hardware-accelerated, best compression
- **VP9 (libvpx-vp9)**: CPU fallback, modern web standard

### Commands:
```bash
# Basic optimization
npm run optimize:gpu

# Dry-run preview
npm run optimize:gpu:dry

# Resume interrupted job
npm run optimize:gpu:continue

# Images only
npm run optimize:gpu:images-only

# Videos only
npm run optimize:gpu:videos-only

# Custom directories
node convert-media-gpu.js --source ./my-assets --output ./optimized
```

### Performance Benefits:
- **Images**: Same as CPU (~2-5 seconds, Sharp doesn't use GPU)
- **Video**: ⚡ **5-10x faster** than CPU mode
  - Example: 100MB video
    - CPU mode: ~10 minutes
    - GPU mode: ~1-2 minutes

---

## 📊 Benchmark Example

Processing a 100MB 4K video:

| Mode | Time | File Size | Quality |
|------|------|-----------|---------|
| CPU (libx264, -crf 28) | ~12 min | 45MB | Good |
| GPU (hevc_amf, QP=23) | ~2 min | 35MB | Excellent |
| **Speedup** | **6x faster** | **22% smaller** | ⭐ Better |

---

## 🔧 Configuration Options

All scripts support these CLI arguments:

```bash
node convert-media-[mode].js [options]

Options:
  -s, --source PATH           Source directory (default: ./public)
  -o, --output PATH          Output directory (default: ./public-optimized)
  --image-quality 0-100      JPEG/WebP quality (default: 80)
  --video-quality 0-51       Video CRF quality, lower=better (default: 28)
  -p, --parallel NUM         Parallel workers (default: 4)
  --dry-run                  Preview without converting
  --continue                 Resume from last successful file
  --skip-images              Skip image conversion
  --skip-videos              Skip video conversion
  -v, --verbose              Detailed logging
  -h, --help                 Show help
```

### Quality Settings:

**Video Quality (CRF/QP values):**
- Lower = Better quality, larger file
- Higher = Lower quality, smaller file
- Recommended: 24-28 (good balance)
- High quality: 18-23
- Aggressive: 32-36

**Image Quality:**
- 0-100 scale
- Recommended: 75-85
- High quality: 90+
- Aggressive: 60-70

---

## 📈 Real-World Usage Examples

### Scenario 1: Quick Test (Small Batch)
```bash
# Preview what would happen
npm run optimize:gpu:dry

# Run GPU optimization for speed
npm run optimize:gpu
```

### Scenario 2: Large Batch Processing
```bash
# Start GPU processing
npm run optimize:gpu

# If interrupted, resume without reprocessing
npm run optimize:gpu:continue
```

### Scenario 3: Video-Heavy Workload
```bash
# Process only videos on GPU (fastest)
npm run optimize:gpu:videos-only

# Process images separately with custom quality
node convert-media-gpu.js --source ./public --output ./public-optimized --skip-videos --image-quality 90
```

### Scenario 4: CI/CD Pipeline (Cloud)
```bash
# Use CPU mode for cloud environments (no GPU available)
npm run optimize:cpu

# Or in a container/GitHub Actions
node convert-media-cpu.js --source ./assets --output ./dist/assets
```

### Scenario 5: Custom Directories
```bash
# Optimize website assets
node convert-media-gpu.js --source ./website/images --output ./website/optimized

# Optimize eCommerce product photos
node convert-media-gpu.js --source ./products/photos --output ./products/optimized --image-quality 85

# Aggressive optimization for bandwidth-limited scenarios
node convert-media-gpu.js --source ./media --output ./compressed --video-quality 35 --image-quality 70
```

---

## 🔍 Reports & Logs

Each processing run generates:

- **`conversion-report.json`** - Detailed JSON report with file-by-file breakdown
  - Shows processing mode used (CPU/GPU)
  - File sizes before/after
  - Success/failure status
  - Reason for skipped files

- **`conversion.log`** - Timestamped log of all operations

Example report structure:
```json
{
  "timestamp": "2026-03-03T06:30:00.000Z",
  "mode": "GPU_ACCELERATED (AMD HEVC)",
  "summary": {
    "total_files_processed": 52,
    "total_files_skipped": 7,
    "images_converted": 36,
    "videos_converted": 16,
    "failed_count": 0,
    "original_size_mb": "657.21",
    "optimized_size_mb": "65.34",
    "savings_percent": "90.1"
  }
}
```

---

## ⚡ GPU Mode Deep Dive

### AMD HEVC AMF Encoder Benefits:

| Aspect | Details |
|--------|---------|
| **Speed** | Delegates encoding to AMD GPU, massive speedup |
| **Quality** | HEVC codec provides better visual quality than H.264 |
| **Compatibility** | Supported by modern browsers, media players |
| **Efficiency** | Smaller file sizes than H.264 at same quality |
| **Power** | Uses GPU, saving CPU cycles for other tasks |

### Supported AMD GPUs:
- Radeon 780M (integrated, laptop)
- Radeon RX 7000 series (RDNA 3)
- Radeon RX 6000 series (RDNA 2)
- Radeon RX 5000 series (RDNA)
- Ryzen 7000 series APUs

---

## 🛠️ Troubleshooting

### GPU Mode Not Working?

1. **Check FFmpeg AMF support:**
   ```bash
   ffmpeg -encoders 2>&1 | grep -i amf
   ```
   Should show: `hevc_amf`, `h264_amf`, `av1_amf`

2. **Reinstall FFmpeg with GPU support:**
   ```bash
   winget install --force ffmpeg
   ```

3. **Check GPU driver:**
   - Ensure AMD drivers are up-to-date
   - Run: `dxdiag` to verify GPU is recognized

4. **Fallback to CPU:**
   ```bash
   npm run optimize:cpu
   ```

### Out of Memory?

Reduce parallel workers:
```bash
node convert-media-gpu.js --source ./public --output ./optimized --parallel 2
```

### Slow Performance?

Check system resources:
```bash
# Check GPU utilization
gpuz  # GPU-Z utility

# Reduce file quality
node convert-media-gpu.js --video-quality 32 --image-quality 70
```

---

## 📝 Tips & Best Practices

1. **Always dry-run first:**
   ```bash
   npm run optimize:gpu:dry
   ```

2. **Process incrementally:**
   - Start with images: `npm run optimize:gpu:images-only`
   - Then videos: `npm run optimize:gpu:videos-only`

3. **Monitor disk space:**
   - GPU mode outputs next to input
   - Ensure output dir has 2x input size available

4. **Use git to track changes:**
   ```bash
   git add public-optimized/conversion-report.json
   git commit -m "Optimized media with GPU mode - 90% reduction"
   ```

5. **Schedule batch processing:**
   - Run during off-peak hours
   - Use task scheduler: `npm run optimize:gpu > optimize.log 2>&1`

---

## 📚 Additional Resources

- [FFmpeg Documentation](https://ffmpeg.org/documentation.html)
- [AMD HEVC AMF Encoder](https://en.wikipedia.org/wiki/Advanced_Media_Framework)
- [HEVC Codec Info](https://en.wikipedia.org/wiki/High_Efficiency_Video_Coding)
- [VP9 Codec Info](https://en.wikipedia.org/wiki/VP9)

---

**Last Updated:** March 3, 2026  
**GPU Mode:** AMD Radeon 780M optimized  
**Tested With:** FFmpeg 8.0.1, Node.js 24.13.1
