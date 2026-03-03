#!/usr/bin/env powershell
<# 
  Media Optimization Script - Windows Examples
  
  This file shows practical examples of pointing the script to different directories
  and website types. Copy/paste the examples that match your setup.
  
  Requirements:
  - Node.js 18+ installed
  - FFmpeg installed (download with: choco install ffmpeg)
  - npm dependencies installed (run: npm install)
#>

# ============================================
# EXAMPLE 1: Single Directory Conversion
# ============================================

Write-Host "Example 1: Convert a single directory" -ForegroundColor Cyan
Write-Host "Command:" -ForegroundColor Yellow
Write-Host 'node convert-media.js --source "C:\Users\YourName\Pictures\website-images" --output "C:\Users\YourName\Pictures\website-images-optimized"' -ForegroundColor White

# Run this command:
# node convert-media.js --source "C:\Users\YourName\Pictures\website-images" --output "C:\Users\YourName\Pictures\website-images-optimized"


# ============================================
# EXAMPLE 2: WordPress Site Optimization
# ============================================

Write-Host "`nExample 2: WordPress Site" -ForegroundColor Cyan
Write-Host "Command:" -ForegroundColor Yellow
Write-Host 'node convert-media.js --source "C:\xampp\htdocs\myblog\wp-content\uploads" --output "C:\xampp\htdocs\myblog\wp-content\uploads-optimized"' -ForegroundColor White

# After optimization, move files:
# Move-Item "C:\xampp\htdocs\myblog\wp-content\uploads-optimized\*" "C:\xampp\htdocs\myblog\wp-content\uploads" -Force


# ============================================
# EXAMPLE 3: Static HTML Website
# ============================================

Write-Host "`nExample 3: Static HTML Website" -ForegroundColor Cyan
Write-Host "Command:" -ForegroundColor Yellow
Write-Host 'node convert-media.js --source "C:\projects\mywebsite\assets" --output "C:\projects\mywebsite\assets-optimized"' -ForegroundColor White
Write-Host "Then update your HTML from:" -ForegroundColor Yellow
Write-Host '<img src="assets/logo.png">' -ForegroundColor White
Write-Host "To:" -ForegroundColor Yellow
Write-Host '<picture><source srcset="assets-optimized/logo.webp" type="image/webp"><img src="assets-optimized/logo.png" alt="Logo"></picture>' -ForegroundColor White


# ============================================
# EXAMPLE 4: Next.js Project
# ============================================

Write-Host "`nExample 4: Next.js Project" -ForegroundColor Cyan
Write-Host "Step 1 - Command:" -ForegroundColor Yellow
Write-Host 'node convert-media.js --source "C:\projects\my-nextjs-app\public\assets" --output "C:\projects\my-nextjs-app\public\assets-optimized"' -ForegroundColor White
Write-Host "Step 2 - Generate Next.js config:" -ForegroundColor Yellow
Write-Host 'node generate-nextjs-config.js' -ForegroundColor White


# ============================================
# EXAMPLE 5: E-Commerce / Shopify
# ============================================

Write-Host "`nExample 5: E-Commerce / Shopify" -ForegroundColor Cyan
Write-Host "Command:" -ForegroundColor Yellow
Write-Host 'node convert-media.js --source "C:\projects\myshop\theme\assets\images" --output "C:\projects\myshop\theme\assets\images-optimized"' -ForegroundColor White


# ============================================
# EXAMPLE 6: Multi-Site Optimization (Batch)
# ============================================

Write-Host "`nExample 6: Batch Process Multiple Sites" -ForegroundColor Cyan
Write-Host "Create this as 'batch-optimize.ps1' and run:" -ForegroundColor Yellow
Write-Host "powershell -ExecutionPolicy Bypass -File batch-optimize.ps1" -ForegroundColor White

<#
# Batch example content (save as batch-optimize.ps1):

$sites = @(
    @{
        name = "Site 1"
        source = "C:\websites\site1\public"
        output = "C:\websites\site1\public-optimized"
    },
    @{
        name = "Site 2"
        source = "C:\websites\site2\assets"
        output = "C:\websites\site2\assets-optimized"
    },
    @{
        name = "Site 3"
        source = "C:\websites\site3\images"
        output = "C:\websites\site3\images-optimized"
    }
)

foreach ($site in $sites) {
    Write-Host "Optimizing $($site.name)..." -ForegroundColor Green
    node convert-media.js --source $site.source --output $site.output
}

Write-Host "All sites optimized!" -ForegroundColor Green
#>


# ============================================
# EXAMPLE 7: High Quality Conversion
# ============================================

Write-Host "`nExample 7: High Quality (Better for design/portfolio sites)" -ForegroundColor Cyan
Write-Host "Command:" -ForegroundColor Yellow
Write-Host 'node convert-media.js --source "C:\projects\portfolio\images" --output "C:\projects\portfolio\images-optimized" --image-quality 90 --video-quality 24' -ForegroundColor White


# ============================================
# EXAMPLE 8: Aggressive Compression (Mobile)
# ============================================

Write-Host "`nExample 8: Aggressive Compression (Fast mobile loading)" -ForegroundColor Cyan
Write-Host "Command:" -ForegroundColor Yellow
Write-Host 'node convert-media.js --source "C:\projects\mobile-site\assets" --output "C:\projects\mobile-site\assets-optimized" --image-quality 65 --video-quality 35 --parallel 8' -ForegroundColor White


# ============================================
# EXAMPLE 9: Preview Before Converting (Dry-Run)
# ============================================

Write-Host "`nExample 9: Preview What Would Be Converted (Dry-Run)" -ForegroundColor Cyan
Write-Host "Command:" -ForegroundColor Yellow
Write-Host 'node convert-media.js --source "C:\projects\mysite\assets" --output "C:\projects\mysite\assets-optimized" --dry-run' -ForegroundColor White
Write-Host "This shows what files would be converted WITHOUT actually converting them" -ForegroundColor Gray


# ============================================
# EXAMPLE 10: Resume Interrupted Conversion
# ============================================

Write-Host "`nExample 10: Resume Interrupted Conversion" -ForegroundColor Cyan
Write-Host "Command:" -ForegroundColor Yellow
Write-Host 'node convert-media.js --source "C:\projects\mysite\assets" --output "C:\projects\mysite\assets-optimized" --continue' -ForegroundColor White
Write-Host "This skips already-converted files and continues from where it left off" -ForegroundColor Gray


# ============================================
# EXAMPLE 11: Apache Server (.htaccess)
# ============================================

Write-Host "`nExample 11: Apache Server Configuration" -ForegroundColor Cyan
Write-Host "Step 1 - Convert media:" -ForegroundColor Yellow
Write-Host 'node convert-media.js --source "\\server\web\assets" --output "\\server\web\assets-optimized"' -ForegroundColor White
Write-Host "Step 2 - Generate .htaccess:" -ForegroundColor Yellow
Write-Host 'node generate-htaccess.js' -ForegroundColor White


# ============================================
# TIPS
# ============================================

Write-Host "`n" -ForegroundColor White
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host "💡 TIPS" -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Yellow

Write-Host "
1. USE QUOTES for paths with spaces:
   ✓ CORRECT:   --source `"C:\My Documents\images`"
   ✗ WRONG:     --source C:\My Documents\images

2. ABSOLUTE PATHS work best:
   ✓ CORRECT:   C:\xampp\htdocs\myblog
   ✗ LESS RELIABLE: ../myblog

3. CHECK DRY-RUN before converting:
   node convert-media.js --source ... --output ... --dry-run

4. VIEW RESULTS in HTML report:
   public-optimized/conversion-report.html

5. MOBILE VARIANTS auto-created:
   Scripts automatically create mobile versions (640px width)

6. RESUME if interrupted:
   Use --continue flag to skip already-converted files

7. PERFECT FOR ANY SITE TYPE:
   • Static HTML sites
   • WordPress blogs
   • Next.js/React apps
   • Vue.js apps
   • Shopify stores
   • Multi-tenant apps
   • Any directory structure!

8. PREVIEW HTML REPORT:
   After running, open: public-optimized/conversion-report.html
" -ForegroundColor Cyan

Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host "Ready to optimize? Pick an example and run the command above!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Yellow
