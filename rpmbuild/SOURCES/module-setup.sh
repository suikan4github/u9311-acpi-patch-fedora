#!/bin/bash

# Fallback if moddir is not provided by dracut
moddir=${moddir:-$(dirname "$(realpath "$0")")}

check() {
    [ -s /usr/share/u9311-acpi-patch/SSDT4.aml ]
}

depends() {
    return 0
}

install() {
    # CONFIG_ACPI_TABLE_UPGRADE reads ACPI tables from this initramfs path.
    inst_simple /usr/share/u9311-acpi-patch/SSDT4.aml \
        /kernel/firmware/acpi/SSDT4.aml
}