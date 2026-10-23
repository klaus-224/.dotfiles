//! Pick a Claude background session and open it in a new tmux window.
//!
//! Usage: claude-tmux
//!
//! The window has nvim on the left, a shell top right, and `claude attach`
//! bottom right, all rooted in the session's working directory.

use std::env;
use std::path::Path;
use std::process::Command;

use serde_json::Value;

use dotfiles_scripts::{die, filter, has_command, read, run};

const USAGE: &str = "\
Usage: claude-tmux

Pick a Claude background session (`claude agents --json --all`) and open it
in a new tmux window: nvim on the left, a shell top right, and
`claude attach <id>` bottom right, all in the session's directory.";

/// Runs in the Claude pane. The id arrives as `$1`, never as shell text, and the
/// pane falls back to a shell so attach errors stay readable.
const ATTACH: &str = r#"claude attach "$1"; exec "${SHELL:-/bin/sh}""#;

#[derive(Debug, PartialEq)]
struct Session {
    id: String,
    cwd: String,
    name: Option<String>,
    state: Option<String>,
}

fn main() {
    match env::args().nth(1).as_deref() {
        None => {}
        Some("--help" | "-h") => {
            println!("{USAGE}");
            return;
        }
        Some(arg) => die(format!("claude-tmux: unexpected argument: {arg}\n{USAGE}")),
    }

    if env::var_os("TMUX").is_none() {
        die("claude-tmux: run this inside tmux");
    }
    let missing: Vec<&str> = ["claude", "fzf", "nvim", "tmux"]
        .into_iter()
        .filter(|cmd| !has_command(cmd))
        .collect();
    if !missing.is_empty() {
        die(format!(
            "claude-tmux: missing dependencies: {}",
            missing.join(" ")
        ));
    }

    // Popups have no TMUX_PANE, but tmux still resolves the caller's session.
    let target = read(&mut tmux(&["display-message", "-p", "#{session_id}"]))
        .trim()
        .to_owned();

    let json = read(Command::new("claude").args(["agents", "--json", "--all"]));
    let sessions = parse_sessions(&json).unwrap_or_else(|err| die(format!("claude-tmux: {err}")));
    if sessions.is_empty() {
        die("claude-tmux: no background sessions");
    }

    let Some(session) = pick(&sessions) else {
        return;
    };
    if !Path::new(&session.cwd).is_dir() {
        die(format!(
            "claude-tmux: directory not found: {}",
            sanitize(&session.cwd)
        ));
    }

    open_window(&target, session);
}

/// Background sessions with a usable id and directory, in Claude's order.
fn parse_sessions(json: &str) -> Result<Vec<Session>, String> {
    let value: Value = serde_json::from_str(json)
        .map_err(|err| format!("invalid JSON from claude agents: {err}"))?;
    let records = value
        .as_array()
        .ok_or("claude agents: expected a JSON array")?;

    let text = |record: &Value, key: &str| {
        record
            .get(key)
            .and_then(Value::as_str)
            .filter(|value| !value.is_empty())
            .map(str::to_owned)
    };

    Ok(records
        .iter()
        .filter(|record| record.get("kind").and_then(Value::as_str) == Some("background"))
        .filter_map(|record| {
            Some(Session {
                id: text(record, "id")?,
                cwd: text(record, "cwd")?,
                name: text(record, "name"),
                state: text(record, "state").or_else(|| text(record, "status")),
            })
        })
        .collect())
}

/// Pick a session with fzf, or `None` if the picker is cancelled.
///
/// Each line starts with its index, which fzf hides, so the selection maps back
/// to the original record instead of being parsed from display text.
fn pick(sessions: &[Session]) -> Option<&Session> {
    let home = env::var("HOME").unwrap_or_default();
    let input: String = sessions
        .iter()
        .enumerate()
        .map(|(index, session)| format!("{index}\t{}\n", display(session, &home)))
        .collect();

    let selection = filter(
        Command::new("fzf").args([
            "--layout=reverse",
            "--border",
            "--delimiter=\t",
            "--with-nth=2..",
            "--no-sort",
            "--header=NAME | STATE | DIRECTORY",
            "--prompt=claude> ",
        ]),
        &input,
    )?;
    let index: usize = selection.split('\t').next()?.parse().ok()?;
    sessions.get(index)
}

fn display(session: &Session, home: &str) -> String {
    let cwd = match session.cwd.strip_prefix(home) {
        Some(rest) if !home.is_empty() && (rest.is_empty() || rest.starts_with('/')) => {
            format!("~{rest}")
        }
        _ => session.cwd.clone(),
    };
    format!(
        "{:<32}  {:<8}  {}",
        sanitize(session.name.as_deref().unwrap_or("(unnamed)")),
        sanitize(session.state.as_deref().unwrap_or("-")),
        sanitize(&cwd),
    )
}

/// Replace control characters so names and paths cannot break the picker.
fn sanitize(text: &str) -> String {
    text.chars()
        .map(|c| if c.is_control() { '?' } else { c })
        .collect()
}

/// tmux expands formats in `-c`, so a literal `#` must be doubled.
fn tmux_escape(text: &str) -> String {
    text.replace('#', "##")
}

fn tmux(args: &[&str]) -> Command {
    let mut command = Command::new("tmux");
    command.args(args);
    command
}

fn open_window(target: &str, session: &Session) {
    let dir = tmux_escape(&session.cwd);

    // `$1:` adds a window at the next free index of the caller's session.
    let ids = read(&mut tmux(&[
        "new-window",
        "-t",
        &format!("{target}:"),
        "-c",
        &dir,
        "-P",
        "-F",
        "#{window_id} #{pane_id}",
        "nvim",
        ".",
    ]));
    let Some((window, code)) = ids.trim().split_once(' ') else {
        die(format!("claude-tmux: unexpected new-window output: {ids}"));
    };

    let claude = read(&mut tmux(&[
        "split-window",
        "-h",
        "-l",
        "55%",
        "-t",
        code,
        "-c",
        &dir,
        "-P",
        "-F",
        "#{pane_id}",
        "/bin/sh",
        "-c",
        ATTACH,
        "claude-tmux",
        &session.id,
    ]));
    let claude = claude.trim();

    run(&mut tmux(&[
        "split-window",
        "-v",
        "-b",
        "-l",
        "30%",
        "-t",
        claude,
        "-c",
        &dir,
    ]));
    run(&mut tmux(&["select-window", "-t", window]));
    run(&mut tmux(&["select-pane", "-t", claude]));
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parse_sessions_keeps_usable_background_sessions() {
        let json = r#"[
            {"id": "a1", "cwd": "/code/a", "kind": "background", "name": "feat/a", "state": "working"},
            {"id": "b2", "cwd": "/code/b", "kind": "background", "status": "idle"},
            {"id": "c3", "cwd": "/code/c", "kind": "interactive"},
            {"id": "", "cwd": "/code/d", "kind": "background"},
            {"id": "e5", "kind": "background"},
            {"id": 6, "cwd": "/code/f", "kind": "background"}
        ]"#;
        assert_eq!(
            parse_sessions(json),
            Ok(vec![
                Session {
                    id: "a1".into(),
                    cwd: "/code/a".into(),
                    name: Some("feat/a".into()),
                    state: Some("working".into()),
                },
                Session {
                    id: "b2".into(),
                    cwd: "/code/b".into(),
                    name: None,
                    state: Some("idle".into()),
                },
            ]),
        );
    }

    #[test]
    fn parse_sessions_rejects_bad_shapes() {
        assert!(parse_sessions("not json").is_err());
        assert!(parse_sessions(r#"{"id": "a1"}"#).is_err());
        assert_eq!(parse_sessions("[]"), Ok(vec![]));
    }

    #[test]
    fn display_shortens_home_and_fills_missing_fields() {
        let session = Session {
            id: "a1".into(),
            cwd: "/Users/me/code/a".into(),
            name: None,
            state: None,
        };
        assert_eq!(
            display(&session, "/Users/me"),
            format!("{:<32}  {:<8}  ~/code/a", "(unnamed)", "-"),
        );
        assert!(display(&session, "/Users/m").ends_with("/Users/me/code/a"));
    }

    #[test]
    fn sanitize_replaces_control_characters() {
        assert_eq!(sanitize("a\tb\nc\x1b[31m"), "a?b?c?[31m");
    }

    #[test]
    fn tmux_escape_doubles_hashes() {
        assert_eq!(tmux_escape("/x/#(touch y)/#{z}"), "/x/##(touch y)/##{z}");
    }
}
