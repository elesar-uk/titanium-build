#!/bin/sh -e

GCC_TARGET="arm-linux-gnueabihf"
GCC_VERSION="4.9-2016.02"
GCC_NAME="gcc-linaro-${GCC_VERSION}-x86_64_${GCC_TARGET}"
GCC_TARBALL="${GCC_NAME}.tar.xz"
GCC_URL="https://releases.linaro.org/components/toolchain/binaries/${GCC_VERSION}/${GCC_TARGET}/${GCC_TARBALL}"
UBOOT_URL="https://github.com/elesar-uk/u-boot.git"
UBOOT_BRANCH="titanium-v2015.07"
KERNEL_URL="https://github.com/elesar-uk/ti-linux-kernel.git"
KERNEL_BRANCH="titanium-linux-4.1"

LOCAL_BRANCH="working"

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
    toolchain/${GCC_NAME}/bin/${GCC_TARGET}-gcc --version > /dev/null
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

# If the u-boot repository does not exist clone it and check out the correct
# branch.

if [ ! -d bootloader/u-boot ]; then
    cd bootloader
    git clone -n ${UBOOT_URL}
    cd u-boot
    git checkout -b ${LOCAL_BRANCH} origin/${UBOOT_BRANCH}
    cd ../..
fi

# If the kernel repository does not exist clone it and check out the correct
# branch.

if [ ! -d kernel/ti-linux-kernel ]; then
    cd kernel
    git clone ${KERNEL_URL}
    cd ti-linux-kernel
    git checkout -b ${LOCAL_BRANCH} origin/${KERNEL_BRANCH}
    cd ../..
fi
