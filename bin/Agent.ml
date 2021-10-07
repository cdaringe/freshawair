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
  Arg.(required & opt (some string) None & info [ "t"; "auth-token" ] ~doc)

let run_agent auth_token awair_endpoint data_store_endpoint poll_duration_s =
  Freshcommon.Log.info "starting";
  Freshagent.Agent.start ~init:true
    ~config:{ auth_token; data_store_endpoint; awair_endpoint; poll_duration_s }
    ()

let cmd =
  let open Cmdliner in
  let doc = "freshawair - agent" in
  ( Term.(
      const run_agent $ auth_token $ awair_endpoint $ data_store_endpoint
      $ poll_duration_s),
    Term.info "agent" ~version:"v2.0.0" ~doc ~exits:Term.default_exits )

let () = Term.(exit @@ eval cmd)
