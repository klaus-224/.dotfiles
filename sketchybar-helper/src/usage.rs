//! Coding-agent usage, read from local files only (no network, no tokens).
//!
//! - Claude: `~/.claude/abtop-rate-limits.json` (written by the abtop status
//!   line hook from Claude Code's `rate_limits`), then the `/usage` cache in
//!   `~/.claude.json`.
//! - Codex: the newest `rate_limits` record in `~/.codex/sessions` rollouts.
//! - OpenCode: token and cost totals from its SQLite session table.

use crate::util::{self, Out};
use serde_json::{Value, json};
use std::collections::HashMap;
use std::io::{Read, Seek, SeekFrom};
use std::path::{Path, PathBuf};

pub fn usage() -> Out {
    let mut out = serde_json::Map::new();
    if let Some(c) = claude() {
        out.insert("claude".into(), c);
    }
    if let Some(c) = codex() {
        out.insert("codex".into(), c);
    }
    if let Some(o) = opencode() {
        out.insert("opencode".into(), o);
    }
    Ok(Value::Object(out))
}

/// A usage window; a window whose reset time has passed is unused (0%).
fn window(used: Option<f64>, resets_at: Option<f64>) -> Value {
    let Some(used) = used else { return Value::Null };
    match resets_at {
        Some(r) if r > util::now() => json!({ "used": used.round(), "resets_at": r as i64 }),
        Some(_) => json!({ "used": 0, "resets_at": null }),
        None => json!({ "used": used.round(), "resets_at": null }),
    }
}

fn read_json(path: &Path) -> Option<Value> {
    serde_json::from_str(&std::fs::read_to_string(path).ok()?).ok()
}

fn claude() -> Option<Value> {
    let dir = std::env::var_os("CLAUDE_CONFIG_DIR")
        .map(PathBuf::from)
        .unwrap_or_else(|| util::home().join(".claude"));
    if let Some(v) = read_json(&dir.join("abtop-rate-limits.json")) {
        let w = |k: &str| window(v[k]["used_percentage"].as_f64(), v[k]["resets_at"].as_f64());
        return Some(
            json!({ "five": w("five_hour"), "week": w("seven_day"), "updated_at": v["updated_at"] }),
        );
    }
    let v = read_json(&util::home().join(".claude.json"))?;
    let cache = &v["cachedUsageUtilization"];
    let u = &cache["utilization"];
    if !u.is_object() {
        return dir.exists().then(|| json!({ "five": null, "week": null }));
    }
    let w = |k: &str| {
        window(
            u[k]["utilization"].as_f64(),
            u[k]["resets_at"].as_str().and_then(util::parse_iso),
        )
    };
    Some(json!({
        "five": w("five_hour"),
        "week": w("seven_day"),
        "updated_at": cache["fetchedAtMs"].as_f64().map(|t| (t / 1000.0) as i64),
    }))
}

fn rollouts(dir: &Path, found: &mut Vec<PathBuf>) {
    let Ok(entries) = std::fs::read_dir(dir) else {
        return;
    };
    for entry in entries.flatten() {
        let path = entry.path();
        if path.is_dir() {
            rollouts(&path, found);
        } else if path
            .file_name()
            .and_then(|n| n.to_str())
            .is_some_and(|n| n.starts_with("rollout-") && n.ends_with(".jsonl"))
        {
            found.push(path);
        }
    }
}

fn tail(path: &Path, bytes: u64) -> Option<String> {
    let mut file = std::fs::File::open(path).ok()?;
    let len = file.metadata().ok()?.len();
    file.seek(SeekFrom::Start(len.saturating_sub(bytes))).ok()?;
    let mut buf = Vec::new();
    file.read_to_end(&mut buf).ok()?;
    Some(String::from_utf8_lossy(&buf).into_owned())
}

fn codex() -> Option<Value> {
    let root = std::env::var_os("CODEX_HOME")
        .map(PathBuf::from)
        .unwrap_or_else(|| util::home().join(".codex"));
    if !root.exists() {
        return None;
    }
    let mut files = Vec::new();
    rollouts(&root.join("sessions"), &mut files);
    rollouts(&root.join("archived_sessions"), &mut files);
    // Newest by name (date) and by mtime: resumed sessions append to old names.
    let mut by_name = files.clone();
    by_name.sort_by(|a, b| b.file_name().cmp(&a.file_name()));
    let mtime = |p: &PathBuf| p.metadata().and_then(|m| m.modified()).ok();
    let mut by_mtime = files;
    by_mtime.sort_by_key(|p| std::cmp::Reverse(mtime(p)));
    let mut candidates: Vec<PathBuf> = by_name.into_iter().take(10).collect();
    for p in by_mtime.into_iter().take(10) {
        if !candidates.contains(&p) {
            candidates.push(p);
        }
    }
    let mut best: Option<(String, Value)> = None;
    for path in candidates {
        let Some(text) = tail(&path, 200_000) else {
            continue;
        };
        for line in text.lines().filter(|l| l.contains("\"rate_limits\"")) {
            let Ok(row) = serde_json::from_str::<Value>(line) else {
                continue;
            };
            let limits = &row["payload"]["rate_limits"];
            if limits["primary"]["used_percent"].as_f64().is_none() {
                continue;
            }
            let at = row["timestamp"].as_str().unwrap_or("").to_string();
            if best.as_ref().is_none_or(|(t, _)| at > *t) {
                best = Some((at, limits.clone()));
            }
        }
    }
    let Some((at, limits)) = best else {
        return Some(json!({ "five": null, "week": null }));
    };
    let seen = util::parse_iso(&at);
    // Newer Codex writes `resets_at` (epoch s); older `resets_in_seconds`.
    let reset = |w: &Value| {
        w["resets_at"]
            .as_f64()
            .or_else(|| Some(seen? + w["resets_in_seconds"].as_f64()?))
    };
    let w = |k: &str| window(limits[k]["used_percent"].as_f64(), reset(&limits[k]));
    Some(
        json!({ "five": w("primary"), "week": w("secondary"), "updated_at": seen.map(|t| t as i64) }),
    )
}

#[derive(Default, Clone, Copy)]
struct Totals {
    input: i64,
    output: i64,
    reasoning: i64,
    cache_read: i64,
    cache_write: i64,
    cost: f64,
    sessions: i64,
}

impl Totals {
    fn add(&mut self, o: &Totals) {
        self.input += o.input;
        self.output += o.output;
        self.reasoning += o.reasoning;
        self.cache_read += o.cache_read;
        self.cache_write += o.cache_write;
        self.cost += o.cost;
        self.sessions += o.sessions;
    }
    fn tokens(&self) -> i64 {
        self.input + self.output + self.reasoning
    }
    fn json(&self) -> Value {
        json!({
            "tokens": self.tokens(), "input": self.input, "output": self.output,
            "reasoning": self.reasoning, "cache_read": self.cache_read, "cache_write": self.cache_write,
            "cost": (self.cost * 100.0).round() / 100.0, "sessions": self.sessions,
        })
    }
}

fn model_name(raw: &str) -> String {
    serde_json::from_str::<Value>(raw)
        .ok()
        .and_then(|v| v["id"].as_str().map(String::from))
        .unwrap_or_else(|| raw.to_string())
}

/// OpenCode keeps per-session token totals in `session` (one DB per channel,
/// e.g. `opencode.db` and `opencode-stable.db`). Sessions count toward the
/// day they were last updated; multi-day sessions are therefore approximate.
/// Top models cover the last 30 days.
fn opencode() -> Option<Value> {
    let dir = util::xdg("XDG_DATA_HOME", ".local/share").join("opencode");
    let entries = std::fs::read_dir(&dir).ok()?;
    let since = (util::local_midnight() - 29 * 86400) * 1000;
    let week_start = (util::local_midnight() - 6 * 86400) * 1000;
    let today = util::local_midnight() * 1000;
    let mut sessions: HashMap<String, (i64, String, Totals)> = HashMap::new();
    for entry in entries.flatten() {
        let path = entry.path();
        let name = path.file_name().and_then(|n| n.to_str()).unwrap_or("");
        if !(name.starts_with("opencode") && name.ends_with(".db"))
            || entry.metadata().map(|m| m.len()).unwrap_or(0) == 0
        {
            continue;
        }
        let flags =
            rusqlite::OpenFlags::SQLITE_OPEN_READ_ONLY | rusqlite::OpenFlags::SQLITE_OPEN_NO_MUTEX;
        let Ok(db) = rusqlite::Connection::open_with_flags(&path, flags) else {
            continue;
        };
        let _ = db.busy_timeout(std::time::Duration::from_millis(500));
        let Ok(mut stmt) = db.prepare(
            "SELECT id, COALESCE(model, ''), cost, tokens_input, tokens_output, tokens_reasoning, \
             tokens_cache_read, tokens_cache_write, time_updated FROM session WHERE time_updated >= ?1",
        ) else {
            continue;
        };
        let rows = stmt.query_map([since], |r| {
            Ok((
                r.get::<_, String>(0)?,
                r.get::<_, String>(1)?,
                Totals {
                    cost: r.get(2)?,
                    input: r.get(3)?,
                    output: r.get(4)?,
                    reasoning: r.get(5)?,
                    cache_read: r.get(6)?,
                    cache_write: r.get(7)?,
                    sessions: 1,
                },
                r.get::<_, i64>(8)?,
            ))
        });
        let Ok(rows) = rows else { continue };
        for (id, model, totals, updated) in rows.flatten() {
            if sessions.get(&id).is_none_or(|(u, _, _)| updated > *u) {
                sessions.insert(id, (updated, model_name(&model), totals));
            }
        }
    }
    let (mut day, mut week, mut month) = (Totals::default(), Totals::default(), Totals::default());
    let mut models: HashMap<String, Totals> = HashMap::new();
    for (updated, model, totals) in sessions.values() {
        month.add(totals);
        models.entry(model.clone()).or_default().add(totals);
        if *updated >= week_start {
            week.add(totals);
        }
        if *updated >= today {
            day.add(totals);
        }
    }
    let mut ranked: Vec<_> = models
        .into_iter()
        .filter(|(_, t)| t.tokens() > 0 || t.cost > 0.0)
        .collect();
    ranked.sort_by_key(|(_, t)| std::cmp::Reverse(t.tokens()));
    let models: Vec<Value> = ranked
        .into_iter()
        .take(3)
        .map(|(name, t)| json!({ "name": name, "tokens": t.tokens(), "cost": (t.cost * 100.0).round() / 100.0 }))
        .collect();
    Some(
        json!({ "today": day.json(), "week": week.json(), "month": month.json(), "models": models }),
    )
}
