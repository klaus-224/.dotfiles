# writing — an OpenCode v2 skill

Clear prose, explanatory diagrams, and interactive HTML for agent replies.
Inspired by the Karpathy excerpt supplied with the request. The style uses relaxed
ASD-STE100 principles; it does not claim formal compliance.

In this dotfiles repository, the shared OpenCode configuration exposes this skill.
Builder uses it for explanations and artifacts; chat uses its inline prose
guidance while staying read-only. The installation steps below are for using the
skill outside this managed configuration.

## Install

Copy this entire `writing` directory, including its scripts and templates, to
either location:

- Project: `.opencode/skills/writing/`
- All projects: `~/.config/opencode/skills/writing/`

For example, from the directory containing this package on macOS or Linux:

```sh
mkdir -p .opencode/skills
cp -R writing .opencode/skills/
```

Use this copy command for a new installation. If `writing` already exists at the
destination, compare and update it deliberately rather than copying over it blindly.
For global installation, use `~/.config/opencode/skills` as the destination instead.
On Windows, copy the folder with your file manager to your OpenCode config's
`skills` directory. The scripts work on Windows with an installed Python runtime;
use `py -3` if your Python command is not `python3`.

The main file must end up at `skills/writing/SKILL.md`, not directly at
`skills/SKILL.md`. No plugin registration, npm dependencies, permission edits,
or server is required. Python 3.10+ is needed only for the rendering tools.

## Use

In OpenCode, start with:

> @writing Explain how this system works. Give me an HTML page with a diagram.

The agent can also load the skill with `skill({"id":"writing"})`.
This is an illustration of the tool input, not a command to paste into a shell.

To make it your normal writing preference, add the following sentence to your
existing project `AGENTS.md`, or to `~/.config/opencode/AGENTS.md` for all projects:

> Load the `writing` skill before composing substantive replies to me. Apply its
> writing principles to brief replies too. Use diagrams and HTML when they make
> an explanation easier to understand. Respect any format I explicitly request.

Installing a discoverable skill makes it available; it does not guarantee that
the model will load it for every reply. The persistent instruction establishes
that preference. Keep your existing `AGENTS.md` guidance when adding this sentence.

## Try the tools

From inside the installed `writing` directory:

```sh
python3 scripts/render_html.py examples/explanation.json --output demo.html
python3 scripts/render_diagram.py examples/diagram.json --output diagram.svg
python3 scripts/check_html.py demo.html
python3 -m unittest discover -s tests -v
```

Open `demo.html` in a browser. Generated HTML and SVG files work offline. A served
site is unnecessary. The HTML includes flow and sequence diagrams, sources,
collapsible details, print styles, and a keyboard-operated walkthrough.
The renderer refuses to replace existing output unless you pass `--overwrite`.
For real tasks, write outputs in the active workspace, not inside the installed skill.

Read `references/tools.md` for the JSON format, bounds, and limitations.

## OpenCode v2 alignment

The directory gives the skill the ID `writing`. `name` supplies its display label,
and `description` makes its purpose discoverable. Supporting paths are relative to
the skill base. Explicit invocation uses `@writing` or the skill tool's `id` input.
These conventions follow the [v2 skill documentation](https://opencode.ai/v2/docs/skills/#create).

The utilities run through [v2's shell tool](https://opencode.ai/v2/docs/tools/).
They are bundled scripts, not tool registrations. For persistent writing guidance,
use [AGENTS.md](https://opencode.ai/v2/docs/instructions/); v2 currently does not
resolve the config's `instructions` array into active instructions.

Docs checked 2026-10-08. The package has no dependency on OpenCode's internal API.
