open Lwt
open Cohttp_lwt_unix
open Core
open! Postgresql

let read_sensors () =
  let url = "http://192.168.0.100/air-data/latest" in
  Lib.Awair.read_local_sensors ~url

let json_headers =
  Cohttp.Header.init_with "content-type" "application/json; charset=utf-8"

let respond_string body =
  Server.respond_string ~headers:json_headers ~status:`OK ~body ()

let on_sensors_read (conn : Ezpostgresql.connection) = function
  | Result.Ok stat -> (
      Lib.Awair.save_local_sensor ~conn stat >>= function
      | Ok _ -> respond_string @@ Lib.Awair.to_json stat
      | Error _ -> Server.respond ~status:`Bad_gateway ~body:`Empty () )
  | Error _ -> Server.respond ~status:`Bad_gateway ~body:`Empty ()

let on_sense_request conn () = read_sensors () >>= on_sensors_read conn

let on_sense_fail exn =
  Server.respond_string ~headers:json_headers ~status:`Bad_gateway
    ~body:(Printf.sprintf "Failed to read sensors: %s" (Exn.to_string exn))
    ()

let stream_air_stats_from_pg_to_http (c : Postgresql.connection) =
  let stat_stream, push = Lwt_stream.create () in
  let rec get_next_stat () =
    let cursor_res = c#exec ~expect:[ Tuples_ok ] "FETCH IN air_cursor" in
    if cursor_res#ntuples <> 0 then (
      push
      @@ Some (String.concat ~sep:"," @@ Array.to_list @@ cursor_res#get_tuple 0);
      get_next_stat () )
    else (
      push @@ Some "]";
      push None )
  in
  let finally () =
    ignore (c#exec ~expect:[ Command_ok ] "CLOSE air_cursor");
    ignore (c#exec ~expect:[ Command_ok ] "END")
  in
  let get_body () =
    ignore (Lwt_stream.closed stat_stream >>= fun _ -> Lwt.return @@ finally ());
    push @@ Some "[";
    get_next_stat ();
    `Stream stat_stream
  in
  ignore (c#exec ~expect:[ Command_ok ] "BEGIN");
  ignore
    (c#exec ~expect:[ Command_ok ]
       "DECLARE air_cursor CURSOR FOR SELECT * FROM sensor_stats");
  Server.respond ~headers:json_headers ~status:`OK ~body:(get_body ()) ()

let create_server_handler ~conn _conn_id (req : Request.t) _body =
  match req.resource with
  | "/air/stats" -> stream_air_stats_from_pg_to_http conn
  | _ -> Lwt.catch (on_sense_request conn) on_sense_fail

exception InitError of string

let with_connection () : Ezpostgresql.connection Lwt.t =
  Lib.Db.create_connection ~host:"localhost" ~password:"fresh" ~user:"fresh" ()
  >|= function
  | Ok c -> c
  | Error e -> raise (InitError (Postgresql.string_of_error e))

let server ~port =
  with_connection () >>= fun conn ->
  let _ = Console.log "connecting to db..." in
  let onconn = create_server_handler ~conn in
  Console.log @@ "Server " ^ Pastel.green "started" ^ " on port "
  ^ Pastel.greenBright @@ string_of_int port;
  Server.create
    ~mode:(`TCP (`Port port))
    (Server.make ~callback:onconn ())
    ~on_exn:(fun err -> Console.error err)

let () = ignore (Lwt_main.run @@ server ~port:8000)
