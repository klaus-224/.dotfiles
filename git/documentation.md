## Branch naming conventions

Use lowercase, a type prefix, and a kebab-case description:

```text
<type>/<short-description>
```

| Type | Use |
|---|---|
| `feat` | New user-facing capability |
| `fix` | Bug fix |
| `refactor` | Internal restructuring without behaviour change |
| `docs` | Documentation only |
| `test` | Tests only |
| `chore` | Tooling, dependencies, maintenance |
| `ci` | CI/CD changes |
| `nix` | Nix, Home Manager, or nix-darwin changes |

Examples:

```text
feat/native-git-workflow
fix/ssh-agent-startup
refactor/remove-conform
docs/neovim-git-workflow
test/git-hook-validation
ci/check-commit-format
nix/add-lua-language-server
```
## Commit conventions

Use Conventional Commits:

```text
type(scope): imperative summary
```

Examples:

```text
feat(git): add Neovim directory difftool
fix(shell): preserve SSH agent across terminal sessions
refactor(nvim): remove Conform formatter layer
docs(git): document patch-staging workflow
test(hooks): cover invalid branch names
ci(dotfiles): validate commit subjects
nix(home): install Lua language server
chore: update flake inputs
```

For a breaking change:

```text
feat(nvim)!: remove Lazygit tmux binding
```

The `commit-msg` hook should require:

- one of `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `ci`, or `nix`
- an optional lowercase scope
- an optional `!` for a breaking change
- an imperative lowercase summary with no trailing period
- a subject under 72 characters

