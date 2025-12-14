use libagent::{
    config::Config,
    etl::{AccumulatedReading, collect_readings, flush_accumulated_readings},
};
use std::error::Error;
use tokio::time::{self, Duration};

#[tokio::main]
async fn main() -> Result<(), Box<dyn Error>> {
    // cargo run -p agent -- --awair-endpoint=foo.com --awair-endpoint=grr.qux --db-host=bar.com --db-port=1234
    let config = Config::get_parsed();
    let mut interval = time::interval(Duration::from_secs(config.poll_duration_s as u64));
    let is_dev = std::env::var("IS_DARWIN").is_ok();
    if is_dev {
        println!("dev mode detected");
    } else {
        interval.tick().await;
    }
    let mut accumulated_readings: Vec<AccumulatedReading> = Vec::new();
    let mut interval_count = 0u32;
    const FLUSH_INTERVAL: u32 = 30;

    loop {
        interval.tick().await;
        interval_count += 1;

        // Collect readings on every interval
        match collect_readings(&config).await {
            Ok(mut readings) => {
                println!(
                    "Collected {} readings (total accumulated: {})",
                    readings.len(),
                    accumulated_readings.len() + readings.len()
                );
                accumulated_readings.append(&mut readings);
            }
            Err(e) => {
                eprintln!("Failed to collect readings: {:?}", e);
            }
        }

        // Flush accumulated readings every 30 intervals
        if interval_count.is_multiple_of(FLUSH_INTERVAL) {
            match flush_accumulated_readings(&accumulated_readings, &config).await {
                Ok(()) => {
                    println!(
                        "Successfully flushed {} readings to database",
                        accumulated_readings.len()
                    );
                    accumulated_readings.clear();
                }
                Err(e) => {
                    eprintln!("Failed to flush readings: {:?}", e);
                }
            }
        }
    }
}
