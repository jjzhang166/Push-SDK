ndk-build -j8
cp ./libs/armeabi-v7a/* ./app/src/main/jniLibs/armeabi-v7a/
sh ./gradlew installDebug

