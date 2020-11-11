open Cohttp
open Cohttp_lwt_unix
open Lwt

let to_json sensor =
  Yojson.Safe.to_string @@ Freshmodel.local_sensors_stat_to_yojson sensor

let from_json sensor_str =
  Freshmodel.local_sensors_stat_of_yojson (Yojson.Safe.from_string sensor_str)

let read_local_sensors ~url =
  let res = Client.get @@ Uri.of_string url in
  res >>= fun x ->
  let resp, body = x in
  body |> Cohttp_lwt.Body.to_string >|= fun body -> from_json body
