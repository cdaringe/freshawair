use clap::Parser;

#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
pub struct Config {
    #[arg(long, env = "AWAIR_ENDPOINT")]
    pub awair_endpoint: Vec<String>,
    #[arg(long, env = "DB_HOST")]
    pub db_host: String,
    #[arg(long, env = "DB_PORT", default_value_t = 5432)]
    pub db_port: u16,
    #[arg(long, env = "DB_USER", default_value = "fresh")]
    pub db_user: String,
    #[arg(long, env = "DB_PASSWORD", default_value = "fresh")]
    pub db_password: String,
    #[arg(long, env = "POLL_DURATION_S", default_value_t = 60)]
    pub poll_duration_s: u16,
}

impl Config {
    pub fn get_parsed() -> Self {
        let mut config = Config::parse();
        config.awair_endpoint = config
            .awair_endpoint
            .iter()
            .map(|x| x.to_string())
            .collect();
        println!("{:?}", config.awair_endpoint);
        config
    }
}
