#! /bin/bash

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
export REPO_ROOT

function make_and_install_patch() {

    MODULE_NAME=u9311-acpi-patch.rpm
    WORK_CONTAINER=u9311-acpi-patch
    LOG_TAG=u9311-acpi-patch

    function log_message() {
        local message="$*"
        printf '%s\n' "${message}"
        logger -t "${LOG_TAG}" -- "${message}"
    }

    function log_error() {
        local message="$*"
        printf '%s\n' "${message}" >&2
        logger -p user.err -t "${LOG_TAG}" -- "${message}"
    }

    log_message "${MODULE_NAME}: Creating work toolbox..."
    toolbox create ${WORK_CONTAINER} # || return 1;
    log_message "${MODULE_NAME}: Installing tools into work toolbox..."
    toolbox run -c ${WORK_CONTAINER} -- sudo dnf install -y rpm-build acpica-tools patch  \
        || return 1;

    log_message "${MODULE_NAME}: Going to rpmbuild/SOURCES directory..."
    cd "${REPO_ROOT}/rpmbuild/SOURCES" || exit 1;

    # Obtain ACPI table. 
    log_message "${MODULE_NAME}: Obtaining ACPI table..."
    # shellcheck disable=SC2024
    sudo cat /sys/firmware/acpi/tables/SSDT4 > SSDT4.aml \
        || return 1;

    # Disassemble the ACPI table to a human-readable format, inside container.
    log_message "${MODULE_NAME}: Disassembling the ACPI table inside container ${WORK_CONTAINER}..."
    toolbox run -c ${WORK_CONTAINER} -- iasl -d SSDT4.aml \
        || return 1;

    # Apply the patch to the disassembled ACPI table, inside container.
    log_message "${MODULE_NAME}: Applying the patch inside container ${WORK_CONTAINER}..."
    toolbox run -c ${WORK_CONTAINER} -- patch < u9311-acpi.patch \
        || return 1;

    # If patch fail, exit the shell function.
    if [ $? -ne 0 ]; then
        log_error "${MODULE_NAME}: Failed to apply the patch. Remove the temporary container and exit."
        # Remove the temporary container before exiting.
        toolbox rm ${WORK_CONTAINER} -f
        return 1
    fi

    # Reassemble the patched ACPI table back to binary format, inside container.
    log_message "${MODULE_NAME}: Reassembling the patched ACPI table inside container ${WORK_CONTAINER}..."
    toolbox run -c ${WORK_CONTAINER} -- iasl -sa SSDT4.dsl \
        || return 1;

    # Go back to the repository root.
    cd "${REPO_ROOT}" || exit 1;

    # Build RPM
    log_message "${MODULE_NAME}: Building RPM..."
    toolbox run -c "${WORK_CONTAINER}" -- \
        rpmbuild --define "_topdir ${REPO_ROOT}/rpmbuild" -bb \
        "${REPO_ROOT}/rpmbuild/SPECS/u9311-acpi-patch.spec" \
        || return 1;

    RPM_FILE=$(find "${REPO_ROOT}/rpmbuild/RPMS/x86_64" -maxdepth 1 -type f \
        -name 'u9311-acpi-patch-*.x86_64.rpm' -print -quit)
    if [ -z "${RPM_FILE}" ]; then
        log_error "${MODULE_NAME}: RPM output was not found."
        return 1
    fi

    # Install
    if [[ -e /run/ostree-booted ]] && command -v rpm-ostree >/dev/null 2>&1; then
        log_message "Environment: Fedora Atomic Desktop (rpm-ostree)"
        log_message "${MODULE_NAME}: Installing RPM by rpm-ostree..."
        sudo rpm-ostree install "${RPM_FILE}" || return 1
    elif command -v dnf >/dev/null 2>&1; then
        log_message "Environment: Standard Fedora (Package-based / Workstation)"
        log_message "${MODULE_NAME}: Installing RPM by dnf..."
        sudo dnf install -y "${RPM_FILE}" || return 1
    else
        log_error "${MODULE_NAME}: No supported package manager was found."
        return 1
    fi



    log_message "${MODULE_NAME}: Removing the container before exiting..."
    toolbox rm ${WORK_CONTAINER} -f

    return 0
}

make_and_install_patch

