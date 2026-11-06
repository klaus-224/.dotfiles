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

To reproduce the dependency-free tool tests from this directory:

```sh
python3 -m unittest discover -s tests -v
```

## 2026-11-05: artifact target and diagram lanes

- 26 unit tests pass. New tests cover the artifact fragment (no skeleton tags,
  system-theme CSS reusing the light tokens, checker rules), unknown targets, the
  CLI `--target artifact` path, lanes for edges that skip rows, and sibling labels.
- The pw-failure-report explainer was rendered with `--target artifact`, passed
  `check_html.py --target artifact`, and was inspected in headless Chrome in dark
  and light mode at 1200px. Inside a host-like wrapper (14px system body font),
  the template font and size applied.
- At 400px (an iframe, because headless Chrome's minimum window is 500px), the
  document was exactly 400px wide; wide tables and diagrams scroll in their frames.
- The three flow diagrams were checked visually: edges that skip rows use their own
  lanes, and sibling labels no longer overlap. One label still crosses a nearby
  vertical edge; its halo keeps it readable.
- Not checked: the theme switch in a live claude.ai viewer, print output.

## 2026-11-05: inline marks, notes, Plex fonts and right-angle diagrams

- 31 unit tests pass. New tests cover inline code and tags (escaping, table cells,
  title), note blocks, key and monospace diagram nodes, right-angle routing that
  avoids other boxes, and label sides.
- The pw-failure-report explainer was rendered again and inspected section by
  section at 1000px in dark and light mode. IBM Plex loaded from Google Fonts.
