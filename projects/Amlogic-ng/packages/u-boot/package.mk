# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2018-present Team CoreELEC (https://coreelec.org)

PKG_NAME="u-boot"
PKG_VERSION="b611c4e60089afcef541eb1ffc198e7c933fe0f1"
PKG_SHA256="4059216238d834f84ec5256698b35c423a4a65628ad20fdaf1e578849387a4ad"
PKG_LICENSE="GPL"
PKG_SITE="https://www.denx.de/wiki/U-Boot"
PKG_URL="https://github.com/CoreELEC/u-boot/archive/$PKG_VERSION.tar.gz"
PKG_DEPENDS_TARGET="toolchain gcc-linaro-aarch64-elf:host gcc-linaro-arm-eabi:host"
PKG_LONGDESC="Das U-Boot is a cross-platform bootloader for embedded systems."
PKG_TOOLCHAIN="manual"

PKG_CANUPDATE="${PROJECT}*"
PKG_NEED_UNPACK="$PROJECT_DIR/$PROJECT/bootloader"

make_target() {
  [ "${BUILD_WITH_DEBUG}" = "yes" ] && PKG_DEBUG=1 || PKG_DEBUG=0
  export PATH=$TOOLCHAIN/lib/gcc-linaro-aarch64-elf/bin/:$TOOLCHAIN/lib/gcc-linaro-arm-eabi/bin/:$PATH
  DEBUG=${PKG_DEBUG} CROSS_COMPILE=aarch64-elf- ARCH=arm CFLAGS="" LDFLAGS="" make distclean
  for PKG_SUBDEVICE in $SUBDEVICES; do
    PKG_SYSTEMMODE=""
    if [[ $PKG_SUBDEVICE = "Odroid_N2" ]]; then
      PKG_UBOOT_CONFIG="odroidn2_defconfig"
    fi
    if [[ $PKG_SUBDEVICE = "Khadas_VIM3" ]]; then
      PKG_UBOOT_CONFIG="khadas_vim3_defconfig"
    fi
    echo Building u-boot for $PKG_SUBDEVICE
    DEBUG=${PKG_DEBUG} CROSS_COMPILE=aarch64-elf- ARCH=arm CFLAGS="" LDFLAGS="" make $PKG_UBOOT_CONFIG
    DEBUG=${PKG_DEBUG} CROSS_COMPILE=aarch64-elf- ARCH=arm CFLAGS="" LDFLAGS="" SYSTEMMODE=${PKG_SYSTEMMODE} make HOSTCC="$HOST_CC" HOSTSTRIP="true"
    mv $(get_build_dir u-boot)/sd_fuse/u-boot.bin.sd.bin $(get_build_dir u-boot)/sd_fuse/${PKG_SUBDEVICE}_u-boot
  done
}

makeinstall_target() {
  mkdir -p $INSTALL/usr/share/bootloader

  # Always install the update script
  find_file_path bootloader/update.sh && cp -av ${FOUND_PATH} $INSTALL/usr/share/bootloader
  sed -e "s/@KERNEL_NAME@/$KERNEL_NAME/g" \
      -e "s/@LEGACY_KERNEL_NAME@/$LEGACY_KERNEL_NAME/g" \
      -e "s/@LEGACY_DTB_NAME@/$LEGACY_DTB_NAME/g" \
      -i $INSTALL/usr/share/bootloader/update.sh

  # Always install the canupdate script
  if find_file_path bootloader/canupdate.sh; then
    cp -av ${FOUND_PATH} $INSTALL/usr/share/bootloader
  fi

  for PKG_SUBDEVICE in $SUBDEVICES; do
    PKG_UBOOTBIN=$(get_build_dir u-boot)/sd_fuse/${PKG_SUBDEVICE}_u-boot
    cp -av ${PKG_UBOOTBIN} $INSTALL/usr/share/bootloader/${PKG_SUBDEVICE}_u-boot

    if find_file_path bootloader/${PKG_SUBDEVICE}_boot.ini; then
      cp -av ${FOUND_PATH} $INSTALL/usr/share/bootloader
    fi
  done
  find_file_path bootloader/config.ini && cp -av ${FOUND_PATH} $INSTALL/usr/share/bootloader
    sed -e "s/@PROJECT@/${PKG_CANUPDATE}/g" \
        -i $INSTALL/usr/share/bootloader/canupdate.sh
  find_file_path splash/boot-logo-1080.bmp.gz && cp -av ${FOUND_PATH} $INSTALL/usr/share/bootloader
  find_file_path splash/timeout-logo-1080.bmp.gz && cp -av ${FOUND_PATH} $INSTALL/usr/share/bootloader
}
