"""Build an offline HTML explainer from plain-text JSON. No third-party packages."""
import re
from html import escape as esc
from pathlib import Path
from string import Template
from common import array, obj, run_cli, safe_url, text
from highlight import display_name, highlight, language
from markup import inline, link_url
from render_diagram import render as diagram_svg, relationships

BASE = Path(__file__).resolve().parent.parent


# A short name such as ai-agent-gateway or apps/platform breaks at its hyphens
# or slashes in a narrow column; keep it on one line. Longer ones may break.
NOBR = re.compile(r'\S*[-/]\S*')


def nobr(fragment):
    def keep(match):
        word = match.group(0)
        return f'<span class="nobr">{word}</span>' if len(word) <= 30 else word
    return NOBR.sub(keep, esc(fragment))


def cell(value):
    return inline(value, 'table cell', plain=nobr)


def code_block(b):
    source = text(b['text'], 'code')
    lang = language(b['lang']) if 'lang' in b else None
    if 'url' in b and 'file' not in b:
        raise ValueError('code.url: also give file, the label for the link')
    head = []
    if 'file' in b:
        name = f'<code>{esc(text(b["file"], "code.file", 300))}</code>'
        if 'url' in b:
            name = f'<a href="{link_url(b["url"], "code.url")}">{name}</a>'
        head.append(f'<span class="code-file">{name}</span>')
    if lang:
        head.append(f'<span class="code-lang">{display_name(lang)}</span>')
    label = f'Code: {esc(b["file"])}' if 'file' in b else 'Code example'
    css = f' class="language-{lang}"' if lang else ''
    pre = f'<pre tabindex="0" aria-label="{label}"><code{css}>{highlight(source, lang)}</code></pre>'
    if not head:
        return pre
    return f'<div class="code-block"><div class="code-head">{"".join(head)}</div>{pre}</div>'


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
        }
        if not isinstance(kind, str) or kind not in fields:
            raise ValueError(f'block.type: unknown type {kind!r}')
        optional = {'code': ['lang', 'file', 'url']}.get(kind, [])
        obj(b, f'{kind} block', ['type'] + fields[kind], ['cite'] + optional)
        self.serial += 1
        uid = f'block-{self.serial}'
        if kind == 'p':
            content = f'<p>{inline(b["text"], "paragraph")}</p>'
        elif kind == 'list':
            content = '<ul>' + ''.join(f'<li>{inline(i, "list item")}</li>'
                                      for i in array(b['items'], 'list.items')) + '</ul>'
        elif kind == 'code':
            content = code_block(b)
        elif kind == 'table':
            caption = esc(text(b['caption'], 'table.caption'))
            headers = array(b['headers'], 'table.headers', 1, 12)
            head = ''.join(f'<th scope="col">{esc(text(h, "table header"))}</th>' for h in headers)
            rows = []
            for row in array(b['rows'], 'table.rows'):
                array(row, 'table row', len(headers), len(headers))
                rows.append('<tr>' + ''.join(f'<td>{cell(c)}</td>' for c in row) + '</tr>')
            content = (f'<div class="overflow" tabindex="0" role="region" aria-label="{caption}">'
                       f'<table><caption>{caption}</caption><thead><tr>{head}</tr></thead>'
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
            content = (f'<details><summary>{inline(b["summary"], "details.summary", links=False)}</summary>'
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


def render(data):
    obj(data, 'document', ['title', 'summary', 'sections'], ['eyebrow', 'lang', 'sources'])
    title = esc(text(data['title'], 'title', 200))
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
    template = Template((BASE/'templates/page.html').read_text(encoding='utf-8'))
    return template.substitute(
        lang=lang, title=title, summary=summary,
        eyebrow=esc(text(data.get('eyebrow', 'A clear explanation'), 'eyebrow', 100)),
        css=(BASE/'templates/style.css').read_text(encoding='utf-8'),
        script=(BASE/'templates/interaction.js').read_text(encoding='utf-8'),
        nav=''.join(nav), content=''.join(contents), sources=source_html)


if __name__ == '__main__':
    run_cli('Render a JSON explanation to one offline HTML file.', render)
