#!/bin/bash
# setup_vfio_passthrough.sh - Configures AMD-Vi IOMMU and VFIO for NVIDIA GeForce GTX 1060
set -e

echo "=== Configuring PCIe Passthrough for GTX 1060 ==="

# 1. Kernel modules for VFIO
cat > /etc/modules-load.d/vfio.conf << 'EOF'
vfio
vfio_iommu_type1
vfio_pci
EOF

# 2. Modprobe configuration: bind GTX 1060 (10de:1b83, 10de:10f0) to vfio-pci
cat > /etc/modprobe.d/vfio.conf << 'EOF'
options vfio-pci ids=10de:1b83,10de:10f0 disable_vga=1
softdep nouveau pre: vfio-pci
softdep nvidia pre: vfio-pci
softdep snd_hda_intel pre: vfio-pci
EOF

# 3. Blacklist host drivers from grabbing the GPU
cat > /etc/modprobe.d/blacklist.conf << 'EOF'
blacklist nouveau
blacklist nvidia
blacklist nvidiafb
blacklist snd_hda_intel
EOF

# 4. GRUB configuration for AMD-Vi and Framebuffer release
mkdir -p /etc/default/grub.d
cat > /etc/default/grub.d/vfio.cfg << 'EOF'
GRUB_CMDLINE_LINUX_DEFAULT="${GRUB_CMDLINE_LINUX_DEFAULT} amd_iommu=on iommu=pt video=efifb:off,vesafb:off,simplefb:off initcall_blacklist=sysfb_init"
EOF

update-grub
update-initramfs -u -k all

echo "=== VFIO Passthrough configured successfully! ==="
