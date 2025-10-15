#!/bin/bash
#
# Handle Server Setup Script for Digital.Grinnell
# This script installs and configures CNRI Handle System for persistent identifiers
#
# Usage: sudo ./setup-handle-server.sh
#
# Prerequisites:
#   - Java 11+ must be installed
#   - Apache must be configured
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
HANDLE_VERSION="9.3.1"
INSTALL_DIR="/var/www/handle-server"
HANDLE_ADMIN_PORT="8000"
HANDLE_SERVER_PORT="2641"
HANDLE_PREFIX=""  # Will be set during setup
ADMIN_EMAIL="admin@grinnell.edu"

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

# Function to check Java installation
check_java() {
    print_info "Checking Java installation..."
    
    if ! command -v java &> /dev/null; then
        print_error "Java is not installed. Please install OpenJDK 11 or later."
        exit 1
    fi
    
    java_version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
    print_info "Java version: ${java_version}"
}

# Function to download Handle server
download_handle_server() {
    print_info "Downloading Handle server version ${HANDLE_VERSION}..."
    
    mkdir -p ${INSTALL_DIR}
    cd /tmp
    
    # Download Handle server
    wget "https://www.handle.net/hnr_downloads/handle-${HANDLE_VERSION}-distribution.tar.gz"
    
    # Extract to installation directory
    tar -xzf "handle-${HANDLE_VERSION}-distribution.tar.gz"
    mv "handle-${HANDLE_VERSION}" "${INSTALL_DIR}/handle"
    
    # Clean up
    rm -f "handle-${HANDLE_VERSION}-distribution.tar.gz"
    
    print_info "Handle server downloaded and extracted successfully"
}

# Function to configure Handle server
configure_handle_server() {
    print_info "Configuring Handle server..."
    
    print_warning "You need a Handle prefix from Handle.Net Registry"
    print_warning "Visit: https://www.handle.net/get_handle.html"
    echo
    
    read -p "Enter your Handle prefix (e.g., 10.XXXXX): " HANDLE_PREFIX
    
    if [ -z "$HANDLE_PREFIX" ]; then
        print_error "Handle prefix is required"
        exit 1
    fi
    
    cd "${INSTALL_DIR}/handle"
    
    # Create configuration directory
    mkdir -p svr_1
    
    print_info "Handle server needs to be configured manually using hdl-setup-server"
    print_info "Please follow the interactive prompts"
    
    # Note: The actual setup requires interactive input from Handle.net
    # This would typically be done manually or with expect scripts
    
    cat > "${INSTALL_DIR}/handle/start-handle.sh" << 'EOF'
#!/bin/bash
cd /var/www/handle-server/handle/svr_1
nohup ../bin/hdl-server . > ../logs/handle-server.log 2>&1 &
echo $! > ../handle.pid
echo "Handle server started with PID $(cat ../handle.pid)"
EOF
    
    chmod +x "${INSTALL_DIR}/handle/start-handle.sh"
    
    cat > "${INSTALL_DIR}/handle/stop-handle.sh" << 'EOF'
#!/bin/bash
if [ -f /var/www/handle-server/handle/handle.pid ]; then
    kill $(cat /var/www/handle-server/handle/handle.pid)
    rm -f /var/www/handle-server/handle/handle.pid
    echo "Handle server stopped"
else
    echo "Handle server is not running"
fi
EOF
    
    chmod +x "${INSTALL_DIR}/handle/stop-handle.sh"
    
    print_info "Handle server configuration scripts created"
}

# Function to create systemd service
create_systemd_service() {
    print_info "Creating systemd service for Handle server..."
    
    cat > /etc/systemd/system/handle-server.service << EOF
[Unit]
Description=CNRI Handle System Server
After=network.target

[Service]
Type=forking
User=www-data
Group=www-data
WorkingDirectory=${INSTALL_DIR}/handle/svr_1
ExecStart=${INSTALL_DIR}/handle/bin/hdl-server ${INSTALL_DIR}/handle/svr_1
ExecStop=${INSTALL_DIR}/handle/stop-handle.sh
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    
    # Reload systemd
    systemctl daemon-reload
    
    print_info "Systemd service created"
}

# Function to configure Apache proxy for Handle server
configure_apache_proxy() {
    print_info "Configuring Apache proxy for Handle server..."
    
    # Create proxy configuration
    cat > /etc/apache2/conf-available/handle-proxy.conf << EOF
# Handle Server Proxy Configuration

<IfModule mod_proxy.c>
    # Proxy Handle server admin interface (localhost only)
    <Location /handle-admin>
        ProxyPass http://localhost:${HANDLE_ADMIN_PORT}
        ProxyPassReverse http://localhost:${HANDLE_ADMIN_PORT}
        
        # Restrict access to localhost
        Require ip 127.0.0.1
    </Location>
    
    # Proxy Handle resolution requests
    <Location /handle>
        ProxyPass http://localhost:${HANDLE_SERVER_PORT}
        ProxyPassReverse http://localhost:${HANDLE_SERVER_PORT}
        
        Require all granted
    </Location>
</IfModule>
EOF
    
    # Enable configuration
    a2enconf handle-proxy
    
    # Test and reload Apache
    apache2ctl configtest
    systemctl reload apache2
    
    print_info "Apache proxy configured successfully"
}

# Function to create sample Handle records
create_sample_handles() {
    print_info "Creating sample Handle record templates..."
    
    mkdir -p "${INSTALL_DIR}/examples"
    
    cat > "${INSTALL_DIR}/examples/create-handle-collection.json" << 'EOF'
{
    "handle": "PREFIX/collection.123",
    "values": [
        {
            "index": 1,
            "type": "URL",
            "data": {
                "format": "string",
                "value": "https://digital.grinnell.edu/collections/sample-collection"
            }
        },
        {
            "index": 2,
            "type": "EMAIL",
            "data": {
                "format": "string",
                "value": "admin@grinnell.edu"
            }
        },
        {
            "index": 100,
            "type": "HS_ADMIN",
            "data": {
                "format": "admin",
                "value": {
                    "handle": "0.NA/PREFIX",
                    "index": 200,
                    "permissions": "011111110011"
                }
            }
        }
    ]
}
EOF
    
    cat > "${INSTALL_DIR}/examples/create-handle-item.json" << 'EOF'
{
    "handle": "PREFIX/item.456",
    "values": [
        {
            "index": 1,
            "type": "URL",
            "data": {
                "format": "string",
                "value": "https://digital.grinnell.edu/items/sample-item-456"
            }
        },
        {
            "index": 2,
            "type": "EMAIL",
            "data": {
                "format": "string",
                "value": "admin@grinnell.edu"
            }
        },
        {
            "index": 3,
            "type": "DESC",
            "data": {
                "format": "string",
                "value": "Digital object from Digital Grinnell collection"
            }
        },
        {
            "index": 100,
            "type": "HS_ADMIN",
            "data": {
                "format": "admin",
                "value": {
                    "handle": "0.NA/PREFIX",
                    "index": 200,
                    "permissions": "011111110011"
                }
            }
        }
    ]
}
EOF
    
    cat > "${INSTALL_DIR}/examples/README.md" << 'EOF'
# Handle Server Examples

## Creating Handle Records

### Using Command Line
```bash
cd /var/www/handle-server/handle/bin
./hdl-admintool
```

### Using REST API
```bash
# Create a handle
curl -X PUT \
  -H "Content-Type: application/json" \
  -d @create-handle-collection.json \
  http://localhost:8000/api/handles/PREFIX/collection.123

# Resolve a handle
curl http://localhost:8000/api/handles/PREFIX/collection.123

# Delete a handle
curl -X DELETE http://localhost:8000/api/handles/PREFIX/collection.123
```

### Handle Types

- **URL**: The primary URL the handle resolves to
- **EMAIL**: Contact email for the resource
- **DESC**: Description of the resource
- **HS_ADMIN**: Administrative information for the handle

## Testing Handle Resolution

```bash
# Test local resolution
curl http://localhost:2641/api/handles/PREFIX/collection.123

# Test via Apache proxy
curl http://localhost/handle/PREFIX/collection.123
```

## Managing Handles

Refer to the Handle System documentation:
https://www.handle.net/tech_manual/HN_Tech_Manual_9.pdf
EOF
    
    print_info "Sample Handle templates created in ${INSTALL_DIR}/examples"
}

# Function to set permissions
set_permissions() {
    print_info "Setting correct permissions..."
    
    chown -R www-data:www-data ${INSTALL_DIR}
    chmod -R 755 ${INSTALL_DIR}
    
    print_info "Permissions set successfully"
}

# Function to print completion message
print_completion() {
    echo
    print_info "============================================"
    print_info "Handle server setup completed!"
    print_info "============================================"
    echo
    print_info "Next steps:"
    echo "  1. Complete Handle server configuration:"
    echo "     cd ${INSTALL_DIR}/handle"
    echo "     ./bin/hdl-setup-server ."
    echo
    echo "  2. Start Handle server:"
    echo "     systemctl start handle-server"
    echo "     systemctl enable handle-server"
    echo
    echo "  3. Check Handle server status:"
    echo "     systemctl status handle-server"
    echo
    echo "  4. Test Handle resolution:"
    echo "     curl http://localhost:${HANDLE_SERVER_PORT}/api/handles/YOUR_PREFIX/test"
    echo
    print_info "Important files:"
    echo "  - Handle installation: ${INSTALL_DIR}/handle"
    echo "  - Examples: ${INSTALL_DIR}/examples"
    echo "  - Service: /etc/systemd/system/handle-server.service"
    echo "  - Apache config: /etc/apache2/conf-available/handle-proxy.conf"
    echo
    print_warning "Remember to:"
    echo "  - Register your Handle prefix at https://www.handle.net"
    echo "  - Configure firewall rules for Handle server ports"
    echo "  - Set up backup procedures for Handle database"
    echo
}

# Main execution
main() {
    print_info "Starting Handle server setup..."
    
    check_root
    check_java
    download_handle_server
    configure_handle_server
    create_systemd_service
    configure_apache_proxy
    create_sample_handles
    set_permissions
    print_completion
}

# Run main function
main
