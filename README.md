# Digital.Grinnell Landing Page

Comprehensive specifications and bash scripts for building an Ubuntu on-premises VM Apache web server capable of displaying a Hugo static site landing page and collection hierarchy, redirecting outdated requests, implementing a custom 404 error page, and running a Handle (hdl.net) server for digital items and collections.

## Project Overview

This repository provides everything needed to set up and maintain a production-ready Digital.Grinnell server infrastructure, including:

- **Hugo Static Site**: Fast, modern static site generator for the landing page and collections
- **Apache Web Server**: Production-grade web server with optimized configuration
- **Handle Server**: Persistent identifier system for digital objects (CNRI Handle System)
- **URL Redirects**: Comprehensive redirect rules for legacy content migration
- **Custom 404 Page**: Branded error page with helpful navigation
- **Automated Scripts**: Deployment, backup, and maintenance automation

## Repository Structure

```
.
├── README.md                    # This file
├── docs/
│   └── SPECIFICATIONS.md        # Detailed technical specifications
└── scripts/
    ├── README.md               # Script documentation
    ├── setup-server.sh         # Initial server setup
    ├── setup-handle-server.sh  # Handle server installation
    ├── configure-redirects.sh  # URL redirect configuration
    ├── deploy-hugo.sh          # Hugo deployment script
    └── maintenance.sh          # Maintenance and monitoring
```

## Quick Start

### Prerequisites

- Ubuntu 22.04 LTS or 20.04 LTS server
- Root/sudo access
- Domain name with DNS configured
- Internet connection

### Installation

1. **Clone this repository**:
   ```bash
   git clone https://github.com/McFateM/Digital.Grinnell-Landing-Page.git
   cd Digital.Grinnell-Landing-Page
   ```

2. **Run the initial setup**:
   ```bash
   sudo ./scripts/setup-server.sh
   ```
   This installs Apache, Hugo, configures the web server, and sets up the basic structure.

3. **Configure URL redirects**:
   ```bash
   sudo ./scripts/configure-redirects.sh
   ```
   Sets up redirect rules for legacy URLs.

4. **Optional: Install Handle server**:
   ```bash
   sudo ./scripts/setup-handle-server.sh
   ```
   Installs the CNRI Handle System for persistent identifiers.

5. **Deploy your Hugo site**:
   ```bash
   ./scripts/deploy-hugo.sh
   ```
   Builds and deploys your Hugo static site.

### What Gets Installed

After running the setup scripts, you'll have:

- ✅ Apache 2.4+ web server with SSL support
- ✅ Hugo static site generator (latest version)
- ✅ Configured firewall (UFW)
- ✅ Custom 404 error page
- ✅ URL redirect system
- ✅ Handle server (optional)
- ✅ Automated backup system
- ✅ Maintenance scripts

## Documentation

### Detailed Specifications

See [docs/SPECIFICATIONS.md](docs/SPECIFICATIONS.md) for:
- Complete system architecture
- Hardware and software requirements
- Security configuration
- Performance optimization
- Backup and recovery procedures
- Troubleshooting guide

### Script Documentation

See [scripts/README.md](scripts/README.md) for:
- Detailed description of each script
- Usage examples
- Configuration options
- Troubleshooting tips
- Automation with cron

## Features

### 1. Hugo Static Site Landing Page

- Modern, fast static site generation
- Responsive design support
- Easy content management with Markdown
- Built-in search functionality
- Automatic sitemap generation

### 2. Collection Hierarchy Display

- Organized digital collections
- Hierarchical navigation
- Collection metadata display
- Breadcrumb navigation
- Taxonomy support

### 3. URL Redirection System

- Handles legacy Islandora URLs
- Pattern-based redirects
- 301 permanent redirects for SEO
- Redirect mapping file support
- Logging for monitoring

**Example redirects**:
- `/islandora/object/grinnell:123` → `/items/grinnell:123`
- `/fedora/get/grinnell:456` → `/items/grinnell:456`
- `/browse` → `/collections`

### 4. Custom 404 Error Page

- Branded design matching site theme
- Helpful navigation links
- Search functionality
- User-friendly error messages
- Maintains proper HTTP 404 status

### 5. Handle Server Integration

- CNRI Handle System implementation
- Persistent identifiers (DOI/Handle)
- HTTP/HTTPS resolution
- RESTful API support
- Admin interface

**Handle resolution**:
- Collections: `10.XXXXX/collection.123` → Collection page
- Items: `10.XXXXX/item.456` → Item page

## Maintenance

### Daily Tasks

```bash
# Check system health
sudo ./scripts/maintenance.sh check
```

### Weekly Tasks

```bash
# Full maintenance (backup, cleanup, analysis)
sudo ./scripts/maintenance.sh all
```

### Automated Maintenance

Set up cron jobs for automated maintenance:

```bash
# Edit crontab
sudo crontab -e

# Add these lines:
0 6 * * * /path/to/scripts/maintenance.sh check
0 1 * * * /path/to/scripts/maintenance.sh backup
0 2 * * 0 /path/to/scripts/maintenance.sh all
```

## Deployment Workflow

### Content Updates

1. Update content in `/var/www/digital-grinnell/content/`
2. Run deployment script: `./scripts/deploy-hugo.sh`
3. Verify changes: Check your website

### Configuration Changes

1. Update Hugo configuration in `/var/www/digital-grinnell/config.toml`
2. Rebuild site: `./scripts/deploy-hugo.sh`
3. Test thoroughly before deploying to production

## Security

The setup includes several security features:

- SSL/TLS with Let's Encrypt
- Firewall configuration (UFW)
- Security headers (X-Frame-Options, etc.)
- Fail2ban for intrusion prevention
- Regular security updates
- Restricted admin interfaces

### Important Security Steps

1. **Configure firewall**: Review and adjust UFW rules
2. **Set up SSL**: Run `sudo certbot --apache -d yourdomain.com`
3. **Restrict SSH**: Use key-based authentication only
4. **Monitor logs**: Check `/var/log/apache2/` regularly
5. **Keep updated**: Run `sudo apt update && sudo apt upgrade` regularly

## Troubleshooting

### Apache Issues

```bash
# Check Apache status
sudo systemctl status apache2

# Test configuration
sudo apache2ctl configtest

# View error logs
sudo tail -f /var/log/apache2/error.log
```

### Hugo Build Issues

```bash
# Check Hugo version
hugo version

# Test build manually
cd /var/www/digital-grinnell
hugo --verbose
```

### Handle Server Issues

```bash
# Check Java installation
java -version

# Check Handle server status
sudo systemctl status handle-server

# View logs
tail -f /var/www/handle-server/logs/handle-server.log
```

## Technology Stack

- **OS**: Ubuntu 22.04 LTS / 20.04 LTS
- **Web Server**: Apache 2.4+
- **Static Site Generator**: Hugo (Extended Edition)
- **Handle System**: CNRI Handle Server 9.x
- **SSL/TLS**: Let's Encrypt (Certbot)
- **Programming**: Bash scripting
- **Version Control**: Git

## System Requirements

### Minimum Requirements

- **CPU**: 2 cores
- **RAM**: 4 GB
- **Storage**: 50 GB
- **Network**: Static IP with DNS

### Recommended Requirements

- **CPU**: 4 cores
- **RAM**: 8 GB
- **Storage**: 100 GB SSD
- **Network**: Static IP with DNS, backup internet connection

## Contributing

Contributions are welcome! Please:

1. Test changes on a development server first
2. Document any new features or modifications
3. Update relevant README files
4. Follow existing code style and conventions
5. Submit pull requests with clear descriptions

## Support and Resources

### Official Documentation

- **Apache**: https://httpd.apache.org/docs/2.4/
- **Hugo**: https://gohugo.io/documentation/
- **Handle System**: https://www.handle.net/tech_manual/HN_Tech_Manual_9.pdf
- **Ubuntu Server**: https://ubuntu.com/server/docs
- **Let's Encrypt**: https://letsencrypt.org/docs/

### Getting Help

- Review `docs/SPECIFICATIONS.md` for technical details
- Check `scripts/README.md` for script-specific help
- Examine log files in `/var/log/apache2/`
- Use system logs: `sudo journalctl -xe`

## License

This project is provided for use with Digital.Grinnell. Please refer to individual component licenses for specific terms.

## Acknowledgments

- Grinnell College Libraries
- Hugo Project
- Apache Software Foundation
- Corporation for National Research Initiatives (CNRI)
- Let's Encrypt / EFF

## Original Project Prompt

> Create specifications and bash scripts, if possible, to build an Ubuntu on-prem VM Apache web server capable of displaying a Hugo static site landing page and collection hierarchy, redirecting outdated requests, a custom 404 error page, and a Handle (hdl.net) server for digital items and collections. Add this prompt to the project's README.md file.

This repository fulfills this requirement by providing comprehensive specifications in `docs/SPECIFICATIONS.md` and a complete set of bash scripts in the `scripts/` directory to automate the entire setup process.
