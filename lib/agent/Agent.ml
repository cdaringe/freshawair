open Freshcommon

type config = {
  auth_token : string;
  data_store_endpoint : string;
  poll_duration_s : int;
  awair_endpoint : string;
}

let upload_stat ~uri ~token (stat : Freshmodel.local_sensors_stat) =
  let body = `String (Freshmodel.stat_to_json stat) in
  let open Freshcommon.HandlerCommon in
  let open Cohttp_lwt_unix in
  let open Cohttp_lwt in
  let open Lwt in
  Client.post ~body
    ~headers:(Cohttp.Header.of_list [ json_headers; auth_header token ])
    uri
  >|= fun (res, body) ->
  Freshcommon.Log.debug @@ Cohttp.Code.string_of_status @@ Response.status res;
  (res, body)

let on_sensor_read ~config =
  let open Lwt in
  let partial_upload stat () =
    upload_stat
      ~uri:(Uri.of_string config.data_store_endpoint)
      ~token:config.auth_token stat
    >>= fun _ ->
    (* Console.log @@ Core.Time.to_string @@ Core.Time.now (); *)
    Lwt.return_unit
  in
  function
  | Ok stat ->
      Lwt.catch (partial_upload stat) (fun e ->
          Log.exn e;
          Lwt.return_unit)
  | Error e ->
      Log.error "failed to read sensor :/";
      Log.error e;
      Lwt.return ()

let poll_awair ~config =
  let open Lwt in
  let on_read_result = on_sensor_read ~config in
  Awair.read_local_sensors ~url:config.awair_endpoint >>= on_read_result

let rec start ?(init = false) ~(config : config) () : unit =
  let ontick () =
    (* Console.log @@ Core.Time.to_string @@ Core.Time.now (); *)
    ignore
    @@ Lwt.on_termination (poll_awair ~config) (fun _ -> start ~config ())
  in
  if init then ontick ()
  else Lwt_timeout.start @@ Lwt_timeout.create config.poll_duration_s ontick
