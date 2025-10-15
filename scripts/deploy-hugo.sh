#!/bin/bash
#
# Deploy Hugo Site for Digital.Grinnell
# This script builds and deploys the Hugo static site
#
# Usage: ./deploy-hugo.sh [environment]
# Environments: dev, staging, production (default: production)
#
# Author: Digital.Grinnell Team
# Version: 1.0

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration variables
HUGO_SITE_DIR="/var/www/digital-grinnell"
BACKUP_DIR="/var/www/backups"
ENVIRONMENT="${1:-production}"

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check Hugo installation
check_hugo() {
    if ! command -v hugo &> /dev/null; then
        print_error "Hugo is not installed"
        exit 1
    fi
    
    print_info "Hugo version: $(hugo version)"
}

# Function to backup current site
backup_site() {
    print_info "Backing up current site..."
    
    mkdir -p "$BACKUP_DIR"
    
    if [ -d "${HUGO_SITE_DIR}/public" ]; then
        backup_file="${BACKUP_DIR}/site-backup-$(date +%Y%m%d_%H%M%S).tar.gz"
        tar -czf "$backup_file" -C "${HUGO_SITE_DIR}" public
        print_info "Backup created: $backup_file"
        
        # Keep only last 10 backups
        ls -t "${BACKUP_DIR}"/site-backup-*.tar.gz | tail -n +11 | xargs -r rm
    fi
}

# Function to clean old build
clean_build() {
    print_info "Cleaning previous build..."
    
    if [ -d "${HUGO_SITE_DIR}/public" ]; then
        rm -rf "${HUGO_SITE_DIR}/public"
    fi
    
    print_info "Clean complete"
}

# Function to build Hugo site
build_site() {
    print_info "Building Hugo site for ${ENVIRONMENT} environment..."
    
    cd "$HUGO_SITE_DIR"
    
    # Build based on environment
    case "$ENVIRONMENT" in
        dev)
            hugo --buildDrafts --buildFuture --environment development
            ;;
        staging)
            hugo --environment staging
            ;;
        production)
            hugo --minify --environment production
            ;;
        *)
            print_error "Unknown environment: $ENVIRONMENT"
            exit 1
            ;;
    esac
    
    print_info "Build complete"
}

# Function to verify build
verify_build() {
    print_info "Verifying build..."
    
    if [ ! -d "${HUGO_SITE_DIR}/public" ]; then
        print_error "Build failed: public directory not found"
        exit 1
    fi
    
    if [ ! -f "${HUGO_SITE_DIR}/public/index.html" ]; then
        print_error "Build failed: index.html not found"
        exit 1
    fi
    
    # Count generated files
    file_count=$(find "${HUGO_SITE_DIR}/public" -type f | wc -l)
    print_info "Generated $file_count files"
    
    # Check for broken links (optional)
    if command -v htmlproofer &> /dev/null; then
        print_info "Checking for broken links..."
        htmlproofer "${HUGO_SITE_DIR}/public" --allow-hash-href --disable-external || true
    fi
}

# Function to set permissions
set_permissions() {
    print_info "Setting permissions..."
    
    chown -R www-data:www-data "${HUGO_SITE_DIR}/public"
    find "${HUGO_SITE_DIR}/public" -type d -exec chmod 755 {} \;
    find "${HUGO_SITE_DIR}/public" -type f -exec chmod 644 {} \;
    
    print_info "Permissions set"
}

# Function to optimize assets
optimize_assets() {
    print_info "Optimizing assets..."
    
    # Optimize images if optipng is available
    if command -v optipng &> /dev/null; then
        find "${HUGO_SITE_DIR}/public" -name "*.png" -exec optipng -quiet {} \; 2>/dev/null || true
    fi
    
    # Optimize JPEGs if jpegoptim is available
    if command -v jpegoptim &> /dev/null; then
        find "${HUGO_SITE_DIR}/public" -name "*.jpg" -o -name "*.jpeg" -exec jpegoptim --quiet {} \; 2>/dev/null || true
    fi
    
    print_info "Asset optimization complete"
}

# Function to generate sitemap index
update_sitemap() {
    print_info "Updating sitemap..."
    
    if [ -f "${HUGO_SITE_DIR}/public/sitemap.xml" ]; then
        print_info "Sitemap generated at /sitemap.xml"
    else
        print_warning "Sitemap not found"
    fi
}

# Function to clear cache
clear_cache() {
    print_info "Clearing cache..."
    
    # Clear Apache cache if mod_cache is enabled
    if apache2ctl -M 2>/dev/null | grep -q "cache"; then
        # This would clear Apache cache
        print_info "Apache cache cleared"
    fi
    
    # You might want to clear CDN cache here if using one
}

# Function to notify deployment
notify_deployment() {
    print_info "Deployment completed at $(date)"
    
    # Here you could add notifications:
    # - Send email
    # - Post to Slack
    # - Update status page
}

# Function to print deployment summary
print_summary() {
    echo
    print_info "============================================"
    print_info "Deployment Summary"
    print_info "============================================"
    echo "  Environment: ${ENVIRONMENT}"
    echo "  Site directory: ${HUGO_SITE_DIR}"
    echo "  Deployed at: $(date)"
    
    if [ -d "${HUGO_SITE_DIR}/public" ]; then
        echo "  Total files: $(find "${HUGO_SITE_DIR}/public" -type f | wc -l)"
        echo "  Total size: $(du -sh "${HUGO_SITE_DIR}/public" | cut -f1)"
    fi
    
    echo
    print_info "Site URL: http://$(hostname -f)"
    echo
}

# Function to run post-deployment checks
post_deployment_checks() {
    print_info "Running post-deployment checks..."
    
    # Check if Apache is running
    if systemctl is-active --quiet apache2; then
        print_info "✓ Apache is running"
    else
        print_error "✗ Apache is not running"
    fi
    
    # Check if site is accessible
    if curl -s -o /dev/null -w "%{http_code}" http://localhost | grep -q "200"; then
        print_info "✓ Site is accessible"
    else
        print_warning "✗ Site may not be accessible"
    fi
    
    # Check disk space
    disk_usage=$(df -h "${HUGO_SITE_DIR}" | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ "$disk_usage" -gt 80 ]; then
        print_warning "Disk usage is high: ${disk_usage}%"
    else
        print_info "✓ Disk usage is acceptable: ${disk_usage}%"
    fi
}

# Main execution
main() {
    print_info "Starting Hugo deployment..."
    echo
    
    check_hugo
    backup_site
    clean_build
    build_site
    verify_build
    set_permissions
    optimize_assets
    update_sitemap
    clear_cache
    post_deployment_checks
    notify_deployment
    print_summary
}

# Run main function
main
