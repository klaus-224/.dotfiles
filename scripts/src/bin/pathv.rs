//! Small fzf viewer for PATH entries.

use std::env;
use std::process::Command;

use clap::Parser;
use dotfiles_scripts::{die, filter, has_command};

/// Browse PATH entries with fzf and print the selection.
#[derive(Parser)]
struct Cli {}

fn main() {
    Cli::parse();
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

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn cli_is_valid() {
        use clap::CommandFactory;
        Cli::command().debug_assert();
    }
}
