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
KERNEL_BUILD_BUILTIN_PATH="$BUILDDIR/linux-$KERNEL_VER-builtin/"

KERNEL_CONF_FRAGMENT="${CURDIR}/hacksaw.kconfig.fragment"

mkdir -p $SRCDIR
mkdir -p $KERNEL_BUILD_PATH
mkdir -p $KERNEL_BUILD_BUILTIN_PATH

if [ ! -d "$KERNEL_SRC_PATH" ]; then
  wget -c https://cdn.kernel.org/pub/linux/kernel/v${KERNEL_VER:0:1}.x/linux-$KERNEL_VER.tar.xz -O - | tar -xJ -C $SRCDIR
fi
if [ "${KERNEL_VER:0:4}" = "5.15" ]; then
#  https://lore.kernel.org/r/20211104215047.663411-1-nathan@kernel.org/
  sed -i 's/1E6L/USEC_PER_SEC/g' $KERNEL_SRC_PATH/drivers/power/reset/ltc2952-poweroff.c
#  https://lore.kernel.org/r/20211104215923.719785-1-nathan@kernel.org/
  sed -i 's/1E6L/USEC_PER_SEC/g' $KERNEL_SRC_PATH/drivers/usb/dwc2/hcd_queue.c
# gcc sanitizer bug
  sed -i 's/-Wall//g' $KERNEL_SRC_PATH/tools/lib/subcmd/Makefile
# TODO: use patch instead of sed
fi

pushd $KERNEL_SRC_PATH

make mrproper
make CC=clang allmodconfig O=$KERNEL_BUILD_BUILTIN_PATH
./scripts/kconfig/merge_config.sh -O $KERNEL_BUILD_BUILTIN_PATH $KERNEL_BUILD_BUILTIN_PATH/.config $KERNEL_CONF_FRAGMENT
make CC=clang olddefconfig O=$KERNEL_BUILD_BUILTIN_PATH
make CC=clang -j$(nproc) vmlinux O=$KERNEL_BUILD_BUILTIN_PATH

make mrproper
make CC=clang allmodconfig O=$KERNEL_BUILD_PATH
./scripts/kconfig/merge_config.sh -O $KERNEL_BUILD_PATH $KERNEL_BUILD_PATH/.config $KERNEL_CONF_FRAGMENT
make CC=clang olddefconfig O=$KERNEL_BUILD_PATH
make -j$(nproc) CC=clang KCFLAGS='-w -save-temps=obj' O=$KERNEL_BUILD_PATH
make -j$(nproc) CC=clang INSTALL_MOD_PATH=./mod_install modules_install O=$KERNEL_BUILD_PATH

popd

${CURDIR}/linkir.py $KERNEL_BUILD_PATH
