#!/usr/bin/env bash
set -euo pipefail

FFMPEG_DIR="${1:-.}"   # 第一个参数是 FFmpeg 源码根目录（默认当前目录）
TARGET_FILE="${FFMPEG_DIR}/libavcodec/mf_utils.c"

if [ -f "${TARGET_FILE}" ]; then
  cp -a "${TARGET_FILE}" "${TARGET_FILE}.bak"
  # 用 awk 插入条件保护，查找 GUID_ENTRY(MF_MT_VIDEO_ROTATION)
	awk '
	  BEGIN{ found=0 }
	  {
		if ($0 ~ /GUID_ENTRY\(MF_MT_VIDEO_ROTATION\)/ && !found) {
		  print "#if defined(MF_MT_VIDEO_ROTATION)";
		  print $0;
		  print "#endif";
		  found=1;
		} else {
		  print $0;
		}
	  }
	' "${TARGET_FILE}.bak" > "${TARGET_FILE}.tmp" && mv "${TARGET_FILE}.tmp" "${TARGET_FILE}"

	echo "Patched ${TARGET_FILE} (backup at ${TARGET_FILE}.bak)"
else
  echo "Warning: ${TARGET_FILE} not found"
fi



