"""Shared input and output helpers. Python standard library only."""
import argparse
import json
import re
import sys
from html import escape
from pathlib import Path
from urllib.parse import urlsplit


def text(value, where, limit=20000):
    if not isinstance(value, str) or not value.strip() or len(value) > limit:
        raise ValueError(f"{where}: expected nonempty text, at most {limit} characters")
    if any(ord(c) < 32 and c not in '\n\r\t' for c in value):
        raise ValueError(f"{where}: invalid control character")
    return value


def obj(value, where, required, optional=()):
    if not isinstance(value, dict):
        raise ValueError(f"{where}: expected an object")
    missing = set(required) - value.keys()
    extra = value.keys() - set(required) - set(optional)
    if missing or extra:
        raise ValueError(f"{where}: missing fields {sorted(missing)}; unknown fields {sorted(extra)}")
    return value


def array(value, where, minimum=1, maximum=100):
    if not isinstance(value, list) or not minimum <= len(value) <= maximum:
        raise ValueError(f"{where}: expected {minimum}–{maximum} items")
    return value


def safe_url(value):
    value = text(value, 'source URL', 4000)
    parsed = urlsplit(value)
    if parsed.scheme not in ('https', 'http') or not parsed.netloc or re.search(r'\s', value):
        raise ValueError('source URL: use a complete HTTP or HTTPS URL without spaces')
    return escape(value, quote=True)


def load_json(path):
    return json.loads(Path(path).read_text(encoding='utf-8'))


def save(path, content, overwrite=False):
    target = Path(path)
    target.parent.mkdir(parents=True, exist_ok=True)
    with target.open('w' if overwrite else 'x', encoding='utf-8') as stream:
        stream.write(content)
    return target.resolve()


def run_cli(description, render):
    parser = argparse.ArgumentParser(description=description)
    parser.add_argument('input', help='UTF-8 JSON input file')
    parser.add_argument('--output', required=True, help='Output file path')
    parser.add_argument('--overwrite', action='store_true', help='Replace the chosen output file')
    args = parser.parse_args()
    try:
        if Path(args.input).resolve() == Path(args.output).resolve():
            raise ValueError('input and output must be different files')
        result = render(load_json(args.input))
        print(save(args.output, result, args.overwrite))
    except (OSError, ValueError, RecursionError) as error:
        print(f'error: {error}', file=sys.stderr)
        raise SystemExit(2)
