open Cohttp_lwt_unix

exception E of string

let run fn =
  try Lwt_main.run @@ fn () with e -> raise @@ E (Printexc.to_string e)

let get url =
  (* Cohttp_lwt_unix.Debug.activate_debug (); *)
  let f () = Client.get @@ Uri.of_string url in
  run f

let read_body_str body =
  let f () = Cohttp_lwt.Body.to_string body in
  run f

let post ({ body; headers; url } : Effects.post) =
  let f () =
    Client.post ~body:(`String body) ~headers:(Cohttp.Header.of_list headers)
    @@ Uri.of_string url
  in
  run f
