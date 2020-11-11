open Cohttp
open Cohttp_lwt_unix
open Lwt
open Db

let to_json sensor =
  Yojson.Safe.to_string @@ Freshmodel.local_sensors_stat_to_yojson sensor

let from_json sensor_str =
  Freshmodel.local_sensors_stat_of_yojson (Yojson.Safe.from_string sensor_str)

let read_local_sensors ~url =
  let res = Client.get @@ Uri.of_string url in
  res >>= fun x ->
  let resp, body = x in
  body |> Cohttp_lwt.Body.to_string >|= fun body -> from_json body

let save_local_sensor ~conn (s : Freshmodel.local_sensors_stat) =
  insert ~conn
    ~query:
      "insert into sensor_stats values (\n\
      \         $1,\n\
      \         $2,\n\
      \         $3,\n\
      \         $4,\n\
      \         $5,\n\
      \         $6,\n\
      \         $7,\n\
      \         $8,\n\
      \         $9,\n\
      \         $10,\n\
      \         $11,\n\
      \         $12,\n\
      \         $13,\n\
      \         $14)"
    ~params:
      [|
        string_of_float s.abs_humid;
        string_of_float s.co2;
        string_of_float s.co2_est;
        string_of_float s.dew_point;
        string_of_float s.humid;
        string_of_float s.pm10_est;
        string_of_float s.pm25;
        string_of_float s.score;
        string_of_float s.temp;
        s.timestamp;
        string_of_float s.voc;
        string_of_float s.voc_baseline;
        string_of_float s.voc_ethanol_raw;
        string_of_float s.voc_h2_raw;
      |]
