open Hiprtc_ffi.Bindings_types
module Hiprtc_funs = Hiprtc_ffi.C.Functions

type result = hiprtc_result
(** See {{:https://rocm.docs.amd.com/projects/HIP/en/latest/reference/hiprtc.html} hiprtcResult}. *)

let sexp_of_result = sexp_of_hiprtc_result

exception Hiprtc_error of { status : result; message : string }

let error_printer = function
  | Hiprtc_error { status; message } ->
      ignore @@ Format.flush_str_formatter ();
      Format.fprintf Format.str_formatter "%s:@ %a" message Sexplib0.Sexp.pp_hum
        (sexp_of_result status);
      Some (Format.flush_str_formatter ())
  | _ -> None

let () = Printexc.register_printer error_printer
let is_success = function HIPRTC_SUCCESS -> true | _ -> false

let error_string status = Hiprtc_funs.hiprtc_get_error_string status

let version () =
  let open Ctypes in
  let major = allocate int 0 in
  let minor = allocate int 0 in
  let status = Hiprtc_funs.hiprtc_version major minor in
  if status <> HIPRTC_SUCCESS then
    raise @@ Hiprtc_error { status; message = "hiprtc_version" };
  (!@major, !@minor)

type compile_to_code_result = {
  log : string option;
  code : (char Ctypes.ptr[@sexp.opaque]);
  code_length : int;
}

let sexp_of_compile_to_code_result { log; code = _; code_length } =
  let log_sexp =
    match log with
    | None -> Sexplib0.Sexp.Atom "None"
    | Some s -> Sexplib0.Sexp.List [ Sexplib0.Sexp.Atom "Some"; Sexplib0.Sexp.Atom s ]
  in
  Sexplib0.Sexp.List
    [
      Sexplib0.Sexp.List [ Sexplib0.Sexp.Atom "log"; log_sexp ];
      Sexplib0.Sexp.List [ Sexplib0.Sexp.Atom "code"; Sexplib0.Sexp.Atom "<opaque>" ];
      Sexplib0.Sexp.List
        [ Sexplib0.Sexp.Atom "code_length"; Sexplib0.Sexp.Atom (Int.to_string code_length) ];
    ]

let compile_to_code ~hip_src ~name ~options ~with_debug =
  let open Ctypes in
  let prog = allocate_n hiprtc_program ~count:1 in
  (* Unlike NVRTC, hiprtc ships its own built-in HIP headers (hiprtc-builtins), so no include path
     needs to be prepended to the options. *)
  let options = Array.of_list options in
  let status =
    Hiprtc_funs.hiprtc_create_program prog hip_src name 0 (from_voidp string null)
      (from_voidp string null)
  in
  if status <> HIPRTC_SUCCESS then
    raise @@ Hiprtc_error { status; message = "hiprtc_create_program " ^ name };
  let num_options = Array.length options in
  let get_c_options options =
    (* Keep string arrays alive to prevent GC during the hiprtc call. *)
    let string_arrays = Array.map (fun v -> CArray.of_string v) options in
    let c_options = CArray.make (ptr char) num_options in
    Array.iteri (fun i arr -> CArray.start arr |> CArray.set c_options i) string_arrays;
    (c_options, string_arrays)
  in
  let c_options, string_arrays_keep_alive = get_c_options options in
  let status = Hiprtc_funs.hiprtc_compile_program !@prog num_options @@ CArray.start c_options in
  ignore (Sys.opaque_identity string_arrays_keep_alive);
  let log_msg log = Option.value log ~default:"no compilation log" in
  let error prefix status log =
    ignore @@ Hiprtc_funs.hiprtc_destroy_program prog;
    raise @@ Hiprtc_error { status; message = prefix ^ " " ^ name ^ ": " ^ log_msg log }
  in
  let log =
    if status = HIPRTC_SUCCESS && not with_debug then None
    else
      let log_size = allocate size_t Unsigned.Size_t.zero in
      let status = Hiprtc_funs.hiprtc_get_program_log_size !@prog log_size in
      if status <> HIPRTC_SUCCESS then None
      else
        let count = Unsigned.Size_t.to_int !@log_size in
        if count <= 1 then None
        else
          let log = allocate_n char ~count in
          let status = Hiprtc_funs.hiprtc_get_program_log !@prog log in
          if status = HIPRTC_SUCCESS then Some (string_from_ptr log ~length:(count - 1)) else None
  in
  if status <> HIPRTC_SUCCESS then error "hiprtc_compile_program" status log;
  let code_size = allocate size_t Unsigned.Size_t.zero in
  let status = Hiprtc_funs.hiprtc_get_code_size !@prog code_size in
  if status <> HIPRTC_SUCCESS then error "hiprtc_get_code_size" status log;
  let count = Unsigned.Size_t.to_int !@code_size in
  let code = allocate_n char ~count in
  let status = Hiprtc_funs.hiprtc_get_code !@prog code in
  if status <> HIPRTC_SUCCESS then error "hiprtc_get_code" status log;
  ignore @@ Hiprtc_funs.hiprtc_destroy_program prog;
  { log; code; code_length = count }

let string_from_code prog = Ctypes.string_from_ptr prog.code ~length:prog.code_length
let compilation_log prog = prog.log
