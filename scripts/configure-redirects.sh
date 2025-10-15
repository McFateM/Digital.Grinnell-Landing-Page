#!/bin/bash
#
# Configure URL Redirects for Digital.Grinnell
# This script sets up Apache redirects for legacy URLs to new Hugo structure
#
# Usage: sudo ./configure-redirects.sh
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
HUGO_SITE_NAME="digital-grinnell"
APACHE_SITE_CONFIG="/etc/apache2/sites-available/${HUGO_SITE_NAME}.conf"
REDIRECTS_FILE="/var/www/${HUGO_SITE_NAME}/.htaccess"

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

# Function to check if script is run as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Function to backup existing configuration
backup_config() {
    print_info "Backing up existing configuration..."
    
    if [ -f "$APACHE_SITE_CONFIG" ]; then
        cp "$APACHE_SITE_CONFIG" "${APACHE_SITE_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)"
        print_info "Backup created: ${APACHE_SITE_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    if [ -f "$REDIRECTS_FILE" ]; then
        cp "$REDIRECTS_FILE" "${REDIRECTS_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
        print_info "Backup created: ${REDIRECTS_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    fi
}

# Function to create redirects in Apache configuration
configure_apache_redirects() {
    print_info "Configuring Apache redirects..."
    
    # Check if mod_rewrite is enabled
    if ! apache2ctl -M 2>/dev/null | grep -q "rewrite_module"; then
        print_warning "mod_rewrite is not enabled. Enabling it now..."
        a2enmod rewrite
    fi
    
    # Create a redirects configuration file
    cat > /etc/apache2/conf-available/digital-grinnell-redirects.conf << 'EOF'
# Digital.Grinnell URL Redirects Configuration
# Legacy URL patterns to new Hugo structure

<IfModule mod_rewrite.c>
    RewriteEngine On
    
    # Log rewrites for debugging (comment out in production)
    # RewriteLog "/var/log/apache2/rewrite.log"
    # RewriteLogLevel 3
    
    # ========================================
    # Legacy Islandora URLs
    # ========================================
    
    # Old Islandora object URLs to new item URLs
    # Pattern: /islandora/object/grinnell:12345 -> /items/grinnell:12345
    RewriteRule ^/islandora/object/(.+)$ /items/$1 [R=301,L]
    
    # Old Fedora get URLs to new item URLs
    # Pattern: /fedora/get/grinnell:12345 -> /items/grinnell:12345
    RewriteRule ^/fedora/get/(.+)$ /items/$1 [R=301,L]
    
    # Old Fedora repository URLs
    RewriteRule ^/fedora/repository/(.+)$ /items/$1 [R=301,L]
    
    # ========================================
    # Collection Redirects
    # ========================================
    
    # Old collection browse URLs to new collection URLs
    # Pattern: /islandora/browse/collections/grinnell:123 -> /collections/grinnell:123
    RewriteRule ^/islandora/browse/collections?/(.+)$ /collections/$1 [R=301,L]
    
    # Old collection listing page
    RewriteRule ^/collections-list$ /collections [R=301,L]
    RewriteRule ^/browse$ /collections [R=301,L]
    
    # ========================================
    # Search and Discovery
    # ========================================
    
    # Old search URLs to new search
    RewriteRule ^/islandora/search/(.*)$ /search?q=$1 [R=301,L,QSA]
    RewriteRule ^/solr/search(.*)$ /search$1 [R=301,L,QSA]
    
    # ========================================
    # Handle Server Integration
    # ========================================
    
    # Redirect handle.net URLs to proper resolution
    # Pattern: /handle/10.XXXXX/123 -> Handle server resolution
    RewriteCond %{REQUEST_URI} ^/handle/
    RewriteRule ^handle/(.+)$ http://localhost:2641/api/handles/$1 [P,L]
    
    # ========================================
    # Download and Datastream URLs
    # ========================================
    
    # Old datastream URLs to new download URLs
    RewriteRule ^/islandora/object/([^/]+)/datastream/([^/]+)/download$ /download/$1/$2 [R=301,L]
    RewriteRule ^/islandora/object/([^/]+)/datastream/([^/]+)/view$ /view/$1/$2 [R=301,L]
    
    # ========================================
    # Special Pages
    # ========================================
    
    # Old about page
    RewriteRule ^/about-digital-grinnell$ /about [R=301,L]
    RewriteRule ^/aboutus$ /about [R=301,L]
    
    # Old contact page
    RewriteRule ^/contact-us$ /contact [R=301,L]
    
    # Old help/FAQ page
    RewriteRule ^/help$ /faq [R=301,L]
    
    # ========================================
    # Force HTTPS (uncomment after SSL setup)
    # ========================================
    # RewriteCond %{HTTPS} off
    # RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
    
    # ========================================
    # Canonical URL (remove www prefix)
    # ========================================
    # RewriteCond %{HTTP_HOST} ^www\.(.+)$ [NC]
    # RewriteRule ^(.*)$ https://%1/$1 [R=301,L]
    
</IfModule>
EOF
    
    # Enable the redirects configuration
    a2enconf digital-grinnell-redirects
    
    print_info "Apache redirects configured successfully"
}

# Function to create .htaccess file with additional redirects
create_htaccess() {
    print_info "Creating .htaccess file for additional redirects..."
    
    cat > "$REDIRECTS_FILE" << 'EOF'
# Digital.Grinnell Additional Redirects
# This file can be edited without restarting Apache

# Enable rewrite engine
RewriteEngine On

# ========================================
# Custom Redirects
# Add your custom redirects below
# ========================================

# Example: Redirect old news page
# Redirect 301 /news/old-article /posts/new-article

# Example: Redirect specific collection
# Redirect 301 /old-collection-name /collections/new-collection-name

# ========================================
# Prevent directory listing
# ========================================
Options -Indexes

# ========================================
# Security Headers
# ========================================
<IfModule mod_headers.c>
    # Prevent clickjacking
    Header always set X-Frame-Options "SAMEORIGIN"
    
    # Enable XSS protection
    Header always set X-XSS-Protection "1; mode=block"
    
    # Prevent MIME type sniffing
    Header always set X-Content-Type-Options "nosniff"
    
    # Referrer policy
    Header always set Referrer-Policy "strict-origin-when-cross-origin"
</IfModule>

# ========================================
# Compression
# ========================================
<IfModule mod_deflate.c>
    AddOutputFilterByType DEFLATE text/html text/plain text/xml text/css text/javascript application/javascript application/json application/xml
</IfModule>

# ========================================
# Browser Caching
# ========================================
<IfModule mod_expires.c>
    ExpiresActive On
    
    # Images
    ExpiresByType image/jpeg "access plus 1 year"
    ExpiresByType image/gif "access plus 1 year"
    ExpiresByType image/png "access plus 1 year"
    ExpiresByType image/webp "access plus 1 year"
    ExpiresByType image/svg+xml "access plus 1 year"
    ExpiresByType image/x-icon "access plus 1 year"
    
    # CSS and JavaScript
    ExpiresByType text/css "access plus 1 month"
    ExpiresByType text/javascript "access plus 1 month"
    ExpiresByType application/javascript "access plus 1 month"
    
    # Fonts
    ExpiresByType font/ttf "access plus 1 year"
    ExpiresByType font/otf "access plus 1 year"
    ExpiresByType font/woff "access plus 1 year"
    ExpiresByType font/woff2 "access plus 1 year"
    ExpiresByType application/font-woff "access plus 1 year"
    
    # Documents
    ExpiresByType application/pdf "access plus 1 month"
    
    # Default
    ExpiresDefault "access plus 2 days"
</IfModule>
EOF
    
    # Set proper permissions
    chown www-data:www-data "$REDIRECTS_FILE"
    chmod 644 "$REDIRECTS_FILE"
    
    print_info ".htaccess file created successfully"
}

# Function to create redirect mapping file
create_redirect_map() {
    print_info "Creating redirect mapping file for bulk imports..."
    
    mkdir -p "/var/www/${HUGO_SITE_NAME}/redirects"
    
    cat > "/var/www/${HUGO_SITE_NAME}/redirects/redirect-map.txt" << 'EOF'
# Redirect Mapping File
# Format: old-url new-url
# One redirect per line, separated by space or tab
# Lines starting with # are comments

# Example mappings:
# /old-page-1 /new-page-1
# /old-page-2 /new-page-2
# /articles/old-article /posts/new-article

# Add your redirects below:
EOF
    
    cat > "/var/www/${HUGO_SITE_NAME}/redirects/README.md" << 'EOF'
# Redirect Mapping

## Using the Redirect Map

This directory contains mapping files for bulk URL redirects.

### Format

The `redirect-map.txt` file uses a simple format:
```
/old-url /new-url
```

### Importing Redirects

To apply redirects from the mapping file to Apache:

1. Edit `redirect-map.txt` with your redirects
2. Run the import script:
   ```bash
   sudo /var/www/digital-grinnell/redirects/import-redirects.sh
   ```

### Manual Apache Configuration

For advanced redirects using Apache's RewriteMap:

```apache
RewriteMap redirects txt:/var/www/digital-grinnell/redirects/redirect-map.txt
RewriteCond ${redirects:$1} !=""
RewriteRule ^(.*)$ ${redirects:$1} [R=301,L]
```

### Testing Redirects

```bash
# Test a redirect
curl -I http://localhost/old-url

# Should return:
# HTTP/1.1 301 Moved Permanently
# Location: /new-url
```

### Redirect Types

- **301 (Permanent)**: Use for permanent URL changes
- **302 (Temporary)**: Use for temporary redirects
- **307 (Temporary, preserve method)**: Use when POST data needs preservation

### Common Patterns

```bash
# Redirect entire directory
Redirect 301 /old-dir /new-dir

# Redirect with pattern matching
RedirectMatch 301 ^/blog/([0-9]+)/(.*)$ /posts/$1/$2

# Redirect external URL
Redirect 301 /external https://example.com/page
```
EOF
    
    chown -R www-data:www-data "/var/www/${HUGO_SITE_NAME}/redirects"
    
    print_info "Redirect mapping file created"
}

# Function to test Apache configuration
test_configuration() {
    print_info "Testing Apache configuration..."
    
    if apache2ctl configtest; then
        print_info "Apache configuration is valid"
    else
        print_error "Apache configuration has errors"
        exit 1
    fi
}

# Function to reload Apache
reload_apache() {
    print_info "Reloading Apache..."
    
    systemctl reload apache2
    
    if systemctl is-active --quiet apache2; then
        print_info "Apache reloaded successfully"
    else
        print_error "Apache failed to reload"
        exit 1
    fi
}

# Function to create test script
create_test_script() {
    print_info "Creating redirect test script..."
    
    cat > "/var/www/${HUGO_SITE_NAME}/test-redirects.sh" << 'EOF'
#!/bin/bash
#
# Test Digital.Grinnell redirects
# Usage: ./test-redirects.sh [domain]
#

DOMAIN="${1:-localhost}"

echo "Testing redirects on ${DOMAIN}..."
echo

# Test function
test_redirect() {
    local url=$1
    local expected=$2
    
    echo -n "Testing: ${url} -> "
    result=$(curl -s -o /dev/null -w "%{http_code} %{redirect_url}" "http://${DOMAIN}${url}")
    
    if echo "$result" | grep -q "301"; then
        echo "✓ PASS (301 redirect)"
    else
        echo "✗ FAIL ($result)"
    fi
}

# Test redirects
test_redirect "/islandora/object/grinnell:123" "/items/grinnell:123"
test_redirect "/fedora/get/grinnell:456" "/items/grinnell:456"
test_redirect "/islandora/browse/collections" "/collections"
test_redirect "/about-digital-grinnell" "/about"

echo
echo "Testing complete!"
EOF
    
    chmod +x "/var/www/${HUGO_SITE_NAME}/test-redirects.sh"
    
    print_info "Test script created at /var/www/${HUGO_SITE_NAME}/test-redirects.sh"
}

# Function to print completion message
print_completion() {
    echo
    print_info "============================================"
    print_info "Redirect configuration completed!"
    print_info "============================================"
    echo
    print_info "Configuration files:"
    echo "  - Apache config: /etc/apache2/conf-available/digital-grinnell-redirects.conf"
    echo "  - .htaccess: ${REDIRECTS_FILE}"
    echo "  - Redirect map: /var/www/${HUGO_SITE_NAME}/redirects/redirect-map.txt"
    echo
    print_info "Testing redirects:"
    echo "  sudo /var/www/${HUGO_SITE_NAME}/test-redirects.sh"
    echo
    print_info "Adding custom redirects:"
    echo "  1. Edit: ${REDIRECTS_FILE}"
    echo "  2. Or edit: /var/www/${HUGO_SITE_NAME}/redirects/redirect-map.txt"
    echo "  3. No Apache restart needed for .htaccess changes"
    echo
    print_warning "Remember to:"
    echo "  - Test all redirects thoroughly"
    echo "  - Update redirects as content is migrated"
    echo "  - Monitor Apache error logs for issues"
    echo
}

# Main execution
main() {
    print_info "Starting redirect configuration..."
    
    check_root
    backup_config
    configure_apache_redirects
    create_htaccess
    create_redirect_map
    create_test_script
    test_configuration
    reload_apache
    print_completion
}

# Run main function
main
