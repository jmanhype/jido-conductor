// Import the necessary dependencies
use serde::{Deserialize, Serialize};
use std::sync::Mutex;
use tauri::State;
use uuid::Uuid;

#[derive(Debug, Serialize, Deserialize)]
struct AppState {
    session_token: String,
}

impl Default for AppState {
    fn default() -> Self {
        Self {
            session_token: Uuid::new_v4().to_string(),
        }
    }
}

#[tauri::command]
fn get_session_token(state: State<Mutex<AppState>>) -> String {
    state.lock().unwrap().session_token.clone()
}

#[tauri::command]
async fn store_secret(key: String, value: String) -> Result<(), String> {
    let entry = keyring::Entry::new("jido-conductor", &key)
        .map_err(|e| e.to_string())?;
    entry.set_password(&value).map_err(|e| e.to_string())?;
    Ok(())
}

#[tauri::command]
async fn get_secret(key: String) -> Result<String, String> {
    let entry = keyring::Entry::new("jido-conductor", &key)
        .map_err(|e| e.to_string())?;
    entry.get_password().map_err(|e| e.to_string())
}

#[tauri::command]
async fn delete_secret(key: String) -> Result<(), String> {
    let entry = keyring::Entry::new("jido-conductor", &key)
        .map_err(|e| e.to_string())?;
    entry.delete_credential().map_err(|e| e.to_string())?;
    Ok(())
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_shell::init())
        .plugin(tauri_plugin_fs::init())
        .plugin(tauri_plugin_http::init())
        .manage(Mutex::new(AppState::default()))
        .invoke_handler(tauri::generate_handler![
            get_session_token,
            store_secret,
            get_secret,
            delete_secret
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}