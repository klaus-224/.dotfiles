//! Small fzf viewer for PATH entries.

use std::env;
use std::process::Command;

use dotfiles_scripts::{die, filter, has_command};

fn main() {
    if !has_command("fzf") {
        die("fzf is required. Install with: brew install fzf");
    }

    let path = env::var("PATH").unwrap_or_default();
    let mut entries: Vec<&str> = path
        .split(':')
        .filter(|entry| !entry.trim().is_empty())
        .collect();
    entries.dedup();

    let picker = ["--height=60%", "--layout=reverse", "--prompt=path> "];
    if let Some(selection) = filter(
        Command::new("fzf").args(picker),
        &(entries.join("\n") + "\n"),
    ) {
        print!("{selection}");
    }
}
