#!/bin/bash
NDK=/opt/android-ndk-r10e
SYSROOT=$NDK/platforms/android-14/arch-arm/

### For ARMv7

cp -rf /home/eoollo/SVN/AppStreaming/ffmpeg/ffmpeg-2.8.2/ build/v7a
cd build/v7a
TOOLCHAIN=$NDK/toolchains/arm-linux-androideabi-4.8/prebuilt/linux-x86_64
function build_one
{
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
		--extra-cflags="-Os -fpic $ADDI_CFLAGS" \
		--extra-ldflags="$ADDI_LDFLAGS" \
		$ADDITIONAL_CONFIGURE_FLAG
		make clean
		make -j8
		make install
}
PREFIX=/home/eoollo/SVN/AppStreaming/ffmpeg/build/android/armeabi-v7a
ADDI_CFLAGS="-marm"
build_one
cd ../..


### For x86
cp -rf /home/eoollo/SVN/AppStreaming/ffmpeg/ffmpeg-2.8.2/ build/x86
TOOLCHAIN=$NDK/toolchains/x86-4.9/prebuilt/linux-x86_64
cd build/x86
function build_one_x86
{
	./configure \
		--prefix=$PREFIX \
		--enable-shared \
		--disable-static \
		--disable-doc \
		--disable-ffmpeg \
		--disable-ffplay \
		--disable-ffprobe \
		--disable-ffserver \
		--disable-avdevice \
		--disable-doc \
		--disable-symver \
		--cross-prefix=$TOOLCHAIN/bin/i686-linux-android- \
		--target-os=linux \
		--arch=arm \
		--incdir=/home/eoollo/SVN/AppStreaming/ffmpeg/freetype-2.4.10/include/ /home/eoollo/SVN/AppStreaming/ffmpeg/build/x86 \
		--enable-cross-compile \
		--sysroot=$SYSROOT \
		--extra-cflags="-Os -fpic $ADDI_CFLAGS" \
		--extra-ldflags="$ADDI_LDFLAGS" \
		$ADDITIONAL_CONFIGURE_FLAG
		make clean
		make -j8
		make install
}
PREFIX=/home/eoollo/SVN/AppStreaming/ffmpeg/build/android/x86
ADDI_CFLAGS="-marm"
build_one_x86
cd ../..

### For x86_64
cp -rf /home/eoollo/SVN/AppStreaming/ffmpeg/ffmpeg-2.8.2/ build/x86_64
cd  build/x86_64
TOOLCHAIN=$NDK/toolchains/x86_64-4.9/prebuilt/linux-x86_64
function build_one_x86_64
{
	./configure \
		--prefix=$PREFIX \
		--enable-shared \
		--disable-static \
		--disable-doc \
		--disable-ffmpeg \
		--disable-ffplay \
		--disable-ffprobe \
		--disable-ffserver \
		--disable-avdevice \
		--disable-doc \
		--disable-symver \
		--cross-prefix=$TOOLCHAIN/bin/x86_64-linux-android- \
		--target-os=linux \
		--arch=arm \
		--incdir=/home/eoollo/SVN/AppStreaming/ffmpeg/freetype-2.4.10/include/ /home/eoollo/SVN/AppStreaming/ffmpeg/build/x86_64 \
		--enable-cross-compile \
		--sysroot=$SYSROOT \
		--extra-cflags="-Os -fpic $ADDI_CFLAGS" \
		--extra-ldflags="$ADDI_LDFLAGS" \
		$ADDITIONAL_CONFIGURE_FLAG
		make clean
		make -j8
		make install
}
PREFIX=/home/eoollo/SVN/AppStreaming/ffmpeg/build/android/x86_64
ADDI_CFLAGS="-marm"
build_one_x86_64
cd ../..


