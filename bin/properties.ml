(* Dumps the attributes of all visible HIP devices as s-expressions. *)
let () =
  Hip.init ();
  let num_devices = Hip.Device.get_count () in
  Printf.printf "%d HIP device(s), hiprtc version %s\n%!" num_devices
    (let major, minor = Hiprtc.version () in
     Printf.sprintf "%d.%d" major minor);
  for ordinal = 0 to num_devices - 1 do
    let device = Hip.Device.get ~ordinal in
    let attributes = Hip.Device.get_attributes device in
    Format.printf "@[<v 2>Device %d:@ %a@]@." ordinal Sexplib0.Sexp.pp_hum
      (Hip.Device.sexp_of_attributes attributes)
  done
