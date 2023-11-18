#!/bin/bash

KERNEL_VERSION="5.4.260"
BUSYBOX_VERSION="1.36.1"

if [ -n "$LDDT_ROOT" ]; then
    LDDT_DEPS_DIR=$(mkdir -p $LDDT_ROOT/deps && cd $LDDT_ROOT/deps && pwd)
fi

fetch_option=
defconfig_option=
menuconfig_option=
build_option=
rootfs_option=
target=

fetch_source_code() {
    pushd $LDDT_DEPS_DIR

    local url=$1
    local tar_file=$2
    local source_dir=$3

    if [ -f "$tar_file" ]; then
        printf "%s exists\n" $tar_file
    else
        printf "Fetching source code at: %s\n" $url
        wget $url
        printf "Done\n"
    fi

    printf "Extracting $s...\n" $tar_file
    tar -xf $tar_file -C .
    printf "Extracting $s done\n" $tar_file

    popd
}

kernel_defconfig() {
    pushd $LDDT_DEPS_DIR
    local kernel_source_dir=linux-${KERNEL_VERSION}
    pushd $kernel_source_dir
    mkdir -p build
    ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- make O=build vexpress_defconfig
    sed -i -e '/CONFIG_GDB_SCRIPTS is not set/c CONFIG_GDB_SCRIPTS=y' -e '/CONFIG_DEBUG_INFO is not set/c CONFIG_DEBUG_INFO=y' build/.config
    popd
    popd
}

busybox_defconfig() {
    pushd $LDDT_DEPS_DIR
    local busybox_source_dir=busybox-${BUSYBOX_VERSION}
    pushd $busybox_source_dir
    mkdir -p build
    ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- make O=build defconfig
    sed -i -e '/CONFIG_STATIC is not set/c CONFIG_STATIC=y' build/.config
    popd
    popd
}

menuconfig() {
    local target_dir=

    if [ "$target" == "k" ]; then
        target_dir=linux-${KERNEL_VERSION}
    elif [ "$target" == "b" ]; then
        target_dir=busybox-${BUSYBOX_VERSION}
    else
        printf "Error menuconfig: invalid target: %s\n" $target
        exit 1
    fi

    pushd $LDDT_DEPS_DIR
    pushd $target_dir
    mkdir -p build
    ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- make O=build menuconfig
    popd
    popd
}

build_target() {
    local target_dir=

    if [ "$target" == "k" ]; then
        target_dir=linux-${KERNEL_VERSION}
    elif [ "$target" == "b" ]; then
        target_dir=busybox-${BUSYBOX_VERSION}
    else
        printf "Error build target: invalid target: %s\n" $target
        exit 1
    fi

    pushd $LDDT_DEPS_DIR
    pushd $target_dir
    mkdir -p build
    ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- make O=build -j$(nproc)
    popd
    popd
}

kernel_handler() {
    if [ "$target" != "k" ]; then
        return
    fi

    if [ "$fetch_option" == "1" ]; then
        local kernel_source_dir="linux-${KERNEL_VERSION}"
        local kernel_tar_file="${kernel_source_dir}.tar.xz"
        local kernel_url="https://cdn.kernel.org/pub/linux/kernel/v5.x/${kernel_file}"
        fetch_source_code $kernel_url $kernel_tar_file $kernel_source_dir
    fi

    if [ "$defconfig_option" == "1" ]; then
        kernel_defconfig
    fi

    if [ "$menuconfig_option" == "1" ]; then
        menuconfig
    fi

    if [ "$build_option" == "1" ]; then
        build_target
    fi
}

busybox_handler() {
    if [ "$target" != "b" ]; then
        return
    fi

    if [ "$fetch_option" == "1" ]; then
        local busybox_source_dir="busybox-${BUSYBOX_VERSION}"
        local busybox_tar_file="${busybox_source_dir}.tar.bz2"
        local busybox_url="https://busybox.net/downloads/${busybox_tar_file}"
        fetch_source_code $busybox_url $busybox_tar_file $busybox_source_dir
    fi

    if [ "$defconfig_option" == "1" ]; then
        busybox_defconfig
    fi

    if [ "$menuconfig_option" == "1" ]; then
        menuconfig
    fi

    if [ "$build_option" == "1" ]; then
        build_target
    fi
}

rootfs_handler() {
    if [ "$target" != "r" ]; then
        return
    fi

    local bubybox_source_dir="busybox-${BUSYBOX_VERSION}"
    pushd $LDDT_DEPS_DIR/${bubybox_source_dir}

    ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- make O=build install
    rm -rf build/rootfs.ext4
    dd if=/dev/zero of=build/rootfs.ext4 bs=4M count=16
    mkfs.ext4 build/rootfs.ext4

    mkdir -p build/mnt
    mount build/rootfs.ext4 build/mnt
    cp -r build/_install/* build/mnt

    mkdir -p build/mnt/{mnt,dev,sys,proc}

    touch build/mnt/bin/init.sh
    chmod +x build/mnt/bin/init.sh
    cat <<EOF >build/mnt/bin/init.sh
#!/bin/sh
mount -t devtmpfs none /dev
mount -t sysfs none /sys
mount -t proc none /proc
mount -t 9p lddt /mnt

/bin/sh
EOF

    umount build/mnt
    popd
}

docker_handler() {
    if [ "$target" != "d" -o -n "$LDDT_ROOT" ]; then
        return
    fi

    local docker_dir=$(realpath "$(dirname ${BASH_SOURCE[0]})/../docker")
    pushd $docker_dir
    docker build -t lddt:latest .
    mkdir -p ../deps/.vscode-server
    popd
}

show_help() {
    echo "Usage: path/to/build.sh [OPTION]"
    echo "  A build tool for linux kernel, busybox, rootfs and docker container"
    echo "Options:"
    echo "  -f: fetch source code"
    echo "  -c: run defconfig"
    echo "  -m: run menuconfig"
    echo "  -b: run build"
    echo "  -t: select the target, can be \"k\"(for linux kernel), \"b\"(for busybox) or \"d\"(for docker container build)"
    echo "  -h: show this help message"
}

main() {
    while getopts ":fcmbt:" opt; do
        case "$opt" in
        f)
            fetch_option=1
            ;;
        c)
            defconfig_option=1
            ;;
        m)
            menuconfig_option=1
            ;;
        b)
            build_option=1
            ;;
        t)
            target=$OPTARG
            ;;
        *)
            show_help
            exit 1
            ;;
        esac
    done

    kernel_handler
    busybox_handler
    rootfs_handler
    docker_handler
}

main $@
