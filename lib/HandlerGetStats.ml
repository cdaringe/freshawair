open HandlerCommon
open JsonHacks
open Lwt
open Stats

let sql_get_stat = {|
declare air_cursor cursor for select
  abs_humid,
  co2,
  co2_est,
  dew_point,
  humid,
  pm10_est,
  pm25,
  score,
  temp,
  extract(epoch from timestamp) * 1000,
  voc,
  voc_baseline,
  voc_ethanol_raw,
  voc_h2_raw
from sensor_stats
|}

let stream_air_stats_from_pg_to_http (c : Postgresql.connection) =
  let stat_stream, push = Lwt_stream.create () in
  let get_cursor_res () = c#exec ~expect:[ Tuples_ok ] "fetch in air_cursor" in
  let rec get_next_stat cursor =
    if cursor#ntuples <> 0 then (
      let l = Array.to_list @@ cursor#get_tuple 0 in
      let serialized = json_arr_wrap @@ join_csv l in
      let next_cursor = get_cursor_res () in
      if next_cursor#ntuples <> 0 then push (Some (serialized ^ ","))
      else push (Some serialized);
      get_next_stat next_cursor )
    else (
      push @@ Some "]";
      push None )
  in
  let finally () =
    ignore (c#exec ~expect:[ Command_ok ] "close air_cursor");
    ignore (c#exec ~expect:[ Command_ok ] "end")
  in
  let get_body () =
    ignore (Lwt_stream.closed stat_stream >>= fun _ -> Lwt.return @@ finally ());
    push @@ Some "[";
    get_next_stat (get_cursor_res ());
    `Stream stat_stream
  in
  ignore (c#exec ~expect:[ Command_ok ] "begin");
  ignore
    (c#exec ~expect:[ Command_ok ] sql_get_stat);
  Cohttp_lwt_unix.Server.respond ~headers:json_headers ~status:`OK
    ~body:(get_body ()) ()

let get_stats = stream_air_stats_from_pg_to_http
