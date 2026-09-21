# GitHub stars review — klaus-224

Reviewed 2026-09-19: **164 publicly visible starred repositories**, assigned to **15 lists**. Each has one primary home. The review used repository descriptions and topics, with README checks for sparse or ambiguous entries. Private stars and existing private lists were not accessible during this review; the script checks live authenticated state when you run it.

## Run

Requires Python 3.9+ and GitHub CLI (`gh`) authenticated as `klaus-224`. No Python packages or AI API keys are needed.

```bash
# Preview live additions
python3 organize-stars.py

# Create lists and add repositories
python3 organize-stars.py --apply

# Read the reviewed catalog without GitHub access
python3 organize-stars.py --catalog
```

New lists are **private**. Existing lists with matching names are reused, preserving their visibility. You can change visibility on GitHub afterward.

## List design

Purpose is the organizing principle. A SQL client belongs with databases regardless of whether it is written in Python or Rust. AI has three groups because agent workflows, memory/indexing, and model/application tooling are distinct things you would look for. Domain references stay with their domain. Neovim, tmux, shell, Nix configuration and mise share a development-workspace list; the small Nix collection does not need a separate list yet.

| List | Repositories | What belongs here |
|---|---:|---|
| AI coding & OpenCode | 17 | Coding agents, OpenCode plugins, skills and orchestration. |
| AI memory & code intelligence | 12 | Agent memory, context management, code indexing and vector search. |
| LLMs & AI applications | 10 | Model inference, gateways, structured outputs and AI applications. |
| Editors, shell & dotfiles | 18 | Neovim, tmux, shell tools, dotfiles and development environments. |
| macOS tools | 8 | Mac applications, window management, automation and Apple platform utilities. |
| Git & code review | 8 | Repository browsing, multi-repo workflows, diffs and code review. |
| Tasks & productivity | 5 | Task tracking, calendars, Jira and personal productivity. |
| Databases & data engineering | 9 | SQL, database clients, testing, transformations and web data extraction. |
| Cloud, containers & DevOps | 13 | AWS, containers, virtualization, deployment, CI and self-hosting. |
| Security, privacy & OSINT | 12 | Sandboxing, identity, network security, privacy and investigation tools. |
| Web & desktop development | 10 | Frontend components, app frameworks, APIs and desktop app architecture. |
| Programming tools & references | 20 | Rust and Python tools, reusable libraries, testing and programming references. |
| PDFs & office documents | 6 | PDF parsing, document conversion and Office automation. |
| Design, maps & media | 9 | Design tools, diagrams, visualizations, GIS and video editing. |
| Games, hardware & experiments | 7 | Simulations, game engines, robotics, sensing and interesting datasets. |

## How changes work

- Default mode is a live dry run: `+` means add, `=` means already assigned, and `?` means unreviewed.
- The script fetches every page of stars, lists, and list items before any mutations. It stops if reads fail or the authenticated account differs.
- All previous memberships are included in each update. It never unstars repositories or deletes lists. Existing lists are matched case-insensitively; ambiguous names stop the run.
- Before applying, it saves a `stars-before-<timestamp>.json` snapshot in the current directory with file permissions `0600`. This records the prior state; there is no automatic rollback command.
- Rerunning resumes an interrupted run without intentionally creating duplicate lists or repeating completed assignments. Failures stop the run; already completed changes remain.
- GitHub list updates replace a membership set. Avoid editing your lists or running a second organizer while `--apply` is running, because the API has no atomic add-only operation here.
- This is a reviewed catalog, not a heuristic classifier. Future or private stars absent from the catalog are shown as unreviewed and left unchanged. Add their `owner/repo` names under the appropriate `CATALOG` entry. Renamed repositories may need an updated name.
- Edit `CATALOG` to change assignments. Multiple categories are supported, but moving a line only adds the new membership; remove an old membership manually if desired.

The implementation uses the documented [GitHub user-list GraphQL mutations](https://docs.github.com/en/graphql/reference/users#updateuserlistsforitem). Authentication is delegated to `gh`; the script does not read, store, or print tokens.

## Verification

All 164 fetched public stars were checked against the catalog: no missing or extra repositories. Eleven offline tests passed, covering pagination, dry-run behavior, preserved memberships, unreviewed stars, wrong-account protection, failed reads, failed backups, duplicate list names, empty accounts, API errors, partial-run recovery, reruns, CLI flags and missing dependencies. Test scenarios are combined where appropriate.

```bash
python3 test-organize-stars.py
```

All five GraphQL operations also validated against the [Octokit GitHub schema snapshot](https://github.com/octokit/graphql-schema). The snapshot has two duplicate, unrelated enterprise fields; validation bypassed that SDL defect while still checking every operation's fields, arguments and types.

Live authenticated reads and writes were not exercised here because this environment has no authenticated GitHub CLI. No changes were made to your GitHub account.

## Full assignment list

### AI coding & OpenCode

Coding agents, OpenCode plugins, skills and orchestration.

- [affaan-m/ECC](https://github.com/affaan-m/ECC)
- [AnganSamadder/opentmux](https://github.com/AnganSamadder/opentmux) — OpenCode agent pane integration, so its primary home is AI coding.
- [darrenhinde/OpenAgentsControl](https://github.com/darrenhinde/OpenAgentsControl)
- [different-ai/openwork](https://github.com/different-ai/openwork)
- [esengine/DeepSeek-Reasonix](https://github.com/esengine/DeepSeek-Reasonix)
- [evermeer/CodingAgentOrchestration](https://github.com/evermeer/CodingAgentOrchestration)
- [gastownhall/gastown](https://github.com/gastownhall/gastown)
- [herdrdev/herdr](https://github.com/herdrdev/herdr)
- [HKUDS/CLI-Anything](https://github.com/HKUDS/CLI-Anything)
- [maddada/Ghostex](https://github.com/maddada/Ghostex)
- [malhashemi/opencode-sessions](https://github.com/malhashemi/opencode-sessions)
- [Mark1708/opencode-agents-sidebar](https://github.com/Mark1708/opencode-agents-sidebar)
- [obra/superpowers](https://github.com/obra/superpowers)
- [pbakaus/impeccable](https://github.com/pbakaus/impeccable) — Design guidance for coding agents, rather than a standalone graphics editor.
- [Randroids-Dojo/ManageSkills](https://github.com/Randroids-Dojo/ManageSkills) — OpenCode skill management.
- [simonwjackson/opencode-direnv](https://github.com/simonwjackson/opencode-direnv)
- [sun-praise/opencode-review](https://github.com/sun-praise/opencode-review)

### AI memory & code intelligence

Agent memory, context management, code indexing and vector search.

- [abhigyanpatwari/GitNexus](https://github.com/abhigyanpatwari/GitNexus)
- [akitaonrails/ai-memory](https://github.com/akitaonrails/ai-memory)
- [CaviraOSS/LongMemory](https://github.com/CaviraOSS/LongMemory)
- [DeusData/codebase-memory-mcp](https://github.com/DeusData/codebase-memory-mcp)
- [jdagdelen/hyperDB](https://github.com/jdagdelen/hyperDB)
- [mksglu/context-mode](https://github.com/mksglu/context-mode)
- [Opencode-DCP/opencode-dynamic-context-pruning](https://github.com/Opencode-DCP/opencode-dynamic-context-pruning)
- [repowise-dev/repowise](https://github.com/repowise-dev/repowise)
- [RyanCodrai/turbovec](https://github.com/RyanCodrai/turbovec) — Vector indexing for embeddings; grouped with AI memory and retrieval.
- [tickernelz/opencode-mem](https://github.com/tickernelz/opencode-mem)
- [topoteretes/cognee](https://github.com/topoteretes/cognee)
- [volcengine/OpenViking](https://github.com/volcengine/OpenViking)

### LLMs & AI applications

Model inference, gateways, structured outputs and AI applications.

- [alibaba/page-agent](https://github.com/alibaba/page-agent)
- [diegosouzapw/OmniRoute](https://github.com/diegosouzapw/OmniRoute)
- [dottxt-ai/outlines](https://github.com/dottxt-ai/outlines)
- [JustVugg/colibri](https://github.com/JustVugg/colibri)
- [odysseus-dev/odysseus](https://github.com/odysseus-dev/odysseus)
- [ollama/ollama](https://github.com/ollama/ollama)
- [pepperoni21/ollama-rs](https://github.com/pepperoni21/ollama-rs)
- [Shubhamsaboo/awesome-llm-apps](https://github.com/Shubhamsaboo/awesome-llm-apps)
- [TauricResearch/TradingAgents](https://github.com/TauricResearch/TradingAgents)
- [virattt/dexter](https://github.com/virattt/dexter)

### Editors, shell & dotfiles

Neovim, tmux, shell tools, dotfiles and development environments.

- [adamchainz/scripts](https://github.com/adamchainz/scripts)
- [alebcay/awesome-shell](https://github.com/alebcay/awesome-shell)
- [bkerley/zshkit](https://github.com/bkerley/zshkit)
- [craftzdog/dotfiles](https://github.com/craftzdog/dotfiles)
- [dmtrKovalenko/my-nvim-config](https://github.com/dmtrKovalenko/my-nvim-config)
- [jdx/mise](https://github.com/jdx/mise)
- [jondot/awesome-devenv](https://github.com/jondot/awesome-devenv)
- [justinmk/vim-ug](https://github.com/justinmk/vim-ug)
- [makyinmars/ghostty-config](https://github.com/makyinmars/ghostty-config)
- [mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles)
- [phlmn/nix-darwin-config](https://github.com/phlmn/nix-darwin-config)
- [rothgar/awesome-tmux](https://github.com/rothgar/awesome-tmux)
- [rothgar/awesome-tuis](https://github.com/rothgar/awesome-tuis)
- [SylvanFranklin/.config](https://github.com/SylvanFranklin/.config)
- [thegdsks/awesome-modern-cli](https://github.com/thegdsks/awesome-modern-cli)
- [vimichael/my-nvim-config](https://github.com/vimichael/my-nvim-config)
- [yacineMTB/dingllm.nvim](https://github.com/yacineMTB/dingllm.nvim)
- [yazgoo/diss](https://github.com/yazgoo/diss)

### macOS tools

Mac applications, window management, automation and Apple platform utilities.

- [Hammerspoon/hammerspoon](https://github.com/Hammerspoon/hammerspoon)
- [herrbischoff/awesome-macos-command-line](https://github.com/herrbischoff/awesome-macos-command-line)
- [jaywcjlove/awesome-mac](https://github.com/jaywcjlove/awesome-mac)
- [Lakr233/vphone-cli](https://github.com/Lakr233/vphone-cli) — Virtual iPhone tooling for Apple Silicon; grouped with Apple platform utilities.
- [nikitabobko/AeroSpace](https://github.com/nikitabobko/AeroSpace)
- [rgcr/m-cli](https://github.com/rgcr/m-cli)
- [serhii-londar/open-source-mac-os-apps](https://github.com/serhii-londar/open-source-mac-os-apps)
- [tw93/Mole](https://github.com/tw93/Mole)

### Git & code review

Repository browsing, multi-repo workflows, diffs and code review.

- [abhixdd/ghgrab](https://github.com/abhixdd/ghgrab)
- [affromero/gitpane](https://github.com/affromero/gitpane)
- [agavra/tuicr](https://github.com/agavra/tuicr)
- [holmityd/GitHub-Issues-Discord-Threads-Bot](https://github.com/holmityd/GitHub-Issues-Discord-Threads-Bot)
- [kitlangton/ghui](https://github.com/kitlangton/ghui)
- [modem-dev/hunk](https://github.com/modem-dev/hunk)
- [rabeeh-ta/manygit](https://github.com/rabeeh-ta/manygit)
- [rcieri/glab-tui](https://github.com/rcieri/glab-tui)

### Tasks & productivity

Task tracking, calendars, Jira and personal productivity.

- [anufrievroman/calcure](https://github.com/anufrievroman/calcure)
- [th3oth3rjak3/timely](https://github.com/th3oth3rjak3/timely)
- [tsoding/tatr](https://github.com/tsoding/tatr)
- [unnecessary-special-projects/ghist](https://github.com/unnecessary-special-projects/ghist)
- [whyisdifficult/jiratui](https://github.com/whyisdifficult/jiratui)

### Databases & data engineering

SQL, database clients, testing, transformations and web data extraction.

- [D4Vinci/Scrapling](https://github.com/D4Vinci/Scrapling) — Web scraping and data extraction.
- [DataExpert-io/data-engineer-handbook](https://github.com/DataExpert-io/data-engineer-handbook)
- [dbcli/litecli](https://github.com/dbcli/litecli)
- [dbt-labs/dbt](https://github.com/dbt-labs/dbt)
- [Maxteabag/sqlit](https://github.com/Maxteabag/sqlit)
- [okbob/plpgsql_check](https://github.com/okbob/plpgsql_check)
- [ScrapeGraphAI/Scrapegraph-ai](https://github.com/ScrapeGraphAI/Scrapegraph-ai) — Its main job is web data extraction.
- [theory/pgtap](https://github.com/theory/pgtap)
- [tursodatabase/turso](https://github.com/tursodatabase/turso)

### Cloud, containers & DevOps

AWS, containers, virtualization, deployment, CI and self-hosting.

- [actions/starter-workflows](https://github.com/actions/starter-workflows)
- [apple/container](https://github.com/apple/container)
- [awesome-selfhosted/awesome-selfhosted](https://github.com/awesome-selfhosted/awesome-selfhosted)
- [aws-samples/aws-dev-hour-backend](https://github.com/aws-samples/aws-dev-hour-backend)
- [awsdocs/aws-doc-sdk-examples](https://github.com/awsdocs/aws-doc-sdk-examples)
- [bastilimbach/docker-scp-deployment](https://github.com/bastilimbach/docker-scp-deployment)
- [fuziontech/lazyaws](https://github.com/fuziontech/lazyaws)
- [jacobusa/react-terraform-aws](https://github.com/jacobusa/react-terraform-aws)
- [jesseduffield/lazydocker](https://github.com/jesseduffield/lazydocker)
- [jessfraz/dockerfiles](https://github.com/jessfraz/dockerfiles)
- [nektos/act](https://github.com/nektos/act)
- [nitrictech/nitric](https://github.com/nitrictech/nitric)
- [smol-machines/smolvm](https://github.com/smol-machines/smolvm)

### Security, privacy & OSINT

Sandboxing, identity, network security, privacy and investigation tools.

- [bee-san/RustScan](https://github.com/bee-san/RustScan)
- [gripebomb/ThreatDeck](https://github.com/gripebomb/ThreatDeck)
- [holtwick/bx-mac](https://github.com/holtwick/bx-mac) — macOS app sandboxing; security is its primary purpose.
- [kaifcodec/user-scanner](https://github.com/kaifcodec/user-scanner)
- [keycloak/keycloak](https://github.com/keycloak/keycloak)
- [koala73/worldmonitor](https://github.com/koala73/worldmonitor)
- [lissy93/personal-security-checklist](https://github.com/lissy93/personal-security-checklist)
- [NationalSecurityAgency/ghidra](https://github.com/NationalSecurityAgency/ghidra)
- [Netflix/security_monkey](https://github.com/Netflix/security_monkey)
- [pi-hole/pi-hole](https://github.com/pi-hole/pi-hole)
- [sundowndev/phoneinfoga](https://github.com/sundowndev/phoneinfoga)
- [Whonix/whonix-firewall](https://github.com/Whonix/whonix-firewall)

### Web & desktop development

Frontend components, app frameworks, APIs and desktop app architecture.

- [awesomeapp-dev/rust-desktop-app](https://github.com/awesomeapp-dev/rust-desktop-app)
- [brillout/awesome-react-components](https://github.com/brillout/awesome-react-components)
- [DioxusLabs/dioxus](https://github.com/DioxusLabs/dioxus)
- [jeremychone/dnative](https://github.com/jeremychone/dnative)
- [microsoft/fluentui](https://github.com/microsoft/fluentui)
- [module-federation/module-federation-examples](https://github.com/module-federation/module-federation-examples)
- [Shpendrr/react-app-structure](https://github.com/Shpendrr/react-app-structure)
- [tauri-apps/awesome-tauri](https://github.com/tauri-apps/awesome-tauri)
- [thesysdev/openui](https://github.com/thesysdev/openui)
- [trpc/trpc](https://github.com/trpc/trpc)

### Programming tools & references

Rust and Python tools, reusable libraries, testing and programming references.

- [Canop/bacon](https://github.com/Canop/bacon)
- [codecrafters-io/build-your-own-x](https://github.com/codecrafters-io/build-your-own-x)
- [DovAmir/awesome-design-patterns](https://github.com/DovAmir/awesome-design-patterns)
- [facebook/pyrefly](https://github.com/facebook/pyrefly)
- [fdehau/tui-rs](https://github.com/fdehau/tui-rs)
- [fffaraz/awesome-cpp](https://github.com/fffaraz/awesome-cpp)
- [Instagram/MonkeyType](https://github.com/Instagram/MonkeyType)
- [leptonyu/cfg-rs](https://github.com/leptonyu/cfg-rs)
- [n0-computer/iroh](https://github.com/n0-computer/iroh)
- [Nukesor/comfy-table](https://github.com/Nukesor/comfy-table)
- [python/mypy](https://github.com/python/mypy)
- [python/typeshed](https://github.com/python/typeshed)
- [ratatui/ratatui](https://github.com/ratatui/ratatui)
- [rust-cli/rexpect](https://github.com/rust-cli/rexpect)
- [rust-unofficial/awesome-rust](https://github.com/rust-unofficial/awesome-rust)
- [rust10x/rust10x](https://github.com/rust10x/rust10x)
- [trimstray/the-book-of-secret-knowledge](https://github.com/trimstray/the-book-of-secret-knowledge)
- [unkn0wn-root/resterm](https://github.com/unkn0wn-root/resterm) — API development and testing client.
- [VladasZ/rustscript](https://github.com/VladasZ/rustscript)
- [zhiburt/tabled](https://github.com/zhiburt/tabled)

### PDFs & office documents

PDF parsing, document conversion and Office automation.

- [AmineDiro/ferrules](https://github.com/AmineDiro/ferrules)
- [firecrawl/pdf-inspector](https://github.com/firecrawl/pdf-inspector)
- [igumnoff/shiva](https://github.com/igumnoff/shiva)
- [iOfficeAI/OfficeCLI](https://github.com/iOfficeAI/OfficeCLI)
- [Stirling-Tools/Stirling-PDF](https://github.com/Stirling-Tools/Stirling-PDF)
- [yingkitw/pdfrs](https://github.com/yingkitw/pdfrs)

### Design, maps & media

Design tools, diagrams, visualizations, GIS and video editing.

- [blitzarx1/egui_graphs](https://github.com/blitzarx1/egui_graphs)
- [likec4/likec4](https://github.com/likec4/likec4)
- [marceloprates/prettymaps](https://github.com/marceloprates/prettymaps)
- [OpenCut-app/OpenCut](https://github.com/OpenCut-app/OpenCut)
- [opengeos/GeoLibre](https://github.com/opengeos/GeoLibre)
- [palmier-io/palmier-pro](https://github.com/palmier-io/palmier-pro)
- [pascalorg/editor](https://github.com/pascalorg/editor)
- [penpot/penpot](https://github.com/penpot/penpot)
- [plotly/plotly.rs](https://github.com/plotly/plotly.rs)

### Games, hardware & experiments

Simulations, game engines, robotics, sensing and interesting datasets.

- [avianphysics/avian](https://github.com/avianphysics/avian)
- [br-g/openf1](https://github.com/br-g/openf1) — Formula 1 data API, kept with exploratory projects.
- [commaai/openpilot](https://github.com/commaai/openpilot)
- [jasonfen/terminal-space-program](https://github.com/jasonfen/terminal-space-program)
- [jdvillal/SIMD_examples](https://github.com/jdvillal/SIMD_examples)
- [Pumpkin-MC/Pumpkin](https://github.com/Pumpkin-MC/Pumpkin)
- [ruvnet/RuView](https://github.com/ruvnet/RuView)
