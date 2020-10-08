open Core
open Cohttp_lwt_unix
open Lwt
open! Postgresql
open HandlerCommon

(* module Config = struct *)
type config = { port : int; awair_endpoint : string }

(* end *)

let read_sensors () =
  let url = "http://192.168.0.100/air-data/latest" in
  Awair.read_local_sensors ~url

let respond_string body =
  Server.respond_string ~headers:json_headers ~status:`OK ~body ()

let on_sensors_read (conn : Ezpostgresql.connection) = function
  | Result.Ok stat -> (
      Awair.save_local_sensor ~conn stat >>= function
      | Ok _ -> respond_string @@ Awair.to_json stat
      | Error _ -> Server.respond ~status:`Bad_gateway ~body:`Empty () )
  | Error _ -> Server.respond ~status:`Bad_gateway ~body:`Empty ()

let on_sense_request conn () = read_sensors () >>= on_sensors_read conn

let on_sense_fail exn =
  Server.respond_string ~headers:json_headers ~status:`Bad_gateway
    ~body:(Printf.sprintf "Failed to read sensors: %s" (Exn.to_string exn))
    ()

let create_server_handler ~conn ~(config : config) _conn_id (req : Request.t)
    _body =
  let uri = Uri.of_string req.resource in
  match Uri.path uri with
  | "/air/stats" -> HandlerGetStats.get_stats ~conn ~uri
  | _ -> Lwt.catch (on_sense_request conn) on_sense_fail

exception InitError of string

let with_connection () : Ezpostgresql.connection Lwt.t =
  Db.create_connection ~host:"localhost" ~password:"fresh" ~user:"fresh" ()
  >|= function
  | Ok c -> c
  | Error e -> raise (InitError (Postgresql.string_of_error e))

let start ~(config : config) =
  with_connection () >>= fun conn ->
  let _ = Console.log "connecting to db..." in
  let onconn = create_server_handler ~conn ~config in
  Console.log @@ "Server " ^ Pastel.green "started" ^ " on port "
  ^ Pastel.greenBright @@ string_of_int config.port;
  Server.create ~mode:(`TCP (`Port config.port)) ~on_exn:Console.error
  @@ Server.make ~callback:onconn ()
