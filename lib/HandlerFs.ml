open Lwt.Infix
open Cohttp_lwt_unix
open CohttpServerCopy

let serve_file ~docroot ~uri =
  let fname = Server.resolve_local_file ~docroot ~uri in
  Server.respond_file ~fname ()

let ls_dir dir =
  Lwt_stream.to_list
    (Lwt_stream.filter (( <> ) ".") (Lwt_unix.files_of_directory dir))

let serve ~info ~docroot ~index uri path =
  let file_name = Server.resolve_local_file ~docroot ~uri in
  Lwt.catch
    (fun () ->
      Lwt_unix.stat file_name >>= fun stat ->
      match kind_of_unix_kind stat.Unix.st_kind with
      | `Directory -> (
          let path_len = String.length path in
          if path_len <> 0 && path.[path_len - 1] <> '/' then
            Server.respond_redirect ~uri:(Uri.with_path uri (path ^ "/")) ()
          else
            match Sys.file_exists (file_name / index) with
            | true ->
                let uri = Uri.with_path uri (path / index) in
                serve_file ~docroot ~uri
            | false ->
                ls_dir file_name
                >>= Lwt_list.map_s (fun f ->
                        let file_name = file_name / f in
                        Lwt.try_bind
                          (fun () -> Lwt_unix.LargeFile.stat file_name)
                          (fun stat ->
                            Lwt.return
                              ( Some
                                  (kind_of_unix_kind
                                     stat.Unix.LargeFile.st_kind),
                                stat.Unix.LargeFile.st_size,
                                f ))
                          (fun _exn -> Lwt.return (None, 0L, f)))
                >>= fun listing ->
                let body = html_of_listing uri path (sort listing) info in
                Server.respond_string ~status:`OK ~body () )
      | `File -> serve_file ~docroot ~uri
      | _ ->
          Server.respond_string ~status:`Forbidden
            ~body:(html_of_forbidden_unnormal path info)
            ())
    (function
      | Unix.Unix_error (Unix.ENOENT, "stat", p) as e ->
          if p = file_name then
            Server.respond_string ~status:`Not_found
              ~body:(html_of_not_found path info)
              ()
          else Lwt.fail e
      | e -> Lwt.fail e)
