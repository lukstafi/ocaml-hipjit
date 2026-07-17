# ocaml-hipjit architecture notes

Bindings to AMD HIP (`amdhip64`) and hiprtc, deliberately mirroring
[ocaml-cudajit](https://github.com/lukstafi/ocaml-cudajit) so that code written against `cudajit`
(e.g. OCANNL's CUDA backend) ports nearly 1:1.

## Layout

- `hip_ffi/`, `hiprtc_ffi/`: low-level FFI via the dune `ctypes` stanza (build-time stub
  generation, no pkg-config). Each has `bindings_types.ml` (a `Types (T : Ctypes.TYPE)` functor:
  enums via `T.constant` + `T.enum` with an `*_UNCATEGORIZED of int64` catch-all, plus a partial
  binding of `hipDeviceProp_t`) and `bindings.ml` (a `Functions (F : Ctypes.FOREIGN)` functor).
  Consumers use `Hip_ffi.C.Functions` and `Hip_ffi.Types_generated`.
- `src/`: the public API. `Hiprtc` mirrors `Nvrtc` (difference: hiprtc emits a binary code object,
  so `compile_to_code`, and no include path needs to be prepended — hiprtc has built-in headers).
  `Hip` mirrors `Cuda`: same `check`/exception error model with `hip_call_hook`, `Gc.finalise`
  resource management, `freed` atomic-bool use-after-free guards, `Delimited_event` + per-stream
  `args_lifetimes`/`owned_events` bookkeeping.

## HIP vs CUDA differences encoded here

- `hipDeviceptr_t` is `void*` on AMD; the OCaml-side representation stays `Unsigned.uint64`
  (`memptr`) for offset arithmetic, converted at the FFI boundary
  (`voidp_of_memptr`/`memptr_of_voidp`).
- Device attributes come from one `hipGetDeviceProperties` call (partial struct binding) instead
  of many `cuDeviceGetAttribute` calls. `gcn_arch_name` (e.g. "gfx1151") is what hiprtc's
  `--offload-arch=` expects.
- Peer memcpy takes device ordinals, not contexts.
- `hipCtx*` APIs are deprecated on AMD (bound anyway; `-Wno-deprecated-declarations`);
  `Context.synchronize` uses `hipDeviceSynchronize`, `Context.set_limit` uses `hipDeviceSetLimit`.
- Events have no CUDA "external" flags; `release_stream` needs no context switching (HIP tracks
  the event's device internally).
- Most `hipModuleLoadDataEx` JIT options are ignored by the AMD runtime (kept for compatibility).

## SDK discovery (delegated to conf-hip)

SDK discovery lives in the `conf-hip` / `conf-hip-config` opam packages (mirroring `conf-cuda` /
`conf-cuda-config`), which `hipjit` depends on — not in this repo. They are not submitted to the
opam repository yet, so they must be pinned from an opam-repository checkout before `hipjit` can be
installed or built (see README); this must happen before `hipjit` is released. Their two-layer
split:

- `conf-hip-config` (discovery): resolves the SDK prefix and writes `conf-hip-config.config`
  exposing `%{conf-hip-config:hip_path}%`. On Unix from `HIP_PATH` (default `/opt/rocm`); on
  Windows a PowerShell `build:` resolves `HIP_PATH` from the environment, then the registry (HKLM
  Session Manager Environment), then the newest `C:\Program Files\AMD\ROCm\*`, and creates an NTFS
  junction `%LOCALAPPDATA%\hip_path_link` to dodge spaces in paths (ocaml/ocaml#13917) — `hip_path`
  is that junction (forward-slashed, usable by both clang `-I` and `PATH`).
- `conf-hip` (env + verify): compile-probes `hip/hip_runtime_api.h` + `hip/hiprtc.h`, then via
  `setenv` exports `HIP_PATH = %{conf-hip-config:hip_path}%` and prepends `%{...}%/bin` to `PATH`
  (the HIP-specific addition: AMD's Windows installer, unlike NVIDIA's, does not put the SDK bin on
  PATH, and the hiprtc DLLs live there).

So `HIP_PATH` (the junction) is present in the opam environment at both build and run time. The ffi
dune files read `%{env:HIP_PATH}/include|lib|lib64` for `-I`/`-L`; Windows links
`amdhip64.lib`/`hiprtc.lib`, Unix `-lamdhip64`/`-lhiprtc`. `-D__HIP_PLATFORM_AMD__` is required.
GCC >= 14 needs `-Wno-incompatible-pointer-types` (ctypes cannot express `const`). Building from a
clone requires the opam environment loaded (`eval $(opam env)`) so `HIP_PATH` is set.

## Testing

- `test_no_device/`: hiprtc-only golden test, no GPU needed.
- `test/`: GPU tests, skipped when `HIPJIT_NO_GPU=true`. On Windows the run rules prepend
  `<hip>/bin` to PATH (hiprtc DLLs live there; the HIP runtime itself loads from the driver's
  System32 copy) and pipe through `filter_output.exe` to drop the `HIP Library Path:` banner that
  `amdhip64_*.dll` prints to stdout on load.
- `dune test` requires the hiprtc DLLs to be locatable; the GPU saxpy test verifies compile →
  load → launch → copy-back end to end.
