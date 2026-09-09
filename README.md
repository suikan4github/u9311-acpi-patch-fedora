# Fujitsu FMV LIFEBOOK U9311 ACPI Patch for Fedora
Building and installing an RPM to patch the Fujitsu FMV LIFEBOOK U9311 ACPI bug.

## Disclaimer

This project is provided as-is, without warranty of any kind, express or implied.
The maintainers and contributors are not liable for any damages, losses, or issues resulting from the use of this software.
Use it at your own risk.



## Overview

This project creates an RPM package that patches the ACPI bug on the Fujitsu FMV LIFEBOOK U9311.

The Fujitsu FMV LIFEBOOK U9311 has a known ACPI bug that affects resume from suspend.
This issue is explained on the Arch Linux wiki page [Fujitsu Lifebook U9311](https://wiki.archlinux.org/title/Fujitsu_Lifebook_U9311). When this happens, the laptop's internal screen goes black when resuming from suspend. The external display, if connected, may continue to work normally.

The linked page provides a patch to fix this ACPI bug by creating a custom SSDT table.

This project automates the process of applying that patch on Fedora systems by packaging it into an RPM.

Thanks to RPM, uninstalling is straightforward, and it removes the custom ACPI table from the initramfs.

## Supported Distributions

This project currently supports Fedora Linux and has been tested on Fedora 44:
- Fedora KDE Plasma Desktop 44
- Fedora Kinoite 44

Any Fedora Workstation or Fedora Atomic Desktop spin should also be supported.

## Supported Hardware
- Fujitsu FMV LIFEBOOK U9311
- Fujitsu Futro U9311m

Other Fujitsu laptops with Intel 11th-generation processors may also be affected by this ACPI bug. In such cases, this project may still be useful for applying the necessary ACPI patch.

## Installation

To install the RPM package, use the following command:

```bash
./build-and-install.sh
```

On Fedora Atomic Desktop (rpm-ostree) systems, the script automatically enables initramfs regeneration (`rpm-ostree initramfs --enable`) before installing the package, because the RPM scriptlets cannot run `rpm-ostree` themselves. This creates one additional deployment.

After installation, reboot your system to apply the ACPI patch.

## Uninstallation

Before updating the system BIOS firmware, or before removing the patch for any reason, uninstall the package from the same environment where it was installed.

Use the following command:

```bash
if [[ -e /run/ostree-booted ]] && command -v rpm-ostree >/dev/null 2>&1; then
    echo "Environment: Fedora Atomic Desktop (rpm-ostree)"
    sudo rpm-ostree uninstall u9311-acpi-patch
elif command -v dnf >/dev/null 2>&1; then
    echo "Environment: Standard Fedora (Package-based / Workstation)"
    sudo dnf remove -y u9311-acpi-patch
else
    echo "u9311-acpi-patch.rpm: No supported package manager was found."
fi
```

After uninstalling the package, reboot the system so the initramfs can be rebuilt without the custom ACPI override. This is especially important on Fedora Atomic Desktop, where the initramfs is managed through `rpm-ostree`.

If you plan to update the system BIOS, uninstall the package first and reboot before applying the BIOS update. Otherwise, the existing ACPI override may remain incompatible with the new firmware.

## Troubleshooting
The ACPI patch depends on the system BIOS firmware. That is why the `build-and-install.sh` script must be run on your own system. In other words, the patch may not work correctly if it is applied on a different system with a different BIOS version.

To avoid potential issues, uninstall the `u9311-acpi-patch` RPM package before updating the system BIOS firmware. After updating the BIOS, you can run the `build-and-install.sh` script again to apply the ACPI patch with the new BIOS version.

If the system BIOS is updated before uninstalling the `u9311-acpi-patch` RPM package, the existing ACPI patch may not be compatible with the new BIOS version. In the worst case, this could lead to a system crash immediately after booting.

To fix this issue, you should boot your PC in rescue mode (or single-user mode), then uninstall the `u9311-acpi-patch` RPM package. After uninstalling, reboot the system and ensure it boots correctly with the new BIOS version. Once the system is stable, you can run the `build-and-install.sh` script again to apply the ACPI patch compatible with the updated BIOS.


## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

