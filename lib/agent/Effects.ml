open Cohttp_lwt_unix
open Obj.Effect_handlers

type reply = Cohttp_lwt.Response.t * Cohttp_lwt.Body.t

type post = { url : string; body : string; headers : (string * string) list }

type _ eff +=
  | HttpReadStringBody : Cohttp_lwt.Body.t -> string eff
  | HttpGet : string -> reply eff
  | HttpPost : post -> reply eff
  | DbConnect : Config.config -> Ezpostgresql.connection eff
  | DbInsert : {
      conn : Ezpostgresql.connection;
      query : string;
      params : string array;
    }
      -> unit eff
