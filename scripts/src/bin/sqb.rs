//! mnemonic: [S][Q]L SCRATCH [B]UFFER
//! Opens a temporary SQL buffer in Neovim with syntax highlighting and LSP
//!
//! Usage:
//!   sqb                 # Open empty SQL scratch buffer
//!   pbpaste | sqb       # Pipe SQL from clipboard
//!   cat query.sql | sqb

use std::env;
use std::io::{self, IsTerminal};
use std::process::{Command, exit};

use dotfiles_scripts::{exit_like, has_command, status};

fn main() {
    // Match nvim/lsp/{sqlls,postgres_lsp}.lua; never install on invocation.
    if !has_command("sqls") && !has_command("postgres-language-server") {
        eprintln!(
            "sqb: SQL LSP unavailable; configure sqls (work) or postgres-language-server (personal). Opening without SQL LSP."
        );
    }

    let editor = env::var("EDITOR")
        .ok()
        .filter(|editor| !editor.is_empty())
        .unwrap_or_else(|| "nvim".to_owned());
    if !has_command(&editor) {
        eprintln!(
            "sqb: editor not found: {editor} (EDITOR must name one executable; default: nvim)."
        );
        exit(127);
    }

    let mut command = Command::new(&editor);
    command.args([
        "-c",
        "setfiletype sql",
        "-c",
        "setlocal buftype=nofile bufhidden=wipe noswapfile",
    ]);
    // Read piped SQL into the buffer
    if !io::stdin().is_terminal() {
        command.arg("-");
    }
    exit_like(status(&mut command));
}
