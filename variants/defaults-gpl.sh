FF_CONFIGURE="--enable-gpl --enable-version3"

if [[ $TARGET == win32 ]]; then
    FF_CONFIGURE+=" --disable-debug --disable-w32threads --enable-pthreads --disable-filter=gfxcapture"
fi

FF_CFLAGS=""
FF_CXXFLAGS=""
FF_LDFLAGS=""
GIT_BRANCH="master"
LICENSE_FILE="COPYING.GPLv3"
