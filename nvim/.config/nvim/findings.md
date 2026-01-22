# Neovim config findings (redundancy / bloat / conflicts)

Scope focus: `lua/plugins/completions.lua` and `lua/plugins/mason.lua` (+ a few cross-file conflicts that directly affect them).

## 1) `lua/plugins/completions.lua`

### 1.1 Likely missing dependency: `cmp-buffer`
You configure the `buffer` completion source, but there is no `hrsh7th/cmp-buffer` plugin declared anywhere (search came up empty). With nvim-cmp this typically means the source won’t be available (often shows as “source not found”).

**Snippet:**
```lua
sources = cmp.config.sources({
  { name = "nvim_lsp" },
  { name = "luasnip" },
}, {
  { name = "buffer" },
})
```
**Why it’s not required / what to do:**
- If you don’t care about buffer words in completion, remove `{ name = "buffer" }`.
- If you do want it, add `"hrsh7th/cmp-buffer"`.

### 1.2 Hard dependency on `nvim-autopairs` module, but autopairs is lazy-loaded
Your cmp config requires `nvim-autopairs.completion.cmp` immediately. In lazy.nvim, an unloaded plugin is not on `runtimepath`, so `require(...)` can fail unless `nvim-autopairs` is loaded first.

**Snippet (from completions.lua):**
```lua
local cmp_autopairs = require("nvim-autopairs.completion.cmp")
cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
```
**Snippet (from plugins/auto-pairs.lua):**
```lua
event = "InsertEnter"
```
**Why it’s not required / what to do:**
- If you want cmp↔autopairs integration, make `nvim-autopairs` a dependency of `hrsh7th/nvim-cmp` (or load cmp on `InsertEnter` too).
- If you don’t care about that integration, remove the `cmp_autopairs` require + event hook.

### 1.3 Formatting menu includes `path`, but no `path` source is configured
Your `lspkind` menu lists `path`, but `sources` doesn’t include it.

**Snippet:**
```lua
menu = {
  nvim_lsp = "[LSP]",
  luasnip = "[Snippet]",
  buffer = "[Buffer]",
  path = "[Path]",
}
```
**Why it’s not required:**
- This is harmless but looks like leftover config. Either add a `path` source plugin (`hrsh7th/cmp-path`) + `{ name = "path" }`, or remove the `path` menu entry.

### 1.4 Potential bloat: `lspkind.nvim` (optional)
You use `lspkind` only for pretty symbols/labels.

**Snippet:**
```lua
formatting = {
  format = lspkind.cmp_format({ mode = "symbol_text", maxwidth = 50, ... }),
}
```
**Why it’s not required:**
- If you’re fine with plain completion labels, you can drop `onsails/lspkind.nvim` and the formatting block.

### 1.5 `cmp-nvim-lsp` declared redundantly
You declare `hrsh7th/cmp-nvim-lsp` as its own plugin and also as a dependency of `nvim-lspconfig` in `mason.lua`.

**Why it’s not required:**
- One declaration is enough; keeping both is redundant (lazy.nvim will de-dup, but it’s still noise).

---

## 2) `lua/plugins/mason.lua`

### 2.1 `nvim-lspconfig` appears unused with your current LSP setup
Your actual LSP config uses Neovim’s native API (`vim.lsp.config[...]` + `vim.lsp.enable(...)`) in `lua/lsp/servers/*.lua`. I didn’t find any use of `require("lspconfig")`.

**Snippet (example server config):**
```lua
vim.lsp.config["ts_ls"] = globals.base()
vim.lsp.enable("ts_ls")
```
**Why it’s not required:**
- If you’re fully on native `vim.lsp.config` (Neovim 0.10+), `neovim/nvim-lspconfig` is likely dead weight.
- Caveat: if you rely on lspconfig-provided defaults/commands implicitly, verify after removal.

### 2.2 `mason-lspconfig` isn’t actually wiring anything up
`mason-lspconfig` is most useful when it *drives* `lspconfig` setup (handlers / automatic setup). Here it only runs `ensure_installed`, while enabling/config is done elsewhere.

**Snippet:**
```lua
require("mason-lspconfig").setup({ ensure_installed = { ... } })
```
**Why it’s not required / what to do:**
- If you only want an installer UI, you can keep just `mason.nvim` and install manually.
- If you want “ensure installed” behavior, `mason-lspconfig` is OK, but it’s still somewhat redundant since it’s not coordinating config.

### 2.3 `lazydev.nvim` may overlap with `lua_ls` configuration (but not a direct conflict)
You already configure `lua_ls` basics (globals = {"vim"}). `lazydev.nvim` mainly improves Lua development for Neovim runtime and plugin ecosystems.

**Why it might be optional:**
- If you don’t write Lua plugins/config often, you can remove `lazydev.nvim`.
- If you do, it’s reasonable to keep.

---

## 3) Cross-file conflicts affecting LSP/completion UX

### 3.1 `<leader>lf` mapping is defined twice (real conflict)
You map `<leader>lf` to `vim.lsp.buf.format` globally, but you also map `<leader>lf` in `conform.nvim` to `require("conform").format(...)`. Whichever is defined last wins.

**Snippet (core/keymaps.lua):**
```lua
globals.keymap.set('n', '<leader>lf', vim.lsp.buf.format, ...)
```
**Snippet (plugins/formatting.lua):**
```lua
keys = {
  { "<leader>lf", function()
      require("conform").format({ async = true, lsp_fallback = true })
    end,
  },
}
```
**Why it’s not required:**
- Pick one formatting entry point. If you prefer conform, remove the core keymap; if you prefer pure LSP formatting, remove conform’s keybinding.

### 3.2 `laststatus=0` conflicts with lualine’s global statusline
You disable the statusline globally, but lualine is configured with `globalstatus = true`.

**Snippet (core/options.lua):**
```lua
vim.opt.laststatus = 0
```
**Snippet (plugins/lualine.lua):**
```lua
options = { globalstatus = true }
```
**Why it’s not required:**
- If you want lualine, don’t set `laststatus = 0`.
- If you want no statusline, lualine is effectively bloat.

### 3.3 `textwidth` is set twice (redundant)
In `core/options.lua` you set `textwidth = 80` and then immediately set it to `0`.

**Snippet:**
```lua
vim.opt.textwidth = 80
...
vim.opt.textwidth = 0
```
**Why it’s not required:**
- The first assignment is dead code; only the final value matters.

---

## Quick wins (highest impact, lowest effort)
1) Fix cmp source correctness: either add `hrsh7th/cmp-buffer` or remove the `buffer` source.
2) Fix cmp↔autopairs load order: add `nvim-autopairs` as a dependency of `nvim-cmp` (or load cmp on `InsertEnter`).
3) Resolve `<leader>lf` duplication: choose conform *or* `vim.lsp.buf.format`.
4) Decide statusline policy: remove `laststatus=0` or remove lualine.
