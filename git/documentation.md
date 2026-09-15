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
| `style` | Formatting-only changes |

Examples:

```text
feat/native-git-workflow
fix/ssh-agent-startup
refactor/remove-conform
docs/neovim-git-workflow
test/git-hook-validation
chore/check-commit-format
chore/add-lua-language-server
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
chore(ci): validate commit subjects
chore(nix): install Lua language server
chore: update flake inputs
```

For a breaking change:

```text
feat(nvim)!: remove Lazygit tmux binding
```

The `commit-msg` hook requires:

- one of `feat`, `fix`, `docs`, `style`, `refactor`, `test`, or `chore`
- an optional scope using lowercase letters, digits, `.`, `_`, or `-`
- an optional `!` for a breaking change
- `: ` followed by a non-whitespace summary

Prefer an imperative summary without a trailing period and under 72 characters;
these are writing guidelines, not hook-enforced checks. Use `chore(ci)` or
`chore(nix)` rather than unsupported `ci:` or `nix:` types. Automatic merge/revert
subjects also need to be rewritten to match the policy; they are not exempt.

## Pre-push policy and hook scope

`pre-push` reads every ref update from Git's stdin and validates the **destination**
`refs/heads/*` name. Allowed names are `main`, `develop`, or a type above followed
by `/` and a nonempty lowercase name containing letters, digits, `.`, `_`, or `-`.
Git itself additionally validates ref syntax. The checked-out branch is irrelevant:
renamed refspecs, multiple-ref pushes and detached-HEAD pushes use the same policy.
Tags, other namespaces, and deletions (all-zero local object IDs) are exempt from
this naming check. This is not a deletion, force-push, or server authorization guard.

**Existing global scope is retained.** `core.hooksPath` continues pointing at
`~/.dotfiles/git/hooks`; no opt-in switch was introduced that would silently turn
existing protections off. This can affect unrelated repositories and replaces
their normal `.git/hooks` discovery; Git does not automatically chain both sets.
Repository-local overrides of `core.hooksPath` still take precedence.

A future opt-in migration must be explicit: inventory protected repositories and
existing hook managers, arrange approved repository-local hook paths or reviewed
chaining first, verify both policies run, and only then remove the global setting
in a separate reviewed change. Do not use an empty hooks directory as a migration
shortcut. This audit does not modify installed Git configuration.

Regression checks run hooks directly with synthetic stdin/message files and
mocked external commands. They never initialize repositories, create commits,
stage files, push, or write Git configuration:

```sh
node --test tests/git-terminal.test.mjs
```

## nvim diff
- `git difftool` for a file-level diff;
- `git difftool -d main...HEAD` for a branch review;
- `git mergetool` for conflicts;
- `]c` / `[c` to move between hunks and `do` / `dp` to obtain or put a hunk.

`merge.tool = nvim` matches `[mergetool "nvim"]`. Escaped quotes survive Git's
config parser and protect paths containing spaces. `trustExitCode = false` keeps
Git's resolution confirmation: merely exiting Neovim does not prove a conflict
was resolved.
