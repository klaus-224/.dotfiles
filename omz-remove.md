## Problem
Remove `oh-my-zsh` while preserving your must-haves: syntax highlighting, autosuggestions, and a configured zsh theme.

## Current State Summary
- Runtime shell init is OMZ-driven in `zsh/.zshrc.d/10-oh-my-zsh.zsh`.
- Setup scripts install OMZ and place theme/plugins under `~/.oh-my-zsh/custom`:
  - `setup-macos.sh`
  - `setup-linux.sh`
- README installation sections explicitly state OMZ setup.
- `todo.md` tracks “Remove oh-my-zsh” as outstanding.

## Complete Impact Map (Every Place Needing Updates)
1. `zsh/.zshrc.d/10-oh-my-zsh.zsh` (**primary runtime change; likely rename**)
   - Remove: `export ZSH=...`, `plugins=(...)`, `source "$ZSH/oh-my-zsh.sh"`, `ZSH_THEME=...`.
   - Add native zsh flow:
     - `autoload -Uz compinit && compinit`
     - explicit `source` for theme script
     - explicit `source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"`
     - explicit `source "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"` (loaded last)
   - Keep: `[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh`.
   - Rename target in implementation: `10-shell-init.zsh`.

2. `setup-macos.sh`
   - Remove OMZ installation block.
   - Remove direct plugin clone blocks for `zsh-autosuggestions` and `zsh-syntax-highlighting`.
   - Ensure plugins are installed via brew package list and sourced from `$(brew --prefix)/share/...`.
   - Keep theme strategy explicit (brew-installed `powerlevel10k` path or direct clone path), then source it directly.
   - Remove OMZ-era assumptions that `.zshrc` contains `ZSH_THEME`/`plugins=(...)`.

3. `setup-linux.sh`
   - Same migration as macOS script.
   - Remove OMZ install block and `ZSH_CUSTOM` usage.
   - Remove direct plugin clone blocks for `zsh-autosuggestions` and `zsh-syntax-highlighting`.
   - Ensure linux package install path includes these formulas before sourcing from `$(brew --prefix)/share/...`.
   - Fix package source mismatch (`setup-linux.sh` currently expects `packages/linux.txt`, repo currently has `brewfiles/Brewfile.linux`).
   - Remove script edits that append `ZSH_THEME` or mutate `plugins=(...)`, since those are OMZ-specific.

4. `README.md`
   - macOS “What this does” section: replace “Oh My Zsh” language with native-zsh plugin/theme setup wording.
   - WSL/Linux “What this does” section: same replacement.
   - Any setup command references that imply OMZ-managed plugin loading should be updated.

5. `todo.md` (optional but recommended consistency update)
   - Mark “Remove oh-my-zsh” completed once implementation lands.

6. `brewfiles/Brewfile.common` and `brewfiles/Brewfile.linux`
   - Add/verify `zsh-autosuggestions` and `zsh-syntax-highlighting` formulas in active brew package manifests.
   - If theme is brew-managed, add/verify `powerlevel10k` formula as well.

7. `/Users/rohineshram/.dotfiles/omz-remove.md` (plan copy artifact)
   - Keep synced with session `plan.md` when plan changes are requested.

8. Existing local environment (outside repo)
   - `~/.oh-my-zsh` becomes unused after migration; document optional manual cleanup (do not auto-delete).

## Functionality That Could Break During/After Migration
- **Aliases from OMZ plugins (especially `git`)**  
  Commands like `gst`, `gco`, `gaa`, etc. may disappear unless redefined in `zsh/.zshrc.d/40-aliases.zsh` or replaced via another plugin source.
- **`copyfile` plugin behavior**  
  OMZ-provided functions/aliases for copy-to-clipboard flows may stop working.
- **Theme loading**  
  Prompt can fall back/default if `powerlevel10k.zsh-theme` path is wrong (brew path vs clone path mismatch).
- **Autosuggestions/highlighting order**  
  `zsh-syntax-highlighting` must be sourced after other widgets/plugins; wrong order can disable or degrade behavior.
- **Brew prefix portability**  
  Hardcoding `/opt/homebrew` or `~/.linuxbrew` can break; source paths should use `$(brew --prefix)` at runtime.
- **Completions**  
  If `compinit` is missed or `fpath` is incomplete, completion quality and plugin completions drop.
- **Installer idempotency**  
  Existing setup logic currently assumes OMZ path layout; partial migration can leave stale clone logic or missing brew formulas.

## Implementation Plan
1. **Finalize native loading contract**
   - Source autosuggestions/highlighting from Homebrew share paths via `$(brew --prefix)`.
   - Choose final theme source path (brew-managed vs cloned repo) and keep it explicit.
   - Define source order: completion -> theme -> autosuggestions -> syntax-highlighting -> `~/.p10k.zsh`.
   - Use renamed init filename: `10-shell-init.zsh`.

2. **Migrate shell init file**
   - Rename and rewrite `zsh/.zshrc.d/10-oh-my-zsh.zsh` to OMZ-free native zsh initialization.
   - Add only explicit `source` statements required for your three priorities.

3. **Migrate installers**
   - Update `setup-macos.sh` and `setup-linux.sh` to stop cloning autosuggestions/highlighting repos.
   - Ensure active brew package manifests install required formulas for both macOS and Linux.
   - Remove OMZ bootstrap and OMZ-specific `.zshrc` mutations.

4. **Update docs**
   - Revise README install summaries to reflect non-OMZ setup.
   - Add short migration note for existing users (`~/.oh-my-zsh` cleanup optional).

5. **Validate behavior**
   - Run shell smoke checks for:
     - prompt loaded
     - autosuggestions active
     - syntax highlighting active
     - expected aliases present (or replacement aliases documented)

## Todo Plan
1. **inventory-omz-dependencies**  
   Confirm and lock all OMZ-dependent surfaces (runtime, setup scripts, docs, aliases/functions).
2. **design-native-zsh-loading**  
   Define explicit non-OMZ load order and source paths for theme/plugins.
3. **plan-installer-migration**  
   Specify script changes and idempotent clone checks for direct plugin installs.
4. **plan-doc-updates**  
   Define exact README wording changes for macOS + WSL/Linux sections.
5. **plan-validation-matrix**  
   Define post-migration checks for prompt, autosuggestions, highlighting, completions, and alias continuity.

## Notes / Decisions
- Confirmed priority: preserve syntax highlighting, autosuggestions, and theme setup.
- Updated decision: source `zsh-autosuggestions` and `zsh-syntax-highlighting` from Homebrew share path via `$(brew --prefix)`.
- Theme remains explicit-source based (final source path to be pinned during implementation).
- Confirmed renamed file: `zsh/.zshrc.d/10-shell-init.zsh`.
