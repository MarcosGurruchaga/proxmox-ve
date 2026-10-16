#!/bin/bash
# setup_network.sh - Configures Proxmox VE with static IP 192.168.1.10 and Linux Bridge vmbr0
set -e

echo "=== Configuring Network for Proxmox VE ==="

# Backup current network configuration
cp /etc/network/interfaces /etc/network/interfaces.bak.$(date +%s) 2>/dev/null || true
cp /etc/hosts /etc/hosts.bak.$(date +%s) 2>/dev/null || true

# Write /etc/network/interfaces
cat > /etc/network/interfaces << 'EOF'
auto lo
iface lo inet loopback

iface enp37s0 inet manual

auto vmbr0
iface vmbr0 inet static
	address 192.168.1.10/24
	gateway 192.168.1.1
	bridge-ports enp37s0
	bridge-stp off
	bridge-fd 0

source /etc/network/interfaces.d/*
EOF

# Update hosts mapping
sed -i 's/192.168.1.4/192.168.1.10/g' /etc/hosts
if ! grep -q "192.168.1.10" /etc/hosts; then
    echo "192.168.1.10   debian.local debian" >> /etc/hosts
fi

# Configure DNS
cat > /etc/resolv.conf << 'EOF'
nameserver 192.168.1.1
nameserver 1.1.1.1
EOF

# Disable NetworkManager to prevent conflicts with ifupdown2
systemctl stop NetworkManager || true
systemctl disable NetworkManager || true

# Apply network configuration
ifup -a || ifreload -a || systemctl restart networking

echo "=== Network configured: 192.168.1.10/24 on vmbr0 ==="
