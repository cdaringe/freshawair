open Freshcommon
open Obj.Effect_handlers
open Obj.Effect_handlers.Deep
open Effects

type config = {
  auth_token : string;
  data_store_endpoint : string;
  poll_duration_s : int;
  awair_endpoint : string;
}

let upload_stat ~url ~token ~(stat : Freshmodel.local_sensors_stat) =
  let open Freshcommon.HandlerCommon in
  let body = Freshmodel.stat_to_json stat in
  perform
    (HttpPost { body; headers = [ json_headers; auth_header token ]; url })

let on_sensor_read ~config stat =
  upload_stat ~url:config.data_store_endpoint ~token:config.auth_token ~stat

let poll_awair ~config =
  let etl () =
    Awair.read_local_sensors ~url:config.awair_endpoint |> function
    | Ok stat -> on_sensor_read ~config stat |> fun _ -> ()
    | Error e ->
        Freshcommon.Log.error
          "failed to unpack sensor data. has the schema changed?"
  in
  let rec run f =
    try_with f ()
      {
        effc =
          (fun (type a) (e : a eff) ->
            let sometinue fn =
              Some (fun (k : (a, _) continuation) -> continue k (fn ()))
            in
            match e with
            | HttpGet url -> sometinue @@ fun _ -> Http.get url
            | HttpReadStringBody body ->
                sometinue @@ fun _ -> Http.read_body_str body
            | HttpPost post -> sometinue @@ fun _ -> Http.post post
            | _ -> None);
      }
  in
  run etl

let rec start ?(init = false) ~(config : config) () : unit =
  let { poll_duration_s } = config in
  while true do
    let () =
      try poll_awair ~config with
      | Http.E e -> Freshcommon.Log.error ("http error: " ^ e)
      | e -> failwith @@ Printexc.to_string e
    in
    Unix.sleep poll_duration_s
  done;
  ()
