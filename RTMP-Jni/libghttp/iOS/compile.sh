#!/bin/sh

rm -f ../jni/*.o *.a

make -f Makefile_v7 -j8 -B
rm ../jni/*.o
make -f Makefile_v7s -j8 -B
rm ../jni/*.o
make -f Makefile_arm64 -j8 -B
rm ../jni/*.o

echo "lipo libghttp-ios-v7.a libghttp-ios-v7s.a libghttp-ios-arm64.a -create -output libghttp-ios.a"

lipo libghttp-ios-v7.a libghttp-ios-v7s.a libghttp-ios-arm64.a -create -output libghttp-ios.a

rm libghttp-ios-v7.a libghttp-ios-v7s.a libghttp-ios-arm64.a
