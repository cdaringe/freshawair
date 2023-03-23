use clap::Parser;

#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
pub struct Config {
    #[arg(long)]
    pub awair_endpoint: Vec<String>,
    #[arg(long)]
    pub db_host: String,
    #[arg(long)]
    pub db_port: u16,
    #[arg(long, default_value = "fresh")]
    pub db_user: String,
    #[arg(long, default_value = "fresh")]
    pub db_password: String,
    #[arg(long, default_value_t = 60)]
    pub poll_duration_s: u16,
}

impl Config {
    pub fn get_parsed() -> Self {
        Config::parse()
    }
}
