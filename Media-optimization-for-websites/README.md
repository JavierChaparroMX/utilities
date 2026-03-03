# Media Optimization Script

A comprehensive, production-ready batch media optimization script that automatically converts images and videos to optimal formats with smaller filesizes while maintaining acceptable visual quality.

## Features

✨ **Image Optimization**
- Convert JPG, PNG, GIF to WebP (primary) + PNG (fallback)
- Automatic quality detection and adjustment
- Animated GIF to video conversion
- Skips already-optimized images (<100KB)

🎬 **Video Optimization**
- MP4 (H.264) and WebM (VP9) output formats
- Adaptive quality settings with CRF 28 (configurable)
- Auto-scaling for large videos (>1920px)
- Mobile variants (640px width) for responsive delivery
- Skips small videos (<2MB)

⚡ **Performance**
- Parallel processing with configurable workers (default: 4)
- Progress bar with real-time status
- Efficient resource usage with streaming

📊 **Reporting**
- Structured JSON report with conversion metrics
- Size reduction calculations (% saved)
- Error tracking and detailed logging
- Conversion state management for resuming

🛠️ **Flexibility**
- Dry-run mode to preview without converting
- Continue flag to resume interrupted conversions
- Per-format quality controls
- Skip specific file types (images/videos only)

## Installation

### Prerequisites
- **Node.js** 18+ ([Download](https://nodejs.org/))
- **FFmpeg** with libx264 and libvpx-vp9

#### Install FFmpeg

**Windows (via Chocolatey):**
```powershell
choco install ffmpeg
```

**Windows (via Scoop):**
```powershell
scoop install ffmpeg
```

**macOS (via Homebrew):**
```bash
brew install ffmpeg
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt-get install ffmpeg
```

**Linux (Fedora/RHEL):**
```bash
sudo dnf install ffmpeg
```

### Setup

1. **Clone or extract this script**
```bash
cd media-optimization-for-websites
```

2. **Install Node.js dependencies**
```bash
npm install
```

3. **Verify FFmpeg installation**
```bash
ffmpeg -version
ffprobe -version
```

## Usage

### Basic Usage

**Preview conversions (dry-run):**
```bash
npm run optimize:dry
```

**Start optimization:**
```bash
npm run optimize
```

**Resume previous conversion:**
```bash
npm run optimize:continue
```

### Advanced CLI

```bash
node convert-media.js [options]
```

#### Options

| Option | Alias | Type | Default | Description |
|--------|-------|------|---------|-------------|
| `--source <path>` | `-s` | string | `./public` | Source directory with media files |
| `--output <path>` | `-o` | string | `./public-optimized` | Output directory for optimized files |
| `--image-quality <0-100>` | | number | `80` | JPEG/WebP quality level |
| `--video-quality <0-51>` | | number | `28` | Video CRF (lower = higher quality) |
| `--parallel <number>` | `-p` | number | `4` | Number of parallel workers |
| `--dry-run` | | boolean | false | Preview without converting |
| `--continue` | | boolean | false | Resume from last successful file |
| `--skip-images` | | boolean | false | Skip image conversion |
| `--skip-videos` | | boolean | false | Skip video conversion |
| `--no-backup` | | boolean | false | Don't create PNG fallbacks |
| `--verbose` | `-v` | boolean | false | Enable detailed logging |

### Example Commands

```bash
# Preview what will be converted
node convert-media.js --dry-run

# High-quality video conversion (slower, better quality)
node convert-media.js --video-quality 26

# Fast conversion with 8 parallel workers
node convert-media.js --parallel 8

# Images only
npm run optimize:images-only

# Videos only
npm run optimize:videos-only

# Custom quality settings
node convert-media.js --image-quality 75 --video-quality 30

# Resume interrupted conversion
node convert-media.js --continue

# Move to custom output directory
node convert-media.js --source ./assets --output ./assets-optimized
```

## Expected Output Structure

After optimization, you'll get:

```
public-optimized/
├── images-optimized/
│   ├── company-logo.webp
│   ├── company-logo.png          (fallback)
│   ├── hero-bg.webp
│   ├── hero-bg.png
│   └── services/
│       └── service-icon.webp
│
├── videos-optimized/
│   ├── product-demo.mp4
│   ├── product-demo.webm
│   ├── product-demo-mobile.mp4
│   ├── product-demo-mobile.webm
│   └── services/
│       ├── Video-Booth360/
│       │   ├── 360-sample.mp4
│       │   ├── 360-sample.webm
│       │   ├── mobile/
│       │   │   ├── 360-sample-mobile.mp4
│       │   │   └── 360-sample-mobile.webm
│
├── conversion.log                (detailed logs)
└── conversion-report.json        (metrics & results)
```

## Reports

### conversion-report.json

Structured data with conversion metrics:

```json
{
  "timestamp": "2026-03-03T10:00:00Z",
  "summary": {
    "total_files_processed": 45,
    "total_files_skipped": 3,
    "images_converted": 30,
    "videos_converted": 15,
    "failed_count": 0,
    "original_size_mb": "2734.50",
    "optimized_size_mb": "1050.25",
    "savings_percent": "61.6"
  },
  "files": [
    {
      "original_path": "public/images/company-logo.png",
      "optimized_path": "images-optimized/company-logo.webp",
      "original_size_kb": "512.00",
      "optimized_size_kb": "128.00",
      "format": "png->webp",
      "type": "image",
      "status": "success"
    }
  ],
  "errors": []
}
```

### conversion.log

Timestamped log of all operations:

```
[2026-03-03T10:00:00.000Z] [INFO] Starting media optimization...
[2026-03-03T10:00:01.234Z] [SUCCESS] Image optimized: public/images/logo.png -> 512KB → 128KB
[2026-03-03T10:00:05.567Z] [SUCCESS] Video optimized: public/services/demo.mp4 -> 156MB → 45MB
```

## Configuration Presets

### High Quality (Slower)
```bash
node convert-media.js --image-quality 90 --video-quality 24
```

### Balanced (Default)
```bash
node convert-media.js --image-quality 80 --video-quality 28
```

### Aggressive (Faster)
```bash
node convert-media.js --image-quality 70 --video-quality 32
```

## Quality Settings Guide

### Image Quality
- **90-100**: Highest quality, minimal visible loss (larger files)
- **80-90**: Good balance (recommended for most use cases)
- **70-80**: Acceptable quality, smaller files
- **60-70**: Lower quality, small files (mobile only)
- **<60**: Minimal quality, tiny files (thumbnails only)

### Video Quality (CRF)
- **18-22**: High quality, large files (4K or archival)
- **23-28**: Good balance for delivery (recommended)
- **29-35**: Lower quality, smaller files (mobile streaming)
- **36-51**: Very low quality, minimal files (thumbnails)

## Features & Extras

### HTML Report (Coming Soon)
Generate visual before/after comparison reports:
```bash
node generate-report-html.js
```

### Responsive Images (Next.js)
Auto-generate `next.config.mjs` image optimization:
```bash
node generate-nextjs-config.js
```

### Apache Content Negotiation (.htaccess)
Auto-serve WebP with PNG fallback:
```bash
node generate-htaccess.js
```

Generate srcset for responsive images:
```bash
node generate-srcset.js
```

## Troubleshooting

### FFmpeg Not Found
```bash
# macOS
brew install ffmpeg

# Windows (via Chocolatey)
choco install ffmpeg

# Linux
sudo apt-get install ffmpeg
```

### Out of Memory
Reduce parallel workers:
```bash
node convert-media.js --parallel 2
```

### Video Conversion Too Slow
Use faster preset (lower quality):
```bash
node convert-media.js --video-quality 32
```

### WebP Not Supported
PNG fallbacks are created automatically. Update your HTML:
```html
<picture>
  <source srcset="image.webp" type="image/webp">
  <img src="image.png" alt="description">
</picture>
```

## Performance Benchmarks

Typical conversion rates (on modern hardware):
- **Images**: 5-10 images/second
- **Videos**: 1-3 videos/minute (depends on quality settings)
- **Typical project** (30 images + 10 videos): 5-15 minutes

Size reductions:
- **JPEG → WebP**: 30-50% smaller
- **PNG → WebP**: 25-35% smaller
- **MP4 → WebM**: 30-40% smaller

## Advanced Topics

### Resume Interrupted Conversions
The script saves state in `.conversion-state.json`. To resume:
```bash
node convert-media.js --continue
```

### Custom Output Structure
Modify the `DEFAULT_CONFIG` in `convert-media.js`:
```javascript
imageDirs: {
  original: 'images-optimized'
},
videoDirs: {
  original: 'videos-optimized',
  mobile: 'videos-optimized/mobile'
}
```

### Parallel Worker Tuning
Adjust based on your system:
```bash
# Low-end systems (2-4 CPU cores)
node convert-media.js --parallel 2

# High-end systems (8+ CPU cores)
node convert-media.js --parallel 8
```

## License

MIT

## Contributing

Contributions welcome! Please ensure:
- FFmpeg is installed and working
- All dependencies are installed
- Code follows the existing style
- Errors are handled gracefully

## Support

For issues or questions:
1. Check the `conversion.log` for detailed error messages
2. Run with `--verbose` flag for more detailed output
3. Verify FFmpeg installation: `ffmpeg -version`
4. Check available disk space

---

**Happy optimizing!** 🚀
