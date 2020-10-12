type config = {
  data_store_endpoint : string;
  poll_duration_s : int;
  awair_endpoint : string;
}

let upload_stat ~uri (stat : Stats.local_sensors_stat) =
  let body = `String (Stats.stat_to_json stat) in
  let open Cohttp_lwt_unix in
  let open Cohttp_lwt in
  let open Lwt in
  Client.post ~body ~headers:HandlerCommon.json_headers uri
  >|= fun (res, body) ->
  Console.log @@ Cohttp.Code.string_of_status @@ Response.status res;
  (* Console.log @@ (match body with | `String s -> s | _ -> "__"); *)
  (res, body)

let on_sensor_read ~config =
  let open Lwt in
  let partial_upload stat () =
    upload_stat ~uri:(Uri.of_string config.data_store_endpoint) stat
    >>= fun _ ->
    (* Console.log @@ Core.Time.to_string @@ Core.Time.now (); *)
    Lwt.return_unit
  in
  function
  | Ok stat ->
      Lwt.catch (partial_upload stat) (fun e ->
          Console.exn e;
          Lwt.return_unit)
  | Error e ->
      Console.error "failed to read sensor :/";
      Console.error e;
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
