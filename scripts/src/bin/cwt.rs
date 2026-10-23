//! Create a sibling Git worktree and optionally dispatch Claude into it.
//!
//! Usage: cwt current|main branch [prompt]

use std::env;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};

use dotfiles_scripts::{die, read, run, status};

const USAGE: &str = "Usage: cwt current|main branch [prompt]";

fn main() {
    let mut args = env::args().skip(1);
    let mode = args
        .next()
        .filter(|arg| !arg.is_empty())
        .unwrap_or_else(|| die(USAGE));
    let branch = args
        .next()
        .filter(|arg| !arg.is_empty())
        .unwrap_or_else(|| die("cwt: Missing branch name"));
    let prompt: Vec<String> = args.collect();

    run(Command::new("git")
        .args(["check-ref-format", "--branch", &branch])
        .stdout(Stdio::null()));

    let root = main_worktree(&read(Command::new("git").args([
        "worktree",
        "list",
        "--porcelain",
    ])))
    .unwrap_or_else(|| die("cwt: could not find the main worktree"));
    let path = worktree_path(&root, &branch);

    let base = match mode.as_str() {
        "current" => "HEAD",
        "main" => {
            run(Command::new("git").args(["fetch", "origin", "main"]));
            "origin/main"
        }
        _ => die("Expected current or main"),
    };

    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent)
            .unwrap_or_else(|err| die(format!("{}: {err}", parent.display())));
    }

    run(Command::new("git")
        .args(["worktree", "add", "--no-track", "-b", &branch])
        .arg(&path)
        .arg(base));

    // Copy local environment only when Git ignores it
    let env_local = root.join(".env.local");
    if env_local.is_file()
        && status(Command::new("git").arg("-C").arg(&path).args([
            "check-ignore",
            "-q",
            ".env.local",
        ]))
        .success()
    {
        fs::copy(&env_local, path.join(".env.local"))
            .unwrap_or_else(|err| die(format!("cwt: copy .env.local: {err}")));
    }

    println!("Created {} from {base}", path.display());

    // Optional: dispatch Claude in the background
    if !prompt.is_empty() {
        run(Command::new("claude").current_dir(&path).args([
            "--bg",
            "--name",
            &branch,
            &prompt.join(" "),
        ]));
    }
}

/// The main worktree is always listed first by `git worktree list`.
fn main_worktree(porcelain: &str) -> Option<PathBuf> {
    porcelain
        .lines()
        .next()?
        .strip_prefix("worktree ")
        .map(PathBuf::from)
}

/// `/code/repo` + `feat/x` -> `/code/repo-worktrees/feat/x`
fn worktree_path(root: &Path, branch: &str) -> PathBuf {
    let name = root.file_name().unwrap_or_default().to_string_lossy();
    root.with_file_name(format!("{name}-worktrees"))
        .join(branch)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn main_worktree_is_the_first_entry() {
        let porcelain = "worktree /code/repo\nHEAD abc\n\nworktree /code/other\n";
        assert_eq!(main_worktree(porcelain), Some(PathBuf::from("/code/repo")));
    }

    #[test]
    fn worktree_path_is_a_sibling_of_the_main_worktree() {
        assert_eq!(
            worktree_path(Path::new("/code/repo"), "feat/x"),
            PathBuf::from("/code/repo-worktrees/feat/x"),
        );
    }
}
