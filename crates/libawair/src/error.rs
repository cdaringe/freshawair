#[derive(Debug)]
pub enum Error {
    Api(String),
    InvalidModel(String),
}

pub fn api(str: &str) -> Error {
    Error::Api(str.to_owned())
}

pub fn invalid_model(str: &str) -> Error {
    Error::InvalidModel(str.to_owned())
}
