# Work `devenv` + Neovim implementation plan

## Goal

Use one out-of-tree `work` profile from `~/.dotfiles/devenv` for company
repositories. It supplies shared work tooling without adding Nix files to
company repositories. Neovim remains environment-agnostic: it starts a server
only when that server's executable is available.

## Target layout

```text
~/.dotfiles/
├── devenv/
│   ├── devenv.nix
│   ├── devenv.yaml
│   └── modules/
│       └── work.nix
└── nvim/
    ├── lua/core/...              # LSP enablement
    ├── lsp/ts_go.lua
    ├── lsp/svelte.lua
    ├── lsp/sqlls.lua
    └── lsp/postgres_lsp.lua
```

Keep Home Manager responsible for workstation tools and editors that must work
outside a development shell: Neovim, Git, tmux, ripgrep, fd, fzf, JSON/YAML
language servers, and similar interactive tooling.

## 1. Create the work profile

Use `packages` directly. This profile is deliberately a broad work toolkit,
not a reproduction of every individual repository's dependency graph.

```nix
# ~/.dotfiles/devenv/devenv.nix
{ ... }:

{
  profiles.work.module = import ./modules/work.nix;
}
```

```nix
# ~/.dotfiles/devenv/modules/work.nix
{ pkgs, ... }:

{
  packages = with pkgs; [
    nodejs
    pnpm

    biome
    svelte-language-server
    sql-language-server
    sleek
    tree-sitter

    gnumake
    pkg-config
    shellcheck
  ];
}
```

Do not add `postgres-language-server` here. Personal Postgres projects should
provide it through their own repo-local `devenv.nix` or personal environment.

Do not add TypeScript solely for `tsc`; the native TypeScript preview uses
`tsgo`, not the normal Nix TypeScript `tsc` binary.

## 2. Install TypeScript Native globally for work

`@typescript/native-preview` is an npm package. Keep Node and pnpm
declarative in `work.nix`, then install this package in the PNPM global prefix
that your shell already exposes through `PNPM_HOME`.

```bash
pnpm add --global @typescript/native-preview
```

Verify the package's executable before changing Neovim:

```bash
command -v tsgo
tsgo --version
```

Add a short bootstrap/check script or `just` recipe in dotfiles later if you
want to make this global npm package reproducible. Do not run `pnpm add -g` in
`enterShell`: activation should never mutate your global package store.

## 3. Make Neovim capability-based

Enable the configs that you want Neovim to *know about*:

```lua
vim.lsp.enable({
  -- existing universal servers...
  "ts_go",
  "svelte",
  "sqlls",
  "postgres_lsp",
})
```

Each optional LSP config must return without starting when its binary is not
on `PATH`. This is what lets one Neovim configuration support both work and
personal environments.

```lua
-- lsp/sqlls.lua
---@type vim.lsp.Config
return {
  cmd = { "sql-language-server", "up", "--method", "stdio" },
  filetypes = { "sql", "mysql" },
  root_dir = function(bufnr, on_dir)
    if vim.fn.executable("sql-language-server") ~= 1 then
      return
    end
    on_dir(vim.fs.root(bufnr, { ".sqllsrc.json", ".git" }) or vim.fn.getcwd())
  end,
}
```

Apply the same executable guard to `postgres_lsp.lua` with
`postgres-language-server`. In a project that provides both servers, select
one deliberately; otherwise both can attach to a `.sql` buffer and duplicate
diagnostics/completion.

Recommended selector rule:

- Start `postgres_lsp` only when `postgres-language-server` exists **and** a
  Postgres-specific project marker exists (choose a marker you actually use).
- Otherwise start `sqlls` when `sql-language-server` exists.

## 4. Update the TypeScript native LSP config

Change the fallback executable in `lsp/ts_go.lua` from `tsc` to `tsgo`.
Prefer a repository-local native preview binary when present, then use the
globally installed work binary.

```lua
local cmd = "tsgo"
local local_cmd = vim.fs.joinpath(root_dir, "node_modules", ".bin", "tsgo")

if vim.fn.executable(local_cmd) == 1 then
  cmd = local_cmd
end

return {
  cmd = { cmd, "--lsp", "--stdio" },
  -- keep the rest of the existing ts_go configuration
}
```

Guard the server with `vim.fn.executable(cmd) == 1` so opening arbitrary
TypeScript files outside work/personal environments does not produce a failed
client start. Keep the server name `ts_go`; its implementation is `tsgo`.

## 5. Enable Svelte

Confirm `lsp/svelte.lua` uses:

```lua
cmd = { "svelteserver", "--stdio" }
```

Add the same executable guard and include `"svelte"` in `vim.lsp.enable()`.
`svelte-language-server` from `work.nix` provides `svelteserver`.

## 6. Repair and verify Tree-sitter

The `tree-sitter` package provides the CLI used by parser tooling; it does not
itself install Neovim parsers. Keep parser installation managed by your
existing Tree-sitter manager/plugin.

1. Ensure your parser list contains at least `typescript`, `tsx`, `javascript`,
   `svelte`, `sql`, `json`, `yaml`, `lua`, `nix`, and `bash`.
2. Ensure the parser installation directory is on Neovim's runtime path if
   your manager uses an external directory.
3. In a fresh work shell, run `:checkhealth vim.treesitter`.
4. Open one file of each relevant type and verify that
   `vim.treesitter.get_parser()` returns a parser object.

On macOS, try the system Apple Clang toolchain first. Add a compiler to
`work.nix` only if parser compilation reports that no C compiler is available.

## 7. Configure automatic activation

Add the zsh hook once:

```zsh
eval "$(devenv hook zsh)"
```

For each work repository, bind and trust the external environment once:

```bash
cd ~/code/company/repository
devenv --from path:$HOME/.dotfiles/devenv --profile work allow
```

After that, a new zsh started by tmux in that directory auto-activates the
bound work shell. Tmux should only choose the session/window working directory;
do not add `devenv shell` calls to tmux configuration.

## 8. Validate the shell contract

From a newly activated work repository:

```bash
for tool in node pnpm biome tsgo svelteserver sql-language-server sleek tree-sitter; do
  command -v "$tool" || exit 1
done

node --version
pnpm --version
biome --version
tsgo --version
svelteserver --version
sql-language-server --version
sleek --version
tree-sitter --version
```

Check that the work-provided commands resolve to Nix store paths, except
`tsgo`, which will resolve through your PNPM global prefix.

## 9. Validate Neovim end-to-end

Launch Neovim from that activated shell and open `test.ts`, `test.svelte`, and
`test.sql`.

| Buffer | Expected result |
| --- | --- |
| `test.ts` / `test.tsx` | `ts_go` attaches and is launched with `tsgo --lsp --stdio`. |
| `test.svelte` | `svelte` attaches via `svelteserver --stdio`. |
| `test.sql` in work | `sqlls` attaches; `postgres_lsp` does not. |
| `test.sql` in personal Postgres project | `postgres_lsp` attaches when the project deliberately provides it. |

Run these in Neovim:

```vim
:LspInfo
:checkhealth vim.lsp
:checkhealth vim.treesitter
:lua print(vim.inspect(vim.treesitter.get_parser()))
:lua print(vim.fn.exepath("tsgo"))
:lua print(vim.fn.exepath("svelteserver"))
:lua print(vim.fn.exepath("sql-language-server"))
```

Do this before removing any overlapping Home Manager packages, so failures
remain attributable to the new work environment rather than a missing
fallback.

## Completion criteria

- `cd` into a bound work repo auto-activates the `work` profile.
- A tmux session opened in that repo gets the same shell automatically.
- Biome, `tsgo`, Svelte, SQL language server, Sleek, and Tree-sitter CLI are
  available in the work shell.
- Neovim attaches the matching TypeScript/Svelte/SQL LSP without hard-coding
  “work” or “personal” into the config.
- Personal projects can still use `postgres_lsp` without putting it in the
  shared work environment.
