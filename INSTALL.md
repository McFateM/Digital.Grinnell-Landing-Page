# Quick Installation Guide

This is a step-by-step guide to get your Digital.Grinnell server up and running quickly.

## Pre-Installation Checklist

- [ ] Ubuntu 22.04 LTS or 20.04 LTS server installed
- [ ] Root/sudo access to the server
- [ ] Domain name registered and DNS configured
- [ ] Server has internet connectivity
- [ ] Firewall ports accessible (22, 80, 443)

## Installation Steps

### Step 1: Access Your Server

```bash
ssh user@your-server-ip
```

### Step 2: Clone Repository

```bash
cd /var/www
sudo git clone https://github.com/McFateM/Digital.Grinnell-Landing-Page.git
cd Digital.Grinnell-Landing-Page
```

### Step 3: Configure Settings (Optional)

Before running scripts, you can customize settings:

```bash
# Edit setup-server.sh to customize domain and email
sudo nano scripts/setup-server.sh

# Look for these variables and update them:
# DOMAIN="digital.grinnell.edu"
# ADMIN_EMAIL="admin@grinnell.edu"
# HUGO_VERSION="0.119.0"
```

### Step 4: Run Initial Server Setup

```bash
sudo ./scripts/setup-server.sh
```

**What this does**:
- Installs Apache, Hugo, and dependencies
- Configures web server
- Sets up firewall
- Creates directory structure
- Initializes Hugo site
- Creates custom 404 page

⏱️ **Estimated time**: 10-15 minutes

**When prompted for SSL**:
- Choose 'y' if your domain is already pointing to this server
- Choose 'n' if you want to set up SSL later

### Step 5: Configure URL Redirects

```bash
sudo ./scripts/configure-redirects.sh
```

**What this does**:
- Sets up Apache redirect rules
- Creates .htaccess file
- Configures redirect mappings
- Adds security headers

⏱️ **Estimated time**: 2-5 minutes

### Step 6: Set Up Handle Server (Optional)

**Prerequisites**:
- You must have a Handle prefix from Handle.Net Registry
- Visit: https://www.handle.net/get_handle.html to register

```bash
sudo ./scripts/setup-handle-server.sh
```

**What this does**:
- Downloads Handle server
- Creates systemd service
- Configures Apache proxy
- Sets up examples

⏱️ **Estimated time**: 5-10 minutes

**After running the script**, complete Handle configuration:
```bash
cd /var/www/handle-server/handle
sudo ./bin/hdl-setup-server .
# Follow the interactive prompts
```

### Step 7: Add Your Content

#### Create Hugo Content

```bash
cd /var/www/digital-grinnell

# Create a new page
sudo hugo new content/about.md

# Create a collection
sudo hugo new content/collections/my-collection/_index.md

# Create an item
sudo hugo new content/items/item-001.md
```

#### Edit Content

```bash
# Edit with your preferred editor
sudo nano content/about.md
```

Example content:
```markdown
---
title: "About Digital Grinnell"
date: 2024-01-01
---

# About Digital Grinnell

Welcome to our digital collections...
```

### Step 8: Deploy Your Site

```bash
sudo ./scripts/deploy-hugo.sh
```

**What this does**:
- Backs up current site
- Builds Hugo site
- Optimizes assets
- Sets permissions
- Runs health checks

⏱️ **Estimated time**: 1-3 minutes

### Step 9: Test Your Site

```bash
# Check if site is accessible
curl http://localhost

# Test redirects
sudo /var/www/digital-grinnell/test-redirects.sh localhost
```

Visit your site in a browser:
- http://your-domain.com
- http://your-server-ip

### Step 10: Set Up SSL (If Not Done Earlier)

```bash
sudo certbot --apache -d your-domain.com
```

Follow the prompts to:
- Enter your email
- Agree to terms
- Choose whether to redirect HTTP to HTTPS (recommended: yes)

### Step 11: Set Up Automated Maintenance

```bash
# Edit root crontab
sudo crontab -e

# Add these lines:
# Daily health check at 6 AM
0 6 * * * /var/www/Digital.Grinnell-Landing-Page/scripts/maintenance.sh check

# Daily backup at 1 AM
0 1 * * * /var/www/Digital.Grinnell-Landing-Page/scripts/maintenance.sh backup

# Weekly full maintenance on Sundays at 2 AM
0 2 * * 0 /var/www/Digital.Grinnell-Landing-Page/scripts/maintenance.sh all
```

## Post-Installation

### Verify Everything Works

```bash
# Run health check
sudo ./scripts/maintenance.sh check

# Expected output:
# ✓ Apache is running
# ✓ Site is accessible
# ✓ Disk usage is acceptable
```

### Important Files and Locations

| Item | Location |
|------|----------|
| Hugo site | `/var/www/digital-grinnell` |
| Apache config | `/etc/apache2/sites-available/digital-grinnell.conf` |
| Apache logs | `/var/log/apache2/` |
| Handle server | `/var/www/handle-server` |
| Backups | `/var/www/backups` |
| Scripts | `/var/www/Digital.Grinnell-Landing-Page/scripts` |

### Next Steps

1. **Customize your Hugo theme**:
   ```bash
   cd /var/www/digital-grinnell/themes
   sudo git clone https://github.com/your-theme-repo
   ```

2. **Add more content**:
   - Collections in `content/collections/`
   - Items in `content/items/`
   - Pages in `content/`

3. **Configure custom redirects**:
   ```bash
   sudo nano /var/www/digital-grinnell/.htaccess
   # Add your custom redirects
   ```

4. **Set up Handle records** (if using Handle server):
   ```bash
   cd /var/www/handle-server/examples
   # Review example JSON files
   # Create your own Handle records
   ```

## Troubleshooting

### Site Not Accessible

```bash
# Check Apache status
sudo systemctl status apache2

# Check Apache configuration
sudo apache2ctl configtest

# Restart Apache
sudo systemctl restart apache2
```

### Hugo Build Fails

```bash
# Check Hugo installation
hugo version

# Try building manually
cd /var/www/digital-grinnell
sudo hugo --verbose
```

### Firewall Blocking Access

```bash
# Check firewall status
sudo ufw status

# Allow HTTP and HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

### Permission Issues

```bash
# Fix ownership
sudo chown -R www-data:www-data /var/www/digital-grinnell

# Fix permissions
sudo find /var/www/digital-grinnell -type d -exec chmod 755 {} \;
sudo find /var/www/digital-grinnell -type f -exec chmod 644 {} \;
```

### SSL Certificate Issues

```bash
# Test certificate renewal
sudo certbot renew --dry-run

# Force renewal
sudo certbot renew --force-renewal
```

## Getting Help

If you encounter issues:

1. **Check the logs**:
   ```bash
   sudo tail -f /var/log/apache2/error.log
   ```

2. **Review documentation**:
   - `README.md` - Overview and features
   - `docs/SPECIFICATIONS.md` - Technical details
   - `scripts/README.md` - Script documentation

3. **Run diagnostics**:
   ```bash
   sudo ./scripts/maintenance.sh check
   ```

4. **Check system logs**:
   ```bash
   sudo journalctl -xe
   ```

## Maintenance Schedule

After installation, follow this maintenance schedule:

| Frequency | Task | Command |
|-----------|------|---------|
| Daily | Health check | `sudo ./scripts/maintenance.sh check` |
| Daily | Backup | `sudo ./scripts/maintenance.sh backup` |
| Weekly | Full maintenance | `sudo ./scripts/maintenance.sh all` |
| Monthly | System updates | `sudo apt update && sudo apt upgrade` |
| Quarterly | Review security | Check logs, update certificates |

## Success!

Your Digital.Grinnell server should now be up and running! 🎉

Visit your site at: https://your-domain.com

For ongoing management, refer to the main README.md and documentation in the `docs/` directory.
