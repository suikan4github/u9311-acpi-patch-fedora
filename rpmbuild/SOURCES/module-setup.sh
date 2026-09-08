#!/bin/bash

# Fallback if moddir is not provided by dracut
moddir=${moddir:-$(dirname "$(realpath "$0")")}

check() {
    [ -s /usr/share/u9311-acpi-patch/SSDT4.aml ] && \
        [ -s /usr/share/u9311-acpi-patch/bios_version_at_install ]
}

depends() {
    return 0
}

install() {
    inst_multiple logger

    # Register check-bios.sh for the cmdline phase of the boot process
    inst_hook cmdline 01 "${moddir}/check-bios.sh"

    # Copy the AML file and target BIOS version into the initramfs
    inst /usr/share/u9311-acpi-patch/SSDT4.aml /usr/share/u9311-acpi-patch/SSDT4.aml
    inst /usr/share/u9311-acpi-patch/bios_version_at_install /usr/share/u9311-acpi-patch/bios_version_at_install
}