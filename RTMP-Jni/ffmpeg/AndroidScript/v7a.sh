#!/bin/bash
NDK=/opt/android-ndk-r10e
SYSROOT=$NDK/platforms/android-14/arch-arm/
mkdir -p build/android/armeabi-v7a

### For ARMv7

cp -rf /home/eoollo/SVN/AppStreaming/ffmpeg/ffmpeg-2.8.2/ build/v7a
cd build/v7a
TOOLCHAIN=$NDK/toolchains/arm-linux-androideabi-4.8/prebuilt/linux-x86_64
function build_one
{
	make clean
	make distclean

	./configure \
		--prefix=$PREFIX \
		--enable-shared \
		--enable-static \
		--disable-doc \
		--disable-ffmpeg \
		--disable-ffplay \
		--disable-ffprobe \
		--disable-ffserver \
		--disable-avdevice \
		--disable-doc \
		--disable-symver \
		--cross-prefix=$TOOLCHAIN/bin/arm-linux-androideabi- \
		--target-os=linux \
		--arch=arm \
		--incdir=/home/eoollo/SVN/AppStreaming/ffmpeg/freetype-2.4.10/include/ \
		--enable-cross-compile \
		--sysroot=$SYSROOT \
		--extra-cflags="-Os -fpic $ADDI_CFLAGS -D__Android__" \
		--extra-ldflags="$ADDI_LDFLAGS" \
		$ADDITIONAL_CONFIGURE_FLAG

		make -j8
		make install
}
PREFIX=/home/eoollo/SVN/AppStreaming/ffmpeg/build/android/armeabi-v7a
ADDI_CFLAGS="-marm"
build_one
cd ../..

