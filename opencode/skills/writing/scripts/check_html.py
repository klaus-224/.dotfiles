"""Check generated HTML structure and portability. Not a full HTML or a11y validator."""
import argparse
from collections import Counter
from html.parser import HTMLParser
from pathlib import Path
import sys


class Check(HTMLParser):
    def __init__(self):
        super().__init__()
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
            self.errors.append('Stylesheet is not embedded')

    def handle_startendtag(self, tag, attributes):
        self.handle_starttag(tag, attributes)
        self.handle_endtag(tag)

    def handle_endtag(self, tag):
        if tag == 'svg':
            self.svg_depth = max(0, self.svg_depth - 1)
        if tag == 'title':
            self.in_title = False

    def handle_data(self, data):
        if self.in_title:
            self.title_text += data


def check(content):
    parser = Check()
    parser.feed(content)
    parser.close()
    errors = parser.errors
    for tag in ('html', 'head', 'body', 'main', 'h1'):
        if parser.tags[tag] != 1:
            errors.append(f'Expected one {tag}; found {parser.tags[tag]}')
    if not parser.doctype:
        errors.append('Missing HTML doctype')
    if parser.document_titles != 1 or not parser.title_text.strip():
        errors.append('Missing title text')
    if not parser.viewport:
        errors.append('Missing responsive viewport')
    errors += [f'Duplicate ID: {key}' for key, count in parser.ids.items() if count > 1]
    errors += [f'Unresolved reference: {key}' for key in set(parser.references) if key not in parser.ids]
    return errors


if __name__ == '__main__':
    cli = argparse.ArgumentParser(description=__doc__)
    cli.add_argument('input', help='HTML file to check')
    args = cli.parse_args()
    try:
        issues = check(Path(args.input).read_text(encoding='utf-8'))
    except (OSError, ValueError) as error:
        print(f'error: {error}', file=sys.stderr)
        raise SystemExit(2)
    if issues:
        print('\n'.join(issues), file=sys.stderr)
        raise SystemExit(1)
    print('PASS: basic structure, local references, and embedded resource checks. Inspect layout in a browser.')
