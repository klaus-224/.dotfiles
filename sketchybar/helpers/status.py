#!/usr/bin/env python3
"""Read-only macOS status for SketchyBar; stdout is always a JSON object."""

import json
import os
from pathlib import Path
import plistlib
import re
import sqlite3
import subprocess
import sys
import time
from contextlib import closing


APPS = {
    "slack": {"names": ["Slack"], "bundles": ["com.tinyspeck.slackmacgap"]},
    "teams": {
        "names": ["Microsoft Teams", "Microsoft Teams (work or school)"],
        "bundles": ["com.microsoft.teams2", "com.microsoft.teams"],
    },
}


def run(*args, timeout=8):
    return subprocess.run(args, capture_output=True, text=True, timeout=timeout,
                          env={**os.environ, "LC_ALL": "C", "LANG": "C"})


def clean(value, limit=160):
    if isinstance(value, list):
        value = next((item for item in value if isinstance(item, str)), "")
    if not isinstance(value, str):
        return ""
    return " ".join("".join(c for c in value if c.isprintable() or c.isspace()).split())[:limit]


def normalize_badge(value):
    value = clean(value, 20)
    if value in ("", "0", "missing value"):
        return ""
    if re.fullmatch(r"[0-9]+\+?", value):
        return value
    # A dot means activity; it is not an exact unread-message count.
    return "•"


def dock_badge(names):
    script = '''on run appNames
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
end run'''
    result = run("/usr/bin/osascript", "-e", script, *names)
    if result.returncode or result.stdout.strip() == "__MISSING__":
        return None
    return normalize_badge(result.stdout)


def badge(key):
    app = APPS[key]
    running = False
    label = None
    for name in app["names"]:
        pid = run("/usr/bin/lsappinfo", "info", "-only", "pid", name)
        if not re.search(r'"?pid"?\s*=\s*[1-9][0-9]*', pid.stdout):
            continue
        running = True
        result = run("/usr/bin/lsappinfo", "info", "-only", "StatusLabel", name)
        match = re.search(r'"label"\s*=\s*"([^"\n]*)"', result.stdout)
        if result.returncode == 0 and match:
            label = normalize_badge(match[1])
        break
    if not running:
        # Teams' executable/display name varies between releases; bundle IDs
        # also resolve installations whose app name has been localized.
        for bundle in app["bundles"]:
            found = run("/usr/bin/lsappinfo", "find", "bundleID=" + bundle)
            selector = re.search(r"ASN:0x[0-9a-fA-F]+-0x[0-9a-fA-F]+:", found.stdout)
            if found.returncode or not selector:
                continue
            running = True
            result = run("/usr/bin/lsappinfo", "info", "-only", "StatusLabel", selector[0])
            match = re.search(r'"label"\s*=\s*"([^"\n]*)"', result.stdout)
            if result.returncode == 0 and match:
                label = normalize_badge(match[1])
            break
    if not running:
        return {"running": False, "badge": ""}
    # Recent Teams/Electron versions may only publish their badge to the Dock.
    if not label:
        dock = dock_badge(app["names"])
        if dock is not None:
            label = dock
    if label is None:
        return {"running": True, "error": "Badge unavailable — check Accessibility"}
    return {"running": True, "badge": label}


def notification_paths():
    yield Path.home() / "Library/Group Containers/group.com.apple.usernoted/db2/db"
    result = run("/usr/bin/getconf", "DARWIN_USER_DIR")
    if result.returncode == 0 and result.stdout.strip():
        yield Path(result.stdout.strip()) / "com.apple.notificationcenter/db2/db"


def read_notifications(path, bundles, now=None):
    cutoff = (time.time() if now is None else now) - 978307200 - 24 * 60 * 60
    placeholders = ",".join("?" for _ in bundles)
    # mode=ro preserves the live WAL view; immutable=1 would miss new messages.
    with closing(sqlite3.connect(path.resolve().as_uri() + "?mode=ro", uri=True, timeout=1)) as db:
        records = db.execute(
            "SELECT record.data FROM record JOIN app ON app.app_id = record.app_id "
            f"WHERE app.identifier IN ({placeholders}) AND record.delivered_date >= ? "
            "ORDER BY record.delivered_date DESC LIMIT 20", (*bundles, cutoff)
        ).fetchall()
    messages = []
    for (data,) in records:
        try:
            request = plistlib.loads(data)["req"]
            title = clean(request.get("titl"))
            subtitle = clean(request.get("subt"))
            body = clean(request.get("body"))
        except (ValueError, TypeError, KeyError, AttributeError, OverflowError, plistlib.InvalidFileException):
            continue
        messages.append({
            "title": " · ".join(part for part in (title, subtitle) if part) or "Notification",
            "body": body or "Preview not supplied by the app",
        })
        if len(messages) == 5:
            break
    return messages


def notifications(key):
    for path in notification_paths():
        try:
            path.stat()
        except FileNotFoundError:
            continue
        except PermissionError:
            return {"error": "Previews need Full Disk Access", "messages": []}
        try:
            return {"messages": read_notifications(path, APPS[key]["bundles"])}
        except (sqlite3.Error, OSError):
            return {"error": "Previews unavailable — check access or DB format", "messages": []}
    return {"error": "Notification database not found", "messages": []}


def wifi_interface():
    result = run("/usr/sbin/networksetup", "-listallhardwareports")
    match = re.search(r"Hardware Port: (?:Wi-Fi|AirPort)\nDevice: (\S+)", result.stdout)
    return match[1] if result.returncode == 0 and match else None


def wifi():
    interface = wifi_interface()
    if not interface:
        return {"error": "Wi-Fi interface unavailable"}
    power = run("/usr/sbin/networksetup", "-getairportpower", interface)
    if power.returncode or not re.search(r": (On|Off)\s*$", power.stdout):
        return {"error": "Wi-Fi status unavailable"}
    enabled = power.stdout.strip().endswith(": On")
    network = run("/usr/sbin/networksetup", "-getairportnetwork", interface)
    match = re.search(r"Current Wi-Fi Network: (.+)", network.stdout)
    ssid = clean(match[1]) if match else ""
    # Modern macOS may hide the SSID without Location Services authorization.
    if ssid.lower() in ("<redacted>", "<hidden>"):
        ssid = ""
    link = run("/sbin/ifconfig", interface)
    connected = enabled and (bool(ssid) or "status: active" in link.stdout)
    ip = run("/usr/sbin/ipconfig", "getifaddr", interface)
    return {"enabled": enabled, "connected": connected, "ssid": ssid,
            "ip": clean(ip.stdout) if ip.returncode == 0 and connected else ""}


def bluetooth():
    result = run("/usr/sbin/system_profiler", "SPBluetoothDataType", "-json", timeout=12)
    if result.returncode:
        return {"error": "Bluetooth status unavailable"}
    try:
        controllers = json.loads(result.stdout)["SPBluetoothDataType"]
        controller = controllers[0]
        state = controller["controller_properties"]["controller_state"]
        if state not in ("attrib_on", "attrib_off"):
            return {"error": "Bluetooth status unavailable"}
        devices = []
        for group in controller.get("device_connected", []):
            devices.extend(clean(name) for name in group)
        return {"enabled": state == "attrib_on", "devices": sorted(devices)}
    except (ValueError, KeyError, IndexError, TypeError):
        return {"error": "Bluetooth status unavailable"}


def main():
    try:
        action = sys.argv[1]
        if action == "badge":
            result = badge(sys.argv[2])
        elif action == "notifications":
            result = notifications(sys.argv[2])
        elif action == "wifi":
            result = wifi()
        elif action == "bluetooth":
            result = bluetooth()
        else:
            result = {"error": "Unknown status request"}
    except (OSError, subprocess.TimeoutExpired, ValueError, KeyError, IndexError):
        result = {"error": "Status unavailable"}
    print(json.dumps(result, ensure_ascii=False))


if __name__ == "__main__":
    main()
