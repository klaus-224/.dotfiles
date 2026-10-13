import copy
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
import xml.etree.ElementTree as ET

BASE = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(BASE/'scripts'))
from check_html import check
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
