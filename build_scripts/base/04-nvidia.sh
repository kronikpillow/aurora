#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

# Not available for Fedora 43 yet
dnf config-manager setopt excludepkgs=golang-github-nvidia-container-toolkit

IMAGE_NAME="${BASE_IMAGE_NAME}" AKMODNV_PATH="/tmp/rpms/nvidia" MULTILIB=0 /tmp/rpms/nvidia/ublue-os/nvidia-install.sh
rm -f /usr/share/vulkan/icd.d/nouveau_icd.*.json
ln -sf libnvidia-ml.so.1 /usr/lib64/libnvidia-ml.so
tee /usr/lib/bootc/kargs.d/00-nvidia.toml <<EOF
kargs = ["rd.driver.blacklist=nouveau", "modprobe.blacklist=nouveau", "nvidia-drm.modeset=1", "initcall_blacklist=simpledrm_platform_driver_init"]
EOF

rsync -rvKl /ctx/system_files/nvidia/ /
systemctl enable ublue-nvidia-flatpak-runtime-sync.service

# Configure Docker with NVIDIA runtime and CDI support if Docker is installed (e.g. on DX images)
if command -v docker >/dev/null 2>&1 && command -v nvidia-ctk >/dev/null 2>&1; then
    nvidia-ctk runtime configure --runtime=docker --cdi.enabled
fi

echo "::endgroup::"
