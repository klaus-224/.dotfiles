"""Offline integration tests. No GitHub access or credentials required."""
import contextlib
import importlib.util
import io
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

SCRIPT = Path(__file__).with_name("organize-stars.py")
spec = importlib.util.spec_from_file_location("organizer", SCRIPT)
app = importlib.util.module_from_spec(spec)
spec.loader.exec_module(app)


def connection(nodes, cursor=None):
    return {"nodes": nodes, "pageInfo": {"hasNextPage": cursor is not None, "endCursor": cursor}}


class FakeGitHub:
    """Simulate pagination and replacement (not additive) membership writes."""
    def __init__(self):
        self.login = app.ACCOUNT
        self.stars = [
            {"id": "repo1", "nameWithOwner": "Maxteabag/sqlit"},
            {"id": "repo2", "nameWithOwner": "jdx/mise"},
            {"id": "repo3", "nameWithOwner": "someone/new-star"},
        ]
        self.lists = [
            {"id": "keep", "name": "Weekend", "isPrivate": False},
            {"id": "database", "name": "Databases & data engineering", "isPrivate": True},
        ]
        self.memberships = {"repo1": {"keep"}, "repo2": {"keep"}, "repo3": {"keep"}}
        self.writes = []
        self.reads = []

    def page(self, nodes, cursor):
        # Deliberately one item per page: exercise every pagination loop.
        start = int(cursor or 0)
        end = start + 1
        return connection(nodes[start:end], str(end) if end < len(nodes) else None)

    def __call__(self, query, **variables):
        if query == app.STARS_QUERY:
            self.reads.append("stars")
            return {"viewer": {"login": self.login, "starredRepositories":
                               self.page(self.stars, variables["after"])}}
        if query == app.LISTS_QUERY:
            self.reads.append("lists")
            return {"viewer": {"login": self.login, "lists":
                               self.page(self.lists, variables["after"])}}
        if query == app.ITEMS_QUERY:
            self.reads.append("items")
            nodes = [r for r in self.stars if variables["id"] in self.memberships[r["id"]]]
            return {"node": {"items": self.page(nodes, variables["after"])}}
        self.writes.append((query, variables["input"]))
        if query == app.CREATE_MUTATION:
            item = {"id": "new-list", **variables["input"]}
            self.lists.append(item)
            return {"createUserList": {"list": item}}
        if query == app.UPDATE_MUTATION:
            item = variables["input"]
            self.memberships[item["itemId"]] = set(item["listIds"])
            return {"updateUserListsForItem": {"lists": [{"id": i} for i in item["listIds"]]}}
        raise AssertionError("Unexpected query")


class OrganizerTests(unittest.TestCase):
    def run_app(self, github, args):
        with patch.object(app, "graphql", github), patch.object(app.shutil, "which", return_value="gh"), \
                patch.object(app.time, "sleep"), contextlib.redirect_stdout(io.StringIO()):
            return app.main(args)

    def test_dry_run_reads_all_pages_and_never_writes(self):
        github = FakeGitHub()
        self.assertEqual(self.run_app(github, []), 0)
        self.assertEqual(github.writes, [])
        self.assertEqual(github.reads.count("stars"), 3)
        self.assertEqual(github.reads.count("lists"), 2)
        self.assertEqual(github.reads.count("items"), 4)

    def test_apply_preserves_existing_skips_unknown_and_rerun_is_noop(self):
        github = FakeGitHub()
        old_cwd = Path.cwd()
        with tempfile.TemporaryDirectory() as folder:
            try:
                os.chdir(folder)
                self.assertEqual(self.run_app(github, ["--apply"]), 0)
                self.assertEqual(github.memberships["repo1"], {"keep", "database"})
                self.assertEqual(github.memberships["repo2"], {"keep", "new-list"})
                self.assertEqual(github.memberships["repo3"], {"keep"})
                self.assertTrue(github.lists[-1]["isPrivate"])
                self.assertFalse(github.lists[0]["isPrivate"])
                backups = list(Path(folder).glob("stars-before-*.json"))
                self.assertEqual(len(backups), 1)
                backup = json.loads(backups[0].read_text())
                self.assertEqual(len(backup["lists"]), 2)
                self.assertEqual(len(backup["lists"][0]["items"]), 3)
                self.assertEqual(backups[0].stat().st_mode & 0o777, 0o600)
                writes = len(github.writes)
                self.run_app(github, ["--apply"])
                self.assertEqual(len(github.writes), writes)
                self.assertEqual(len(list(Path(folder).glob("stars-before-*.json"))), 1)
            finally:
                os.chdir(old_cwd)

    def test_wrong_account_cannot_write(self):
        github = FakeGitHub()
        github.login = "wrong-account"
        with self.assertRaisesRegex(RuntimeError, "Wrong account"):
            self.run_app(github, ["--apply"])
        self.assertEqual(github.writes, [])

    def test_partial_read_failure_cannot_write(self):
        github = FakeGitHub()
        def fail(query, **variables):
            if query == app.ITEMS_QUERY and variables["after"]:
                raise RuntimeError("read failed")
            return github(query, **variables)
        with self.assertRaisesRegex(RuntimeError, "read failed"):
            self.run_app(fail, ["--apply"])
        self.assertEqual(github.writes, [])

    def test_backup_failure_cannot_write(self):
        github = FakeGitHub()
        with patch.object(app, "save_snapshot", side_effect=OSError("disk full")):
            with self.assertRaisesRegex(OSError, "disk full"):
                self.run_app(github, ["--apply"])
        self.assertEqual(github.writes, [])

    def test_empty_stars_no_writes(self):
        github = FakeGitHub()
        github.stars = []
        self.assertEqual(self.run_app(github, ["--apply"]), 0)
        self.assertEqual(github.writes, [])

    def test_duplicate_lists_fail_closed(self):
        github = FakeGitHub()
        github.lists.append({"id": "ambiguous", "name": "WEEKEND", "isPrivate": True})
        with self.assertRaisesRegex(RuntimeError, "Ambiguous"):
            self.run_app(github, ["--apply"])
        self.assertEqual(github.writes, [])

    def test_graphql_errors_even_with_partial_data(self):
        result = subprocess.CompletedProcess([], 0, json.dumps({
            "data": {"viewer": {}}, "errors": [{"message": "not authorized"}]}), "")
        with patch.object(app.subprocess, "run", return_value=result):
            with self.assertRaisesRegex(RuntimeError, "not authorized"):
                app.graphql(app.STARS_QUERY)

    def test_partial_apply_can_resume(self):
        github = FakeGitHub()
        def fail(query, **variables):
            if query == app.UPDATE_MUTATION and variables["input"]["itemId"] == "repo2":
                raise RuntimeError("temporary failure")
            return github(query, **variables)
        old_cwd = Path.cwd()
        with tempfile.TemporaryDirectory() as folder:
            try:
                os.chdir(folder)
                with self.assertRaisesRegex(RuntimeError, "temporary failure"):
                    self.run_app(fail, ["--apply"])
                self.run_app(github, ["--apply"])
                creates = [w for w in github.writes if w[0] == app.CREATE_MUTATION]
                self.assertEqual(len(creates), 1)
                self.assertEqual(github.memberships["repo1"], {"keep", "database"})
                self.assertEqual(github.memberships["repo2"], {"keep", "new-list"})
            finally:
                os.chdir(old_cwd)

    def test_cli_catalog_and_invalid_flags(self):
        result = subprocess.run([sys.executable, str(SCRIPT), "--catalog"], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0)
        self.assertIn("164 repositories across 15 lists", result.stdout)
        result = subprocess.run([sys.executable, str(SCRIPT), "--apply", "--catalog"],
                                capture_output=True, text=True)
        self.assertEqual(result.returncode, 2)

    def test_missing_dependency(self):
        with patch.object(app.shutil, "which", return_value=None):
            with self.assertRaisesRegex(RuntimeError, "Install GitHub CLI"):
                app.main([])


if __name__ == "__main__":
    unittest.main()
