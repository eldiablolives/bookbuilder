use serde::{Serialize, Deserialize};

#[derive(Debug, Serialize, Deserialize)]
pub struct BookConf {
    pub name: String,
    pub author: String,
    pub title: String,
    pub start: Option<String>,
    pub start_title: Option<String>,
}

#[derive(Serialize)]
pub struct ErrorMessage {
    pub error: String,
}

pub struct EpubInfo {
    pub id: Option<String>,
    pub conf: BookConf,
    pub fonts: Option<Vec<String>>,
    pub images: Option<Vec<String>>
}

