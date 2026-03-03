#!/usr/bin/env node

import fs from 'fs';
import path from 'path';

/**
 * Generate srcset attributes and HTML for responsive images
 * Creates responsive image variants and generates HTML code
 * Usage: node generate-srcset.js <image-path> [output-dir]
 */

const RESPONSIVE_SIZES = {
  thumbnail: { width: 150, height: 150, description: 'Thumbnail (150px)' },
  small: { width: 320, height: 240, description: 'Mobile (320px)' },
  medium: { width: 640, height: 480, description: 'Tablet (640px)' },
  large: { width: 1024, height: 768, description: 'Desktop (1024px)' },
  xlarge: { width: 1920, height: 1440, description: 'High-res (1920px)' },
};

function generateSrcsetConfig(imagePath) {
  const ext = path.extname(imagePath);
  const name = imagePath.replace(ext, '');
  
  const srcset = Object.entries(RESPONSIVE_SIZES)
    .map(([key, { width }]) => `${name}-w${width}${ext} ${width}w`)
    .join(', ');

  const sizes = '(max-width: 640px) 100vw, (max-width: 1024px) 50vw, 33vw';

  return { srcset, sizes, name, ext };
}

function generateHTMLSnippet(imagePath) {
  const { srcset, sizes, name } = generateSrcsetConfig(imagePath);
  const fallback = imagePath.replace('.webp', '.png');

  return \`<!-- Responsive Image with WebP + Fallback -->
<picture>
  <source 
    srcset="\${srcset}" 
    sizes="\${sizes}" 
    type="image/webp">
  <img 
    src="\${fallback}" 
    alt="Image description" 
    class="responsive-image"
    loading="lazy"
    decoding="async">
</picture>

<!-- CSS -->
<style>
  .responsive-image {
    max-width: 100%;
    height: auto;
    display: block;
  }
</style>\`;
}

function generateLazyLoadHTML(imagePath) {
  const { srcset, sizes, name } = generateSrcsetConfig(imagePath);
  const fallback = imagePath.replace('.webp', '.png');

  return \`<!-- Lazy-loaded responsive image -->
<img 
  src="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 1200 800'%3E%3C/svg%3E"
  data-src="\${fallback}"
  data-srcset="\${srcset}"
  sizes="\${sizes}"
  alt="Image description"
  class="lazy-image"
  loading="lazy"
  decoding="async">

<script>
  // Lazy load with fallback
  document.querySelectorAll('.lazy-image').forEach(img => {
    img.addEventListener('load', () => {
      img.classList.add('loaded');
    });
    
    if ('IntersectionObserver' in window) {
      const observer = new IntersectionObserver((entries) => {
        if (entries[0].isIntersecting) {
          img.src = img.dataset.src;
          img.srcset = img.dataset.srcset;
          observer.unobserve(img);
        }
      });
      observer.observe(img);
    } else {
      img.src = img.dataset.src;
      img.srcset = img.dataset.srcset;
    }
  });
</script>\`;
}

function generateNextImageCode(imagePath) {
  const { srcset, sizes, name } = generateSrcsetConfig(imagePath);

  return \`import Image from 'next/image';

export default function ResponsiveImage() {
  return (
    <Image
      src="\${imagePath}"
      alt="Image description"
      sizes="\${sizes}"
      srcSet="\${srcset}"
      responsive
      width={1200}
      height={800}
      priority={false}
    />
  );
}\`;
}

// Main
const imagePath = process.argv[2];
const outputDir = process.argv[3] || '.';

if (!imagePath) {
  console.log(\`
╔════════════════════════════════════════════╗
║   Responsive Image Srcset Generator        ║
╚════════════════════════════════════════════╝

Usage: node generate-srcset.js <image-path> [output-dir]

Examples:
  node generate-srcset.js /images/hero.webp
  node generate-srcset.js /images/logo.png ./html-snippets

Generates:
  • srcset and sizes attributes
  • HTML snippets with WebP + fallback
  • Lazy-loading code
  • Next.js Image component code
\`);
  process.exit(0);
}

const { srcset, sizes, name } = generateSrcsetConfig(imagePath);

Console.log(\`
╔════════════════════════════════════════════╗
║   Image: \${path.basename(imagePath).padEnd(30)} ║
╚════════════════════════════════════════════╝
\`);

console.log(\`Srcset:\n\${srcset}\n\`);
console.log(\`Sizes:\n\${sizes}\n\`);

console.log('────────────────────────────────────────────');
console.log('HTML Snippet (Responsive Picture):');
console.log('────────────────────────────────────────────\n');
console.log(generateHTMLSnippet(imagePath));

console.log('\n────────────────────────────────────────────');
console.log('Lazy Load HTML:');
console.log('────────────────────────────────────────────\n');
console.log(generateLazyLoadHTML(imagePath));

console.log('\n────────────────────────────────────────────');
console.log('Next.js Image Component:');
console.log('────────────────────────────────────────────\n');
console.log(generateNextImageCode(imagePath));

// Save HTML snippets to file if output dir specified
if (outputDir !== '.') {
  if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
  }

  const htmlFile = path.join(
    outputDir,
    \`\${path.basename(name)}-responsive.html\`
  );
  
  const htmlContent = \`<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Responsive Image - \${path.basename(imagePath)}</title>
  <style>
    body { font-family: system-ui; padding: 2rem; max-width: 1200px; margin: 0 auto; }
    h1 { color: #333; }
    .example { margin: 2rem 0; padding: 1rem; background: #f5f5f5; border-radius: 8px; }
    code { background: #222; color: #0f0; padding: 0.2rem 0.4rem; border-radius: 3px; font-size: 0.9em; }
    pre { background: #222; color: #0f0; padding: 1rem; border-radius: 8px; overflow-x: auto; }
    img.responsive { max-width: 100%; height: auto; }
  </style>
</head>
<body>
  <h1>Responsive Image Examples</h1>
  <p>Image: <code>\${path.basename(imagePath)}</code></p>
  
  <div class="example">
    <h2>Picture Element (Recommended)</h2>
    \${generateHTMLSnippet(imagePath).replace(/</g, '&lt;').replace(/>/g, '&gt;')}
    
    <h3>Preview:</h3>
    \${generateHTMLSnippet(imagePath)}
  </div>
  
  <div class="example">
    <h2>Lazy Loading</h2>
    <pre>\${generateLazyLoadHTML(imagePath).replace(/</g, '&lt;').replace(/>/g, '&gt;')}</pre>
  </div>

  <div class="example">
    <h2>Next.js Image Component</h2>
    <pre>\${generateNextImageCode(imagePath).replace(/</g, '&lt;').replace(/>/g, '&gt;')}</pre>
  </div>
</body>
</html>\`;

  fs.writeFileSync(htmlFile, htmlContent);
  console.log(\`\n✅ HTML snippets saved to: \${htmlFile}\`);
}
