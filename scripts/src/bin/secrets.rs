//! Store secrets in the macOS keychain and inject them into commands.
//!
//! Usage:
//!   secrets set SECRET_NAME
//!   secrets with SECRET_NAME ... -- COMMAND

use std::env;
use std::process::{Command, Stdio};

use clap::Parser;
use dotfiles_scripts::{capture, die, exec, run};

/// Store secrets in the macOS keychain and inject them into commands.
#[derive(Parser)]
struct Cli {
    #[command(subcommand)]
    command: Subcommand,
}

#[derive(clap::Subcommand)]
enum Subcommand {
    /// Store a secret; prompts for its value.
    Set { name: String },
    /// Run COMMAND with the named secrets as environment variables.
    With {
        #[arg(required = true, value_name = "SECRET_NAME")]
        names: Vec<String>,
        #[arg(last = true, required = true)]
        command: Vec<String>,
    },
}

fn main() {
    match Cli::parse().command {
        Subcommand::Set { name } => set_secret(&name),
        Subcommand::With { names, command } => with_secrets(&names, &command),
    }
}

/// Set a secret as a password in the macOS keychain under the USER namespace.
fn set_secret(name: &str) {
    // `-w` without a value prompts for the password.
    run(Command::new("security").args(["add-generic-password", "-a", &user(), "-s", name, "-w"]));
}

/// Execute a command with secrets injected at run time as environment variables.
fn with_secrets(names: &[String], command: &[String]) {
    // Grab secrets from the macOS keychain in the USER space
    let user = user();
    let secrets: Vec<(&String, String)> = names
        .iter()
        .map(|name| {
            let value = capture(
                Command::new("security")
                    .args(["find-generic-password", "-a", &user, "-s", name, "-w"])
                    .stdin(Stdio::null()),
            )
            .unwrap_or_else(|| die(format!("with_secrets: failed to read secret: {name}")));
            (name, value.trim_end_matches('\n').to_owned())
        })
        .collect();

    exec(Command::new(&command[0]).args(&command[1..]).envs(secrets));
}

fn user() -> String {
    env::var("USER").unwrap_or_else(|_| die("secrets: USER is not set"))
}

#[cfg(test)]
mod tests {
    use super::*;
    use clap::CommandFactory;

    #[test]
    fn cli_is_valid() {
        Cli::command().debug_assert();
    }

    #[test]
    fn with_splits_names_from_command_at_the_first_delimiter() {
        let cli =
            Cli::try_parse_from(["secrets", "with", "A", "B", "--", "env", "--", "x"]).unwrap();
        let Subcommand::With { names, command } = cli.command else {
            panic!("expected with");
        };
        assert_eq!(names, ["A", "B"]);
        assert_eq!(command, ["env", "--", "x"]);
    }

    #[test]
    fn with_requires_names_delimiter_and_command() {
        for args in [
            &["secrets", "with", "A", "B"][..],
            &["secrets", "with", "--", "env"],
            &["secrets", "with", "A", "--"],
        ] {
            assert!(Cli::try_parse_from(args).is_err(), "{args:?}");
        }
    }
}
