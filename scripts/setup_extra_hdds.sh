#!/bin/bash
# setup_extra_hdds.sh - Formats and prepares secondary 500GB and 1TB mechanical hard drives for Proxmox VE
set -e

echo "=== Unmounting old mounts ==="
umount /mnt/vm-storage 2>/dev/null || true
rm -rf /mnt/vm-storage

# Remove old mount line from /etc/fstab
sed -i '/94F0DF34F0DF1B76/d' /etc/fstab
sed -i '/HDD_500G/d' /etc/fstab
sed -i '/HDD_1TB/d' /etc/fstab

echo "=== 1. Formatting 500GB HDD (/dev/sdb - ST500DM002-1SB10A) ==="
wipefs -a /dev/sdb
parted -s /dev/sdb mklabel gpt mkpart primary ext4 1MiB 100%
partprobe /dev/sdb || true
sleep 2

mkfs.ext4 -F -m 1 -L HDD_500G /dev/sdb1
mkdir -p /mnt/hdd-500g
mount -t ext4 -o defaults,noatime /dev/sdb1 /mnt/hdd-500g

mkdir -p /mnt/hdd-500g/proxmox-data/images
mkdir -p /mnt/hdd-500g/proxmox-data/template/iso
mkdir -p /mnt/hdd-500g/proxmox-data/dump

echo "LABEL=HDD_500G /mnt/hdd-500g ext4 defaults,noatime 0 2" >> /etc/fstab

echo "=== 2. Formatting 1TB HDD (/dev/sdc - HGST HTS541010B7E610) ==="
wipefs -a /dev/sdc
parted -s /dev/sdc mklabel gpt mkpart primary ext4 1MiB 100%
partprobe /dev/sdc || true
sleep 2

mkfs.ext4 -F -m 1 -L HDD_1TB /dev/sdc1
mkdir -p /mnt/hdd-1tb
mount -t ext4 -o defaults,noatime /dev/sdc1 /mnt/hdd-1tb

mkdir -p /mnt/hdd-1tb/proxmox-data/images
mkdir -p /mnt/hdd-1tb/proxmox-data/template/iso
mkdir -p /mnt/hdd-1tb/proxmox-data/dump

echo "LABEL=HDD_1TB /mnt/hdd-1tb ext4 defaults,noatime 0 2" >> /etc/fstab

echo "=== 3. Updating Proxmox Storage Configuration (/etc/pve/storage.cfg) ==="
cat > /etc/pve/storage.cfg << 'EOF'
dir: local
	path /var/lib/vz
	content iso,vztmpl,backup

dir: ssd-storage
	path /mnt/ssd-storage/proxmox-data
	content images,iso,backup,vztmpl
	shared 0

dir: hdd-500g
	path /mnt/hdd-500g/proxmox-data
	content images,iso,backup,vztmpl
	shared 0

dir: hdd-1tb
	path /mnt/hdd-1tb/proxmox-data
	content images,iso,backup,vztmpl
	shared 0
EOF

echo "=== 4. Storage Pools Status ==="
pvesm status

echo "=== 5. Disk Space Verification ==="
df -h /mnt/ssd-storage /mnt/hdd-500g /mnt/hdd-1tb

echo "=== Hard Drives Formatted and Configured Successfully for Proxmox VE! ==="
