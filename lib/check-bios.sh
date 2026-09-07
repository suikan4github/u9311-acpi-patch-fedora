#!/bin/sh
# /usr/lib/dracut/modules.d/99u9311-bios-check/check-bios.sh

CURRENT_BIOS=$(cat /sys/class/dmi/id/bios_version 2>/dev/null)
BUILT_BIOS=$(cat /etc/acpi-overrides/built_bios_version 2>/dev/null)

info "U9311-ACPI-Check: Current BIOS: '$CURRENT_BIOS', Built BIOS: '$BUILT_BIOS'"

if [ -n "$CURRENT_BIOS" ] && [ "$CURRENT_BIOS" = "$BUILT_BIOS" ]; then
    info "U9311-ACPI-Check: BIOS version matches. Applying ACPI override via configfs..."
    
    if [ ! -d /sys/kernel/config/acpi/table ]; then
        mount -t configfs none /sys/kernel/config 2>/dev/null
    fi

    if [ -d /sys/kernel/config/acpi/table ]; then
        mkdir -p /sys/kernel/config/acpi/table/SSDT4
        cat /etc/acpi-overrides/SSDT4.aml > /sys/kernel/config/acpi/table/SSDT4/aml
        info "U9311-ACPI-Check: ACPI Table SSDT4 loaded successfully."
    else
        warn "U9311-ACPI-Check: Dynamic ACPI Table Overlay is not supported by kernel."
    fi
else
    warn "====================================================================="
    warn "U9311-ACPI-Check: WARNING! BIOS version mismatch detected!"
    warn "U9311-ACPI-Check: System BIOS was updated ($BUILT_BIOS -> $CURRENT_BIOS)."
    warn "U9311-ACPI-Check: Skipping ACPI Override to prevent system crash."
    warn "====================================================================="
fi
