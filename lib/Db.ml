open Lwt
open Ezpostgresql

exception Foo of string

let create_connection ~host ?(port = 5432) () =
  let open Lwt_result.Infix in
  connect ~conninfo:(Printf.sprintf "host=%s port=%d user=postgres password=postgres" host port) ()

let insert ~conn ~query ~params = Ezpostgresql.command ~query ~params conn
