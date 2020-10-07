type http_response = (Cohttp.Response.t * Cohttp_lwt.Body.t) Lwt.t

let json_headers =
  Cohttp.Header.init_with "content-type" "application/json; charset=utf-8"
