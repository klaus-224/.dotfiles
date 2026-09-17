#!/usr/bin/env python3
"""Isolated offline tests. Fixtures are private temporary dirs in this checkout.

No Git initialization/commits, installations, real-home startup, or database reads.
"""

import contextlib
import importlib.util
import io
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import time
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.dont_write_bytecode = True
ZSH = shutil.which("zsh")
spec = importlib.util.spec_from_file_location("doctor", ROOT / "scripts/config-doctor.py")
doctor = importlib.util.module_from_spec(spec)
spec.loader.exec_module(doctor)


class AuditTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix=".audit-test-", dir=ROOT)
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        self.env = {"HOME": str(self.home), "ZDOTDIR": str(self.home),
                    "PATH": "/usr/bin:/bin", "TERM": "dumb", "USER": "audit"}

    def run_command(self, command, **kwargs):
        return subprocess.run(list(map(str, command)), cwd=self.home,
                              env=self.env, text=True, capture_output=True,
                              timeout=20, **kwargs)

    def stub(self, name, body):
        path = self.home / name
        path.write_text("#!/bin/sh\n" + body + "\n")
        path.chmod(0o700)
        return path

    def test_doctor_missing_tools_does_not_execute_or_write(self):
        self.env["PATH"] = ""
        before = list(self.home.iterdir())
        result = self.run_command([sys.executable, "-B", ROOT / "scripts/config-doctor.py", "--repo", ROOT])
        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertIn("FAIL: git: missing", result.stdout)
        self.assertIn("WARN: agent_memory: missing", result.stdout)
        self.assertEqual(list(self.home.iterdir()), before)

    def test_doctor_does_not_invoke_discovered_executables(self):
        for name in (*doctor.REQUIRED, *doctor.OPTIONAL):
            self.stub(name, 'printf called >> "$HOME/invoked"; exit 99')
        self.env["PATH"] = str(self.home)
        result = self.run_command([sys.executable, "-B", ROOT / "scripts/config-doctor.py", "--repo", ROOT])
        self.assertIn("OK: git:", result.stdout)
        self.assertFalse((self.home / "invoked").exists())

    def test_reference_failure_and_deployed_links(self):
        with patch.object(doctor, "references", return_value=[("absent.txt", "fixture")]):
            output = io.StringIO()
            with contextlib.redirect_stdout(output):
                code = doctor.audit(ROOT, refs_only=True, deployed_home=self.home)
            self.assertEqual(code, 1)
            self.assertIn("FAIL: fixture -> absent.txt", output.getvalue())
            self.assertIn("WARN: deployed", output.getvalue())
        self.assertEqual(list(self.home.iterdir()), [])

    def test_managed_links_match_modular_home_configuration(self):
        self.assertEqual(doctor.managed_links(ROOT), {
            ".config/nvim": "nvim",
            ".config/ghostty": "ghostty",
            ".config/gh-dash": "git/gh-dash",
            ".config/opencode": "opencode",
            ".config/mise": "mise",
            ".tmux.conf": "tmux/.tmux.conf",
            ".zshenv": "zsh/.zshenv",
            ".zshrc": "zsh/.zshrc",
            ".zshrc.d": "zsh/.zshrc.d",
            ".gitconfig": "git/.gitconfig",
        })

    def test_modular_checkout_recognition_reports_missing_modules(self):
        checkout = self.home / "fixture"
        (checkout / "nix/home").mkdir(parents=True)
        (checkout / "nix/home/default.nix").write_text("{ ... }: { }\n")
        (checkout / "nix/home/files.nix").write_text("{ ... }: { }\n")
        (checkout / "Justfile").write_text("")
        with patch.object(doctor, "references", return_value=[]):
            output = io.StringIO()
            with contextlib.redirect_stdout(output):
                self.assertEqual(doctor.audit(checkout, refs_only=True), 1)
            self.assertIn("Checkout:", output.getvalue())
            self.assertNotIn("not a dotfiles checkout", output.getvalue())

        (checkout / "nix/home/files.nix").unlink()
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            self.assertEqual(doctor.audit(checkout, refs_only=True), 1)
        self.assertIn("missing nix/home/files.nix", output.getvalue())

    def test_jsonc_reference_scan_ignores_comments_not_strings(self):
        text = r'''{
          // "prompt": "{file:./missing.md}"
          /* "prompt": "{file:./also-missing.md}" */
          "url": "https://example.org", "escaped": "\" // not a comment",
          "prompt": "{file:./active.md}"
        }'''
        self.assertEqual(list(doctor.file_references(text)), ["./active.md"])

    def test_validator_separates_schema_and_does_not_install(self):
        checkout = self.home / "fixture"
        tests = checkout / "opencode/tests"
        tests.mkdir(parents=True)
        (tests / "config.test.ts").write_text("")
        (tests / "schema-validation.test.ts").write_text("")
        self.stub("node", 'printf "<%s>\\n" "$@"')
        self.env["PATH"] = str(self.home)
        command = [sys.executable, "-B", ROOT / "scripts/config-validate.py", "--repo", checkout]
        result = self.run_command([*command, "opencode"])
        self.assertEqual(result.returncode, 1)
        self.assertIn("local tsx dependency missing", result.stderr)
        (checkout / "opencode/node_modules/tsx").mkdir(parents=True)
        result = self.run_command([*command, "opencode"])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("config.test.ts", result.stdout)
        self.assertNotIn("schema-validation.test.ts", result.stdout)
        result = self.run_command([*command, "schema"])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("schema-validation.test.ts", result.stdout)
        self.assertNotIn("config.test.ts", result.stdout)

    def test_ctx_missing_and_argument_passthrough(self):
        self.env["PATH"] = ""
        result = self.run_command(["/bin/sh", ROOT / "bin/ctx", "docs", "/example/lib", "two words"])
        self.assertEqual(result.returncode, 127)
        self.assertIn("npm install -g ctx7", result.stderr)
        self.assertEqual(list(self.home.iterdir()), [])
        self.stub("ctx7", 'printf "<%s>\\n" "$@"; exit 23')
        self.env["PATH"] = str(self.home)
        result = self.run_command(["/bin/sh", ROOT / "bin/ctx", "docs", "/example/lib", "two words"])
        self.assertEqual(result.returncode, 23)
        self.assertEqual(result.stdout, "<docs>\n</example/lib>\n<two words>\n")

    def shell_fixture(self):
        dotfiles = self.home / "checkout"
        modules = dotfiles / "zsh/.zshrc.d"
        modules.mkdir(parents=True)
        # Deliberately never read/copy any real local.zsh, including in the checkout.
        for file in (ROOT / "zsh/.zshrc.d").glob("*.zsh"):
            if file.name != "local.zsh":
                shutil.copyfile(file, modules / file.name)
        shutil.copyfile(ROOT / "zsh/.zshrc", dotfiles / "zsh/.zshrc")
        self.env["DOTFILES_HOME"] = str(dotfiles)
        self.stub("brew", 'printf called >> "$HOME/brew-called"; exit 99')
        self.env["PATH"] = str(self.home) + ":/usr/bin:/bin"
        return modules

    @unittest.skipUnless(ZSH, "zsh unavailable")
    def test_isolated_startup_and_keymaps(self):
        modules = self.shell_fixture()
        command = '''
source "$DOTFILES_HOME/zsh/.zshrc"
[[ ${path[(Ie)/go/bin]} == 0 ]] || exit 10
(( $+functions[up-line-or-beginning-search] )) || exit 11
autoload +X up-line-or-beginning-search || exit 12
[[ $(bindkey -M viins '^G') == *undefined-key ]] || exit 13
[[ $(bindkey -M viins 'jk') == *vi-cmd-mode ]] || exit 14
[[ $(bindkey -M viins '^P') == *up-line-or-beginning-search ]] || exit 15
[[ $(bindkey -M viins '^b') != *ghostty_transparency_toggle_widget ]] || exit 16
'''
        started = time.monotonic()
        result = self.run_command([ZSH, "-d", "-f", "-i", "-c", command])
        print(f"Isolated startup + assertions: {time.monotonic() - started:.3f}s (not a real-home benchmark)")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stderr, "")
        self.assertFalse((self.home / "brew-called").exists())
        (modules / "local.zsh").write_text("ghostty_transparency_toggle_widget() { :; }\n")
        result = self.run_command([ZSH, "-d", "-f", "-i", "-c",
                                  'source "$DOTFILES_HOME/zsh/.zshrc"; bindkey -M viins "^b"'])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("ghostty_transparency_toggle_widget", result.stdout)
        self.assertEqual(result.stderr, "")


if __name__ == "__main__":
    unittest.main(verbosity=2)
