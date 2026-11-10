"""Small offline syntax highlighter for code blocks. Python standard library only.

Each language is an ordered list of (class, pattern) rules. At each position the
first rule that matches wins. A class of None leaves the matched text unstyled;
it only stops later rules from matching inside a word. This is a readability aid,
not a parser: unusual syntax may be coloured imperfectly, but text is never lost.
"""
import re
from html import escape as esc


def words(names, flags=''):
    group = '|'.join(names.split())
    return rf'(?{flags}:\b(?:{group})\b)' if flags else rf'\b(?:{group})\b'


DQ = r'"(?:[^"\\\n]|\\.)*"'
SQ = r"'(?:[^'\\\n]|\\.)*'"
BT = r'`(?:[^`\\]|\\.)*`'
NUM = r'\b(?:0[xXbBoO][0-9a-fA-F_]+|\d[\d_]*(?:\.\d[\d_]*)?(?:[eE][+-]?\d+)?)\b'
HASH = r'#[^\n]*'
SLASH = r'//[^\n]*'
BLOCK = r'/\*[\s\S]*?\*/'
PROP_CALL = r'(?<=\.)[A-Za-z_]\w*(?=\s*\()'
PROP = r'(?<=\.)[A-Za-z_]\w*'
CALL = r'\b[A-Za-z_]\w*(?=\s*\()'
IDENT = r'[A-Za-z_]\w*'


def c_like(keywords, literals, strings=(DQ, SQ), extra=()):
    return [('com', SLASH), ('com', BLOCK), *[('str', s) for s in strings], *extra,
            ('fn', PROP_CALL), (None, PROP), ('kw', words(keywords)),
            ('lit', words(literals)), ('num', NUM), ('fn', CALL), (None, IDENT)]


JS_KEYWORDS = ('async await break case catch class const continue default delete do else '
               'export extends finally for from function if import in instanceof let new '
               'of return static super switch throw try typeof var void while yield')
TS_KEYWORDS = JS_KEYWORDS + ' as declare enum implements interface keyof namespace private protected public readonly satisfies type'
JS_LITERALS = 'true false null undefined NaN Infinity this'

LANGUAGES = {
    'python': [
        ('com', HASH),
        ('str', r'(?:\b[rRbBfFuU]{1,2})?(?:"""[\s\S]*?"""|\'\'\'[\s\S]*?\'\'\')'),
        ('str', rf'(?:\b[rRbBfFuU]{{1,2}})?(?:{DQ}|{SQ})'),
        ('dec', r'(?m:^[ \t]*@[\w.]+)'),
        ('fn', PROP_CALL), (None, PROP),
        ('kw', words('and as assert async await break class continue def del elif else except '
                     'finally for from global if import in is lambda match case nonlocal not or '
                     'pass raise return try while with yield')),
        ('lit', words('True False None self cls')), ('num', NUM), ('fn', CALL), (None, IDENT),
    ],
    'javascript': c_like(JS_KEYWORDS, JS_LITERALS, (DQ, SQ, BT)),
    'typescript': c_like(TS_KEYWORDS, JS_LITERALS, (DQ, SQ, BT)),
    'go': c_like('break case chan const continue default defer else fallthrough for func go goto '
                 'if import interface map package range return select struct switch type var',
                 'true false nil iota', (DQ, BT, r"'(?:[^'\\\n]|\\.)+'")),
    'rust': c_like('as async await break const continue crate dyn else enum extern fn for if impl '
                   'in let loop match mod move mut pub ref return static struct trait type unsafe '
                   'use where while', 'true false None Some Ok Err self Self',
                   (DQ, r"'(?:[^'\\\n]|\\.)'"), (('fn', r'\b[A-Za-z_]\w*!'),)),
    'json': [
        ('com', SLASH), ('com', BLOCK), ('key', DQ + r'(?=\s*:)'), ('str', DQ),
        ('lit', words('true false null')), ('num', r'-?' + NUM),
    ],
    'shell': [
        ('com', r'(?<!\S)#[^\n]*'), ('str', DQ), ('str', r"'[^']*'"),
        ('var', r'\$(?:\{[^}\n]*\}|[A-Za-z_]\w*|[0-9@#?$!*-])'),
        ('kw', words('if then else elif fi for while until do done case esac in function '
                     'return export local unset source')),
        ('flag', r'(?<![\w-])--?[A-Za-z][\w-]*'),
        # The first word of a command, unless it is an assignment such as out=…
        ('fn', r'(?m:(?:^|(?<=[|;&(]))[ \t]*(?![\w./-]*=)[A-Za-z_./~][\w./~-]*)'),
        (None, r'[\w./~-]+'),
    ],
    'nix': [
        ('com', HASH), ('com', BLOCK), ('str', DQ), ('str', r"''[\s\S]*?''"),
        ('kw', words('let in with rec inherit if then else assert import or')),
        ('lit', words('true false null')), ('num', NUM),
        ('key', r"\b[A-Za-z_][\w'-]*(?=\s*=(?!=))"), (None, r"[A-Za-z_][\w'-]*"),
    ],
    'lua': [
        ('com', r'--\[\[[\s\S]*?\]\]'), ('com', r'--[^\n]*'),
        ('str', DQ), ('str', SQ), ('str', r'\[\[[\s\S]*?\]\]'),
        ('fn', r'(?<=[.:])[A-Za-z_]\w*(?=\s*[({"\'])'), (None, r'(?<=[.:])[A-Za-z_]\w*'),
        ('kw', words('and break do else elseif end for function goto if in local not or '
                     'repeat return then until while')),
        ('lit', words('true false nil self')), ('num', NUM), ('fn', CALL), (None, IDENT),
    ],
    'yaml': [
        ('com', r'(?<!\S)#[^\n]*'),
        ('key', r'(?m:^[ \t]*(?:- )?[\w.\-/"\']+(?=[ \t]*:(?:\s|$)))'),
        ('str', DQ), ('str', SQ), ('lit', words('true false null yes no on off')),
        ('num', NUM), (None, r'[\w.-]+'),
    ],
    'toml': [
        ('com', HASH), ('kw', r'(?m:^[ \t]*\[\[?[^\]\n]+\]\]?)'),
        ('key', r'(?m:^[ \t]*[\w.\-"]+(?=[ \t]*=))'),
        ('str', r'"""[\s\S]*?"""'), ('str', DQ), ('str', r"'[^'\n]*'"),
        ('lit', words('true false')), ('num', NUM), (None, r'[\w.-]+'),
    ],
    'sql': [
        ('com', r'--[^\n]*'), ('com', BLOCK), ('str', SQ), ('key', DQ),
        ('kw', words('select from where and or not in is as join left right inner outer full '
                     'on group by order having limit offset insert into values update set '
                     'delete create table view index alter drop with distinct union all case '
                     'when then else end exists between like returning primary key references', 'i')),
        ('lit', words('null true false', 'i')), ('num', NUM), ('fn', CALL), (None, IDENT),
    ],
    'css': [
        ('com', BLOCK), ('str', DQ), ('str', SQ), ('kw', r'@[\w-]+|!important'),
        ('key', r'--?[A-Za-z][\w-]*(?=\s*:[^{\n]*;)|\b[A-Za-z][\w-]*(?=\s*:[^{\n]*;)'),
        ('num', r'#[0-9a-fA-F]{3,8}\b|(?<![\w-])-?\d+(?:\.\d+)?(?:%|[a-z]+)?'),
        ('fn', r'\b[A-Za-z][\w-]*(?=\()'), (None, r'[\w-]+'),
    ],
    'html': [
        ('com', r'<!--[\s\S]*?-->'), ('kw', r'</?[A-Za-z][\w:-]*|/?>'),
        ('key', r'\b[\w:-]+(?==)'), ('str', DQ), ('str', SQ),
    ],
    'diff': [
        ('com', r'(?m:^(?:diff |index |\+\+\+ |--- )[^\n]*)'), ('hunk', r'(?m:^@@[^\n]*)'),
        ('add', r'(?m:^\+[^\n]*)'), ('del', r'(?m:^-[^\n]*)'),
    ],
}

ALIASES = {
    'py': 'python', 'python3': 'python',
    'js': 'javascript', 'jsx': 'javascript', 'mjs': 'javascript', 'cjs': 'javascript',
    'ts': 'typescript', 'tsx': 'typescript',
    'golang': 'go', 'rs': 'rust', 'jsonc': 'json',
    'sh': 'shell', 'bash': 'shell', 'zsh': 'shell', 'console': 'shell',
    'yml': 'yaml', 'xml': 'html', 'svg': 'html', 'patch': 'diff',
}
PLAIN = {'text', 'plain', 'none'}
NAMES = {
    'python': 'Python', 'javascript': 'JavaScript', 'typescript': 'TypeScript', 'go': 'Go',
    'rust': 'Rust', 'json': 'JSON', 'shell': 'Shell', 'nix': 'Nix', 'lua': 'Lua',
    'yaml': 'YAML', 'toml': 'TOML', 'sql': 'SQL', 'css': 'CSS', 'html': 'HTML', 'diff': 'Diff',
}
_COMPILED = {}


def language(name):
    """Return the canonical language name, or None for plain text."""
    if not isinstance(name, str):
        raise ValueError('code.lang: expected a language name')
    key = name.strip().lower()
    if key in PLAIN:
        return None
    key = ALIASES.get(key, key)
    if key not in LANGUAGES:
        known = ', '.join(sorted(set(LANGUAGES) | set(ALIASES) | PLAIN))
        raise ValueError(f'code.lang: unknown language {name!r}; use one of {known}')
    return key


def display_name(name):
    return NAMES[name]


def highlight(code, name):
    """Return escaped HTML for code, with token spans for a known language."""
    if name is None:
        return esc(code)
    if name not in _COMPILED:
        rules = LANGUAGES[name]
        pattern = '|'.join(f'(?P<t{i}>{rule})' for i, (_, rule) in enumerate(rules))
        _COMPILED[name] = (re.compile(pattern), [cls for cls, _ in rules])
    pattern, classes = _COMPILED[name]
    out, position = [], 0
    for match in pattern.finditer(code):
        if match.end() == match.start():
            continue
        out.append(esc(code[position:match.start()]))
        cls = classes[int(match.lastgroup[1:])]
        token = esc(match.group())
        out.append(f'<span class="t-{cls}">{token}</span>' if cls else token)
        position = match.end()
    out.append(esc(code[position:]))
    return ''.join(out)
