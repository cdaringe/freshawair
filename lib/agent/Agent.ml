open Freshcommon
open Obj.Effect_handlers
open Obj.Effect_handlers.Deep
open Effects
open Config

let upload_stat ~url ~token ~(stat : Freshmodel.local_sensors_stat) =
  let open Freshcommon.HandlerCommon in
  let body = Freshmodel.stat_to_json stat in
  perform
    (HttpPost { body; headers = [ json_headers; auth_header token ]; url })

let on_sensor_read ~config stat =
  (* upload_stat ~url:config.data_store_endpoint ~token:config.auth_token ~stat *)
  let conn = perform (DbConnect config) in
  Awair.save_local_sensor ~conn stat

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
            let cont fn =
              Some (fun (k : (a, _) continuation) -> continue k (fn ()))
            in
            match e with
            | DbConnect config -> cont @@ fun _ -> Db.get_connection config
            | DbInsert { conn; query; params } ->
                cont @@ fun _ -> Db.insert ~conn ~query ~params
            | HttpGet url -> cont @@ fun _ -> Http.get url
            | HttpReadStringBody body ->
                cont @@ fun _ -> Http.read_body_str body
            | HttpPost post -> cont @@ fun _ -> Http.post post
            | _ -> None);
      }
  in
  run etl

let rec start ?(init = false) ~(config : Config.config) () : unit =
  let open Freshcommon.Log in
  info "agent started";
  let { poll_duration_s } = config in
  while true do
    let () =
      try poll_awair ~config with
      | Http.E e -> error ("http error: " ^ e)
      | e -> error @@ Printexc.to_string e;
    in
    Unix.sleep poll_duration_s
  done;
  ()
