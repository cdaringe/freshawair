open Core
open Cohttp_lwt_unix
open Lwt
open! Postgresql
open HandlerCommon

(* module Config = struct *)
type config = { port : int }

(* end *)

let respond_string body =
  Server.respond_string ~headers:json_headers ~status:`OK ~body ()

let on_receive_stat ~conn ~body =
  Cohttp_lwt.Body.to_string body >>= fun body_as_str ->
  let s = Stats.local_sensors_stat_of_yojson (Stats.str_to_json body_as_str) in
  match s with
  | Result.Ok stat -> (
      Awair.save_local_sensor ~conn stat >>= function
      | Ok _ -> respond_string @@ Awair.to_json stat
      | Error _ -> Server.respond ~status:`Bad_gateway ~body:`Empty () )
  | Error _ -> Server.respond ~status:`Bad_gateway ~body:`Empty ()

let create_server_handler ~conn ~(config : config) _id (req : Request.t) body =
  let uri = Uri.of_string req.resource in
  let url = Uri.path uri in
  match (url, req.meth) with
  | "/air/stats", `GET -> HandlerGetStats.get_stats ~conn ~uri
  | "/air/stats", `POST -> on_receive_stat ~conn ~body
  | _ -> Server.respond_not_found ()

let with_connection () : Ezpostgresql.connection Lwt.t =
  Db.create_connection ~host:"localhost" ~password:"fresh" ~user:"fresh" ()
  >|= function
  | Ok c -> c
  | Error e -> raise (Constants.InitError (Postgresql.string_of_error e))

let start ~(config : config) =
  with_connection () >>= fun conn ->
  let _ = Log.info "connecting to db" in
  let onconn = create_server_handler ~conn ~config in
  let msg =
    sprintf "Server started on port %s\n"
    @@ Console.green @@ string_of_int config.port
  in
  Log.info msg;
  Out_channel.flush stdout;
  Server.create ~mode:(`TCP (`Port config.port)) ~on_exn:Log.exn
  @@ Server.make ~callback:onconn ()
