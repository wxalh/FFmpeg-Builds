#!/usr/bin/env bash
set -euo pipefail 2>/dev/null || set -eu

FFMPEG_DIR="${1:-.}"

echo "Disabling SetThreadDescription in ${FFMPEG_DIR} for 32-bit build..."

W32PTHREADS_FILE="${FFMPEG_DIR}/compat/w32pthreads.h"
GFX_FILE="${FFMPEG_DIR}/libavfilter/vsrc_gfxcapture_winrt.cpp"
MF_FILE="${FFMPEG_DIR}/libavcodec/mf_utils.c"

# 1) 处理 compat/w32pthreads.h 中的 !HAVE_UWP 替换（保留 .bak）
if [ -f "${W32PTHREADS_FILE}" ]; then
  if grep -q "\!HAVE_UWP" "${W32PTHREADS_FILE}"; then
    # 在原有文件上做替换并保留 .bak
    sed -i.bak -E 's/\!HAVE_UWP/0/' "${W32PTHREADS_FILE}"
    echo "Patched ${W32PTHREADS_FILE} (replaced !HAVE_UWP -> 0), backup at ${W32PTHREADS_FILE}.bak"
  else
    echo "No !HAVE_UWP line found in ${W32PTHREADS_FILE} (nothing to do for that step)"
  fi

  # 2) 用 perl 跨行替换整个 win32_thread_setname() 函数体为一行 return
  #    生成备份 ${W32PTHREADS_FILE}.bak2
  perl -0777 -i.bak2 -pe '
    # 用非��婪匹配从函数头到首个闭合大括号对的末尾（/s允许跨行, /x允许注释空白）
    s{
      (static\s+inline\s+int\s+win32_thread_setname\s*\([^)]*\)\s*\{)  # group 1: header + {
      .*?                                                         # 非贪婪匹配函数体（包括预处理分支）
      \}                                                          # 关闭该函数的 }
    }{$1
    return AVERROR(ENOSYS);
}gsx
  ' "${W32PTHREADS_FILE}"

  echo "Rewrote win32_thread_setname() in ${W32PTHREADS_FILE}, backup at ${W32PTHREADS_FILE}.bak2"
else
  echo "Warning: ${W32PTHREADS_FILE} not found"
fi

# 3) 从 libavfilter/vsrc_gfxcapture_winrt.cpp 中删除所有包含 SetThreadDescription 的行
if [ -f "${GFX_FILE}" ]; then
  # 使用 perl 做行过滤并在原地创建备份（.bak3）
  perl -i.bak3 -ne 'print unless /SetThreadDescription/' "${GFX_FILE}"
  echo "Removed lines containing SetThreadDescription from ${GFX_FILE}, backup at ${GFX_FILE}.bak3"
else
  echo "Warning: ${GFX_FILE} not found"
fi

echo "Commenting out MF_MT_VIDEO_ROTATION entry in ${MF_FILE} ..."

if [ -f "${MF_FILE}" ]; then
  if grep -Fq "GUID_ENTRY(MF_MT_VIDEO_ROTATION)" "${MF_FILE}"; then
    sed -i.bak -E 's/^[[:space:]]*(GUID_ENTRY\(\s*MF_MT_VIDEO_ROTATION\s*\),)//' "${MF_FILE}"
    echo "Patched ${MF_FILE}"
  else
    echo "No GUID_ENTRY(MF_MT_VIDEO_ROTATION) found in ${MF_FILE} (nothing to do)"
  fi
else
  echo "Warning: ${MF_FILE} not found"
fi

echo "Done."