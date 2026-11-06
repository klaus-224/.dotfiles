"""Build an offline HTML explainer from plain-text JSON. No third-party packages."""
import re
from html import escape as esc
from pathlib import Path
from string import Template
from common import array, obj, run_cli, safe_url, text
from render_diagram import render as diagram_svg, relationships

BASE = Path(__file__).resolve().parent.parent


# A short name such as ai-agent-gateway or apps/platform breaks at its hyphens
# or slashes in a narrow column; keep it on one line. Longer ones may break.
NOBR = re.compile(r'\S*[-/]\S*')


# Inline markup in plain-text fields: `code`, [[tag]] and [[!warning tag]].
INLINE = re.compile(r'`([^`\n]+)`|\[\[(!?)([^\]\n]+)\]\]')


def inline(value, where, limit=20000, plain=esc):
    raw = text(value, where, limit)
    out, pos = [], 0
    for match in INLINE.finditer(raw):
        out.append(plain(raw[pos:match.start()]))
        if match.group(1) is not None:
            out.append(f'<code>{esc(match.group(1))}</code>')
        else:
            tone = ' warn' if match.group(2) else ''
            out.append(f'<span class="tag{tone}">{esc(match.group(3))}</span>')
        pos = match.end()
    out.append(plain(raw[pos:]))
    return ''.join(out)


def strip_inline(value):
    """Plain text for attributes and <title>: the markup without its delimiters."""
    return INLINE.sub(lambda m: m.group(1) if m.group(1) is not None else m.group(3), value)


def cell(value):
    def keep(match):
        word = match.group(0)
        return f'<span class="nobr">{word}</span>' if len(word) <= 30 else word
    return inline(value, 'table cell', plain=lambda part: NOBR.sub(keep, esc(part)))


class Renderer:
    def __init__(self, sources):
        self.sources = sources
        self.serial = 0

    def blocks(self, blocks, depth=0):
        if depth > 6:
            raise ValueError('blocks: too many nested disclosures')
        return ''.join(self.block(b, depth) for b in array(blocks, 'blocks'))

    def block(self, b, depth):
        if not isinstance(b, dict):
            raise ValueError('block: expected an object')
        kind = b.get('type')
        fields = {
            'p': ['text'], 'list': ['items'], 'table': ['caption', 'headers', 'rows'],
            'code': ['text'], 'diagram': ['data', 'caption'],
            'details': ['summary', 'blocks'], 'steps': ['title', 'items'],
            'note': ['label', 'blocks'],
        }
        if not isinstance(kind, str) or kind not in fields:
            raise ValueError(f'block.type: unknown type {kind!r}')
        obj(b, f'{kind} block', ['type'] + fields[kind], ['cite', 'tone'] if kind == 'note' else ['cite'])
        self.serial += 1
        uid = f'block-{self.serial}'
        if kind == 'p':
            content = f'<p>{inline(b["text"], "paragraph")}</p>'
        elif kind == 'note':
            tone = b.get('tone', 'warn')
            if tone not in ('warn', 'info'):
                raise ValueError('note.tone: use warn or info')
            content = (f'<div class="note {tone}"><p class="note-label">{esc(text(b["label"], "note.label", 40))}</p>'
                       f'{self.blocks(b["blocks"], depth+1)}</div>')
        elif kind == 'list':
            content = '<ul>' + ''.join(f'<li>{inline(i, "list item")}</li>'
                                      for i in array(b['items'], 'list.items')) + '</ul>'
        elif kind == 'code':
            content = f'<pre tabindex="0" aria-label="Code example"><code>{esc(text(b["text"], "code"))}</code></pre>'
        elif kind == 'table':
            caption_html = inline(b['caption'], 'table.caption')
            caption = esc(strip_inline(b['caption']))
            headers = array(b['headers'], 'table.headers', 1, 12)
            head = ''.join(f'<th scope="col">{esc(text(h, "table header"))}</th>' for h in headers)
            rows = []
            for row in array(b['rows'], 'table.rows'):
                array(row, 'table row', len(headers), len(headers))
                rows.append('<tr>' + ''.join(f'<td>{cell(c)}</td>' for c in row) + '</tr>')
            content = (f'<div class="overflow" tabindex="0" role="region" aria-label="{caption}">'
                       f'<table><caption>{caption_html}</caption><thead><tr>{head}</tr></thead>'
                       f'<tbody>{"".join(rows)}</tbody></table></div>')
        elif kind == 'diagram':
            caption = inline(b['caption'], 'diagram caption')
            svg = diagram_svg(b['data'], uid)
            lines = relationships(b['data'])
            relation_list = '<ul>' + ''.join(f'<li>{esc(r)}</li>' for r in lines) + '</ul>' if lines else ''
            content = (f'<figure><p class="diagram-hint">Scroll sideways if the diagram does not fit.</p><div class="diagram overflow" tabindex="0" role="region" '
                       f'aria-label="{esc(b["data"]["title"])}">{svg}</div>'
                       f'<figcaption>{caption}</figcaption><details><summary>Diagram in words</summary>'
                       f'<p>{esc(b["data"]["description"])}</p>{relation_list}</details></figure>')
        elif kind == 'details':
            content = (f'<details><summary>{esc(text(b["summary"], "details.summary"))}</summary>'
                       f'{self.blocks(b["blocks"], depth+1)}</details>')
        else:
            title = esc(text(b['title'], 'steps.title'))
            items = []
            for index, item in enumerate(array(b['items'], 'steps.items', 1, 20), 1):
                obj(item, 'step', ['title', 'text'])
                items.append(f'<li value="{index}"><h4>{esc(text(item["title"], "step.title"))}</h4>'
                             f'<p>{inline(item["text"], "step.text")}</p></li>')
            content = (f'<div class="walkthrough" aria-labelledby="{uid}-title">'
                       f'<h3 id="{uid}-title">{title}</h3><div class="step-controls" hidden>'
                       f'<button type="button" data-prev aria-controls="{uid}-steps">Previous</button>'
                       f'<span role="status" aria-live="polite" aria-atomic="true"></span>'
                       f'<button type="button" data-next aria-controls="{uid}-steps">Next</button>'
                       f'<button type="button" data-all aria-pressed="false" aria-controls="{uid}-steps">Show all steps</button>'
                       f'</div><ol id="{uid}-steps">{"".join(items)}</ol></div>')
        citations = b.get('cite', [])
        array(citations, 'cite', 0, len(self.sources))
        if citations:
            links = []
            for number in citations:
                if type(number) is not int or not 1 <= number <= len(self.sources):
                    raise ValueError('cite: use 1-based source numbers from the document sources list')
                links.append(f'<a href="#source-{number}" aria-label="Source {number}">[{number}]</a>')
            content += f'<p class="citations">Sources: {" ".join(links)}</p>'
        return content


TARGETS = ('page', 'artifact')

# claude.ai artifacts: the host wraps the file in its own doctype/html/head/body, its body rule
# sets a 14px system font, and most viewers leave the theme on "system" (no data-theme attribute).
# So the fragment restores the page font, follows prefers-color-scheme, and keeps the side gutter
# clear of a phone's safe-area insets.
ARTIFACT_CSS = """
body { font-family: inherit; font-size: 1rem; line-height: inherit; }
.page { padding-left: max(48px, env(safe-area-inset-left, 0px)); padding-right: max(48px, env(safe-area-inset-right, 0px)); }
@media (max-width: 800px) {
  .page { padding-left: max(16px, env(safe-area-inset-left, 0px)); padding-right: max(16px, env(safe-area-inset-right, 0px)); }
}
"""


def artifact_css(css):
    """Add a system-preference light theme that reuses the template's light tokens."""
    marker = ':root[data-theme="light"] {'
    start = css.index(marker) + len(marker)
    light = css[start:css.index('}', start)]
    system = ('/* Follow the viewer\'s system theme unless a theme is chosen. */\n'
              '@media (prefers-color-scheme: light) {\n  :root:not([data-theme="dark"]) {' + light + '}\n}\n')
    # Before the print rules, so print colors still win.
    at = css.find('@media print')
    css = css[:at] + system + css[at:] if at >= 0 else css + system
    return css + ARTIFACT_CSS


def render(data, target='page'):
    if target not in TARGETS:
        raise ValueError(f'target: use one of {", ".join(TARGETS)}')
    obj(data, 'document', ['title', 'summary', 'sections'], ['eyebrow', 'lang', 'sources'])
    title_html = inline(data['title'], 'title', 200)
    title = esc(strip_inline(data['title']))
    summary = inline(data['summary'], 'summary', 2000)
    lang = data.get('lang', 'en')
    if not isinstance(lang, str) or not re.fullmatch(r'[A-Za-z]{2,8}(?:-[A-Za-z0-9]{1,8})*', lang):
        raise ValueError('lang: expected a language tag such as en or en-CA')
    sources = array(data.get('sources', []), 'sources', 0, 100)
    source_items = []
    for index, source in enumerate(sources, 1):
        obj(source, 'source', ['label', 'url'])
        source_items.append(f'<li id="source-{index}"><a href="{safe_url(source["url"])}">'
                            f'{esc(text(source["label"], "source.label"))}</a></li>')
    renderer = Renderer(sources)
    contents, nav = [], []
    for index, section in enumerate(array(data['sections'], 'sections', 1, 30), 1):
        obj(section, 'section', ['title', 'blocks'])
        heading = esc(text(section['title'], 'section.title', 200))
        sid = f'section-{index}'
        nav.append(f'<li><a href="#{sid}"><span>{index:02}</span>{heading}</a></li>')
        contents.append(f'<section id="{sid}"><p class="section-number">{index:02}</p>'
                        f'<h2>{heading}</h2>{renderer.blocks(section["blocks"])}</section>')
    source_html = ('<section id="sources"><h2>Sources</h2><ol class="sources">' +
                   ''.join(source_items) + '</ol></section>') if sources else ''
    name = 'artifact.html' if target == 'artifact' else 'page.html'
    template = Template((BASE/'templates'/name).read_text(encoding='utf-8'))
    css = (BASE/'templates/style.css').read_text(encoding='utf-8')
    return template.substitute(
        lang=lang, title=title, title_html=title_html, summary=summary,
        eyebrow=esc(text(data.get('eyebrow', 'A clear explanation'), 'eyebrow', 100)),
        css=artifact_css(css) if target == 'artifact' else css,
        script=(BASE/'templates/interaction.js').read_text(encoding='utf-8'),
        nav=''.join(nav), content=''.join(contents), sources=source_html)


if __name__ == '__main__':
    run_cli('Render a JSON explanation to one offline HTML file.', render, targets=TARGETS)
