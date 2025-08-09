use serde::Deserialize;

#[derive(Debug, Deserialize)]
pub struct ElementStat {
    pub abs_humid: f64,
    pub co2: f64,
    pub co2_est: f64,
    pub co2_est_baseline: f64,
    pub dew_point: f64,
    pub humid: f64,
    pub pm10_est: f64,
    pub pm25: f64,
    pub score: f64,
    pub temp: f64,
    pub timestamp: String,
    pub voc: f64,
    pub voc_baseline: f64,
    pub voc_ethanol_raw: f64,
    pub voc_h2_raw: f64,
}
