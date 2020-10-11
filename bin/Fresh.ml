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
      and _uawair_endpoint =
        flag "--awair" (optional string)
          ~doc:"awair endpoint, e.g. http://192.168.0.100/api/local_data"
      in
      fun () ->
        let open Option in
        match (is_agent, is_server) with
        | _, true ->
            start_server
              ~config:
                {
                  port =
                    value uport ~default:8000
                    (* awair_endpoint = value uawair_endpoint ~default:"arst"; *);
                }
        | true, _ -> Console.log "do agenty thing"
        | _ ->
            raise
              (Lib.Constants.InitError "--agent or --server must be specified"))

let () = Core.Command.run ~version:"1.0" cmd
