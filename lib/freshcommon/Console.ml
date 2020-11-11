let logger s =
  print_string @@ s ^ "\n";
  Core.Out_channel.flush stdout

let error s =
  Printf.eprintf "%s" s;
  Core.Out_channel.flush stderr

let log = logger
