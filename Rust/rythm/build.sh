export PKG_CONFIG_ALLOW_CROSS=1
export PKG_CONFIG_PATH=$VCPKG_ROOT/installed/arm64-android/lib/pkgconfig

cargo ndk -t arm64-v8a build --release