#!/bin/sh
# Guard the Mali-compatible EGL cache optimization.
set -eu
cd "$(dirname "$0")/.."
[ -f system.prop ] || { echo 'Missing EGL cache property file' >&2; exit 1; }
count=$(grep -c '^ro\.egl\.blobcache\.multifile=true$' system.prop)
[ "$count" = 1 ] || { echo 'Multifile EGL blobcache must be enabled exactly once' >&2; exit 1; }
if grep -Eq '^([[:space:]]*)?(ro|debug)\.egl\.blobcache\.multifile_limit=' system.prop; then
  echo 'Do not override the ROM EGL blobcache size limit' >&2
  exit 1
fi
if grep -Eq '^debug\.egl\.blobcache\.multifile=' system.prop; then
  echo 'Debug mode must remain user-controlled for opt-out' >&2
  exit 1
fi
for lib in system/vendor/lib/egl/libGLES_mali.so system/vendor/lib64/egl/libGLES_mali.so; do
  [ -f "$lib" ] || { echo "Missing $lib" >&2; exit 1; }
  if ! strings -a "$lib" | grep -Fq 'EGL_ANDROID_blob_cache'; then
    echo "Driver lacks expected EGL_ANDROID_blob_cache: $lib" >&2
    exit 1
  fi
done
sh tools/verify-mali-blobs.sh
python3 tests/check-vulkan-features.py
echo 'PASS: EGL cache optimization is enabled; original Mali and Vulkan 1.3 unchanged.'
