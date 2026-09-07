#!/bin/bash

# dracut から渡されない場合のフォールバック（念のための安全策）
moddir=${moddir:-$(dirname "$(realpath "$0")")}

check() {
    [ -f /usr/share/u9311-acpi-patch/SSDT4.aml ] && return 0
    return 1
}

depends() {
    return 0
}

install() {
    # 起動処理（cmdlineフェーズ）にcheck-bios.shを登録
    inst_hook cmdline 01 "${moddir}/check-bios.sh"

    # initramfs内にAMLとターゲットバージョン情報をコピー
    inst /usr/share/u9311-acpi-patch/SSDT4.aml /usr/share/u9311-acpi-patch/SSDT4.aml
    inst /usr/share/u9311-acpi-patch/bios_version_at_install /usr/share/u9311-acpi-patch/bios_version_at_install
}