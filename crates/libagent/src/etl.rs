use crate::{config::Config, error::Error};
use libawair::{api::get_stat, element::ElementStat};
use std::time::SystemTime;
use tokio_postgres::{Client, Connection, NoTls, Socket, tls::NoTlsStream};

#[derive(Debug)]
pub struct AccumulatedReading {
    pub sensor_index: i16,
    pub stat: ElementStat,
    pub timestamp: SystemTime,
}

async fn collect_reading(
    url: &str,
    index: i16,
    _config: &Config,
) -> Result<AccumulatedReading, Error> {
    println!("Collecting reading from {}", url);
    match get_stat(url).await {
        Ok(stat) => Ok(AccumulatedReading {
            sensor_index: index,
            stat,
            timestamp: SystemTime::now(),
        }),
        Err(e) => Err(Error::Awair(e)),
    }
}

async fn flush_readings(readings: &[AccumulatedReading], client: &Client) -> Result<(), Error> {
    if readings.is_empty() {
        return Ok(());
    }

    let mut query = String::from(
        "INSERT INTO sensor_stats (sensor_index,abs_humid,co2,co2_est,dew_point,humid,pm10_est,pm25,score,temp,timestamp,voc,voc_baseline,voc_ethanol_raw,voc_h2_raw) VALUES ",
    );
    let mut params: Vec<&(dyn tokio_postgres::types::ToSql + Sync)> = Vec::new();
    let mut param_idx = 1;

    for (i, reading) in readings.iter().enumerate() {
        if i > 0 {
            query.push_str(", ");
        }
        query.push_str(&format!(
            "(${},${},${},${},${},${},${},${},${},${},${},${},${},${},${})",
            param_idx,
            param_idx + 1,
            param_idx + 2,
            param_idx + 3,
            param_idx + 4,
            param_idx + 5,
            param_idx + 6,
            param_idx + 7,
            param_idx + 8,
            param_idx + 9,
            param_idx + 10,
            param_idx + 11,
            param_idx + 12,
            param_idx + 13,
            param_idx + 14
        ));

        params.extend_from_slice(&[
            &reading.sensor_index,
            &reading.stat.abs_humid,
            &reading.stat.co2,
            &reading.stat.co2_est,
            &reading.stat.dew_point,
            &reading.stat.humid,
            &reading.stat.pm10_est,
            &reading.stat.pm25,
            &reading.stat.score,
            &reading.stat.temp,
            &reading.timestamp,
            &reading.stat.voc,
            &reading.stat.voc_baseline,
            &reading.stat.voc_ethanol_raw,
            &reading.stat.voc_h2_raw,
        ]);
        param_idx += 15;
    }

    client
        .execute(&query, &params)
        .await
        .map_err(|e| Error::DbQuery(e.to_string()))?;

    Ok(())
}

async fn open_conn(conn: Connection<Socket, NoTlsStream>) -> Result<(), crate::error::Error> {
    let conn_thread =
        tokio::spawn(async move { conn.await.map_err(|e| Error::DbConn(e.to_string())) });
    conn_thread
        .await
        .map(|_| ())
        .map_err(|e| Error::DbConn(e.to_string()))?;
    Ok(())
}

async fn collect_all_readings(
    config: &Config,
) -> Result<Vec<AccumulatedReading>, crate::error::Error> {
    let mut readings = Vec::new();
    for (index, endpoint) in config.awair_endpoint.iter().enumerate() {
        match collect_reading(endpoint, index.try_into().unwrap(), config).await {
            Ok(reading) => readings.push(reading),
            Err(e) => eprintln!("Failed to collect reading from {}: {:?}", endpoint, e),
        }
    }
    Ok(readings)
}

pub async fn collect_readings(
    config: &Config,
) -> Result<Vec<AccumulatedReading>, crate::error::Error> {
    collect_all_readings(config).await
}

pub async fn flush_accumulated_readings(
    readings: &[AccumulatedReading],
    config: &Config,
) -> Result<(), crate::error::Error> {
    if readings.is_empty() {
        return Ok(());
    }

    // handy connection string test (within db image)
    // psql -Atx postgresql://fresh:fresh@localhost:5432/fresh?connect_timeout=10 -c 'select current_date'
    let conn_str = format!(
        "postgresql://{}:{}@{}:{}/fresh?connect_timeout=5",
        &config.db_user, &config.db_password, &config.db_host, config.db_port,
    );
    let (client, conn) = tokio_postgres::connect(&conn_str, NoTls)
        .await
        .map_err(|e| Error::DbConn(e.to_string()))?;
    tokio::select! {
      x = flush_readings(readings, &client) => { x }
      y = open_conn(conn) => { y }
    }
}
