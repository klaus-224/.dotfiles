//! Docker Desktop / Rancher Desktop: running containers from each app's own
//! engine socket (Docker Engine API), or `nerdctl` when Rancher Desktop runs
//! containerd instead of moby. Kubernetes-managed containers are left out.
//! Read-only.

use crate::util::{self, Out};
use serde_json::{Value, json};
use std::io::{Read, Write};
use std::os::unix::net::UnixStream;
use std::path::PathBuf;
use std::time::Duration;

struct Container {
    name: String,
    image: String,
    status: String,
}

fn socket(key: &str) -> Option<PathBuf> {
    let home = util::home();
    match key {
        "docker" => Some(home.join(".docker/run/docker.sock")),
        "rancher" => Some(home.join(".rd/docker.sock")),
        _ => None,
    }
}

/// `GET /containers/json` over the engine's unix socket. HTTP/1.0 keeps the
/// body unchunked and the connection closes after it.
fn engine(path: &PathBuf) -> Option<Vec<Container>> {
    let mut stream = UnixStream::connect(path).ok()?;
    stream.set_read_timeout(Some(Duration::from_secs(2))).ok()?;
    stream
        .set_write_timeout(Some(Duration::from_secs(2)))
        .ok()?;
    stream
        .write_all(b"GET /containers/json HTTP/1.0\r\nHost: docker\r\n\r\n")
        .ok()?;
    let mut raw = Vec::new();
    stream.read_to_end(&mut raw).ok()?;
    parse_response(&String::from_utf8_lossy(&raw))
}

fn parse_response(raw: &str) -> Option<Vec<Container>> {
    let (head, body) = raw.split_once("\r\n\r\n")?;
    if !head.starts_with("HTTP/1.") || head.split_whitespace().nth(1) != Some("200") {
        return None;
    }
    let list: Value = serde_json::from_str(body).ok()?;
    Some(
        list.as_array()?
            .iter()
            // Rancher Desktop's Kubernetes runs its pods on the same engine.
            .filter(|c| c["Labels"].get("io.kubernetes.pod.name").is_none())
            .map(|c| Container {
                name: c["Names"]
                    .as_array()
                    .and_then(|n| n.first())
                    .and_then(Value::as_str)
                    .unwrap_or("")
                    .trim_start_matches('/')
                    .to_string(),
                image: c["Image"].as_str().unwrap_or("").to_string(),
                status: c["Status"].as_str().unwrap_or("").to_string(),
            })
            .collect(),
    )
}

/// Rancher Desktop with the containerd engine: one JSON object per line.
fn nerdctl() -> Option<Vec<Container>> {
    let bin = util::home().join(".rd/bin/nerdctl");
    let out = util::run(bin.to_str()?, &["ps", "--format", "{{json .}}"])?;
    Some(
        out.lines()
            .filter_map(|l| serde_json::from_str::<Value>(l).ok())
            .filter(|c| !c["Names"].as_str().unwrap_or("").starts_with("k8s://"))
            .map(|c| Container {
                name: c["Names"].as_str().unwrap_or("").to_string(),
                image: c["Image"].as_str().unwrap_or("").to_string(),
                status: c["Status"].as_str().unwrap_or("").to_string(),
            })
            .collect(),
    )
}

fn running(key: &str) -> Option<Vec<Container>> {
    let path = socket(key)?;
    if path.exists()
        && let Some(list) = engine(&path)
    {
        return Some(list);
    }
    if key == "rancher" { nerdctl() } else { None }
}

/// Whether at least one container runs (false when the engine is down).
pub fn active(key: &str) -> bool {
    running(key).is_some_and(|list| !list.is_empty())
}

/// Running containers for the menu, sorted by name.
pub fn list(key: &str) -> Out {
    socket(key).ok_or("unknown container app")?;
    let Some(mut list) = running(key) else {
        return Ok(json!({ "engine": false, "containers": [] }));
    };
    list.sort_by(|a, b| a.name.cmp(&b.name));
    let containers: Vec<Value> = list
        .iter()
        .map(|c| {
            json!({
                "name": util::clean(&c.name, 80),
                "image": util::clean(&c.image, 80),
                "status": util::clean(&c.status, 40),
            })
        })
        .collect();
    Ok(json!({ "engine": true, "containers": containers }))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn engine_response() {
        let raw = "HTTP/1.0 200 OK\r\nContent-Type: application/json\r\n\r\n\
                   [{\"Names\":[\"/db\"],\"Image\":\"postgres:16\",\"Status\":\"Up 2 hours\"},\
                   {\"Names\":[\"/k8s_POD_x\"],\"Labels\":{\"io.kubernetes.pod.name\":\"x\"}}]";
        let list = parse_response(raw).unwrap();
        assert_eq!(list.len(), 1);
        assert_eq!(list[0].name, "db");
        assert_eq!(list[0].image, "postgres:16");
        assert_eq!(list[0].status, "Up 2 hours");
        assert!(parse_response("HTTP/1.0 500 Internal Server Error\r\n\r\n{}").is_none());
    }
}
