# Packaging and device checks

`tools/build-module.sh` produces an installable Magisk-compatible ZIP.
The archive contains the known-good Mali/GLES and Vulkan 1.3 files, the module
installer, `system.prop`, and its existing metadata. It is validated against
the fixed SHA-256 baseline before packaging. The GitHub Actions run publishes
a download artifact containing the flashable ZIP plus checksum. The outer
GitHub Actions artifact ZIP is **not** itself the module to install.

To build locally on Linux: `bash tools/build-module.sh dist`.

A read-only check can be run on the S21 via:
```sh
adb push tools/check-device-compat.sh /data/local/tmp/
adb shell sh /data/local/tmp/check-device-compat.sh
```

It prints advertised Vulkan API version, Mali module version if exposed,
and EGL cache status. It cannot prove Vulkan 1.3 runtime support: device-side
Vulkan queries and CTS/dEQP are required. No driver binaries are modified.
