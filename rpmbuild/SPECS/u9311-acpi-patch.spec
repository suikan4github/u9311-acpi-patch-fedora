Name:           u9311-acpi-patch
Version:        1.0
Release:        1%{?dist}
Summary:        ACPI SSDT4 Override for LIFEBOOK U9311

License:        MIT
BuildArch:      x86_64

Source0:        SSDT4.aml
Source1:        module-setup.sh

Requires:       dracut

%description
Provides a pre-compiled ACPI SSDT4 override through the initramfs.

%prep

%build

%install
rm -rf %{buildroot}

# 1. Install data files (/usr/share)
mkdir -p %{buildroot}/usr/share/u9311-acpi-patch
install -m 0644 %{SOURCE0} %{buildroot}/usr/share/u9311-acpi-patch/SSDT4.aml

# 2. Install the dracut module (/usr/lib/dracut/modules.d)
DRACUT_MOD_DIR="%{buildroot}/usr/lib/dracut/modules.d/99acpi-override"
mkdir -p "${DRACUT_MOD_DIR}"
install -m 0755 %{SOURCE1} "${DRACUT_MOD_DIR}/module-setup.sh"

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
/usr/lib/dracut/modules.d/99acpi-override/module-setup.sh

%changelog
* Mon Sep 07 2026 Custom User <user@example.com> - 1.0-1
- Initial release.