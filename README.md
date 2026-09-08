# u9311-acpi-patch-fedora
Building and installing an RPM to patch the Fujitsu FMV LIFEBOOK U9311 ACPI bug.

The package installs `SSDT4.aml` into the initramfs at
`kernel/firmware/acpi/SSDT4.aml`. Fedora's kernel loads the table during early
ACPI initialization when `CONFIG_ACPI_TABLE_UPGRADE` is enabled.

The patch is applied on every boot and does not perform BIOS version detection.
Reboot after installation to apply the updated ACPI table.
