#!/usr/bin/env bash
# Read-only ELF/ABI inventory of known-working Mali userspace libraries.
set -euo pipefail

ROOT=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT"
for cmd in readelf sha256sum awk sed sort grep; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "Missing command: $cmd" >&2; exit 2; }
done

failures=0

inspect() {
  local path=$1 expected_class=$2 expected_machine=$3
  local header class machine kind digest needed stack relro textrel exports
  printf '### `%s`\n\n' "$path"
  if [[ ! -f "$path" ]]; then
    echo '**ERROR:** missing ELF file'
    echo
    failures=$((failures + 1))
    return
  fi
  if ! header=$(readelf -hW "$path" 2>&1); then
    echo '**ERROR:** not a valid ELF file'
    echo
    failures=$((failures + 1))
    return
  fi
  class=$(awk '/^[[:space:]]*Class:/ {print $2;exit}' <<< "$header")
  machine=$(sed -n 's/^[[:space:]]*Machine:[[:space:]]*//p' <<< "$header" | head -n 1)
  kind=$(awk '/^[[:space:]]*Type:/ {print $2;exit}' <<< "$header")
  digest=$(sha256sum "$path" | awk '{print $1}')
  printf -- '- ELF: `%s`, `%s`, type `%s`\n' "$class" "$machine" "$kind"
  printf -- '- SHA-256: `%s`\n' "$digest"
  if [[ "$class" != "$expected_class" || "$machine" != "$expected_machine" || "$kind" != 'DYN' ]]; then
    printf '**ERROR:** expected %s / %s / DYN\n' "$expected_class" "$expected_machine"
    failures=$((failures + 1))
  fi
  needed=$(readelf -dW "$path" | sed -n 's/.*(NEEDED).*Shared library: \[\([^]]*\)\].*/\1/p' | awk 'BEGIN {s=""} {s=s (NR>1 ? ", " : "") $0} END {print s}')
  printf -- '- DT_NEEDED: %s\n' "${needed:-none}"
  if readelf -lW "$path" | grep -q 'GNU_RELRO'; then relro=yes; else relro=no; fi
  stack=$(readelf -lW "$path" | grep 'GNU_STACK' || true)
  if [[ -z "$stack" ]]; then
    stack_status='not declared'
  elif [[ "$stack" =~ [[:space:]]RWE[[:space:]] ]]; then
    stack_status='executable (review needed)'
  else
    stack_status='non-executable'
  fi
  if readelf -dW "$path" | grep -Eq '\(TEXTREL\)|TEXTREL'; then textrel='present (review needed)'; else textrel='not reported'; fi
  printf -- '- GNU_RELRO: %s; GNU_STACK: %s; TEXTREL: %s\n' "$relro" "$stack_status" "$textrel"
  exports=$(readelf --dyn-syms -W "$path" | awk '
    $5 ~ /^(GLOBAL|WEAK)$/ && $7 != "UND" && $8 ~ /^(eglGetProcAddress|eglInitialize|glGetString|glCompileShader|vkGetInstanceProcAddr|vk_icdGetInstanceProcAddr|vkNegotiateLoaderICDInterfaceVersion)(@.*)?$/ { print $8 }' | sort -u | awk 'BEGIN {s=""} {s=s (NR>1 ? ", " : "") $0} END {print s}')
  printf -- '- Selected exported entrypoints: %s\n\n' "${exports:-none from sample list}"
}

printf '# Mali r38p1 ELF/ABI inventory\n\n'
printf '> Static analysis of repository artifacts. No runtime/conformance claims.\n\n'
inspect 'system/vendor/lib/egl/libGLES_mali.so' ELF32 ARM
inspect 'system/vendor/lib64/egl/libGLES_mali.so' ELF64 AArch64
# Vulkan loader stubs are inspected only as linkage context, never modified.
inspect 'system/vendor/lib/hw/vulkan.mali.so' ELF32 ARM
inspect 'system/vendor/lib64/hw/vulkan.mali.so' ELF64 AArch64

if [[ $failures -gt 0 ]]; then
  printf '**Audit failed:** %d file(s) missing or with mismatched ELF headers.\n' "$failures"
  exit 1
fi
printf '**Audit complete:** ELF architectures and shared-object types match installation paths.\n