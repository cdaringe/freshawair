open Cmdliner

let data_store_endpoint =
  let doc = "data store endpoint" in
  Arg.(
    value
    & opt string "https://192.168.0.36/air/stats"
    & info [ "d"; "data-store-endpoint" ] ~doc)

let poll_duration_s =
  let doc = "poll duration (seconds)" in
  Arg.(value & opt int 60 & info [ "p"; "poll-duration" ] ~doc)

let awair_endpoint =
  let doc = "awair endpoint, default http://192.168.0.100/air-data/latest" in
  Arg.(
    value
    & opt string "http://192.168.0.100/air-data/latest"
    & info [ "a"; "awair-endpoint" ] ~doc)

let auth_token =
  let doc = "auth token for accepting i/o for awair data" in
  Arg.(value & opt string "fresh" & info [ "t"; "auth-token" ] ~doc)

let db_host =
  let doc = "database hostname" in
  Arg.(value & opt string "localhost" & info [ "db-host" ] ~doc)

let db_port =
  let doc = "database port" in
  Arg.(value & opt int 5432 & info [ "db-port" ] ~doc)

let run_agent auth_token awair_endpoint data_store_endpoint poll_duration_s
    db_host db_port =
  Freshagent.Agent.start ~init:true
    ~config:
      {
        auth_token;
        db_host;
        db_port;
        data_store_endpoint;
        awair_endpoint;
        poll_duration_s;
      }
    ()

let cmd =
  let open Cmdliner in
  let doc = "freshawair - agent" in
  ( Term.(
      const run_agent $ auth_token $ awair_endpoint $ data_store_endpoint
      $ poll_duration_s $ db_host $ db_port),
    Term.info "agent" ~version:"v2.0.0" ~doc ~exits:Term.default_exits )

let () = Term.(exit @@ eval cmd)
