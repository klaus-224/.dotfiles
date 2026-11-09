//! mnemonic: [G]it [B]ranch [D]elete
//! Pick local branches and worktrees with fzf (TAB to multi-select), then
//! remove each selected worktree and delete its branch.
//! See `dotfiles_scripts::cleanup` for what is listed and asked.

use clap::Parser;
use dotfiles_scripts::cleanup::{self, Options};

/// Pick local branches and worktrees with fzf, then delete them.
#[derive(Parser)]
struct Cli {
    /// Also delete the picked branches on origin.
    #[arg(short, long)]
    remote: bool,
}

fn main() {
    let Cli { remote } = Cli::parse();
    cleanup::run(&Options {
        name: "gbd",
        worktrees_only: false,
        delete_branches: true,
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
}
