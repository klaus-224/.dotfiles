//! Slack / Teams: installed and running state, Dock badge count, and recent
//! Notification Center previews (read-only; nothing is cached).

use crate::util::{self, Out};
use serde_json::{Value, json};
use std::path::{Path, PathBuf};

struct App {
    names: &'static [&'static str],
    bundles: &'static [&'static str],
    paths: &'static [&'static str],
}

fn app(key: &str) -> Option<App> {
    match key {
        "slack" => Some(App {
            names: &["Slack"],
            bundles: &["com.tinyspeck.slackmacgap"],
            paths: &["Slack.app"],
        }),
        "teams" => Some(App {
            names: &["Microsoft Teams", "Microsoft Teams (work or school)"],
            bundles: &["com.microsoft.teams2", "com.microsoft.teams"],
            paths: &[
                "Microsoft Teams.app",
                "Microsoft Teams (work or school).app",
                "Microsoft Teams classic.app",
            ],
        }),
        _ => None,
    }
}

fn installed(app: &App) -> bool {
    let home = util::home();
    let dirs = [PathBuf::from("/Applications"), home.join("Applications")];
    if app
        .paths
        .iter()
        .any(|p| dirs.iter().any(|d| d.join(p).exists()))
    {
        return true;
    }
    app.bundles.iter().any(|b| {
        util::run(
            "/usr/bin/mdfind",
            &[&format!("kMDItemCFBundleIdentifier == '{b}'")],
        )
        .is_some_and(|o| !o.trim().is_empty())
    })
}

fn normalize(label: &str) -> String {
    let v = util::clean(label, 20);
    if v.is_empty() || v == "0" || v == "missing value" {
        return String::new();
    }
    if v.trim_end_matches('+').chars().all(|c| c.is_ascii_digit()) {
        return v;
    }
    // A dot (or other glyph) means activity without an exact count.
    "•".into()
}

fn label_of(info: &str) -> Option<String> {
    let start = info.find("\"label\"=\"")? + 9;
    let end = info[start..].find('"')?;
    Some(normalize(&info[start..start + end]))
}

/// `ASN:0x0-0x72072-"Slack":` → `ASN:0x0-0x72072:`.
fn asn_of(found: &str) -> Option<String> {
    let start = found.find("ASN:0x")?;
    let rest = &found[start + 4..];
    let id: String = rest
        .chars()
        .take_while(|c| c.is_ascii_hexdigit() || *c == 'x' || *c == '-')
        .collect();
    let id = id.trim_end_matches('-');
    (!id.is_empty()).then(|| format!("ASN:{id}:"))
}

/// Matches `"pid"=123` and `pid = 123 !cgsConnection …`.
fn pid_of(info: &str) -> Option<i64> {
    let at = info.find("pid")?;
    let rest = info[at + 3..].trim_start_matches('"').trim_start();
    let digits: String = rest
        .strip_prefix('=')?
        .trim_start()
        .chars()
        .take_while(|c| c.is_ascii_digit())
        .collect();
    digits.parse().ok()
}

fn dock_badge(names: &[&str]) -> Option<String> {
    let script = r#"on run appNames
tell application "System Events"
  tell process "Dock"
    repeat with dockItem in UI elements of list 1
      if (name of dockItem as text) is in appNames then
        try
          return value of attribute "AXStatusLabel" of dockItem as text
        on error
          return ""
        end try
      end if
    end repeat
  end tell
end tell
return "__MISSING__"
end run"#;
    let out = util::osascript(script, names)?;
    (out.trim() != "__MISSING__").then(|| normalize(&out))
}

pub fn status(key: &str) -> Out {
    let app = app(key).ok_or("unknown app")?;
    if !installed(&app) {
        return Ok(json!({ "installed": false, "running": false, "badge": "" }));
    }
    let mut running = false;
    let mut label = None;
    let mut targets: Vec<String> = app.names.iter().map(|s| s.to_string()).collect();
    for bundle in app.bundles {
        // Bundle IDs resolve localized or renamed installs (Teams changes names).
        if let Some(found) = util::run(
            "/usr/bin/lsappinfo",
            &["find", &format!("bundleID={bundle}")],
        ) && let Some(asn) = asn_of(&found)
        {
            targets.insert(0, asn);
        }
    }
    for target in &targets {
        let Some(info) = util::run("/usr/bin/lsappinfo", &["info", "-only", "pid", target]) else {
            continue;
        };
        if pid_of(&info).is_none_or(|p| p <= 0) {
            continue;
        }
        running = true;
        label = util::run(
            "/usr/bin/lsappinfo",
            &["info", "-only", "StatusLabel", target],
        )
        .and_then(|o| label_of(&o));
        break;
    }
    if !running {
        return Ok(json!({ "installed": true, "running": false, "badge": "" }));
    }
    // Recent Teams/Electron builds may only publish their badge to the Dock.
    if label.as_deref().is_none_or(str::is_empty)
        && let Some(dock) = dock_badge(app.names)
    {
        label = Some(dock);
    }
    Ok(json!({ "installed": true, "running": true, "badge": label.unwrap_or_default() }))
}

fn notification_dbs() -> Vec<PathBuf> {
    let mut paths =
        vec![util::home().join("Library/Group Containers/group.com.apple.usernoted/db2/db")];
    if let Some(dir) = util::run("/usr/bin/getconf", &["DARWIN_USER_DIR"]) {
        paths.push(Path::new(dir.trim()).join("com.apple.notificationcenter/db2/db"));
    }
    paths
}

fn text(dict: &plist::Dictionary, key: &str) -> String {
    match dict.get(key) {
        Some(plist::Value::String(s)) => util::clean(s, 160),
        Some(plist::Value::Array(a)) => a
            .iter()
            .find_map(|v| v.as_string())
            .map(|s| util::clean(s, 160))
            .unwrap_or_default(),
        _ => String::new(),
    }
}

/// Up to five previews from the last 24 hours, newest first. This is the
/// delivered-notification history, not an unread inbox.
pub fn notifications(key: &str) -> Out {
    let app = app(key).ok_or("unknown app")?;
    for path in notification_dbs() {
        match std::fs::metadata(&path) {
            Err(e) if e.kind() == std::io::ErrorKind::NotFound => continue,
            Err(_) => {
                return Ok(json!({ "error": "Previews need Full Disk Access", "messages": [] }));
            }
            Ok(_) => {}
        }
        return read(&path, app.bundles).or_else(|e| Ok(json!({ "error": e, "messages": [] })));
    }
    Ok(json!({ "error": "Notification database not found", "messages": [] }))
}

fn read(path: &Path, bundles: &[&str]) -> Out {
    // Mac absolute time counts from 2001-01-01.
    const EPOCH_2001: f64 = 978_307_200.0;
    let cutoff = util::now() - EPOCH_2001 - 86_400.0;
    let flags =
        rusqlite::OpenFlags::SQLITE_OPEN_READ_ONLY | rusqlite::OpenFlags::SQLITE_OPEN_NO_MUTEX;
    let db = rusqlite::Connection::open_with_flags(path, flags)
        .map_err(|_| "Previews need Full Disk Access")?;
    let marks = vec!["?"; bundles.len()].join(",");
    let sql = format!(
        "SELECT record.data, record.delivered_date FROM record JOIN app ON app.app_id = record.app_id \
         WHERE app.identifier IN ({marks}) AND record.delivered_date >= ? ORDER BY record.delivered_date DESC LIMIT 20"
    );
    let mut stmt = db
        .prepare(&sql)
        .map_err(|_| "Previews unavailable (access or DB format)")?;
    let mut params: Vec<rusqlite::types::Value> =
        bundles.iter().map(|b| b.to_string().into()).collect();
    params.push(cutoff.into());
    let rows = stmt
        .query_map(rusqlite::params_from_iter(params), |r| {
            Ok((r.get::<_, Vec<u8>>(0)?, r.get::<_, f64>(1)?))
        })
        .map_err(|_| "Previews unavailable (access or DB format)")?;
    let mut messages: Vec<Value> = Vec::new();
    for (data, delivered) in rows.flatten() {
        let Ok(value) = plist::Value::from_reader(std::io::Cursor::new(data)) else {
            continue;
        };
        let Some(req) = value
            .as_dictionary()
            .and_then(|d| d.get("req"))
            .and_then(|r| r.as_dictionary())
        else {
            continue;
        };
        let title = [text(req, "titl"), text(req, "subt")]
            .into_iter()
            .filter(|s| !s.is_empty())
            .collect::<Vec<_>>()
            .join(" · ");
        let body = text(req, "body");
        messages.push(json!({
            "title": if title.is_empty() { "Notification".into() } else { title },
            "body": if body.is_empty() { "Preview not supplied by the app".into() } else { body },
            "at": (delivered + EPOCH_2001) as i64,
        }));
        if messages.len() == 5 {
            break;
        }
    }
    Ok(json!({ "messages": messages }))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn badges() {
        assert_eq!(normalize("3"), "3");
        assert_eq!(normalize("99+"), "99+");
        assert_eq!(normalize("0"), "");
        assert_eq!(normalize("•"), "•");
        assert_eq!(
            label_of("\"StatusLabel\"={ \"label\"=\"12\" }"),
            Some("12".into())
        );
        assert_eq!(
            asn_of("ASN:0x0-0x72072-\"Slack\":\n"),
            Some("ASN:0x0-0x72072:".into())
        );
        assert_eq!(pid_of("    pid = 10388 !cgsConnection"), Some(10388));
        assert_eq!(pid_of("\"pid\"=42"), Some(42));
        assert_eq!(pid_of("[ NULL ]"), None);
    }
}
