let create_pg_connection ~host ?(port = 5432) ?(user = "postgres")
    ?(password = "postgres") () =
  let open Lwt_result.Infix in
  Ezpostgresql.connect
    ~conninfo:
      (Printf.sprintf "host=%s port=%d user=%s password=%s" host port user
         password)
    ()

let unpack = function
  | Ok x -> x
  | Error e -> failwith @@ Postgresql.string_of_error e

let get_connection ~(config : Config.config) : Ezpostgresql.connection =
  let open Lwt in
  let open Ezpostgresql in
  let create () =
    create_pg_connection ~host:config.db_host ~port:config.db_port
      ~password:"fresh" ~user:"fresh" ()
    >|= unpack
  in
  Lwt_main.run @@ create ()

let insert ~conn ~query ~params =
  let open Lwt in
  Lwt_main.run @@ (Ezpostgresql.command ~query ~params conn >|= unpack)
