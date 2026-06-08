#!/bin/bash

SCRIPT_REPO="https://github.com/google/snappy.git"
SCRIPT_COMMIT="27ab5f7f518430a021239bc26a5b2fd64affbc7b"

ffbuild_enabled() {
    [[ $TARGET == linuxriscv64 ]] && return -1
    return 0
}

ffbuild_dockerbuild() {
    mkdir build && cd build

    local myconf=(
        -DCMAKE_TOOLCHAIN_FILE="$FFBUILD_CMAKE_TOOLCHAIN"
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_INSTALL_PREFIX="$FFBUILD_PREFIX"
        -DBUILD_SHARED_LIBS=OFF
        -DSNAPPY_BUILD_TESTS=OFF
        -DSNAPPY_BUILD_BENCHMARKS=OFF
        -DSNAPPY_FUZZING_BUILD=OFF
        -DSNAPPY_REQUIRE_AVX=OFF
        -DSNAPPY_REQUIRE_AVX2=OFF
    )

    if [[ $TARGET == linuxppc64 || $TARGET == linuxriscv64 || $TARGET == linuxmips64 ]]; then
        myconf+=(
            -DSNAPPY_RVV_1=0
            -DSNAPPY_RVV_0_7=0
        )
    fi

    cmake "${myconf[@]}" ..
    make -j$(nproc)
    make install DESTDIR="$FFBUILD_DESTDIR"
}

ffbuild_configure() {
    echo --enable-libsnappy
}

ffbuild_unconfigure() {
    echo --disable-libsnappy
}
