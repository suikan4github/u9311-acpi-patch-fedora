#!/bin/sh
# initramfs内で実行され、BIOS一致時のみconfigfs経由でSSDT4を適用する

BIOS_VERSION_FILE="/usr/share/u9311-acpi-patch/bios_version_at_install"
AML_FILE="/usr/share/u9311-acpi-patch/SSDT4.aml"

if [ ! -f "$BIOS_VERSION_FILE" ] || [ ! -f "$AML_FILE" ]; then
    exit 0
fi

CURRENT_BIOS_VERSION=$(cat /sys/class/dmi/id/bios_version 2>/dev/null)
BIOS_VERSION_AT_INSTALL=$(cat "$BIOS_VERSION_FILE" 2>/dev/null)

# BIOSバージョンが一致する場合のみACPIパッチをロード
if [ "$CURRENT_BIOS_VERSION" = "$BIOS_VERSION_AT_INSTALL" ] && [ -n "$CURRENT_BIOS_VERSION" ]; then
    echo "[acpi-patch] BIOS match ($CURRENT_BIOS_VERSION). Loading SSDT4..."
    
    if [ ! -d /sys/kernel/config/acpi ]; then
        mount -t configfs none /sys/kernel/config 2>/dev/null || true
    fi

    if [ -d /sys/kernel/config/acpi/system ]; then
        mkdir -p /sys/kernel/config/acpi/system/SSDT4
        cat "$AML_FILE" > /sys/kernel/config/acpi/system/SSDT4/aml
    fi
else
    echo "[acpi-patch] BIOS mismatch! (Current: '$CURRENT_BIOS_VERSION', Target: '$BIOS_VERSION_AT_INSTALL'). Skipping."
fi