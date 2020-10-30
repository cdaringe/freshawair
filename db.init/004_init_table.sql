create table fresh.public.sensor_stats(
  abs_humid float,
  co2 float,
  co2_est float,
  dew_point float,
  humid float,
  pm10_est float,
  pm25 float,
  score float,
  temp float,
  timestamp timestamp,
  voc float,
  voc_baseline float,
  voc_ethanol_raw float,
  voc_h2_raw float
);
SELECT create_hypertable('fresh.public.sensor_stats', 'timestamp');
