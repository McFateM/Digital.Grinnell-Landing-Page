# Ubuntu Apache Web Server Specifications for Digital.Grinnell

## Overview
This document outlines the specifications for building an Ubuntu on-premises Virtual Machine (VM) running Apache web server capable of hosting Digital.Grinnell's landing page, collection hierarchy, redirections, custom error pages, and Handle server.

## System Requirements

### Hardware Requirements (Minimum)
- **CPU**: 2 cores (4 cores recommended)
- **RAM**: 4 GB (8 GB recommended)
- **Storage**: 50 GB (100 GB recommended for collections)
- **Network**: Static IP address with proper DNS configuration

### Software Requirements
- **Operating System**: Ubuntu 22.04 LTS (or 20.04 LTS)
- **Web Server**: Apache 2.4+
- **Static Site Generator**: Hugo (latest stable version)
- **Handle Server**: CNRI Handle System 9.x
- **Additional Packages**:
  - OpenJDK 11+ (for Handle server)
  - Git
  - Certbot (for SSL/TLS certificates)
  - mod_rewrite (Apache module)
  - mod_ssl (Apache module)

## Server Architecture

### Directory Structure
```
/var/www/
├── digital-grinnell/           # Main Hugo site
│   ├── public/                 # Hugo generated static files
│   ├── content/                # Hugo content
│   ├── themes/                 # Hugo themes
│   └── config.toml             # Hugo configuration
├── handle-server/              # Handle server installation
│   ├── handle/                 # Handle server files
│   └── logs/                   # Handle server logs
└── html/                       # Default Apache directory
```

### Apache Virtual Host Configuration
- **Primary Site**: digital.grinnell.edu (or your domain)
- **HTTP Port**: 80 (redirect to HTTPS)
- **HTTPS Port**: 443
- **Document Root**: `/var/www/digital-grinnell/public`

## Component Specifications

### 1. Hugo Static Site Landing Page

**Purpose**: Serve the main landing page and collection hierarchy for Digital.Grinnell

**Features**:
- Responsive design
- Collection browsing interface
- Search functionality
- Fast static content delivery

**Configuration**:
- Hugo site located at `/var/www/digital-grinnell`
- Automatic builds on content updates
- Apache serves files from `public/` directory

### 2. Collection Hierarchy Display

**Purpose**: Organize and display digital collections in a hierarchical structure

**Implementation**:
- Hugo taxonomies for collections
- Nested menu structure
- Breadcrumb navigation
- Collection landing pages with metadata

**URL Structure**:
```
/collections/                   # Main collections page
/collections/[collection-name]/ # Individual collection
/items/[item-id]/              # Individual item
```

### 3. URL Redirection

**Purpose**: Handle legacy URLs and redirect to new structure

**Features**:
- Permanent redirects (301) for moved content
- Pattern-based redirects for bulk migrations
- Redirect mapping file support
- Logging of redirected requests

**Apache Configuration**:
- Uses mod_rewrite
- Redirect rules in `.htaccess` or virtual host config
- Support for regex-based redirects

**Example Redirects**:
```apache
# Old Islandora URLs to new Hugo structure
RedirectMatch 301 ^/islandora/object/(.*)$ /items/$1
RedirectMatch 301 ^/fedora/get/(.*)$ /items/$1
```

### 4. Custom 404 Error Page

**Purpose**: Provide user-friendly error page for missing content

**Features**:
- Branded error page matching site design
- Search functionality
- Links to main sections
- Helpful navigation
- Optional suggestion system for similar content

**Implementation**:
- Custom HTML page at `/var/www/digital-grinnell/404.html`
- Apache ErrorDocument directive
- Maintains proper 404 HTTP status code

### 5. Handle Server (hdl.net)

**Purpose**: Provide persistent identifiers for digital objects and collections

**Features**:
- DOI/Handle resolution
- HTTP proxy support
- HTTPS support
- Admin interface
- Backup and recovery

**Configuration**:
- Prefix: (assigned by Handle.net)
- Resolution: HTTP/HTTPS redirect to actual resource
- Admin interface: localhost:8000 (secured)
- Public interface: Port 8000 (proxied through Apache)

**Handle Types**:
```
10.XXXXX/collection.123  -> https://digital.grinnell.edu/collections/collection-name
10.XXXXX/item.456        -> https://digital.grinnell.edu/items/item-id
```

## Security Specifications

### SSL/TLS Configuration
- **Certificates**: Let's Encrypt (via Certbot)
- **Protocols**: TLSv1.2, TLSv1.3 only
- **Cipher Suites**: Modern, secure ciphers
- **HSTS**: Enabled with max-age=31536000
- **Auto-renewal**: Certbot timer enabled

### Firewall Configuration
- **Ports Open**:
  - 22 (SSH - limited to admin IPs)
  - 80 (HTTP - redirect to HTTPS)
  - 443 (HTTPS)
  - 2641 (Handle server - optional, can be proxied)
  - 8000 (Handle admin - localhost only)

### Access Control
- SSH key-based authentication only
- Sudo access for administrators
- Apache directory restrictions
- Handle admin interface restricted to localhost

## Monitoring and Maintenance

### Log Files
- Apache access logs: `/var/log/apache2/access.log`
- Apache error logs: `/var/log/apache2/error.log`
- Handle server logs: `/var/www/handle-server/logs/`
- System logs: `/var/log/syslog`

### Backup Strategy
- Daily backups of Hugo content
- Weekly backups of Handle database
- Monthly full system backups
- Off-site backup storage

### Performance Optimization
- Apache KeepAlive enabled
- Gzip compression for static assets
- Browser caching headers
- Static file optimization (minification)
- CDN consideration for large assets

## Deployment Process

### Initial Setup
1. Install Ubuntu 22.04 LTS
2. Configure network and hostname
3. Update system packages
4. Install Apache and dependencies
5. Install Hugo
6. Install Handle server
7. Configure firewall
8. Configure SSL certificates
9. Deploy Hugo site
10. Configure redirects and error pages
11. Test all components

### Ongoing Deployment
1. Update Hugo content
2. Build static site (`hugo`)
3. Deploy to production (`rsync` or `git pull`)
4. Clear cache if needed
5. Verify deployment

## Testing Requirements

### Functional Testing
- [ ] Landing page loads correctly
- [ ] Collection hierarchy displays properly
- [ ] All internal links work
- [ ] Redirects function as expected
- [ ] 404 page displays for invalid URLs
- [ ] Handle resolution works
- [ ] HTTPS redirects from HTTP
- [ ] Mobile responsive design works

### Performance Testing
- [ ] Page load times < 2 seconds
- [ ] Handle resolution < 1 second
- [ ] Server handles 100 concurrent users
- [ ] Static assets properly cached

### Security Testing
- [ ] SSL/TLS configuration secure (A+ rating)
- [ ] No exposed admin interfaces
- [ ] Firewall properly configured
- [ ] File permissions correct
- [ ] No sensitive data in logs

## Documentation Requirements

- Installation guide
- Configuration guide
- Maintenance procedures
- Troubleshooting guide
- Handle management guide
- Backup and recovery procedures

## Support and Maintenance

### Regular Tasks
- **Daily**: Monitor logs, check backups
- **Weekly**: Review security updates, check disk space
- **Monthly**: Apply system updates, review analytics
- **Quarterly**: Full system audit, backup testing

### Contact Information
- System Administrator: [contact information]
- Handle.net Support: https://www.handle.net/contact_support.html
- Hugo Documentation: https://gohugo.io/documentation/

## References

- Apache HTTP Server Documentation: https://httpd.apache.org/docs/2.4/
- Hugo Documentation: https://gohugo.io/documentation/
- Handle System Documentation: https://www.handle.net/tech_manual/HN_Tech_Manual_9.pdf
- Ubuntu Server Guide: https://ubuntu.com/server/docs
- Let's Encrypt Documentation: https://letsencrypt.org/docs/
