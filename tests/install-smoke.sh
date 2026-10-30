#!/bin/sh
# Standalone smoke checks for customize.sh; no Android device required.
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT HUP INT TERM

mkdir -p "$TMP/module/system/vendor/lib/egl" \
         "$TMP/module/system/vendor/lib64/egl" \
         "$TMP/module/system/vendor/lib64/hw" \
         "$TMP/module/system/vendor/etc/permissions" \
         "$TMP/modules" "$TMP/modules_update"
cp "$REPO_DIR/module.prop" "$TMP/module/module.prop"
grep -Eq '^versionCode=[0-9]+$' "$REPO_DIR/module.prop"
: > "$TMP/module/system/vendor/lib/egl/libGLES_mali.so"
: > "$TMP/module/system/vendor/lib64/egl/libGLES_mali.so"
: > "$TMP/module/system/vendor/lib64/hw/vulkan.mali.so"
: > "$TMP/module/system/vendor/etc/permissions/test.xml"

run_install() {
  TEST_SOC=$1
  TEST_PLATFORM=$2
  TEST_BOARD=$3
  export TEST_SOC TEST_PLATFORM TEST_BOARD
  (
    MODPATH="$TMP/module"
    MODULES_DIR="$TMP/modules"
    MODULES_UPDATE_DIR="$TMP/modules_update"
    export MODPATH MODULES_DIR MODULES_UPDATE_DIR
    getprop() {
      case "$1" in
        ro.soc.model) printf '%s' "$TEST_SOC" ;;
        ro.board.platform) printf '%s' "$TEST_PLATFORM" ;;
        ro.product.board) printf '%s' "$TEST_BOARD" ;;
        ro.hardware) printf '%s' '' ;;
      esac
    }
    grep_prop() { sed -n "s/^$1=//p" "$2" | head -n 1; }
    ui_print() { :; }
    abort() { printf 'ABORT: %s\n' "$1" >&2; exit 8; }
    set_perm_recursive() { printf 'DIR %s %s\n' "$1" "$6" >> "$TMP/perms"; }
    set_perm() { printf 'FILE %s %s\n' "$1" "$5" >> "$TMP/perms"; }
    . "$REPO_DIR/customize.sh"
  )
}

run_install 'Exynos 2100' '' ''
grep -q 'vendor_configs_file:s0' "$TMP/perms"
grep -q 'same_process_hal_file:s0' "$TMP/perms"
grep -q 'vendor_file:s0' "$TMP/perms"
run_install '' 'universal2100' ''
run_install '' '' 'o1s'

if run_install 'Snapdragon 888' 'lahaina' 'o1q' 2> "$TMP/error"; then
  echo 'ERROR: accepted unsupported hardware' >&2
  exit 1
fi
grep -q 'Unsupported device' "$TMP/error"

mkdir -p "$TMP/modules/another_gpu/system/vendor/lib64/egl"
: > "$TMP/modules/another_gpu/system/vendor/lib64/egl/libGLES_mali.so"
if run_install 'Exynos 2100' '' '' 2> "$TMP/error"; then
  echo 'ERROR: accepted overlapping GPU driver module' >&2
  exit 1
fi
grep -q 'Conflicting GPU driver' "$TMP/error"
: > "$TMP/modules/another_gpu/disable"
run_install 'Exynos 2100' '' ''

rm "$TMP/module/system/vendor/lib/egl/libGLES_mali.so"
if run_install 'Exynos 2100' '' '' 2> "$TMP/error"; then
  echo 'ERROR: accepted incomplete module' >&2
  exit 1
fi
grep -q 'Missing required Mali library' "$TMP/error"

printf 'Installer smoke tests passed.\n'
