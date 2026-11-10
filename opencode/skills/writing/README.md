# writing

Clear prose, explanatory diagrams, and self-contained HTML for agent replies.
The style uses relaxed ASD-STE100 principles; it does not claim formal compliance.

The skill lives in `apps/playwright-tests/.agents/skills/writing/`. Any agent
harness that loads skills from this folder can use it. Point the agent at
`SKILL.md`; it reads the supporting files from this directory as needed.

## Contents

| Path | Purpose |
| --- | --- |
| `SKILL.md` | Writing principles and the steps for producing an HTML explanation |
| `references/tools.md` | JSON input format, bounds, and limitations of the renderers |
| `examples/` | Sample inputs for an HTML page (`explanation.json`) and a diagram (`diagram.json`) |
| `scripts/render_html.py` | Renders an explanation JSON into a standalone HTML page |
| `scripts/render_diagram.py` | Renders a small `flow` or `sequence` diagram as standalone SVG |
| `scripts/markup.py` | Safe inline markup (code, bold, highlight, links) for prose fields |
| `scripts/highlight.py` | Offline syntax highlighting for code blocks |
| `scripts/check_html.py` | Static checks on a generated page |
| `templates/` | Page template, CSS, and walkthrough script embedded in generated pages |

Python 3.10+ is needed only for the scripts. They use the standard library, need
no network access, and do not install or register anything.

## Use

Ask the agent to load the `writing` skill, for example:

> Use the writing skill. Explain how manual QC sign-in works, with a diagram.

## Try the tools

From this directory:

```sh
out=/tmp/writing/demo
python3 scripts/render_html.py examples/explanation.json --output "$out/demo.html"
python3 scripts/render_diagram.py examples/diagram.json --output "$out/diagram.svg"
python3 scripts/check_html.py "$out/demo.html"
```

Open `demo.html` in a browser. Generated HTML and SVG files work offline. The page
includes flow and sequence diagrams, sources, collapsible details, print styles,
and a keyboard-operated walkthrough. The renderers refuse to replace existing
output unless you pass `--overwrite`.

## Where output goes

Write inputs and outputs to a scratch directory on the user's machine, such as
`/tmp/writing/<task-slug>/`. Do not write them into the repository or this skill
directory, and do not commit them. To share a diagram in a PR or issue, embed it
there (for example as a Mermaid block, which GitHub renders).
