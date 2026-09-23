#!/usr/bin/env python3
"""Organize klaus-224's reviewed stars. Python 3.9+, GitHub CLI; no pip deps.

  python3 organize-stars.py             # Live dry run
  python3 organize-stars.py --apply     # Create lists and add memberships
  python3 organize-stars.py --catalog   # Show the reviewed catalog offline

Edit CATALOG below to change assignments or classify new stars. Every line is
an exact owner/repo name, matched case-insensitively. A repo may appear in more
than one category. Unreviewed stars are reported and left untouched.
"""

import argparse
from collections import defaultdict
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import time

ACCOUNT = "klaus-224"
REVIEW_DATE = "2026-09-19"

# Curated from all 164 public stars, descriptions/topics, and sparse READMEs.
# Categories reflect purpose, not implementation language. All current stars
# have one primary home; add a second only when it helps retrieval.
CATALOG = {
    "AI coding & OpenCode": """
affaan-m/ECC
maddada/Ghostex
evermeer/CodingAgentOrchestration
sun-praise/opencode-review
malhashemi/opencode-sessions
AnganSamadder/opentmux
Mark1708/opencode-agents-sidebar
Randroids-Dojo/ManageSkills
simonwjackson/opencode-direnv
darrenhinde/OpenAgentsControl
HKUDS/CLI-Anything
esengine/DeepSeek-Reasonix
different-ai/openwork
pbakaus/impeccable
herdrdev/herdr
gastownhall/gastown
obra/superpowers
""",
    "AI memory & code intelligence": """
tickernelz/opencode-mem
Opencode-DCP/opencode-dynamic-context-pruning
mksglu/context-mode
abhigyanpatwari/GitNexus
akitaonrails/ai-memory
volcengine/OpenViking
CaviraOSS/LongMemory
topoteretes/cognee
DeusData/codebase-memory-mcp
repowise-dev/repowise
RyanCodrai/turbovec
jdagdelen/hyperDB
""",
    "LLMs & AI applications": """
JustVugg/colibri
Shubhamsaboo/awesome-llm-apps
TauricResearch/TradingAgents
diegosouzapw/OmniRoute
dottxt-ai/outlines
alibaba/page-agent
odysseus-dev/odysseus
virattt/dexter
pepperoni21/ollama-rs
ollama/ollama
""",
    "Editors, shell & dotfiles": """
phlmn/nix-darwin-config
SylvanFranklin/.config
jdx/mise
adamchainz/scripts
bkerley/zshkit
rothgar/awesome-tmux
justinmk/vim-ug
yazgoo/diss
makyinmars/ghostty-config
yacineMTB/dingllm.nvim
jondot/awesome-devenv
alebcay/awesome-shell
thegdsks/awesome-modern-cli
vimichael/my-nvim-config
dmtrKovalenko/my-nvim-config
mathiasbynens/dotfiles
craftzdog/dotfiles
rothgar/awesome-tuis
""",
    "macOS tools": """
Lakr233/vphone-cli
tw93/Mole
serhii-londar/open-source-mac-os-apps
nikitabobko/AeroSpace
jaywcjlove/awesome-mac
Hammerspoon/hammerspoon
rgcr/m-cli
herrbischoff/awesome-macos-command-line
""",
    "Git & code review": """
abhixdd/ghgrab
rcieri/glab-tui
rabeeh-ta/manygit
modem-dev/hunk
affromero/gitpane
holmityd/GitHub-Issues-Discord-Threads-Bot
agavra/tuicr
kitlangton/ghui
""",
    "Tasks & productivity": """
tsoding/tatr
whyisdifficult/jiratui
anufrievroman/calcure
unnecessary-special-projects/ghist
th3oth3rjak3/timely
""",
    "Databases & data engineering": """
okbob/plpgsql_check
Maxteabag/sqlit
theory/pgtap
dbt-labs/dbt
tursodatabase/turso
dbcli/litecli
ScrapeGraphAI/Scrapegraph-ai
DataExpert-io/data-engineer-handbook
D4Vinci/Scrapling
""",
    "Cloud, containers & DevOps": """
nektos/act
actions/starter-workflows
apple/container
jessfraz/dockerfiles
awsdocs/aws-doc-sdk-examples
smol-machines/smolvm
fuziontech/lazyaws
jesseduffield/lazydocker
nitrictech/nitric
awesome-selfhosted/awesome-selfhosted
aws-samples/aws-dev-hour-backend
bastilimbach/docker-scp-deployment
jacobusa/react-terraform-aws
""",
    "Security, privacy & OSINT": """
holtwick/bx-mac
kaifcodec/user-scanner
NationalSecurityAgency/ghidra
Whonix/whonix-firewall
koala73/worldmonitor
keycloak/keycloak
Netflix/security_monkey
pi-hole/pi-hole
sundowndev/phoneinfoga
bee-san/RustScan
gripebomb/ThreatDeck
lissy93/personal-security-checklist
""",
    "Web & desktop development": """
trpc/trpc
jeremychone/dnative
DioxusLabs/dioxus
microsoft/fluentui
thesysdev/openui
brillout/awesome-react-components
Shpendrr/react-app-structure
tauri-apps/awesome-tauri
awesomeapp-dev/rust-desktop-app
module-federation/module-federation-examples
""",
    "Programming tools & references": """
Canop/bacon
VladasZ/rustscript
rust10x/rust10x
leptonyu/cfg-rs
rust-cli/rexpect
zhiburt/tabled
Nukesor/comfy-table
Instagram/MonkeyType
facebook/pyrefly
python/mypy
python/typeshed
n0-computer/iroh
trimstray/the-book-of-secret-knowledge
fffaraz/awesome-cpp
DovAmir/awesome-design-patterns
codecrafters-io/build-your-own-x
rust-unofficial/awesome-rust
ratatui/ratatui
fdehau/tui-rs
unkn0wn-root/resterm
""",
    "PDFs & office documents": """
yingkitw/pdfrs
firecrawl/pdf-inspector
iOfficeAI/OfficeCLI
Stirling-Tools/Stirling-PDF
AmineDiro/ferrules
igumnoff/shiva
""",
    "Design, maps & media": """
marceloprates/prettymaps
OpenCut-app/OpenCut
pascalorg/editor
opengeos/GeoLibre
palmier-io/palmier-pro
likec4/likec4
penpot/penpot
plotly/plotly.rs
blitzarx1/egui_graphs
""",
    "Games, hardware & experiments": """
jasonfen/terminal-space-program
jdvillal/SIMD_examples
Pumpkin-MC/Pumpkin
ruvnet/RuView
commaai/openpilot
avianphysics/avian
br-g/openf1
""",
}

DESCRIPTIONS = {
    "AI coding & OpenCode": "Coding agents, OpenCode plugins, skills and orchestration.",
    "AI memory & code intelligence": "Agent memory, context management, code indexing and vector search.",
    "LLMs & AI applications": "Model inference, gateways, structured outputs and AI applications.",
    "Editors, shell & dotfiles": "Neovim, tmux, shell tools, dotfiles and development environments.",
    "macOS tools": "Mac applications, window management, automation and Apple platform utilities.",
    "Git & code review": "Repository browsing, multi-repo workflows, diffs and code review.",
    "Tasks & productivity": "Task tracking, calendars, Jira and personal productivity.",
    "Databases & data engineering": "SQL, database clients, testing, transformations and web data extraction.",
    "Cloud, containers & DevOps": "AWS, containers, virtualization, deployment, CI and self-hosting.",
    "Security, privacy & OSINT": "Sandboxing, identity, network security, privacy and investigation tools.",
    "Web & desktop development": "Frontend components, app frameworks, APIs and desktop app architecture.",
    "Programming tools & references": "Rust and Python tools, reusable libraries, testing and programming references.",
    "PDFs & office documents": "PDF parsing, document conversion and Office automation.",
    "Design, maps & media": "Design tools, diagrams, visualizations, GIS and video editing.",
    "Games, hardware & experiments": "Simulations, game engines, robotics, sensing and interesting datasets.",
}

STARS_QUERY = """query Stars($after: String) {
  viewer { login starredRepositories(first: 100, after: $after) {
    nodes { id nameWithOwner }
    pageInfo { hasNextPage endCursor }
  } }
}"""
LISTS_QUERY = """query Lists($after: String) {
  viewer { login lists(first: 100, after: $after) {
    nodes { id name isPrivate }
    pageInfo { hasNextPage endCursor }
  } }
}"""
ITEMS_QUERY = """query Items($id: ID!, $after: String) {
  node(id: $id) { ... on UserList {
    items(first: 100, after: $after) {
      nodes { ... on Repository { id nameWithOwner } }
      pageInfo { hasNextPage endCursor }
    }
  } }
}"""
CREATE_MUTATION = """mutation Create($input: CreateUserListInput!) {
  createUserList(input: $input) { list { id name isPrivate } }
}"""
UPDATE_MUTATION = """mutation Assign($input: UpdateUserListsForItemInput!) {
  updateUserListsForItem(input: $input) { lists { id } }
}"""


def graphql(query, **variables):
    """Use gh's existing login; credentials never enter the script or files."""
    result = subprocess.run(
        ["gh", "api", "graphql", "--hostname", "github.com", "--input", "-"],
        input=json.dumps({"query": query, "variables": variables}),
        text=True, capture_output=True, timeout=90,
    )
    if result.returncode:
        raise RuntimeError(result.stderr.strip() or "GitHub CLI request failed")
    payload = json.loads(result.stdout)
    if payload.get("errors"):
        raise RuntimeError("; ".join(e["message"] for e in payload["errors"]))
    if not isinstance(payload.get("data"), dict):
        raise RuntimeError("GitHub returned no data")
    return payload["data"]


def pages(query, path, **variables):
    """Fully paginate every connection, including each existing list's items."""
    cursor, seen = None, set()
    while True:
        data = graphql(query, after=cursor, **variables)
        if "viewer" in data and data["viewer"]["login"].casefold() != ACCOUNT.casefold():
            raise RuntimeError(f"Wrong account. Run: gh auth switch --hostname github.com --user {ACCOUNT}")
        connection = data
        for key in path:
            if not isinstance(connection, dict) or key not in connection:
                raise RuntimeError("Incomplete GitHub response; stopped to protect existing memberships")
            connection = connection[key]
        for node in connection["nodes"]:
            if not node or not node.get("id"):
                raise RuntimeError("Unreadable item; stopped to protect existing memberships")
            yield node
        info = connection["pageInfo"]
        if not info["hasNextPage"]:
            break
        cursor = info["endCursor"]
        if not cursor or cursor in seen:
            raise RuntimeError("Invalid pagination cursor")
        seen.add(cursor)


def catalog():
    assignments = defaultdict(list)
    for title, block in CATALOG.items():
        if title not in DESCRIPTIONS or not title.strip():
            raise ValueError(f"Missing description for {title!r}")
        for repo in block.split():
            if repo.count("/") != 1 or any(not p for p in repo.split("/")):
                raise ValueError(f"Invalid repository name: {repo}")
            if title in assignments[repo.casefold()]:
                raise ValueError(f"Duplicate repository in {title}: {repo}")
            assignments[repo.casefold()].append(title)
    return assignments


def load_lists():
    lists = list(pages(LISTS_QUERY, ("viewer", "lists")))
    by_name = {}
    memberships = defaultdict(set)
    for item in lists:
        key = item["name"].casefold()
        if key in by_name:
            raise RuntimeError(f"Ambiguous existing list name: {item['name']}")
        by_name[key] = item
        item["items"] = list(pages(ITEMS_QUERY, ("node", "items"), id=item["id"]))
        for repo in item["items"]:
            memberships[repo["id"]].add(item["id"])
    return lists, by_name, memberships


def show_plan(stars, assignments, by_name, memberships):
    planned = defaultdict(list)
    unknown = []
    additions = 0
    for repo in stars:
        titles = assignments.get(repo["nameWithOwner"].casefold(), [])
        if not titles:
            unknown.append(repo["nameWithOwner"])
        for title in titles:
            existing = by_name.get(title.casefold())
            done = existing and existing["id"] in memberships.get(repo["id"], set())
            planned[title].append((repo["nameWithOwner"], bool(done)))
            additions += not done
    for title in CATALOG:
        if title not in planned:
            continue
        status = "reuse existing" if title.casefold() in by_name else "create private"
        print(f"\n{title} ({len(planned[title])}; {status})")
        for name, done in sorted(planned[title], key=lambda row: row[0].casefold()):
            print(f"  {'=' if done else '+'} {name}")
    if unknown:
        print("\nUnreviewed stars — left unchanged; add them to CATALOG to classify:")
        for name in sorted(unknown):
            print(f"  ? {name}")
    print(f"\n{len(stars)} stars; {len(stars) - len(unknown)} classified; "
          f"{len(unknown)} unreviewed; {additions} membership additions.")
    return planned, additions


def save_snapshot(stars, lists):
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S.%fZ")
    path = Path.cwd() / f"stars-before-{stamp}.json"
    # Exclusive creation and restrictive permissions; never overwrite a backup.
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(fd, "w", encoding="utf-8") as stream:
        json.dump({"account": ACCOUNT, "saved_at": stamp, "stars": stars,
                   "lists": lists}, stream, indent=2)
        stream.write("\n")
        stream.flush()
        os.fsync(stream.fileno())
    return path


def apply_plan(stars, assignments, by_name, memberships, planned):
    for title in planned:
        if title.casefold() in by_name:
            continue
        data = graphql(CREATE_MUTATION, input={
            "name": title, "description": DESCRIPTIONS[title], "isPrivate": True,
        })
        item = data["createUserList"]["list"]
        if not item or not item.get("id"):
            raise RuntimeError(f"GitHub did not confirm creation of {title}")
        by_name[title.casefold()] = item
        print(f"Created: {title}", flush=True)
        time.sleep(1)  # Space writes to respect secondary rate limits.
    changed = 0
    for repo in stars:
        titles = assignments.get(repo["nameWithOwner"].casefold(), [])
        if not titles:
            continue
        current = memberships.get(repo["id"], set())
        desired = current | {by_name[title.casefold()]["id"] for title in titles}
        if desired == current:
            continue
        data = graphql(UPDATE_MUTATION, input={
            "itemId": repo["id"], "listIds": sorted(desired),
        })
        returned = data["updateUserListsForItem"]["lists"]
        if returned is None or {item["id"] for item in returned} != desired:
            raise RuntimeError(f"Membership verification failed for {repo['nameWithOwner']}")
        memberships[repo["id"]] = desired
        changed += 1
        print(f"Added: {repo['nameWithOwner']} -> {', '.join(titles)}", flush=True)
        time.sleep(1)
    print(f"\nDone: updated {changed} repositories. Existing memberships retained.")


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    modes = parser.add_mutually_exclusive_group()
    modes.add_argument("--apply", action="store_true", help="apply additions to GitHub")
    modes.add_argument("--dry-run", action="store_true", help="preview live additions (default)")
    modes.add_argument("--catalog", action="store_true", help="show reviewed assignments offline")
    args = parser.parse_args(argv)
    assignments = catalog()
    if args.catalog:
        print(f"Reviewed catalog: {ACCOUNT}, {REVIEW_DATE}. Not live GitHub state.")
        for title, block in CATALOG.items():
            print(f"\n{title} ({len(block.split())})")
            for repo in sorted(block.split(), key=str.casefold):
                print(f"  {repo}")
        print(f"\n{len(assignments)} repositories across {len(CATALOG)} lists.")
        return 0
    if not shutil.which("gh"):
        raise RuntimeError("Install GitHub CLI (gh), then run: gh auth login --hostname github.com")
    print(f"Reading stars and existing lists for {ACCOUNT}...", flush=True)
    # All reads finish successfully before any GitHub mutations.
    stars = list(pages(STARS_QUERY, ("viewer", "starredRepositories")))
    lists, by_name, memberships = load_lists()
    planned, additions = show_plan(stars, assignments, by_name, memberships)
    if not args.apply:
        print("\nDry run: no changes. Run with --apply to apply these additions.")
        return 0
    if not additions:
        print("\nNothing to change.")
        return 0
    snapshot = save_snapshot(stars, lists)
    print(f"\nSaved previous state: {snapshot}", flush=True)
    print("Applying additions. New lists are private; existing list visibility is unchanged.", flush=True)
    apply_plan(stars, assignments, by_name, memberships, planned)
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print("\nInterrupted. If applying, some changes may have completed; rerun to resume.", file=sys.stderr)
        sys.exit(130)
    except (RuntimeError, ValueError, OSError, KeyError, TypeError, subprocess.TimeoutExpired) as exc:
        print(f"Error: {exc}\nIf applying, some changes may have completed. "
              "Fix the error and rerun; existing assignments are skipped.", file=sys.stderr)
        sys.exit(1)
