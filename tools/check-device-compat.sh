#!/system/bin/sh
# Read-only device diagnostic, no root required.
echo '=== Mali/Exynos/Vulkan compatibility ==='
for key in ro.soc.model ro.board.platform ro.product.board \
  ro.egl.blobcache.multifile debug.egl.blobcache.multifile; do
  val=$(getprop "$key")
  printf '%s=%s\n' "$key" "${val:-unset}"
done
echo '[Android Vulkan feature declarations]'
features=$(pm list features 2>/dev/null)
printf '%s\n' "$features" | grep -E 'android\.(hardware\.vulkan|software\.vulkan)' || :
value=$(printf '%s\n' "$features" | sed -n 's/^feature:android\.hardware\.vulkan\.version=//p' | head -1)
case "$value" in
  ''|*[!0-9]*) echo 'Vulkan version feature absent' ;;
  *) printf 'Advertised Vulkan: %s.%s.%s\n' "$(( (value >> 22) & 127 ))" "$(( (value >> 12) & 1023 ))" "$((value & 4095))" ;;
esac
for file in /sys/module/mali_kbase/version /sys/module/mali_kbase_r38p1/version; do
  if [ -r "$file" ]; then printf '%s: ' "$file"; cat "$file"; fi
done
echo 'Feature flags do not prove Vulkan 1.3 runtime conformance or GPU performance.'
