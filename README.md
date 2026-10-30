# Exynos 2100 Mali-G78 r38p1 driver module

This repository packages working **32-bit and 64-bit proprietary Mali r38p1 userspace libraries** for Exynos 2100 devices as a Magisk-compatible module. The underlying GPU libraries have **not** been patched or rebuilt.

This is an independent maintenance fork of [EliteUI/elitetest1's Exynos 2100 GPU Driver Update](https://github.com/elitetest1/GpuDriverUpdate_Exynos2100). Credits for the original port and module go to **EliteUI/elitetest1**, with thanks to **@daubfy** for testing.

## What this maintenance revision changes

- Valid numeric `versionCode` and revised installer metadata (the Mali r38p1 driver binaries are unchanged).
- Exynos 2100 hardware check, with known Exynos 2100 board-name fallbacks.
- Conflict detection for active modules that replace the same graphics libraries.
- Vendor file permissions and SELinux labels applied by file type.
- No recursive deletion of arbitrary files named `*shader*` under `/data`. Android can regenerate caches on demand.
- Standalone installer smoke tests and Git blob checks for both Mali libraries.
- Keep the Vulkan 1.3 API feature while **not overriding** the ROM's dEQP conformance date with an unverified Android 13 claim.

**Not included:** Vulkan driver upgrades, changes to the contents of `libGLES_mali.so`, kernel changes, or a claim of higher GPU performance.


## OpenGL ES shader-cache optimization

The module enables Android's **multifile EGL shader/program blob cache** via the standard `ro.egl.blobcache.multifile=true` property (see `system.prop`). Both original Mali r38p1 libraries expose `EGL_ANDROID_blob_cache`. The Android EGL loader checks this property and switches from monolithic to multifile storage, allowing better retention of cached graphics program data between app launches.

The module **does not override** `ro.egl.blobcache.multifile_limit`; the ROM's existing limit or Android framework default remains authoritative. The feature affects Android/EGL caching, not the proprietary Mali compiler, kernel scheduling or the Vulkan API. Improved smoothness is plausible for shader-heavy apps, but no device-level FPS or latency benefit has been measured.

To opt out without changing the Mali binaries, set `debug.egl.blobcache.multifile=false` **before starting the app** (Android's EGL loader gives that debug setting precedence), or remove the `ro.egl.blobcache.multifile=true` line from the module and reboot. Test with Android builds that support multifile EGL caches.

References: [Android AOSP egl_cache.cpp](https://android.googlesource.com/platform/frameworks/native/+/master/opengl/libs/EGL/egl_cache.cpp) and [Google GS201 Mali configuration](https://android.googlesource.com/device/google/gs201/+/b4cd7bf61985a8fa4d2ba16cf434df10caece9a7/device.mk).

## Installation and compatibility

Install this module with a compatible Magisk-based module installer, then reboot. The installer rejects devices whose reported SoC/platform/board cannot be recognized as Exynos 2100, and rejects conflicts with other active modules replacing these graphics libraries. Back up your current setup and have a recovery path before installing experimental graphics modules.

For newer versions of KernelSU Next, the original project notes that [meta-mm](https://modules.kernelsu.org/module/meta-mm/) may be required. Installation on every root manager and firmware build has **not** been validated.

## Offline checks

Run from a Linux shell (no phone required):

```sh
sh -n customize.sh
sh tests/install-smoke.sh
sh tools/verify-mali-blobs.sh
```

`verify-mali-blobs.sh` requires Git and the full two-library checkout; it verifies the exact working baseline Git blob hashes. The tests validate installer logic and binary identity; they do **not** prove runtime stability or performance on a Galaxy S21.

## Binary origin and licensing

The upstream README describes the binaries as extracted from Vivo firmware, whereas its module metadata refers to Exynos 1080. Exact firmware provenance remains to be verified. The `LICENSE` and `NOTICE` files preserve upstream attribution, but **an Apache license for installation scripts does not automatically relicense proprietary Arm/Samsung/Vivo binary drivers**. Redistribution remains subject to the applicable third-party rights and terms.

Use at your own risk. No warranty is provided.
