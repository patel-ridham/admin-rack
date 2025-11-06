#!/bin/bash

# Set Proxy Variables
echo "Updating proxy settings..."
PROXY_URL="http://proxy-iind.intel.com:912"
HTTP_PROXY="http_proxy=$PROXY_URL"
HTTPS_PROXY="https_proxy=$PROXY_URL"
NO_PROXY="no_proxy=127.0.0.1,localhost,.intel.com,.cluster.local,.intel.local,10.233.0.0/18,10.49.92.0/23"

# Check if /etc/environment file exists
if [ ! -f /etc/environment ]; then
    echo "/etc/environment file is missing! Creating a new one..."
    touch /etc/environment
else
    echo "/etc/environment file exists. Proceeding with the backup..."

    # Check if backup of /etc/environment already exists
    if [ -f /etc/environment.bak ]; then
        echo "Backup of /etc/environment already exists. Removing the old backup..."
        rm /etc/environment.bak
    fi

    # Create a new backup of /etc/environment
    echo "Backing up /etc/environment..."
    cp /etc/environment /etc/environment.bak
fi

# Recreate /etc/environment and add proxy values
echo "Configuring proxy settings in /etc/environment..."
echo "$HTTP_PROXY" > /etc/environment
echo "$HTTPS_PROXY" >> /etc/environment
echo "$NO_PROXY" >> /etc/environment

# Source /etc/environment to apply the settings for the current session
echo "Applying proxy settings to the current shell session..."
source /etc/environment

# Check if bkc repo exists before attempting to move it
echo "Checking for bkc yum repositories..."
BKC_REPO_FILES=$(ls /etc/yum.repos.d/bkc* 2>/dev/null)

if [ -z "$BKC_REPO_FILES" ]; then
    echo "No bkc yum repositories found. Skipping removal."
else
    echo "bkc yum repositories found. Removing them..."
    mv /etc/yum.repos.d/bkc* ~/
fi

# Update system with yum
echo "Updating system packages..."
yum update --allowerasing --skip-broken --nobest -y

# Install required packages
echo "Installing required packages..."
yum install -y socat ipset container-selinux conntrack-tools

echo "Script execution completed successfully!"