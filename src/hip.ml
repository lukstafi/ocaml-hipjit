module Hip = Hip_ffi.C.Functions
open Hip_ffi.Bindings_types
open Sexplib0.Sexp_conv

type result = hip_result

let sexp_of_result = sexp_of_hip_result

exception Hip_error of { status : result; message : string }
exception Use_after_free of { func : string; arg : string }

let hip_error_printer = function
  | Hip_error { status; message } ->
      ignore @@ Format.flush_str_formatter ();
      Format.fprintf Format.str_formatter "%s:@ %a" message Sexplib0.Sexp.pp_hum
        (sexp_of_result status);
      Some (Format.flush_str_formatter ())
  | Use_after_free { func; arg } -> Some (func ^ ": " ^ arg ^ " is already freed")
  | _ -> None

let () = Printexc.register_printer hip_error_printer
let is_success = function HIP_SUCCESS -> true | _ -> false
let error_name status = Hip.hip_get_error_name status
let error_string status = Hip.hip_get_error_string status
let hip_call_hook : (message:string -> status:result -> unit) option ref = ref None

let check message status =
  (match !hip_call_hook with None -> () | Some callback -> callback ~message ~status);
  if status <> HIP_SUCCESS then raise @@ Hip_error { status; message }

let check_freed ~func args =
  List.iter (fun (arg, freed) -> if Atomic.get freed then raise @@ Use_after_free { func; arg }) args

let init ?(flags = 0) () = check "hip_init" @@ Hip.hip_init @@ Unsigned.UInt.of_int flags

let driver_get_version () =
  let open Ctypes in
  let version = allocate int 0 in
  check "hip_driver_get_version" @@ Hip.hip_driver_get_version version;
  !@version

let runtime_get_version () =
  let open Ctypes in
  let version = allocate int 0 in
  check "hip_runtime_get_version" @@ Hip.hip_runtime_get_version version;
  !@version

type memptr = Unsigned.uint64

let string_of_memptr ptr = Unsigned.UInt64.to_hexstring ptr
let sexp_of_memptr ptr = Sexplib0.Sexp.Atom (string_of_memptr ptr)

(* On the AMD platform [hipDeviceptr_t] is [void*]; we keep an integer representation for pointer
   arithmetic (offsets) and hashing, converting at the FFI boundary. *)
let voidp_of_memptr ptr =
  Ctypes.ptr_of_raw_address @@ Int64.to_nativeint @@ Unsigned.UInt64.to_int64 ptr

let memptr_of_voidp voidp =
  Unsigned.UInt64.of_int64 @@ Int64.of_nativeint @@ Ctypes.raw_address_of_ptr voidp

type atomic_bool = bool Atomic.t

let sexp_of_atomic_bool flag = sexp_of_bool @@ Atomic.get flag

type deviceptr = Deviceptr of { ptr : memptr; freed : atomic_bool }

let sexp_of_deviceptr (Deviceptr { ptr; freed }) =
  Sexplib0.Sexp.List
    [
      Sexplib0.Sexp.Atom "Deviceptr";
      sexp_of_memptr ptr;
      Sexplib0.Sexp.List [ Sexplib0.Sexp.Atom "freed"; sexp_of_atomic_bool freed ];
    ]

let string_from_carray arr =
  let len = Ctypes.CArray.length arr in
  let b = Buffer.create 64 in
  (try
     for i = 0 to len - 1 do
       let c = Ctypes.CArray.get arr i in
       if Char.equal c '\000' then raise Exit else Buffer.add_char b c
     done
   with Exit -> ());
  Buffer.contents b

module Device = struct
  type t = hip_device

  let sexp_of_t = sexp_of_hip_device

  let get_count () =
    let open Ctypes in
    let count = allocate int 0 in
    check "hip_get_device_count" @@ Hip.hip_get_device_count count;
    !@count

  let get ~ordinal =
    let open Ctypes in
    let device = allocate Hip_ffi.Types_generated.hip_device (Hip_device 0) in
    check "hip_device_get" @@ Hip.hip_device_get device ordinal;
    !@device

  let get_ordinal (Hip_device ordinal) = ordinal

  let primary_ctx_release device =
    check "hip_device_primary_ctx_release" @@ Hip.hip_device_primary_ctx_release device

  let primary_ctx_reset device =
    check "hip_device_primary_ctx_reset" @@ Hip.hip_device_primary_ctx_reset device

  let get_free_and_total_mem () =
    let open Ctypes in
    let free = allocate size_t Unsigned.Size_t.zero in
    let total = allocate size_t Unsigned.Size_t.zero in
    check "hip_mem_get_info" @@ Hip.hip_mem_get_info free total;
    (Unsigned.Size_t.to_int !@free, Unsigned.Size_t.to_int !@total)

  let total_mem device =
    let open Ctypes in
    let total = allocate size_t Unsigned.Size_t.zero in
    check "hip_device_total_mem" @@ Hip.hip_device_total_mem total device;
    Unsigned.Size_t.to_int !@total

  let set_current (Hip_device ordinal) = check "hip_set_device" @@ Hip.hip_set_device ordinal

  let get_current () =
    let open Ctypes in
    let ordinal = allocate int 0 in
    check "hip_get_device" @@ Hip.hip_get_device ordinal;
    Hip_device !@ordinal

  let can_access_peer ~dst:(Hip_device dst) ~src:(Hip_device src) =
    let open Ctypes in
    let can = allocate int 0 in
    check "hip_device_can_access_peer" @@ Hip.hip_device_can_access_peer can dst src;
    !@can <> 0

  (* Enables the current device to access memory of [peer]. *)
  let enable_peer_access ?(flags = 0) (Hip_device peer) =
    check "hip_device_enable_peer_access"
    @@ Hip.hip_device_enable_peer_access peer (Unsigned.UInt.of_int flags)

  let disable_peer_access (Hip_device peer) =
    check "hip_device_disable_peer_access" @@ Hip.hip_device_disable_peer_access peer

  type attributes = {
    name : string;
    gcn_arch_name : string;
    total_global_mem : int;
    shared_mem_per_block : int;
    regs_per_block : int;
    warp_size : int;
    max_threads_per_block : int;
    max_threads_dim : int * int * int;
    max_grid_size : int * int * int;
    clock_rate : int;
    total_const_mem : int;
    compute_capability_major : int;
    compute_capability_minor : int;
    multiprocessor_count : int;
    integrated : bool;
    can_map_host_memory : bool;
    compute_mode : int;
    concurrent_kernels : bool;
    pci_bus_id : int;
    pci_device_id : int;
    pci_domain_id : int;
    async_engine_count : int;
    unified_addressing : bool;
    memory_clock_rate : int;
    memory_bus_width : int;
    l2_cache_size : int;
    max_threads_per_multiprocessor : int;
    shared_mem_per_multiprocessor : int;
    managed_memory : bool;
    is_multi_gpu_board : bool;
    host_native_atomic_supported : bool;
    pageable_memory_access : bool;
    concurrent_managed_access : bool;
    cooperative_launch : bool;
    cooperative_multi_device_launch : bool;
    memory_pools_supported : bool;
    max_shared_memory_per_multiprocessor : int;
    clock_instruction_rate : int;
    is_large_bar : bool;
    asic_revision : int;
  }

  let sexp_of_attributes a =
    let open Sexplib0.Sexp in
    let entry name sexp = List [ Atom name; sexp ] in
    let int_entry name i = entry name (Atom (Int.to_string i)) in
    let bool_entry name b = entry name (sexp_of_bool b) in
    let triple_entry name (x, y, z) =
      entry name
        (List [ Atom (Int.to_string x); Atom (Int.to_string y); Atom (Int.to_string z) ])
    in
    List
      [
        entry "name" (Atom a.name);
        entry "gcn_arch_name" (Atom a.gcn_arch_name);
        int_entry "total_global_mem" a.total_global_mem;
        int_entry "shared_mem_per_block" a.shared_mem_per_block;
        int_entry "regs_per_block" a.regs_per_block;
        int_entry "warp_size" a.warp_size;
        int_entry "max_threads_per_block" a.max_threads_per_block;
        triple_entry "max_threads_dim" a.max_threads_dim;
        triple_entry "max_grid_size" a.max_grid_size;
        int_entry "clock_rate" a.clock_rate;
        int_entry "total_const_mem" a.total_const_mem;
        int_entry "compute_capability_major" a.compute_capability_major;
        int_entry "compute_capability_minor" a.compute_capability_minor;
        int_entry "multiprocessor_count" a.multiprocessor_count;
        bool_entry "integrated" a.integrated;
        bool_entry "can_map_host_memory" a.can_map_host_memory;
        int_entry "compute_mode" a.compute_mode;
        bool_entry "concurrent_kernels" a.concurrent_kernels;
        int_entry "pci_bus_id" a.pci_bus_id;
        int_entry "pci_device_id" a.pci_device_id;
        int_entry "pci_domain_id" a.pci_domain_id;
        int_entry "async_engine_count" a.async_engine_count;
        bool_entry "unified_addressing" a.unified_addressing;
        int_entry "memory_clock_rate" a.memory_clock_rate;
        int_entry "memory_bus_width" a.memory_bus_width;
        int_entry "l2_cache_size" a.l2_cache_size;
        int_entry "max_threads_per_multiprocessor" a.max_threads_per_multiprocessor;
        int_entry "shared_mem_per_multiprocessor" a.shared_mem_per_multiprocessor;
        bool_entry "managed_memory" a.managed_memory;
        bool_entry "is_multi_gpu_board" a.is_multi_gpu_board;
        bool_entry "host_native_atomic_supported" a.host_native_atomic_supported;
        bool_entry "pageable_memory_access" a.pageable_memory_access;
        bool_entry "concurrent_managed_access" a.concurrent_managed_access;
        bool_entry "cooperative_launch" a.cooperative_launch;
        bool_entry "cooperative_multi_device_launch" a.cooperative_multi_device_launch;
        bool_entry "memory_pools_supported" a.memory_pools_supported;
        int_entry "max_shared_memory_per_multiprocessor" a.max_shared_memory_per_multiprocessor;
        int_entry "clock_instruction_rate" a.clock_instruction_rate;
        bool_entry "is_large_bar" a.is_large_bar;
        int_entry "asic_revision" a.asic_revision;
      ]

  let get_attributes (Hip_device ordinal) =
    let open Ctypes in
    let module E = Hip_ffi.Types_generated in
    let props = make E.hip_device_prop in
    check "hip_get_device_properties" @@ Hip.hip_get_device_properties (addr props) ordinal;
    let geti field = getf props field in
    let getb field = getf props field <> 0 in
    let getsz field = Unsigned.Size_t.to_int @@ getf props field in
    let get3 field =
      let arr = getf props field in
      (CArray.get arr 0, CArray.get arr 1, CArray.get arr 2)
    in
    {
      name = string_from_carray (getf props E.prop_name);
      gcn_arch_name = string_from_carray (getf props E.prop_gcn_arch_name);
      total_global_mem = getsz E.prop_total_global_mem;
      shared_mem_per_block = getsz E.prop_shared_mem_per_block;
      regs_per_block = geti E.prop_regs_per_block;
      warp_size = geti E.prop_warp_size;
      max_threads_per_block = geti E.prop_max_threads_per_block;
      max_threads_dim = get3 E.prop_max_threads_dim;
      max_grid_size = get3 E.prop_max_grid_size;
      clock_rate = geti E.prop_clock_rate;
      total_const_mem = getsz E.prop_total_const_mem;
      compute_capability_major = geti E.prop_major;
      compute_capability_minor = geti E.prop_minor;
      multiprocessor_count = geti E.prop_multi_processor_count;
      integrated = getb E.prop_integrated;
      can_map_host_memory = getb E.prop_can_map_host_memory;
      compute_mode = geti E.prop_compute_mode;
      concurrent_kernels = getb E.prop_concurrent_kernels;
      pci_bus_id = geti E.prop_pci_bus_id;
      pci_device_id = geti E.prop_pci_device_id;
      pci_domain_id = geti E.prop_pci_domain_id;
      async_engine_count = geti E.prop_async_engine_count;
      unified_addressing = getb E.prop_unified_addressing;
      memory_clock_rate = geti E.prop_memory_clock_rate;
      memory_bus_width = geti E.prop_memory_bus_width;
      l2_cache_size = geti E.prop_l2_cache_size;
      max_threads_per_multiprocessor = geti E.prop_max_threads_per_multi_processor;
      shared_mem_per_multiprocessor = getsz E.prop_shared_mem_per_multiprocessor;
      managed_memory = getb E.prop_managed_memory;
      is_multi_gpu_board = getb E.prop_is_multi_gpu_board;
      host_native_atomic_supported = getb E.prop_host_native_atomic_supported;
      pageable_memory_access = getb E.prop_pageable_memory_access;
      concurrent_managed_access = getb E.prop_concurrent_managed_access;
      cooperative_launch = getb E.prop_cooperative_launch;
      cooperative_multi_device_launch = getb E.prop_cooperative_multi_device_launch;
      memory_pools_supported = getb E.prop_memory_pools_supported;
      max_shared_memory_per_multiprocessor =
        getsz E.prop_max_shared_memory_per_multi_processor;
      clock_instruction_rate = geti E.prop_clock_instruction_rate;
      is_large_bar = getb E.prop_is_large_bar;
      asic_revision = geti E.prop_asic_revision;
    }
end

let sexp_of_voidp ptr =
  Sexplib0.Sexp.Atom
    ("@" ^ Unsigned.UInt64.to_hexstring @@ Unsigned.UInt64.of_int64 @@ Int64.of_nativeint
   @@ Ctypes.raw_address_of_ptr ptr)

let sexp_of_hip_event (event : hip_event) = sexp_of_voidp @@ Ctypes.to_voidp event

type lifetime = Remember : 'a -> lifetime
type delimited_event = { event : hip_event; mutable is_released : bool }

let sexp_of_delimited_event { event; is_released } =
  Sexplib0.Sexp.List
    [
      Sexplib0.Sexp.List [ Sexplib0.Sexp.Atom "event"; sexp_of_hip_event event ];
      Sexplib0.Sexp.List [ Sexplib0.Sexp.Atom "is_released"; sexp_of_bool is_released ];
    ]

let destroy_event event = check "hip_event_destroy" @@ Hip.hip_event_destroy event
let sexp_of_hip_stream (hip_stream : hip_stream) = sexp_of_voidp @@ Ctypes.to_voidp hip_stream

type stream = {
  mutable args_lifetimes : (lifetime list[@sexp.opaque]);
  mutable owned_events : delimited_event list;
  stream : hip_stream;
  destroyed : atomic_bool;
}

let sexp_of_stream { args_lifetimes = _; owned_events; stream; destroyed } =
  Sexplib0.Sexp.List
    [
      Sexplib0.Sexp.List [ Sexplib0.Sexp.Atom "args_lifetimes"; Sexplib0.Sexp.Atom "<opaque>" ];
      Sexplib0.Sexp.List
        [ Sexplib0.Sexp.Atom "owned_events"; sexp_of_list sexp_of_delimited_event owned_events ];
      Sexplib0.Sexp.List [ Sexplib0.Sexp.Atom "stream"; sexp_of_hip_stream stream ];
      Sexplib0.Sexp.List [ Sexplib0.Sexp.Atom "destroyed"; sexp_of_atomic_bool destroyed ];
    ]

let query_event event =
  match Hip.hip_event_query event with
  | HIP_SUCCESS ->
      check "hip_event_query" HIP_SUCCESS;
      true
  | HIP_ERROR_NOT_READY ->
      check "hip_event_query" HIP_SUCCESS;
      false
  | error ->
      check "hip_event_query" error;
      false

let release_event event =
  if not event.is_released then (
    destroy_event event.event;
    event.is_released <- true)

(* Unlike CUDA, HIP does not require switching to the event's context before destroying it: the
   runtime tracks the owning device internally. *)
let release_stream stream =
  stream.args_lifetimes <- [];
  List.iter (fun event -> if not event.is_released then release_event event) stream.owned_events;
  stream.owned_events <- []

let no_stream =
  {
    args_lifetimes = [];
    owned_events = [];
    stream = Ctypes.(coerce (ptr void) hip_stream null);
    destroyed = Atomic.make false;
  }

module Context = struct
  type t = hip_context

  let sexp_of_t (ctx : t) = sexp_of_voidp @@ Ctypes.to_voidp ctx

  type flag =
    | SCHED_AUTO
    | SCHED_SPIN
    | SCHED_YIELD
    | SCHED_BLOCKING_SYNC
    | SCHED_MASK
    | MAP_HOST
    | LMEM_RESIZE_TO_MAX

  let sexp_of_flag = function
    | SCHED_AUTO -> Sexplib0.Sexp.Atom "SCHED_AUTO"
    | SCHED_SPIN -> Sexplib0.Sexp.Atom "SCHED_SPIN"
    | SCHED_YIELD -> Sexplib0.Sexp.Atom "SCHED_YIELD"
    | SCHED_BLOCKING_SYNC -> Sexplib0.Sexp.Atom "SCHED_BLOCKING_SYNC"
    | SCHED_MASK -> Sexplib0.Sexp.Atom "SCHED_MASK"
    | MAP_HOST -> Sexplib0.Sexp.Atom "MAP_HOST"
    | LMEM_RESIZE_TO_MAX -> Sexplib0.Sexp.Atom "LMEM_RESIZE_TO_MAX"

  type flags = flag list

  let sexp_of_flags = sexp_of_list sexp_of_flag

  let uint_of_flag f =
    let open Hip_ffi.Types_generated in
    match f with
    | SCHED_AUTO -> Unsigned.UInt.of_int64 hip_device_schedule_auto
    | SCHED_SPIN -> Unsigned.UInt.of_int64 hip_device_schedule_spin
    | SCHED_YIELD -> Unsigned.UInt.of_int64 hip_device_schedule_yield
    | SCHED_BLOCKING_SYNC -> Unsigned.UInt.of_int64 hip_device_schedule_blocking_sync
    | SCHED_MASK -> Unsigned.UInt.of_int64 hip_device_schedule_mask
    | MAP_HOST -> Unsigned.UInt.of_int64 hip_device_map_host
    | LMEM_RESIZE_TO_MAX -> Unsigned.UInt.of_int64 hip_device_lmem_resize_to_max

  let destroy ctx = check "hip_ctx_destroy" @@ Hip.hip_ctx_destroy ctx

  let create (flags : flags) device =
    let open Ctypes in
    let ctx = allocate_n hip_context ~count:1 in
    let open Unsigned.UInt in
    let flags = List.fold_left (fun flags flag -> Infix.(flags lor uint_of_flag flag)) zero flags in
    check "hip_ctx_create" @@ Hip.hip_ctx_create ctx flags device;
    let ctx = !@ctx in
    Stdlib.Gc.finalise destroy ctx;
    ctx

  let get_device () =
    let open Ctypes in
    let device = allocate Hip_ffi.Types_generated.hip_device (Hip_device 0) in
    check "hip_ctx_get_device" @@ Hip.hip_ctx_get_device device;
    !@device

  let pop_current () =
    let open Ctypes in
    let ctx = allocate_n hip_context ~count:1 in
    check "hip_ctx_pop_current" @@ Hip.hip_ctx_pop_current ctx;
    !@ctx

  let get_current () =
    let open Ctypes in
    let ctx = allocate_n hip_context ~count:1 in
    check "hip_ctx_get_current" @@ Hip.hip_ctx_get_current ctx;
    !@ctx

  let push_current ctx = check "hip_ctx_push_current" @@ Hip.hip_ctx_push_current ctx
  let set_current ctx = check "hip_ctx_set_current" @@ Hip.hip_ctx_set_current ctx

  let get_primary device =
    let open Ctypes in
    let ctx = allocate_n hip_context ~count:1 in
    check "hip_device_primary_ctx_retain" @@ Hip.hip_device_primary_ctx_retain ctx device;
    let ctx = !@ctx in
    Stdlib.Gc.finalise (fun _ -> Device.primary_ctx_release device) ctx;
    ctx

  (* Synchronizes the current device (HIP deprecates [hipCtxSynchronize]; for primary-context usage
     the semantics coincide). *)
  let synchronize () =
    check "hip_device_synchronize" @@ Hip.hip_device_synchronize ();
    release_stream no_stream

  type limit = STACK_SIZE | PRINTF_FIFO_SIZE | MALLOC_HEAP_SIZE

  let sexp_of_limit = function
    | STACK_SIZE -> Sexplib0.Sexp.Atom "STACK_SIZE"
    | PRINTF_FIFO_SIZE -> Sexplib0.Sexp.Atom "PRINTF_FIFO_SIZE"
    | MALLOC_HEAP_SIZE -> Sexplib0.Sexp.Atom "MALLOC_HEAP_SIZE"

  let hip_of_limit = function
    | STACK_SIZE -> HIP_LIMIT_STACK_SIZE
    | PRINTF_FIFO_SIZE -> HIP_LIMIT_PRINTF_FIFO_SIZE
    | MALLOC_HEAP_SIZE -> HIP_LIMIT_MALLOC_HEAP_SIZE

  (* Note: HIP limits are scoped to the current device rather than a context. *)
  let set_limit limit value =
    check "hip_device_set_limit"
    @@ Hip.hip_device_set_limit (hip_of_limit limit)
    @@ Unsigned.Size_t.of_int value

  let get_limit limit =
    let open Ctypes in
    let value = allocate size_t Unsigned.Size_t.zero in
    check "hip_device_get_limit" @@ Hip.hip_device_get_limit value (hip_of_limit limit);
    Unsigned.Size_t.to_int !@value
end

let bigarray_start_not_managed arr = Ctypes_bigarray.unsafe_address arr

let get_ptr_not_managed ~reftyp arr =
  (* Work around because Ctypes.bigarray_start doesn't support half precision. *)
  Ctypes_static.CPointer (Ctypes_memory.make_unmanaged ~reftyp @@ bigarray_start_not_managed arr)

(* Advance a device pointer by a byte [offset] for use at a single copy operation. For a zero
   [offset] the original [Deviceptr.t] is returned unchanged, so its finalizer-bearing block stays
   reachable through the copy. For a non-zero [offset] the result shares the original allocation's
   [freed] flag -- so [check_freed] still observes frees -- but carries no finalizer and is never
   returned to callers: the offset is applied at the copy and does not escape as a public,
   separately-freeable [Deviceptr.t]. Callers must keep the original value alive across the HIP
   call; the [memcpy_*_impl] helpers do so for the synchronous path via [Sys.opaque_identity]. *)
let offset_deviceptr dp offset =
  if offset = 0 then dp
  else
    let (Deviceptr { ptr; freed }) = dp in
    Deviceptr { ptr = Unsigned.UInt64.add ptr (Unsigned.UInt64.of_int offset); freed }

let memcpy_H_to_D_impl ?host_offset ?length ?(dst_offset = 0) ~dst ~src memcpy =
  let full_size = Bigarray.Genarray.size_in_bytes src in
  let elem_bytes = Bigarray.kind_size_in_bytes @@ Bigarray.Genarray.kind src in
  let size_in_bytes =
    match (host_offset, length) with
    (* When the size is derived from the full bigarray, a non-zero device [dst_offset] reduces it
       so the copy does not write past the end of a same-sized device allocation. *)
    | None, None -> full_size - dst_offset
    | Some _, None -> invalid_arg "Hipjit.memcpy_H_to_D: providing offset requires providing length"
    | _, Some length -> elem_bytes * length
  in
  let open Ctypes in
  let host =
    match host_offset with
    | None -> get_ptr_not_managed ~reftyp:void src
    | Some offset ->
        let host = get_ptr_not_managed ~reftyp:uint8_t src in
        coerce (ptr uint8_t) (ptr void) @@ (host +@ (offset * elem_bytes))
  in
  let result = memcpy ~dst:(offset_deviceptr dst dst_offset) ~src:host ~size_in_bytes in
  (* Keep the owning [dst] reachable across the synchronous copy: a non-zero [dst_offset] hands the
     callback a finalizer-less wrapper that shares only [dst]'s [freed] flag, so without this the
     GC could finalize and [hipFree] the original allocation mid-copy. *)
  ignore (Sys.opaque_identity dst : deviceptr);
  result

let memcpy_D_to_H_impl ?host_offset ?length ?(src_offset = 0) ~dst ~src memcpy =
  let full_size = Bigarray.Genarray.size_in_bytes dst in
  let elem_bytes = Bigarray.kind_size_in_bytes @@ Bigarray.Genarray.kind dst in
  let size_in_bytes =
    match (host_offset, length) with
    | None, None -> full_size - src_offset
    | Some offset, None -> full_size - (elem_bytes * offset) - src_offset
    (* [length] is a count of elements to copy -- not an end index. The copy fills
       [dst.(host_offset .. host_offset + length)] from the device. *)
    | None, Some length | Some _, Some length -> elem_bytes * length
  in
  let open Ctypes in
  let host =
    match host_offset with
    | None -> get_ptr_not_managed ~reftyp:void dst
    | Some offset ->
        let host = get_ptr_not_managed ~reftyp:uint8_t dst in
        let host = host +@ (offset * elem_bytes) in
        coerce (ptr uint8_t) (ptr void) host
  in
  let result = memcpy ~dst:host ~src:(offset_deviceptr src src_offset) ~size_in_bytes in
  (* Keep the owning [src] reachable across the synchronous copy; see [memcpy_H_to_D_impl]. *)
  ignore (Sys.opaque_identity src : deviceptr);
  result

let get_size_in_bytes ?kind ?length ?size_in_bytes provenance =
  match (size_in_bytes, kind, length) with
  | Some size, None, None -> size
  | None, Some kind, Some length ->
      let elem_bytes = Bigarray.kind_size_in_bytes kind in
      elem_bytes * length
  | Some _, Some _, Some _ ->
      invalid_arg @@ provenance
      ^ ": Too many arguments, provide either both [kind] and [length], or just [size_in_bytes]."
  | _ ->
      invalid_arg @@ provenance
      ^ ": Too few arguments, provide either both [kind] and [length], or just [size_in_bytes]."

module Deviceptr = struct
  type t = deviceptr
  type region = { base : t; offset_bytes : int }

  let offset ptr ~bytes = { base = ptr; offset_bytes = bytes }
  let region_of ptr = { base = ptr; offset_bytes = 0 }
  let sexp_of_t = sexp_of_deviceptr

  let equal (Deviceptr { ptr = ptr1; freed = _ }) (Deviceptr { ptr = ptr2; freed = _ }) =
    Unsigned.UInt64.equal ptr1 ptr2

  let hash (Deviceptr { ptr; freed = _ }) = Unsigned.UInt64.to_int ptr

  let string_of (Deviceptr { ptr; freed }) =
    let addr = string_of_memptr ptr in
    if Atomic.get freed then addr ^ "/FREED" else addr

  let mem_free (Deviceptr { ptr; freed }) =
    if Atomic.compare_and_set freed false true then
      check "hip_free" @@ Hip.hip_free @@ voidp_of_memptr ptr

  let mem_alloc ~size_in_bytes =
    let open Ctypes in
    let deviceptr = allocate_n hip_deviceptr ~count:1 in
    check "hip_malloc" @@ Hip.hip_malloc deviceptr @@ Unsigned.Size_t.of_int size_in_bytes;
    let result = Deviceptr { ptr = memptr_of_voidp !@deviceptr; freed = Atomic.make false } in
    Gc.finalise mem_free result;
    result

  let memcpy_H_to_D_unsafe ~dst:(Deviceptr { ptr = dst; freed }) ~(src : unit Ctypes.ptr)
      ~size_in_bytes =
    check_freed ~func:"Deviceptr.memcpy_H_to_D" [ ("dst", freed) ];
    check "hip_memcpy_H_to_D"
    @@ Hip.hip_memcpy_H_to_D (voidp_of_memptr dst) src
    @@ Unsigned.Size_t.of_int size_in_bytes

  let memcpy_H_to_D ?host_offset ?length ?dst_offset ~dst ~src () =
    memcpy_H_to_D_impl ?host_offset ?length ?dst_offset ~dst ~src memcpy_H_to_D_unsafe

  let alloc_and_memcpy src =
    let size_in_bytes = Bigarray.Genarray.size_in_bytes src in
    let dst = mem_alloc ~size_in_bytes in
    memcpy_H_to_D ~dst ~src ();
    dst

  let memcpy_D_to_H_unsafe ~(dst : unit Ctypes.ptr) ~src:(Deviceptr { ptr = src; freed })
      ~size_in_bytes =
    check_freed ~func:"Deviceptr.memcpy_D_to_H" [ ("src", freed) ];
    check "hip_memcpy_D_to_H"
    @@ Hip.hip_memcpy_D_to_H dst (voidp_of_memptr src)
    @@ Unsigned.Size_t.of_int size_in_bytes

  let memcpy_D_to_H ?host_offset ?length ?src_offset ~dst ~src () =
    memcpy_D_to_H_impl ?host_offset ?length ?src_offset ~dst ~src memcpy_D_to_H_unsafe

  let memcpy_D_to_D ?kind ?length ?size_in_bytes ?(dst_offset = 0) ?(src_offset = 0)
      ~dst:(Deviceptr { ptr = dst; freed = dst_freed })
      ~src:(Deviceptr { ptr = src; freed = src_freed }) () =
    check_freed ~func:"Deviceptr.memcpy_D_to_D" [ ("dst", dst_freed); ("src", src_freed) ];
    let size_in_bytes = get_size_in_bytes ?kind ?length ?size_in_bytes "memcpy_D_to_D" in
    let dst = Unsigned.UInt64.add dst (Unsigned.UInt64.of_int dst_offset) in
    let src = Unsigned.UInt64.add src (Unsigned.UInt64.of_int src_offset) in
    check "hip_memcpy_D_to_D"
    @@ Hip.hip_memcpy_D_to_D (voidp_of_memptr dst) (voidp_of_memptr src)
    @@ Unsigned.Size_t.of_int size_in_bytes

  (** Provide either both [kind] and [length], or just [size_in_bytes]. *)
  let memcpy_peer ?kind ?length ?size_in_bytes ?(dst_offset = 0) ?(src_offset = 0)
      ~dst:(Deviceptr { ptr = dst; freed = dst_freed }) ~dst_device
      ~src:(Deviceptr { ptr = src; freed = src_freed }) ~src_device () =
    check_freed ~func:"Deviceptr.memcpy_peer" [ ("dst", dst_freed); ("src", src_freed) ];
    let size_in_bytes = get_size_in_bytes ?kind ?length ?size_in_bytes "memcpy_peer" in
    let dst = Unsigned.UInt64.add dst (Unsigned.UInt64.of_int dst_offset) in
    let src = Unsigned.UInt64.add src (Unsigned.UInt64.of_int src_offset) in
    check "hip_memcpy_peer"
    @@ Hip.hip_memcpy_peer (voidp_of_memptr dst) (Device.get_ordinal dst_device)
         (voidp_of_memptr src) (Device.get_ordinal src_device)
    @@ Unsigned.Size_t.of_int size_in_bytes

  let memset_d8 ?(offset = 0) (Deviceptr { ptr; freed }) v ~length =
    check_freed ~func:"Deviceptr.memset_d8" [ ("ptr", freed) ];
    let ptr = Unsigned.UInt64.add ptr (Unsigned.UInt64.of_int offset) in
    check "hip_memset_d8"
    @@ Hip.hip_memset_d8 (voidp_of_memptr ptr) v
    @@ Unsigned.Size_t.of_int length

  let memset_d16 ?(offset = 0) (Deviceptr { ptr; freed }) v ~length =
    check_freed ~func:"Deviceptr.memset_d16" [ ("ptr", freed) ];
    let ptr = Unsigned.UInt64.add ptr (Unsigned.UInt64.of_int offset) in
    check "hip_memset_d16"
    @@ Hip.hip_memset_d16 (voidp_of_memptr ptr) v
    @@ Unsigned.Size_t.of_int length

  let memset_d32 ?(offset = 0) (Deviceptr { ptr; freed }) v ~length =
    check_freed ~func:"Deviceptr.memset_d32" [ ("ptr", freed) ];
    let ptr = Unsigned.UInt64.add ptr (Unsigned.UInt64.of_int offset) in
    check "hip_memset_d32"
    @@ Hip.hip_memset_d32 (voidp_of_memptr ptr) v
    @@ Unsigned.Size_t.of_int length
end

module Module = struct
  type t = hip_module

  (* The function retains its module, so that the module's unload-on-GC finalizer cannot fire
     while a kernel extracted from it is still reachable. *)
  type func = { func : hip_function; owning_module : t }

  let sexp_of_t (module_ : t) = sexp_of_voidp @@ Ctypes.to_voidp module_

  let sexp_of_func { func; owning_module } =
    Sexplib0.Sexp.List
      [
        Sexplib0.Sexp.List [ Sexplib0.Sexp.Atom "func"; sexp_of_voidp @@ Ctypes.to_voidp func ];
        Sexplib0.Sexp.List [ Sexplib0.Sexp.Atom "owning_module"; sexp_of_t owning_module ];
      ]

  (* Note: on the AMD platform, [hipModuleLoadDataEx] ignores most JIT options; they are accepted
     for CUDA-driver-API compatibility. *)
  type jit_option =
    | MAX_REGISTERS of int
    | THREADS_PER_BLOCK of int
    | OPTIMIZATION_LEVEL of int
    | GENERATE_DEBUG_INFO of bool
    | LOG_VERBOSE of bool
    | GENERATE_LINE_INFO of bool
    | FAST_COMPILE of bool
    | POSITION_INDEPENDENT_CODE of bool
    | MIN_CTA_PER_SM of int
    | MAX_THREADS_PER_BLOCK of int

  let sexp_of_jit_option =
    let open Sexplib0.Sexp in
    function
    | MAX_REGISTERS i -> List [ Atom "MAX_REGISTERS"; Atom (Int.to_string i) ]
    | THREADS_PER_BLOCK i -> List [ Atom "THREADS_PER_BLOCK"; Atom (Int.to_string i) ]
    | OPTIMIZATION_LEVEL i -> List [ Atom "OPTIMIZATION_LEVEL"; Atom (Int.to_string i) ]
    | GENERATE_DEBUG_INFO b -> List [ Atom "GENERATE_DEBUG_INFO"; sexp_of_bool b ]
    | LOG_VERBOSE b -> List [ Atom "LOG_VERBOSE"; sexp_of_bool b ]
    | GENERATE_LINE_INFO b -> List [ Atom "GENERATE_LINE_INFO"; sexp_of_bool b ]
    | FAST_COMPILE b -> List [ Atom "FAST_COMPILE"; sexp_of_bool b ]
    | POSITION_INDEPENDENT_CODE b -> List [ Atom "POSITION_INDEPENDENT_CODE"; sexp_of_bool b ]
    | MIN_CTA_PER_SM i -> List [ Atom "MIN_CTA_PER_SM"; Atom (Int.to_string i) ]
    | MAX_THREADS_PER_BLOCK i -> List [ Atom "MAX_THREADS_PER_BLOCK"; Atom (Int.to_string i) ]

  let unload module_ = check "hip_module_unload" @@ Hip.hip_module_unload module_

  let load_data_ex code options =
    let open Ctypes in
    let hip_mod = allocate_n hip_module ~count:1 in
    let n_opts = List.length options in
    let c_options =
      CArray.of_list Hip_ffi.Types_generated.hip_jit_option
      @@ List.map
           (function
             | MAX_REGISTERS _ -> HIP_JIT_OPTION_MAX_REGISTERS
             | THREADS_PER_BLOCK _ -> HIP_JIT_OPTION_THREADS_PER_BLOCK
             | OPTIMIZATION_LEVEL _ -> HIP_JIT_OPTION_OPTIMIZATION_LEVEL
             | GENERATE_DEBUG_INFO _ -> HIP_JIT_OPTION_GENERATE_DEBUG_INFO
             | LOG_VERBOSE _ -> HIP_JIT_OPTION_LOG_VERBOSE
             | GENERATE_LINE_INFO _ -> HIP_JIT_OPTION_GENERATE_LINE_INFO
             | FAST_COMPILE _ -> HIP_JIT_OPTION_FAST_COMPILE
             | POSITION_INDEPENDENT_CODE _ -> HIP_JIT_OPTION_POSITION_INDEPENDENT_CODE
             | MIN_CTA_PER_SM _ -> HIP_JIT_OPTION_MIN_CTA_PER_SM
             | MAX_THREADS_PER_BLOCK _ -> HIP_JIT_OPTION_MAX_THREADS_PER_BLOCK)
           options
    in
    (* Per the CUDA driver API convention, scalar option values are cast to [void*] directly. *)
    let i2vp i = ptr_of_raw_address @@ Nativeint.of_int i in
    let b2vp b = i2vp (if b then 1 else 0) in
    let c_opts_args =
      CArray.of_list (ptr void)
      @@ List.map
           (function
             | MAX_REGISTERS v | THREADS_PER_BLOCK v | OPTIMIZATION_LEVEL v | MIN_CTA_PER_SM v
             | MAX_THREADS_PER_BLOCK v ->
                 i2vp v
             | GENERATE_DEBUG_INFO b | LOG_VERBOSE b | GENERATE_LINE_INFO b | FAST_COMPILE b
             | POSITION_INDEPENDENT_CODE b ->
                 b2vp b)
           options
    in
    check "hip_module_load_data_ex"
    @@ Hip.hip_module_load_data_ex hip_mod
         (coerce (ptr char) (ptr void) code.Hiprtc.code)
         (Unsigned.UInt.of_int n_opts) (CArray.start c_options)
    @@ CArray.start c_opts_args;
    let result = !@hip_mod in
    Gc.finalise unload result;
    result

  let load_data code = load_data_ex code []

  let get_function module_ ~name =
    let open Ctypes in
    let func = allocate_n hip_function ~count:1 in
    check "hip_module_get_function" @@ Hip.hip_module_get_function func module_ name;
    { func = !@func; owning_module = module_ }

  let get_global module_ ~name =
    let open Ctypes in
    let devptr = allocate_n hip_deviceptr ~count:1 in
    let size_in_bytes = allocate size_t Unsigned.Size_t.zero in
    check "hip_module_get_global" @@ Hip.hip_module_get_global devptr size_in_bytes module_ name;
    (Deviceptr { ptr = memptr_of_voidp !@devptr; freed = Atomic.make false }, !@size_in_bytes)
end

module Stream = struct
  type t = stream

  let sexp_of_t = sexp_of_stream

  let mem_free stream (Deviceptr { ptr; freed }) =
    if Atomic.compare_and_set freed false true then
      check "hip_free_async" @@ Hip.hip_free_async (voidp_of_memptr ptr) stream.stream

  let mem_alloc stream ~size_in_bytes =
    let open Ctypes in
    let deviceptr = allocate_n hip_deviceptr ~count:1 in
    check "hip_malloc_async"
    @@ Hip.hip_malloc_async deviceptr (Unsigned.Size_t.of_int size_in_bytes) stream.stream;
    let result = Deviceptr { ptr = memptr_of_voidp !@deviceptr; freed = Atomic.make false } in
    Gc.finalise (mem_free stream) result;
    result

  let memcpy_H_to_D_unsafe ~dst:(Deviceptr { ptr = dst; freed }) ~(src : unit Ctypes.ptr)
      ~size_in_bytes stream =
    check_freed ~func:"Stream.memcpy_H_to_D" [ ("dst", freed) ];
    check "hip_memcpy_H_to_D_async"
    @@ Hip.hip_memcpy_H_to_D_async (voidp_of_memptr dst) src
         (Unsigned.Size_t.of_int size_in_bytes)
         stream.stream

  let memcpy_H_to_D ?host_offset ?length ?dst_offset ~dst ~src =
    memcpy_H_to_D_impl ?host_offset ?length ?dst_offset ~dst ~src memcpy_H_to_D_unsafe

  type size_t = Unsigned.size_t

  let sexp_of_size_t i = Sexplib0.Sexp.Atom (Unsigned.Size_t.to_string i)

  type kernel_param =
    | Tensor of Deviceptr.t
    | Tensor_at of Deviceptr.region
    | Int of int
    | Size_t of size_t
    | Single of float
    | Double of float

  let sexp_of_kernel_param =
    let open Sexplib0.Sexp in
    function
    | Tensor t -> List [ Atom "Tensor"; Deviceptr.sexp_of_t t ]
    | Tensor_at { Deviceptr.base; offset_bytes } ->
        List
          [
            Atom "Tensor_at";
            List
              [
                Deviceptr.sexp_of_t base;
                List [ Atom "offset_bytes"; Atom (Int.to_string offset_bytes) ];
              ];
          ]
    | Int i -> List [ Atom "Int"; Atom (Int.to_string i) ]
    | Size_t s -> List [ Atom "Size_t"; sexp_of_size_t s ]
    | Single f -> List [ Atom "Single"; Atom (Float.to_string f) ]
    | Double f -> List [ Atom "Double"; Atom (Float.to_string f) ]

  let no_stream = no_stream

  let total_unreleased_unfinished_delimited_events stream =
    List.fold_left
      (fun (tot, unr, unf) e ->
        ( tot + 1,
          (if not e.is_released then unr + 1 else unr),
          if (not e.is_released) && query_event e.event then unf + 1 else unf ))
      (0, 0, 0) stream.owned_events

  let launch_kernel func ~grid_dim_x ?(grid_dim_y = 1) ?(grid_dim_z = 1) ~block_dim_x
      ?(block_dim_y = 1) ?(block_dim_z = 1) ~shared_mem_bytes stream kernel_params =
    let orig_params = kernel_params in
    let i2u = Unsigned.UInt.of_int in
    let open Ctypes in
    let p = ptr in
    let c_params =
      List.mapi
        (fun i -> function
          | Tensor (Deviceptr { ptr; freed }) ->
              check_freed ~func:"Stream.launch_kernel"
                [ ("kernel (from 0) parameter " ^ Int.to_string i, freed) ];
              coerce (p (p void)) (p void) @@ allocate (p void) (voidp_of_memptr ptr)
          | Tensor_at { Deviceptr.base = Deviceptr { ptr; freed }; offset_bytes } ->
              check_freed ~func:"Stream.launch_kernel"
                [ ("kernel (from 0) parameter " ^ Int.to_string i ^ " (base)", freed) ];
              let ptr = Unsigned.UInt64.add ptr (Unsigned.UInt64.of_int offset_bytes) in
              coerce (p (p void)) (p void) @@ allocate (p void) (voidp_of_memptr ptr)
          | Int i -> coerce (p int) (p void) @@ allocate int i
          | Size_t u -> coerce (p size_t) (p void) @@ allocate size_t u
          | Single u -> coerce (p float) (p void) @@ allocate float u
          | Double u -> coerce (p double) (p void) @@ allocate double u)
        kernel_params
    in
    let c_kernel_params = c_params |> CArray.of_list (p void) in
    check "hip_module_launch_kernel"
    @@ Hip.hip_module_launch_kernel func.Module.func (i2u grid_dim_x) (i2u grid_dim_y)
         (i2u grid_dim_z) (i2u block_dim_x) (i2u block_dim_y) (i2u block_dim_z)
         (i2u shared_mem_bytes) stream.stream
         (CArray.start c_kernel_params)
    @@ coerce (p void) (p @@ ptr void) null;
    (* [func] is retained so the kernel's module is not unloaded while the launch is queued. *)
    stream.args_lifetimes <-
      Remember (func, orig_params, c_params, c_kernel_params) :: stream.args_lifetimes

  let uint_of_hip_stream_flags ~non_blocking =
    let open Hip_ffi.Types_generated in
    match non_blocking with
    | false -> Unsigned.UInt.of_int64 hip_stream_default
    | true -> Unsigned.UInt.of_int64 hip_stream_non_blocking

  let total_live_streams = Atomic.make 0
  let get_total_live_streams () = Atomic.get total_live_streams

  (* Idempotent, because it is both part of the public API and a GC finalizer: only the first
     call destroys the stream. *)
  let destroy stream =
    if Atomic.compare_and_set stream.destroyed false true then (
      (* hipStreamDestroy returns immediately when work is pending, so args_lifetimes must stay
         alive until all queued GPU work completes. Synchronize first, then release. *)
      (try check "hip_stream_synchronize" @@ Hip.hip_stream_synchronize stream.stream
       with Hip_error _ -> ());
      release_stream stream;
      Atomic.decr total_live_streams;
      check "hip_stream_destroy" @@ Hip.hip_stream_destroy stream.stream)

  let create ?(non_blocking = false) ?(lower_priority = 0) () =
    let open Ctypes in
    let stream = allocate_n hip_stream ~count:1 in
    Atomic.incr total_live_streams;
    check "hip_stream_create_with_priority"
    @@ Hip.hip_stream_create_with_priority stream
         (uint_of_hip_stream_flags ~non_blocking)
         lower_priority;
    let stream =
      {
        args_lifetimes = [];
        owned_events = [];
        stream = !@stream;
        destroyed = Atomic.make false;
      }
    in
    Stdlib.Gc.finalise destroy stream;
    stream

  let get_device stream =
    let open Ctypes in
    let device = allocate Hip_ffi.Types_generated.hip_device (Hip_device 0) in
    check "hip_stream_get_device" @@ Hip.hip_stream_get_device stream.stream device;
    !@device

  let get_device_id stream = Hip.hip_get_stream_device_id stream.stream

  let is_ready stream =
    match Hip.hip_stream_query stream.stream with
    | HIP_ERROR_NOT_READY ->
        check "hip_stream_query" HIP_SUCCESS;
        false
    | e ->
        check "hip_stream_query" e;
        (* We do not destroy delimited events, but any kernel arguments no longer needed. *)
        stream.args_lifetimes <- [];
        true

  let synchronize stream =
    check "hip_stream_synchronize" @@ Hip.hip_stream_synchronize stream.stream;
    release_stream stream

  let memcpy_D_to_H_unsafe ~(dst : unit Ctypes.ptr) ~src:(Deviceptr { ptr = src; freed })
      ~size_in_bytes stream =
    check_freed ~func:"Stream.memcpy_D_to_H" [ ("src", freed) ];
    check "hip_memcpy_D_to_H_async"
    @@ Hip.hip_memcpy_D_to_H_async dst (voidp_of_memptr src)
         (Unsigned.Size_t.of_int size_in_bytes)
         stream.stream

  let memcpy_D_to_H ?host_offset ?length ?src_offset ~dst ~src =
    memcpy_D_to_H_impl ?host_offset ?length ?src_offset ~dst ~src memcpy_D_to_H_unsafe

  let memcpy_D_to_D ?kind ?length ?size_in_bytes ?(dst_offset = 0) ?(src_offset = 0)
      ~dst:(Deviceptr { ptr = dst; freed = dst_freed })
      ~src:(Deviceptr { ptr = src; freed = src_freed }) stream =
    check_freed ~func:"Stream.memcpy_D_to_D" [ ("dst", dst_freed); ("src", src_freed) ];
    let size_in_bytes = get_size_in_bytes ?kind ?length ?size_in_bytes "memcpy_D_to_D_async" in
    let dst = Unsigned.UInt64.add dst (Unsigned.UInt64.of_int dst_offset) in
    let src = Unsigned.UInt64.add src (Unsigned.UInt64.of_int src_offset) in
    check "hip_memcpy_D_to_D_async"
    @@ Hip.hip_memcpy_D_to_D_async (voidp_of_memptr dst) (voidp_of_memptr src)
         (Unsigned.Size_t.of_int size_in_bytes)
         stream.stream

  (** Provide either both [kind] and [length], or just [size_in_bytes]. *)
  let memcpy_peer ?kind ?length ?size_in_bytes ?(dst_offset = 0) ?(src_offset = 0)
      ~dst:(Deviceptr { ptr = dst; freed = dst_freed }) ~dst_device
      ~src:(Deviceptr { ptr = src; freed = src_freed }) ~src_device stream =
    check_freed ~func:"Stream.memcpy_peer" [ ("dst", dst_freed); ("src", src_freed) ];
    let size_in_bytes = get_size_in_bytes ?kind ?length ?size_in_bytes "memcpy_peer_async" in
    let dst = Unsigned.UInt64.add dst (Unsigned.UInt64.of_int dst_offset) in
    let src = Unsigned.UInt64.add src (Unsigned.UInt64.of_int src_offset) in
    check "hip_memcpy_peer_async"
    @@ Hip.hip_memcpy_peer_async (voidp_of_memptr dst)
         (Device.get_ordinal dst_device)
         (voidp_of_memptr src)
         (Device.get_ordinal src_device)
         (Unsigned.Size_t.of_int size_in_bytes)
         stream.stream

  let memset_d8 ?(offset = 0) (Deviceptr { ptr; freed }) v ~length stream =
    check_freed ~func:"Stream.memset_d8" [ ("ptr", freed) ];
    let ptr = Unsigned.UInt64.add ptr (Unsigned.UInt64.of_int offset) in
    check "hip_memset_d8_async"
    @@ Hip.hip_memset_d8_async (voidp_of_memptr ptr) v (Unsigned.Size_t.of_int length)
         stream.stream

  let memset_d16 ?(offset = 0) (Deviceptr { ptr; freed }) v ~length stream =
    check_freed ~func:"Stream.memset_d16" [ ("ptr", freed) ];
    let ptr = Unsigned.UInt64.add ptr (Unsigned.UInt64.of_int offset) in
    check "hip_memset_d16_async"
    @@ Hip.hip_memset_d16_async (voidp_of_memptr ptr) v (Unsigned.Size_t.of_int length)
         stream.stream

  let memset_d32 ?(offset = 0) (Deviceptr { ptr; freed }) v ~length stream =
    check_freed ~func:"Stream.memset_d32" [ ("ptr", freed) ];
    let ptr = Unsigned.UInt64.add ptr (Unsigned.UInt64.of_int offset) in
    check "hip_memset_d32_async"
    @@ Hip.hip_memset_d32_async (voidp_of_memptr ptr) v (Unsigned.Size_t.of_int length)
         stream.stream
end

module Event = struct
  type t = hip_event

  let sexp_of_t = sexp_of_hip_event

  let uint_of_hip_event_flags ~blocking_sync ~enable_timing ~interprocess =
    let open Hip_ffi.Types_generated in
    let open Unsigned.UInt in
    let default = of_int64 hip_event_default in
    let blocking_sync = if blocking_sync then of_int64 hip_event_blocking_sync else zero in
    let disable_timing = if enable_timing then zero else of_int64 hip_event_disable_timing in
    let interprocess = if interprocess then of_int64 hip_event_interprocess else zero in
    List.fold_left
      (fun flags flag -> Infix.(flags lor flag))
      default
      [ blocking_sync; disable_timing; interprocess ]

  let destroy event = destroy_event event

  let create_event ?(blocking_sync = false) ?(enable_timing = false) ?(interprocess = false) () =
    let open Ctypes in
    let event = allocate_n hip_event ~count:1 in
    check "hip_event_create_with_flags"
    @@ Hip.hip_event_create_with_flags event
         (uint_of_hip_event_flags ~blocking_sync ~enable_timing ~interprocess);
    !@event

  let create ?blocking_sync ?enable_timing ?interprocess () =
    let event = create_event ?blocking_sync ?enable_timing ?interprocess () in
    Gc.finalise destroy event;
    event

  let elapsed_time ~start ~end_ =
    let open Ctypes in
    let result = allocate float 0.0 in
    check "hip_event_elapsed_time" @@ Hip.hip_event_elapsed_time result start end_;
    !@result

  let query = query_event
  let record event stream = check "hip_event_record" @@ Hip.hip_event_record event stream.stream
  let synchronize event = check "hip_event_synchronize" @@ Hip.hip_event_synchronize event

  let wait stream event =
    check "hip_stream_wait_event"
    @@ Hip.hip_stream_wait_event stream.stream event Unsigned.UInt.zero
end

module Delimited_event = struct
  type t = delimited_event

  let sexp_of_t = sexp_of_delimited_event
  let query event = if event.is_released then true else Event.query event.event

  let record ?blocking_sync ?interprocess stream =
    let event = Event.create_event ?blocking_sync ~enable_timing:false ?interprocess () in
    Event.record event stream;
    let result = { event; is_released = false } in
    stream.owned_events <- result :: stream.owned_events;
    result

  let synchronize event =
    if not event.is_released then (
      Event.synchronize event.event;
      release_event event)

  let wait stream event = if not event.is_released then Event.wait stream event.event
  let is_released event = event.is_released
end
