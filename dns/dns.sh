#!/bin/bash

COREDNS_VERSION="1.12.4"
COREDNS_DIR="/usr/local/bin"
COREDNS_CONFIG_DIR="/etc/coredns"
COREDNS_BINARY_PATH="$COREDNS_DIR/coredns"
COREDNS_CONFIG_FILE="$COREDNS_CONFIG_DIR/Corefile"
COREDNS_HOSTS_FILE="$COREDNS_CONFIG_DIR/hosts"
SYSTEMD_SERVICE_FILE="/etc/systemd/system/coredns.service"
DOMAIN_NAME="intel.local"

# --- Pre-installation checks ---
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root."
    exit 1
fi

# --- Main script starts here ---

echo "Starting CoreDNS setup for domain: $DOMAIN_NAME"

# 1. Create configuration directory
echo "1. Creating configuration directory at $COREDNS_CONFIG_DIR..."
mkdir -p "$COREDNS_CONFIG_DIR"

# 2. Download and install CoreDNS binary
echo "2. Downloading and installing CoreDNS binary version $COREDNS_VERSION..."
wget -q "https://github.com/coredns/coredns/releases/download/v${COREDNS_VERSION}/coredns_${COREDNS_VERSION}_linux_amd64.tgz" -O /tmp/coredns.tgz
tar -xvzf /tmp/coredns.tgz -C /tmp
mv /tmp/coredns "$COREDNS_BINARY_PATH"
rm -f /tmp/coredns.tgz /tmp/README.md /tmp/LICENSE
chmod +x "$COREDNS_BINARY_PATH"

# 3. Create the Corefile
echo "3. Creating Corefile at $COREDNS_CONFIG_FILE..."
tee "$COREDNS_CONFIG_FILE" > /dev/null <<EOF
. {
    hosts $COREDNS_HOSTS_FILE {
        reload 5s
        fallthrough
    }
    forward . 10.248.2.1
    log
    errors
}
EOF

# 4. Create the hosts file with a sample entry
echo "4. Creating hosts file with a sample entry for $DOMAIN_NAME..."
tee "$COREDNS_HOSTS_FILE" > /dev/null <<EOF
# --- CoreDNS hosts file for $DOMAIN_NAME ---
#
# Add your custom DNS entries below in the format:
# IP_ADDRESS      HOSTNAME
#
# Examples:
# 192.168.1.100   server1.intel.local
# 192.168.1.101   db.intel.local
# 192.168.1.1     router.intel.local
#
127.0.0.1       localhost
192.168.1.250   coredns.intel.local
EOF

# 5. Create the systemd service file
echo "5. Creating systemd service file at $SYSTEMD_SERVICE_FILE..."
tee "$SYSTEMD_SERVICE_FILE" > /dev/null <<EOF
[Unit]
Description=CoreDNS DNS server
Documentation=https://coredns.io
After=network.target

[Service]
User=root
Group=root
LimitNOFILE=1048576
WorkingDirectory=$COREDNS_CONFIG_DIR
ExecStart=$COREDNS_BINARY_PATH -conf $COREDNS_CONFIG_FILE
Restart=on-failure
RestartSec=5s
StandardOutput=append:/var/log/coredns.stdout.log
StandardError=append:/var/log/coredns.stdout.log
[Install]
WantedBy=multi-user.target
EOF

# 6. Reload systemd, enable and start the service
echo "6. Reloading systemd, enabling and starting the CoreDNS service..."
systemctl stop systemd-resolved
systemctl disable systemd-resolved
systemctl daemon-reload
systemctl enable coredns
systemctl start coredns

# 7. Check service status
echo "7. Checking CoreDNS service status..."
systemctl status coredns --no-pager

echo "Setup complete. To add more DNS entries, edit the file $COREDNS_HOSTS_FILE."
echo "Changes to the hosts file will be automatically reloaded by CoreDNS."