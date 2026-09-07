#! /bin/bash

function make_patch() {

    MODULE_NAME=u9311-acpi-patch.rpm
    WORK_CONTAINER=u9311-acpi-patch

    echo "${MODULE_NAME}: Creating work toolbox..."
    toolbox create ${WORK_CONTAINER} \
        || return 1;
    echo "${MODULE_NAME}: Installing tools into work toolbox..."
    toolbox run -c ${WORK_CONTAINER} -- sudo dnf install -y rpm-build acpica-tools patch  \
        || return 1;

    echo "${MODULE_NAME}: Going to rpmbuild/SOURCES directory..."
    cd rpm-build/SOURCES || exit 1;

    # Obtain ACPI table. 
    echo "${MODULE_NAME}: Obtaining ACPI table..."
    # shellcheck disable=SC2024
    sudo cat /sys/firmware/acpi/tables/SSDT4 > SSDT4.aml \
        || return 1;

    # Disassemble the ACPI table to a human-readable format, inside container.
    echo "${MODULE_NAME}: Disassembling the ACPI table inside container ${CONTAINER}..."
    toolbox run -c ${WORK_CONTAINER} -- iasl -d SSDT4.aml \
        || return 1;

    # Apply the patch to the disassembled ACPI table, inside container.
    echo "${MODULE_NAME}: Applying the patch inside container ${CONTAINER}..."
    toolbox run -c ${WORK_CONTAINER} -- patch < u9311-acpi.patch \
        || return 1;

    # If patch fail, exit the shell function.
    if [ $? -ne 0 ]; then
        echo "${MODULE_NAME}: Failed to apply the patch. Remove the temporaly container and exit."
        # Remove the temporary container before exiting.
        toolbox rm ${WORK_CONTAINER} -f
        return 1
    fi

    # Reassemble the patched ACPI table back to binary format, inside container.
    echo "${MODULE_NAME}: Reassembling the patched ACPI table inside container ${CONTAINER}..."
    toolbox run -c ${WORK_CONTAINER} -- iasl -sa SSDT4.dsl \
        || return 1;

    echo "${MODULE_NAME}: Obtaining current version number..."
    cat /sys/class/dmi/id/bios_version > bios_version_at_install \
        || return 1;

    echo "${MODULE_NAME}: Removing the container before exiting..."
    toolbox rm ${WORK_CONTAINER} -f

    return 0
}

# execute function.
make_patch
