---
name: ghgrab-fetch
description: Fetch files from GitHub, GitLab, Codeberg, Gitea, or Forgejo without cloning. Use when you need to reference source code from other repositories.  
---

# Fetch remote repos with ghgrab
Do not `git clone` unless the task needs a working tree or git history.

1. Inspect: `ghgrab agent tree <repo-url> --token auto`

2. Parse the JSON envelope (`ok`, `data`, or `error`)

3. Download only what you need: reference to ghgrab docs -> [GhGrab - v2.1.0](https://ghgrab.readthedocs.io/en/latest/)
    `ghgrab agent download <repo-url> <path> [<path> ...] --out . --cwd --no-folder --token auto`
    or
    `ghgrab agent download <repo-url> --subtree <dir> --out . --cwd --no-folder --token auto`

4. If `ghgrab` is missing or the command fails, say so. Do not silently clone.
