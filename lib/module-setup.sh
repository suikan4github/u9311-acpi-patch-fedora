#!/bin/bash
# /usr/lib/dracut/modules.d/99u9311-bios-check/module-setup.sh

# dracut から渡されない場合のフォールバック（念のための安全策）
moddir=${moddir:-$(dirname "$(realpath "$0")")}

check() {
    [ -f /etc/acpi-overrides/SSDT4.aml ] && return 0
    return 1
}

depends() {
    return 0
}

install() {
    inst_hook cmdline 01 "${moddir}/check-bios.sh"
    inst /etc/acpi-overrides/SSDT4.aml /etc/acpi-overrides/SSDT4.aml

    local current_bios
    current_bios=$(cat /sys/class/dmi/id/bios_version 2>/dev/null || echo "unknown")
    
    echo "$current_bios" > "${TMPDIR}/built_bios_version"
    inst "${TMPDIR}/built_bios_version" /etc/acpi-overrides/built_bios_version
}