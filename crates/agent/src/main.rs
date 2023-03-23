use libagent::{config::Config, etl::etl_all};
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
    loop {
        interval.tick().await;
        let () = etl_all(&config)
            .await
            .or_else(|e| {
                eprintln!("{:?}", e);
                Ok::<(), libagent::error::Error>(())
            })
            .map(|_| println!("ok"))
            .expect("unit");
    }
}
