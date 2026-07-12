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
  The installer sets the `HIP_PATH` environment variable (the build also falls back to the
  registry and to scanning `C:\Program Files\AMD\ROCm`). At run time, executables need
  `%HIP_PATH%\bin` on `PATH` so that the hiprtc DLLs are found (the HIP runtime itself is loaded
  from the AMD driver in `System32`). Since the SDK installs under `C:\Program Files`, the build
  creates an NTFS junction `%LOCALAPPDATA%\hip_path_link` to avoid spaces in paths.

Then: `opam install hipjit` (or from a clone: `dune build && dune test`).

Tests that require a GPU are skipped when the environment variable `HIPJIT_NO_GPU=true`;
`test_no_device` only needs the hiprtc library, not a GPU.

## Example

See `test/saxpy.ml` for an end-to-end example: compile a kernel with `Hiprtc.compile_to_code`,
load it with `Hip.Module.load_data_ex`, copy data with `Hip.Stream.memcpy_H_to_D`, launch with
`Hip.Stream.launch_kernel`, synchronize with `Hip.Delimited_event` / `Hip.Stream.synchronize`.
`bin/properties.ml` dumps all devices' attributes.
