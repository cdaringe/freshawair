let value_default_cb ~default = function Some x -> x | None -> default ()

exception Missing_auth_token of string

let cmd =
  let open Core.Command in
  basic ~summary:"freshawair - self hosted awair ETL"
    ~readme:(fun () -> "More detailed information")
    Let_syntax.(
      let%map_open idata_store_endpoint =
        flag "data-store-endpoint" (optional string) ~doc:"data store endpoint"
      and poll_duration =
        flag "poll-duration" (optional int)
          ~doc:
            "poll_duration seconds between awair data capture and uploads, \
             default 60"
      and awair_endpoint =
        flag "awair-endpoint" (optional string)
          ~doc:"awair endpoint, default http://192.168.0.100/air-data/latest"
      and uauth_token =
        flag "auth-token" (optional string)
          ~doc:"auth token for accepting i/o for awair data"
      in
      fun () ->
        let open Option in
        let auth_token =
          value_default_cb uauth_token ~default:(fun _ ->
              Sys.getenv_opt "AUTH_TOKEN" |> function
              | Some x -> x
              | _ -> raise (Missing_auth_token "missing auth toke"))
        in
        Lib.Log.info "starting agent";
        Lib.FreshAgent.start ~init:true
          ~config:
            {
              auth_token;
              data_store_endpoint =
                value idata_store_endpoint
                  ~default:"https://192.168.0.36/air/stats";
              awair_endpoint =
                value awair_endpoint
                  ~default:"http://192.168.0.100/air-data/latest";
              poll_duration_s = value poll_duration ~default:60;
            }
          ();
        let never_resolves, _ = Lwt.wait () in
        Lwt_main.run never_resolves)

let () = Core.Command.run ~version:"0.0.1" cmd
