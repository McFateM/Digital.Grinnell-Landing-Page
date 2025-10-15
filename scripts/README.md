# Digital.Grinnell Server Scripts

This directory contains bash scripts for setting up, deploying, and maintaining the Digital.Grinnell server infrastructure.

## Scripts Overview

### 1. setup-server.sh
**Purpose**: Initial server setup and configuration

**What it does**:
- Installs Ubuntu system packages (Apache, Git, etc.)
- Installs Hugo static site generator
- Configures Apache web server
- Sets up firewall (UFW)
- Creates directory structure
- Initializes Hugo site
- Sets up SSL certificates (optional)
- Creates custom 404 error page

**Usage**:
```bash
sudo ./setup-server.sh
```

**Requirements**:
- Ubuntu 22.04 LTS or 20.04 LTS
- Root/sudo access
- Internet connection

**Estimated time**: 10-15 minutes

---

### 2. setup-handle-server.sh
**Purpose**: Install and configure CNRI Handle System

**What it does**:
- Downloads Handle server software
- Installs Handle server
- Creates systemd service
- Configures Apache proxy for Handle server
- Creates example Handle records
- Sets up admin interface

**Usage**:
```bash
sudo ./setup-handle-server.sh
```

**Requirements**:
- Java 11+ installed
- Handle prefix from Handle.Net Registry
- setup-server.sh must be run first

**Estimated time**: 5-10 minutes (plus manual configuration)

**Post-installation**:
After running this script, you need to complete Handle server configuration:
```bash
cd /var/www/handle-server/handle
./bin/hdl-setup-server .
```

---

### 3. configure-redirects.sh
**Purpose**: Set up URL redirects for legacy content

**What it does**:
- Configures Apache mod_rewrite redirects
- Creates .htaccess file with redirect rules
- Sets up redirect mapping file
- Creates redirect test script
- Configures security headers and caching

**Usage**:
```bash
sudo ./configure-redirects.sh
```

**Requirements**:
- setup-server.sh must be run first
- Apache mod_rewrite enabled

**Estimated time**: 2-5 minutes

**Testing redirects**:
```bash
/var/www/digital-grinnell/test-redirects.sh
```

---

### 4. deploy-hugo.sh
**Purpose**: Build and deploy Hugo static site

**What it does**:
- Backs up current site
- Builds Hugo site
- Verifies build
- Optimizes assets
- Sets correct permissions
- Runs post-deployment checks

**Usage**:
```bash
# Deploy to production (default)
./deploy-hugo.sh

# Deploy to staging
./deploy-hugo.sh staging

# Deploy development build (includes drafts)
./deploy-hugo.sh dev
```

**Requirements**:
- Hugo site initialized
- Content available in Hugo content directory

**Estimated time**: 1-3 minutes

---

### 5. maintenance.sh
**Purpose**: Routine maintenance and monitoring

**What it does**:
- System health checks
- Backups of content and configuration
- System update checks
- Log cleanup
- Log analysis
- Report generation

**Usage**:
```bash
# Run all maintenance tasks
sudo ./maintenance.sh all

# Run specific tasks
sudo ./maintenance.sh check      # Health check only
sudo ./maintenance.sh backup     # Backup only
sudo ./maintenance.sh update     # Check for updates
sudo ./maintenance.sh cleanup    # Clean old files
sudo ./maintenance.sh analyze    # Analyze logs
sudo ./maintenance.sh report     # Generate report
```

**Requirements**:
- setup-server.sh must be run first

**Recommended schedule**:
- Daily: `maintenance.sh check`
- Weekly: `maintenance.sh all`

---

## Installation Order

Follow this order for initial setup:

1. **setup-server.sh** - Base server setup
2. **configure-redirects.sh** - URL redirects
3. **setup-handle-server.sh** - Handle server (optional)
4. **deploy-hugo.sh** - Deploy your site
5. **maintenance.sh** - Regular maintenance

## Quick Start

```bash
# 1. Clone this repository
git clone https://github.com/McFateM/Digital.Grinnell-Landing-Page.git
cd Digital.Grinnell-Landing-Page

# 2. Run initial setup
sudo ./scripts/setup-server.sh

# 3. Configure redirects
sudo ./scripts/configure-redirects.sh

# 4. Optional: Setup Handle server
sudo ./scripts/setup-handle-server.sh

# 5. Deploy your Hugo site
./scripts/deploy-hugo.sh

# 6. Run maintenance checks
sudo ./scripts/maintenance.sh check
```

## Configuration

### Customizing Variables

Before running the scripts, you may want to customize these variables:

**setup-server.sh**:
- `DOMAIN` - Your domain name (default: digital.grinnell.edu)
- `ADMIN_EMAIL` - Administrator email
- `HUGO_VERSION` - Hugo version to install
- `HUGO_SITE_NAME` - Hugo site directory name

**setup-handle-server.sh**:
- `HANDLE_VERSION` - Handle server version
- `HANDLE_ADMIN_PORT` - Admin interface port (default: 8000)
- `HANDLE_SERVER_PORT` - Handle resolution port (default: 2641)

Edit the scripts and modify the configuration section at the top.

## Automated Deployment

### Using Cron for Regular Maintenance

Add to crontab (`sudo crontab -e`):

```bash
# Daily health check at 6 AM
0 6 * * * /var/www/Digital.Grinnell-Landing-Page/scripts/maintenance.sh check

# Weekly full maintenance on Sundays at 2 AM
0 2 * * 0 /var/www/Digital.Grinnell-Landing-Page/scripts/maintenance.sh all

# Daily backup at 1 AM
0 1 * * * /var/www/Digital.Grinnell-Landing-Page/scripts/maintenance.sh backup
```

### Automatic Hugo Deployment

For automatic deployment when content changes:

```bash
# Watch for changes and deploy
while inotifywait -e modify,create,delete -r /var/www/digital-grinnell/content; do
    /var/www/Digital.Grinnell-Landing-Page/scripts/deploy-hugo.sh
done
```

## Troubleshooting

### Script fails with permission error
```bash
# Make sure scripts are executable
chmod +x scripts/*.sh

# Run with sudo for system-level changes
sudo ./scripts/setup-server.sh
```

### Apache fails to restart
```bash
# Check Apache configuration
sudo apache2ctl configtest

# View Apache error log
sudo tail -f /var/log/apache2/error.log
```

### Hugo build fails
```bash
# Check Hugo installation
hugo version

# Test Hugo build manually
cd /var/www/digital-grinnell
hugo --verbose
```

### Handle server won't start
```bash
# Check Java installation
java -version

# Check Handle server logs
tail -f /var/www/handle-server/logs/handle-server.log

# Check systemd service status
sudo systemctl status handle-server
```

## Directory Structure After Installation

```
/var/www/
├── digital-grinnell/           # Main Hugo site
│   ├── content/               # Hugo content files
│   ├── themes/                # Hugo themes
│   ├── public/                # Generated static files (served by Apache)
│   ├── redirects/             # Redirect mappings
│   └── config.toml            # Hugo configuration
├── handle-server/             # Handle server installation
│   ├── handle/                # Handle server binaries
│   ├── examples/              # Example Handle records
│   └── logs/                  # Handle server logs
└── backups/                   # Automated backups
    ├── content-*.tar.gz
    ├── config-*.tar.gz
    └── handle-*.tar.gz
```

## Security Considerations

- All scripts should be run with appropriate privileges (sudo when needed)
- Review firewall rules after setup (`sudo ufw status`)
- Keep system packages updated (`sudo apt update && sudo apt upgrade`)
- Monitor Apache logs regularly (`/var/log/apache2/`)
- Ensure SSL certificates auto-renew (`sudo certbot renew --dry-run`)
- Restrict Handle admin interface to localhost only
- Use strong passwords for all admin interfaces

## Support

For issues or questions:
- Review the SPECIFICATIONS.md document in the docs/ directory
- Check Apache error logs: `/var/log/apache2/error.log`
- Check system logs: `sudo journalctl -xe`
- Consult the official documentation:
  - Apache: https://httpd.apache.org/docs/
  - Hugo: https://gohugo.io/documentation/
  - Handle System: https://www.handle.net/tech_manual/

## Contributing

To contribute improvements to these scripts:
1. Test thoroughly on a development server
2. Document any new features or changes
3. Update this README with usage instructions
4. Submit pull request with detailed description

## License

These scripts are provided for use with the Digital.Grinnell project.
