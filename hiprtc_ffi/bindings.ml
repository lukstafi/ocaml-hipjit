open Ctypes
open Bindings_types

module Functions (F : Ctypes.FOREIGN) = struct
  module E = Types_generated

  let hiprtc_version = F.foreign "hiprtcVersion" F.(ptr int @-> ptr int @-> returning E.hiprtc_result)

  let hiprtc_get_error_string =
    F.foreign "hiprtcGetErrorString" F.(E.hiprtc_result @-> returning string)

  let hiprtc_create_program =
    F.foreign "hiprtcCreateProgram"
      F.(
        ptr hiprtc_program @-> string @-> string @-> int @-> ptr string @-> ptr string
        @-> returning E.hiprtc_result)

  let hiprtc_destroy_program =
    F.foreign "hiprtcDestroyProgram" F.(ptr hiprtc_program @-> returning E.hiprtc_result)

  let hiprtc_compile_program =
    F.foreign "hiprtcCompileProgram"
      F.(hiprtc_program @-> int @-> ptr (ptr char) @-> returning E.hiprtc_result)

  let hiprtc_get_code_size =
    F.foreign "hiprtcGetCodeSize" F.(hiprtc_program @-> ptr size_t @-> returning E.hiprtc_result)

  let hiprtc_get_code =
    F.foreign "hiprtcGetCode" F.(hiprtc_program @-> ptr char @-> returning E.hiprtc_result)

  let hiprtc_get_bitcode_size =
    F.foreign "hiprtcGetBitcodeSize" F.(hiprtc_program @-> ptr size_t @-> returning E.hiprtc_result)

  let hiprtc_get_bitcode =
    F.foreign "hiprtcGetBitcode" F.(hiprtc_program @-> ptr char @-> returning E.hiprtc_result)

  let hiprtc_get_program_log_size =
    F.foreign "hiprtcGetProgramLogSize"
      F.(hiprtc_program @-> ptr size_t @-> returning E.hiprtc_result)

  let hiprtc_get_program_log =
    F.foreign "hiprtcGetProgramLog" F.(hiprtc_program @-> ptr char @-> returning E.hiprtc_result)

  let hiprtc_add_name_expression =
    F.foreign "hiprtcAddNameExpression" F.(hiprtc_program @-> string @-> returning E.hiprtc_result)

  let hiprtc_get_lowered_name =
    F.foreign "hiprtcGetLoweredName"
      F.(hiprtc_program @-> string @-> ptr string @-> returning E.hiprtc_result)
end
