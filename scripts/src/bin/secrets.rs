//! Store secrets in the macOS keychain and inject them into commands.
//!
//! Usage:
//!   secrets set SECRET_NAME
//!   secrets with SECRET_NAME ... -- COMMAND

use std::env;
use std::process::{Command, Stdio, exit};

use dotfiles_scripts::{capture, die, exec, run};

fn main() {
    let args: Vec<String> = env::args().skip(1).collect();
    match args.split_first() {
        Some((subcommand, rest)) if subcommand == "set" => set_secret(rest),
        Some((subcommand, rest)) if subcommand == "with" => with_secrets(rest),
        _ => {
            eprintln!("usage:");
            eprintln!("  secrets set SECRET_NAME");
            eprintln!("  secrets with SECRET_NAME ... -- COMMAND");
            exit(1);
        }
    }
}

/// Set a secret as a password in the macOS keychain under the USER namespace.
fn set_secret(args: &[String]) {
    let [name] = args else {
        die("usage: set_secret SECRET_NAME");
    };
    if name.is_empty() {
        die("usage: set_secret SECRET_NAME");
    }

    // `-w` without a value prompts for the password.
    run(Command::new("security").args(["add-generic-password", "-a", &user(), "-s", name, "-w"]));
}

/// Execute a command with secrets injected at run time as environment variables.
fn with_secrets(args: &[String]) {
    let Some((names, command)) = split_command(args) else {
        die("usage: with_secrets SECRET_NAME ... -- COMMAND");
    };

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

/// Split `NAME ... -- COMMAND ...`, requiring at least one of each.
fn split_command(args: &[String]) -> Option<(&[String], &[String])> {
    let delimiter = args.iter().position(|arg| arg == "--")?;
    let (names, command) = (&args[..delimiter], &args[delimiter + 1..]);
    (!names.is_empty() && !command.is_empty()).then_some((names, command))
}

fn user() -> String {
    env::var("USER").unwrap_or_else(|_| die("secrets: USER is not set"))
}

#[cfg(test)]
mod tests {
    use super::*;

    fn strings(values: &[&str]) -> Vec<String> {
        values.iter().map(|value| value.to_string()).collect()
    }

    #[test]
    fn split_command_separates_names_from_command() {
        let args = strings(&["A", "B", "--", "env", "--", "x"]);
        let (names, command) = split_command(&args).unwrap();
        assert_eq!(names, strings(&["A", "B"]));
        assert_eq!(command, strings(&["env", "--", "x"]));
    }

    #[test]
    fn split_command_requires_names_delimiter_and_command() {
        assert_eq!(split_command(&strings(&["A", "B"])), None);
        assert_eq!(split_command(&strings(&["--", "env"])), None);
        assert_eq!(split_command(&strings(&["A", "--"])), None);
    }
}
