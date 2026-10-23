//! mnemonic: [G]it [F]ile [D]iff
//! Browse commits for a file with fzf, then open a
//! side-by-side diff of the selected commit in neovim.
//!
//! Usage: gfd <file>

use std::env;
use std::fs;
use std::path::Path;
use std::process::{self, Command};

use dotfiles_scripts::{die, exit_like, filter, read, shell_quote, status};

fn main() {
    let file = env::args()
        .nth(1)
        .filter(|arg| !arg.is_empty())
        .unwrap_or_else(|| die("Usage: gfd <file>"));
    if !Path::new(&file).is_file() {
        die(format!("Error: File '{file}' not found"));
    }

    let rel_file = read(Command::new("git").args(["ls-files", "--full-name", &file]))
        .trim()
        .to_owned();

    let commits = read(Command::new("git").args(["log", "--follow", "--oneline", "--", &file]));
    let preview = format!(
        "git show {{1}}:{rel} 2>/dev/null | bat --color=always --style=numbers --file-name={rel} || echo 'File not found in this commit'",
        rel = shell_quote(&rel_file),
    );
    let commit = filter(
        Command::new("fzf").args([
            "--height=80%",
            &format!("--preview={preview}"),
            "--preview-window=right:60%",
            "--header=Select commit to diff against current version (ESC to cancel)",
        ]),
        &commits,
    )
    .and_then(|line| line.split_whitespace().next().map(str::to_owned));

    let Some(commit) = commit else {
        println!("No commit selected");
        return;
    };

    let old = Command::new("git")
        .args(["show", &format!("{commit}:{rel_file}")])
        .output()
        .unwrap_or_else(|err| die(format!("git: {err}")));
    if !old.status.success() {
        exit_like(old.status);
    }

    // Keep the file name so Neovim detects the filetype.
    let name = Path::new(&rel_file)
        .file_name()
        .unwrap_or_default()
        .to_string_lossy();
    let tmpfile = env::temp_dir().join(format!("gfd-{}-{name}", process::id()));
    fs::write(&tmpfile, old.stdout)
        .unwrap_or_else(|err| die(format!("{}: {err}", tmpfile.display())));

    let diff = status(Command::new("nvim").arg("-d").arg(&tmpfile).arg(&file));
    let _ = fs::remove_file(&tmpfile);
    if !diff.success() {
        exit_like(diff);
    }
}
