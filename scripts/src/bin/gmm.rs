//! mnemonic: [G]it [M]erge [M]ain
//! Fetch origin/<base>, preview the merge in memory with `git merge-tree`,
//! then merge it into the current branch with `git merge`.
//!
//! Usage: gmm [--resolve] [base]
//!
//! Conflicts stop before touching the worktree unless `--resolve` is given,
//! which starts the merge and opens `git mergetool`.

use std::env;
use std::process::{Command, Stdio};

use dotfiles_scripts::{capture, die, exit_like, read, run, status};

const USAGE: &str = "Usage: gmm [--resolve] [base]";

fn main() {
    let mut resolve = false;
    let mut base = String::from("main");
    for arg in env::args().skip(1) {
        match arg.as_str() {
            "--resolve" => resolve = true,
            "-h" | "--help" => {
                println!("{USAGE}");
                return;
            }
            _ if arg.starts_with('-') || arg.is_empty() => die(USAGE),
            _ => base = arg,
        }
    }

    let branch = capture(Command::new("git").args(["symbolic-ref", "--quiet", "--short", "HEAD"]))
        .map(|name| name.trim().to_owned())
        .unwrap_or_else(|| die("gmm: HEAD is detached; check out a branch first"));
    if branch == base {
        die(format!("gmm: already on {base}"));
    }

    // A merge needs a clean index and worktree so it can be aborted safely.
    let dirty = read(Command::new("git").args(["status", "--porcelain", "--untracked-files=no"]));
    if !dirty.trim().is_empty() {
        die("gmm: commit or set aside tracked changes before merging");
    }

    run(Command::new("git").args(["fetch", "origin", &base]));
    let upstream = format!("origin/{base}");

    if status(Command::new("git").args(["merge-base", "--is-ancestor", &upstream, "HEAD"]))
        .success()
    {
        println!("{branch} already contains {upstream}");
        return;
    }

    println!("Incoming from {upstream}:");
    run(Command::new("git").args([
        "log",
        "--oneline",
        "--no-decorate",
        &format!("HEAD..{upstream}"),
    ]));

    // Merge in memory first: no index, worktree, or ref changes.
    let preview = Command::new("git")
        .args([
            "merge-tree",
            "--write-tree",
            "--name-only",
            "--no-messages",
            "HEAD",
            &upstream,
        ])
        .stderr(Stdio::inherit())
        .output()
        .unwrap_or_else(|err| die(format!("git: {err}")));
    let conflicts = match preview.status.code() {
        Some(0) => Vec::new(),
        Some(1) => conflicted_files(&String::from_utf8_lossy(&preview.stdout)),
        _ => exit_like(preview.status),
    };

    if conflicts.is_empty() {
        println!("\nNo conflicts; merging {upstream} into {branch}");
        // prepare-commit-msg rewrites Git's "Merge ..." subject to the commit policy.
        run(Command::new("git").args(["merge", "--no-edit", &upstream]));
        return;
    }

    println!("\nConflicts with {upstream}:");
    for file in &conflicts {
        println!("  {file}");
    }
    if !resolve {
        println!("\nNothing changed. Run `gmm --resolve {base}` to merge and open the mergetool.");
        std::process::exit(1);
    }

    // Expected to fail with conflicts; mergetool takes over from here.
    status(Command::new("git").args(["merge", "--no-edit", &upstream]));
    status(Command::new("git").arg("mergetool"));
    println!(
        "\nReview with `git diff --staged`, then `git merge --continue` or `git merge --abort`."
    );
}

/// `git merge-tree --name-only` prints the tree OID, then one conflicted path
/// per line, then a blank line before any informational messages.
fn conflicted_files(output: &str) -> Vec<String> {
    output
        .lines()
        .skip(1)
        .take_while(|line| !line.is_empty())
        .map(str::to_owned)
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn conflicted_files_skips_the_tree_oid() {
        assert_eq!(
            conflicted_files("abc123\na.txt\ndir/b.txt\n"),
            ["a.txt", "dir/b.txt"]
        );
    }

    #[test]
    fn conflicted_files_stops_before_messages() {
        assert_eq!(
            conflicted_files("abc123\na.txt\n\nAuto-merging a.txt\nCONFLICT (content)\n"),
            ["a.txt"],
        );
    }

    #[test]
    fn conflicted_files_is_empty_for_a_clean_merge() {
        assert!(conflicted_files("abc123\n").is_empty());
    }
}
