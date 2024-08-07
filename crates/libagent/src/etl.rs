use crate::{config::Config, error::Error};
use libawair::api::get_stat;
use std::time::SystemTime;
use tokio_postgres::{tls::NoTlsStream, Client, Connection, NoTls, Socket};

async fn etl(url: &str, index: i16, client: &Client, _config: &Config) -> Result<(), Error> {
    match get_stat(url).await {
        Ok(stat) => {
            let _ = client
                .execute(
                    "insert into sensor_stats
(sensor_index,abs_humid,co2,co2_est,dew_point,humid,pm10_est,pm25,score,temp,timestamp,voc,voc_baseline,voc_ethanol_raw,voc_h2_raw)
values ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15)",
                    &[
                        &index,
                        &stat.abs_humid,
                        &stat.co2,
                        &stat.co2_est,
                        &stat.dew_point,
                        &stat.humid,
                        &stat.pm10_est,
                        &stat.pm25,
                        &stat.score,
                        &stat.temp,
                        &SystemTime::now(),
                        //  &stat.timestamp,
                        &stat.voc,
                        &stat.voc_baseline,
                        &stat.voc_ethanol_raw,
                        &stat.voc_h2_raw,
                    ],
                )
                .await
                .map_err(|e| Error::DbQuery(e.to_string()))?;
            Ok(())
        }
        Err(e) => Err(Error::Awair(e)),
    }
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

async fn etl_each(config: &Config, client: &Client) -> Result<(), crate::error::Error> {
    for (index, endpoint) in config.awair_endpoint.iter().enumerate() {
        etl(endpoint, index.try_into().unwrap(), client, config).await?;
    }
    Ok(())
}

pub async fn etl_all(config: &Config) -> Result<(), crate::error::Error> {
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
      x = etl_each(config, &client) => { x }
      y = open_conn(conn) => { y }
    }
}
