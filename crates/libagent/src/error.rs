#[derive(Debug)]
pub enum Error {
    DbConn(String),
    DbQuery(String),
    CorruptData(String),
    Awair(libawair::error::Error),
}
