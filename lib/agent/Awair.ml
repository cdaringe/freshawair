open Cohttp_lwt_unix
open Effects
open Lwt
open Obj.Effect_handlers

let to_json sensor =
  Yojson.Safe.to_string @@ Freshmodel.local_sensors_stat_to_yojson sensor

let from_json sensor_str =
  Yojson.Safe.from_string sensor_str |> Freshmodel.local_sensors_stat_of_yojson

let read_local_sensors ~url =
  perform @@ HttpGet url |> fun (_res, body) ->
  perform @@ HttpReadStringBody body |> from_json
(* Freshcommon.Log.debug body_str; *)
