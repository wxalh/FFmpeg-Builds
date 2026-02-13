#!/usr/bin/env bash
set -euo pipefail 2>/dev/null || set -eu

FFMPEG_DIR="${1:-.}"

echo "Disabling SetThreadDescription in ${FFMPEG_DIR} for 32-bit build..."

TARGET_FILE="${FFMPEG_DIR}/compat/w32pthreads.h"
if [ -f "${TARGET_FILE}" ]; then
  if grep -q "\!HAVE_UWP" "${TARGET_FILE}"; then
    sed -i.bak -E 's/\!HAVE_UWP/0/' "${TARGET_FILE}"
    echo "Patched ${TARGET_FILE} (replaced !HAVE_UWP)"
  else
    echo "No !HAVE_UWP line found in ${TARGET_FILE} (nothing to do for that step)"
  fi

  # --- Replace entire win32_thread_setname() body with a one-line return ---
  # This makes the function simply return AVERROR(ENOSYS) unconditionally.
  # Creates another backup: ${TARGET_FILE}.perl.bak
  perl -0777 -i.bak2 -pe '
    s{
      (static\s+inline\s+int\s+win32_thread_setname\s*\([^)]*\)\s*\{)   # group 1: function header + opening brace
      .*?                                                             # non-greedy match of the whole body (including preproc branches)
      \}                                                               # the closing brace of the function
    }{$1 return AVERROR(ENOSYS);\} }sx
  ' "${TARGET_FILE}"

  if grep -q "win32_thread_setname(const char \\*name) { return AVERROR(ENOSYS); }" "${TARGET_FILE}"; then
    echo "Rewrote win32_thread_setname() in ${TARGET_FILE}"
  else
    echo "Warning: failed to rewrite win32_thread_setname() automatically. Inspect ${TARGET_FILE}.bak2"
  fi
else
  echo "Warning: ${TARGET_FILE} not found"
fi

TARGET_FILE="${FFMPEG_DIR}/libavcodec/mf_utils.c"

echo "Commenting out MF_MT_VIDEO_ROTATION entry in ${TARGET_FILE} ..."

if [ -f "${TARGET_FILE}" ]; then
  if grep -Fq "GUID_ENTRY(MF_MT_VIDEO_ROTATION)" "${TARGET_FILE}"; then
    sed -i.bak -E 's/^[[:space:]]*(GUID_ENTRY\(\s*MF_MT_VIDEO_ROTATION\s*\),)//' "${TARGET_FILE}"
    echo "Patched ${TARGET_FILE}"
  else
    echo "No GUID_ENTRY(MF_MT_VIDEO_ROTATION) found in ${TARGET_FILE} (nothing to do)"
  fi
else
  echo "Warning: ${TARGET_FILE} not found"
fi

echo "Done."