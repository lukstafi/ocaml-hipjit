let kernel =
  {|
extern "C" __global__ void saxpy(float a, float *x, float *y, float *out, size_t n) {
  size_t tid = blockIdx.x * blockDim.x + threadIdx.x;
  if (tid < n) {
    out[tid] = a * x[tid] + y[tid];
  }
}
|}

let () =
  let major, minor = Hiprtc.version () in
  assert (major >= 6 || (major = 0 && minor >= 0));
  Printf.printf "hiprtc version retrieved: %b\n%!" (major > 0);
  let code =
    Hiprtc.compile_to_code ~hip_src:kernel ~name:"saxpy.hip" ~options:[ "-ffast-math" ]
      ~with_debug:true
  in
  let binary = Hiprtc.string_from_code code in
  Printf.printf "compiled code object: non-empty %b\n%!" (String.length binary > 0);
  (* Code objects are ELF files ("\x7fELF") on all HIP platforms. *)
  Printf.printf "code object is ELF: %b\n%!" (String.length binary > 4 && String.sub binary 1 3 = "ELF");
  (match Hiprtc.compilation_log code with
  | None -> Printf.printf "compilation log: none\n%!"
  | Some _ -> Printf.printf "compilation log: present\n%!");
  (* Check that compilation errors are reported as exceptions. *)
  (try
     ignore
     @@ Hiprtc.compile_to_code ~hip_src:"__global__ void bad() { syntax error; }" ~name:"bad.hip"
          ~options:[] ~with_debug:false
   with Hiprtc.Hiprtc_error { status; message = _ } ->
     Printf.printf "compilation error reported: %s\n%!"
       (Sexplib0.Sexp.to_string_hum @@ Hiprtc.sexp_of_result status));
  Printf.printf "OK\n%!"
