#!/bin/bash

SCRIPT_REPO="https://github.com/ggml-org/whisper.cpp.git"
SCRIPT_COMMIT="8443cf05e3fa8ce1b32348e1bcbcf8fc31f7f3ae"
SCRIPT_VERSION="1.8.4"
SCRIPT_STAGE_CACHEBUST="20260609-pkgconfig-libdir"

ffbuild_depends() {
    echo base
    echo vulkan
    echo opencl
}

ffbuild_enabled() {
    [[ $TARGET == linuxarmhf ]] && return -1
    [[ $TARGET == linuxppc64 || $TARGET == linuxmips64 || $TARGET == linuxriscv64 ]] && return -1
    [[ $TARGET != *32 ]] || return -1
    (( $(ffbuild_ffver) >= 800 )) || return -1
    [[ $TARGET == linuxppc64 || $TARGET == linuxriscv64 || $TARGET == linuxmips64 ]] && return -1
    return 0
}

ffbuild_dockerstage() {
    if [[ -n "$SELFCACHE" ]]; then
        to_df "RUN --mount=src=${SELF},dst=/stage.sh --mount=src=${SELFCACHE},dst=/cache.tar.xz WHISPER_STAGE_CACHEBUST=${SCRIPT_STAGE_CACHEBUST} run_stage /stage.sh"
    else
        to_df "RUN --mount=src=${SELF},dst=/stage.sh WHISPER_STAGE_CACHEBUST=${SCRIPT_STAGE_CACHEBUST} run_stage /stage.sh"
    fi
}

ffbuild_dockerbuild() {
    mkdir build && cd build

    cmake -GNinja -DCMAKE_TOOLCHAIN_FILE="$FFBUILD_CMAKE_TOOLCHAIN" -DCMAKE_INSTALL_PREFIX="$FFBUILD_PREFIX" -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_SHARED_LIBS=OFF -DWHISPER_BUILD_TESTS=OFF -DWHISPER_BUILD_EXAMPLES=OFF -DWHISPER_BUILD_SERVER=OFF -DWHISPER_USE_SYSTEM_GGML=OFF \
        -DGGML_CCACHE=OFF -DGGML_OPENCL=ON -DGGML_VULKAN=ON \
        -DGGML_NATIVE=OFF -DGGML_SSE42=ON -DGGML_AVX=ON -DGGML_F16C=ON -DGGML_AVX2=ON -DGGML_BMI2=ON -DGGML_FMA=ON ..

    ninja -j$(nproc)
    DESTDIR="$FFBUILD_DESTDIR" ninja install

    # For some reason, these lack the lib prefix on Windows
    shopt -s nullglob
    for libfile in "$FFBUILD_DESTPREFIX"/lib/ggml*.a; do
        mv "${libfile}" "$(dirname "${libfile}")/lib$(basename "${libfile}")"
    done

    local pc="$FFBUILD_DESTPREFIX"/lib/pkgconfig/whisper.pc
    test -f "$pc"

    sed -i \
        -e "s/^\(Version:\).*$/\1 ${SCRIPT_VERSION}/" \
        -e 's/^\(Libs:\).*$/\1 -L${libdir} -lwhisper/' \
        -e '/^Libs.private:/d' \
        -e '/^Requires:/d' \
        -e '/^Requires.private:/d' \
        "$pc"
    {
        echo "Libs.private: -lggml -lggml-base -lggml-cpu -lggml-vulkan -lggml-opencl -lstdc++"
        echo "Requires.private: vulkan OpenCL"
    } >> "$pc"

    PKG_CONFIG_LIBDIR="$FFBUILD_DESTPREFIX/lib/pkgconfig:$FFBUILD_DESTPREFIX/share/pkgconfig:$FFBUILD_PREFIX/lib/pkgconfig:$FFBUILD_PREFIX/share/pkgconfig" \
        pkg-config --static --print-errors --exists "whisper >= 1.7.5"
}

ffbuild_configure() {
    echo --enable-whisper
}

ffbuild_unconfigure() {
    (( $(ffbuild_ffver) >= 800 )) || return 0
    echo --disable-whisper
}
