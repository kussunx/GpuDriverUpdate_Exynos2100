#!/usr/bin/env bash
# Analyze known-working proprietary Mali userspace without modifying a byte.
set -euo pipefail
cd "$(dirname "$0")/.."

for tool in readelf strings grep sort sha256sum; do
  command -v "$tool" >/dev/null || { echo "Missing tool: $tool" >&2; exit 2; }
done

sha256sum -c tools/mali-r38p1-baseline.sha256

for lib in system/vendor/lib/egl/libGLES_mali.so system/vendor/lib64/egl/libGLES_mali.so; do
  printf '\n=== %s ===\n' "$lib"
  markers=$(strings -a "$lib" | grep -E '^(U:)?r38p1-01bet0|^Mali-G78$' | sort -u || true)
  printf '%s\n' "$markers"
  if ! grep -qF 'r38p1-01bet0' <<< "$markers"; then
    echo "Wrong Mali UMD build marker: $lib" >&2
    exit 1
  fi
  if ! grep -qF 'Mali-G78' <<< "$markers"; then
    echo "Missing Mali-G78 compatibility marker: $lib" >&2
    exit 1
  fi

  echo '[Graphics dependencies]'
  needed=$(readelf -dW "$lib" | grep 'NEEDED')
  for dep in libnativewindow.so libion_exynos.so android.hardware.graphics.mapper@4.0.so; do
    if ! grep -Fq "[$dep]" <<< "$needed"; then
      echo "Missing expected dependency: $dep" >&2
      exit 1
    fi
    echo "$dep"
  done

  echo '[AFBC options embedded in proprietary code — NOT enabled]'
  strings -a "$lib" | grep -E '^GLES_(DISABLE_SURFACE_AFBC|DISABLE_TEXTURE_AFBC|DELAY_AFBC_DECOMPRESSION|AFBC_UPLOAD_HEURISTIC)$' | sort -u || :

  echo '[Known EGL cache extension]'
  if strings -a "$lib" | grep -F 'EGL_ANDROID_blob_cache' >/dev/null; then
    echo EGL_ANDROID_blob_cache
  else
    echo 'MISSING EGL_ANDROID_blob_cache' >&2
    exit 1
  fi
done

echo 'PASS: both Mali proprietary UMD variants match expected version markers, dependencies and cache extension.'
