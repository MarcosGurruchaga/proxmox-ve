#!/bin/bash
set -e

echo "Starting network transition to 192.168.1.10..." > /root/apply_network.log

# Backup
cp /etc/network/interfaces /etc/network/interfaces.bak 2>/dev/null || true
cp /etc/hosts /etc/hosts.bak 2>/dev/null || true

# Write new /etc/network/interfaces
cat > /etc/network/interfaces << 'NETEOF'
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
NETEOF

# Update hosts
sed -i 's/192.168.1.4/192.168.1.10/g' /etc/hosts

# Update DNS
cat > /etc/resolv.conf << 'DNSEOF'
nameserver 192.168.1.1
nameserver 1.1.1.1
DNSEOF

# Safety fallback in background
(
  sleep 45
  if ! ping -c 1 -W 2 192.168.1.1 > /dev/null 2>&1; then
    echo "Network unreachable after 45s, rolling back..." >> /root/apply_network.log
    cp /etc/network/interfaces.bak /etc/network/interfaces
    cp /etc/hosts.bak /etc/hosts
    systemctl unmask NetworkManager || true
    systemctl enable --now NetworkManager || true
  else
    echo "Network verified reachable!" >> /root/apply_network.log
  fi
) &

# Apply networking
systemctl stop NetworkManager || true
systemctl disable NetworkManager || true
ip addr flush dev enp37s0 || true
ifup -a || ifreload -a || true
systemctl restart networking || true

echo "Network transition complete." >> /root/apply_network.log
