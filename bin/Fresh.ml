let start_server ~config =
  ignore (Lwt_main.run @@ Lib.FreshServer.start ~config : unit)

let cmd =
  let open Core.Command in
  basic ~summary:"freshawair - self hosted awair ETL"
    ~readme:(fun () -> "More detailed information")
    Let_syntax.(
      let%map_open uport =
        flag "port" (optional int) ~doc:"#### port, default 8000"
      and is_agent = flag "agent" no_arg ~doc:"run as agent"
      and is_server = flag "server" no_arg ~doc:"run as server"
      and idata_store_endpoint =
        flag "data-store-endpoint" (optional string) ~doc:"data store endpoint"
      and poll_duration =
        flag "poll-duration" (optional int)
          ~doc:
            "poll_duration seconds between awair data capture and uploads, \
             default 60"
      and awair_endpoint =
        flag "awair-endpoint" (optional string)
          ~doc:"awair endpoint, default http://192.168.0.100/air-data/latest"
      in
      fun () ->
        let open Option in
        match (is_agent, is_server) with
        | _, true ->
            let port =
              value uport
                ~default:
                  ( Sys.getenv_opt "PORT" |> value ~default:"8000"
                  |> int_of_string )
            in
            start_server ~config:{ port }
        | true, _ ->
            Lib.Log.info "starting agent";
            Lib.FreshAgent.start ~init:true
              ~config:
                {
                  poll_duration_s = value poll_duration ~default:60;
                  data_store_endpoint =
                    value idata_store_endpoint
                      ~default:"https://cdaringe.com/api/freshawair";
                  awair_endpoint =
                    value awair_endpoint
                      ~default:"http://192.168.0.100/air-data/latest";
                }
              ();
            let never_resolves, _ = Lwt.wait () in
            Lwt_main.run never_resolves
        | _ ->
            raise
              (Lib.Constants.InitError "--agent or --server must be specified"))

let () = Core.Command.run ~version:"0.0.1" cmd
