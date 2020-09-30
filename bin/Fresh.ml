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
    ~body:(Printf.sprintf "Failed to read sensors: %s" (Exn.to_string exn)) ()

let stream_air_stats_from_pg_to_http (conn: Postgresql.connection) () =
let c = conn in
ignore (c#exec ~expect:[Command_ok] "begin");
ignore (
  c#exec
    ~expect:[Command_ok]
    "declare air_cursor cursor for select * from sensor_stats");
let rec loop () =
  let res = c#exec ~expect:[Tuples_ok] "FETCH IN air_cursor" in
  if res#ntuples <> 0 then (
    let tpl = res#get_tuple 0 in
    Console.log tpl;
    (* print_string tpl.(0); *)
    (* for i = 1 to Array.length tpl - 1 do print_string (" " ^ tpl.(i)) done; *)
    (* Console.log (); *)
    loop ()) in
loop ();
ignore (c#exec ~expect:[Command_ok] "CLOSE air_cursor");
ignore (c#exec ~expect:[Command_ok] "END")

let create_server_handler ~conn _conn_id (req: Request.t) _body =
  match req.resource with
    | "/air/stats" ->
      let () = stream_air_stats_from_pg_to_http conn () in
      Server.respond_string ~headers:json_headers ~status:`OK ~body:"sup!" ()
    | _ ->  Lwt.catch (on_sense_request conn) on_sense_fail

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
  Server.create ~mode:(`TCP (`Port port)) (Server.make ~callback:onconn ()) ~on_exn:(fun err ->
    Console.error err)

let () = ignore (Lwt_main.run @@ server ~port:8000)
