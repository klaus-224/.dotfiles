//! Spotify now playing and controls (AppleScript), plus cached album art.

use crate::util::{self, Out};
use serde_json::json;
use std::path::PathBuf;

const BUNDLE: &str = "com.spotify.client";

/// AppleScript compiles `tell application "Spotify"` against the app's
/// dictionary, and asks where the app is when it is missing - so check first.
fn installed() -> bool {
    let home = util::home();
    [
        "/Applications/Spotify.app".into(),
        home.join("Applications/Spotify.app"),
    ]
    .iter()
    .any(|p: &PathBuf| p.exists())
        || util::run(
            "/usr/bin/mdfind",
            &[&format!("kMDItemCFBundleIdentifier == '{BUNDLE}'")],
        )
        .is_some_and(|o| !o.trim().is_empty())
}

const STATUS: &str = r#"if application "Spotify" is running then
  tell application "Spotify"
    set s to player state as text
    if s is "stopped" then return "stopped"
    set t to current track
    set u to ""
    try
      set u to artwork url of t
    end try
    return s & tab & (name of t) & tab & (artist of t) & tab & (album of t) & tab & ((duration of t) as integer as text) & tab & ((player position) as integer as text) & tab & u & tab & (id of t) & tab & ((shuffling) as text)
  end tell
end if
return "notrunning""#;

pub fn status() -> Out {
    if !installed() {
        return Ok(json!({ "installed": false, "running": false, "state": "none" }));
    }
    let Some(out) = util::osascript(STATUS, &[]) else {
        return Ok(
            json!({ "installed": true, "running": false, "state": "none", "error": "Allow Automation access to Spotify" }),
        );
    };
    match out.trim() {
        "notrunning" => return Ok(json!({ "installed": true, "running": false, "state": "none" })),
        "stopped" => return Ok(json!({ "installed": true, "running": true, "state": "stopped" })),
        _ => {}
    }
    let f: Vec<&str> = out.split('\t').collect();
    if f.len() < 8 {
        return Ok(json!({ "installed": true, "running": true, "state": "stopped" }));
    }
    let duration_ms: i64 = f[4].parse().unwrap_or(0);
    let position: i64 = f[5].parse().unwrap_or(0);
    Ok(json!({
        "installed": true,
        "running": true,
        "state": f[0],
        "title": util::clean(f[1], 120),
        "artist": util::clean(f[2], 120),
        "album": util::clean(f[3], 120),
        "duration": duration_ms / 1000,
        "position": position,
        "art": artwork(f[6], f[7]),
        "shuffle": f.get(8).is_some_and(|v| *v == "true"),
    }))
}

/// Downloads the cover once per track into the cache, resized to 476 px
/// (238 pt at 2x) so the popup can always draw it at scale 0.5. A new file
/// name per track: SketchyBar keeps showing an old image if it is rewritten.
fn artwork(url: &str, track_id: &str) -> Option<String> {
    if !url.starts_with("https://") {
        return None;
    }
    let key: String = track_id
        .chars()
        .filter(|c| c.is_ascii_alphanumeric())
        .rev()
        .take(22)
        .collect();
    let dir = util::cache_dir();
    let path = dir.join(format!("art-{key}.jpg"));
    if path.exists() {
        return Some(path.display().to_string());
    }
    let tmp = dir.join(format!("art-{key}.tmp"));
    let tmp_s = tmp.display().to_string();
    util::run(
        "/usr/bin/curl",
        &["-sfL", "--max-time", "6", "-o", &tmp_s, url],
    )?;
    util::run("/usr/bin/sips", &["-z", "476", "476", &tmp_s]);
    std::fs::rename(&tmp, &path).ok()?;
    if let Ok(entries) = std::fs::read_dir(&dir) {
        for e in entries.flatten() {
            let n = e.file_name().to_string_lossy().into_owned();
            if n.starts_with("art-") && e.path() != path {
                let _ = std::fs::remove_file(e.path());
            }
        }
    }
    Some(path.display().to_string())
}

pub fn control(command: &str) -> Out {
    if !installed() {
        return Err("Spotify is not installed".into());
    }
    let verb = match command {
        "playpause" | "toggle" => "playpause",
        "next" => "next track",
        "previous" | "prev" => "previous track",
        "play" => "play",
        "pause" => "pause",
        "open" => {
            util::run("/usr/bin/open", &["-b", BUNDLE]);
            return Ok(json!({ "ok": true }));
        }
        _ => return Err("unknown Spotify command".into()),
    };
    let script = format!("tell application \"Spotify\" to {verb}");
    util::osascript(&script, &[]).ok_or("Spotify did not respond")?;
    Ok(json!({ "ok": true }))
}
