# Dotfiles conventions

- Keep application source directories at the repository root.
- Use Home Manager in `nix/home/files.nix` for links into the selected user's home.
- Edit source files, not generated links or machine-local runtime state.
- Preserve unrelated changes.
- Use pnpm for JavaScript packages.
- Keep OpenCode dependencies pinned in `opencode/package.json`; regenerate editor
  schemas only when the pinned version changes.
- Run relevant OpenCode checks from `opencode/`: `pnpm test`, `pnpm test:schema`,
  `pnpm test:workflows`, and `pnpm typecheck`.
- When changing Nix expressions, evaluate both Darwin hosts if Nix is available.
- Do not activate a host configuration solely to validate a change.
- Follow `git/documentation.md` for branch, commit, and hook conventions.
- Stage named files and preserve hooks.
- Commit and publish only within the user's requested scope.
- Do not rewrite history or perform destructive Git operations without explicit
  authorization.
- Keep credentials, runtime `service.json`, browser sessions, and test evidence
  containing private data out of Git.
