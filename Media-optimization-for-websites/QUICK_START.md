# Quick Start Guide

Get up and running with media optimization in 5 minutes!

## 1. Prerequisites Check

```bash
# Verify Node.js is installed
node --version    # Should be v18 or higher

# Verify FFmpeg is installed
ffmpeg -version   # Should show version information
ffprobe -version  # Should show version information
```

### If FFmpeg is missing:

**Windows (Chocolatey):**
```bash
choco install ffmpeg
```

**macOS (Homebrew):**
```bash
brew install ffmpeg
```

**Linux (Ubuntu):**
```bash
sudo apt-get update && sudo apt-get install ffmpeg
```

---

## 2. Installation

```bash
# Navigate to the script directory
cd media-optimization-for-websites

# Install Node.js dependencies
npm install

# Verify installation
npm list
```

---

## 3. Run Your First Conversion

### Step 1: Preview (Dry-Run)
```bash
npm run optimize:dry
```

This shows what files will be converted without actually processing them.

### Step 2: Start Optimization
```bash
npm run optimize
```

This converts all images and videos in `./public` to `./public-optimized`.

---

## 🎯 Using with Any Directory

The script works with **any folder structure**. Just point it to your directory:

```bash
# Convert files from any directory
node convert-media.js --source "path/to/your/media" --output "path/to/optimized"
```

### Real-World Examples

**E-Commerce Site:**
```bash
node convert-media.js --source ./website/assets/products --output ./website/assets/products-optimized
```

**Blog/News Content:**
```bash
node convert-media.js --source ./content/posts/images --output ./content/posts/images-optimized
```

**Full Website Assets:**
```bash
node convert-media.js --source ./public --output ./public-optimized
```

**Windows Paths:**
```powershell
node convert-media.js --source "C:\Users\yourname\Pictures\website-photos" --output "C:\Users\yourname\Pictures\website-photos-optimized"
```

**Network Drives:**
```bash
node convert-media.js --source "\\server\shared\media" --output "\\server\shared\media-optimized"
```

**Deep Nested Structure:**
```bash
node convert-media.js --source ./src/components/Hero/images --output ./src/components/Hero/images-optimized
```

### How It Works

The script **automatically discovers** all image and video files by recursively scanning the source directory:

```
Your Directory Structure:
┌─ images/
│  ├─ logo.png
│  ├─ hero.jpg
│  └─ gallery/
│     ├─ photo-1.jpg
│     └─ photo-2.png
│
└─ videos/
   ├─ intro.mp4
   ├─ demo.mov
   └─ testimonials/
      └─ client-1.mp4

Result (Auto-Created):
┌─ images-optimized/
│  ├─ logo.webp
│  ├─ logo.png (fallback)
│  ├─ hero.webp
│  ├─ hero.png (fallback)
│  └─ gallery/
│     ├─ photo-1.webp
│     ├─ photo-1.png
│     ├─ photo-2.webp
│     └─ photo-2.png
│
└─ videos-optimized/
   ├─ intro.mp4
   ├─ intro.webm
   ├─ intro-mobile.mp4
   ├─ demo.mp4
   ├─ demo.webm
   ├─ demo-mobile.mp4
   └─ testimonials/
      ├─ client-1.mp4
      ├─ client-1.webm
      └─ mobile/
         ├─ client-1-mobile.mp4
         └─ client-1-mobile.webm
```

### Preserve Directory Structure?

Yes! Subdirectories are preserved exactly:
```bash
# Original structure
source/
├── images/
│   └── products/
│       └── item.jpg

# Result structure (same hierarchy)
output/
├── images/
│   └── products/
│       └── item.webp
```

---

## 4. Check Results

After conversion completes, you'll find:

```
public-optimized/
├── conversion-report.json      ← Metrics & detailed results
├── conversion.log              ← Processing logs
├── images-optimized/           ← Converted images (.webp)
│   ├── company-logo.webp
│   ├── company-logo.png        ← PNG fallback
│   └── ...
└── videos-optimized/           ← Converted videos (MP4 + WebM)
    ├── product-demo.mp4
    ├── product-demo.webm
    ├── mobile/                 ← Mobile variants (640px width)
    │   ├── product-demo-mobile.mp4
    │   └── product-demo-mobile.webm
    └── ...
```

---

## 5. Options for Different Websites

### Website Type Examples

**WordPress Blog:**
```bash
node convert-media.js --source ./wp-content/uploads --output ./wp-content/uploads-optimized
```

**Next.js App:**
```bash
node convert-media.js --source ./public/assets --output ./public/assets-optimized
node generate-nextjs-config.js  # Also set up Next.js config
```

**Vue.js App:**
```bash
node convert-media.js --source ./src/assets --output ./src/assets-optimized
```

**Gatsby Site:**
```bash
node convert-media.js --source ./src/images --output ./public/images-optimized
```

**Shopify:**
```bash
node convert-media.js --source ./theme/assets/images --output ./theme/assets/images-optimized
```

**Multi-Tenant App:**
```bash
# Optimize for each client
node convert-media.js --source ./client-1/media --output ./client-1/media-optimized --parallel 4
node convert-media.js --source ./client-2/media --output ./client-2/media-optimized --parallel 4
node convert-media.js --source ./client-3/media --output ./client-3/media-optimized --parallel 4
```

---

## 6. Integration

### For Static Websites

**Replace image references:**
```html
<!-- Before -->
<img src="/public/images/logo.png" alt="Logo">

<!-- After -->
<picture>
  <source srcset="/public-optimized/images-optimized/logo.webp" type="image/webp">
  <img src="/public-optimized/images-optimized/logo.png" alt="Logo">
</picture>
```

### For Next.js

1. Generate Next.js config:
```bash
node generate-nextjs-config.js
```

2. Replace `next.config.js` with generated `next.config.mjs`

3. Use optimized image component:
```jsx
import { OptimizedImage } from '@/components/OptimizedImage';

export default function Page() {
  return (
    <OptimizedImage
      src="/images-optimized/logo.webp"
      alt="Logo"
      width={200}
      height={100}
    />
  );
}
```

### For Apache Servers

Generate `.htaccess` for automatic content negotiation:
```bash
node generate-htaccess.js
```

This automatically serves WebP to supporting browsers with PNG fallback.

---

## 7. Quality Settings

### Choose Your Profile

**Balanced (Recommended):**
```bash
npm run optimize
# image-quality: 80, video-quality: 28
```

**High Quality (For design/portfolio):**
```bash
node convert-media.js --image-quality 90 --video-quality 24
```

**Aggressive (For fast mobile):**
```bash
node convert-media.js --image-quality 70 --video-quality 32 --parallel 8
```

---

## 8. Monitor Progress

During conversion:
- **Progress bar** shows file count and completion percentage
- **Real-time feedback** with ✓, ✗, ✓ symbols
- **Duration** tracking

After completion:
- **Summary report** with total size saved and percentages
- **JSON report** with detailed file-by-file metrics
- **Log file** with timestamps and error details

---

## 9. HTML Report

View a visual before/after report:

```bash
node generate-report-html.js
# Opens: public-optimized/conversion-report.html
```

The HTML report includes:
- 📊 Visual size comparisons
- 📈 Savings percentage
- 🖼️ Image gallery preview
- 🎬 Video file listings
- ⚠️ Error summary

---

## 10. Resume Interrupted Conversions

If the script is interrupted:

```bash
npm run optimize:continue
# Skips already-converted files, continues from where it left off
```

---

## 10. Resume Interrupted Conversions

If the script is interrupted:

```bash
npm run optimize:continue
# Skips already-converted files, continues from where it left off
```

---

## 11. Troubleshooting

### "FFmpeg not found"
```bash
# Windows - Add to PATH or reinstall with chocolatey
choco install ffmpeg --force

# macOS
brew install ffmpeg

# Linux
sudo apt-get install ffmpeg
```

### "Out of memory"
```bash
# Reduce parallel workers
node convert-media.js --parallel 2
```

### "Conversion too slow"
```bash
# Use faster settings
node convert-media.js --video-quality 32 --parallel 8
```

### Check detailed logs
```bash
# View logs
cat public-optimized/conversion.log

# View report
cat public-optimized/conversion-report.json
```

---

## 12. Advanced Options

```bash
# Custom source and output directories
node convert-media.js --source ./assets --output ./assets-optimized

# Images only
npm run optimize:images-only

# Videos only
npm run optimize:videos-only

# High verbosity logging
node convert-media.js --verbose

# Skip PNG fallbacks
node convert-media.js --no-backup
```

---

## 13. Batch Processing Multiple Directories

Need to optimize multiple sites/projects? Create a batch script:

**Windows (batch-optimize.bat):**
```batch
@echo off
REM Optimize all websites

echo Optimizing Website 1...
node convert-media.js --source C:\websites\site1\public --output C:\websites\site1\public-optimized

echo Optimizing Website 2...
node convert-media.js --source C:\websites\site2\assets --output C:\websites\site2\assets-optimized

echo Optimizing Website 3...
node convert-media.js --source C:\websites\site3\images --output C:\websites\site3\images-optimized

echo All done!
pause
```

**macOS/Linux (batch-optimize.sh):**
```bash
#!/bin/bash
echo "Optimizing Website 1..."
node convert-media.js --source ~/websites/site1/public --output ~/websites/site1/public-optimized

echo "Optimizing Website 2..."
node convert-media.js --source ~/websites/site2/assets --output ~/websites/site2/assets-optimized

echo "Optimizing Website 3..."
node convert-media.js --source ~/websites/site3/images --output ~/websites/site3/images-optimized

echo "All done!"
```

Run with: `bash batch-optimize.sh` or double-click (.bat file on Windows)

---

## 14. Typical Results

After optimization, you can expect:

| Type | Format | Size Reduction | Quality Impact |
|------|--------|----------------|-----------------|
| JPEG | → WebP | 30-50% | Imperceptible |
| PNG  | → WebP | 25-35% | Imperceptible |
| MP4  | → WebM | 30-40% | Minor |
| Video| Quality 28 | - | Good balance |

**Example:**
- **Before:** 2.7 GB (45 images + 15 videos)
- **After:** 1.0 GB
- **Saved:** 61.6% (1.7 GB)

---

## 15. Next Steps

1. ✅ Run `npm run optimize:dry` to preview
2. ✅ Run `npm run optimize` to process
3. ✅ Check `conversion-report.json` for metrics
4. ✅ Update your HTML to use optimized files
5. ✅ Generate reports and configs for your framework

---

## Support & Documentation

- **README.md** - Full feature documentation
- **config.example.json** - Configuration profiles and presets
- **conversion-report.json** - Detailed conversion metrics
- **conversion.log** - Processing logs with timestamps

---

**Happy optimizing!** 🚀

For questions or issues, check the logs or run with `--verbose` flag.
