#!/bin/bash

if [ $# -eq 1 ]; then
  KERNEL_VER="$1"
else
  KERNEL_VER="5.19.17"
fi

CURDIR=$(dirname $(realpath $0))
ROOTDIR=$(dirname ${CURDIR})
SRCDIR="$CURDIR/src"
BUILDDIR="${ROOTDIR}/build/"

KERNEL_SRC_PATH="$SRCDIR/linux-$KERNEL_VER/"
KERNEL_BUILD_PATH="$BUILDDIR/linux-$KERNEL_VER/"

KERNEL_CONF_FRAGMENT="${CURDIR}/hacksaw.kconfig.fragment"

mkdir -p $SRCDIR
mkdir -p $KERNEL_BUILD_PATH

if [ ! -d "$KERNEL_SRC_PATH" ]; then
  wget -c https://cdn.kernel.org/pub/linux/kernel/v${KERNEL_VER:0:1}.x/linux-$KERNEL_VER.tar.xz -O - | tar -xJ -C $SRCDIR
fi

pushd $KERNEL_SRC_PATH

make mrproper
make CC=clang allmodconfig O=$KERNEL_BUILD_PATH
./scripts/kconfig/merge_config.sh -O $KERNEL_BUILD_PATH $KERNEL_BUILD_PATH/.config $KERNEL_CONF_FRAGMENT
make CC=clang olddefconfig O=$KERNEL_BUILD_PATH
make -j$(nproc) CC=clang O=$KERNEL_BUILD_PATH
make -j$(nproc) CC=clang INSTALL_MOD_PATH=./mod_install modules_install O=$KERNEL_BUILD_PATH

popd

${CURDIR}/buildir.py $KERNEL_BUILD_PATH
${CURDIR}/linkir.py $KERNEL_BUILD_PATH
