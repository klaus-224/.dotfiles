# Dotfiles & Dev Environment Roadmap

> Principle: Stabilize → Optimize → Standardize  
> Rule: One lane per week. No cross-lane drift.

# Current Focus

**Active Lane:** Lane A — Core Infrastructure  
Ignore all other lanes until complete.

---

# Lane A — Core Infrastructure (Foundational)

**Goal:** Make macOS + Linux setups reproducible, clean, and frictionless.  
**Why:** Everything else builds on this.

## Week 1 Focus

### macOS

- [ ] Test macOS setup script end-to-end
- [ ] Verify Brewfile installs correctly
- [ ] Confirm Neovim loads correctly after install
- [ ] Confirm `.zshrc` reload works

### Linux

- [ ] Install Homebrew
- [ ] Add `eza` install
- [ ] Install `lazygit`
- [ ] Add Zen browser install
- [ ] Add command to source Neovim after install
- [ ] Add command to source `.zshrc`

### Shell Architecture

- [ ] Implement OS-detecting brew util:
  - [ ] Detect macOS vs Linux
  - [ ] Combine Brewfiles
  - [ ] Run install cleanly

### Windows Cleanup (One-time)

- [ ] Remove McAfee

---

# Lane B — Dev Workflow Power-Ups

**Goal:** Improve speed + flow inside the terminal.  
**Constraint:** Only after Lane A is stable.

## Week 2 Focus

### Core Workflow

- [ ] ripgrep → select result → open in nvim
- [ ] fzf + environment variable explorer
- [ ] Process finder + killer utility

## Later (Not Week 2)

- [ ] tmux borders like Alacritty
- [ ] TUIs
  - [ ] HTTP requests
  - [ ] Monitor network
  - [ ] Monitor processes
  - [ ] Monitor containers
- [ ] Add workflow improvements from:
  - [ ] https://sidneyliebrand.io/blog/how-fzf-and-ripgrep-improved-my-workflow
  - [ ] https://www.youtube.com/watch?v=CbMbGV9GT8I&t=56s

---

# Lane C — Tooling Standardization & Agents

**Goal:** Cleanly unify Copilot, Codex, agents, and dev containers.  
**Warning:** High-distraction category. Only after A + B feel solid.

## Week 3+ Focus

- [ ] Evaluate OpenCode (https://opencode.ai/docs/)
- [ ] Standardize Copilot + Codex usage
- [ ] Decide umbrella strategy
- [ ] Run agents inside dev containers
- [ ] Define agent execution patterns
- [ ] handle secrets better (password, security)
- [ ] tj devries stuff
