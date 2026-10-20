import importlib.util
import json
import os
from pathlib import Path
import plistlib
import sqlite3
import subprocess
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("status", Path(__file__).parents[1] / "helpers/status.py")
status = importlib.util.module_from_spec(spec)
spec.loader.exec_module(status)


def result(stdout="", code=0):
    return subprocess.CompletedProcess([], code, stdout, "")


class BadgeTests(unittest.TestCase):
    def test_numeric_badge_and_zero(self):
        for value, expected in [("7", "7"), ("99+", "99+"), ("0", ""), ("•", "•")]:
            with self.subTest(value=value), patch.object(status, "run", side_effect=[
                result('"pid"=123'), result('"StatusLabel"={ "label"="' + value + '"; }'),
            ]), patch.object(status, "dock_badge", return_value=""):
                self.assertEqual(status.badge("slack"), {"running": True, "badge": expected})

    def test_new_teams_name_and_dock_fallback(self):
        with patch.object(status, "run", side_effect=[
            result(), result("pid=987"), result(), result("3\n"),
        ]) as command:
            self.assertEqual(status.badge("teams"), {"running": True, "badge": "3"})
            self.assertEqual(command.call_args_list[1].args[-1], "Microsoft Teams (work or school)")

    def test_stopped_and_denied_are_distinct(self):
        with patch.object(status, "run", return_value=result()):
            self.assertEqual(status.badge("slack"), {"running": False, "badge": ""})
        with patch.object(status, "run", side_effect=[result("pid=123"), result(), result(code=1)]):
            self.assertIn("error", status.badge("slack"))

    def test_teams_bundle_id_fallback(self):
        with patch.object(status, "run", side_effect=[
            result(), result(), result("ASN:0x0-0x1234:\n"), result('"label"="9"'),
        ]) as command:
            self.assertEqual(status.badge("teams"), {"running": True, "badge": "9"})
            self.assertEqual(command.call_args_list[2].args[-1], "bundleID=com.microsoft.teams2")

    def test_dock_cleared_badge(self):
        with patch.object(status, "run", side_effect=[result("pid=123"), result(), result("missing value")]):
            self.assertEqual(status.badge("slack")["badge"], "")


class NotificationTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.path = Path(self.directory.name) / "notifications db"
        self.db = sqlite3.connect(self.path)
        self.addCleanup(self.db.close)
        self.db.executescript('''
            PRAGMA journal_mode=WAL;
            CREATE TABLE app (app_id INTEGER, identifier TEXT);
            CREATE TABLE record (app_id INTEGER, data BLOB, delivered_date REAL);
            INSERT INTO app VALUES (1, 'com.tinyspeck.slackmacgap');
            INSERT INTO app VALUES (2, 'com.microsoft.teams2');
            INSERT INTO app VALUES (3, 'unrelated.app');
        ''')
        self.now = 1800000000
        self.apple_now = self.now - 978307200

    def insert(self, app=1, age=0, body="Hello", raw=None):
        blob = raw if raw is not None else plistlib.dumps(
            {"req": {"titl": "Sender", "subt": "Channel", "body": body}}, fmt=plistlib.FMT_BINARY)
        self.db.execute("INSERT INTO record VALUES (?, ?, ?)", (app, blob, self.apple_now - age))
        self.db.commit()

    def read(self, key="slack"):
        return status.read_notifications(self.path, status.APPS[key]["bundles"], self.now)

    def test_filter_sort_limit_and_live_wal(self):
        for age in range(7):
            self.insert(age=age, body=str(age))
        self.insert(app=3, body="Unrelated")
        self.insert(age=90000, body="Old")
        before = self.db.total_changes
        self.assertEqual([row["body"] for row in self.read()], ["0", "1", "2", "3", "4"])
        self.assertEqual(self.db.total_changes, before)
        self.assertEqual(self.db.execute("SELECT count(*) FROM record").fetchone()[0], 9)

    def test_teams_unicode_and_no_shell_interpretation(self):
        self.insert(app=2, body='Hello\n世界 $(touch /tmp/nope) "quoted"')
        self.assertEqual(self.read(), [])
        self.assertEqual(self.read("teams")[0], {
            "title": "Sender · Channel", "body": 'Hello 世界 $(touch /tmp/nope) "quoted"'})

    def test_bad_plists_and_missing_body(self):
        self.insert(raw=b"bad plist")
        self.insert(body="")
        self.assertEqual(len(self.read()), 1)
        self.assertEqual(self.read()[0]["body"], "Preview not supplied by the app")

    def test_database_errors_clear_messages(self):
        with patch.object(status, "notification_paths", return_value=[self.path]), patch.object(
            status, "read_notifications", side_effect=sqlite3.OperationalError("denied")
        ):
            response = status.notifications("slack")
            self.assertEqual(response["messages"], [])
            self.assertIn("error", response)

    def test_missing_database(self):
        with patch.object(status, "notification_paths", return_value=[self.path.with_name("absent")]):
            self.assertEqual(status.notifications("slack")["error"], "Notification database not found")


class ConnectivityTests(unittest.TestCase):
    def wifi_results(self, power="On", network="Current Wi-Fi Network: Office", link="active"):
        return [result("Hardware Port: Ethernet\nDevice: en0\n\nHardware Port: Wi-Fi\nDevice: en7\n"),
                result(f"Wi-Fi Power (en7): {power}"), result(network),
                result(f"status: {link}"), result("192.168.1.20\n")]

    def test_wifi_detects_interface(self):
        with patch.object(status, "run", side_effect=self.wifi_results()) as command:
            response = status.wifi()
            self.assertTrue(response["connected"])
            self.assertEqual(response["ssid"], "Office")
            self.assertEqual(command.call_args_list[1].args[-1], "en7")

    def test_wifi_hidden_ssid_and_radio_off(self):
        for power, expected in [("On", True), ("Off", False)]:
            with patch.object(status, "run", side_effect=self.wifi_results(power, "Current Wi-Fi Network: <redacted>")):
                response = status.wifi()
                self.assertEqual(response["connected"], expected)
                self.assertEqual(response["ssid"], "")
                if not expected:
                    self.assertEqual(response["ip"], "")

    def test_wifi_disconnected_and_unavailable(self):
        with patch.object(status, "run", side_effect=self.wifi_results(network="You are not associated", link="inactive")):
            self.assertFalse(status.wifi()["connected"])
        with patch.object(status, "run", return_value=result(code=1)):
            self.assertIn("error", status.wifi())

    def test_bluetooth_on_off_and_devices(self):
        for state in ("attrib_on", "attrib_off"):
            payload = {"SPBluetoothDataType": [{"controller_properties": {"controller_state": state},
                       "device_connected": [{"Keyboard": {}}, {"Headphones": {}}]}]}
            with patch.object(status, "run", return_value=result(json.dumps(payload))):
                response = status.bluetooth()
                self.assertEqual(response["enabled"], state == "attrib_on")
                self.assertEqual(response["devices"], ["Headphones", "Keyboard"])

    def test_bluetooth_unknown_schema(self):
        with patch.object(status, "run", return_value=result('{}')):
            self.assertIn("error", status.bluetooth())


def field(number, value):
    def varint(value):
        out = bytearray()
        while value > 0x7F:
            out.append(value & 0x7F | 0x80)
            value >>= 7
        return bytes(out + bytes([value]))
    if isinstance(value, int):
        return varint(number << 3) + varint(value)
    return varint(number << 3 | 2) + varint(len(value)) + value


def frecency(*entries):
    return b"".join(field(1, field(1, uri.encode()) + field(2, field(2, 1) + field(4, used)))
                    for uri, used in entries)


class SpotifyTests(unittest.TestCase):
    def test_now_playing_paused_stopped_and_closed(self):
        with patch.object(status, "run", return_value=result("playing\nSong — Live\nBand\n")):
            self.assertEqual(status.spotify(), {"running": True, "state": "playing",
                                                "track": "Song — Live", "artist": "Band"})
        with patch.object(status, "run", return_value=result("stopped\n")):
            self.assertEqual(status.spotify()["track"], "")
        with patch.object(status, "run", return_value=result("__NOT_RUNNING__\n")):
            self.assertEqual(status.spotify(), {"running": False})
        with patch.object(status, "run", return_value=result(code=1)):
            self.assertIn("error", status.spotify())

    def test_frecency_playlists_newest_first(self):
        data = frecency(("spotify:playlist:old", 100), ("spotify:album:skip", 900),
                        ("spotify:playlist:new", 500), ("spotify:playlist:bad\"uri", 999),
                        ("spotify:playlist:old", 300))
        self.assertEqual(status.read_frecency(data), ["spotify:playlist:new", "spotify:playlist:old"])
        with self.assertRaises((ValueError, IndexError)):
            status.read_frecency(field(1, b"\x0a\x7f"))

    def test_playlists_use_newest_profile_and_cache(self):
        with tempfile.TemporaryDirectory() as directory:
            users = Path(directory) / "Users"
            for name, uri, mtime in [("a-user", "spotify:playlist:aaa", 1), ("b-user", "spotify:playlist:bbb", 2)]:
                (users / name).mkdir(parents=True)
                path = users / name / "frecency.pb"
                path.write_bytes(frecency((uri, 1)))
                os.utime(path, (mtime, mtime))
            cache = Path(directory) / "cache/names.json"
            with patch.object(status, "SPOTIFY_USERS", users), patch.object(status, "SPOTIFY_NAMES", cache), \
                    patch.object(status, "playlist_name", side_effect=lambda uri, names: names.setdefault(uri, "Mix")):
                self.assertEqual(status.spotify_playlists(),
                                 {"playlists": [{"uri": "spotify:playlist:bbb", "name": "Mix"}]})
            self.assertEqual(json.loads(cache.read_text()), {"spotify:playlist:bbb": "Mix"})
            with patch.object(status, "SPOTIFY_USERS", Path(directory) / "missing"):
                self.assertIn("error", status.spotify_playlists())

    def test_playlist_name_offline_falls_back(self):
        with patch.object(status.urllib.request, "urlopen", side_effect=OSError):
            self.assertEqual(status.playlist_name("spotify:playlist:abc", {}), "")
        self.assertEqual(status.playlist_name("spotify:playlist:abc", {"spotify:playlist:abc": "Cached"}), "Cached")


if __name__ == "__main__":
    unittest.main()
