#!/bin/bash
set -e

echo "=== Formatting Kingston 480GB/500GB SSD (/dev/sda) ==="
wipefs -a /dev/sda
parted -s /dev/sda mklabel gpt mkpart primary ext4 1MiB 100%
partprobe /dev/sda || true
sleep 2

mkfs.ext4 -F -m 1 -L SSD_VMS /dev/sda1
mkdir -p /mnt/ssd-storage
mount -t ext4 -o defaults,noatime,discard /dev/sda1 /mnt/ssd-storage

mkdir -p /mnt/ssd-storage/proxmox-data/images
mkdir -p /mnt/ssd-storage/proxmox-data/template/iso
mkdir -p /mnt/ssd-storage/proxmox-data/dump

# Add to /etc/fstab
if ! grep -q "LABEL=SSD_VMS" /etc/fstab; then
    echo "LABEL=SSD_VMS /mnt/ssd-storage ext4 defaults,noatime,discard 0 2" >> /etc/fstab
fi

# Configure Proxmox storage pool
cat > /etc/pve/storage.cfg << 'EOF'
dir: local
	path /var/lib/vz
	content iso,vztmpl,backup

dir: ssd-storage
	path /mnt/ssd-storage/proxmox-data
	content images,iso,backup,vztmpl
	shared 0

dir: hdd-storage
	path /mnt/vm-storage/proxmox-data
	content images,iso,backup,vztmpl
	shared 0
EOF

pvesm status
df -h /mnt/ssd-storage
echo "=== Kingston SSD Formatted and Mounted Successfully! ==="
