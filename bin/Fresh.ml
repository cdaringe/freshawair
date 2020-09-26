open Lwt
open Cohttp_lwt_unix
open Core

let read_sensors () =
  let url = "http://192.168.0.100/air-data/latest" in
  Lib.Awair.read_local_sensors ~url

let json_headers =
  Cohttp.Header.init_with "content-type" "application/json; charset=utf-8"

let respond_string body =
  Server.respond_string ~headers:json_headers ~status:`OK ~body ()

let on_sensors_read (conn : Ezpostgresql.connection) = function
  | Ok stat -> (
      Lib.Awair.save_local_sensor ~conn stat >>= function
      | Ok _ -> respond_string @@ Lib.Awair.to_json stat
      | Error _ -> Server.respond ~status:`Bad_gateway ~body:`Empty () )
  | Error _ -> Server.respond ~status:`Bad_gateway ~body:`Empty ()

let on_sense_request conn () = read_sensors () >>= on_sensors_read conn

let on_sense_fail _exn =
  Server.respond_string ~headers:json_headers ~status:`Bad_gateway
    ~body:"Failed to read sensors" ()

let create_server_handler ~conn _conn_id _req _body =
  Lwt.catch (on_sense_request conn) on_sense_fail

exception InitError of string

let with_connection (): Postgresql.connection Lwt.t =
  Lib.Db.create_connection ~host:"localhost" () >>= function
  | Ok c -> Lwt.return c
  | Error (e) -> raise (InitError (Postgresql.string_of_error e))

let server ~port =
  with_connection () >>= fun conn ->
  let onconn = create_server_handler ~conn in
  Console.log @@ "Server " ^ Pastel.green "started" ^ " on port "
  ^ Pastel.greenBright @@ string_of_int port;
  Server.create ~mode:(`TCP (`Port port)) (Server.make ~callback:onconn ())

let () = ignore (Lwt_main.run @@ server ~port:8000)
