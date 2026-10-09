"""Build an offline HTML explainer from plain-text JSON. No third-party packages."""
import re
from html import escape as esc
from pathlib import Path
from string import Template
from common import array, obj, run_cli, safe_url, text
from render_diagram import render as diagram_svg, relationships

BASE = Path(__file__).resolve().parent.parent


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
        obj(b, f'{kind} block', ['type'] + fields[kind], ['cite'])
        self.serial += 1
        uid = f'block-{self.serial}'
        if kind == 'p':
            content = f'<p>{esc(text(b["text"], "paragraph"))}</p>'
        elif kind == 'list':
            content = '<ul>' + ''.join(f'<li>{esc(text(i, "list item"))}</li>'
                                      for i in array(b['items'], 'list.items')) + '</ul>'
        elif kind == 'code':
            content = f'<pre tabindex="0" aria-label="Code example"><code>{esc(text(b["text"], "code"))}</code></pre>'
        elif kind == 'table':
            caption = esc(text(b['caption'], 'table.caption'))
            headers = array(b['headers'], 'table.headers', 1, 12)
            head = ''.join(f'<th scope="col">{esc(text(h, "table header"))}</th>' for h in headers)
            rows = []
            for row in array(b['rows'], 'table.rows'):
                array(row, 'table row', len(headers), len(headers))
                rows.append('<tr>' + ''.join(f'<td>{esc(text(c, "table cell"))}</td>' for c in row) + '</tr>')
            content = (f'<div class="overflow" tabindex="0" role="region" aria-label="{caption}">'
                       f'<table><caption>{caption}</caption><thead><tr>{head}</tr></thead>'
                       f'<tbody>{"".join(rows)}</tbody></table></div>')
        elif kind == 'diagram':
            caption = esc(text(b['caption'], 'diagram caption'))
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
                             f'<p>{esc(text(item["text"], "step.text"))}</p></li>')
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
    summary = esc(text(data['summary'], 'summary', 2000))
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
