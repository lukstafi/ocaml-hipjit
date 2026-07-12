open Ctypes

let str_atom s = Sexplib0.Sexp.Atom s

(* Opaque handle types, all pointers to incomplete structs on the AMD platform. *)

type hip_context_t
type hip_context = hip_context_t structure ptr

let hip_context : hip_context typ = typedef (ptr @@ structure "ihipCtx_t") "hipCtx_t"

type hip_module_t
type hip_module = hip_module_t structure ptr

let hip_module : hip_module typ = typedef (ptr @@ structure "ihipModule_t") "hipModule_t"

type hip_function_t
type hip_function = hip_function_t structure ptr

let hip_function : hip_function typ = typedef (ptr @@ structure "ihipModuleSymbol_t") "hipFunction_t"

type hip_stream_t
type hip_stream = hip_stream_t structure ptr

let hip_stream : hip_stream typ = typedef (ptr @@ structure "ihipStream_t") "hipStream_t"

type hip_event_t
type hip_event = hip_event_t structure ptr

let hip_event : hip_event typ = typedef (ptr @@ structure "ihipEvent_t") "hipEvent_t"

(* On the AMD platform [hipDeviceptr_t] is [void*] (unlike CUDA's integer [CUdeviceptr]). *)
let hip_deviceptr : unit ptr typ = typedef (ptr void) "hipDeviceptr_t"

type hip_device = Hip_device of int

let sexp_of_hip_device = function
  | Hip_device i -> Sexplib0.Sexp.List [ str_atom "Hip_device"; str_atom (Int.to_string i) ]

type hip_result =
  | HIP_SUCCESS
  | HIP_ERROR_INVALID_VALUE
  | HIP_ERROR_OUT_OF_MEMORY
  | HIP_ERROR_NOT_INITIALIZED
  | HIP_ERROR_DEINITIALIZED
  | HIP_ERROR_PROFILER_DISABLED
  | HIP_ERROR_PROFILER_NOT_INITIALIZED
  | HIP_ERROR_PROFILER_ALREADY_STARTED
  | HIP_ERROR_PROFILER_ALREADY_STOPPED
  | HIP_ERROR_INVALID_CONFIGURATION
  | HIP_ERROR_INVALID_PITCH_VALUE
  | HIP_ERROR_INVALID_SYMBOL
  | HIP_ERROR_INVALID_DEVICE_POINTER
  | HIP_ERROR_INVALID_MEMCPY_DIRECTION
  | HIP_ERROR_INSUFFICIENT_DRIVER
  | HIP_ERROR_MISSING_CONFIGURATION
  | HIP_ERROR_PRIOR_LAUNCH_FAILURE
  | HIP_ERROR_INVALID_DEVICE_FUNCTION
  | HIP_ERROR_NO_DEVICE
  | HIP_ERROR_INVALID_DEVICE
  | HIP_ERROR_INVALID_IMAGE
  | HIP_ERROR_INVALID_CONTEXT
  | HIP_ERROR_CONTEXT_ALREADY_CURRENT
  | HIP_ERROR_MAP_FAILED
  | HIP_ERROR_UNMAP_FAILED
  | HIP_ERROR_ARRAY_IS_MAPPED
  | HIP_ERROR_ALREADY_MAPPED
  | HIP_ERROR_NO_BINARY_FOR_GPU
  | HIP_ERROR_ALREADY_ACQUIRED
  | HIP_ERROR_NOT_MAPPED
  | HIP_ERROR_NOT_MAPPED_AS_ARRAY
  | HIP_ERROR_NOT_MAPPED_AS_POINTER
  | HIP_ERROR_ECC_NOT_CORRECTABLE
  | HIP_ERROR_UNSUPPORTED_LIMIT
  | HIP_ERROR_CONTEXT_ALREADY_IN_USE
  | HIP_ERROR_PEER_ACCESS_UNSUPPORTED
  | HIP_ERROR_INVALID_KERNEL_FILE
  | HIP_ERROR_INVALID_GRAPHICS_CONTEXT
  | HIP_ERROR_INVALID_SOURCE
  | HIP_ERROR_FILE_NOT_FOUND
  | HIP_ERROR_SHARED_OBJECT_SYMBOL_NOT_FOUND
  | HIP_ERROR_SHARED_OBJECT_INIT_FAILED
  | HIP_ERROR_OPERATING_SYSTEM
  | HIP_ERROR_INVALID_HANDLE
  | HIP_ERROR_ILLEGAL_STATE
  | HIP_ERROR_NOT_FOUND
  | HIP_ERROR_NOT_READY
  | HIP_ERROR_ILLEGAL_ADDRESS
  | HIP_ERROR_LAUNCH_OUT_OF_RESOURCES
  | HIP_ERROR_LAUNCH_TIMEOUT
  | HIP_ERROR_PEER_ACCESS_ALREADY_ENABLED
  | HIP_ERROR_PEER_ACCESS_NOT_ENABLED
  | HIP_ERROR_SET_ON_ACTIVE_PROCESS
  | HIP_ERROR_CONTEXT_IS_DESTROYED
  | HIP_ERROR_ASSERT
  | HIP_ERROR_HOST_MEMORY_ALREADY_REGISTERED
  | HIP_ERROR_HOST_MEMORY_NOT_REGISTERED
  | HIP_ERROR_LAUNCH_FAILURE
  | HIP_ERROR_COOPERATIVE_LAUNCH_TOO_LARGE
  | HIP_ERROR_NOT_SUPPORTED
  | HIP_ERROR_STREAM_CAPTURE_UNSUPPORTED
  | HIP_ERROR_STREAM_CAPTURE_INVALIDATED
  | HIP_ERROR_STREAM_CAPTURE_MERGE
  | HIP_ERROR_STREAM_CAPTURE_UNMATCHED
  | HIP_ERROR_STREAM_CAPTURE_UNJOINED
  | HIP_ERROR_STREAM_CAPTURE_ISOLATION
  | HIP_ERROR_STREAM_CAPTURE_IMPLICIT
  | HIP_ERROR_CAPTURED_EVENT
  | HIP_ERROR_STREAM_CAPTURE_WRONG_THREAD
  | HIP_ERROR_GRAPH_EXEC_UPDATE_FAILURE
  | HIP_ERROR_INVALID_CHANNEL_DESCRIPTOR
  | HIP_ERROR_INVALID_TEXTURE
  | HIP_ERROR_UNKNOWN
  | HIP_ERROR_RUNTIME_MEMORY
  | HIP_ERROR_RUNTIME_OTHER
  | HIP_ERROR_TBD
  | HIP_ERROR_UNCATEGORIZED of int64

let sexp_of_hip_result = function
  | HIP_SUCCESS -> str_atom "HIP_SUCCESS"
  | HIP_ERROR_INVALID_VALUE -> str_atom "HIP_ERROR_INVALID_VALUE"
  | HIP_ERROR_OUT_OF_MEMORY -> str_atom "HIP_ERROR_OUT_OF_MEMORY"
  | HIP_ERROR_NOT_INITIALIZED -> str_atom "HIP_ERROR_NOT_INITIALIZED"
  | HIP_ERROR_DEINITIALIZED -> str_atom "HIP_ERROR_DEINITIALIZED"
  | HIP_ERROR_PROFILER_DISABLED -> str_atom "HIP_ERROR_PROFILER_DISABLED"
  | HIP_ERROR_PROFILER_NOT_INITIALIZED -> str_atom "HIP_ERROR_PROFILER_NOT_INITIALIZED"
  | HIP_ERROR_PROFILER_ALREADY_STARTED -> str_atom "HIP_ERROR_PROFILER_ALREADY_STARTED"
  | HIP_ERROR_PROFILER_ALREADY_STOPPED -> str_atom "HIP_ERROR_PROFILER_ALREADY_STOPPED"
  | HIP_ERROR_INVALID_CONFIGURATION -> str_atom "HIP_ERROR_INVALID_CONFIGURATION"
  | HIP_ERROR_INVALID_PITCH_VALUE -> str_atom "HIP_ERROR_INVALID_PITCH_VALUE"
  | HIP_ERROR_INVALID_SYMBOL -> str_atom "HIP_ERROR_INVALID_SYMBOL"
  | HIP_ERROR_INVALID_DEVICE_POINTER -> str_atom "HIP_ERROR_INVALID_DEVICE_POINTER"
  | HIP_ERROR_INVALID_MEMCPY_DIRECTION -> str_atom "HIP_ERROR_INVALID_MEMCPY_DIRECTION"
  | HIP_ERROR_INSUFFICIENT_DRIVER -> str_atom "HIP_ERROR_INSUFFICIENT_DRIVER"
  | HIP_ERROR_MISSING_CONFIGURATION -> str_atom "HIP_ERROR_MISSING_CONFIGURATION"
  | HIP_ERROR_PRIOR_LAUNCH_FAILURE -> str_atom "HIP_ERROR_PRIOR_LAUNCH_FAILURE"
  | HIP_ERROR_INVALID_DEVICE_FUNCTION -> str_atom "HIP_ERROR_INVALID_DEVICE_FUNCTION"
  | HIP_ERROR_NO_DEVICE -> str_atom "HIP_ERROR_NO_DEVICE"
  | HIP_ERROR_INVALID_DEVICE -> str_atom "HIP_ERROR_INVALID_DEVICE"
  | HIP_ERROR_INVALID_IMAGE -> str_atom "HIP_ERROR_INVALID_IMAGE"
  | HIP_ERROR_INVALID_CONTEXT -> str_atom "HIP_ERROR_INVALID_CONTEXT"
  | HIP_ERROR_CONTEXT_ALREADY_CURRENT -> str_atom "HIP_ERROR_CONTEXT_ALREADY_CURRENT"
  | HIP_ERROR_MAP_FAILED -> str_atom "HIP_ERROR_MAP_FAILED"
  | HIP_ERROR_UNMAP_FAILED -> str_atom "HIP_ERROR_UNMAP_FAILED"
  | HIP_ERROR_ARRAY_IS_MAPPED -> str_atom "HIP_ERROR_ARRAY_IS_MAPPED"
  | HIP_ERROR_ALREADY_MAPPED -> str_atom "HIP_ERROR_ALREADY_MAPPED"
  | HIP_ERROR_NO_BINARY_FOR_GPU -> str_atom "HIP_ERROR_NO_BINARY_FOR_GPU"
  | HIP_ERROR_ALREADY_ACQUIRED -> str_atom "HIP_ERROR_ALREADY_ACQUIRED"
  | HIP_ERROR_NOT_MAPPED -> str_atom "HIP_ERROR_NOT_MAPPED"
  | HIP_ERROR_NOT_MAPPED_AS_ARRAY -> str_atom "HIP_ERROR_NOT_MAPPED_AS_ARRAY"
  | HIP_ERROR_NOT_MAPPED_AS_POINTER -> str_atom "HIP_ERROR_NOT_MAPPED_AS_POINTER"
  | HIP_ERROR_ECC_NOT_CORRECTABLE -> str_atom "HIP_ERROR_ECC_NOT_CORRECTABLE"
  | HIP_ERROR_UNSUPPORTED_LIMIT -> str_atom "HIP_ERROR_UNSUPPORTED_LIMIT"
  | HIP_ERROR_CONTEXT_ALREADY_IN_USE -> str_atom "HIP_ERROR_CONTEXT_ALREADY_IN_USE"
  | HIP_ERROR_PEER_ACCESS_UNSUPPORTED -> str_atom "HIP_ERROR_PEER_ACCESS_UNSUPPORTED"
  | HIP_ERROR_INVALID_KERNEL_FILE -> str_atom "HIP_ERROR_INVALID_KERNEL_FILE"
  | HIP_ERROR_INVALID_GRAPHICS_CONTEXT -> str_atom "HIP_ERROR_INVALID_GRAPHICS_CONTEXT"
  | HIP_ERROR_INVALID_SOURCE -> str_atom "HIP_ERROR_INVALID_SOURCE"
  | HIP_ERROR_FILE_NOT_FOUND -> str_atom "HIP_ERROR_FILE_NOT_FOUND"
  | HIP_ERROR_SHARED_OBJECT_SYMBOL_NOT_FOUND -> str_atom "HIP_ERROR_SHARED_OBJECT_SYMBOL_NOT_FOUND"
  | HIP_ERROR_SHARED_OBJECT_INIT_FAILED -> str_atom "HIP_ERROR_SHARED_OBJECT_INIT_FAILED"
  | HIP_ERROR_OPERATING_SYSTEM -> str_atom "HIP_ERROR_OPERATING_SYSTEM"
  | HIP_ERROR_INVALID_HANDLE -> str_atom "HIP_ERROR_INVALID_HANDLE"
  | HIP_ERROR_ILLEGAL_STATE -> str_atom "HIP_ERROR_ILLEGAL_STATE"
  | HIP_ERROR_NOT_FOUND -> str_atom "HIP_ERROR_NOT_FOUND"
  | HIP_ERROR_NOT_READY -> str_atom "HIP_ERROR_NOT_READY"
  | HIP_ERROR_ILLEGAL_ADDRESS -> str_atom "HIP_ERROR_ILLEGAL_ADDRESS"
  | HIP_ERROR_LAUNCH_OUT_OF_RESOURCES -> str_atom "HIP_ERROR_LAUNCH_OUT_OF_RESOURCES"
  | HIP_ERROR_LAUNCH_TIMEOUT -> str_atom "HIP_ERROR_LAUNCH_TIMEOUT"
  | HIP_ERROR_PEER_ACCESS_ALREADY_ENABLED -> str_atom "HIP_ERROR_PEER_ACCESS_ALREADY_ENABLED"
  | HIP_ERROR_PEER_ACCESS_NOT_ENABLED -> str_atom "HIP_ERROR_PEER_ACCESS_NOT_ENABLED"
  | HIP_ERROR_SET_ON_ACTIVE_PROCESS -> str_atom "HIP_ERROR_SET_ON_ACTIVE_PROCESS"
  | HIP_ERROR_CONTEXT_IS_DESTROYED -> str_atom "HIP_ERROR_CONTEXT_IS_DESTROYED"
  | HIP_ERROR_ASSERT -> str_atom "HIP_ERROR_ASSERT"
  | HIP_ERROR_HOST_MEMORY_ALREADY_REGISTERED -> str_atom "HIP_ERROR_HOST_MEMORY_ALREADY_REGISTERED"
  | HIP_ERROR_HOST_MEMORY_NOT_REGISTERED -> str_atom "HIP_ERROR_HOST_MEMORY_NOT_REGISTERED"
  | HIP_ERROR_LAUNCH_FAILURE -> str_atom "HIP_ERROR_LAUNCH_FAILURE"
  | HIP_ERROR_COOPERATIVE_LAUNCH_TOO_LARGE -> str_atom "HIP_ERROR_COOPERATIVE_LAUNCH_TOO_LARGE"
  | HIP_ERROR_NOT_SUPPORTED -> str_atom "HIP_ERROR_NOT_SUPPORTED"
  | HIP_ERROR_STREAM_CAPTURE_UNSUPPORTED -> str_atom "HIP_ERROR_STREAM_CAPTURE_UNSUPPORTED"
  | HIP_ERROR_STREAM_CAPTURE_INVALIDATED -> str_atom "HIP_ERROR_STREAM_CAPTURE_INVALIDATED"
  | HIP_ERROR_STREAM_CAPTURE_MERGE -> str_atom "HIP_ERROR_STREAM_CAPTURE_MERGE"
  | HIP_ERROR_STREAM_CAPTURE_UNMATCHED -> str_atom "HIP_ERROR_STREAM_CAPTURE_UNMATCHED"
  | HIP_ERROR_STREAM_CAPTURE_UNJOINED -> str_atom "HIP_ERROR_STREAM_CAPTURE_UNJOINED"
  | HIP_ERROR_STREAM_CAPTURE_ISOLATION -> str_atom "HIP_ERROR_STREAM_CAPTURE_ISOLATION"
  | HIP_ERROR_STREAM_CAPTURE_IMPLICIT -> str_atom "HIP_ERROR_STREAM_CAPTURE_IMPLICIT"
  | HIP_ERROR_CAPTURED_EVENT -> str_atom "HIP_ERROR_CAPTURED_EVENT"
  | HIP_ERROR_STREAM_CAPTURE_WRONG_THREAD -> str_atom "HIP_ERROR_STREAM_CAPTURE_WRONG_THREAD"
  | HIP_ERROR_GRAPH_EXEC_UPDATE_FAILURE -> str_atom "HIP_ERROR_GRAPH_EXEC_UPDATE_FAILURE"
  | HIP_ERROR_INVALID_CHANNEL_DESCRIPTOR -> str_atom "HIP_ERROR_INVALID_CHANNEL_DESCRIPTOR"
  | HIP_ERROR_INVALID_TEXTURE -> str_atom "HIP_ERROR_INVALID_TEXTURE"
  | HIP_ERROR_UNKNOWN -> str_atom "HIP_ERROR_UNKNOWN"
  | HIP_ERROR_RUNTIME_MEMORY -> str_atom "HIP_ERROR_RUNTIME_MEMORY"
  | HIP_ERROR_RUNTIME_OTHER -> str_atom "HIP_ERROR_RUNTIME_OTHER"
  | HIP_ERROR_TBD -> str_atom "HIP_ERROR_TBD"
  | HIP_ERROR_UNCATEGORIZED i64 ->
      Sexplib0.Sexp.List [ str_atom "HIP_ERROR_UNCATEGORIZED"; str_atom (Int64.to_string i64) ]

type hip_jit_option =
  | HIP_JIT_OPTION_MAX_REGISTERS
  | HIP_JIT_OPTION_THREADS_PER_BLOCK
  | HIP_JIT_OPTION_OPTIMIZATION_LEVEL
  | HIP_JIT_OPTION_GENERATE_DEBUG_INFO
  | HIP_JIT_OPTION_LOG_VERBOSE
  | HIP_JIT_OPTION_GENERATE_LINE_INFO
  | HIP_JIT_OPTION_FAST_COMPILE
  | HIP_JIT_OPTION_POSITION_INDEPENDENT_CODE
  | HIP_JIT_OPTION_MIN_CTA_PER_SM
  | HIP_JIT_OPTION_MAX_THREADS_PER_BLOCK
  | HIP_JIT_OPTION_IR_TO_ISA_OPT_EXT
  | HIP_JIT_OPTION_IR_TO_ISA_OPT_COUNT_EXT
  | HIP_JIT_OPTION_UNCATEGORIZED of int64

let sexp_of_hip_jit_option = function
  | HIP_JIT_OPTION_MAX_REGISTERS -> str_atom "HIP_JIT_OPTION_MAX_REGISTERS"
  | HIP_JIT_OPTION_THREADS_PER_BLOCK -> str_atom "HIP_JIT_OPTION_THREADS_PER_BLOCK"
  | HIP_JIT_OPTION_OPTIMIZATION_LEVEL -> str_atom "HIP_JIT_OPTION_OPTIMIZATION_LEVEL"
  | HIP_JIT_OPTION_GENERATE_DEBUG_INFO -> str_atom "HIP_JIT_OPTION_GENERATE_DEBUG_INFO"
  | HIP_JIT_OPTION_LOG_VERBOSE -> str_atom "HIP_JIT_OPTION_LOG_VERBOSE"
  | HIP_JIT_OPTION_GENERATE_LINE_INFO -> str_atom "HIP_JIT_OPTION_GENERATE_LINE_INFO"
  | HIP_JIT_OPTION_FAST_COMPILE -> str_atom "HIP_JIT_OPTION_FAST_COMPILE"
  | HIP_JIT_OPTION_POSITION_INDEPENDENT_CODE ->
      str_atom "HIP_JIT_OPTION_POSITION_INDEPENDENT_CODE"
  | HIP_JIT_OPTION_MIN_CTA_PER_SM -> str_atom "HIP_JIT_OPTION_MIN_CTA_PER_SM"
  | HIP_JIT_OPTION_MAX_THREADS_PER_BLOCK -> str_atom "HIP_JIT_OPTION_MAX_THREADS_PER_BLOCK"
  | HIP_JIT_OPTION_IR_TO_ISA_OPT_EXT -> str_atom "HIP_JIT_OPTION_IR_TO_ISA_OPT_EXT"
  | HIP_JIT_OPTION_IR_TO_ISA_OPT_COUNT_EXT -> str_atom "HIP_JIT_OPTION_IR_TO_ISA_OPT_COUNT_EXT"
  | HIP_JIT_OPTION_UNCATEGORIZED i64 ->
      Sexplib0.Sexp.List [ str_atom "HIP_JIT_OPTION_UNCATEGORIZED"; str_atom (Int64.to_string i64) ]

type hip_limit = HIP_LIMIT_STACK_SIZE | HIP_LIMIT_PRINTF_FIFO_SIZE | HIP_LIMIT_MALLOC_HEAP_SIZE

let sexp_of_hip_limit = function
  | HIP_LIMIT_STACK_SIZE -> str_atom "HIP_LIMIT_STACK_SIZE"
  | HIP_LIMIT_PRINTF_FIFO_SIZE -> str_atom "HIP_LIMIT_PRINTF_FIFO_SIZE"
  | HIP_LIMIT_MALLOC_HEAP_SIZE -> str_atom "HIP_LIMIT_MALLOC_HEAP_SIZE"

module Types (T : Ctypes.TYPE) = struct
  let hip_device_t = T.typedef T.int "hipDevice_t"

  let hip_device =
    T.view ~read:(fun i -> Hip_device i) ~write:(function Hip_device i -> i) hip_device_t

  (* hipError_t *)
  let hip_success = T.constant "hipSuccess" T.int64_t
  let hip_error_invalid_value = T.constant "hipErrorInvalidValue" T.int64_t
  let hip_error_out_of_memory = T.constant "hipErrorOutOfMemory" T.int64_t
  let hip_error_not_initialized = T.constant "hipErrorNotInitialized" T.int64_t
  let hip_error_deinitialized = T.constant "hipErrorDeinitialized" T.int64_t
  let hip_error_profiler_disabled = T.constant "hipErrorProfilerDisabled" T.int64_t
  let hip_error_profiler_not_initialized = T.constant "hipErrorProfilerNotInitialized" T.int64_t
  let hip_error_profiler_already_started = T.constant "hipErrorProfilerAlreadyStarted" T.int64_t
  let hip_error_profiler_already_stopped = T.constant "hipErrorProfilerAlreadyStopped" T.int64_t
  let hip_error_invalid_configuration = T.constant "hipErrorInvalidConfiguration" T.int64_t
  let hip_error_invalid_pitch_value = T.constant "hipErrorInvalidPitchValue" T.int64_t
  let hip_error_invalid_symbol = T.constant "hipErrorInvalidSymbol" T.int64_t
  let hip_error_invalid_device_pointer = T.constant "hipErrorInvalidDevicePointer" T.int64_t
  let hip_error_invalid_memcpy_direction = T.constant "hipErrorInvalidMemcpyDirection" T.int64_t
  let hip_error_insufficient_driver = T.constant "hipErrorInsufficientDriver" T.int64_t
  let hip_error_missing_configuration = T.constant "hipErrorMissingConfiguration" T.int64_t
  let hip_error_prior_launch_failure = T.constant "hipErrorPriorLaunchFailure" T.int64_t
  let hip_error_invalid_device_function = T.constant "hipErrorInvalidDeviceFunction" T.int64_t
  let hip_error_no_device = T.constant "hipErrorNoDevice" T.int64_t
  let hip_error_invalid_device = T.constant "hipErrorInvalidDevice" T.int64_t
  let hip_error_invalid_image = T.constant "hipErrorInvalidImage" T.int64_t
  let hip_error_invalid_context = T.constant "hipErrorInvalidContext" T.int64_t
  let hip_error_context_already_current = T.constant "hipErrorContextAlreadyCurrent" T.int64_t
  let hip_error_map_failed = T.constant "hipErrorMapFailed" T.int64_t
  let hip_error_unmap_failed = T.constant "hipErrorUnmapFailed" T.int64_t
  let hip_error_array_is_mapped = T.constant "hipErrorArrayIsMapped" T.int64_t
  let hip_error_already_mapped = T.constant "hipErrorAlreadyMapped" T.int64_t
  let hip_error_no_binary_for_gpu = T.constant "hipErrorNoBinaryForGpu" T.int64_t
  let hip_error_already_acquired = T.constant "hipErrorAlreadyAcquired" T.int64_t
  let hip_error_not_mapped = T.constant "hipErrorNotMapped" T.int64_t
  let hip_error_not_mapped_as_array = T.constant "hipErrorNotMappedAsArray" T.int64_t
  let hip_error_not_mapped_as_pointer = T.constant "hipErrorNotMappedAsPointer" T.int64_t
  let hip_error_ecc_not_correctable = T.constant "hipErrorECCNotCorrectable" T.int64_t
  let hip_error_unsupported_limit = T.constant "hipErrorUnsupportedLimit" T.int64_t
  let hip_error_context_already_in_use = T.constant "hipErrorContextAlreadyInUse" T.int64_t
  let hip_error_peer_access_unsupported = T.constant "hipErrorPeerAccessUnsupported" T.int64_t
  let hip_error_invalid_kernel_file = T.constant "hipErrorInvalidKernelFile" T.int64_t
  let hip_error_invalid_graphics_context = T.constant "hipErrorInvalidGraphicsContext" T.int64_t
  let hip_error_invalid_source = T.constant "hipErrorInvalidSource" T.int64_t
  let hip_error_file_not_found = T.constant "hipErrorFileNotFound" T.int64_t

  let hip_error_shared_object_symbol_not_found =
    T.constant "hipErrorSharedObjectSymbolNotFound" T.int64_t

  let hip_error_shared_object_init_failed = T.constant "hipErrorSharedObjectInitFailed" T.int64_t
  let hip_error_operating_system = T.constant "hipErrorOperatingSystem" T.int64_t
  let hip_error_invalid_handle = T.constant "hipErrorInvalidHandle" T.int64_t
  let hip_error_illegal_state = T.constant "hipErrorIllegalState" T.int64_t
  let hip_error_not_found = T.constant "hipErrorNotFound" T.int64_t
  let hip_error_not_ready = T.constant "hipErrorNotReady" T.int64_t
  let hip_error_illegal_address = T.constant "hipErrorIllegalAddress" T.int64_t
  let hip_error_launch_out_of_resources = T.constant "hipErrorLaunchOutOfResources" T.int64_t
  let hip_error_launch_timeout = T.constant "hipErrorLaunchTimeOut" T.int64_t

  let hip_error_peer_access_already_enabled =
    T.constant "hipErrorPeerAccessAlreadyEnabled" T.int64_t

  let hip_error_peer_access_not_enabled = T.constant "hipErrorPeerAccessNotEnabled" T.int64_t
  let hip_error_set_on_active_process = T.constant "hipErrorSetOnActiveProcess" T.int64_t
  let hip_error_context_is_destroyed = T.constant "hipErrorContextIsDestroyed" T.int64_t
  let hip_error_assert = T.constant "hipErrorAssert" T.int64_t

  let hip_error_host_memory_already_registered =
    T.constant "hipErrorHostMemoryAlreadyRegistered" T.int64_t

  let hip_error_host_memory_not_registered =
    T.constant "hipErrorHostMemoryNotRegistered" T.int64_t

  let hip_error_launch_failure = T.constant "hipErrorLaunchFailure" T.int64_t

  let hip_error_cooperative_launch_too_large =
    T.constant "hipErrorCooperativeLaunchTooLarge" T.int64_t

  let hip_error_not_supported = T.constant "hipErrorNotSupported" T.int64_t
  let hip_error_stream_capture_unsupported = T.constant "hipErrorStreamCaptureUnsupported" T.int64_t
  let hip_error_stream_capture_invalidated = T.constant "hipErrorStreamCaptureInvalidated" T.int64_t
  let hip_error_stream_capture_merge = T.constant "hipErrorStreamCaptureMerge" T.int64_t
  let hip_error_stream_capture_unmatched = T.constant "hipErrorStreamCaptureUnmatched" T.int64_t
  let hip_error_stream_capture_unjoined = T.constant "hipErrorStreamCaptureUnjoined" T.int64_t
  let hip_error_stream_capture_isolation = T.constant "hipErrorStreamCaptureIsolation" T.int64_t
  let hip_error_stream_capture_implicit = T.constant "hipErrorStreamCaptureImplicit" T.int64_t
  let hip_error_captured_event = T.constant "hipErrorCapturedEvent" T.int64_t

  let hip_error_stream_capture_wrong_thread =
    T.constant "hipErrorStreamCaptureWrongThread" T.int64_t

  let hip_error_graph_exec_update_failure = T.constant "hipErrorGraphExecUpdateFailure" T.int64_t

  let hip_error_invalid_channel_descriptor =
    T.constant "hipErrorInvalidChannelDescriptor" T.int64_t

  let hip_error_invalid_texture = T.constant "hipErrorInvalidTexture" T.int64_t
  let hip_error_unknown = T.constant "hipErrorUnknown" T.int64_t
  let hip_error_runtime_memory = T.constant "hipErrorRuntimeMemory" T.int64_t
  let hip_error_runtime_other = T.constant "hipErrorRuntimeOther" T.int64_t
  let hip_error_tbd = T.constant "hipErrorTbd" T.int64_t

  let hip_result =
    T.enum ~typedef:true
      ~unexpected:(fun error_code -> HIP_ERROR_UNCATEGORIZED error_code)
      "hipError_t"
      [
        (HIP_SUCCESS, hip_success);
        (HIP_ERROR_INVALID_VALUE, hip_error_invalid_value);
        (HIP_ERROR_OUT_OF_MEMORY, hip_error_out_of_memory);
        (HIP_ERROR_NOT_INITIALIZED, hip_error_not_initialized);
        (HIP_ERROR_DEINITIALIZED, hip_error_deinitialized);
        (HIP_ERROR_PROFILER_DISABLED, hip_error_profiler_disabled);
        (HIP_ERROR_PROFILER_NOT_INITIALIZED, hip_error_profiler_not_initialized);
        (HIP_ERROR_PROFILER_ALREADY_STARTED, hip_error_profiler_already_started);
        (HIP_ERROR_PROFILER_ALREADY_STOPPED, hip_error_profiler_already_stopped);
        (HIP_ERROR_INVALID_CONFIGURATION, hip_error_invalid_configuration);
        (HIP_ERROR_INVALID_PITCH_VALUE, hip_error_invalid_pitch_value);
        (HIP_ERROR_INVALID_SYMBOL, hip_error_invalid_symbol);
        (HIP_ERROR_INVALID_DEVICE_POINTER, hip_error_invalid_device_pointer);
        (HIP_ERROR_INVALID_MEMCPY_DIRECTION, hip_error_invalid_memcpy_direction);
        (HIP_ERROR_INSUFFICIENT_DRIVER, hip_error_insufficient_driver);
        (HIP_ERROR_MISSING_CONFIGURATION, hip_error_missing_configuration);
        (HIP_ERROR_PRIOR_LAUNCH_FAILURE, hip_error_prior_launch_failure);
        (HIP_ERROR_INVALID_DEVICE_FUNCTION, hip_error_invalid_device_function);
        (HIP_ERROR_NO_DEVICE, hip_error_no_device);
        (HIP_ERROR_INVALID_DEVICE, hip_error_invalid_device);
        (HIP_ERROR_INVALID_IMAGE, hip_error_invalid_image);
        (HIP_ERROR_INVALID_CONTEXT, hip_error_invalid_context);
        (HIP_ERROR_CONTEXT_ALREADY_CURRENT, hip_error_context_already_current);
        (HIP_ERROR_MAP_FAILED, hip_error_map_failed);
        (HIP_ERROR_UNMAP_FAILED, hip_error_unmap_failed);
        (HIP_ERROR_ARRAY_IS_MAPPED, hip_error_array_is_mapped);
        (HIP_ERROR_ALREADY_MAPPED, hip_error_already_mapped);
        (HIP_ERROR_NO_BINARY_FOR_GPU, hip_error_no_binary_for_gpu);
        (HIP_ERROR_ALREADY_ACQUIRED, hip_error_already_acquired);
        (HIP_ERROR_NOT_MAPPED, hip_error_not_mapped);
        (HIP_ERROR_NOT_MAPPED_AS_ARRAY, hip_error_not_mapped_as_array);
        (HIP_ERROR_NOT_MAPPED_AS_POINTER, hip_error_not_mapped_as_pointer);
        (HIP_ERROR_ECC_NOT_CORRECTABLE, hip_error_ecc_not_correctable);
        (HIP_ERROR_UNSUPPORTED_LIMIT, hip_error_unsupported_limit);
        (HIP_ERROR_CONTEXT_ALREADY_IN_USE, hip_error_context_already_in_use);
        (HIP_ERROR_PEER_ACCESS_UNSUPPORTED, hip_error_peer_access_unsupported);
        (HIP_ERROR_INVALID_KERNEL_FILE, hip_error_invalid_kernel_file);
        (HIP_ERROR_INVALID_GRAPHICS_CONTEXT, hip_error_invalid_graphics_context);
        (HIP_ERROR_INVALID_SOURCE, hip_error_invalid_source);
        (HIP_ERROR_FILE_NOT_FOUND, hip_error_file_not_found);
        (HIP_ERROR_SHARED_OBJECT_SYMBOL_NOT_FOUND, hip_error_shared_object_symbol_not_found);
        (HIP_ERROR_SHARED_OBJECT_INIT_FAILED, hip_error_shared_object_init_failed);
        (HIP_ERROR_OPERATING_SYSTEM, hip_error_operating_system);
        (HIP_ERROR_INVALID_HANDLE, hip_error_invalid_handle);
        (HIP_ERROR_ILLEGAL_STATE, hip_error_illegal_state);
        (HIP_ERROR_NOT_FOUND, hip_error_not_found);
        (HIP_ERROR_NOT_READY, hip_error_not_ready);
        (HIP_ERROR_ILLEGAL_ADDRESS, hip_error_illegal_address);
        (HIP_ERROR_LAUNCH_OUT_OF_RESOURCES, hip_error_launch_out_of_resources);
        (HIP_ERROR_LAUNCH_TIMEOUT, hip_error_launch_timeout);
        (HIP_ERROR_PEER_ACCESS_ALREADY_ENABLED, hip_error_peer_access_already_enabled);
        (HIP_ERROR_PEER_ACCESS_NOT_ENABLED, hip_error_peer_access_not_enabled);
        (HIP_ERROR_SET_ON_ACTIVE_PROCESS, hip_error_set_on_active_process);
        (HIP_ERROR_CONTEXT_IS_DESTROYED, hip_error_context_is_destroyed);
        (HIP_ERROR_ASSERT, hip_error_assert);
        (HIP_ERROR_HOST_MEMORY_ALREADY_REGISTERED, hip_error_host_memory_already_registered);
        (HIP_ERROR_HOST_MEMORY_NOT_REGISTERED, hip_error_host_memory_not_registered);
        (HIP_ERROR_LAUNCH_FAILURE, hip_error_launch_failure);
        (HIP_ERROR_COOPERATIVE_LAUNCH_TOO_LARGE, hip_error_cooperative_launch_too_large);
        (HIP_ERROR_NOT_SUPPORTED, hip_error_not_supported);
        (HIP_ERROR_STREAM_CAPTURE_UNSUPPORTED, hip_error_stream_capture_unsupported);
        (HIP_ERROR_STREAM_CAPTURE_INVALIDATED, hip_error_stream_capture_invalidated);
        (HIP_ERROR_STREAM_CAPTURE_MERGE, hip_error_stream_capture_merge);
        (HIP_ERROR_STREAM_CAPTURE_UNMATCHED, hip_error_stream_capture_unmatched);
        (HIP_ERROR_STREAM_CAPTURE_UNJOINED, hip_error_stream_capture_unjoined);
        (HIP_ERROR_STREAM_CAPTURE_ISOLATION, hip_error_stream_capture_isolation);
        (HIP_ERROR_STREAM_CAPTURE_IMPLICIT, hip_error_stream_capture_implicit);
        (HIP_ERROR_CAPTURED_EVENT, hip_error_captured_event);
        (HIP_ERROR_STREAM_CAPTURE_WRONG_THREAD, hip_error_stream_capture_wrong_thread);
        (HIP_ERROR_GRAPH_EXEC_UPDATE_FAILURE, hip_error_graph_exec_update_failure);
        (HIP_ERROR_INVALID_CHANNEL_DESCRIPTOR, hip_error_invalid_channel_descriptor);
        (HIP_ERROR_INVALID_TEXTURE, hip_error_invalid_texture);
        (HIP_ERROR_UNKNOWN, hip_error_unknown);
        (HIP_ERROR_RUNTIME_MEMORY, hip_error_runtime_memory);
        (HIP_ERROR_RUNTIME_OTHER, hip_error_runtime_other);
        (HIP_ERROR_TBD, hip_error_tbd);
      ]

  (* hipJitOption *)
  let hip_jit_option_max_registers = T.constant "hipJitOptionMaxRegisters" T.int64_t
  let hip_jit_option_threads_per_block = T.constant "hipJitOptionThreadsPerBlock" T.int64_t
  let hip_jit_option_optimization_level = T.constant "hipJitOptionOptimizationLevel" T.int64_t
  let hip_jit_option_generate_debug_info = T.constant "hipJitOptionGenerateDebugInfo" T.int64_t
  let hip_jit_option_log_verbose = T.constant "hipJitOptionLogVerbose" T.int64_t
  let hip_jit_option_generate_line_info = T.constant "hipJitOptionGenerateLineInfo" T.int64_t
  let hip_jit_option_fast_compile = T.constant "hipJitOptionFastCompile" T.int64_t

  let hip_jit_option_position_independent_code =
    T.constant "hipJitOptionPositionIndependentCode" T.int64_t

  let hip_jit_option_min_cta_per_sm = T.constant "hipJitOptionMinCTAPerSM" T.int64_t
  let hip_jit_option_max_threads_per_block = T.constant "hipJitOptionMaxThreadsPerBlock" T.int64_t
  let hip_jit_option_ir_to_isa_opt_ext = T.constant "hipJitOptionIRtoISAOptExt" T.int64_t

  let hip_jit_option_ir_to_isa_opt_count_ext =
    T.constant "hipJitOptionIRtoISAOptCountExt" T.int64_t

  let hip_jit_option =
    T.enum ~typedef:true
      ~unexpected:(fun error_code -> HIP_JIT_OPTION_UNCATEGORIZED error_code)
      "hipJitOption"
      [
        (HIP_JIT_OPTION_MAX_REGISTERS, hip_jit_option_max_registers);
        (HIP_JIT_OPTION_THREADS_PER_BLOCK, hip_jit_option_threads_per_block);
        (HIP_JIT_OPTION_OPTIMIZATION_LEVEL, hip_jit_option_optimization_level);
        (HIP_JIT_OPTION_GENERATE_DEBUG_INFO, hip_jit_option_generate_debug_info);
        (HIP_JIT_OPTION_LOG_VERBOSE, hip_jit_option_log_verbose);
        (HIP_JIT_OPTION_GENERATE_LINE_INFO, hip_jit_option_generate_line_info);
        (HIP_JIT_OPTION_FAST_COMPILE, hip_jit_option_fast_compile);
        (HIP_JIT_OPTION_POSITION_INDEPENDENT_CODE, hip_jit_option_position_independent_code);
        (HIP_JIT_OPTION_MIN_CTA_PER_SM, hip_jit_option_min_cta_per_sm);
        (HIP_JIT_OPTION_MAX_THREADS_PER_BLOCK, hip_jit_option_max_threads_per_block);
        (HIP_JIT_OPTION_IR_TO_ISA_OPT_EXT, hip_jit_option_ir_to_isa_opt_ext);
        (HIP_JIT_OPTION_IR_TO_ISA_OPT_COUNT_EXT, hip_jit_option_ir_to_isa_opt_count_ext);
      ]

  (* enum hipLimit_t (not a typedef) *)
  let hip_limit_stack_size = T.constant "hipLimitStackSize" T.int64_t
  let hip_limit_printf_fifo_size = T.constant "hipLimitPrintfFifoSize" T.int64_t
  let hip_limit_malloc_heap_size = T.constant "hipLimitMallocHeapSize" T.int64_t

  let hip_limit =
    T.enum
      ~unexpected:(fun _ -> HIP_LIMIT_STACK_SIZE)
      "hipLimit_t"
      [
        (HIP_LIMIT_STACK_SIZE, hip_limit_stack_size);
        (HIP_LIMIT_PRINTF_FIFO_SIZE, hip_limit_printf_fifo_size);
        (HIP_LIMIT_MALLOC_HEAP_SIZE, hip_limit_malloc_heap_size);
      ]

  (* Context / device scheduling flags (macros). *)
  let hip_device_schedule_auto = T.constant "hipDeviceScheduleAuto" T.int64_t
  let hip_device_schedule_spin = T.constant "hipDeviceScheduleSpin" T.int64_t
  let hip_device_schedule_yield = T.constant "hipDeviceScheduleYield" T.int64_t
  let hip_device_schedule_blocking_sync = T.constant "hipDeviceScheduleBlockingSync" T.int64_t
  let hip_device_schedule_mask = T.constant "hipDeviceScheduleMask" T.int64_t
  let hip_device_map_host = T.constant "hipDeviceMapHost" T.int64_t
  let hip_device_lmem_resize_to_max = T.constant "hipDeviceLmemResizeToMax" T.int64_t

  (* Stream flags (macros). *)
  let hip_stream_default = T.constant "hipStreamDefault" T.int64_t
  let hip_stream_non_blocking = T.constant "hipStreamNonBlocking" T.int64_t

  (* Event flags (macros). *)
  let hip_event_default = T.constant "hipEventDefault" T.int64_t
  let hip_event_blocking_sync = T.constant "hipEventBlockingSync" T.int64_t
  let hip_event_disable_timing = T.constant "hipEventDisableTiming" T.int64_t
  let hip_event_interprocess = T.constant "hipEventInterprocess" T.int64_t

  (* Partial binding of hipDeviceProp_t (macro-versioned to hipDeviceProp_tR0600); field offsets
     and struct size are computed from the header by the ctypes stub generator, so fields can be
     bound selectively. *)
  type hip_device_prop

  let hip_device_prop : hip_device_prop Ctypes.structure T.typ = T.structure "hipDeviceProp_t"
  let prop_name = T.field hip_device_prop "name" (T.array 256 T.char)
  let prop_total_global_mem = T.field hip_device_prop "totalGlobalMem" T.size_t
  let prop_shared_mem_per_block = T.field hip_device_prop "sharedMemPerBlock" T.size_t
  let prop_regs_per_block = T.field hip_device_prop "regsPerBlock" T.int
  let prop_warp_size = T.field hip_device_prop "warpSize" T.int
  let prop_max_threads_per_block = T.field hip_device_prop "maxThreadsPerBlock" T.int
  let prop_max_threads_dim = T.field hip_device_prop "maxThreadsDim" (T.array 3 T.int)
  let prop_max_grid_size = T.field hip_device_prop "maxGridSize" (T.array 3 T.int)
  let prop_clock_rate = T.field hip_device_prop "clockRate" T.int
  let prop_total_const_mem = T.field hip_device_prop "totalConstMem" T.size_t
  let prop_major = T.field hip_device_prop "major" T.int
  let prop_minor = T.field hip_device_prop "minor" T.int
  let prop_multi_processor_count = T.field hip_device_prop "multiProcessorCount" T.int
  let prop_integrated = T.field hip_device_prop "integrated" T.int
  let prop_can_map_host_memory = T.field hip_device_prop "canMapHostMemory" T.int
  let prop_compute_mode = T.field hip_device_prop "computeMode" T.int
  let prop_concurrent_kernels = T.field hip_device_prop "concurrentKernels" T.int
  let prop_pci_bus_id = T.field hip_device_prop "pciBusID" T.int
  let prop_pci_device_id = T.field hip_device_prop "pciDeviceID" T.int
  let prop_pci_domain_id = T.field hip_device_prop "pciDomainID" T.int
  let prop_async_engine_count = T.field hip_device_prop "asyncEngineCount" T.int
  let prop_unified_addressing = T.field hip_device_prop "unifiedAddressing" T.int
  let prop_memory_clock_rate = T.field hip_device_prop "memoryClockRate" T.int
  let prop_memory_bus_width = T.field hip_device_prop "memoryBusWidth" T.int
  let prop_l2_cache_size = T.field hip_device_prop "l2CacheSize" T.int

  let prop_max_threads_per_multi_processor =
    T.field hip_device_prop "maxThreadsPerMultiProcessor" T.int

  let prop_shared_mem_per_multiprocessor =
    T.field hip_device_prop "sharedMemPerMultiprocessor" T.size_t

  let prop_managed_memory = T.field hip_device_prop "managedMemory" T.int
  let prop_is_multi_gpu_board = T.field hip_device_prop "isMultiGpuBoard" T.int

  let prop_host_native_atomic_supported =
    T.field hip_device_prop "hostNativeAtomicSupported" T.int

  let prop_pageable_memory_access = T.field hip_device_prop "pageableMemoryAccess" T.int
  let prop_concurrent_managed_access = T.field hip_device_prop "concurrentManagedAccess" T.int
  let prop_cooperative_launch = T.field hip_device_prop "cooperativeLaunch" T.int

  let prop_cooperative_multi_device_launch =
    T.field hip_device_prop "cooperativeMultiDeviceLaunch" T.int

  let prop_memory_pools_supported = T.field hip_device_prop "memoryPoolsSupported" T.int
  let prop_gcn_arch_name = T.field hip_device_prop "gcnArchName" (T.array 256 T.char)

  let prop_max_shared_memory_per_multi_processor =
    T.field hip_device_prop "maxSharedMemoryPerMultiProcessor" T.size_t

  let prop_clock_instruction_rate = T.field hip_device_prop "clockInstructionRate" T.int
  let prop_is_large_bar = T.field hip_device_prop "isLargeBar" T.int
  let prop_asic_revision = T.field hip_device_prop "asicRevision" T.int
  let () = T.seal hip_device_prop
end
