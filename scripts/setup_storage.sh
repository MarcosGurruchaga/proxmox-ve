#!/bin/bash
# setup_storage.sh - Mounts second hard drive and configures Proxmox VE storage pool
set -e

echo "=== Configuring VM and ISO Storage ==="

MOUNT_POINT="/mnt/vm-storage"
PARTITION_UUID="94F0DF34F0DF1B76"

mkdir -p "$MOUNT_POINT"

# Fix potential dirty NTFS flag from Windows fast startup
ntfsfix -d /dev/disk/by-uuid/"$PARTITION_UUID" || true

# Mount filesystem
if ! mountpoint -q "$MOUNT_POINT"; then
    mount -t ntfs-3g -o rw,nofail,uid=0,gid=0 /dev/disk/by-uuid/"$PARTITION_UUID" "$MOUNT_POINT"
fi

# Ensure fstab entry
if ! grep -q "$PARTITION_UUID" /etc/fstab; then
    echo "UUID=$PARTITION_UUID $MOUNT_POINT ntfs-3g rw,nofail,uid=0,gid=0 0 0" >> /etc/fstab
fi

# Create Proxmox directory structure
mkdir -p "$MOUNT_POINT/proxmox-data/images"
mkdir -p "$MOUNT_POINT/proxmox-data/template/iso"
mkdir -p "$MOUNT_POINT/proxmox-data/dump"

# Configure Proxmox storage
cat > /etc/pve/storage.cfg << 'EOF'
dir: local
	path /var/lib/vz
	content iso,vztmpl,backup

dir: hdd-storage
	path /mnt/vm-storage/proxmox-data
	content images,iso,backup,vztmpl
	shared 0
EOF

pvesm status
echo "=== Storage configuration complete ==="
