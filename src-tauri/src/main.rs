// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use std::fs;
use std::path::Path;
use std::io::{self, Error, ErrorKind};
use serde::{Serialize, Deserialize};
use serde_yaml;
use serde_json::json;
use dirs;

mod types;
use types::*;

#[derive(Serialize)]
struct FileInfo {
    folder: bool,
    name: String,
}

#[derive(Serialize)]
struct FileInfoResponse {
    path: String,
    error: Option<String>,
    files: Vec<FileInfo>,
    conf: Option<BookConf>
}



// Learn more about Tauri commands at https://tauri.app/v1/guides/features/command
#[tauri::command]
fn get_book_conf(name: &str) -> String {
    match read_book_conf(&name) {
        Ok(conf) => {
            // Convert conf to JSON and return
            serde_json::to_string(&conf).unwrap_or_else(|_| json!({ "status": true }).to_string())
        }
        Err(_) => {
            json!({ "status": false }).to_string()
        }
    }
}

// #[tauri::command]
// fn save_book_conf(name: &str, conf: &str) -> String {

//     let book_conf: BookConf = // parse JSON conf string 

//     match write_book_conf(&name, &book_conf) {
//         Ok(conf) => {
//             // Convert conf to JSON and return
//             json!({ "status": true }).to_string()
//         }
//         Err(_) => {
//             json!({ "status": false }).to_string()
//         }
//     }
// }


#[tauri::command]
fn root() -> String {
    match dirs::home_dir() {
        Some(path) => {
            let mut path_str = path.into_os_string().into_string().unwrap();
            if !path_str.ends_with("/") {
                path_str.push('/');
            }
            path_str
        },
        None => "/".to_string()
    }
}

#[tauri::command]
fn list(path: &str) -> String {
    let mut path = if path.is_empty() {
        root()
    } else {
        path.to_string()
    };

    if !path.ends_with("/") {
        path.push('/');
    }

    let entries = fs::read_dir(&path);
    let mut file_infos = Vec::new();
    let mut response = FileInfoResponse {
        path: path.clone(),
        error: None,
        files: Vec::new(),
        conf: None,
    };

    match entries {
        Ok(entries) => {
            let mut has_book_conf = false;

            for entry in entries {
                match entry {
                    Ok(entry) => {
                        let file_name = entry.file_name().to_string_lossy().to_string();

                        // Check for book.yaml or assets folder
                        if file_name == "book.yaml" || (file_name == "assets" && entry.path().is_dir()) {
                            has_book_conf = true;
                        }

                        if file_name.starts_with('.') {
                            continue;
                        }

                        // If path is "/" and the file_name starts with a lowercase letter, skip this entry
                        if path == "/" && file_name.chars().next().map(|c| c.is_lowercase()).unwrap_or(false) {
                            continue;
                        }

                        let metadata = match entry.metadata() {
                            Ok(metadata) => metadata,
                            Err(err) => {
                                response.error = Some(err.to_string());
                                return serde_json::to_string(&response).unwrap();
                            },
                        };
                        
                        file_infos.push(FileInfo {
                            folder: metadata.is_dir(),
                            name: file_name,
                        });
                    }
                    Err(err) => {
                        response.error = Some(err.to_string());
                        return serde_json::to_string(&response).unwrap();
                    }
                }
            }

            // If book.yaml or assets folder found, load the book configuration
            if has_book_conf {
                match read_book_conf(&path) {
                    Ok(conf) => response.conf = Some(conf),
                    Err(err) => response.error = Some(err.to_string()),
                }
            }

            // Sort the vector by file name
            file_infos.sort_by(|a, b| a.name.cmp(&b.name));
            response.files = file_infos;
            serde_json::to_string(&response).unwrap()
        }
        Err(err) => {
            response.error = Some(err.to_string());
            serde_json::to_string(&response).unwrap()
        }
    }
}


fn make_epub(path: &String, epub_info: &EpubInfo) -> String {
    return "Dummy".to_string();
}

fn main() {
    tauri::Builder::default()
        .invoke_handler(tauri::generate_handler![list,root,get_book_conf])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}

// fn make_epub_info(book_conf: &BookConf) -> EpubInfo {

// }

pub fn read_book_conf(folder_path: &str) -> io::Result<BookConf> {
    let mut path = Path::new(folder_path).join("book.yaml");

    if !path.exists() {
        path = Path::new(folder_path).join("assets").join("book.yaml");
        if !path.exists() {
            return Err(Error::new(ErrorKind::NotFound, "book.yaml not found"));
        }
    }

    let content = fs::read_to_string(&path)?;

    let book_conf: BookConf = serde_yaml::from_str(&content).map_err(|err| {
        std::io::Error::new(std::io::ErrorKind::Other, err.to_string())
    })?;

    Ok(book_conf)
}


fn write_book_conf(folder_path: &str, book_conf: &BookConf) -> io::Result<()> {
    let path = Path::new(folder_path).join("book.yaml");

    let yaml_string = serde_yaml::to_string(book_conf).map_err(|err| {
        std::io::Error::new(std::io::ErrorKind::Other, err.to_string())
    })?;

    fs::write(path, yaml_string)
}