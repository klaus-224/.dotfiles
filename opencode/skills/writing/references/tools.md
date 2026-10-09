# Tool reference

Run these scripts with Python 3.10 or later through OpenCode v2's `shell` tool.
They use only Python's standard library. Use the base directory supplied when the
skill loads. The following commands assume that directory is the working directory;
otherwise use absolute script paths and workspace-relative input/output paths.

```sh
python3 scripts/render_html.py examples/explanation.json --output demo.html
python3 scripts/render_diagram.py examples/diagram.json --output diagram.svg
python3 scripts/check_html.py demo.html
```

`render_html.py` and `render_diagram.py` accept `--overwrite` for intended revisions.
They print the absolute output path on success. Invalid JSON, unsupported fields,
bad diagrams, and filesystem failures exit with status 2. They refuse to overwrite
their input or replace existing output by default. An invalid render does not
replace a previous output file. There are no downloads or subprocesses.

`check_html.py` exits 0 for a pass, 1 for findings, or 2 if the file cannot be read.
It checks basic landmarks, IDs, local links, accessible SVG names, and obvious
external asset references. It does not validate all HTML, parse CSS/JavaScript for
network requests, prove accessibility, verify claims, or detect visual overlaps.

## HTML document input

The file is a JSON object. All content strings are plain text, not Markdown or HTML.
Text is escaped before insertion. Unknown keys are errors so misspelled fields do
not silently disappear. Required fields:

```json
{
  "title": "Use a queue to absorb short bursts",
  "summary": "A queue holds tasks until a worker can process them.",
  "sections": [
    {
      "title": "How it works",
      "blocks": [
        {"type": "p", "text": "The producer adds tasks. The worker takes them when it has capacity."}
      ]
    }
  ]
}
```

Optional document fields:

| Field | Value |
| --- | --- |
| `eyebrow` | A short label above the title |
| `lang` | Language tag; defaults to `en` |
| `sources` | List of objects with `label` and absolute HTTP(S) `url` |

The default interface labels are English. For another language, translate the
template and fixed UI strings as well as setting `lang` and translating the content.

Use 1–30 sections and 1–100 blocks per block list. These are guardrails, not targets;
prefer a small document. Each section has `title` and `blocks`. Each block has a
`type` and the fields below. Every block also accepts optional `cite: [1, 2]`, which
links to the corresponding 1-based entries in the document's `sources` list.
Keep citations attached to the block with the supported claim.

| Type | Required fields | Meaning |
| --- | --- | --- |
| `p` | `text` | Paragraph |
| `list` | `items`: list of strings | Unordered list |
| `table` | `caption`, `headers`: strings, `rows`: arrays of strings | Comparison table; each row must match the header count |
| `code` | `text` | Literal code or commands; never executed |
| `diagram` | `data`: diagram object, `caption` | Embedded SVG and text equivalent |
| `details` | `summary`, `blocks` | Native expandable detail; nesting limited to six levels |
| `steps` | `title`, `items`: objects with `title` and `text` | Previous/next walkthrough; all steps remain present without JavaScript |

Keep key findings outside `details`. Each diagram's text equivalent includes its
description and generated relationships. Walkthrough controls use native buttons
and announce the current step. Print styles show all steps, and the print handler
opens disclosures temporarily. Browser print behavior can vary, so inspect the
result if PDF or print is a deliverable.

## Diagram input

Use the same object as `diagram.data` or pass it directly to `render_diagram.py`:

```json
{
  "type": "flow",
  "title": "One task through the system",
  "description": "The producer sends a task to a worker.",
  "nodes": [
    {"id": "producer", "label": "Producer"},
    {"id": "worker", "label": "Worker"}
  ],
  "edges": [
    {"from": "producer", "to": "worker", "label": "Send task"}
  ]
}
```

- `flow` arranges a directed acyclic graph from top to bottom. Branches and merges
  work. Node order controls order within a row. Cycles and self edges are rejected.
- `sequence` places participants in node order and messages in edge order. Opposing
  message directions are supported. Self messages are unsupported.
- Flow accepts up to 16 nodes; sequence accepts up to 8. Both accept 0–32 edges.
- IDs must be unique and match `[A-Za-z][A-Za-z0-9_-]*`. Edge endpoints must exist.
- Node labels accept up to 100 characters; edge labels accept up to 60. Prefer
  much shorter labels. Titles and descriptions are required for accessibility.
- These layouts are intentionally simple. Dense graphs, long edges that skip
  levels, and many crossings need visual inspection or a custom layout.
  Split an unreadable diagram rather than shrinking its labels.

For a custom chart, cyclic graph, or simulation, use the generated HTML as a
starting point or write standalone HTML directly. Keep CSS, scripts, and SVG local
or embedded, label assumptions, and preserve keyboard and noninteractive access.
Re-run the checker after edits and inspect the result. The tool does not accept
arbitrary raw HTML, CSS, JavaScript, external SVG, or Mermaid in JSON fields.

## Editing and verification

To revise the content, edit the JSON and render again. To change the standard page
design, edit `templates/page.html`, `templates/style.css`, or
`templates/interaction.js`. The HTML template uses Python `string.Template` tokens:
use `$$` for a literal dollar sign in the template. CSS and JavaScript files are
inserted as values, so their own dollar signs need no escaping.

Run the bundled checks:

```sh
python3 -m unittest discover -s tests -v
```

Also open a generated page. Check a wide and narrow viewport, horizontal diagram
scrolling, keyboard focus, previous/next buttons, all-steps mode, and print output.
Disable JavaScript once: all explanations and all walkthrough steps must remain
readable. External source links are links, not assets needed to render the page.
