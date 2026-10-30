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
