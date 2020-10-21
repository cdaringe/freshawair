let start_server ~config =
  ignore (Lwt_main.run @@ Lib.FreshServer.start ~config : unit)

exception Missing_auth_token of string

let value_default_cb ~default = function Some x -> x | None -> default ()

let cmd =
  let open Core.Command in
  basic ~summary:"freshawair server - self hosted awair ETL"
    ~readme:(fun () -> "More detailed information")
    Let_syntax.(
      let%map_open uport =
        flag "port" (optional int) ~doc:"#### port, default 8000"
      and uauth_token =
        flag "auth-token" (optional string)
          ~doc:"auth token for accepting i/o for awair data"
      in
      fun () ->
        let open Option in
        let port =
          value uport
            ~default:
              (Sys.getenv_opt "PORT" |> value ~default:"8000" |> int_of_string)
        in
        let auth_token =
          value_default_cb uauth_token ~default:(fun _ ->
              Sys.getenv_opt "AUTH_TOKEN" |> function
              | Some x -> x
              | _ -> raise (Missing_auth_token "missing auth toke"))
        in
        start_server ~config:{ port; auth_token })

let () = Core.Command.run ~version:"0.0.1" cmd
