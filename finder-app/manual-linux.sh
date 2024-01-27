#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.1.10
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-
#CC_PATH=/home/yassir/AELD/Cross_compiler/gcc-arm-10.2-2020.11-x86_64-aarch64-none-linux-gnu/bin
CC_PATH=/usr/local/arm-cross-compiler/install/gcc-arm-10.2-2020.11-x86_64-aarch64-none-linux-gnu/bin

if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

    # TODO: Add your kernel build steps here
 
    echo "Build kernel"
    export PATH=${CC_PATH}:$PATH
    echo $PATH
    pwd
    ls -al
    env

    sudo make ARCH=arm64 CROSS_COMPILE=${CC_PATH}/${CROSS_COMPILE} mrproper			# Deep clean
    sudo make ARCH=arm64 CROSS_COMPILE=${CC_PATH}/${CROSS_COMPILE} defconfig			# Configure for our “virt"
    sudo make -j2 ARCH=arm64 CROSS_COMPILE=${CC_PATH}/${CROSS_COMPILE} all			# Build a kernel image for booting with QEMU
    # make ARCH=arm64 CROSS_COMPILE=${CC_PATH}/${CROSS_COMPILE} modules			# Build any kernel modules
    sudo make ARCH=arm64 CROSS_COMPILE=${CC_PATH}/${CROSS_COMPILE} dtbs 				# Build the devicetree

fi

echo "Adding the Image in outdir"
    cp -a ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ${OUTDIR}/

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi

# TODO: Create necessary base directories
    sudo mkdir -p ${OUTDIR}/rootfs
    cd ${OUTDIR}/rootfs
    sudo mkdir -p bin dev etc home lib lib64 proc sbin sys tmp usr var
    sudo mkdir -p usr/bin usr/lib usr/sbin
    sudo mkdir -p var/log 

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    # TODO:  Configure busybox
    sudo make distclean
    sudo make defconfig
else
    cd busybox
fi

# TODO: Make and install busybox
    echo "Install busybox"
    sudo make ARCH=${ARCH} CROSS_COMPILE=${CC_PATH}/${CROSS_COMPILE}
    sudo make CONFIG_PREFIX=${OUTDIR}/rootfs ARCH=${ARCH} CROSS_COMPILE=${CC_PATH}/${CROSS_COMPILE} install
    export PATH=${CC_PATH}:$PATH

echo "Library dependencies"
cd ${OUTDIR}/rootfs
${CROSS_COMPILE}readelf -a bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a bin/busybox | grep "Shared library"

# TODO: Add library dependencies to rootfs
    export SYSROOT=`${CC_PATH}/aarch64-none-linux-gnu-gcc -print-sysroot`
    cd  ${OUTDIR}/rootfs
    cp -a ${SYSROOT}/lib/ ${OUTDIR}/rootfs/
    cp -a ${SYSROOT}/lib64/ ${OUTDIR}/rootfs/
# TODO: Make device nodes
    sudo mknod -m 666 dev/null c 1 3
    sudo mknod -m 600 dev/console c 5 1
# TODO: Clean and build the writer utility
    pwd
    cd /home/yassir/AELD/assignment-1-YassirAlamin/finder-app/
    if [  -e *.o ]; then
        sudo rm *.o
    fi
    if [  -e writer ]; then
        sudo rm writer
    fi
    if [ -e writer-cross ]; then
        sudo rm writer-cross
    fi
    sudo ${CC_PATH}/${CROSS_COMPILE}gcc writer.c -o writer    
    sudo ${CC_PATH}/${CROSS_COMPILE}gcc writer.c -o writer-cross

# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs
    echo "Copy finder Dir"

    cp -a /home/yassir/AELD/assignment-1-YassirAlamin/finder-app/writer-cross ${OUTDIR}/rootfs/home
    cp -a /home/yassir/AELD/assignment-1-YassirAlamin/finder-app/writer ${OUTDIR}/rootfs/home
    cp -a /home/yassir/AELD/assignment-1-YassirAlamin/conf ${OUTDIR}/rootfs/home
    cp -a /home/yassir/AELD/assignment-1-YassirAlamin/finder-app/finder.sh ${OUTDIR}/rootfs/home
    cp -a /home/yassir/AELD/assignment-1-YassirAlamin/finder-app/finder-test.sh ${OUTDIR}/rootfs/home
    cp -a /home/yassir/AELD/assignment-1-YassirAlamin/finder-app/writer.sh ${OUTDIR}/rootfs/home
    cp -a /home/yassir/AELD/assignment-1-YassirAlamin/finder-app/autorun-qemu.sh ${OUTDIR}/rootfs/home

    cp ${OUTDIR}/rootfs/home/finder.sh ${OUTDIR}/rootfs/usr/bin
    cp ${OUTDIR}/rootfs/home/writer-cross ${OUTDIR}/rootfs/usr/bin
    cp ${OUTDIR}/rootfs/home/writer ${OUTDIR}/rootfs/usr/bin

# TODO: Chown the root directory
    echo "chown root dir"
    sudo chown -R root:root *
# TODO: Create initramfs.cpio.gz
    echo "Create initramfs.cpio.gz"
    cd ${OUTDIR}/rootfs
    find . | cpio -H newc -ov --owner root:root > ../initramfs.cpio
    cd ..
    if [ -e initramfs.cpio.gz ]; then
            sudo rm initramfs.cpio.gz
    fi

    gzip initramfs.cpio
    
