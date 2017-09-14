#!/bin/sh

rm -rf build librtmp.a
sync
mkdir -p build/v7 build/v7s build/arm64

cp -rf rtmpdump-ios/* build/v7
cp -rf rtmpdump-ios/* build/v7s
cp -rf rtmpdump-ios/* build/arm64

## Build for V7
cd build/v7/librtmp/
export CROSS_COMPILE=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/
#export XLDFLAGS="-isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk -L../openssl/include/openssl/lib/ -arch armv7"
export XLDFLAGS="-isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk -L/Users/wangyong/Code/Back/AppStreaming/rtmpdump-ios/openssl -arch armv7"
export XCFLAGS="-isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk -I../openssl-1.0.0g/include/ -arch armv7"
make clean
make SYS=darwin -j8 -B
cd ../../..

## Build for V7s
cd build/v7s/librtmp/
export CROSS_COMPILE=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/
#export XLDFLAGS="-isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk -L../openssl/include/openssl/lib/ -arch armv7s"
export XLDFLAGS="-isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk -L/Users/wangyong/Code/Back/AppStreaming/rtmpdump-ios/openssl -arch armv7s"
export XCFLAGS="-isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk -I../openssl-1.0.0g/include/ -arch armv7s"
make clean
make SYS=darwin -j8 -B
cd ../../..

## Build for arm64
cd build/arm64/librtmp/
export CROSS_COMPILE=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/
#export XLDFLAGS="-isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk -L../openssl/include/openssl/lib/ -arch arm64"
export XLDFLAGS="-isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk -L/Users/wangyong/Code/Back/AppStreaming/rtmpdump-ios/openssl -arch arm64"
export XCFLAGS="-isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk -I../openssl-1.0.0g/include/ -arch arm64"
make clean
make SYS=darwin -j8 -B
cd ../../..

lipo build/v7/librtmp/librtmp.a build/v7s/librtmp/librtmp.a build/arm64/librtmp/librtmp.a -create -output librtmp.a
rm -rf build
