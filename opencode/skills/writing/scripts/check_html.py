"""Check generated HTML structure and portability. Not a full HTML or a11y validator.

--target page (default) checks a standalone file. --target artifact checks a claude.ai
artifact fragment: the host supplies doctype, html, head, body and viewport, so those must
be absent, and the colors must follow the viewer's theme."""
import argparse
import re
from collections import Counter
from html.parser import HTMLParser
from pathlib import Path
import sys


ARTIFACT_STYLESHEETS = ('https://fonts.googleapis.com/',)


class Check(HTMLParser):
    def __init__(self, target='page'):
        super().__init__()
        self.target = target
        self.style = ''
        self.in_style = False
        self.tags = Counter()
        self.ids = Counter()
        self.references = []
        self.errors = []
        self.doctype = False
        self.viewport = False
        self.in_title = False
        self.title_text = ''
        self.svg_depth = 0
        self.document_titles = 0

    def handle_decl(self, decl):
        if decl.lower() == 'doctype html':
            self.doctype = True

    def handle_starttag(self, tag, attributes):
        attrs = dict(attributes)
        self.tags[tag] += 1
        if attrs.get('id'):
            self.ids[attrs['id']] += 1
        if tag == 'html' and not attrs.get('lang'):
            self.errors.append('Missing document language')
        if tag == 'svg':
            self.svg_depth += 1
        if tag == 'title' and self.svg_depth == 0:
            self.in_title = True
            self.document_titles += 1
        if tag == 'meta' and attrs.get('name') == 'viewport':
            self.viewport = 'width=device-width' in attrs.get('content', '')
        for key in ('aria-labelledby', 'aria-describedby', 'aria-controls'):
            self.references.extend(attrs.get(key, '').split())
        if tag == 'a' and attrs.get('href', '').startswith('#'):
            self.references.append(attrs['href'][1:])
        if tag == 'img' and 'alt' not in attrs:
            self.errors.append('Image missing alt text')
        if tag == 'svg' and (attrs.get('role') != 'img' or not attrs.get('aria-labelledby')):
            self.errors.append('SVG missing accessible name')
        if tag in ('script', 'img', 'iframe', 'video', 'audio', 'source') and attrs.get('src'):
            if not attrs['src'].startswith('data:'):
                self.errors.append(f'{tag} depends on a separate resource')
        if tag == 'link' and attrs.get('rel') == 'stylesheet':
            if not (self.target == 'artifact' and attrs.get('href', '').startswith(ARTIFACT_STYLESHEETS)):
                self.errors.append('Stylesheet is not embedded')
        if tag == 'style':
            self.in_style = True

    def handle_startendtag(self, tag, attributes):
        self.handle_starttag(tag, attributes)
        self.handle_endtag(tag)

    def handle_endtag(self, tag):
        if tag == 'svg':
            self.svg_depth = max(0, self.svg_depth - 1)
        if tag == 'title':
            self.in_title = False
        if tag == 'style':
            self.in_style = False

    def handle_data(self, data):
        if self.in_title:
            self.title_text += data
        if self.in_style:
            self.style += data


def check(content, target='page'):
    if target not in ('page', 'artifact'):
        raise ValueError('target: use page or artifact')
    parser = Check(target)
    parser.feed(content)
    parser.close()
    errors = parser.errors
    if target == 'page':
        for tag in ('html', 'head', 'body', 'main', 'h1'):
            if parser.tags[tag] != 1:
                errors.append(f'Expected one {tag}; found {parser.tags[tag]}')
        if not parser.doctype:
            errors.append('Missing HTML doctype')
        if not parser.viewport:
            errors.append('Missing responsive viewport')
    else:
        for tag in ('html', 'head', 'body'):
            if parser.tags[tag]:
                errors.append(f'Artifact must not contain <{tag}>; the host adds it')
        for tag in ('main', 'h1'):
            if parser.tags[tag] != 1:
                errors.append(f'Expected one {tag}; found {parser.tags[tag]}')
        if parser.doctype:
            errors.append('Artifact must not contain a doctype; the host adds it')
        if '<title>' not in content[:8192]:
            errors.append('Artifact title must appear in the first 8 KB')
        css = re.sub(r'\s+', '', parser.style)
        if ':root{' not in css:
            errors.append('Artifact CSS must define its color tokens on bare :root')
        if '@media(prefers-color-scheme:' not in css:
            errors.append("Artifact CSS must follow the viewer's system theme (prefers-color-scheme)")
        if not re.search(r':root\[data-theme="(light|dark)"\]', css):
            errors.append('Artifact CSS must honour an explicit data-theme on the root')
    if parser.document_titles != 1 or not parser.title_text.strip():
        errors.append('Missing title text')
    errors += [f'Duplicate ID: {key}' for key, count in parser.ids.items() if count > 1]
    errors += [f'Unresolved reference: {key}' for key in set(parser.references) if key not in parser.ids]
    return errors


if __name__ == '__main__':
    cli = argparse.ArgumentParser(description=__doc__)
    cli.add_argument('input', help='HTML file to check')
    cli.add_argument('--target', choices=('page', 'artifact'), default='page',
                     help='page: standalone file; artifact: claude.ai artifact fragment')
    args = cli.parse_args()
    try:
        issues = check(Path(args.input).read_text(encoding='utf-8'), args.target)
    except (OSError, ValueError) as error:
        print(f'error: {error}', file=sys.stderr)
        raise SystemExit(2)
    if issues:
        print('\n'.join(issues), file=sys.stderr)
        raise SystemExit(1)
    print('PASS: basic structure, local references, and embedded resource checks. Inspect layout in a browser.')
