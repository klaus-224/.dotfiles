//! Small fzf viewer for environment variables.

use std::env;
use std::process::Command;

use dotfiles_scripts::{die, filter, has_command};

fn main() {
    if !has_command("fzf") {
        die("fzf is required. Install with: brew install fzf");
    }

    let mut vars: Vec<String> = env::vars_os()
        .map(|(key, value)| format!("{}={}\n", key.to_string_lossy(), value.to_string_lossy()))
        .collect();
    vars.sort();

    let picker = ["--height=60%", "--layout=reverse", "--prompt=env> "];
    if let Some(selection) = filter(Command::new("fzf").args(picker), &vars.concat()) {
        print!("{selection}");
    }
}
