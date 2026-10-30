#!/system/bin/sh
# Safe installation of the existing Mali-G78 r38p1 userspace libraries.
# This file is sourced by the Magisk-compatible module installer.

MODID=$(grep_prop id "$MODPATH/module.prop")
MODVER=$(grep_prop version "$MODPATH/module.prop")

# Do not mount this Exynos 2100-specific driver on unrelated hardware.
# The product-board fallbacks cover Samsung Exynos 2100 devices where
# the SoC properties are absent or use different spellings.
SOC=$(getprop ro.soc.model 2>/dev/null)
PLATFORM=$(getprop ro.board.platform 2>/dev/null)
HARDWARE=$(getprop ro.hardware 2>/dev/null)
BOARD=$(getprop ro.product.board 2>/dev/null)
IDENTITY=$(printf '%s' "$SOC $PLATFORM $HARDWARE $BOARD" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')

case "$IDENTITY" in
  *exynos2100*|*universal2100*|*o1s*|*t2s*|*p3s*|*r9s*) ;;
  *) abort "Unsupported device: Exynos 2100 is required (SoC=$SOC, platform=$PLATFORM, board=$BOARD)" ;;
esac

# Refuse installations that would overlay the same Mali userspace libraries.
# Disabled or scheduled-for-removal modules are ignored.
check_conflicting_modules() {
  for root in "${MODULES_DIR:-/data/adb/modules}" "${MODULES_UPDATE_DIR:-/data/adb/modules_update}"; do
    for module in "$root"/*; do
      [ -d "$module" ] || continue
      [ "${module##*/}" = "$MODID" ] && continue
      [ -f "$module/disable" ] && continue
      [ -f "$module/remove" ] && continue

      if [ -f "$module/system/vendor/lib/egl/libGLES_mali.so" ] || \
         [ -f "$module/system/vendor/lib64/egl/libGLES_mali.so" ] || \
         [ -f "$module/system/vendor/lib/hw/vulkan.mali.so" ] || \
         [ -f "$module/system/vendor/lib64/hw/vulkan.mali.so" ]; then
        abort "Conflicting GPU driver module detected: ${module##*/}. Disable or remove it before installing."
      fi
    done
  done
}

for library in \
  system/vendor/lib/egl/libGLES_mali.so \
  system/vendor/lib64/egl/libGLES_mali.so; do
  [ -f "$MODPATH/$library" ] || abort "Missing required Mali library: $library"
done

check_conflicting_modules

ui_print " "
ui_print " Exynos 2100 Mali-G78 driver: $MODVER"
ui_print " Device: ${SOC:-${PLATFORM:-$BOARD}}"
ui_print " "

# Assign the vendor baseline label first, then specific labels to libraries
# and permission XML files. Do not indiscriminately label all vendor files as HALs.
set_perm_recursive "$MODPATH/system/vendor" 0 0 0755 0644 u:object_r:vendor_file:s0 || \
  abort "Unable to set vendor module permissions"

for library in \
  system/vendor/lib/egl/libGLES_mali.so \
  system/vendor/lib64/egl/libGLES_mali.so \
  system/vendor/lib/hw/vulkan.mali.so \
  system/vendor/lib64/hw/vulkan.mali.so; do
  [ -f "$MODPATH/$library" ] || continue
  set_perm "$MODPATH/$library" 0 0 0644 u:object_r:same_process_hal_file:s0 || \
    abort "Unable to set permissions on $library"
done

for xml in "$MODPATH"/system/vendor/etc/permissions/*.xml; do
  [ -f "$xml" ] || continue
  set_perm "$xml" 0 0 0644 u:object_r:vendor_configs_file:s0 || \
    abort "Unable to set permissions on ${xml##*/}"
done

# Android regenerates shader caches when necessary. Never delete arbitrary
# files under /data during module installation.
ui_print " Mali libraries installed; user data and shader caches left untouched."
ui_print " Please reboot."
ui_print " "
