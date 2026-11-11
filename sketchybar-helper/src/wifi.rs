//! Wi-Fi: current network, addresses, saved networks in range, joining.
//!
//! macOS hides SSIDs from programs without Location access. The helper runs
//! from an app bundle (see the Justfile) so it can hold that permission; the
//! location itself is never read. Without it the SSID falls back to
//! `ipconfig getsummary` (works after `sudo ipconfig setverbose 1`) or the
//! last name seen by a scan.

use crate::util::{self, Out};
use objc2_core_location::{CLAuthorizationStatus, CLLocationManager};
use objc2_core_wlan::CWWiFiClient;
use objc2_foundation::{NSDate, NSRunLoop};
use serde_json::{Value, json};
use std::collections::HashMap;

fn interface() -> String {
    util::run("/usr/sbin/networksetup", &["-listallhardwareports"])
        .and_then(|out| {
            let mut lines = out.lines();
            while let Some(line) = lines.next() {
                if line.contains("Hardware Port: Wi-Fi") || line.contains("Hardware Port: AirPort")
                {
                    return lines
                        .next()?
                        .strip_prefix("Device: ")
                        .map(|d| d.trim().to_string());
                }
            }
            None
        })
        .unwrap_or_else(|| "en0".into())
}

fn valid(ssid: &str) -> bool {
    !ssid.is_empty() && ssid != "<redacted>" && ssid != "<hidden>"
}

fn cached_ssid_path() -> std::path::PathBuf {
    util::cache_dir().join("ssid")
}

/// (ssid, rssi) from CoreWLAN; the SSID is None without Location access.
fn corewlan() -> (Option<String>, Option<i64>, bool) {
    unsafe {
        let client = CWWiFiClient::sharedWiFiClient();
        let Some(iface) = client.interface() else {
            return (None, None, false);
        };
        let power = iface.powerOn();
        let ssid = iface.ssid().map(|s| s.to_string()).filter(|s| valid(s));
        let rssi = iface.rssiValue() as i64;
        (ssid, (rssi != 0).then_some(rssi), power)
    }
}

fn ipconfig_ssid(iface: &str) -> Option<String> {
    let out = util::run("/usr/sbin/ipconfig", &["getsummary", iface])?;
    out.lines()
        .find_map(|l| {
            l.trim()
                .strip_prefix("SSID : ")
                .map(|s| s.trim().to_string())
        })
        .filter(|s| valid(s))
}

pub fn info() -> Out {
    let iface = interface();
    let (wlan_ssid, rssi, power) = corewlan();
    let ip = util::run("/usr/sbin/ipconfig", &["getifaddr", &iface])
        .map(|s| s.trim().to_string())
        .filter(|s| !s.is_empty());
    let router = util::run("/usr/sbin/ipconfig", &["getoption", &iface, "router"])
        .map(|s| s.trim().to_string())
        .filter(|s| !s.is_empty());
    let mut ssid = wlan_ssid.or_else(|| ipconfig_ssid(&iface));
    if let Some(s) = &ssid {
        let _ = std::fs::write(cached_ssid_path(), s);
    } else if ip.is_some() {
        ssid = std::fs::read_to_string(cached_ssid_path())
            .ok()
            .map(|s| s.trim().to_string())
            .filter(|s| valid(s));
    }
    let connected = power && ip.is_some();
    Ok(json!({
        "interface": iface,
        "power": power,
        "connected": connected,
        "ssid": if connected { ssid } else { None },
        "ip": ip,
        "router": router,
        "rssi": rssi,
    }))
}

fn location_status() -> &'static str {
    unsafe {
        let manager = CLLocationManager::new();
        let mut status = manager.authorizationStatus();
        if status == CLAuthorizationStatus::NotDetermined {
            manager.requestWhenInUseAuthorization();
            // The answer arrives on the run loop; give the prompt a minute.
            for _ in 0..240 {
                NSRunLoop::currentRunLoop()
                    .runUntilDate(&NSDate::dateWithTimeIntervalSinceNow(0.25));
                status = manager.authorizationStatus();
                if status != CLAuthorizationStatus::NotDetermined {
                    break;
                }
            }
        }
        match status {
            CLAuthorizationStatus::AuthorizedAlways
            | CLAuthorizationStatus::AuthorizedWhenInUse => "ok",
            CLAuthorizationStatus::NotDetermined => "undetermined",
            _ => "denied",
        }
    }
}

/// Saved networks that are in range now, strongest first (current on top).
pub fn scan() -> Out {
    let iface = interface();
    let saved: Vec<String> = util::run(
        "/usr/sbin/networksetup",
        &["-listpreferredwirelessnetworks", &iface],
    )
    .map(|o| {
        o.lines()
            .skip(1)
            .map(|l| l.trim().to_string())
            .filter(|l| !l.is_empty())
            .collect()
    })
    .unwrap_or_default();
    let status = location_status();
    if status != "ok" {
        return Ok(json!({ "status": status, "networks": [] }));
    }
    let mut seen: HashMap<String, i64> = HashMap::new();
    let current = unsafe {
        let client = CWWiFiClient::sharedWiFiClient();
        let Some(iface) = client.interface() else {
            return Ok(json!({ "status": "ok", "networks": [] }));
        };
        if let Ok(networks) = iface.scanForNetworksWithSSID_error(None) {
            for n in networks.iter() {
                if let Some(s) = n.ssid() {
                    let rssi = n.rssiValue() as i64;
                    let e = seen.entry(s.to_string()).or_insert(rssi);
                    *e = (*e).max(rssi);
                }
            }
        }
        iface.ssid().map(|s| s.to_string())
    };
    if let Some(c) = &current {
        let _ = std::fs::write(cached_ssid_path(), c);
    }
    let mut list: Vec<(String, i64)> = saved
        .into_iter()
        .filter_map(|s| seen.get(&s).map(|r| (s, *r)))
        .collect();
    list.sort_by_key(|(s, r)| (Some(s) != current.as_ref(), -r));
    let networks: Vec<Value> = list
        .into_iter()
        .take(4)
        .map(|(s, r)| json!({ "ssid": s.clone(), "rssi": r, "current": Some(&s) == current.as_ref() }))
        .collect();
    Ok(json!({ "status": "ok", "networks": networks }))
}

/// Joins a saved network (networksetup uses the Keychain password).
/// networksetup exits 0 even on failure, so any output means failure.
pub fn join(ssid: &str) -> Out {
    let iface = interface();
    match util::run_input(
        "/usr/sbin/networksetup",
        &["-setairportnetwork", &iface, ssid],
        None,
        std::time::Duration::from_secs(20),
    ) {
        Some((0, out)) if out.trim().is_empty() => Ok(json!({ "ok": true })),
        Some((_, out)) => Ok(json!({ "ok": false, "error": util::clean(&out, 80) })),
        None => Ok(json!({ "ok": false, "error": "timed out" })),
    }
}
