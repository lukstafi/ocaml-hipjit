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
  Hip.init ();
  let num_devices = Hip.Device.get_count () in
  Printf.printf "at least one device: %b\n%!" (num_devices > 0);
  let device = Hip.Device.get ~ordinal:0 in
  let attrs = Hip.Device.get_attributes device in
  Printf.printf "device name non-empty: %b\n%!" (String.length attrs.Hip.Device.name > 0);
  Printf.printf "gcn arch name is gfx*: %b\n%!"
    (String.length attrs.Hip.Device.gcn_arch_name >= 3
    && String.sub attrs.Hip.Device.gcn_arch_name 0 3 = "gfx");
  Printf.printf "positive max threads per block: %b\n%!" (attrs.Hip.Device.max_threads_per_block > 0);
  Printf.printf "positive multiprocessor count: %b\n%!" (attrs.Hip.Device.multiprocessor_count > 0);
  Printf.printf "positive warp size: %b\n%!" (attrs.Hip.Device.warp_size > 0);
  let ctx = Hip.Context.get_primary device in
  Hip.Context.set_current ctx;
  let free_mem, total_mem = Hip.Device.get_free_and_total_mem () in
  Printf.printf "positive free and total memory: %b\n%!" (free_mem > 0 && total_mem >= free_mem);
  let code =
    Hiprtc.compile_to_code ~hip_src:kernel ~name:"saxpy.hip"
      ~options:[ "-ffast-math" ] ~with_debug:false
  in
  let module_ = Hip.Module.load_data_ex code [ Hip.Module.GENERATE_LINE_INFO true ] in
  let saxpy = Hip.Module.get_function module_ ~name:"saxpy" in
  let stream = Hip.Stream.create ~non_blocking:true () in
  let n = 1024 in
  let a = 2.0 in
  let x = Bigarray.Genarray.create Bigarray.float32 Bigarray.c_layout [| n |] in
  let y = Bigarray.Genarray.create Bigarray.float32 Bigarray.c_layout [| n |] in
  for i = 0 to n - 1 do
    Bigarray.Genarray.set x [| i |] (Float.of_int i);
    Bigarray.Genarray.set y [| i |] (Float.of_int (2 * i))
  done;
  let size_in_bytes = n * 4 in
  let dx = Hip.Deviceptr.mem_alloc ~size_in_bytes in
  let dy = Hip.Deviceptr.mem_alloc ~size_in_bytes in
  let dout = Hip.Deviceptr.mem_alloc ~size_in_bytes in
  Hip.Stream.memcpy_H_to_D ~dst:dx ~src:x stream;
  Hip.Stream.memcpy_H_to_D ~dst:dy ~src:y stream;
  Hip.Stream.memset_d8 dout Unsigned.UChar.zero ~length:size_in_bytes stream;
  let block_dim_x = 128 in
  let grid_dim_x = (n + block_dim_x - 1) / block_dim_x in
  Hip.Stream.launch_kernel saxpy ~grid_dim_x ~block_dim_x ~shared_mem_bytes:0 stream
    Hip.Stream.
      [
        Single a; Tensor dx; Tensor dy; Tensor dout; Size_t (Unsigned.Size_t.of_int n);
      ];
  let after_launch = Hip.Delimited_event.record stream in
  Printf.printf "event not released after record: %b\n%!"
    (not @@ Hip.Delimited_event.is_released after_launch);
  Hip.Delimited_event.synchronize after_launch;
  Printf.printf "event released after synchronize: %b\n%!"
    (Hip.Delimited_event.is_released after_launch);
  let out = Bigarray.Genarray.create Bigarray.float32 Bigarray.c_layout [| n |] in
  Hip.Stream.memcpy_D_to_H ~dst:out ~src:dout stream;
  Hip.Stream.synchronize stream;
  let ok = ref true in
  for i = 0 to n - 1 do
    let expected = (a *. Float.of_int i) +. Float.of_int (2 * i) in
    if Bigarray.Genarray.get out [| i |] <> expected then ok := false
  done;
  Printf.printf "saxpy results correct: %b\n%!" !ok;
  (* Device-to-device copy, then read back and check again. *)
  let dcopy = Hip.Deviceptr.mem_alloc ~size_in_bytes in
  Hip.Stream.memcpy_D_to_D ~size_in_bytes ~dst:dcopy ~src:dout stream;
  let out2 = Bigarray.Genarray.create Bigarray.float32 Bigarray.c_layout [| n |] in
  Hip.Stream.memcpy_D_to_H ~dst:out2 ~src:dcopy stream;
  Hip.Stream.synchronize stream;
  let ok2 = ref true in
  for i = 0 to n - 1 do
    if Bigarray.Genarray.get out2 [| i |] <> Bigarray.Genarray.get out [| i |] then ok2 := false
  done;
  Printf.printf "device-to-device copy correct: %b\n%!" !ok2;
  (* Offset copies: copy the second half of [dout] into the first half of [dcopy]. *)
  Hip.Stream.memcpy_D_to_D ~size_in_bytes:(size_in_bytes / 2) ~src_offset:(size_in_bytes / 2)
    ~dst:dcopy ~src:dout stream;
  let out3 = Bigarray.Genarray.create Bigarray.float32 Bigarray.c_layout [| n / 2 |] in
  Hip.Stream.memcpy_D_to_H ~length:(n / 2) ~dst:out3 ~src:dcopy stream;
  Hip.Stream.synchronize stream;
  let ok3 = ref true in
  for i = 0 to (n / 2) - 1 do
    if Bigarray.Genarray.get out3 [| i |] <> Bigarray.Genarray.get out [| i + (n / 2) |] then
      ok3 := false
  done;
  Printf.printf "offset device-to-device copy correct: %b\n%!" !ok3;
  Hip.Deviceptr.mem_free dx;
  Hip.Deviceptr.mem_free dy;
  Hip.Deviceptr.mem_free dout;
  Hip.Deviceptr.mem_free dcopy;
  (* Use-after-free must be caught. *)
  (try
     Hip.Stream.memcpy_D_to_H ~dst:out ~src:dout stream;
     Printf.printf "use after free not detected!\n%!"
   with Hip.Use_after_free _ -> Printf.printf "use after free detected: true\n%!");
  Hip.Stream.synchronize stream;
  Hip.Context.synchronize ();
  Printf.printf "OK\n%!"
