//! Running coding-agent sessions and their state, for the pilo circle.
//!
//! Sources (records whose `pid` is gone are dropped):
//! - Claude Code's per-process files in `~/.claude/sessions/*.json`.
//! - The generic `${XDG_STATE_HOME:-~/.local/state}/agents/*.json` protocol,
//!   written by `opencode/plugins/agent-status` and anything else:
//!   `{"agent", "id", "pid", "name", "status": "busy"|"idle"|"waiting"}`.

use crate::util::{self, Out};
use serde_json::{Value, json};
use std::path::{Path, PathBuf};

fn state(raw: &str) -> Option<&'static str> {
    Some(match raw {
        "busy" | "retry" | "working" => "working",
        "idle" | "done" => "idle",
        "waiting" | "blocked" => "waiting",
        "failed" | "error" => "failed",
        _ => return None,
    })
}

fn alive(pid: &Value) -> bool {
    let Some(pid) = pid.as_i64().filter(|p| *p > 0 && *p < i32::MAX as i64) else {
        return false;
    };
    // kill(pid, 0): EPERM still means the process exists.
    unsafe { libc::kill(pid as i32, 0) == 0 || *libc::__error() == libc::EPERM }
}

fn files(dir: &Path) -> Vec<PathBuf> {
    let mut found: Vec<PathBuf> = std::fs::read_dir(dir)
        .map(|e| {
            e.flatten()
                .map(|e| e.path())
                .filter(|p| p.extension().is_some_and(|x| x == "json"))
                .collect()
        })
        .unwrap_or_default();
    found.sort();
    found
}

fn read(path: &Path) -> Option<Value> {
    serde_json::from_str::<Value>(&std::fs::read_to_string(path).ok()?)
        .ok()
        .filter(Value::is_object)
}

fn text(v: &Value, limit: usize) -> String {
    v.as_str()
        .map(|s| util::clean(s, limit))
        .unwrap_or_default()
}

pub fn agents() -> Out {
    let mut found: Vec<Value> = Vec::new();
    let mut push = |agent: String, id: String, pid: &Value, name: String, status: &Value| {
        let Some(st) = status.as_str().and_then(state) else {
            return;
        };
        if !alive(pid) {
            return;
        }
        let key = format!("{agent}:{id}");
        if found.iter().any(|f| f["key"] == key.as_str()) {
            return;
        }
        let name = if name.is_empty() { agent.clone() } else { name };
        found.push(json!({ "key": key, "agent": agent, "name": name, "state": st }));
    };
    let claude = std::env::var_os("CLAUDE_CONFIG_DIR")
        .map(PathBuf::from)
        .unwrap_or_else(|| util::home().join(".claude"));
    for path in files(&claude.join("sessions")) {
        let Some(d) = read(&path) else { continue };
        let cwd = text(&d["cwd"], 200);
        let base = cwd.rsplit('/').next().unwrap_or("").to_string();
        let name = Some(text(&d["name"], 40))
            .filter(|n| !n.is_empty())
            .unwrap_or(base);
        let id = Some(text(&d["sessionId"], 80))
            .filter(|n| !n.is_empty())
            .unwrap_or_else(|| path.display().to_string());
        push("claude".into(), id, &d["pid"], name, &d["status"]);
    }
    for path in files(&util::xdg("XDG_STATE_HOME", ".local/state").join("agents")) {
        let Some(d) = read(&path) else { continue };
        let agent = Some(text(&d["agent"], 20))
            .filter(|n| !n.is_empty())
            .unwrap_or_else(|| "agent".into());
        let id = Some(text(&d["id"], 80))
            .filter(|n| !n.is_empty())
            .unwrap_or_else(|| path.display().to_string());
        push(agent, id, &d["pid"], text(&d["name"], 40), &d["status"]);
    }
    found.sort_by(|a, b| a["key"].as_str().cmp(&b["key"].as_str()));
    found.truncate(20);
    Ok(json!({ "agents": found }))
}
