# Digital.Grinnell-Landing-Page
Specifications and scripts for creating and managing the Digital.Grinnell landing page, redirection, Handles, and custom 404 response.

## Project Overview

This project provides specifications and bash scripts to build an Ubuntu on-prem VM Apache web server capable of:
- Displaying a Hugo static site landing page and collection hierarchy
- Redirecting outdated requests
- Serving a custom 404 error page
- Running a Handle (hdl.net) server for digital items and collections

## Original Prompt

> Current Date and Time (UTC - YYYY-MM-DD HH:MM:SS formatted): 2025-10-15 16:49:01
> Current User's Login: McFateM
> 
> In this repo, create specifications and bash scripts, if possible, to build an Ubuntu on-prem VM Apache web server capable of displaying a Hugo static site landing page and collection hierarchy, redirecting outdated requests, a custom 404 error page, and a Handle (hdl.net) server for digital items and collections. Add this prompt to the project's README.md file.

## System Requirements

- Ubuntu 22.04 LTS or newer
- Minimum 2GB RAM
- 20GB available disk space
- Root or sudo access
- Active internet connection during setup

## Installation

Run the main installation script:

```bash
sudo bash ./scripts/install.sh
```

## Architecture

### Components

1. **Apache Web Server** - Serves static content and handles redirects
2. **Hugo Static Site** - Landing page and collection hierarchy
3. **Handle Server** - Manages persistent identifiers (hdl.net)
4. **Custom Error Pages** - User-friendly 404 responses

### Directory Structure

```
/var/www/
├── digital-grinnell/          # Hugo static site output
│   ├── index.html
│   ├── collections/
│   └── ...
├── error-pages/               # Custom error pages
│   └── 404.html
└── handle-server/             # Handle server installation
    ├── handle-9.x.x/
    └── logs/
```

## Configuration Files

See the `config/` directory for:
- `apache-vhost.conf` - Apache virtual host configuration
- `redirects.conf` - URL redirection rules
- `handle-config.json` - Handle server configuration
- `hugo-config.toml` - Hugo site configuration

## Scripts

- `scripts/install.sh` - Main installation script
- `scripts/setup-apache.sh` - Apache setup and configuration
- `scripts/setup-hugo.sh` - Hugo installation and site generation
- `scripts/setup-handle-server.sh` - Handle server installation
- `scripts/configure-redirects.sh` - Configure URL redirects
- `scripts/setup-404.sh` - Custom 404 page setup

## Usage

### Updating the Hugo Site

```bash
cd /var/www/hugo-source
# Make your changes
hugo
sudo cp -r public/* /var/www/digital-grinnell/
```

### Restarting Services

```bash
sudo systemctl restart apache2
sudo systemctl restart handle-server
```

### Checking Logs

```bash
# Apache logs
sudo tail -f /var/log/apache2/error.log
sudo tail -f /var/log/apache2/access.log

# Handle server logs
sudo tail -f /var/www/handle-server/logs/error.log
```

## Testing

Verify the installation:

```bash
bash ./scripts/test-installation.sh
```

## Maintenance

- Regular updates: `sudo apt update && sudo apt upgrade`
- Monitor disk space: `df -h`
- Check service status: `sudo systemctl status apache2 handle-server`

## License

[Specify your license here]

## Contributors

- McFateM
