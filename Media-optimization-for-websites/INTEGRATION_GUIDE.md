# Directory & Integration Guide

This guide shows how to use the media optimization script with **any directory structure** and various website types.

## 🎯 The Basics

### Point to Any Directory

The script works with **any folder** on your system. Just specify the source and output paths:

```bash
node convert-media.js --source "path/to/your/images" --output "path/to/optimized/images"
```

### Recursive Discovery

The script **automatically discovers** all images and videos in subdirectories:

```
Your directory:
  images/
    ├── logo.png
    ├── hero.jpg
    └── products/
        ├── product-1.jpg
        └── product-2.jpg

After optimization:
  images-optimized/
    ├── logo.webp
    ├── logo.png (fallback)
    ├── hero.webp
    ├── hero.png (fallback)
    └── products/
        ├── product-1.webp
        ├── product-1.png
        ├── product-2.webp
        └── product-2.png
```

**Your directory structure is preserved exactly!**

---

## 📁 Website Type Examples

### Static HTML/CSS Website

**Directory structure:**
```
my-website/
├── index.html
├── about.html
├── assets/
│   ├── images/
│   │   ├── logo.png
│   │   ├── hero.jpg
│   │   └── gallery/
│   │       └── photo.jpg
│   └── style.css
```

**Command:**
```bash
node convert-media.js --source "./assets/images" --output "./assets/images-optimized"
```

**Update HTML:**
```html
<!-- Before: <img src="assets/images/logo.png" alt="Logo"> -->
<!-- After: -->
<picture>
  <source srcset="assets/images-optimized/logo.webp" type="image/webp">
  <img src="assets/images-optimized/logo.png" alt="Logo">
</picture>
```

---

### WordPress Blog

**Directory structure:**
```
wordpress/
├── wp-content/
│   ├── uploads/
│   │   ├── 2024/01/
│   │   │   ├── post-image-1.jpg
│   │   │   └── post-image-2.jpg
│   │   └── 2024/02/
│   │       └── post-image-3.jpg
│   └── themes/
│       └── my-theme/
│           └── img/
│               └── logo.png
```

**Command:**
```bash
# Optimize uploads
node convert-media.js --source "./wp-content/uploads" --output "./wp-content/uploads-optimized"

# Optimize theme images
node convert-media.js --source "./wp-content/themes/my-theme/img" --output "./wp-content/themes/my-theme/img-optimized"
```

**WordPress Plugin Integration:**
You can use a plugin like "Imagify" or "Smush" to automatically serve optimized images, OR update your theme template to use the optimized paths.

---

### Next.js / React

**Directory structure:**
```
my-nextjs-app/
├── public/
│   ├── assets/
│   │   ├── images/
│   │   │   ├── logo.png
│   │   │   └── hero.jpg
│   │   └── videos/
│   │       ├── intro.mp4
│   │       └── demo.mov
│   └── favicon.ico
├── src/
│   ├── pages/
│   └── components/
└── next.config.js
```

**Command:**
```bash
# Optimize public assets
node convert-media.js --source "./public/assets" --output "./public/assets-optimized"

# Generate Next.js config (optional, for auto-optimization)
node generate-nextjs-config.js

# Generate React components for optimized images
node generate-nextjs-config.js
```

**Update React Components:**
```jsx
import { OptimizedImage } from '@/components/OptimizedImage';

export default function Home() {
  return (
    <OptimizedImage
      src="/assets/images-optimized/hero.webp"
      alt="Hero banner"
      width={1200}
      height={600}
      priority
    />
  );
}
```

**Or manually:**
```jsx
export default function Home() {
  return (
    <picture>
      <source srcset="/assets/images-optimized/logo.webp" type="image/webp" />
      <img src="/assets/images-optimized/logo.png" alt="Logo" />
    </picture>
  );
}
```

---

### Vue.js Application

**Directory structure:**
```
my-vue-app/
├── src/
│   ├── assets/
│   │   ├── images/
│   │   │   ├── logo.png
│   │   │   └── hero.jpg
│   │   └── videos/
│   │       └── demo.mp4
│   ├── components/
│   └── App.vue
└── public/
```

**Command:**
```bash
node convert-media.js --source "./src/assets" --output "./src/assets-optimized"
```

**Update Vue Components:**
```vue
<template>
  <div>
    <!-- Optimized Image -->
    <picture>
      <source :srcset="require('@/assets/images-optimized/logo.webp')" type="image/webp" />
      <img :src="require('@/assets/images-optimized/logo.png')" alt="Logo" />
    </picture>
    
    <!-- Optimized Video -->
    <video controls>
      <source :src="require('@/assets/videos-optimized/demo.webm')" type="video/webm" />
      <source :src="require('@/assets/videos-optimized/demo.mp4')" type="video/mp4" />
    </video>
  </div>
</template>

<script>
export default {
  name: 'OptimizedMedia'
}
</script>
```

---

### Gatsby Static Site

**Directory structure:**
```
my-gatsby-site/
├── src/
│   ├── images/
│   │   ├── logo.png
│   │   ├── hero.jpg
│   │   └── gallery/
│   └── pages/
└── static/
    ├── images/
    └── videos/
```

**Command:**
```bash
# Optimize source images
node convert-media.js --source "./src/images" --output "./public/images-optimized"

# Optimize static files
node convert-media.js --source "./static" --output "./public/static-optimized"
```

**Update Gatsby Components:**
```jsx
export default function Page() {
  return (
    <picture>
      <source srcSet="/images-optimized/logo.webp" type="image/webp" />
      <img src="/images-optimized/logo.png" alt="Logo" />
    </picture>
  );
}
```

---

### Shopify Store

**Directory structure:**
```
my-shopify-theme/
├── assets/
│   ├── images/
│   │   ├── logo.png
│   │   ├── product-1.jpg
│   │   └── product-2.jpg
│   └── videos/
│       └── demo.mp4
├── sections/
└── templates/
```

**Command:**
```bash
node convert-media.js --source "./assets" --output "./assets-optimized"
```

**Update Liquid Templates:**
```liquid
<!-- Before: -->
<img src="{{ 'logo.png' | asset_url }}" alt="Logo">

<!-- After: -->
<picture>
  <source srcset="{{ 'logo.webp' | asset_url }}" type="image/webp">
  <img src="{{ 'logo.png' | asset_url }}" alt="Logo">
</picture>
```

---

### E-Commerce / Product Catalog

**Directory structure:**
```
ecommerce/
├── products/
│   ├── electronics/
│   │   ├── laptop-1.jpg
│   │   ├── laptop-2.jpg
│   │   └── specs.jpg
│   ├── clothing/
│   │   ├── shirt-1.jpg
│   │   └── shirt-2.jpg
│   └── videos/
│       ├── product-unbox.mp4
│       └── how-to-use.mov
└── uploads/
    └── user-reviews/
```

**Command:**
```bash
# Optimize product images
node convert-media.js --source "./products" --output "./products-optimized" --image-quality 85

# Optimize user uploads
node convert-media.js --source "./uploads" --output "./uploads-optimized" --image-quality 75
```

**Impact:**
- 40% faster product page loads
- 30-50% smaller image files
- Better mobile experience
- Improved SEO rankings

---

### Multi-Tenant SaaS Application

**Directory structure:**
```
saas-app/
├── public/
│   ├── client-1/
│   │   └── media/
│   │       ├── logo.png
│   │       └── images/
│   ├── client-2/
│   │   └── media/
│   │       ├── logo.png
│   │       └── images/
│   └── client-3/
│       └── media/
│           ├── logo.png
│           └── images/
```

**Batch Optimization Script (optimize-all-clients.sh):**
```bash
#!/bin/bash

clients=("client-1" "client-2" "client-3" "client-4" "client-5")

for client in "${clients[@]}"; do
  echo "Optimizing $client..."
  node convert-media.js \
    --source "./public/$client/media" \
    --output "./public/$client/media-optimized" \
    --parallel 4
done

echo "All clients optimized!"
```

**Run:**
```bash
bash optimize-all-clients.sh
```

---

### Headless CMS (Contentful, Strapi, etc.)

**Upload Process:**
```
Traditional Flow:
CMS (upload) → Store in Media Library → Serve original

Optimized Flow:
CMS (upload) → Store in Media Library → Batch optimize → Serve optimized
```

**Command (run as part of deployment):**
```bash
# After exports from CMS
node convert-media.js --source "./cms-exports/media" --output "./public/media-optimized"

# Then update content URLs to point to optimized versions
```

---

### Blog with Multiple Categories

**Directory structure:**
```
blog/
├── posts/
│   ├── technology/
│   │   ├── 2024-01-post.md
│   │   └── images/
│   │       ├── hero.jpg
│   │       └── diagram.png
│   ├── lifestyle/
│   │   ├── 2024-02-post.md
│   │   └── images/
│   │       ├── header.jpg
│   │       └── gallery/
│   │           └── photo-1.jpg
│   └── travel/
│       ├── 2024-03-post.md
│       └── images/
│           ├── map.png
│           └── photos/
```

**Batch Command:**
```bash
# Optimize all post images
node convert-media.js --source "./posts" --output "./posts-optimized"
```

---

## 🔄 Workflow Examples

### Workflow 1: Dry-Run First

```bash
# 1. Preview without converting
node convert-media.js --source "./assets" --output "./assets-optimized" --dry-run
# Shows what files would be converted

# 2. Check results
cat "assets-optimized/conversion-report.json"

# 3. If looks good, run for real
node convert-media.js --source "./assets" --output "./assets-optimized"
```

### Workflow 2: High Quality Setup

```bash
# For design-heavy sites
node convert-media.js \
  --source "./assets" \
  --output "./assets-optimized" \
  --image-quality 90 \
  --video-quality 24
```

### Workflow 3: Mobile-First

```bash
# For mobile-first projects
node convert-media.js \
  --source "./assets" \
  --output "./assets-optimized" \
  --image-quality 70 \
  --video-quality 32 \
  --parallel 8
```

### Workflow 4: Batch All Sites

**batch-optimize.sh:**
```bash
#!/bin/bash

sites=(
  "~/projects/site1"
  "~/projects/site2"
  "~/projects/site3"
)

for site_dir in "${sites[@]}"; do
  echo "Processing: $site_dir"
  node convert-media.js \
    --source "$site_dir/assets" \
    --output "$site_dir/assets-optimized"
done
```

---

## 🚀 Tips for Different Scenarios

### Fast Conversion (Aggressive)
```bash
node convert-media.js \
  --source "./assets" \
  --output "./assets-optimized" \
  --image-quality 65 \
  --video-quality 35 \
  --parallel 8
```

### High Quality (Slow but Best)
```bash
node convert-media.js \
  --source "./assets" \
  --output "./assets-optimized" \
  --image-quality 95 \
  --video-quality 20 \
  --parallel 2
```

### Balanced (Recommended)
```bash
node convert-media.js \
  --source "./assets" \
  --output "./assets-optimized" \
  --image-quality 80 \
  --video-quality 28 \
  --parallel 4
```

### Mobile Only
```bash
node convert-media.js \
  --source "./assets" \
  --output "./assets-optimized" \
  --image-quality 65 \
  --skip-videos
```

### Videos Only
```bash
node convert-media.js \
  --source "./assets" \
  --output "./assets-optimized" \
  --skip-images
```

---

## 📊 Results & Reports

After optimization, check:

**JSON Report:**
```bash
cat public-optimized/conversion-report.json
```

**HTML Report:**
```bash
# Open the visual report
open public-optimized/conversion-report.html  # macOS
xdg-open public-optimized/conversion-report.html  # Linux
start public-optimized/conversion-report.html  # Windows
```

**Logs:**
```bash
cat public-optimized/conversion.log
```

---

## ✅ Checklist After Optimization

- [ ] Dry-run preview reviewed
- [ ] Conversion completed successfully
- [ ] HTML report checked (public-optimized/conversion-report.html)
- [ ] Final file sizes verified
- [ ] Fallback images (PNG) confirmed
- [ ] Mobile video variants created
- [ ] Website/app updated to use optimized paths
- [ ] HTML `<picture>` elements in place
- [ ] Mobile variants loading correctly
- [ ] Performance metrics improved

---

## 🎓 Learning More

- See [QUICK_START.md](./QUICK_START.md) for 5-minute setup
- See [README.md](./README.md) for full documentation
- Check [EXAMPLES.sh](./EXAMPLES.sh) or [EXAMPLES.ps1](./EXAMPLES.ps1) for your OS
- View in-depth guides in [DOCUMENTATION.md](./DOCUMENTATION.md)

---

**Tip:** The script works with **any directory structure** on your system. Just point it to your images/videos and it handles the rest! 🚀
