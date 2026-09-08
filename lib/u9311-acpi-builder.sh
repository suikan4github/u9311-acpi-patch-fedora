#!/bin/bash
set -e

DST_DIR="/etc/acpi-overrides"
PATCH_FILE="/usr/share/u9311-acpi-patch/ssdt4.patch"

# Skip if the AML file already exists
if [ -f "${DST_DIR}/SSDT4.aml" ]; then
    echo "[u9311-acpi-builder] SSDT4.aml already exists. Skipping build."
    exit 0
fi

if [ ! -f /sys/firmware/acpi/tables/SSDT4 ]; then
    echo "[u9311-acpi-builder] ERROR: /sys/firmware/acpi/tables/SSDT4 not found." >&2
    exit 1
fi

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

cd "$WORKDIR"

echo "[u9311-acpi-builder] Dumping and patching ACPI table SSDT4..."
cp /sys/firmware/acpi/tables/SSDT4 SSDT4.dat
iasl -d SSDT4.dat

patch SSDT4.dsl "$PATCH_FILE"
iasl -tc SSDT4.dsl

mkdir -p "$DST_DIR"

# Move atomically
mv -f SSDT4.aml "${DST_DIR}/SSDT4.aml"

echo "[u9311-acpi-builder] Regenerating initramfs to update the ACPI override..."
if [ -e /run/ostree-booted ]; then
    rpm-ostree initramfs --enable || {
        rpm-ostree initramfs --disable
        rpm-ostree initramfs --enable
    }
else
    dracut --force
fi

echo "[u9311-acpi-builder] Build and initramfs update completed successfully."
