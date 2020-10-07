type local_sensors_stat = {
  abs_humid : float;
  co2 : float;
  co2_est : float;
  dew_point : float;
  humid : float;
  pm10_est : float;
  pm25 : float;
  score : float;
  temp : float;
  timestamp : string;
  voc : float;
  voc_baseline : float;
  voc_ethanol_raw : float;
  voc_h2_raw : float;
}
[@@deriving yojson { exn = true }]

(* legacy code from when shipping iso timestamps down as string, vs
epoch ms offsets
*)
(* let with_serialized_sensor_date i x =
  match i with 9 -> "\"" ^ x ^ "\"" | _ -> x

let to_serialized_parts = List.mapi with_serialized_sensor_date *)
