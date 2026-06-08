#!/bin/bash

SCRIPT_REPO="https://github.com/rockchip-linux/mpp.git"
SCRIPT_COMMIT="c2c1ee502b3a26efebcf843f7a0aeb4d172c6237"
SCRIPT_COMMIT_LEGACY="31814aea59947cb2b5347b8fa1f2dabfee6fc6c9"

ffbuild_depends() {
    echo base
    echo vaapi
}

ffbuild_enabled() {
    [[ $TARGET != linuxarm64 && $TARGET != linuxarmhf ]] && return -1
    (( $(ffbuild_ffver) >= 800 )) || return -1
    return 0
}

ffbuild_dockerbuild() {
    local rkmpp_src="mpp-current"

    if [[ $RKMPP_LEGACY == 1 ]]; then
        rkmpp_src="mpp-legacy"
    fi

    cd "$rkmpp_src"

    export CFLAGS="$RAW_CFLAGS"
    export CXXFLAGS="$RAW_CXXFLAGS"
    export LDFLAGS="$RAW_LDFLAGS"

    if ! echo '#include <linux/dma-buf.h>' | "$CC" -E -x c - >/dev/null 2>&1; then
        mkdir -p ffbuild-compat/linux
        cat >ffbuild-compat/linux/dma-buf.h <<'EOF'
/* SPDX-License-Identifier: GPL-2.0 WITH Linux-syscall-note */
#ifndef _DMA_BUF_UAPI_H_
#define _DMA_BUF_UAPI_H_

#include <linux/ioctl.h>
#include <linux/types.h>

struct dma_buf_sync {
    __u64 flags;
};

#define DMA_BUF_SYNC_READ  (1 << 0)
#define DMA_BUF_SYNC_WRITE (2 << 0)
#define DMA_BUF_SYNC_RW    (DMA_BUF_SYNC_READ | DMA_BUF_SYNC_WRITE)
#define DMA_BUF_SYNC_START (0 << 2)
#define DMA_BUF_SYNC_END   (1 << 2)

#define DMA_BUF_BASE       'b'
#define DMA_BUF_IOCTL_SYNC _IOW(DMA_BUF_BASE, 0, struct dma_buf_sync)

#endif
EOF

        export CFLAGS="$CFLAGS -I$PWD/ffbuild-compat"
        export CXXFLAGS="$CXXFLAGS -I$PWD/ffbuild-compat"
    fi

    if [[ $RKMPP_LEGACY == 1 && ! -f ffbuild-legacy-compat-applied ]]; then
        if ! grep -q 'mpp_buffer_sync_begin_f' inc/mpp_buffer.h; then
            sed -i '/#define mpp_buffer_group_get_internal/i \
#define mpp_buffer_sync_begin(buffer) \\\
        mpp_buffer_sync_begin_f(buffer, 0, __FUNCTION__)\
#define mpp_buffer_sync_end(buffer) \\\
        mpp_buffer_sync_end_f(buffer, 0, __FUNCTION__)\
#define mpp_buffer_sync_partial_begin(buffer, offset, length) \\\
        mpp_buffer_sync_partial_begin_f(buffer, 0, offset, length, __FUNCTION__)\
#define mpp_buffer_sync_partial_end(buffer, offset, length) \\\
        mpp_buffer_sync_partial_end_f(buffer, 0, offset, length, __FUNCTION__)\
' inc/mpp_buffer.h

            sed -i '/MPP_RET mpp_buffer_group_get/i \
MPP_RET mpp_buffer_sync_begin_f(MppBuffer buffer, RK_S32 ro, const char *caller);\
MPP_RET mpp_buffer_sync_end_f(MppBuffer buffer, RK_S32 ro, const char *caller);\
MPP_RET mpp_buffer_sync_partial_begin_f(MppBuffer buffer, RK_S32 ro, RK_U32 offset, RK_U32 length, const char *caller);\
MPP_RET mpp_buffer_sync_partial_end_f(MppBuffer buffer, RK_S32 ro, RK_U32 offset, RK_U32 length, const char *caller);\
' inc/mpp_buffer.h
        fi

        if ! grep -q '#include "mpp_buffer.h"' mpp/base/mpp_buffer.cpp; then
            sed -i '/#include "mpp_buffer_impl.h"/i #include "mpp_buffer.h"' mpp/base/mpp_buffer.cpp
        fi

        cat >>mpp/base/mpp_buffer.cpp <<'EOF'

MPP_RET mpp_buffer_sync_begin_f(MppBuffer buffer, RK_S32 ro, const char *caller)
{
    (void)buffer;
    (void)ro;
    (void)caller;
    return MPP_OK;
}

MPP_RET mpp_buffer_sync_end_f(MppBuffer buffer, RK_S32 ro, const char *caller)
{
    (void)buffer;
    (void)ro;
    (void)caller;
    return MPP_OK;
}

MPP_RET mpp_buffer_sync_partial_begin_f(MppBuffer buffer, RK_S32 ro, RK_U32 offset, RK_U32 length, const char *caller)
{
    (void)buffer;
    (void)ro;
    (void)offset;
    (void)length;
    (void)caller;
    return MPP_OK;
}

MPP_RET mpp_buffer_sync_partial_end_f(MppBuffer buffer, RK_S32 ro, RK_U32 offset, RK_U32 length, const char *caller)
{
    (void)buffer;
    (void)ro;
    (void)offset;
    (void)length;
    (void)caller;
    return MPP_OK;
}
EOF

        touch ffbuild-legacy-compat-applied
    fi

    mkdir ffbuild-build && cd ffbuild-build

    cmake -DCMAKE_TOOLCHAIN_FILE="$FFBUILD_CMAKE_TOOLCHAIN" -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$FFBUILD_PREFIX" \
        -DBUILD_SHARED_LIBS=NO -DBUILD_TEST=OFF ..
    make -j$(nproc)
    make install DESTDIR="$FFBUILD_DESTDIR"

    if [[ $RKMPP_LEGACY == 1 ]]; then
        rm -rf "$FFBUILD_DESTPREFIX"/lib/librockchip_vpu.so*
    else
        rm -rf "$FFBUILD_DESTPREFIX"/lib/librockchip_{mpp,vpu}.so*
    fi
    rm -rf "$FFBUILD_DESTPREFIX"/bin
}

ffbuild_dockerdl() {
    echo "git-mini-clone \"$SCRIPT_REPO\" \"$SCRIPT_COMMIT\" mpp-current"
    echo "git-mini-clone \"$SCRIPT_REPO\" \"$SCRIPT_COMMIT_LEGACY\" mpp-legacy"
}

ffbuild_configure() {
    echo --enable-rkmpp
}

ffbuild_unconfigure() {
    (( $(ffbuild_ffver) >= 800 )) || return 0
    echo --disable-rkmpp
}
