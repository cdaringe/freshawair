let start ~config = ignore (Lwt_main.run @@ Lib.FreshServer.start ~config : unit)

let cmd =
  let open Core.Command in
  basic ~summary:"freshawair - self hosted awair ETL"
    ~readme:(fun () -> "More detailed information")
    Let_syntax.(
      let%map_open uport =
        flag ~doc:"server port, default 8000" "--port" (optional int)
      and _is_agent = flag ~doc:"run as agent" "--agent" (optional bool)
      and _is_server = flag ~doc:"run as server" "--server" (optional bool)
      and uawair_endpoint =
        flag ~doc:"awair endpoint, e.g. http://192.168.0.100/api/local_data"
          "--awair" (optional string)
      in
      fun () ->
        let open Option in
        let config : Lib.FreshServer.config =
          {
            port = value uport ~default:8000;
            awair_endpoint = value uawair_endpoint ~default:"arst";
          }
        in
        start ~config)

let () = Core.Command.run ~version:"1.0" cmd
