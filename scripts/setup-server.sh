#!/bin/bash
#
# Digital.Grinnell Server Setup Script
# This script installs and configures an Ubuntu Apache web server for Digital.Grinnell
# with Hugo static site support, Handle server, redirects, and custom 404 page
#
# Usage: sudo ./setup-server.sh
#
# Author: Digital.Grinnell Team
# Version: 1.0

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration variables (customize these)
DOMAIN="digital.grinnell.edu"
ADMIN_EMAIL="admin@grinnell.edu"
HUGO_VERSION="0.119.0"  # Update to latest stable version
HANDLE_VERSION="9.3.1"
INSTALL_DIR="/var/www"
HUGO_SITE_NAME="digital-grinnell"

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

# Function to update system
update_system() {
    print_info "Updating system packages..."
    apt-get update -y
    apt-get upgrade -y
    print_info "System updated successfully"
}

# Function to install required packages
install_packages() {
    print_info "Installing required packages..."
    
    apt-get install -y \
        apache2 \
        apache2-utils \
        git \
        curl \
        wget \
        unzip \
        software-properties-common \
        certbot \
        python3-certbot-apache \
        openjdk-11-jdk \
        ufw \
        rsync \
        fail2ban
    
    print_info "Packages installed successfully"
}

# Function to enable Apache modules
enable_apache_modules() {
    print_info "Enabling required Apache modules..."
    
    a2enmod rewrite
    a2enmod ssl
    a2enmod headers
    a2enmod proxy
    a2enmod proxy_http
    a2enmod deflate
    
    print_info "Apache modules enabled successfully"
}

# Function to install Hugo
install_hugo() {
    print_info "Installing Hugo version ${HUGO_VERSION}..."
    
    cd /tmp
    wget "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-amd64.tar.gz"
    tar -xzf "hugo_extended_${HUGO_VERSION}_linux-amd64.tar.gz"
    mv hugo /usr/local/bin/
    chmod +x /usr/local/bin/hugo
    rm -f "hugo_extended_${HUGO_VERSION}_linux-amd64.tar.gz"
    
    # Verify installation
    hugo version
    print_info "Hugo installed successfully"
}

# Function to create directory structure
create_directories() {
    print_info "Creating directory structure..."
    
    mkdir -p "${INSTALL_DIR}/${HUGO_SITE_NAME}"
    mkdir -p "${INSTALL_DIR}/handle-server"
    mkdir -p "${INSTALL_DIR}/backups"
    
    print_info "Directories created successfully"
}

# Function to initialize Hugo site
init_hugo_site() {
    print_info "Initializing Hugo site..."
    
    cd "${INSTALL_DIR}"
    
    # Check if Hugo site already exists
    if [ -d "${INSTALL_DIR}/${HUGO_SITE_NAME}/config.toml" ]; then
        print_warning "Hugo site already exists, skipping initialization"
        return
    fi
    
    # Create new Hugo site
    hugo new site "${HUGO_SITE_NAME}"
    cd "${HUGO_SITE_NAME}"
    
    # Initialize git repository
    git init
    
    # Create a basic index page
    mkdir -p content
    cat > content/_index.md << 'EOF'
---
title: "Digital Grinnell"
date: 2024-01-01
draft: false
---

# Welcome to Digital Grinnell

This is the landing page for Digital Grinnell's digital collections.

## Collections

Browse our collections to explore digitized materials from Grinnell College.
EOF
    
    print_info "Hugo site initialized successfully"
}

# Function to configure Apache virtual host
configure_apache() {
    print_info "Configuring Apache virtual host..."
    
    # Create virtual host configuration
    cat > /etc/apache2/sites-available/${HUGO_SITE_NAME}.conf << EOF
<VirtualHost *:80>
    ServerName ${DOMAIN}
    ServerAdmin ${ADMIN_EMAIL}
    
    DocumentRoot ${INSTALL_DIR}/${HUGO_SITE_NAME}/public
    
    <Directory ${INSTALL_DIR}/${HUGO_SITE_NAME}/public>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    
    # Enable compression
    <IfModule mod_deflate.c>
        AddOutputFilterByType DEFLATE text/html text/plain text/xml text/css text/javascript application/javascript application/json
    </IfModule>
    
    # Browser caching
    <IfModule mod_expires.c>
        ExpiresActive On
        ExpiresByType image/jpg "access plus 1 year"
        ExpiresByType image/jpeg "access plus 1 year"
        ExpiresByType image/gif "access plus 1 year"
        ExpiresByType image/png "access plus 1 year"
        ExpiresByType text/css "access plus 1 month"
        ExpiresByType application/javascript "access plus 1 month"
        ExpiresByType application/pdf "access plus 1 month"
    </IfModule>
    
    # Custom error pages
    ErrorDocument 404 /404.html
    
    # Logging
    ErrorLog \${APACHE_LOG_DIR}/${HUGO_SITE_NAME}-error.log
    CustomLog \${APACHE_LOG_DIR}/${HUGO_SITE_NAME}-access.log combined
</VirtualHost>
EOF
    
    # Disable default site and enable new site
    a2dissite 000-default.conf
    a2ensite ${HUGO_SITE_NAME}.conf
    
    # Test Apache configuration
    apache2ctl configtest
    
    # Reload Apache
    systemctl reload apache2
    
    print_info "Apache configured successfully"
}

# Function to configure firewall
configure_firewall() {
    print_info "Configuring firewall..."
    
    # Enable UFW
    ufw --force enable
    
    # Allow SSH (be careful!)
    ufw allow 22/tcp
    
    # Allow HTTP and HTTPS
    ufw allow 80/tcp
    ufw allow 443/tcp
    
    # Allow Handle server (optional - comment out if using proxy only)
    # ufw allow 2641/tcp
    
    # Show status
    ufw status
    
    print_info "Firewall configured successfully"
}

# Function to set up SSL with Let's Encrypt
setup_ssl() {
    print_info "Setting up SSL certificate..."
    
    print_warning "SSL setup requires a valid domain name pointing to this server"
    read -p "Do you want to set up SSL now? (y/n) " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        certbot --apache -d ${DOMAIN} --non-interactive --agree-tos -m ${ADMIN_EMAIL}
        print_info "SSL certificate installed successfully"
    else
        print_warning "Skipping SSL setup. Run 'sudo certbot --apache -d ${DOMAIN}' manually when ready"
    fi
}

# Function to set correct permissions
set_permissions() {
    print_info "Setting correct permissions..."
    
    # Set ownership to www-data
    chown -R www-data:www-data "${INSTALL_DIR}/${HUGO_SITE_NAME}"
    
    # Set directory permissions
    find "${INSTALL_DIR}/${HUGO_SITE_NAME}" -type d -exec chmod 755 {} \;
    
    # Set file permissions
    find "${INSTALL_DIR}/${HUGO_SITE_NAME}" -type f -exec chmod 644 {} \;
    
    print_info "Permissions set successfully"
}

# Function to create sample 404 page
create_404_page() {
    print_info "Creating custom 404 error page..."
    
    mkdir -p "${INSTALL_DIR}/${HUGO_SITE_NAME}/public"
    
    cat > "${INSTALL_DIR}/${HUGO_SITE_NAME}/public/404.html" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>404 - Page Not Found | Digital Grinnell</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .container {
            background: white;
            border-radius: 10px;
            padding: 50px;
            text-align: center;
            max-width: 600px;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
        }
        h1 {
            font-size: 120px;
            color: #667eea;
            margin-bottom: 20px;
        }
        h2 {
            font-size: 28px;
            color: #333;
            margin-bottom: 20px;
        }
        p {
            font-size: 16px;
            color: #666;
            margin-bottom: 30px;
            line-height: 1.6;
        }
        .button {
            display: inline-block;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 12px 30px;
            text-decoration: none;
            border-radius: 5px;
            font-weight: 600;
            transition: transform 0.3s ease;
        }
        .button:hover {
            transform: translateY(-2px);
        }
        .links {
            margin-top: 30px;
        }
        .links a {
            color: #667eea;
            text-decoration: none;
            margin: 0 15px;
        }
        .links a:hover {
            text-decoration: underline;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>404</h1>
        <h2>Page Not Found</h2>
        <p>The page you're looking for doesn't exist or has been moved. This might be because the content has been reorganized or the URL has changed.</p>
        <a href="/" class="button">Go to Homepage</a>
        <div class="links">
            <a href="/collections">Browse Collections</a>
            <a href="/search">Search</a>
            <a href="/about">About</a>
        </div>
    </div>
</body>
</html>
EOF
    
    chown www-data:www-data "${INSTALL_DIR}/${HUGO_SITE_NAME}/public/404.html"
    
    print_info "Custom 404 page created successfully"
}

# Function to print completion message
print_completion() {
    echo
    print_info "============================================"
    print_info "Server setup completed successfully!"
    print_info "============================================"
    echo
    print_info "Next steps:"
    echo "  1. Configure your Hugo site in ${INSTALL_DIR}/${HUGO_SITE_NAME}"
    echo "  2. Run 'hugo' to build your site"
    echo "  3. Set up Handle server using ./setup-handle-server.sh"
    echo "  4. Configure redirects using ./configure-redirects.sh"
    echo "  5. Test your site: http://${DOMAIN}"
    echo
    print_info "Important files:"
    echo "  - Apache config: /etc/apache2/sites-available/${HUGO_SITE_NAME}.conf"
    echo "  - Hugo site: ${INSTALL_DIR}/${HUGO_SITE_NAME}"
    echo "  - Logs: /var/log/apache2/"
    echo
}

# Main execution
main() {
    print_info "Starting Digital.Grinnell server setup..."
    
    check_root
    update_system
    install_packages
    enable_apache_modules
    install_hugo
    create_directories
    init_hugo_site
    create_404_page
    configure_apache
    configure_firewall
    set_permissions
    setup_ssl
    print_completion
}

# Run main function
main
