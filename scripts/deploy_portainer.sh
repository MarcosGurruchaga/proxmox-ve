#!/bin/bash
# deploy_portainer.sh - Installs Docker and deploys Portainer CE on Proxmox VE host
set -e

echo "=== Deploying Docker & Portainer CE on 192.168.1.10 ==="

if ! command -v docker &>/dev/null; then
    apt update
    apt install -y docker.io
    systemctl enable --now docker
fi

# Create persistent storage volume
docker volume create portainer_data || true

# Remove old container if exists
docker rm -f portainer 2>/dev/null || true

# Run Portainer CE
docker run -d \
  -p 8000:8000 \
  -p 9000:9000 \
  -p 9443:9443 \
  --name portainer \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:latest

echo "=== Portainer CE running at https://192.168.1.10:9443 ==="
