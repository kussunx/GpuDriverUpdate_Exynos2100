# Mali-G78 r38p1 proprietary driver audit (Phase 2)

## Scope and baseline

The known-working 32-bit and 64-bit `libGLES_mali.so` binaries remain **unmodified**. The smaller `vulkan.mali.so` loader artifacts are inventoried strictly as ABI/dependency context, not upgraded. This phase does not alter GPU kernel drivers, Android graphics frameworks, Vulkan behavior, clocks, or proprietary binary instructions.

Baseline Git blob IDs on `master` (repository content identity, not SHA-256):

| File | Git blob SHA-1 |
| --- | --- |
| `system/vendor/lib/egl/libGLES_mali.so` | `7c995c0071165fa0b5646af1301ce3d8046be2b0` |
| `system/vendor/lib64/egl/libGLES_mali.so` | `4b136a06e09aa170883e958ceaa616de88638aef` |
| `system/vendor/lib/hw/vulkan.mali.so` | `39be104c134c9e73bd848e6cbfd672fcf77ff07e` |
| `system/vendor/lib64/hw/vulkan.mali.so` | `c048dee8f86150e5e08b4d2f2166b9d3fa80afe1` |

## Reproduce the static inventory

On Ubuntu or another Linux host with `binutils`, `bash`, `coreutils`, and the full repository checkout:

```sh
bash tools/audit-mali-elf.sh > mali-elf-report.md
```

The script checks ELF class, machine and `ET_DYN` for the two main Mali driver binaries and the loader stubs. It reports SHA-256, `DT_NEEDED` dependencies, `GNU_RELRO`/`GNU_STACK`/`TEXTREL` indicators and a small sample of exported graphics entrypoints. CI publishes the same report as a build artifact and step summary.

## How to interpret findings

- A missing or wrong-architecture binary is a **hard failure**.
- ABI dependency lists and exports identify what the loader expects, but a library name alone does not prove that a particular Android ROM supplies a compatible implementation.
- Missing RELRO or executable-stack flags are **review findings**, not automatic proof of exploitability.
- An ELF report cannot prove Android video playback correctness, cache coherency, DMA-fence integrity, GPU driver conformance, power/performance, or compatibility with every Mali kernel-mode driver revision.
- The module ships proprietary, precompiled vendor GPU code. Without source code or an independently reproducible upstream build, modifying internal instructions is unsafe and requires a narrowly specified defect, reverse-engineering evidence, and hardware validation.

## Subsequent investigation

1. Compare the 32-bit/64-bit `DT_NEEDED` sets and loader entrypoints against the target ROM's published vendor ABI; identify absent or mismatched dependencies.
2. Check kernel-mode (KMD) and user-mode (UMD) interface negotiation for the exact firmware in scope; do not assume that matching `r38p1` labels guarantees ABI compatibility.
3. Only propose a driver change after a reproducible defect and a verification procedure exist; otherwise preserve known-working blobs.

## Findings from the first successful CI run (2026-10-30)

- Both Mali driver libraries are correctly classified as 32-bit ARM / 64-bit AArch64 shared objects (ET_DYN). EGL/OpenGL ES entrypoints including `eglGetProcAddress`, `eglInitialize`, `glCompileShader`, and `glGetString` are exported in both variants.
- The observed security metadata includes GNU_RELRO and non-executable GNU_STACK; no dynamic TEXTREL marker was reported. This does **not** establish that the binaries have no exploitable vulnerabilities.
- Both `libGLES_mali.so` variants depend on `libnativewindow.so`, `libgralloctypes.so`, `libion_exynos.so`, `android.hardware.graphics.mapper@4.0.so`, and other Android libraries. These dependencies must be resolved in the target system's linker namespaces.
- The existing `vulkan.mali.so` files each declare `DT_NEEDED: libGLES_mali.so`. Even with Vulkan development explicitly out of scope, changing the shared Mali binary could indirectly affect Vulkan clients. **Do not** treat the APIs as completely independent libraries.
- The SHA-256 values collected from the successful runner are pinned in `tools/mali-r38p1-baseline.sha256` and checked in CI. Updating the binaries deliberately requires changing this manifest in a reviewed commit.
- No performance improvement, video-flicker fix, or Android runtime verification is claimed.

## Same-architecture loader ABI checks

The Vulkan loader stubs already ship in the baseline. Static auditing found the undefined `vkAcquireImageANDROID` symbol in both loader stubs. The auditor now verifies that each pre-existing stub's Vulkan-named undefined dynamic symbols are exported by the **matching-architecture** `libGLES_mali.so`. This does not modify, update or optimize Vulkan; it checks the direct dependency of artifacts already shipped together. A missing export is a static compatibility failure, not a proof of a video playback problem.

## Vulkan 1.3 and dEQP compatibility (Phase 3)

**What changed:** this module no longer overlays `android.software.vulkan.deqp.level.xml`, which asserted the date `2022-03-01` (Android 13 Vulkan dEQP tests) without any conformance evidence in this repository. Android interprets this value as a claim that **all** dEQP test cases up to that date pass; it does not describe the driver API version.

The separate `android.hardware.vulkan.version.xml` remains **unchanged** with API version `1.3.0` (decimal `4206592`). The existing proprietary `libGLES_mali.so` and `vulkan.mali.so` binaries, their ABI and behaviour remain unchanged.

On an Android 11+ ROM with a correctly defined stock dEQP feature flag, the ROM's own tested declaration can now remain effective instead of being replaced by this unverified Android 13 claim. This does **not** downgrade the actual Vulkan API implementation. It also does not prove this proprietary binary actually returns Vulkan 1.3 at runtime: **that still requires a physical-device query and CTS/dEQP validation** on the target device.

**Limitation:** on ROMs which lack a Vulkan dEQP feature flag entirely, removing this override cannot fill the gap. Test the ROM's stock feature declarations if considering support for such configurations. Do not copy a different phone's dEQP test date.

References:
- [Android Open Source Project: Implement Vulkan](https://source.android.com/docs/core/graphics/implement-vulkan)
- [Android 16 Compatibility Definition §7.1.4.2](https://source.android.com/docs/compatibility/16/android-16-cdd)

This is a genuine metadata/compatibility correction, **not an internal shader compiler, scheduling, FPS, battery, or flicker fix**.
