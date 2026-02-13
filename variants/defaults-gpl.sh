FF_CONFIGURE="--enable-gpl --enable-version3"

FF_CFLAGS=""

if [[ $TARGET == win32 ]]; then
    FF_CFLAGS="-D_WIN32_WINNT=0x0601 -DWINVER=0x0601"
fi

FF_CXXFLAGS=""
FF_LDFLAGS=""
GIT_BRANCH="master"
LICENSE_FILE="COPYING.GPLv3"
