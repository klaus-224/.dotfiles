# Dotfiles conventions

Keep application source directories at the repository root. Home Manager in
`nix/home/files.nix` links them into the selected user's home; do not edit generated
links or machine-local runtime state. Preserve unrelated changes.

Use pnpm for JavaScript packages. OpenCode dependencies and editor schemas are
pinned in `opencode/package.json`; regenerate schemas only when the pinned version
changes. Relevant checks from `opencode/` are `pnpm test`, `pnpm test:schema`,
`pnpm test:workflows`, and `pnpm typecheck`. Run Nix evaluation for both Darwin
hosts when changing Nix expressions and when Nix is available. Do not activate a
host configuration merely to validate a change.

Read `git/documentation.md` for branch, commit, and hook conventions. Stage named
files only, preserve hooks, and never rewrite history or perform destructive Git
operations without explicit authorization. Commit and publish only within the
user's requested scope. Do not include credentials, runtime `service.json`, browser
sessions, or test evidence containing private data in Git.
