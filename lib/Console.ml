let green (s : string) = ANSITerminal.(sprintf [ green ] "%s" s)

let red (s : string) = ANSITerminal.(sprintf [ red ] "%s" s)

let logger s =
  print_string s;
  Core.Out_channel.flush stdout

let log = logger

let exn e =
  let msg = Core.Exn.to_string e in
  logger @@ red msg
