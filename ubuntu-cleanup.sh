#!/usr/bin/env bash
set -Eeuo pipefail

# Ubuntu Cleanup
# Removes:
#   - installed Snap packages
#   - snapd
#   - cloud-init
#   - cloud-initramfs-copymods
#   - cloud-initramfs-dyn-netconf
#
# IMPORTANT:
# Existing /etc/netplan configuration is NOT removed.

if [[ $EUID -ne 0 ]]; then
    echo "ERROR: This script must be run as root."
    echo "Use: sudo bash $0"
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive

echo "=================================================="
echo " Ubuntu Snap + Cloud-Init Cleanup"
echo "=================================================="

# --------------------------------------------------
# 1. Remove installed snaps
# --------------------------------------------------

echo
echo "[1/6] Removing installed Snap packages..."

if command -v snap >/dev/null 2>&1; then

    # Remove applications first.
    mapfile -t snaps < <(
        snap list 2>/dev/null |
        awk 'NR > 1 {print $1}' |
        grep -Ev '^(snapd|core|core[0-9]+|bare)$' || true
    )

    for pkg in "${snaps[@]}"; do
        [[ -z "$pkg" ]] && continue
        echo "Removing snap: $pkg"
        snap remove --purge "$pkg" || true
    done

    # Remove remaining base/system snaps.
    mapfile -t snaps < <(
        snap list 2>/dev/null |
        awk 'NR > 1 {print $1}' || true
    )

    for pkg in "${snaps[@]}"; do
        [[ -z "$pkg" ]] && continue
        echo "Removing snap: $pkg"
        snap remove --purge "$pkg" || true
    done

else
    echo "Snap is not installed. Skipping."
fi


# --------------------------------------------------
# 2. Stop snapd
# --------------------------------------------------

echo
echo "[2/6] Stopping and disabling snapd..."

systemctl disable --now snapd.service 2>/dev/null || true
systemctl disable --now snapd.socket 2>/dev/null || true
systemctl disable --now snapd.seeded.service 2>/dev/null || true


# --------------------------------------------------
# 3. Remove snapd
# --------------------------------------------------

echo
echo "[3/6] Removing snapd..."

apt-get purge -y snapd || true


# --------------------------------------------------
# 4. Remove cloud-init
# --------------------------------------------------

echo
echo "[4/6] Removing cloud-init..."

apt-get purge -y \
    cloud-init \
    cloud-initramfs-copymods \
    cloud-initramfs-dyn-netconf || true


# --------------------------------------------------
# 5. Cleanup
# --------------------------------------------------

echo
echo "[5/6] Cleaning unused packages and files..."

apt-get autoremove -y
apt-get autoclean -y

rm -rf /var/cache/snapd
rm -rf /var/lib/snapd
rm -rf /snap
rm -rf /root/snap

rm -rf /var/lib/cloud
rm -f /var/log/cloud-init.log
rm -f /var/log/cloud-init-output.log

# Do NOT remove /etc/netplan.
# A cloud-init generated Netplan file may now be the server's
# permanent network configuration.


# --------------------------------------------------
# 6. Verification
# --------------------------------------------------

echo
echo "[6/6] Verification"
echo

echo "--- Snap ---"

if command -v snap >/dev/null 2>&1; then
    echo "WARNING: snap command still exists:"
    command -v snap
else
    echo "OK: snap removed"
fi

echo
echo "--- Packages ---"

if dpkg -l 2>/dev/null |
    grep -E '^(ii|rc)[[:space:]]+(snapd|cloud-init|cloud-initramfs)'; then
    echo
    echo "WARNING: Some related package entries remain."
else
    echo "OK: snapd/cloud-init packages are not installed"
fi

echo
echo "--- Network ---"
ip -br addr

echo
ip route

echo
echo "[Time] Configuring timezone and 24-hour time format..."

timedatectl set-timezone Europe/Tallinn

if command -v locale-gen >/dev/null 2>&1; then
    locale-gen en_GB.UTF-8
fi

update-locale LC_TIME=en_GB.UTF-8

echo
echo "--- Time settings ---"
timedatectl show -p Timezone --value
LC_TIME=en_GB.UTF-8 date

echo
echo "=================================================="
echo " Cleanup completed successfully."
echo " Reboot is recommended."
echo "=================================================="
