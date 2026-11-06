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
from render_diagram import render as svg, flow_layout


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

    def test_artifact_target_is_a_themed_fragment(self):
        result = render(self.document, target='artifact')
        self.assertEqual(check(result, 'artifact'), [])
        self.assertTrue(result.startswith('<title>'))
        for tag in ('doctype', 'html', 'head', 'body'):
            self.assertNotRegex(result.lower(), rf'<!?{tag}[\s>]')
        self.assertIn('@media (prefers-color-scheme: light)', result)
        self.assertIn(':root:not([data-theme="dark"])', result)
        self.assertIn('data-theme-toggle', result)
        self.assertIn('https://fonts.googleapis.com/css2?family=IBM+Plex', result)

    def test_artifact_light_tokens_match_page_light_tokens(self):
        css = (BASE/'templates/style.css').read_text()
        start = css.index(':root[data-theme="light"] {') + len(':root[data-theme="light"] {')
        light = css[start:css.index('}', start)]
        self.assertIn(':root:not([data-theme="dark"]) {' + light + '}', render(self.document, target='artifact'))

    def test_standalone_page_fails_artifact_check(self):
        issues = check(render(self.document), 'artifact')
        self.assertIn('Artifact must not contain a doctype; the host adds it', issues)
        self.assertIn("Artifact CSS must follow the viewer's system theme (prefers-color-scheme)", issues)

    def test_unknown_target_rejected(self):
        with self.assertRaisesRegex(ValueError, 'target'):
            render(self.document, target='pdf')

    def test_edge_that_skips_rows_avoids_other_nodes(self):
        nodes = [{'id': i, 'label': i} for i in ('top', 'left', 'right', 'middle', 'bottom')]
        edges = [{'from': 'top', 'to': 'left', 'label': 'a'}, {'from': 'top', 'to': 'right', 'label': 'b'},
                 {'from': 'right', 'to': 'middle', 'label': 'c'}, {'from': 'left', 'to': 'bottom', 'label': 'd'},
                 {'from': 'middle', 'to': 'bottom', 'label': 'e'}]
        _, _, boxes, paths = flow_layout(nodes, edges)
        for edge, path in zip(edges, paths):
            for (xa, ya), (xb, yb) in zip(path, path[1:]):
                self.assertTrue(xa == xb or ya == yb, 'edges use right angles')
                for nid, (x, top, h) in boxes.items():
                    if nid in (edge['from'], edge['to']):
                        continue
                    hit = (min(xa, xb) < x + 120 and max(xa, xb) > x - 120
                           and min(ya, yb) < top + h and max(ya, yb) > top)
                    self.assertFalse(hit, f"{edge['from']} -> {edge['to']} crosses {nid}")
        ET.fromstring(svg({'type': 'flow', 'title': 'T', 'description': 'D', 'nodes': nodes, 'edges': edges}))

    def test_sibling_edge_labels_sit_apart(self):
        self.diagram['nodes'].append({'id': 'other', 'label': 'Other'})
        self.diagram['edges'].append({'from': 'answer', 'to': 'other', 'label': 'Branch'})
        result = svg(self.diagram)
        labels = __import__('re').findall(r'<g class="edge-label"><text x="([0-9.]+)" y="[0-9.]+" text-anchor="(\w+)"', result)
        (x1, a1), (x2, a2) = labels[0], labels[2]
        self.assertEqual((a1, a2), ('end', 'start'))
        self.assertGreater(float(x2) - float(x1), 200)

    def test_key_node_and_mono_label(self):
        self.diagram['nodes'][0]['key'] = True
        self.diagram['nodes'][1]['label'] = 'Reads `data/<window>/summary.json`'
        result = svg(self.diagram)
        self.assertIn('<rect class="key"', result)
        self.assertIn('class="m">data/&lt;window&gt;/summary.json</tspan>', result)
        self.diagram['nodes'][0]['key'] = 'yes'
        with self.assertRaisesRegex(ValueError, 'node.key'):
            svg(self.diagram)

    def test_inline_code_and_tags(self):
        self.document['sections'][0]['blocks'][0]['text'] = 'Run `a <b>` then [[flaky]] or [[!broken]].'
        result = render(self.document)
        self.assertIn('Run <code>a &lt;b&gt;</code> then <span class="tag">flaky</span> or '
                      '<span class="tag warn">broken</span>.', result)
        self.assertEqual(check(result), [])

    def test_inline_code_in_table_cell_keeps_markup_intact(self):
        self.document['sections'][0]['blocks'] = [{'type': 'table', 'caption': 'Use `x`', 'headers': ['A'],
                                                   'rows': [['Run `tsc --noEmit` on a-b']]}]
        result = render(self.document)
        self.assertIn('Run <code>tsc --noEmit</code> on <span class="nobr">a-b</span>', result)
        self.assertIn('aria-label="Use x"', result)

    def test_title_markup_is_plain_in_document_title(self):
        self.document['title'] = 'How `pw-report` works'
        result = render(self.document)
        self.assertIn('<title>How pw-report works</title>', result)
        self.assertIn('<h1>How <code>pw-report</code> works</h1>', result)

    def test_note_block(self):
        self.document['sections'][0]['blocks'].append(
            {'type': 'note', 'label': 'Limit', 'blocks': [{'type': 'p', 'text': 'One `thing`.'}]})
        result = render(self.document)
        self.assertIn('<div class="note warn"><p class="note-label">Limit</p><p>One <code>thing</code>.</p></div>', result)
        self.document['sections'][0]['blocks'][-1]['tone'] = 'loud'
        with self.assertRaisesRegex(ValueError, 'note.tone'):
            render(self.document)

    def test_cli_artifact_target(self):
        with tempfile.TemporaryDirectory() as folder:
            output = Path(folder)/'artifact.html'
            result = subprocess.run([sys.executable, str(BASE/'scripts/render_html.py'),
                                     str(BASE/'examples/explanation.json'), '--output', str(output),
                                     '--target', 'artifact'], capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            result = subprocess.run([sys.executable, str(BASE/'scripts/check_html.py'),
                                     '--target', 'artifact', str(output)], capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)


if __name__ == '__main__':
    unittest.main()
