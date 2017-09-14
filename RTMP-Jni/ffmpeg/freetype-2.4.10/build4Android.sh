#!/bin/bash

export PATH=/home/eoollo/SVN/AppStreaming/ffmpeg/freetype-2.4.10/toolchain/bin:$PATH

### For ARMv7

rm -rf  freetype toolchain
mkdir -p /home/eoollo/SVN/AppStreaming/ffmpeg/freetype-2.4.10/freetype/armv7

/opt/android-ndk-r10e/build/tools/make-standalone-toolchain.sh platform=android-14 --toolchain=arm-linux-androideabi-4.8 --install-dir=/home/eoollo/SVN/AppStreaming/ffmpeg/freetype-2.4.10/toolchain/ --system=linux-x86_64
export PATH=/home/eoollo/SVN/AppStreaming/ffmpeg/freetype-2.4.10/toolchain/bin/:$PATH

./configure --host=arm-linux-androideabi --prefix=/home/eoollo/SVN/AppStreaming/ffmpeg/freetype-2.4.10/freetype/armv7 --without-zlib --with-png=no --with-harfbuzz=no
make -j8 -B
make install

make clean
make distclean
rm -rf toolchain

### For ARM64
mkdir -p /home/eoollo/SVN/AppStreaming/ffmpeg/freetype-2.4.10/freetype/arm64
/opt/android-ndk-r10e/build/tools/make-standalone-toolchain.sh platform=android-14 --toolchain=aarch64-linux-android-4.9 --install-dir=/home/eoollo/SVN/AppStreaming/ffmpeg/freetype-2.4.10/toolchain/ --system=linux-x86_64
./configure --host=aarch64-linux-android --prefix=/home/eoollo/SVN/AppStreaming/ffmpeg/freetype-2.4.10/freetype/arm64 #--without-zlib --with-png=no --with-harfbuzz=no
make -j8 -B
make install 

make clean
make distclean
rm -rf toolchain


### For x86
mkdir -p /home/eoollo/SVN/AppStreaming/ffmpeg/freetype-2.4.10/freetype/x86
/opt/android-ndk-r10e/build/tools/make-standalone-toolchain.sh platform=android-14 --toolchain=x86-4.8 --install-dir=/home/eoollo/SVN/AppStreaming/ffmpeg/freetype-2.4.10/toolchain/ --system=linux-x86_64
./configure --host=i686-linux-android --prefix=/home/eoollo/SVN/AppStreaming/ffmpeg/freetype-2.4.10/freetype/x86 --without-zlib --with-png=no --with-harfbuzz=no
make -j8 -B
make install 

make clean
make distclean
rm -rf toolchain


### For x86_64
mkdir -p /home/eoollo/SVN/AppStreaming/ffmpeg/freetype-2.4.10/freetype/x86_64
/opt/android-ndk-r10e/build/tools/make-standalone-toolchain.sh platform=android-14 --toolchain=x86_64-4.9 --install-dir=/home/eoollo/SVN/AppStreaming/ffmpeg/freetype-2.4.10/toolchain/ --system=linux-x86_64
./configure --host=x86_64-linux-android --prefix=/home/eoollo/SVN/AppStreaming/ffmpeg/freetype-2.4.10/freetype/x86_64 --without-zlib --with-png=no --with-harfbuzz=no
make -j8 -B
make install 

make clean
make distclean
rm -rf toolchain
