#!/usr/bin/env bash
set -euo pipefail

echo "Installing virtualization prerequisites for Rocky/RHEL host..."
sudo dnf install -y qemu-kvm libvirt virt-install packer xorriso lorax wget

echo "Installing Packer QEMU plugin..."
packer plugins install github.com/hashicorp/qemu[cite: 8]
