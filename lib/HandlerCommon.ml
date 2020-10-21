type http_response = (Cohttp.Response.t * Cohttp_lwt.Body.t) Lwt.t

let json_headers = ("content-type", "application/json; charset=utf-8")

let auth_header token = ("authorization", token)
