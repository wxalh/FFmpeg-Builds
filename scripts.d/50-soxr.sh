#!/bin/bash

SCRIPT_REPO="https://git.code.sf.net/p/soxr/code"
SCRIPT_COMMIT="945b592b70470e29f917f4de89b4281fbbd540c0"

ffbuild_enabled() {
    return 0
}

ffbuild_dockerbuild() {
    sed -i 's/VERSION 3.1 /VERSION 3.1...3.10 /g' CMakeLists.txt

    # Short-circuit the check to generate a .pc file. We always want it.
    sed -i 's/NOT WIN32/1/g' src/CMakeLists.txt

    mkdir build && cd build

    local openmp=ON
    if ! ffbuild_soxr_openmp_enabled; then
        openmp=OFF
    fi

    cmake -DCMAKE_TOOLCHAIN_FILE="$FFBUILD_CMAKE_TOOLCHAIN" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$FFBUILD_PREFIX" \
        -DWITH_OPENMP="$openmp" \
        -DBUILD_TESTS=OFF -DBUILD_EXAMPLES=OFF -DBUILD_SHARED_LIBS=OFF \
        ..
    make -j$(nproc)
    make install DESTDIR="$FFBUILD_DESTDIR"

    if ffbuild_soxr_openmp_enabled; then
        echo "Libs.private: -lgomp" >> "$FFBUILD_DESTPREFIX"/lib/pkgconfig/soxr.pc
    fi
}

ffbuild_soxr_openmp_enabled() {
    [[ $TARGET == winarm64 || $TARGET == linuxppc64 || $TARGET == linuxriscv64 || $TARGET == linuxmips64 ]] && return -1
    return 0
}

ffbuild_configure() {
    echo --enable-libsoxr
}

ffbuild_unconfigure() {
    echo --disable-libsoxr
}

ffbuild_ldflags() {
    echo -pthread
}

ffbuild_libs() {
    ffbuild_soxr_openmp_enabled && echo -lgomp
}
