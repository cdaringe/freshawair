(* open Core
open Cohttp_lwt_unix *)
open Lwt
open! Postgresql
open Freshcommon.HandlerCommon
open Freshcommon
open Opium
open Opium.Std

type config = {
  port : int;
  auth_token : string;
  db_host : string;
  db_port : int;
}

(* let respond_string body = *)
(* Server.respond_string *)
(* ~headers:(Cohttp.Header.of_list [ json_headers ]) *)
(* ~status:`OK ~body () *)
(*  *)
(* let on_receive_stat ~conn ~body = *)
(* Cohttp_lwt.Body.to_string body >>= fun body_as_str -> *)
(* let s = Freshmodel.local_sensors_stat_of_yojson (Freshmodel.str_to_json body_as_str) in *)
(* match s with *)
(* | Result.Ok stat -> ( *)
(* Awair.save_local_sensor ~conn stat >>= function *)
(* | Ok _ -> respond_string @@ Awair.to_json stat *)
(* | Error _ -> Server.respond ~status:`Bad_gateway ~body:`Empty () ) *)
(* | Error _ -> Server.respond ~status:`Bad_gateway ~body:`Empty () *)
(*  *)
(* let create_server_handler ~conn ~(config : config) _id (req : Request.t) body = *)
(* let uri = Uri.of_string req.resource in *)
(* let url = Uri.path uri in *)
(* (* let auth_token = *)
     (* Option.value ~default:"" (Cohttp.Header.get req.headers "authorization") *)
   (* in *) *)
(* let is_token_matched = equal_string config.auth_token auth_token in *)
(* match (url, req.meth) with *)
(* | "/air/stats", `OPTIONS -> *)
(* Server.respond *)
(* ~headers:(Cohttp.Header.of_list [ HandlerCommon.cors_header ]) *)
(* ~status:`OK ~body:`Empty () *)
(* | "/air/stats", `GET -> HandlerGetStats.get_stats ~conn ~uri *)
(* | "/air/stats", `POST -> on_receive_stat ~conn ~body *)
(* USE OPIUM STATIC FILE SERVER!! *)
(* (* | _, `GET -> *)
    (* HandlerFs.serve ~info:"static-file-serve" ~docroot:"public" *)
      (* ~index:"index.html" uri url *) *)
(* | _ -> Server.respond_not_found () *)
(*  *)
let with_connection ~config : Ezpostgresql.connection Lwt.t =
  Db.create_connection ~host:config.db_host ~port:config.db_port
    ~password:"fresh" ~user:"fresh" ()
  >|= function
  | Ok c -> c
  | Error e -> raise (Constants.InitError (Postgresql.string_of_error e))

(* let on_db_ready ~config conn = *)
(* Log.info "db connected"; *)
(* let onconn = create_server_handler ~conn ~config in *)
(* let msg = *)
(* sprintf "Server started on port %s\n" @@ string_of_int config.port *)
(* in *)
(* Log.info msg; *)
(* Out_channel.flush stdout; *)
(* Server.create ~mode:(`TCP (`Port config.port)) ~on_exn:Log.exn *)
(* @@ Server.make ~callback:onconn () *)
(*  *)
(* let start ~(config : config) = *)

let streaming_handler req =
  let length = Body.length req.Request.body in
  let content = Body.to_stream req.Request.body in
  let body = Lwt_stream.map String.uppercase_ascii content in
  Response.of_stream body |> Lwt.return

let start ~config =
  Log.info "connecting to db";
  let db_ready =
    Lwt.catch
      (fun _ -> with_connection ~config)
      (fun e ->
        Log.exn e;
        raise e)
  in
  db_ready >>= fun conn ->
  Log.info
  @@ Core.sprintf "Server started on port %s\n"
  @@ string_of_int config.port;
  App.empty |> App.port config.port
  |> App.post "/hello/stream" streaming_handler
  |> App.start
