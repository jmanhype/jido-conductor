pub use crate::run;

mod main {
    pub use super::*;
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    crate::main::run()
}