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

let with_connection ~config : Ezpostgresql.connection Lwt.t =
  Db.create_connection ~host:config.db_host ~port:config.db_port
    ~password:"fresh" ~user:"fresh" ()
  >|= function
  | Ok c -> c
  | Error e -> raise (Constants.InitError (Postgresql.string_of_error e))

let handle_options_air_stats req =
  Response.of_string_body
    ~headers:(Cohttp.Header.of_list [ HandlerCommon.cors_header ])
    ""
  |> Lwt.return

let create_handle_get_air_stats conn (req : Rock.Request.t) =
  let headers = Cohttp.Header.of_list [ json_headers; cors_header ] in
  let uri = Uri.of_string req.request.resource in
  let body = HandlerGetStats.get_stats_stream ~conn ~uri in
  Response.create ~body ~headers () |> Lwt.return

let create_handle_post_air_stats conn (req : Rock.Request.t) =
  let headers = Cohttp.Header.of_list [ json_headers; cors_header ] in
  Cohttp_lwt.Body.to_string req.body >>= fun body_as_str ->
  let stat_result =
    Freshmodel.local_sensors_stat_of_yojson (Freshmodel.str_to_json body_as_str)
  in
  match stat_result with
  | Result.Ok stat -> (
      Awair.save_local_sensor ~conn stat >>= function
      | Ok _ ->
          Lwt.return @@ Response.of_string_body ~headers (Awair.to_json stat)
      | Error _ ->
          Lwt.return @@ Response.create ~code:`Bad_gateway ~body:`Empty () )
  | Error _ -> Lwt.return @@ Response.create ~code:`Bad_gateway ~body:`Empty ()

let create_middleware () =
  Opium.Middleware.static ~local_path:"./public/" ~uri_prefix:"/" ()

let start ~config =
  let middleware = create_middleware () in
  let db_ready =
    Lwt.catch
      (fun _ -> with_connection ~config)
      (fun e ->
        Log.exn e;
        raise e)
  in
  db_ready >>= fun conn ->
  Log.info
  @@ Core.sprintf "Server started on port %s"
  @@ string_of_int config.port;
  App.empty |> App.middleware middleware |> App.port config.port
  |> App.options "/air/stats" handle_options_air_stats
  |> App.get "/air/stats" (create_handle_get_air_stats conn)
  |> App.post "/air/stats" (create_handle_post_air_stats conn)
  |> App.start
