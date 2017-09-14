#!/bin/sh

rm -f ../*.o *.a

make -f Makefile_v7 -j8 -B
rm ../*.o
make -f Makefile_v7s -j8 -B
rm ../*.o
make -f Makefile_arm64 -j8 -B
rm ../*.o

echo "lipo librtmp-ios-v7.a librtmp-ios-v7s.a librtmp-ios-arm64.a -create -output librtmp-ios.a"

lipo librtmp-ios-v7.a librtmp-ios-v7s.a librtmp-ios-arm64.a -create -output librtmp-ios.a

rm librtmp-ios-v7.a librtmp-ios-v7s.a librtmp-ios-arm64.a
