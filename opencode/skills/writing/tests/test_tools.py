import copy
from html import unescape
import json
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import unittest
import xml.etree.ElementTree as ET

BASE = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(BASE/'scripts'))
from check_html import check
from highlight import LANGUAGES, highlight
from render_html import render
from render_diagram import render as svg


class ToolsTest(unittest.TestCase):
    def setUp(self):
        self.document = json.loads((BASE/'examples/explanation.json').read_text())
        self.diagram = json.loads((BASE/'examples/diagram.json').read_text())

    def test_complete_example_has_valid_references(self):
        self.assertEqual(check(render(self.document)), [])

    def test_plain_text_cannot_inject_markup(self):
        self.document['title'] = '</title><script>alert("title")</script>'
        self.document['summary'] = '<img src=x onerror=alert(1)>'
        self.document['sections'][0]['blocks'][0]['text'] = '</p><script>alert("body")</script>'
        result = render(self.document)
        self.assertNotIn('<script>alert', result)
        self.assertNotIn('<img src=x', result)
        self.assertIn('&lt;img', result)
        self.assertEqual(check(result), [])

    def test_executable_source_url_rejected(self):
        self.document['sources'][0]['url'] = 'javascript:alert(1)'
        with self.assertRaises(ValueError):
            render(self.document)

    def test_unknown_field_rejected(self):
        self.document['sectons'] = []
        with self.assertRaisesRegex(ValueError, 'unknown fields'):
            render(self.document)

    def test_source_index_must_exist(self):
        self.document['sections'][0]['blocks'][0]['cite'] = [3]
        with self.assertRaises(ValueError):
            render(self.document)

    def test_table_row_count_must_match(self):
        self.document['sections'][0]['blocks'] = [
            {'type':'table','caption':'Test','headers':['A','B'],'rows':[['Only one']]}
        ]
        with self.assertRaises(ValueError):
            render(self.document)

    def test_repeated_diagrams_have_unique_ids(self):
        block = self.document['sections'][0]['blocks'][1]
        self.document['sections'][0]['blocks'].append(copy.deepcopy(block))
        self.assertEqual(check(render(self.document)), [])

    def test_walkthrough_content_exists_without_javascript(self):
        result = render(self.document)
        for phrase in ('State the answer', 'Show the mechanism', 'Name the limit'):
            self.assertIn(f'<h4>{phrase}</h4>', result)
        self.assertNotIn('<li hidden', result)

    def test_svg_is_xml_and_escapes_labels(self):
        self.diagram['nodes'][0]['label'] = '<script>& "test"'
        result = svg(self.diagram)
        ET.fromstring(result)
        self.assertNotIn('<script>', result)

    def test_sequence_supports_return_messages(self):
        self.diagram['type'] = 'sequence'
        self.diagram['edges'].append({'from':'action','to':'answer','label':'Reply'})
        ET.fromstring(svg(self.diagram))

    def test_dangling_edge_rejected(self):
        self.diagram['edges'][0]['to'] = 'missing'
        with self.assertRaisesRegex(ValueError, 'unknown node'):
            svg(self.diagram)

    def test_duplicate_node_rejected(self):
        self.diagram['nodes'][1]['id'] = 'answer'
        with self.assertRaisesRegex(ValueError, 'duplicate'):
            svg(self.diagram)

    def test_cycle_rejected(self):
        self.diagram['edges'].append({'from':'action','to':'answer','label':'Repeat'})
        with self.assertRaisesRegex(ValueError, 'cycle'):
            svg(self.diagram)

    def test_self_edge_rejected(self):
        self.diagram['edges'][0]['to'] = 'answer'
        with self.assertRaisesRegex(ValueError, 'self edges'):
            svg(self.diagram)

    def test_checker_finds_broken_anchor(self):
        result = render(self.document).replace('href="#section-1"', 'href="#missing"')
        self.assertIn('Unresolved reference: missing', check(result))

    def test_svg_title_does_not_replace_document_title(self):
        result = render(self.document)
        start = result.index('<title>')
        end = result.index('</title>') + len('</title>')
        result = result[:start] + result[end:]
        self.assertIn('Missing title text', check(result))

    def test_checker_finds_external_asset(self):
        result = render(self.document).replace('</head>', '<script src="https://example.com/a.js"></script></head>')
        self.assertIn('script depends on a separate resource', check(result))

    def test_cli_runs_outside_skill_directory_and_preserves_output(self):
        with tempfile.TemporaryDirectory(prefix='writing test ') as folder:
            output = Path(folder)/'subfolder'/'result.html'
            command = [sys.executable, str(BASE/'scripts/render_html.py'),
                       str(BASE/'examples/explanation.json'), '--output', str(output)]
            result = subprocess.run(command, cwd=folder, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            original = output.read_bytes()
            result = subprocess.run(command, cwd=folder, capture_output=True, text=True)
            self.assertEqual(result.returncode, 2)
            self.assertEqual(original, output.read_bytes())
            result = subprocess.run(command+['--overwrite'], cwd=folder, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)

    def paragraph(self, value):
        self.document['sections'] = self.document['sections'][:1]
        self.document['sections'][0]['blocks'] = [{'type': 'p', 'text': value}]
        return render(self.document)

    def test_inline_markup_renders_and_escapes_content(self):
        result = self.paragraph('Use `a<b>` with **care <i>** and ==this== [docs](https://example.com/?a=1&b=2).')
        self.assertIn('<code class="inline">a&lt;b&gt;</code>', result)
        self.assertIn('<strong>care &lt;i&gt;</strong>', result)
        self.assertIn('<mark>this</mark>', result)
        self.assertIn('<a href="https://example.com/?a=1&amp;b=2">docs</a>', result)
        self.assertEqual(check(result), [])

    def test_inline_link_can_wrap_code_and_target_a_section(self):
        result = self.paragraph('See [`render.py:42`](file:///tmp/render.py) and [above](#section-1).')
        self.assertIn('<a href="file:///tmp/render.py"><code class="inline">render.py:42</code></a>', result)
        self.assertIn('<a href="#section-1">above</a>', result)
        self.assertEqual(check(result), [])

    def test_unsafe_inline_link_rejected(self):
        for url in ('javascript:alert', 'data:text/html,x', 'file:relative', '//example.com'):
            with self.subTest(url=url), self.assertRaisesRegex(ValueError, 'link'):
                self.paragraph(f'[x]({url})')

    def test_inline_markers_stay_literal_when_escaped_or_in_code(self):
        result = self.paragraph(r'Glob src/**/*.ts, `a **b**`, \*\*not bold\*\*, and a == b == c.')
        self.assertIn('src/**/*.ts', result)
        self.assertIn('<code class="inline">a **b**</code>', result)
        self.assertIn('**not bold**', result)
        self.assertIn('a == b == c', result)
        self.assertNotIn('<strong>', result)
        self.assertNotIn('<mark>', result)

    def test_code_span_inside_emphasis_is_kept_whole(self):
        result = self.paragraph('**run `a**b` first**')
        self.assertIn('<strong>run <code class="inline">a**b</code> first</strong>', result)

    def test_disclosure_summary_drops_links(self):
        self.document['sections'][0]['blocks'] = [
            {'type': 'details', 'summary': 'See [docs](https://example.com)', 'blocks': [{'type': 'p', 'text': 'x'}]}
        ]
        self.assertIn('<summary>See docs</summary>', render(self.document))

    def test_code_block_highlights_and_links_source(self):
        self.document['sections'][0]['blocks'] = [{
            'type': 'code', 'lang': 'py', 'file': 'app.py:3', 'url': 'https://example.com/app.py#L3',
            'text': 'def run(x):\n    return "<ok>"  # done',
        }]
        result = render(self.document)
        self.assertIn('<a href="https://example.com/app.py#L3"><code>app.py:3</code></a>', result)
        self.assertIn('<span class="code-lang">Python</span>', result)
        self.assertIn('<span class="t-kw">def</span> <span class="t-fn">run</span>', result)
        self.assertIn('<span class="t-str">&quot;&lt;ok&gt;&quot;</span>', result)
        self.assertIn('<span class="t-com"># done</span>', result)
        self.assertEqual(check(result), [])

    def test_code_block_field_errors(self):
        cases = [
            ({'lang': 'klingon'}, 'unknown language'),
            ({'url': 'https://example.com'}, 'also give file'),
            ({'file': 'a.py', 'url': 'javascript:x'}, 'code.url'),
        ]
        for extra, message in cases:
            with self.subTest(extra=extra):
                self.document['sections'][0]['blocks'] = [{'type': 'code', 'text': 'x', **extra}]
                with self.assertRaisesRegex(ValueError, message):
                    render(self.document)

    def test_plain_code_block_is_unchanged(self):
        self.document['sections'][0]['blocks'] = [{'type': 'code', 'text': 'a < b'}]
        self.assertIn('<pre tabindex="0" aria-label="Code example"><code>a &lt; b</code></pre>', render(self.document))

    def test_highlighter_never_loses_text(self):
        sample = ('#!/bin/sh\n# c "x"\nlet x = { a = 1; }; in `t` \'s\' "d\\"q" /* b */ -- s\n'
                  'select * from t; <a href="x">y</a> @dec f(1.5e3) x.y() $HOME --flag\n'
                  '+add\n-del\n@@ -1 +1 @@\nkey: [true, null] """doc""" [[x]] é & <')
        for name in LANGUAGES:
            with self.subTest(language=name):
                html = highlight(sample, name)
                self.assertEqual(unescape(re.sub(r'</?span[^>]*>', '', html)), sample)
                self.assertNotIn('<a', re.sub(r'&lt;a', '', html))

    def test_width_toggle_is_present_and_progressive(self):
        result = render(self.document)
        self.assertIn('data-width="narrow"', result)
        self.assertIn('data-width-toggle aria-pressed="false" hidden', result)

    def test_cli_rejects_input_output_collision(self):
        with tempfile.TemporaryDirectory() as folder:
            source = Path(folder)/'input.json'
            source.write_text(json.dumps(self.document))
            original = source.read_bytes()
            result = subprocess.run([sys.executable, str(BASE/'scripts/render_html.py'),
                                     str(source), '--output', str(source), '--overwrite'],
                                    capture_output=True, text=True)
            self.assertEqual(result.returncode, 2)
            self.assertEqual(original, source.read_bytes())


if __name__ == '__main__':
    unittest.main()
