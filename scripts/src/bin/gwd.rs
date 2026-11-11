//! mnemonic: [G]it [W]orktree [D]elete
//! Pick worktrees with fzf (TAB to multi-select), then remove them.
//! Branches stay unless `--branch` is given.
//! See `dotfiles_scripts::cleanup` for what is listed and asked.

use clap::Parser;
use dotfiles_scripts::cleanup::{self, Options};

/// Pick worktrees with fzf, then remove them.
#[derive(Parser)]
struct Cli {
    /// Also delete each picked worktree's branch.
    #[arg(short, long)]
    branch: bool,
    /// Also delete the branch on origin.
    #[arg(short, long, requires = "branch")]
    remote: bool,
}

fn main() {
    let Cli { branch, remote } = Cli::parse();
    cleanup::run(&Options {
        name: "gwd",
        worktrees_only: true,
        delete_branches: branch,
        remote,
    });
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn cli_is_valid() {
        use clap::CommandFactory;
        Cli::command().debug_assert();
    }

    #[test]
    fn remote_requires_branch() {
        assert!(Cli::try_parse_from(["gwd", "--remote"]).is_err());
        assert!(Cli::try_parse_from(["gwd", "-br"]).is_ok());
    }
}
