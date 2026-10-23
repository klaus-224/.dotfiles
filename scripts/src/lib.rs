//! Process helpers shared by the scripts in `src/bin/`.

use std::env;
use std::fmt::Display;
use std::io::{self, Write};
use std::os::unix::fs::PermissionsExt;
use std::os::unix::process::{CommandExt, ExitStatusExt};
use std::path::Path;
use std::process::{Command, ExitStatus, Stdio, exit};
use std::thread;

/// Print `message` to stderr and exit 1.
pub fn die(message: impl Display) -> ! {
    eprintln!("{message}");
    exit(1);
}

/// Exit with the same code as a finished child, like a shell would.
pub fn exit_like(status: ExitStatus) -> ! {
    exit(
        status
            .code()
            .unwrap_or_else(|| 128 + status.signal().unwrap_or(0)),
    );
}

/// Run `command` with inherited stdio and return its exit status.
pub fn status(command: &mut Command) -> ExitStatus {
    command
        .status()
        .unwrap_or_else(|err| die(spawn_error(command, err)))
}

/// Run `command` with inherited stdio and exit with its code if it fails.
pub fn run(command: &mut Command) {
    let status = status(command);
    if !status.success() {
        exit_like(status);
    }
}

/// Capture stdout from `command`, or `None` if it fails. Stderr is inherited.
pub fn capture(command: &mut Command) -> Option<String> {
    let output = command
        .stderr(Stdio::inherit())
        .output()
        .unwrap_or_else(|err| die(spawn_error(command, err)));
    output
        .status
        .success()
        .then(|| String::from_utf8_lossy(&output.stdout).into_owned())
}

/// Capture stdout from `command`, exiting with its code if it fails.
pub fn read(command: &mut Command) -> String {
    let output = command
        .stderr(Stdio::inherit())
        .output()
        .unwrap_or_else(|err| die(spawn_error(command, err)));
    if !output.status.success() {
        exit_like(output.status);
    }
    String::from_utf8_lossy(&output.stdout).into_owned()
}

/// Feed `input` to `command` and capture its stdout, or `None` if it fails.
///
/// Used for pickers like fzf, which draw on the terminal and print the selection.
pub fn filter(command: &mut Command, input: &str) -> Option<String> {
    let mut child = command
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .spawn()
        .unwrap_or_else(|err| die(spawn_error(command, err)));

    let mut stdin = child.stdin.take().expect("stdin is piped");
    let input = input.to_owned();
    // The picker may exit before reading everything, so ignore broken pipes.
    let writer = thread::spawn(move || stdin.write_all(input.as_bytes()));

    let output = child
        .wait_with_output()
        .unwrap_or_else(|err| die(spawn_error(command, err)));
    let _ = writer.join();

    output
        .status
        .success()
        .then(|| String::from_utf8_lossy(&output.stdout).into_owned())
}

/// Replace the current process with `command`.
pub fn exec(command: &mut Command) -> ! {
    let err = command.exec();
    die(spawn_error(command, err))
}

/// Whether `name` resolves to an executable, like `command -v`.
pub fn has_command(name: &str) -> bool {
    if name.contains('/') {
        return is_executable(Path::new(name));
    }
    env::var_os("PATH")
        .is_some_and(|path| env::split_paths(&path).any(|dir| is_executable(&dir.join(name))))
}

fn is_executable(path: &Path) -> bool {
    path.metadata()
        .is_ok_and(|meta| meta.is_file() && meta.permissions().mode() & 0o111 != 0)
}

/// Quote `value` for interpolation into a shell command, such as an fzf preview.
pub fn shell_quote(value: &str) -> String {
    format!("'{}'", value.replace('\'', r"'\''"))
}

fn spawn_error(command: &Command, err: io::Error) -> String {
    format!("{}: {err}", command.get_program().display())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn shell_quote_escapes_single_quotes() {
        assert_eq!(shell_quote("it's"), r"'it'\''s'");
    }

    #[test]
    fn filter_returns_stdout_on_success() {
        assert_eq!(
            filter(&mut Command::new("cat"), "a\nb\n").as_deref(),
            Some("a\nb\n")
        );
    }

    #[test]
    fn filter_returns_none_on_failure() {
        assert_eq!(filter(&mut Command::new("false"), "a"), None);
    }

    #[test]
    fn has_command_finds_executables_on_path() {
        assert!(has_command("sh"));
        assert!(!has_command("definitely-not-a-command"));
    }
}
