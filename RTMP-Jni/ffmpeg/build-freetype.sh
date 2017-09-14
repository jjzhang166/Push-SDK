#!/bin/sh
cd freetype-2.4.10

#### For i386 ########
#make clean
#make distclean
#./configure --prefix=/usr/local/iphone --enable-static=yes --enable-shared=no CC=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/cc CFLAGS="-arch i386 -Wno-extended-offsetof -miphoneos-version-min=7.0 -I/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/usr/include -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk" CPP=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/cpp AR=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/ar LDFLAGS="-arch i386 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -miphoneos-version-min=7.0"  
#make -j8 -B
#cp objs/.libs/libfreetype.a libfreetype-i386.a  

#### For x86_64 ########
#make clean
#make distclean
#./configure --prefix=/usr/local/iphone --enable-static=yes --enable-shared=no CC=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/cc CFLAGS="-arch x86_64  -Wno-extended-offsetof -miphoneos-version-min=7.0 -I/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/usr/include -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk" CPP=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/cpp AR=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/ar LDFLAGS="-arch x86_64 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -miphoneos-version-min=7.0"  
#make -j8 -B 
#cp objs/.libs/libfreetype.a libfreetype-x86_64.a  

#### For armv7 ########
make clean
make distclean
./configure --prefix=/usr/local/iphone --host=arm-apple-darwin --enable-static=yes --enable-shared=no CC=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/cc  CFLAGS="-arch armv7 -pipe -std=c99 -Wno-extended-offsetof -Wno-trigraphs -fpascal-strings -O2 -Wreturn-type -Wunused-variable -fmessage-length=0 -fvisibility=hidden -miphoneos-version-min=7.0 -I/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/usr/include/ -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk" AR=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/ar LDFLAGS="-arch armv7 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk -miphoneos-version-min=7.0"  
make -j8 -B
cp objs/.libs/libfreetype.a libfreetype-arm7.a  

#### For armv7s ########
make clean  
make distclean  
./configure --prefix=/usr/local/iphone --host=arm-apple-darwin --enable-static=yes --enable-shared=no CC=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/cc  CFLAGS="-arch armv7s -pipe -std=c99 -Wno-extended-offsetof -Wno-trigraphs -fpascal-strings -O2 -Wreturn-type -Wunused-variable -fmessage-length=0 -fvisibility=hidden -miphoneos-version-min=7.0 -I/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/usr/include/ -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk" AR=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/ar LDFLAGS="-arch armv7s -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk -miphoneos-version-min=7.0"  
make -j8 -B
cp objs/.libs/libfreetype.a libfreetype-arm7s.a  

#### For arm64 ########
make clean  
make distclean  
./configure --prefix=/usr/local/iphone --host=arm-apple-darwin --enable-static=yes --enable-shared=no CC=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/cc  CFLAGS="-arch arm64 -pipe -std=c99 -Wno-extended-offsetof -Wno-trigraphs -fpascal-strings -O2 -Wreturn-type -Wunused-variable -fmessage-length=0 -fvisibility=hidden -miphoneos-version-min=7.0 -I/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/usr/include/ -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk" AR=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/ar LDFLAGS="-arch arm64 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk -miphoneos-version-min=7.0"  
make -j8 -B
cp objs/.libs/libfreetype.a libfreetype-arm64.a  

#lipo -create -output libfreetype.a libfreetype-i386.a libfreetype-x86_64.a libfreetype-arm7.a libfreetype-arm7s.a libfreetype-arm64.a  
lipo -create -output libfreetype.a libfreetype-arm7.a libfreetype-arm7s.a libfreetype-arm64.a
make clean && make distclean
lipo -info libfreetype.a  
