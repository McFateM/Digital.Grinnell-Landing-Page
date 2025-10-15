#!/bin/bash
#
# Maintenance and Monitoring Script for Digital.Grinnell
# This script performs routine maintenance and health checks
#
# Usage: ./maintenance.sh [check|backup|update|cleanup|all]
#
# Author: Digital.Grinnell Team
# Version: 1.0

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
HUGO_SITE_DIR="/var/www/digital-grinnell"
BACKUP_DIR="/var/www/backups"
LOG_DIR="/var/log/digital-grinnell"
APACHE_LOG_DIR="/var/log/apache2"
ACTION="${1:-check}"

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

# Function to check system health
check_health() {
    print_info "=== System Health Check ==="
    echo
    
    # Check Apache status
    print_info "Apache Status:"
    if systemctl is-active --quiet apache2; then
        echo "  ✓ Apache is running"
    else
        echo "  ✗ Apache is not running"
    fi
    
    # Check Handle server status
    print_info "Handle Server Status:"
    if systemctl is-active --quiet handle-server 2>/dev/null; then
        echo "  ✓ Handle server is running"
    else
        echo "  ⓘ Handle server is not running (may not be configured)"
    fi
    
    # Check disk usage
    print_info "Disk Usage:"
    df -h | grep -E '^/dev/' | awk '{printf "  %s: %s used (%s)\n", $1, $5, $3}'
    
    # Check memory usage
    print_info "Memory Usage:"
    free -h | grep Mem | awk '{printf "  Used: %s / %s (%s%%)\n", $3, $2, int($3/$2*100)}'
    
    # Check CPU load
    print_info "CPU Load:"
    uptime | awk -F'load average:' '{print "  " $2}'
    
    # Check site accessibility
    print_info "Site Accessibility:"
    if curl -s -o /dev/null -w "%{http_code}" http://localhost | grep -q "200"; then
        echo "  ✓ Site is accessible (HTTP 200)"
    else
        echo "  ✗ Site may not be accessible"
    fi
    
    # Check SSL certificate expiration
    print_info "SSL Certificate:"
    if [ -d "/etc/letsencrypt/live" ]; then
        for cert_dir in /etc/letsencrypt/live/*/; do
            domain=$(basename "$cert_dir")
            if [ -f "${cert_dir}cert.pem" ]; then
                expiry=$(openssl x509 -enddate -noout -in "${cert_dir}cert.pem" | cut -d= -f2)
                echo "  ${domain}: expires ${expiry}"
            fi
        done
    else
        echo "  ⓘ No SSL certificates found"
    fi
    
    # Check recent errors in Apache logs
    print_info "Recent Apache Errors (last 24 hours):"
    if [ -f "${APACHE_LOG_DIR}/error.log" ]; then
        error_count=$(find "${APACHE_LOG_DIR}/error.log" -mtime -1 -exec grep -c "error" {} \; 2>/dev/null || echo "0")
        echo "  Error count: ${error_count}"
        if [ "$error_count" -gt 100 ]; then
            print_warning "High error count detected!"
        fi
    fi
    
    echo
}

# Function to perform backups
perform_backup() {
    print_info "=== Performing Backups ==="
    echo
    
    mkdir -p "$BACKUP_DIR"
    timestamp=$(date +%Y%m%d_%H%M%S)
    
    # Backup Hugo content
    print_info "Backing up Hugo content..."
    if [ -d "${HUGO_SITE_DIR}/content" ]; then
        tar -czf "${BACKUP_DIR}/content-${timestamp}.tar.gz" -C "${HUGO_SITE_DIR}" content
        print_info "Content backup: content-${timestamp}.tar.gz"
    fi
    
    # Backup Hugo configuration
    if [ -f "${HUGO_SITE_DIR}/config.toml" ] || [ -f "${HUGO_SITE_DIR}/hugo.toml" ]; then
        print_info "Backing up Hugo configuration..."
        tar -czf "${BACKUP_DIR}/config-${timestamp}.tar.gz" -C "${HUGO_SITE_DIR}" config* hugo* 2>/dev/null || true
        print_info "Config backup: config-${timestamp}.tar.gz"
    fi
    
    # Backup Apache configuration
    print_info "Backing up Apache configuration..."
    tar -czf "${BACKUP_DIR}/apache-config-${timestamp}.tar.gz" /etc/apache2/sites-available /etc/apache2/conf-available 2>/dev/null
    print_info "Apache config backup: apache-config-${timestamp}.tar.gz"
    
    # Backup Handle server data (if exists)
    if [ -d "/var/www/handle-server/handle" ]; then
        print_info "Backing up Handle server data..."
        tar -czf "${BACKUP_DIR}/handle-${timestamp}.tar.gz" -C /var/www/handle-server handle
        print_info "Handle backup: handle-${timestamp}.tar.gz"
    fi
    
    # Remove old backups (keep last 30 days)
    print_info "Cleaning old backups (keeping last 30 days)..."
    find "$BACKUP_DIR" -name "*.tar.gz" -mtime +30 -delete
    
    # Show backup summary
    echo
    print_info "Backup Summary:"
    du -sh "$BACKUP_DIR"
    echo "  Total backups: $(ls -1 "$BACKUP_DIR" | wc -l)"
    
    echo
}

# Function to update system
update_system() {
    print_info "=== Updating System ==="
    echo
    
    # Update package lists
    print_info "Updating package lists..."
    apt-get update -qq
    
    # List available updates
    print_info "Available updates:"
    apt list --upgradable 2>/dev/null | grep -v "Listing..." || echo "  System is up to date"
    
    # Check for security updates
    print_info "Security updates:"
    security_updates=$(apt-get upgrade -s | grep -i security | wc -l)
    if [ "$security_updates" -gt 0 ]; then
        print_warning "$security_updates security updates available!"
        echo "  Run 'sudo apt-get upgrade' to install"
    else
        echo "  No security updates needed"
    fi
    
    # Update Hugo (check for new version)
    print_info "Checking Hugo version..."
    if command -v hugo &> /dev/null; then
        current_version=$(hugo version | awk '{print $2}' | head -n1)
        echo "  Current Hugo version: ${current_version}"
        echo "  Check https://github.com/gohugoio/hugo/releases for latest version"
    fi
    
    echo
}

# Function to cleanup old files
cleanup_files() {
    print_info "=== Cleaning Up Old Files ==="
    echo
    
    # Clean old logs
    print_info "Cleaning old Apache logs (older than 90 days)..."
    find "${APACHE_LOG_DIR}" -name "*.gz" -mtime +90 -delete 2>/dev/null || true
    find "${APACHE_LOG_DIR}" -name "*.log.*" -mtime +90 -delete 2>/dev/null || true
    
    # Clean temporary files
    print_info "Cleaning temporary files..."
    find /tmp -name "hugo*" -mtime +7 -delete 2>/dev/null || true
    
    # Clean old backups (already done in backup function, but double-check)
    print_info "Verifying backup retention..."
    old_backups=$(find "$BACKUP_DIR" -name "*.tar.gz" -mtime +30 | wc -l)
    if [ "$old_backups" -gt 0 ]; then
        print_warning "Found $old_backups old backups to clean"
        find "$BACKUP_DIR" -name "*.tar.gz" -mtime +30 -delete
    fi
    
    # Clean package cache
    print_info "Cleaning package cache..."
    apt-get clean
    apt-get autoremove -y -qq
    
    # Show disk space saved
    echo
    print_info "Disk space after cleanup:"
    df -h / | tail -n 1 | awk '{print "  Used: " $3 " / " $2 " (" $5 ")"}'
    
    echo
}

# Function to analyze logs
analyze_logs() {
    print_info "=== Log Analysis ==="
    echo
    
    # Top 10 most accessed pages
    print_info "Top 10 most accessed pages (last 7 days):"
    if [ -f "${APACHE_LOG_DIR}/access.log" ]; then
        awk '{print $7}' "${APACHE_LOG_DIR}/access.log"* | sort | uniq -c | sort -rn | head -10 | while read count url; do
            echo "  $count - $url"
        done
    fi
    
    echo
    
    # Top 10 referrers
    print_info "Top 10 referrers:"
    if [ -f "${APACHE_LOG_DIR}/access.log" ]; then
        awk '{print $11}' "${APACHE_LOG_DIR}/access.log"* | sort | uniq -c | sort -rn | head -10 | while read count referrer; do
            echo "  $count - $referrer"
        done
    fi
    
    echo
    
    # Recent 404 errors
    print_info "Recent 404 errors (last 50):"
    if [ -f "${APACHE_LOG_DIR}/access.log" ]; then
        grep " 404 " "${APACHE_LOG_DIR}/access.log" | tail -50 | awk '{print "  " $7}' | sort | uniq -c | sort -rn
    fi
    
    echo
}

# Function to generate maintenance report
generate_report() {
    print_info "=== Maintenance Report ==="
    echo
    
    report_file="${LOG_DIR}/maintenance-report-$(date +%Y%m%d).txt"
    mkdir -p "$LOG_DIR"
    
    {
        echo "Digital.Grinnell Maintenance Report"
        echo "Generated: $(date)"
        echo "========================================"
        echo
        
        # System info
        echo "System Information:"
        echo "  Hostname: $(hostname)"
        echo "  OS: $(lsb_release -d | cut -f2)"
        echo "  Kernel: $(uname -r)"
        echo "  Uptime: $(uptime -p)"
        echo
        
        # Service status
        echo "Service Status:"
        systemctl status apache2 --no-pager | head -5
        echo
        
        # Disk usage
        echo "Disk Usage:"
        df -h
        echo
        
        # Recent errors
        echo "Recent Apache Errors:"
        tail -20 "${APACHE_LOG_DIR}/error.log" 2>/dev/null || echo "No errors found"
        echo
        
    } > "$report_file"
    
    print_info "Report saved to: $report_file"
    echo
}

# Function to print usage
print_usage() {
    echo "Usage: $0 [check|backup|update|cleanup|analyze|report|all]"
    echo
    echo "Actions:"
    echo "  check   - Perform system health checks"
    echo "  backup  - Backup critical files"
    echo "  update  - Check for system updates"
    echo "  cleanup - Clean up old files and logs"
    echo "  analyze - Analyze Apache logs"
    echo "  report  - Generate maintenance report"
    echo "  all     - Perform all actions"
    echo
}

# Main execution
main() {
    echo "Digital.Grinnell Maintenance Script"
    echo "====================================="
    echo
    
    case "$ACTION" in
        check)
            check_health
            ;;
        backup)
            perform_backup
            ;;
        update)
            update_system
            ;;
        cleanup)
            cleanup_files
            ;;
        analyze)
            analyze_logs
            ;;
        report)
            generate_report
            ;;
        all)
            check_health
            perform_backup
            update_system
            cleanup_files
            analyze_logs
            generate_report
            ;;
        *)
            print_error "Unknown action: $ACTION"
            print_usage
            exit 1
            ;;
    esac
    
    print_info "Maintenance completed!"
}

# Run main function
main
