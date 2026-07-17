# ocaml-hipjit: bindings to AMD HIP and hiprtc

OCaml bindings for AMD's HIP API: the GPU runtime (`amdhip64`) and the runtime compiler
(`hiprtc`). The package `hipjit` mirrors the API of
[ocaml-cudajit](https://github.com/lukstafi/ocaml-cudajit) (package `cudajit`), so code written
against `Cuda` / `Nvrtc` ports nearly 1:1 to `Hip` / `Hiprtc`.

The bindings cover devices, (primary) contexts, streams, events and delimited events, device
memory with sync/async copies and memsets, module loading, kernel launches, and runtime
compilation of HIP C++ to GPU code objects.

## Structure

- `hipjit.hiprtc` (module `Hiprtc`): runtime compilation, analogous to cudajit's `Nvrtc`. One
  difference: hiprtc produces a binary code object rather than textual PTX, hence
  `compile_to_code` instead of `compile_to_ptx`.
- `hipjit.hip` (module `Hip`): the runtime/driver functionality, analogous to cudajit's `Cuda`.
  Differences: device pointers are `void*` on AMD (still with byte-offset arithmetic), peer copies
  take devices instead of contexts, contexts are deprecated in HIP (prefer
  `Hip.Device.set_current`, though `Hip.Context.get_primary` etc. work), and events lack CUDA's
  "external" flags.
- `hipjit.hip_ffi`, `hipjit.hiprtc_ffi`: the low-level ctypes bindings (dune `ctypes` stanza with
  build-time stub generation).

## Installation

Requirements:

- **Linux**: install [ROCm](https://rocm.docs.amd.com/) (or at least the HIP runtime and hiprtc);
  set `HIP_PATH` if the installation prefix differs from `/opt/rocm`.
- **Windows**: install the [AMD HIP SDK](https://www.amd.com/en/developer/resources/rocm-hub/hip-sdk.html).
  The installer sets the `HIP_PATH` environment variable. At run time, executables need
  `%HIP_PATH%\bin` on `PATH` so that the hiprtc DLLs are found (the HIP runtime itself is loaded
  from the AMD driver in `System32`).

SDK discovery is delegated to the `conf-hip` opam package (and its helper `conf-hip-config`), a
dependency of `hipjit`. It resolves the SDK prefix (`HIP_PATH`, then — on Windows — the registry
and a scan of `C:\Program Files\AMD\ROCm`), exports `HIP_PATH`, and prepends the SDK's `bin`
directory to `PATH` through opam's environment. On Windows it exposes the SDK through a space-free
NTFS junction `%LOCALAPPDATA%\hip_path_link` (clang's `-I` rejects spaces, and the SDK installs
under `C:\Program Files`).

> **Note.** `conf-hip` and `conf-hip-config` are not in the opam repository yet, so they must be
> pinned before installing or building `hipjit`:
>
> ```sh
> opam pin add conf-hip-config.1 <opam-repository>/packages/conf-hip-config/conf-hip-config.1
> opam pin add conf-hip.1 <opam-repository>/packages/conf-hip/conf-hip.1
> ```
>
> Without these pins the solver cannot satisfy `hipjit`'s `conf-hip` dependency. They will be
> submitted to the opam repository before `hipjit` is released there.

Then: `opam install hipjit`. Load the opam environment (`eval $(opam env)`, or its PowerShell
equivalent) so that `HIP_PATH`/`PATH` are set before building from a clone (`dune build && dune test`).

Tests that require a GPU are skipped when the environment variable `HIPJIT_NO_GPU=true`;
`test_no_device` only needs the hiprtc library, not a GPU.

## Example

See `test/saxpy.ml` for an end-to-end example: compile a kernel with `Hiprtc.compile_to_code`,
load it with `Hip.Module.load_data_ex`, copy data with `Hip.Stream.memcpy_H_to_D`, launch with
`Hip.Stream.launch_kernel`, synchronize with `Hip.Delimited_event` / `Hip.Stream.synchronize`.
`bin/properties.ml` dumps all devices' attributes.
