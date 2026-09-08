#!/bin/sh
# Run in the initramfs and apply SSDT4 via configfs only when the BIOS version matches

BIOS_VERSION_FILE="/usr/share/u9311-acpi-patch/bios_version_at_install"
AML_FILE="/usr/share/u9311-acpi-patch/SSDT4.aml"
LOG_TAG="u9311-acpi-patch"

log_info() {
    logger -t "$LOG_TAG" -- "$*"
}

log_error() {
    logger -p err -t "$LOG_TAG" -- "$*"
}

main() {
    MODULE_NAME=u9311-acpi-patch.rpm
    if [ ! -s "$BIOS_VERSION_FILE" ] || [ ! -s "$AML_FILE" ]; then
        log_error "${MODULE_NAME}: Required ACPI patch files are missing. Skipping."
        return 0
    fi

    CURRENT_BIOS_VERSION=$(cat /sys/class/dmi/id/bios_version 2>/dev/null)
    BIOS_VERSION_AT_INSTALL=$(cat "$BIOS_VERSION_FILE" 2>/dev/null)

    # Load the ACPI patch only when the BIOS versions match.
    if [ "$CURRENT_BIOS_VERSION" != "$BIOS_VERSION_AT_INSTALL" ] || [ -z "$CURRENT_BIOS_VERSION" ]; then
        log_info "${MODULE_NAME}: BIOS mismatch! (Current: '$CURRENT_BIOS_VERSION', Target: '$BIOS_VERSION_AT_INSTALL'). Skipping."
        return 0
    fi

    log_info "${MODULE_NAME}: BIOS match ($CURRENT_BIOS_VERSION). Loading SSDT4..."

    if [ ! -d /sys/kernel/config/acpi/table ]; then
        mount -t configfs configfs /sys/kernel/config 2>/dev/null || {
            log_error "${MODULE_NAME}: Failed to mount ACPI configfs."
            return 0
        }
    fi

    TABLE_DIR=/sys/kernel/config/acpi/table/SSDT4
    if [ -e "$TABLE_DIR" ]; then
        log_info "${MODULE_NAME}: SSDT4 is already loaded. Skipping."
        return 0
    fi

    mkdir "$TABLE_DIR" || {
        log_error "${MODULE_NAME}: Failed to create the SSDT4 configfs table."
        return 0
    }

    cat "$AML_FILE" > "$TABLE_DIR/aml" || {
        log_error "${MODULE_NAME}: Failed to load SSDT4 into configfs."
        rmdir "$TABLE_DIR" 2>/dev/null || true
    }
}

main "$@"