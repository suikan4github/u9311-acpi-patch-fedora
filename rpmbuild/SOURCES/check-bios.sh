#!/bin/sh
# Run in the initramfs and apply SSDT4 via configfs only when the BIOS version matches

BIOS_VERSION_FILE="/usr/share/u9311-acpi-patch/bios_version_at_install"
AML_FILE="/usr/share/u9311-acpi-patch/SSDT4.aml"

main() {
    MODULE_NAME=u9311-acpi-patch.rpm
    if [ ! -s "$BIOS_VERSION_FILE" ] || [ ! -s "$AML_FILE" ]; then
        echo "${MODULE_NAME}: Required ACPI patch files are missing. Skipping." >&2
        return 0
    fi

    CURRENT_BIOS_VERSION=$(cat /sys/class/dmi/id/bios_version 2>/dev/null)
    BIOS_VERSION_AT_INSTALL=$(cat "$BIOS_VERSION_FILE" 2>/dev/null)

    # Load the ACPI patch only when the BIOS versions match.
    if [ "$CURRENT_BIOS_VERSION" != "$BIOS_VERSION_AT_INSTALL" ] || [ -z "$CURRENT_BIOS_VERSION" ]; then
        echo "${MODULE_NAME}: BIOS mismatch! (Current: '$CURRENT_BIOS_VERSION', Target: '$BIOS_VERSION_AT_INSTALL'). Skipping."
        return 0
    fi

    echo "${MODULE_NAME}: BIOS match ($CURRENT_BIOS_VERSION). Loading SSDT4..."

    if [ ! -d /sys/kernel/config/acpi/table ]; then
        mount -t configfs configfs /sys/kernel/config 2>/dev/null || {
            echo "${MODULE_NAME}: ERROR: Failed to mount ACPI configfs." >&2
            return 0
        }
    fi

    TABLE_DIR=/sys/kernel/config/acpi/table/SSDT4
    if [ -e "$TABLE_DIR" ]; then
        echo "${MODULE_NAME}: SSDT4 is already loaded. Skipping."
        return 0
    fi

    mkdir "$TABLE_DIR" || {
        echo "${MODULE_NAME}: ERROR: Failed to create the SSDT4 configfs table." >&2
        return 0
    }

    cat "$AML_FILE" > "$TABLE_DIR/aml" || {
        echo "${MODULE_NAME}: ERROR: Failed to load SSDT4 into configfs." >&2
        rmdir "$TABLE_DIR" 2>/dev/null || true
    }
}

main "$@"