open Ctypes
open Bindings_types

module Functions (F : Ctypes.FOREIGN) = struct
  module E = Types_generated

  (* Initialization and versioning. *)
  let hip_init = F.foreign "hipInit" F.(uint @-> returning E.hip_result)
  let hip_driver_get_version = F.foreign "hipDriverGetVersion" F.(ptr int @-> returning E.hip_result)

  let hip_runtime_get_version =
    F.foreign "hipRuntimeGetVersion" F.(ptr int @-> returning E.hip_result)

  let hip_get_error_name = F.foreign "hipGetErrorName" F.(E.hip_result @-> returning string)
  let hip_get_error_string = F.foreign "hipGetErrorString" F.(E.hip_result @-> returning string)

  (* Device management. *)
  let hip_get_device_count = F.foreign "hipGetDeviceCount" F.(ptr int @-> returning E.hip_result)
  let hip_device_get = F.foreign "hipDeviceGet" F.(ptr E.hip_device @-> int @-> returning E.hip_result)

  let hip_device_get_name =
    F.foreign "hipDeviceGetName" F.(ptr char @-> int @-> E.hip_device @-> returning E.hip_result)

  let hip_device_total_mem =
    F.foreign "hipDeviceTotalMem" F.(ptr size_t @-> E.hip_device @-> returning E.hip_result)

  let hip_mem_get_info =
    F.foreign "hipMemGetInfo" F.(ptr size_t @-> ptr size_t @-> returning E.hip_result)

  let hip_get_device_properties =
    F.foreign "hipGetDeviceProperties" F.(ptr E.hip_device_prop @-> int @-> returning E.hip_result)

  let hip_set_device = F.foreign "hipSetDevice" F.(int @-> returning E.hip_result)
  let hip_get_device = F.foreign "hipGetDevice" F.(ptr int @-> returning E.hip_result)
  let hip_device_synchronize = F.foreign "hipDeviceSynchronize" F.(void @-> returning E.hip_result)

  let hip_device_set_limit =
    F.foreign "hipDeviceSetLimit" F.(E.hip_limit @-> size_t @-> returning E.hip_result)

  let hip_device_get_limit =
    F.foreign "hipDeviceGetLimit" F.(ptr size_t @-> E.hip_limit @-> returning E.hip_result)

  (* Peer-to-peer access. *)
  let hip_device_can_access_peer =
    F.foreign "hipDeviceCanAccessPeer" F.(ptr int @-> int @-> int @-> returning E.hip_result)

  let hip_device_enable_peer_access =
    F.foreign "hipDeviceEnablePeerAccess" F.(int @-> uint @-> returning E.hip_result)

  let hip_device_disable_peer_access =
    F.foreign "hipDeviceDisablePeerAccess" F.(int @-> returning E.hip_result)

  (* Primary context and (deprecated in HIP, but CUDA-driver-compatible) context management. *)
  let hip_device_primary_ctx_retain =
    F.foreign "hipDevicePrimaryCtxRetain"
      F.(ptr hip_context @-> E.hip_device @-> returning E.hip_result)

  let hip_device_primary_ctx_release =
    F.foreign "hipDevicePrimaryCtxRelease" F.(E.hip_device @-> returning E.hip_result)

  let hip_device_primary_ctx_reset =
    F.foreign "hipDevicePrimaryCtxReset" F.(E.hip_device @-> returning E.hip_result)

  let hip_ctx_create =
    F.foreign "hipCtxCreate" F.(ptr hip_context @-> uint @-> E.hip_device @-> returning E.hip_result)

  let hip_ctx_destroy = F.foreign "hipCtxDestroy" F.(hip_context @-> returning E.hip_result)
  let hip_ctx_set_current = F.foreign "hipCtxSetCurrent" F.(hip_context @-> returning E.hip_result)

  let hip_ctx_get_current =
    F.foreign "hipCtxGetCurrent" F.(ptr hip_context @-> returning E.hip_result)

  let hip_ctx_push_current =
    F.foreign "hipCtxPushCurrent" F.(hip_context @-> returning E.hip_result)

  let hip_ctx_pop_current =
    F.foreign "hipCtxPopCurrent" F.(ptr hip_context @-> returning E.hip_result)

  let hip_ctx_get_device =
    F.foreign "hipCtxGetDevice" F.(ptr E.hip_device @-> returning E.hip_result)

  (* Memory management. *)
  let hip_malloc = F.foreign "hipMalloc" F.(ptr hip_deviceptr @-> size_t @-> returning E.hip_result)
  let hip_free = F.foreign "hipFree" F.(hip_deviceptr @-> returning E.hip_result)

  let hip_malloc_async =
    F.foreign "hipMallocAsync"
      F.(ptr hip_deviceptr @-> size_t @-> hip_stream @-> returning E.hip_result)

  let hip_free_async =
    F.foreign "hipFreeAsync" F.(hip_deviceptr @-> hip_stream @-> returning E.hip_result)

  let hip_memcpy_H_to_D =
    F.foreign "hipMemcpyHtoD" F.(hip_deviceptr @-> ptr void @-> size_t @-> returning E.hip_result)

  let hip_memcpy_H_to_D_async =
    F.foreign "hipMemcpyHtoDAsync"
      F.(hip_deviceptr @-> ptr void @-> size_t @-> hip_stream @-> returning E.hip_result)

  let hip_memcpy_D_to_H =
    F.foreign "hipMemcpyDtoH" F.(ptr void @-> hip_deviceptr @-> size_t @-> returning E.hip_result)

  let hip_memcpy_D_to_H_async =
    F.foreign "hipMemcpyDtoHAsync"
      F.(ptr void @-> hip_deviceptr @-> size_t @-> hip_stream @-> returning E.hip_result)

  let hip_memcpy_D_to_D =
    F.foreign "hipMemcpyDtoD"
      F.(hip_deviceptr @-> hip_deviceptr @-> size_t @-> returning E.hip_result)

  let hip_memcpy_D_to_D_async =
    F.foreign "hipMemcpyDtoDAsync"
      F.(hip_deviceptr @-> hip_deviceptr @-> size_t @-> hip_stream @-> returning E.hip_result)

  let hip_memcpy_peer =
    F.foreign "hipMemcpyPeer"
      F.(ptr void @-> int @-> ptr void @-> int @-> size_t @-> returning E.hip_result)

  let hip_memcpy_peer_async =
    F.foreign "hipMemcpyPeerAsync"
      F.(ptr void @-> int @-> ptr void @-> int @-> size_t @-> hip_stream
         @-> returning E.hip_result)

  let hip_memset_d8 =
    F.foreign "hipMemsetD8" F.(hip_deviceptr @-> uchar @-> size_t @-> returning E.hip_result)

  let hip_memset_d8_async =
    F.foreign "hipMemsetD8Async"
      F.(hip_deviceptr @-> uchar @-> size_t @-> hip_stream @-> returning E.hip_result)

  let hip_memset_d16 =
    F.foreign "hipMemsetD16" F.(hip_deviceptr @-> ushort @-> size_t @-> returning E.hip_result)

  let hip_memset_d16_async =
    F.foreign "hipMemsetD16Async"
      F.(hip_deviceptr @-> ushort @-> size_t @-> hip_stream @-> returning E.hip_result)

  let hip_memset_d32 =
    F.foreign "hipMemsetD32" F.(hip_deviceptr @-> int @-> size_t @-> returning E.hip_result)

  let hip_memset_d32_async =
    F.foreign "hipMemsetD32Async"
      F.(hip_deviceptr @-> int @-> size_t @-> hip_stream @-> returning E.hip_result)

  (* Modules and kernels. *)
  let hip_module_load_data =
    F.foreign "hipModuleLoadData" F.(ptr hip_module @-> ptr void @-> returning E.hip_result)

  let hip_module_load_data_ex =
    F.foreign "hipModuleLoadDataEx"
      F.(ptr hip_module @-> ptr void @-> uint @-> ptr E.hip_jit_option @-> ptr (ptr void)
         @-> returning E.hip_result)

  let hip_module_unload = F.foreign "hipModuleUnload" F.(hip_module @-> returning E.hip_result)

  let hip_module_get_function =
    F.foreign "hipModuleGetFunction"
      F.(ptr hip_function @-> hip_module @-> string @-> returning E.hip_result)

  let hip_module_get_global =
    F.foreign "hipModuleGetGlobal"
      F.(ptr hip_deviceptr @-> ptr size_t @-> hip_module @-> string @-> returning E.hip_result)

  let hip_module_launch_kernel =
    F.foreign "hipModuleLaunchKernel"
      F.(hip_function @-> uint @-> uint @-> uint @-> uint @-> uint @-> uint @-> uint @-> hip_stream
         @-> ptr (ptr void) @-> ptr (ptr void) @-> returning E.hip_result)

  (* Streams. *)
  let hip_stream_create_with_flags =
    F.foreign "hipStreamCreateWithFlags" F.(ptr hip_stream @-> uint @-> returning E.hip_result)

  let hip_stream_create_with_priority =
    F.foreign "hipStreamCreateWithPriority"
      F.(ptr hip_stream @-> uint @-> int @-> returning E.hip_result)

  let hip_stream_destroy = F.foreign "hipStreamDestroy" F.(hip_stream @-> returning E.hip_result)

  let hip_stream_synchronize =
    F.foreign "hipStreamSynchronize" F.(hip_stream @-> returning E.hip_result)

  let hip_stream_query = F.foreign "hipStreamQuery" F.(hip_stream @-> returning E.hip_result)

  let hip_stream_wait_event =
    F.foreign "hipStreamWaitEvent" F.(hip_stream @-> hip_event @-> uint @-> returning E.hip_result)

  let hip_stream_get_device =
    F.foreign "hipStreamGetDevice" F.(hip_stream @-> ptr E.hip_device @-> returning E.hip_result)

  let hip_get_stream_device_id = F.foreign "hipGetStreamDeviceId" F.(hip_stream @-> returning int)

  (* Events. *)
  let hip_event_create_with_flags =
    F.foreign "hipEventCreateWithFlags" F.(ptr hip_event @-> uint @-> returning E.hip_result)

  let hip_event_destroy = F.foreign "hipEventDestroy" F.(hip_event @-> returning E.hip_result)
  let hip_event_query = F.foreign "hipEventQuery" F.(hip_event @-> returning E.hip_result)

  let hip_event_record =
    F.foreign "hipEventRecord" F.(hip_event @-> hip_stream @-> returning E.hip_result)

  let hip_event_synchronize =
    F.foreign "hipEventSynchronize" F.(hip_event @-> returning E.hip_result)

  let hip_event_elapsed_time =
    F.foreign "hipEventElapsedTime" F.(ptr float @-> hip_event @-> hip_event @-> returning E.hip_result)
end
