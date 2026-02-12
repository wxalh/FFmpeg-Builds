#!/usr/bin/env bash
set -euo pipefail

FFMPEG_DIR="${1:-.}"   # 第一个参数是 FFmpeg 源码根目录（默认当前目录）
TARGET_FILE="${FFMPEG_DIR}/libavcodec/mf_utils.c"

echo "Commenting out MF_MT_VIDEO_ROTATION entry in ${TARGET_FILE} ..."

if [ -f "${TARGET_FILE}" ]; then
  # 使用固定字符串搜索以避免正则歧义
  if grep -Fq "GUID_ENTRY(MF_MT_VIDEO_ROTATION)" "${TARGET_FILE}"; then
    cp -a "${TARGET_FILE}" "${TARGET_FILE}.bak"
    # 用 sed 将包含 GUID_ENTRY(MF_MT_VIDEO_ROTATION), 的整行替换为注释行（保留原内容备份）
    sed -E -i 's/^[[:space:]]*(GUID_ENTRY\(\s*MF_MT_VIDEO_ROTATION\s*\),)/\/\* disabled-for-win7: \1 \*\//' "${TARGET_FILE}"
    echo "Patched ${TARGET_FILE} (backup at ${TARGET_FILE}.bak)"
  else
    echo "No GUID_ENTRY(MF_MT_VIDEO_ROTATION) found in ${TARGET_FILE} (nothing to do)"
  fi
else
  echo "Warning: ${TARGET_FILE} not found"
fi

echo "Done."