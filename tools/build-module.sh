#!/usr/bin/env bash
set -euo pipefail
ROOT=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT"

# Refuse modified Mali binaries or incompatible feature declarations.
sha256sum -c tools/mali-r38p1-baseline.sha256
sh tests/install-smoke.sh
sh tests/check-cache-policy.sh
python3 tests/check-vulkan-features.py

version=$(sed -n 's/^version=//p' module.prop | head -1)
[[ "$version" =~ ^[A-Za-z0-9_.-]+$ ]] || { echo "Unsafe module version" >&2; exit 1; }
out=${1:-dist}
mkdir -p "$out"
archive="$out/GpuDriverUpdate-Exynos2100-$version.zip"
rm -f "$archive"
zip -q -r -X "$archive" module.prop customize.sh system.prop META-INF system
unzip -tqq "$archive"
for path in module.prop customize.sh system.prop \
  META-INF/com/google/android/update-binary \
  system/vendor/lib/egl/libGLES_mali.so \
  system/vendor/lib64/egl/libGLES_mali.so \
  system/vendor/lib/hw/vulkan.mali.so \
  system/vendor/lib64/hw/vulkan.mali.so \
  system/vendor/etc/permissions/android.hardware.vulkan.version.xml; do
  unzip -Z1 "$archive" | grep -Fxq "$path" || { echo "Missing ZIP member: $path" >&2; exit 1; }
done
if unzip -Z1 "$archive" | grep -Fxq 'system/vendor/etc/permissions/android.software.vulkan.deqp.level.xml'; then
  echo "Refusing unverified dEQP flag" >&2
  exit 1
fi
sha256sum "$archive" > "$archive.sha256"
printf 'Verified module: %s\n' "$archive"
