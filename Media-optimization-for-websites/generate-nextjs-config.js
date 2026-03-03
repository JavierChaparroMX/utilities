#!/usr/bin/env node

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

/**
 * Generate next.config.mjs with optimized image configuration
 * Usage: node generate-nextjs-config.js [output-path]
 */

const nextConfigContent = `/** @type {import('next').NextConfig} */
const nextConfig = {
  // Image optimization configuration
  images: {
    // Responsive image sizes for different devices
    deviceSizes: [640, 750, 828, 1080, 1200, 1920, 2048, 3840],
    imageSizes: [16, 32, 48, 64, 96, 128, 256, 384],
    
    // Supported image formats
    // WebP is primary, PNG/JPEG fallbacks
    formats: ['image/avif', 'image/webp', 'image/png', 'image/jpeg'],
    
    // Image domain whitelist (security)
    domains: [
      'localhost',
      'yourdomain.com',
      // Add your CDN or image hosting domains here
    ],
    
    // Cache configuration
    minimumCacheTTL: 31536000, // 1 year in seconds
    
    // Disable static imports if using external CDN
    unoptimized: false,
    
    // Dangerously allow data: URLs (use cautiously)
    dangerouslyAllowSVG: true,
    contentSecurityPolicy: "default-src 'self'; script-src 'none'; sandbox;",
  },

  // Responsive images configuration
  env: {
    // Image optimization settings
    NEXT_PUBLIC_IMAGE_QUALITY_DESKTOP: '80',
    NEXT_PUBLIC_IMAGE_QUALITY_MOBILE: '70',
  },

  // Webpack configuration for additional optimization
  webpack: (config, { isServer }) => {
    // Custom webpack optimizations
    return config;
  },

  // Compression settings
  compress: true,
  
  // Generate ETags for cache validation
  generateEtags: true,
  
  // Performance optimizations
  productionBrowserSourceMaps: false,
  
  // Headers for optimal delivery
  async headers() {
    return [
      {
        source: '/images-optimized/:path*',
        headers: [
          {
            key: 'Cache-Control',
            value: 'public, max-age=31536000, immutable',
          },
          {
            key: 'Content-Type',
            value: 'image/webp',
            has: [{ type: 'header', key: 'Accept', value: '.*webp.*' }],
          },
        ],
      },
      {
        source: '/videos-optimized/:path*',
        headers: [
          {
            key: 'Cache-Control',
            value: 'public, max-age=2592000', // 30 days
          },
          {
            key: 'Accept-Ranges',
            value: 'bytes',
          },
        ],
      },
    ];
  },

  // Rewrites for content negotiation
  async rewrites() {
    return {
      beforeFiles: [
        {
          source: '/images-optimized/:path*',
          destination: '/images-optimized/:path*',
        },
        {
          source: '/videos-optimized/:path*',
          destination: '/videos-optimized/:path*',
        },
      ],
    };
  },

  // Environment variables
  env: {
    // Image optimization quality levels
    NEXT_PUBLIC_IMAGE_QUALITY: '80',
  },
};

export default nextConfig;
`;

const nextImageComponentContent = `"use client";

import NextImage from 'next/image';
import { useState } from 'react';

/**
 * Optimized Image Component
 * Automatically handles WebP with fallbacks
 * Usage: <OptimizedImage src="..." alt="..." />
 */

export function OptimizedImage({
  src,
  alt,
  width,
  height,
  priority = false,
  className = '',
  ...props
}) {
  const [isLoading, setIsLoading] = useState(true);
  const [hasError, setHasError] = useState(false);

  // Convert image paths to WebP if not already
  let imageSrc = src;
  if (!imageSrc.startsWith('/') && !imageSrc.startsWith('http')) {
    imageSrc = '/' + imageSrc;
  }

  // Use WebP path if available
  if (!imageSrc.includes('.webp') && imageSrc.match(/\\.(jpg|jpeg|png)$/i)) {
    imageSrc = imageSrc.replace(/\\.(jpg|jpeg|png)$/i, '.webp');
  }

  return (
    <div className={\`relative \${className}\`}>
      <NextImage
        src={imageSrc}
        alt={alt}
        width={width}
        height={height}
        priority={priority}
        quality={80}
        onLoadingComplete={() => setIsLoading(false)}
        onError={() => {
          setHasError(true);
          setIsLoading(false);
        }}
        className={\`transition-opacity duration-300 \${isLoading ? 'opacity-0' : 'opacity-100'}\`}
        {...props}
      />
      
      {isLoading && (
        <div className="absolute inset-0 bg-gray-200 animate-pulse rounded" />
      )}
      
      {hasError && (
        <div className="absolute inset-0 bg-gray-100 flex items-center justify-center text-gray-500">
          <span>Image failed to load</span>
        </div>
      )}
    </div>
  );
}

/**
 * Picture component for enhanced compatibility
 * Manually specify WebP + PNG fallback
 */

export function PictureImage({
  webpSrc,
  fallbackSrc,
  alt,
  className = '',
  ...props
}) {
  return (
    <picture>
      <source srcSet={webpSrc} type="image/webp" />
      <img
        src={fallbackSrc}
        alt={alt}
        className={className}
        {...props}
      />
    </picture>
  );
}

/**
 * Video component with multiple formats
 * Serves MP4 primarily, WebM fallback
 */

export function OptimizedVideo({
  src,
  mobileVariant = null,
  poster = '',
  className = '',
  ...props
}) {
  const [isMobile, setIsMobile] = useState(false);

  const videoSrc = isMobile && mobileVariant ? mobileVariant : src;

  return (
    <video
      poster={poster}
      className={className}
      {...props}
    >
      <source src={videoSrc.replace(/\\.mp4$/, '.webm')} type="video/webm" />
      <source src={videoSrc} type="video/mp4" />
      Your browser does not support the video tag.
    </video>
  );
}
`;

const srcsetGeneratorContent = `#!/usr/bin/env node

import fs from 'fs';
import path from 'path';

/**
 * Generate srcset attributes for responsive images
 * Usage: node generate-srcset.js <image-path>
 */

const SIZES = [640, 750, 828, 1080, 1200, 1920];

function generateSrcset(imagePath) {
  const ext = path.extname(imagePath);
  const name = imagePath.replace(ext, '');
  
  return SIZES
    .map(size => \`\${name}-w\${size}\${ext} \${size}w\`)
    .join(', ');
}

function generateSizes() {
  return '(max-width: 750px) 100vw, (max-width: 1200px) 50vw, 33vw';
}

// Example usage
if (process.argv[2]) {
  const srcset = generateSrcset(process.argv[2]);
  const sizes = generateSizes();
  
  console.log('srcset:', srcset);
  console.log('sizes:', sizes);
  
  console.log('\\nHTML example:');
  console.log(\`<img\`);
  console.log(\`  src="\${process.argv[2]}"\`);
  console.log(\`  srcset="\${srcset}"\`);
  console.log(\`  sizes="\${sizes}"\`);
  console.log(\`  alt="Description"\`);
  console.log(\`/>\`);
} else {
  console.log('Usage: node generate-srcset.js <image-path>');
  console.log('Example: node generate-srcset.js /images/hero.webp');
}
`;

function generateNextConfig(outputPath = './next.config.mjs') {
  fs.writeFileSync(outputPath, nextConfigContent, 'utf8');
  console.log(`✅ Next.js config generated: ${outputPath}`);
}

function generateImageComponent(outputPath = './components/OptimizedImage.jsx') {
  const dir = path.dirname(outputPath);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
  
  fs.writeFileSync(outputPath, nextImageComponentContent, 'utf8');
  console.log(`✅ Image component generated: ${outputPath}`);
}

function generateSrcsetGenerator(outputPath = './scripts/generate-srcset.js') {
  const dir = path.dirname(outputPath);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
  
  fs.writeFileSync(outputPath, srcsetGeneratorContent, 'utf8');
  console.log(`✅ Srcset generator generated: ${outputPath}`);
}

// Main
console.log('🚀 Generating Next.js optimization files...\n');

generateNextConfig();
generateImageComponent();
generateSrcsetGenerator();

console.log(\`
📝 Next Steps:
1. Replace your next.config.js with the generated next.config.mjs
2. Update image imports to use OptimizedImage component
3. Run: npm run dev

💡 Usage examples:

// Using OptimizedImage component
import { OptimizedImage } from '@/components/OptimizedImage';

export default function Page() {
  return (
    <OptimizedImage
      src="/images-optimized/hero.webp"
      alt="Hero banner"
      width={1200}
      height={600}
      priority
    />
  );
}

// Using Picture element for better control
import { PictureImage } from '@/components/OptimizedImage';

export default function Page() {
  return (
    <PictureImage
      webpSrc="/images-optimized/hero.webp"
      fallbackSrc="/images-optimized/hero.png"
      alt="Hero banner"
      className="w-full"
    />
  );
}

// Using OptimizedVideo
import { OptimizedVideo } from '@/components/OptimizedImage';

export default function Page() {
  return (
    <OptimizedVideo
      src="/videos-optimized/product-demo.mp4"
      mobileVariant="/videos-optimized/mobile/product-demo-mobile.mp4"
      poster="/videos-optimized/product-demo-poster.webp"
      controls
      className="w-full"
    />
  );
}
\`);
