#!/bin/sh -e

GCC_TARGET="arm-linux-gnueabihf"
GCC_VERSION="7.5-2019.12"
GCC_FULL_VERSION="7.5.0-2019.12"
GCC_NAME="gcc-linaro-${GCC_FULL_VERSION}-x86_64_${GCC_TARGET}"
GCC_TARBALL="${GCC_NAME}.tar.xz"
GCC_URL="https://releases.linaro.org/components/toolchain/binaries/${GCC_VERSION}/${GCC_TARGET}/${GCC_TARBALL}"
UBOOT_URL="https://github.com/elesar-uk/u-boot.git"
UBOOT_BRANCH="titanium-v2019.07"
KERNEL_URL="https://github.com/elesar-uk/ti-linux-kernel.git"
KERNEL_BRANCH="titanium-linux-4.14"

LOCAL_SUFFIX="-working"

check_download() {
    (cd downloads && test -f ${GCC_TARBALL}.asc && md5sum --strict --check --status ${GCC_TARBALL}.asc)
}

download_toolchain() {
    if ! check_download; then
        echo "Downloading toolchain"
        echo "---------------------"
        echo
        wget --directory-prefix=downloads -c ${GCC_URL} ${GCC_URL}.asc
        if ! check_download; then
            echo
            echo "Failed to download toolchain archive"
            exit 1
        fi
    fi

    echo
    echo "Installing toolchain"
    echo "--------------------"
    echo
    tar -xf downloads/${GCC_TARBALL} -C toolchain
}

check_gcc() {
    toolchain/${GCC_NAME}/bin/${GCC_TARGET}-gcc --version > /dev/null 2>&1
}

checkout() {
    branch=$2
    git fetch
    # Do we already have the correct commit checked out?
    if [ "$(git rev-parse HEAD)" != "$(git rev-parse origin/${branch})" ]; then
        if [ "$1" != "-f" ]; then
            printf "\nYour checked-out branch does not match origin/%s.\n" "${branch}"
            printf "Run '%s -f' if you want to clean and reset your checkout to this point.\n" "$0"
        else
            # Invoked with -f, so clean everything.
            git reset --hard HEAD
            git clean -fdx
            # Do we already have a local branch?
            if git show-ref -q --verify refs/heads/${branch}${LOCAL_SUFFIX}; then
                # Yes, check it out and try to pull it up to the latest version.
                git checkout ${branch}${LOCAL_SUFFIX}
                if ! git pull --ff-only; then
                    # Couldn't fast-forward it, check out on a detached HEAD.
                    git checkout origin/${branch}
                fi
            else
                # Check out the correct commit as a local branch.
                git checkout -b ${branch}${LOCAL_SUFFIX} origin/${branch}
            fi
        fi
    fi
}

mkdir -p downloads toolchain

# Download and install the toolchain if it has not already been installed.

if ! check_gcc; then
    download_toolchain
    if ! check_gcc; then
        echo
        echo "Failed to install toolchain archive"
        exit 2
    fi
fi

# Create the 'buildenv' file.

echo "CC=$(readlink -f .)/toolchain/${GCC_NAME}/bin/${GCC_TARGET}-" > buildenv

CPUS=$(getconf _NPROCESSORS_ONLN)
if [ -n "${CPUS}" ]; then
    echo "PARALLEL_BUILD=-j${CPUS}" >> buildenv
fi

# If run with '-f' prompt before continuing.

if [ "$1" = "-f" ]; then
    printf "\nWARNING: Running this script with -f will delete all locally modified\n"
    printf "files in the 'bootloader/u-boot' and 'kernel/ti-linux-kernel' directories.\n"
    printf "Are you sure you want to do this (Y/N)? "
    read -r answer
    case $answer in
        ([yY][eE][sS] | [yY]) ;;
        (*) exit 1;;
  esac
  echo
fi

# If the u-boot repository does not exist clone it and check out the correct
# branch.

echo "Preparing U-Boot"
echo "----------------"

if [ ! -d bootloader/u-boot ]; then
    (
    cd bootloader
    git clone -n ${UBOOT_URL} u-boot
    cd u-boot
    git checkout -b ${UBOOT_BRANCH}${LOCAL_SUFFIX} origin/${UBOOT_BRANCH}
    )
else
    # The directory already exists, so check out the latest version.
    (
    cd bootloader/u-boot
    checkout "$1" ${UBOOT_BRANCH}
    )
fi

echo
echo "Preparing kernel"
echo "----------------"

# If the kernel repository does not exist clone it and check out the correct
# branch.

if [ ! -d kernel/ti-linux-kernel ]; then
    (
    cd kernel
    git clone -n ${KERNEL_URL} ti-linux-kernel
    cd ti-linux-kernel
    git checkout -b ${KERNEL_BRANCH}${LOCAL_SUFFIX} origin/${KERNEL_BRANCH}
    )
else
    # The directory already exists, so check out the latest version.
    (
    cd kernel/ti-linux-kernel
    checkout "$1" ${KERNEL_BRANCH}
    )
fi
