# Validation

Checked on 2026-10-08 with Python 3.12 and Chromium.

- 19 standard-library unit tests pass. They cover invalid inputs, HTML/SVG text
  escaping, source references, diagram cycles and endpoints, and CLI file handling.
- The example HTML passes the included structural checker.
- YAML frontmatter parses; the directory ID is `writing`; referenced supporting
  files exist.
- Chromium checks pass at desktop and mobile widths: no document-wide overflow,
  keyboard previous/next controls, all-steps mode, disclosures, and print steps.
- The page renders to PDF. The page makes no external resource requests.
- With JavaScript disabled, both SVG diagrams and all walkthrough steps remain
  available; native disclosures still work.
- Desktop and mobile screenshots were visually inspected. Diagram labels retain
  their size with horizontal scrolling when space is limited.

The browser harness loaded the generated HTML directly with Playwright's
`set_content`; this environment's browser policy blocks `file://` navigation.
The generated file contains no asset fetches and requires no server.

The OpenCode conventions were checked against the linked v2 documentation.
OpenCode itself is not installed in this environment, so a live OpenCode discovery
and invocation test was not run. Browser checks are not a full accessibility audit.

## 2026-11-10: inline markup, syntax highlighting, layout switch

Checked with Python 3.14 and Playwright 1.61 Chromium.

- 30 unit tests pass. The 11 new tests cover inline markup and its escaping,
  rejected link schemes, literal markers, links to code, code block fields,
  highlighting of every language without text loss, and the width switch markup.
- The example HTML passes the structural checker.
- Chromium at 1600×1000 and 390×844: the narrow layout has 48px and 22px
  gutters, and the wide layout has 24px and 12px. The width choice survives a reload.
  No layout has document-wide horizontal overflow. No page errors or network requests.
- With JavaScript disabled, the switches stay hidden and the narrow layout applies.
- Dark, light, and print screenshots of code blocks, inline code, highlights, and
  linked code headers were visually inspected. Syntax colors measure at least
  4.7:1 contrast against every code background, including print.

To reproduce the dependency-free tool tests from this directory:

```sh
python3 -m unittest discover -s tests -v
```
