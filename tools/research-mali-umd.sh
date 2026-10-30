#!/usr/bin/env bash
# Investigate read-only config switches embedded in the proprietary Mali UMD.
set -euo pipefail
cd "$(dirname "$0")/.."
for bin in system/vendor/lib/egl/libGLES_mali.so system/vendor/lib64/egl/libGLES_mali.so; do
  printf '### %s\n' "$bin"
  printf '### Version/build hints\n'
  strings -a -n 8 "$bin" | LC_ALL=C grep -Ei '(r38p1|r[0-9]{2}p[0-9]+-|mali-g78|Mali-G78|Vulkan 1\.[0-9]|vulkan_1_[0-9]|MALI-.*r38)' | LC_ALL=C sort -u | sed -n '1,80p' || :
  printf '### Readable Android properties and environment keys\n'
  strings -a -n 7 "$bin" | LC_ALL=C grep -Ei '^(debug[._]|persist[._]|ro[._]|vendor[._]|MALI_[A-Za-z_]|mali_[A-Za-z_]|EGL_[A-Za-z_]|MESA_[A-Za-z_])' | LC_ALL=C sort -u | sed -n '1,180p' || :
  printf '### Relevant exported API entrypoints\n'
  readelf --dyn-syms -W "$bin" | awk '$7 != "UND" && ($8 ~ /^vk(GetPhysicalDeviceProperties|EnumerateInstanceVersion|GetInstanceProcAddr|CreateInstance)/ || $8 ~ /^egl(SwapBuffers|QueryString|GetProcAddress)/) {print $8}' | sort -u
  printf '### ABI compatibility version symbols\n'
  readelf -V "$bin" | LC_ALL=C grep -E '(Name: |Version needs section)' | sed -n '1,45p' || :
  printf '\n'
done
