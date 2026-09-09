Name:           u9311-acpi-patch
Version:        1.0
Release:        4%{?dist}
Summary:        ACPI SSDT4 Override for LIFEBOOK U9311

License:        MIT
BuildArch:      x86_64

Source0:        SSDT4.aml
Source1:        99-acpi-override.conf

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

# 2. Install the dracut configuration.
# Installed under /usr/lib/dracut/dracut.conf.d (not /etc/dracut.conf.d):
# dracut always reads $dracutbasedir/dracut.conf.d regardless of --confdir,
# so the file is picked up immediately during rpm-ostree's client-side
# initramfs regeneration, which runs before the new deployment's /etc is
# fully merged (a file placed only in /etc would be missed on first install).
DRACUT_CONF_DIR="%{buildroot}/usr/lib/dracut/dracut.conf.d"
mkdir -p "${DRACUT_CONF_DIR}"
install -m 0644 %{SOURCE1} "${DRACUT_CONF_DIR}/99-acpi-override.conf"

%post
# Rebuild the initramfs after installation to apply the changes.
# On rpm-ostree (Atomic Desktop) systems, initramfs regeneration is handled
# automatically by rpm-ostree itself after package installation, as long as
# it has been enabled beforehand (rpm-ostree initramfs --enable).
# NOTE: Never call rpm-ostree from a scriptlet: scriptlets run in a bwrap
# sandbox without access to the system D-Bus, so it always fails.
if [ ! -e /run/ostree-booted ]; then
    dracut --force
fi

%postun
if [ $1 -eq 0 ]; then
    if [ ! -e /run/ostree-booted ]; then
        dracut --force
    fi
fi

%files
/usr/share/u9311-acpi-patch/SSDT4.aml
/usr/lib/dracut/dracut.conf.d/99-acpi-override.conf

%changelog
* Wed Sep 09 2026 Custom User <user@example.com> - 1.0-4
- Move the dracut config snippet from /etc/dracut.conf.d to
  /usr/lib/dracut/dracut.conf.d. On rpm-ostree systems, the client-side
  initramfs regeneration triggered by package install runs before the new
  deployment's /etc is fully merged, so a config file under /etc was silently
  ignored on first install, leaving the ACPI override missing from the
  initramfs. dracut always scans $dracutbasedir/dracut.conf.d (/usr/lib/dracut
  /dracut.conf.d) in addition to /etc/dracut.conf.d, so this location works
  reliably regardless of merge timing.

* Wed Sep 09 2026 Custom User <user@example.com> - 1.0-3
- Fix %post scriptlet failure on rpm-ostree systems: never call rpm-ostree
  from scriptlets (system D-Bus is unavailable in the scriptlet sandbox).
  rpm-ostree regenerates the initramfs automatically when enabled.

* Mon Sep 07 2026 Custom User <user@example.com> - 1.0-1
- Initial release.