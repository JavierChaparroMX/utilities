#!/bin/bash

# Media Optimization Script - macOS/Linux Examples
# 
# This file shows practical examples of pointing the script to different directories
# and website types. Copy/paste the examples that match your setup.
#
# Requirements:
# - Node.js 18+ installed
# - FFmpeg installed (brew install ffmpeg on macOS)
# - npm dependencies installed (run: npm install)

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Media Optimization Script - Directory Examples            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# ============================================
# EXAMPLE 1: Single Directory Conversion
# ============================================

echo -e "\033[1;36mExample 1: Convert a single directory\033[0m"
echo -e "\033[1;33mCommand:\033[0m"
echo 'node convert-media.js --source "~/Pictures/website-images" --output "~/Pictures/website-images-optimized"'
echo ""

# ============================================
# EXAMPLE 2: WordPress Site Optimization
# ============================================

echo -e "\033[1;36mExample 2: WordPress Site\033[0m"
echo -e "\033[1;33mCommand:\033[0m"
echo 'node convert-media.js --source "/var/www/html/myblog/wp-content/uploads" --output "/var/www/html/myblog/wp-content/uploads-optimized"'
echo ""
echo -e "\033[0;90mAfter optimization, move files:\033[0m"
echo 'mv /var/www/html/myblog/wp-content/uploads-optimized/* /var/www/html/myblog/wp-content/uploads/'
echo ""

# ============================================
# EXAMPLE 3: Static HTML Website
# ============================================

echo -e "\033[1;36mExample 3: Static HTML Website\033[0m"
echo -e "\033[1;33mCommand:\033[0m"
echo 'node convert-media.js --source "~/projects/mywebsite/assets" --output "~/projects/mywebsite/assets-optimized"'
echo ""
echo -e "\033[1;33mThen update your HTML from:\033[0m"
echo '<img src="assets/logo.png">'
echo -e "\033[1;33mTo:\033[0m"
echo '<picture><source srcset="assets-optimized/logo.webp" type="image/webp"><img src="assets-optimized/logo.png" alt="Logo"></picture>'
echo ""

# ============================================
# EXAMPLE 4: Next.js Project
# ============================================

echo -e "\033[1;36mExample 4: Next.js Project\033[0m"
echo -e "\033[1;33mStep 1 - Command:\033[0m"
echo 'node convert-media.js --source "~/projects/my-nextjs-app/public/assets" --output "~/projects/my-nextjs-app/public/assets-optimized"'
echo ""
echo -e "\033[1;33mStep 2 - Generate Next.js config:\033[0m"
echo 'node generate-nextjs-config.js'
echo ""

# ============================================
# EXAMPLE 5: E-Commerce / Shopify
# ============================================

echo -e "\033[1;36mExample 5: E-Commerce / Shopify\033[0m"
echo -e "\033[1;33mCommand:\033[0m"
echo 'node convert-media.js --source "~/projects/myshop/theme/assets/images" --output "~/projects/myshop/theme/assets/images-optimized"'
echo ""

# ============================================
# EXAMPLE 6: Multi-Site Optimization (Batch)
# ============================================

echo -e "\033[1;36mExample 6: Batch Process Multiple Sites\033[0m"
echo -e "\033[1;33mCreate this as '\033[0mbatch-optimize.sh\033[1;33m' and run:\033[0m"
echo "bash batch-optimize.sh"
echo ""
echo -e "\033[0;90mExample batch script content:\033[0m"
cat << 'EOF'
#!/bin/bash

sites=(
    "work|~/websites/work|~/websites/work-optimized"
    "blog|~/websites/blog|~/websites/blog-optimized"
    "portfolio|~/websites/portfolio|~/websites/portfolio-optimized"
)

for site in "${sites[@]}"; do
    IFS='|' read -r name source output <<< "$site"
    echo "Optimizing $name..."
    node convert-media.js --source "$source" --output "$output"
done

echo "All sites optimized!"
EOF
echo ""

# ============================================
# EXAMPLE 7: High Quality Conversion
# ============================================

echo -e "\033[1;36mExample 7: High Quality (Better for design/portfolio sites)\033[0m"
echo -e "\033[1;33mCommand:\033[0m"
echo 'node convert-media.js --source "~/projects/portfolio/images" --output "~/projects/portfolio/images-optimized" --image-quality 90 --video-quality 24'
echo ""

# ============================================
# EXAMPLE 8: Aggressive Compression (Mobile)
# ============================================

echo -e "\033[1;36mExample 8: Aggressive Compression (Fast mobile loading)\033[0m"
echo -e "\033[1;33mCommand:\033[0m"
echo 'node convert-media.js --source "~/projects/mobile-site/assets" --output "~/projects/mobile-site/assets-optimized" --image-quality 65 --video-quality 35 --parallel 8'
echo ""

# ============================================
# EXAMPLE 9: Preview Before Converting (Dry-Run)
# ============================================

echo -e "\033[1;36mExample 9: Preview What Would Be Converted (Dry-Run)\033[0m"
echo -e "\033[1;33mCommand:\033[0m"
echo 'node convert-media.js --source "~/projects/mysite/assets" --output "~/projects/mysite/assets-optimized" --dry-run'
echo -e "\033[0;90mThis shows what files would be converted WITHOUT actually converting them\033[0m"
echo ""

# ============================================
# EXAMPLE 10: Resume Interrupted Conversion
# ============================================

echo -e "\033[1;36mExample 10: Resume Interrupted Conversion\033[0m"
echo -e "\033[1;33mCommand:\033[0m"
echo 'node convert-media.js --source "~/projects/mysite/assets" --output "~/projects/mysite/assets-optimized" --continue'
echo -e "\033[0;90mThis skips already-converted files and continues from where it left off\033[0m"
echo ""

# ============================================
# EXAMPLE 11: Apache Server (.htaccess)
# ============================================

echo -e "\033[1;36mExample 11: Apache Server Configuration\033[0m"
echo -e "\033[1;33mStep 1 - Convert media:\033[0m"
echo 'node convert-media.js --source "/var/www/html/assets" --output "/var/www/html/assets-optimized"'
echo ""
echo -e "\033[1;33mStep 2 - Generate .htaccess:\033[0m"
echo 'node generate-htaccess.js'
echo ""

# ============================================
# TIPS
# ============================================

echo "═══════════════════════════════════════════════════════════"
echo -e "\033[1;33m💡 TIPS\033[0m"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo -e "\033[1;36m1. USE QUOTES for paths with spaces:\033[0m"
echo -e "\033[0;32m✓ CORRECT:   --source \"~/My Documents/images\"\033[0m"
echo -e "\033[0;31m✗ WRONG:     --source ~/My Documents/images\033[0m"
echo ""
echo -e "\033[1;36m2. TILDE expansion works:\033[0m"
echo -e "\033[0;32m✓ WORKS:     ~/websites/site1\033[0m"
echo -e "\033[0;32m✓ ALSO WORKS: \$HOME/websites/site1\033[0m"
echo ""
echo -e "\033[1;36m3. CHECK DRY-RUN before converting:\033[0m"
echo 'node convert-media.js --source ... --output ... --dry-run'
echo ""
echo -e "\033[1;36m4. VIEW RESULTS in HTML report:\033[0m"
echo 'open public-optimized/conversion-report.html  # macOS'
echo 'xdg-open public-optimized/conversion-report.html  # Linux'
echo ""
echo -e "\033[1;36m5. MOBILE VARIANTS auto-created:\033[0m"
echo "Scripts automatically create mobile versions (640px width)"
echo ""
echo -e "\033[1;36m6. RESUME if interrupted:\033[0m"
echo "Use --continue flag to skip already-converted files"
echo ""
echo -e "\033[1;36m7. PERFECT FOR ANY SITE TYPE:\033[0m"
echo "  • Static HTML sites"
echo "  • WordPress blogs"
echo "  • Next.js/React apps"
echo "  • Vue.js apps"
echo "  • Shopify stores"
echo "  • Multi-tenant apps"
echo "  • Any directory structure!"
echo ""
echo -e "\033[1;36m8. PREVIEW HTML REPORT:\033[0m"
echo "After running, open: public-optimized/conversion-report.html"
echo ""
echo "═══════════════════════════════════════════════════════════"
echo -e "\033[1;32mReady to optimize? Pick an example and run the command above!\033[0m"
echo "═══════════════════════════════════════════════════════════"
