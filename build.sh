#!/bin/bash
VERSION=20230102

SHORT=u,l,i,p,h
LONG=build-uboot,build-linux,build-image,pack-image,help
OPTS=$(getopt --options $SHORT --longoptions $LONG --name "$0" -- "$@")
eval set -- "$OPTS"

while true; do
  case "$1" in
    -u|--build-uboot)
      BUILD_UBOOT=1
      shift
      ;;
    -l|--build-linux)
      BUILD_LINUX=1
      shift
      ;;
    -i|--build-image)
      BUILD_IMAGE=1
      shift
      ;;
    -p|--pack-image)
      PACK_IMAGE=1
      shift
      ;;
    -h|--help)
      echo "Usage: build.sh [options]"
      echo "Options:"
      echo "  -bu, --build-uboot  Build U-Boot"
      echo "  -bl, --build-linux  Build Linux"
      echo "  -bi, --build-image  Build Image"
      echo "  -pi, --pack-image   Pack Image"
      echo "  -h,  --help         Display this help and exit"
      exit 0
      ;;
    --)
      shift
      break
      ;;
    *)
      echo "Invalid option: $1"
      exit 1
      ;;
  esac
done

if [ -v BUILD_UBOOT ]; then
  echo "Building U-Boot..."
  if [ ! -d uboot-soquartz-super6c ]; then
    git clone https://github.com/JoshuaMulliken/uboot-soquartz-super6c.git
  fi

  sudo buildarmpkg -p uboot-soquartz-super6c
fi

if [ -v BUILD_LINUX ]; then
  echo "Building Linux..."
  if [ ! -d linux-soquartz-super6c ]; then
    git clone https://github.com/JoshuaMulliken/linux-soquartz-super6c.git
  fi

  sudo buildarmpkg -p linux-soquartz-super6c
fi

if [ -v BUILD_IMAGE ]; then
  echo "Building Image..."
  
  # Create the packages directory
  mkdir -p packages

  # Copy the packages to the packages directory
  cp /var/cache/manjaro-arm-tools/pkg/aarch64/uboot-soquartz-super6c-*.pkg.tar.zst packages/
  cp /var/cache/manjaro-arm-tools/pkg/aarch64/linux-[0-9]*.pkg.tar.zst packages/

  sudo getarmprofiles -f
  sudo cp soquartz-super6c-profile /usr/share/manjaro-arm-tools/profiles/arm-profiles/devices/

  # Create the image
  sudo buildarmimg -d soquartz-super6c -e minimal -b stable -v $VERSION -i packages
fi

if [ -v PACK_IMAGE ]; then
  # Copy the image to the current directory
  cp /var/cache/manjaro-arm-tools/img/Manjaro-ARM-minimal-soquartz-super6c-$VERSION.img.xz .

  # Extract the image
  if [ -f Manjaro-ARM-minimal-soquartz-super6c-$VERSION.img ]; then
    rm Manjaro-ARM-minimal-soquartz-super6c-$VERSION.img
  fi
  unxz Manjaro-ARM-minimal-soquartz-super6c-$VERSION.img.xz

  # Extract the uboot package
  cp packages/uboot-soquartz-super6c-*.pkg.tar.zst .
  mkdir -p uboot-soquartz-super6c-pkg
  tar -xvf uboot-soquartz-super6c-*.pkg.tar.zst --directory=uboot-soquartz-super6c-pkg

  # Use dd to write the uboot to the image
  dd if=uboot-soquartz-super6c-pkg/boot/idbloader.img of=Manjaro-ARM-minimal-soquartz-super6c-$VERSION.img seek=64 conv=notrunc,fsync
  dd if=uboot-soquartz-super6c-pkg/boot/u-boot.itb of=Manjaro-ARM-minimal-soquartz-super6c-$VERSION.img seek=16384 conv=notrunc,fsync

  echo "You can now flash the image to an SD card with the following command:"
  echo "sudo dd if=Manjaro-ARM-minimal-soquartz-super6c-$VERSION.img of=/dev/sdX bs=4M status=progress"
fi