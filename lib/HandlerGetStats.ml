open HandlerCommon
open JsonHacks
open Lwt
open Stats

let sql_get_stat binningValue =
  Printf.sprintf
    {|
declare air_cursor cursor for select
  avg(abs_humid) as abs_humid,
  avg(co2) as co2,
  avg(co2_est) as co2_est,
  avg(dew_point) as dew_point,
  avg(humid) as humid,
  avg(pm10_est) as pm10_est,
  avg(pm25) as pm25,
  avg(score) as score,
  avg(temp) as temp,
  (extract(epoch from time_bucket('1 %s', timestamp)) * 1000) as bucket,
  avg(voc) as voc,
  avg(voc_baseline) as voc_baseline,
  avg(voc_ethanol_raw) as voc_ethanol_raw,
  avg(voc_h2_raw) as voc_h2_raw
from sensor_stats group by bucket order by bucket;
|}
    binningValue

let get_binning_value uri =
  match Uri.get_query_param uri "binningValue" with
  | Some x -> (
      match x with
      | "minute" | "hour" | "day" -> x
      | _ ->
          Log.error @@ "invalid binningValue: " ^ x;
          "hour" )
  | _ -> "hour"

let stream_air_stats_from_pg_to_http ~(conn : Postgresql.connection) ~uri =
  let stat_stream, push = Lwt_stream.create () in
  let get_cursor_res () =
    conn#exec ~expect:[ Tuples_ok ] "fetch in air_cursor"
  in
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
    ignore (conn#exec ~expect:[ Command_ok ] "close air_cursor");
    ignore (conn#exec ~expect:[ Command_ok ] "end")
  in
  let get_body () =
    ignore (Lwt_stream.closed stat_stream >>= fun _ -> Lwt.return @@ finally ());
    push @@ Some "[";
    get_next_stat (get_cursor_res ());
    `Stream stat_stream
  in
  ignore (conn#exec ~expect:[ Command_ok ] "begin");
  ignore
    (conn#exec ~expect:[ Command_ok ] (sql_get_stat @@ get_binning_value uri));
  Cohttp_lwt_unix.Server.respond
    ~headers:(Cohttp.Header.of_list [ json_headers ])
    ~status:`OK ~body:(get_body ()) ()

let get_stats = stream_air_stats_from_pg_to_http
