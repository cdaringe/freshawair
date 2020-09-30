open Lwt
open Ezpostgresql

exception Foo of string

let create_connection ~host ?(port = 5432) ?(user = "postgres")
    ?(password = "postgres") () =
  let open Lwt_result.Infix in
  connect
    ~conninfo:
      (Printf.sprintf "host=%s port=%d user=%s password=%s" host port user
         password)
    ()

let insert ~conn ~query ~params = Ezpostgresql.command ~query ~params conn
