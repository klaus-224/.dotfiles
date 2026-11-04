//! Slack custom status (get / set / clear) through the Web API.
//!
//! The user token (`xoxp-…`, scopes `users.profile:read` and
//! `users.profile:write`) is read from the login Keychain item
//! `sketchybar-slack`. It goes to curl through stdin, never argv, and is
//! never printed.

use crate::util::{self, Out};
use serde_json::{Value, json};
use std::time::Duration;

const SERVICE: &str = "sketchybar-slack";

fn token() -> Option<String> {
    let t = util::run(
        "/usr/bin/security",
        &["find-generic-password", "-s", SERVICE, "-w"],
    )?;
    let t = t.trim().to_string();
    (!t.is_empty()).then_some(t)
}

fn quote(value: &str) -> String {
    let mut s = String::from("\"");
    for c in value.chars() {
        match c {
            '"' => s.push_str("\\\""),
            '\\' => s.push_str("\\\\"),
            '\n' => s.push_str("\\n"),
            '\r' => s.push_str("\\r"),
            '\t' => s.push_str("\\t"),
            c => s.push(c),
        }
    }
    s.push('"');
    s
}

fn call(method: &str, body: Option<Value>) -> Result<Value, String> {
    let token =
        token().ok_or_else(|| format!("Add a Slack token to the Keychain item '{SERVICE}'"))?;
    let mut config = format!(
        "url = {}\nheader = {}\nsilent\nshow-error\nmax-time = 8\n",
        quote(&format!("https://slack.com/api/{method}")),
        quote(&format!("Authorization: Bearer {token}")),
    );
    if let Some(body) = body {
        config.push_str(&format!(
            "header = {}\n",
            quote("Content-Type: application/json; charset=utf-8")
        ));
        config.push_str(&format!("data = {}\n", quote(&body.to_string())));
    }
    let (code, out) = util::run_input(
        "/usr/bin/curl",
        &["-K", "-"],
        Some(&config),
        Duration::from_secs(10),
    )
    .ok_or("Slack request timed out")?;
    if code != 0 {
        return Err("Slack unreachable".into());
    }
    let v: Value = serde_json::from_str(&out).map_err(|_| "Unexpected Slack response")?;
    if v["ok"].as_bool() != Some(true) {
        return Err(format!(
            "Slack: {}",
            v["error"].as_str().unwrap_or("request failed")
        ));
    }
    Ok(v)
}

pub fn get() -> Out {
    match call("users.profile.get", None) {
        Ok(v) => {
            let p = &v["profile"];
            Ok(json!({
                "text": p["status_text"].as_str().unwrap_or(""),
                "emoji": p["status_emoji"].as_str().unwrap_or(""),
                "expires": p["status_expiration"].as_i64().unwrap_or(0),
            }))
        }
        Err(e) => Ok(json!({ "error": e })),
    }
}

/// `minutes` = 0 keeps the status until it is changed.
pub fn set(emoji: &str, text: &str, minutes: i64) -> Out {
    let expires = if minutes > 0 {
        util::now() as i64 + minutes * 60
    } else {
        0
    };
    let body = json!({ "profile": { "status_text": text, "status_emoji": emoji, "status_expiration": expires } });
    match call("users.profile.set", Some(body)) {
        Ok(_) => get(),
        Err(e) => Ok(json!({ "error": e })),
    }
}

#[cfg(test)]
mod tests {
    #[test]
    fn curl_quoting() {
        assert_eq!(super::quote(r#"a"b\c"#), r#""a\"b\\c""#);
    }
}
