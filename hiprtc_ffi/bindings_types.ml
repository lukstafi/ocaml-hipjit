open Ctypes

type hiprtc_program_t
type hiprtc_program = hiprtc_program_t structure ptr

let hiprtc_program : hiprtc_program typ = ptr (structure "_hiprtcProgram")

type hiprtc_result =
  | HIPRTC_SUCCESS
  | HIPRTC_ERROR_OUT_OF_MEMORY
  | HIPRTC_ERROR_PROGRAM_CREATION_FAILURE
  | HIPRTC_ERROR_INVALID_INPUT
  | HIPRTC_ERROR_INVALID_PROGRAM
  | HIPRTC_ERROR_INVALID_OPTION
  | HIPRTC_ERROR_COMPILATION
  | HIPRTC_ERROR_BUILTIN_OPERATION_FAILURE
  | HIPRTC_ERROR_NO_NAME_EXPRESSIONS_AFTER_COMPILATION
  | HIPRTC_ERROR_NO_LOWERED_NAMES_BEFORE_COMPILATION
  | HIPRTC_ERROR_NAME_EXPRESSION_NOT_VALID
  | HIPRTC_ERROR_INTERNAL_ERROR
  | HIPRTC_ERROR_LINKING
  | HIPRTC_ERROR_UNCATEGORIZED of int64

let sexp_of_hiprtc_result = function
  | HIPRTC_SUCCESS -> Sexplib0.Sexp.Atom "HIPRTC_SUCCESS"
  | HIPRTC_ERROR_OUT_OF_MEMORY -> Sexplib0.Sexp.Atom "HIPRTC_ERROR_OUT_OF_MEMORY"
  | HIPRTC_ERROR_PROGRAM_CREATION_FAILURE ->
      Sexplib0.Sexp.Atom "HIPRTC_ERROR_PROGRAM_CREATION_FAILURE"
  | HIPRTC_ERROR_INVALID_INPUT -> Sexplib0.Sexp.Atom "HIPRTC_ERROR_INVALID_INPUT"
  | HIPRTC_ERROR_INVALID_PROGRAM -> Sexplib0.Sexp.Atom "HIPRTC_ERROR_INVALID_PROGRAM"
  | HIPRTC_ERROR_INVALID_OPTION -> Sexplib0.Sexp.Atom "HIPRTC_ERROR_INVALID_OPTION"
  | HIPRTC_ERROR_COMPILATION -> Sexplib0.Sexp.Atom "HIPRTC_ERROR_COMPILATION"
  | HIPRTC_ERROR_BUILTIN_OPERATION_FAILURE ->
      Sexplib0.Sexp.Atom "HIPRTC_ERROR_BUILTIN_OPERATION_FAILURE"
  | HIPRTC_ERROR_NO_NAME_EXPRESSIONS_AFTER_COMPILATION ->
      Sexplib0.Sexp.Atom "HIPRTC_ERROR_NO_NAME_EXPRESSIONS_AFTER_COMPILATION"
  | HIPRTC_ERROR_NO_LOWERED_NAMES_BEFORE_COMPILATION ->
      Sexplib0.Sexp.Atom "HIPRTC_ERROR_NO_LOWERED_NAMES_BEFORE_COMPILATION"
  | HIPRTC_ERROR_NAME_EXPRESSION_NOT_VALID ->
      Sexplib0.Sexp.Atom "HIPRTC_ERROR_NAME_EXPRESSION_NOT_VALID"
  | HIPRTC_ERROR_INTERNAL_ERROR -> Sexplib0.Sexp.Atom "HIPRTC_ERROR_INTERNAL_ERROR"
  | HIPRTC_ERROR_LINKING -> Sexplib0.Sexp.Atom "HIPRTC_ERROR_LINKING"
  | HIPRTC_ERROR_UNCATEGORIZED i64 ->
      Sexplib0.Sexp.List
        [ Sexplib0.Sexp.Atom "HIPRTC_ERROR_UNCATEGORIZED"; Sexplib0.Sexp.Atom (Int64.to_string i64) ]

module Types (T : Ctypes.TYPE) = struct
  let hiprtc_success = T.constant "HIPRTC_SUCCESS" T.int64_t
  let hiprtc_error_out_of_memory = T.constant "HIPRTC_ERROR_OUT_OF_MEMORY" T.int64_t

  let hiprtc_error_program_creation_failure =
    T.constant "HIPRTC_ERROR_PROGRAM_CREATION_FAILURE" T.int64_t

  let hiprtc_error_invalid_input = T.constant "HIPRTC_ERROR_INVALID_INPUT" T.int64_t
  let hiprtc_error_invalid_program = T.constant "HIPRTC_ERROR_INVALID_PROGRAM" T.int64_t
  let hiprtc_error_invalid_option = T.constant "HIPRTC_ERROR_INVALID_OPTION" T.int64_t
  let hiprtc_error_compilation = T.constant "HIPRTC_ERROR_COMPILATION" T.int64_t

  let hiprtc_error_builtin_operation_failure =
    T.constant "HIPRTC_ERROR_BUILTIN_OPERATION_FAILURE" T.int64_t

  let hiprtc_error_no_name_expressions_after_compilation =
    T.constant "HIPRTC_ERROR_NO_NAME_EXPRESSIONS_AFTER_COMPILATION" T.int64_t

  let hiprtc_error_no_lowered_names_before_compilation =
    T.constant "HIPRTC_ERROR_NO_LOWERED_NAMES_BEFORE_COMPILATION" T.int64_t

  let hiprtc_error_name_expression_not_valid =
    T.constant "HIPRTC_ERROR_NAME_EXPRESSION_NOT_VALID" T.int64_t

  let hiprtc_error_internal_error = T.constant "HIPRTC_ERROR_INTERNAL_ERROR" T.int64_t
  let hiprtc_error_linking = T.constant "HIPRTC_ERROR_LINKING" T.int64_t

  let hiprtc_result =
    T.enum ~typedef:true
      ~unexpected:(fun error_code -> HIPRTC_ERROR_UNCATEGORIZED error_code)
      "hiprtcResult"
      [
        (HIPRTC_SUCCESS, hiprtc_success);
        (HIPRTC_ERROR_OUT_OF_MEMORY, hiprtc_error_out_of_memory);
        (HIPRTC_ERROR_PROGRAM_CREATION_FAILURE, hiprtc_error_program_creation_failure);
        (HIPRTC_ERROR_INVALID_INPUT, hiprtc_error_invalid_input);
        (HIPRTC_ERROR_INVALID_PROGRAM, hiprtc_error_invalid_program);
        (HIPRTC_ERROR_INVALID_OPTION, hiprtc_error_invalid_option);
        (HIPRTC_ERROR_COMPILATION, hiprtc_error_compilation);
        (HIPRTC_ERROR_BUILTIN_OPERATION_FAILURE, hiprtc_error_builtin_operation_failure);
        ( HIPRTC_ERROR_NO_NAME_EXPRESSIONS_AFTER_COMPILATION,
          hiprtc_error_no_name_expressions_after_compilation );
        ( HIPRTC_ERROR_NO_LOWERED_NAMES_BEFORE_COMPILATION,
          hiprtc_error_no_lowered_names_before_compilation );
        (HIPRTC_ERROR_NAME_EXPRESSION_NOT_VALID, hiprtc_error_name_expression_not_valid);
        (HIPRTC_ERROR_INTERNAL_ERROR, hiprtc_error_internal_error);
        (HIPRTC_ERROR_LINKING, hiprtc_error_linking);
      ]
end
