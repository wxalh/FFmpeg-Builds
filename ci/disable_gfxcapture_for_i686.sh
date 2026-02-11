#!/usr/bin/env bash
set -euo pipefail

FFMPEG_DIR="${1:-.}"   # 第一个参数是 FFmpeg 源码根目录（默认当前目录）

echo "Disabling gfxcapture in ${FFMPEG_DIR} for 32-bit build..."

MAKEFILE="${FFMPEG_DIR}/libavfilter/Makefile"
if [ -f "${MAKEFILE}" ]; then
  if grep -q "OBJS-\\$\\(CONFIG_GFXCAPTURE_FILTER\\)" "${MAKEFILE}"; then
    sed -i.bak -E 's/^(OBJS-\$\(CONFIG_GFXCAPTURE_FILTER\).*)/#\1  # disabled for 32-bit build (Win7 compat)/' "${MAKEFILE}"
    echo "Patched ${MAKEFILE}"
  else
    echo "No gfxcapture OBJS line found in ${MAKEFILE} (nothing to do)"
  fi
else
  echo "Warning: ${MAKEFILE} not found"
fi

ALLFILTERS="${FFMPEG_DIR}/libavfilter/allfilters.c"
if [ -f "${ALLFILTERS}" ]; then
  if grep -q "ff_vsrc_gfxcapture" "${ALLFILTERS}"; then
    sed -i.bak -E 's/^(.*ff_vsrc_gfxcapture.*)$/\/\* disabled-for-win7 \*\/ \1 \/\* disabled-for-win7 \*\//g' "${ALLFILTERS}"
    echo "Patched ${ALLFILTERS}"
  else
    echo "No ff_vsrc_gfxcapture references found in ${ALLFILTERS} (nothing to do)"
  fi
else
  echo "Warning: ${ALLFILTERS} not found"
fi

echo "Done."