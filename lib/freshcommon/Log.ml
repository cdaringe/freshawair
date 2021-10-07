type log_message = { timestamp : string; message : string; level : int }
[@@deriving yojson { exn = true }]

type log_format = Plain | Json

exception Invald_log_format of string [@@deriving sexp]

let log_format_from_str = function
  | "json" -> `Json
  | "plain" -> `Plain
  | str ->
      raise
        (Invald_log_format
           (Printf.sprintf "invalid log level found in env: %s" str))

let active_log_format =
  Sys.getenv_opt "LOG_FORMAT" |> function
  | Some str -> log_format_from_str str
  | None -> `Json

(* https://en.wikipedia.org/wiki/Syslog#Severity_level *)
let log ~(level : int) ?(transport = Console.log) (message : string) =
  log_message_to_yojson
    { timestamp = ODate.Unix.(Printer.to_iso @@ now ()); message; level }
  |> Yojson.Safe.to_string |> transport

let error = log ~level:3 ~transport:Console.error

let exn e = log ~level:3 ~transport:Console.error @@ Printexc.to_string e

let warn = log ~level:4

let info = log ~level:6

let debug = log ~level:7
