//! Small shared helpers: subprocesses with timeouts, paths, text cleanup, time.

use std::io::{Read, Write};
use std::path::PathBuf;
use std::process::{Command, Stdio};
use std::time::{Duration, Instant, SystemTime, UNIX_EPOCH};

pub type Out = Result<serde_json::Value, String>;

pub fn home() -> PathBuf {
    std::env::var_os("HOME")
        .map(PathBuf::from)
        .unwrap_or_else(|| PathBuf::from("/"))
}

/// `$XDG_*` directory with its documented default under `$HOME`.
pub fn xdg(var: &str, default: &str) -> PathBuf {
    match std::env::var_os(var) {
        Some(v) if !v.is_empty() => PathBuf::from(v),
        _ => home().join(default),
    }
}

pub fn cache_dir() -> PathBuf {
    let dir = home().join(".cache/sketchybar");
    let _ = std::fs::create_dir_all(&dir);
    dir
}

pub fn now() -> f64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs_f64())
        .unwrap_or(0.0)
}

/// Runs a program with a C locale and returns stdout when it exits 0.
pub fn run(program: &str, args: &[&str]) -> Option<String> {
    run_input(program, args, None, Duration::from_secs(8))
        .filter(|(code, _)| *code == 0)
        .map(|(_, out)| out)
}

/// Runs a program, optionally feeding stdin, killing it after `timeout`.
/// Returns (exit code, stdout). Used for curl so secrets go through stdin,
/// never through argv where `ps` could show them.
pub fn run_input(
    program: &str,
    args: &[&str],
    input: Option<&str>,
    timeout: Duration,
) -> Option<(i32, String)> {
    let mut child = Command::new(program)
        .args(args)
        .env("LC_ALL", "C")
        .env("LANG", "C")
        .stdin(if input.is_some() {
            Stdio::piped()
        } else {
            Stdio::null()
        })
        .stdout(Stdio::piped())
        .stderr(Stdio::null())
        .spawn()
        .ok()?;
    if let Some(text) = input {
        let mut stdin = child.stdin.take()?;
        let _ = stdin.write_all(text.as_bytes());
    }
    let mut stdout = child.stdout.take()?;
    let reader = std::thread::spawn(move || {
        let mut buf = Vec::new();
        let _ = stdout.read_to_end(&mut buf);
        buf
    });
    let deadline = Instant::now() + timeout;
    let status = loop {
        match child.try_wait() {
            Ok(Some(status)) => break status,
            Ok(None) if Instant::now() < deadline => std::thread::sleep(Duration::from_millis(15)),
            _ => {
                let _ = child.kill();
                let _ = child.wait();
                return None;
            }
        }
    };
    let out = reader.join().ok()?;
    Some((
        status.code().unwrap_or(-1),
        String::from_utf8_lossy(&out).into_owned(),
    ))
}

pub fn osascript(script: &str, args: &[&str]) -> Option<String> {
    let mut all = vec!["-e", script];
    all.extend_from_slice(args);
    run("/usr/bin/osascript", &all).map(|s| s.trim_end_matches('\n').to_string())
}

/// Collapses whitespace, drops control characters and limits the length.
pub fn clean(value: &str, limit: usize) -> String {
    let text: String = value
        .chars()
        .map(|c| if c.is_control() { ' ' } else { c })
        .collect();
    let joined = text.split_whitespace().collect::<Vec<_>>().join(" ");
    joined.chars().take(limit).collect()
}

pub fn sketchybar(args: &[&str]) {
    for path in ["/opt/homebrew/bin/sketchybar", "/usr/local/bin/sketchybar"] {
        if std::path::Path::new(path).exists() {
            let _ = Command::new(path)
                .args(args)
                .stdout(Stdio::null())
                .stderr(Stdio::null())
                .status();
            return;
        }
    }
}

pub fn sketchybar_running() -> bool {
    run("/usr/bin/pgrep", &["-x", "sketchybar"]).is_some()
}

/// Local midnight today as a Unix timestamp.
pub fn local_midnight() -> i64 {
    unsafe {
        let t = libc::time(std::ptr::null_mut());
        let mut tm: libc::tm = std::mem::zeroed();
        libc::localtime_r(&t, &mut tm);
        tm.tm_hour = 0;
        tm.tm_min = 0;
        tm.tm_sec = 0;
        tm.tm_isdst = -1;
        libc::mktime(&mut tm) as i64
    }
}

/// Local (year, month 1-12, day) for a Unix timestamp.
pub fn local_date(t: i64) -> (i32, u32, u32) {
    unsafe {
        let t = t as libc::time_t;
        let mut tm: libc::tm = std::mem::zeroed();
        libc::localtime_r(&t, &mut tm);
        (tm.tm_year + 1900, (tm.tm_mon + 1) as u32, tm.tm_mday as u32)
    }
}

/// Local midnight of the given date; month overflow is normalised by mktime.
pub fn local_time(year: i32, month0: i32, day: i32) -> i64 {
    unsafe {
        let mut tm: libc::tm = std::mem::zeroed();
        tm.tm_year = year - 1900;
        tm.tm_mon = month0;
        tm.tm_mday = day;
        tm.tm_isdst = -1;
        libc::mktime(&mut tm) as i64
    }
}

fn days_from_civil(y: i64, m: i64, d: i64) -> i64 {
    let y = if m <= 2 { y - 1 } else { y };
    let era = if y >= 0 { y } else { y - 399 } / 400;
    let yoe = y - era * 400;
    let mp = (m + 9) % 12;
    let doy = (153 * mp + 2) / 5 + d - 1;
    let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy;
    era * 146097 + doe - 719468
}

/// Parses RFC 3339 timestamps such as `2026-11-04T17:00:00.123Z` or `+09:00`.
pub fn parse_iso(s: &str) -> Option<f64> {
    let b = s.as_bytes();
    if b.len() < 19 {
        return None;
    }
    let num = |r: std::ops::Range<usize>| s.get(r)?.parse::<i64>().ok();
    let (y, mo, d) = (num(0..4)?, num(5..7)?, num(8..10)?);
    let (h, mi, se) = (num(11..13)?, num(14..16)?, num(17..19)?);
    let mut rest = &s[19..];
    let mut frac = 0.0;
    if let Some(r) = rest.strip_prefix('.') {
        let digits: String = r.chars().take_while(|c| c.is_ascii_digit()).collect();
        frac = format!("0.{digits}").parse().unwrap_or(0.0);
        rest = &r[digits.len()..];
    }
    let offset = match rest {
        "" | "Z" | "z" => 0,
        _ => {
            let sign = if rest.starts_with('-') { -1 } else { 1 };
            let oh: i64 = rest.get(1..3)?.parse().ok()?;
            let om: i64 = rest.get(4..6).and_then(|v| v.parse().ok()).unwrap_or(0);
            sign * (oh * 3600 + om * 60)
        }
    };
    let secs = days_from_civil(y, mo, d) * 86400 + h * 3600 + mi * 60 + se - offset;
    Some(secs as f64 + frac)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn iso_parsing() {
        assert_eq!(parse_iso("1970-01-01T00:00:00Z"), Some(0.0));
        assert_eq!(parse_iso("2026-11-04T17:00:00+01:00"), Some(1793808000.0));
        assert_eq!(parse_iso("2026-11-04T16:00:00.500Z"), Some(1793808000.5));
        assert_eq!(parse_iso("nope"), None);
    }

    #[test]
    fn cleanup() {
        assert_eq!(clean("  a\n\tb  c ", 10), "a b c");
        assert_eq!(clean("abcdef", 3), "abc");
    }
}
