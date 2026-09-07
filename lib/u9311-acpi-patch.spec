Name:           u9311-acpi-patch
Version:        1.0
Release:        1%{?dist}
Summary:        Dynamic ACPI SSDT4 Patch for Fujitsu LIFEBOOK U9311

License:        MIT
BuildArch:      noarch

Source0:        u9311-acpi-builder.sh
Source1:        u9311-acpi-builder.service
Source2:        module-setup.sh
Source3:        check-bios.sh
Source4:        ssdt4.patch

Requires:       acpica-tools
Requires:       patch
Requires:       dracut

%description
Extracts local ACPI SSDT4 table on Fujitsu LIFEBOOK U9311, applies custom patch,
and configures a dracut module to safely load the override via configfs.
Includes automated safety checks for BIOS updates.

%prep

%build

%install
rm -rf %{buildroot}

# 1. 実行スクリプトとサービスの配置
mkdir -p %{buildroot}/usr/libexec
mkdir -p %{buildroot}/usr/lib/systemd/system
mkdir -p %{buildroot}/usr/share/u9311-acpi-patch

install -m 0755 %{SOURCE0} %{buildroot}/usr/libexec/u9311-acpi-builder.sh
install -m 0644 %{SOURCE1} %{buildroot}/usr/lib/systemd/system/u9311-acpi-builder.service
install -m 0644 %{SOURCE4} %{buildroot}/usr/share/u9311-acpi-patch/ssdt4.patch

# 2. dracut モジュールの配置
DRACUT_MOD_DIR="%{buildroot}/usr/lib/dracut/modules.d/99u9311-bios-check"
mkdir -p "${DRACUT_MOD_DIR}"

install -m 0755 %{SOURCE2} "${DRACUT_MOD_DIR}/module-setup.sh"
install -m 0755 %{SOURCE3} "${DRACUT_MOD_DIR}/check-bios.sh"

%post
%systemd_post u9311-acpi-builder.service

%preun
%systemd_preun u9311-acpi-builder.service

%postun
if [ $1 -eq 0 ]; then
    echo "[u9311-acpi-patch] Removing generated files and cleaning up..."
    
    rm -rf /etc/acpi-overrides

    if [ -e /run/ostree-booted ]; then
        echo "[u9311-acpi-patch] Updating initramfs via rpm-ostree..."
        rpm-ostree initramfs --disable || true
    else
        echo "[u9311-acpi-patch] Regenerating initramfs via dracut..."
        dracut --force || true
    fi
    echo "[u9311-acpi-patch] Cleanup complete."
fi

%files
/usr/libexec/u9311-acpi-builder.sh
/usr/lib/systemd/system/u9311-acpi-builder.service
/usr/share/u9311-acpi-patch/ssdt4.patch
/usr/lib/dracut/modules.d/99u9311-bios-check/module-setup.sh
/usr/lib/dracut/modules.d/99u9311-bios-check/check-bios.sh

%ghost /etc/acpi-overrides/SSDT4.aml

%changelog
* Mon Sep 07 2026 Custom User <user@example.com> - 1.0-1
- Initial release of u9311-acpi-patch with dynamic builder and dracut BIOS safety check.