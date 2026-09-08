Name:           u9311-acpi-patch
Version:        1.0
Release:        1%{?dist}
Summary:        ACPI SSDT4 Override with BIOS Check for LIFEBOOK U9311

License:        MIT
BuildArch:      x86_64

Source0:        SSDT4.aml
Source1:        bios_version_at_install
Source2:        module-setup.sh
Source3:        check-bios.sh

Requires:       dracut

%description
Provides pre-compiled ACPI SSDT4 override with boot-time BIOS version check.

%prep

%build

%install
rm -rf %{buildroot}

# 1. Install data files (/usr/share)
mkdir -p %{buildroot}/usr/share/u9311-acpi-patch
install -m 0644 %{SOURCE0} %{buildroot}/usr/share/u9311-acpi-patch/SSDT4.aml
install -m 0644 %{SOURCE1} %{buildroot}/usr/share/u9311-acpi-patch/bios_version_at_install

# 2. Install the dracut module (/usr/lib/dracut/modules.d)
DRACUT_MOD_DIR="%{buildroot}/usr/lib/dracut/modules.d/99acpi-bios-check"
mkdir -p "${DRACUT_MOD_DIR}"
install -m 0755 %{SOURCE2} "${DRACUT_MOD_DIR}/module-setup.sh"
install -m 0755 %{SOURCE3} "${DRACUT_MOD_DIR}/check-bios.sh"

%post
# Rebuild the initramfs after installation to apply the changes
if [ -e /run/ostree-booted ]; then
    rpm-ostree initramfs --enable
else
    dracut --force
fi

%postun
if [ $1 -eq 0 ]; then
    if [ -e /run/ostree-booted ]; then
        rpm-ostree initramfs --enable
    else
        dracut --force
    fi
fi

%files
/usr/share/u9311-acpi-patch/SSDT4.aml
/usr/share/u9311-acpi-patch/bios_version_at_install
/usr/lib/dracut/modules.d/99acpi-bios-check/module-setup.sh
/usr/lib/dracut/modules.d/99acpi-bios-check/check-bios.sh

%changelog
* Mon Sep 07 2026 Custom User <user@example.com> - 1.0-1
- Initial release.