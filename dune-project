(lang dune 3.16)

(using ctypes 0.3)

(name hipjit)

(version 0.1.0)

(generate_opam_files true)

(source
 (github lukstafi/ocaml-hipjit))

(authors "Lukasz Stafiniak")

(maintainers "Lukasz Stafiniak <lukstafi@gmail.com>")

(license MIT)

(documentation
 https://github.com/lukstafi/ocaml-hipjit/blob/master/README.md)

(package
 (name hipjit)
 (synopsis
  "Bindings to the AMD HIP runtime and the `hiprtc` library with a unified interface")
 (description
  "Bindings to manually selected parts of `libamdhip64` and `libhiprtc`, with a few types and conversion functions to facilitate use. Mirrors the API of the `cudajit` package.")
 (depends
  (ocaml
   (>= 4.13))
  dune
  (ctypes
   (>= 0.14.0))
  ctypes-foreign
  sexplib0
  conf-hip
  (odoc :with-doc))
 (tags
  (hip rocm jit hiprtc gpu amd)))
