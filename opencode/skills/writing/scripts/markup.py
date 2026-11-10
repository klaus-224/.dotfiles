"""Safe inline markup for prose fields. Python standard library only.

Supported: `code`, **important**, ==highlight==, [label](url), and a backslash
before ` * = [ ] or \\ for a literal character. Everything else is escaped text.
"""
import re
from html import escape as esc
from urllib.parse import urlsplit
from common import text

# A code span inside **…** or ==…== is skipped as a unit, so markers inside it
# do not end the emphasis early.
INNER = r'(?:`[^`\n]+`|[^`\n])'
TOKEN = re.compile(
    r'\\(?P<escape>[\\`*=\[\]])'
    r'|`(?P<code>[^`\n]+)`'
    r'|\[(?P<label>[^\]\n]+)\]\((?P<url>[^()\s]+)\)'
    rf'|\*\*(?P<strong>(?=\S){INNER}+?(?<=\S))\*\*'
    rf'|==(?P<mark>(?=\S){INNER}+?(?<=\S))=='
)
ANCHOR = re.compile(r'#[A-Za-z][\w-]*')


def link_url(value, where='link URL'):
    """Allow web links, local file links, and links to an ID on the same page."""
    value = text(value, where, 4000)
    if ANCHOR.fullmatch(value):
        return esc(value, quote=True)
    parsed = urlsplit(value)
    web = parsed.scheme in ('https', 'http') and parsed.netloc
    local = parsed.scheme == 'file' and parsed.path.startswith('/')
    if not (web or local) or re.search(r'\s', value):
        raise ValueError(f'{where}: use an HTTP(S) URL, a file:/// URL, or a #id on this page')
    return esc(value, quote=True)


def inline(value, where, limit=20000, plain=esc, links=True, nowrap=0):
    """Render one plain-text field with inline markup. Returns safe HTML.

    Code spans up to `nowrap` characters are kept on one line."""
    return _render(text(value, where, limit), where, plain, links, nowrap)


def _render(value, where, plain, links, nowrap=0):
    out, position = [], 0
    for match in TOKEN.finditer(value):
        out.append(plain(value[position:match.start()]))
        position = match.end()
        kind = match.lastgroup
        if kind == 'escape':
            out.append(plain(match.group('escape')))
        elif kind == 'code':
            source = match.group('code')
            css = 'inline nobr' if len(source) <= nowrap else 'inline'
            out.append(f'<code class="{css}">{esc(source)}</code>')
        elif kind == 'url':
            label = _render(match.group('label'), where, plain, False, nowrap)
            if links:
                href = link_url(match.group('url'), f'{where} link')
                out.append(f'<a href="{href}">{label}</a>')
            else:
                out.append(label)
        else:
            tag = 'strong' if kind == 'strong' else 'mark'
            out.append(f'<{tag}>{_render(match.group(kind), where, plain, links, nowrap)}</{tag}>')
    out.append(plain(value[position:]))
    return ''.join(out)
