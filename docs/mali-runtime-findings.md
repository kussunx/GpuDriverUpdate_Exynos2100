# Remaining driver constraints — Exynos 2100 Mali r38p1

## Evidence from the proprietary `libGLES_mali.so` binaries

Both the 32-bit ARM and 64-bit AArch64 libraries include the build
marker `r38p1-01bet0` and a Mali-G78 string. Their dynamically linked
dependencies include `libnativewindow.so`, `libion_exynos.so`, and
`android.hardware.graphics.mapper@4.0.so`. The included Vulkan loader
stubs link against those same proprietary Mali libraries.

Both variants also embed `EGL_ANDROID_blob_cache`, explaining why
the standard Android EGL multifile caching property is a plausible
noninvasive optimisation. This does **not** prove an FPS increase.

The binaries include `GLES_DISABLE_SURFACE_AFBC`,
`GLES_DISABLE_TEXTURE_AFBC`, `GLES_DELAY_AFBC_DECOMPRESSION`,
and `GLES_AFBC_UPLOAD_HEURISTIC`. These are **identifiers in machine
code**, not documented user-facing tuning switches. We have not verified
how they are read, whether they are enabled by default, or which
graphics workloads they affect; they must not be forced blindly.

The string `1.4 Valhall` is part of a Mali vendor/build identifier,
**not evidence of Vulkan API 1.4 support**. The package retains
its Vulkan 1.3 declaration; runtime Vulkan 1.3 support and conformance
cannot be established from `strings` or feature XML.

## What is still unresolved

1. Runtime KMD/UMD version negotiation and kernel-side Mali UAPI
   compatibility on the exact target ROM/kernel.
2. The possible Instagram/TikTok flickering regression: no confirmed
   reproduction, GPU/decoder logs or trace proving whether AFBC,
   MediaCodec, HWC, fences, or page-flipping is responsible.
3. Any real compiler, frame pacing, AFBC or scheduling enhancement
   inside proprietary Mali r38p1 would require a specific reproducible
   bug, reverse-engineering of its call path, a measurable verification
   case and safe rollback.

Use `tools/check-device-compat.sh` to gather a minimal,
read-only compatibility snapshot on the S21. Do not edit proprietary
`.so` instructions without a defensible patch and hardware evidence.

## Regression guard

`bash tools/check-mali-runtime-abi.sh` validates the known-working
binary hashes, expected vendor UMD markers, three important shared
library dependencies and EGL cache support. It reports AFBC identifiers
without changing or activating them.
