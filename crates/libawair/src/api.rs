use std::time::Duration;

use reqwest::Client;

use crate::{
    element::ElementStat,
    error::{api, invalid_model},
};

pub async fn get_stat(url: &str) -> Result<ElementStat, crate::error::Error> {
    Client::builder()
        .timeout(Duration::from_millis(5000))
        .build()
        .unwrap()
        .get(url)
        .send()
        .await
        .map_err(|e| api(&e.to_string()))?
        .json::<ElementStat>()
        .await
        .map_err(|e| invalid_model(&e.to_string()))
}
