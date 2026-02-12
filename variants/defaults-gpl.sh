FF_CONFIGURE="--enable-gpl --enable-version3"

if [[ $TARGET == win32 ]]; then
    FF_CONFIGURE+=" --disable-debug --disable-w32threads --enable-pthreads --disable-filter=gfxcapture"
fi

FF_CFLAGS="-D_WIN32_WINNT=0x0601 -DWINVER=0x0601"
FF_CXXFLAGS=""
FF_LDFLAGS=""
GIT_BRANCH="master"
LICENSE_FILE="COPYING.GPLv3"
