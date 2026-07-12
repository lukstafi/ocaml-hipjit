(* On Windows, amdhip64_*.dll prints a banner line "HIP Library Path: ..." to stdout when it
   loads; drop it so test outputs are stable across machines and platforms. *)
let () =
  try
    while true do
      let line = input_line stdin in
      if not (String.length line >= 17 && String.sub line 0 17 = "HIP Library Path:") then
        print_endline line
    done
  with End_of_file -> ()
