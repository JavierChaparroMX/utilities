#!/usr/bin/env node

import fs from 'fs';
import path from 'path';

/**
 * Generate .htaccess file for Apache-based content negotiation
 * Serves WebP to browsers that support it with PNG/JPG fallback
 * Usage: node generate-htaccess.js [output-path]
 */

const htaccessContent = `# Media Optimization - Content Negotiation Rules
# Automatically serve WebP images to supporting browsers with fallback

# Enable mod_rewrite
<IfModule mod_rewrite.c>
    RewriteEngine On
    
    # Check if browser accepts WebP
    # If request ends in .webp, serve it as image/webp
    
    # Redirect image requests to .webp if available and supported
    RewriteCond %{HTTP_ACCEPT} image/webp
    RewriteCond %{REQUEST_FILENAME} !.*\\.webp$
    RewriteCond %{REQUEST_FILENAME}\\.webp -f
    RewriteRule ^(.*)\\.(jpg|jpeg|png)$ $1.webp [T=image/webp,L]
    
    # Handle static video variants for different devices
    # Mobile detection based on viewport or referrer
    RewriteCond %{HTTP_USER_AGENT} Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera\ Mini [NC]
    RewriteCond %{REQUEST_FILENAME} !.*-mobile\\.mp4$
    RewriteCond %{REQUEST_FILENAME}\\.mp4 -f
    RewriteRule ^(.*/)?([^/]+)\\.mp4$ $1$2-mobile.mp4 [L]
</IfModule>

# Set correct MIME types
<IfModule mod_mime.c>
    AddType image/webp .webp
    AddEncoding gzip .webp.gz
    AddType video/mp4 .mp4
    AddType video/webm .webm
</IfModule>

# Browser cache settings
<IfModule mod_expires.c>
    ExpiresActive On
    
    # Images (1 year)
    ExpiresByType image/webp "access plus 1 year"
    ExpiresByType image/jpeg "access plus 1 year"
    ExpiresByType image/png "access plus 1 year"
    ExpiresByType image/gif "access plus 1 year"
    ExpiresByType image/x-icon "access plus 1 year"
    
    # Videos (30 days - update frequently for new versions)
    ExpiresByType video/mp4 "access plus 30 days"
    ExpiresByType video/webm "access plus 30 days"
</IfModule>

# Gzip compression for text-based assets
<IfModule mod_deflate.c>
    AddOutputFilterByType DEFLATE text/html
    AddOutputFilterByType DEFLATE text/plain
    AddOutputFilterByType DEFLATE text/css
    AddOutputFilterByType DEFLATE image/svg+xml
    
    # Ensure WebP is served with correct type (gzip may interfere)
    SetEnvIfNoCase Request_URI "\\.webp$" no-gzip
</IfModule>

# Vary header for proper caching with content negotiation
<IfModule mod_headers.c>
    Header always append Vary Accept-Encoding
    Header always append Vary Accept
</IfModule>

# Disable directory listing
Options -Indexes
`;

function generateHtaccess(outputPath = './public-optimized/.htaccess') {
  const dir = path.dirname(outputPath);
  
  // Create directory if it doesn't exist
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
  
  fs.writeFileSync(outputPath, htaccessContent, 'utf8');
  console.log(`✅ .htaccess generated: ${outputPath}`);
  console.log(`\n📝 Configuration includes:`);
  console.log('   • WebP image serving with PNG fallback');
  console.log('   • Mobile video redirection');
  console.log('   • Proper MIME types');
  console.log('   • Browser caching (1 year for images, 30 days for videos)');
  console.log('   • Gzip compression');
  console.log('   • Content negotiation via Vary headers\n');
}

// Main
const outputPath = process.argv[2] || './public-optimized/.htaccess';
generateHtaccess(outputPath);
