#!/bin/sh

WORK_CONTAINER=u9311-acpi-patch

toolbox create ${WORK_CONTAINER} 
toolbox run -c ${WORK_CONTAINER} -- sudo dnf install -y rpm-build acpica-tools patch dracut
toolbox run -c ${WORK_CONTAINER} -- mkdir -p rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
cp lib/u9311-acpi-patch.spec rpmbuild/SPECS/
cp lib/u9311-acpi-builder.sh lib/u9311-acpi-builder.service lib/module-setup.sh lib/check-bios.sh lib/u9311-acpi.patch rpmbuild/SOURCES/

# Apply patch here

# Build RPM
toolbox run -c ${WORK_CONTAINER} -- rpmbuild --define "_topdir $(pwd)/rpmbuild" -bb rpmbuild/SPECS/u9311-acpi-patch.spec


# DNF (Fedora Workstation 等) の場合
sudo dnf install ./rpmbuild/RPMS/noarch/u9311-acpi-patch-1.0-1.noarch.rpm

# rpm-ostree (Fedora Kinoite / Silverblue 等) の場合
sudo rpm-ostree install ./rpmbuild/RPMS/noarch/u9311-acpi-patch-1.0-1.noarch.rpm

# サービス起動（/etc/acpi-overrides/SSDT4.aml の自動ビルドと initramfs 更新）
sudo systemctl enable --now u9311-acpi-builder.service

