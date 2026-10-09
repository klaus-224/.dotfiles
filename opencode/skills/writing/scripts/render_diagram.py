"""Render small flow or sequence diagrams as standalone, accessible SVG."""
import re
import textwrap
from html import escape as esc
from common import array, obj, run_cli, text


def label(value, x, y, width=24):
    lines = textwrap.wrap(value, width=width) or ['']
    start = y - (len(lines) - 1) * 9
    spans = ''.join(f'<tspan x="{x}" y="{start + i * 18}">{esc(line)}</tspan>'
                    for i, line in enumerate(lines))
    return f'<text x="{x}" y="{y}" text-anchor="middle">{spans}</text>'


def validate(data):
    obj(data, 'diagram', ['type', 'title', 'description', 'nodes', 'edges'])
    kind = data['type']
    if kind not in ('flow', 'sequence'):
        raise ValueError('diagram.type: use flow or sequence')
    text(data['title'], 'diagram.title', 160)
    text(data['description'], 'diagram.description')
    nodes = array(data['nodes'], 'diagram.nodes', 1, 16 if kind == 'flow' else 8)
    edges = array(data['edges'], 'diagram.edges', 0, 32)
    ids = set()
    for node in nodes:
        obj(node, 'node', ['id', 'label'])
        nid = text(node['id'], 'node.id', 64)
        if not re.fullmatch(r'[A-Za-z][A-Za-z0-9_-]*', nid) or nid in ids:
            raise ValueError(f'node.id: invalid or duplicate ID {nid!r}')
        ids.add(nid)
        text(node['label'], 'node.label', 100)
    for edge in edges:
        obj(edge, 'edge', ['from', 'to', 'label'])
        for endpoint in ('from', 'to'):
            text(edge[endpoint], f'edge.{endpoint}', 64)
            if edge[endpoint] not in ids:
                raise ValueError(f'edge.{endpoint}: unknown node {edge[endpoint]!r}')
        if edge['from'] == edge['to']:
            raise ValueError('self edges are unsupported; split the step into two nodes')
        text(edge['label'], 'edge.label', 60)
    return nodes, edges


def relationships(data):
    nodes, edges = validate(data)
    names = {n['id']: n['label'] for n in nodes}
    return [f"{names[e['from']]} → {names[e['to']]}: {e['label']}" for e in edges]


def render(data, prefix='diagram'):
    nodes, edges = validate(data)
    if not re.fullmatch(r'[A-Za-z][A-Za-z0-9_-]*', prefix):
        raise ValueError('invalid SVG prefix')
    shapes = []
    arrow = f'{prefix}-arrow'
    if data['type'] == 'flow':
        incoming = {n['id']: 0 for n in nodes}
        children = {n['id']: [] for n in nodes}
        rank = {n['id']: 0 for n in nodes}
        for edge in edges:
            incoming[edge['to']] += 1
            children[edge['from']].append(edge['to'])
        queue = [nid for nid in incoming if incoming[nid] == 0]
        for nid in queue:
            for child in children[nid]:
                rank[child] = max(rank[child], rank[nid] + 1)
                incoming[child] -= 1
                if incoming[child] == 0:
                    queue.append(child)
        if len(queue) != len(nodes):
            raise ValueError('flow contains a cycle; show one pass or author a custom SVG')
        levels = [[n for n in nodes if rank[n['id']] == r] for r in range(max(rank.values()) + 1)]
        width = max(520, max(map(len, levels)) * 260 + 40)
        height = len(levels) * 220 + 20
        positions = {}
        for r, level in enumerate(levels):
            for i, node in enumerate(level):
                x = width / 2 + (i - (len(level) - 1) / 2) * 260
                positions[node['id']] = (x, 75 + r * 220)
        for edge in edges:
            x1, y1 = positions[edge['from']]
            x2, y2 = positions[edge['to']]
            y1 += 50
            y2 -= 50
            mid = (y1 + y2) / 2
            shapes.append(f'<path d="M{x1},{y1} C{x1},{mid} {x2},{mid} {x2},{y2}" '
                          f'class="edge" marker-end="url(#{arrow})"/>')
            shapes.append(f'<g class="edge-label">{label(edge["label"], (x1+x2)/2, mid, 22)}</g>')
        for node in nodes:
            x, y = positions[node['id']]
            shapes.append(f'<rect x="{x-110}" y="{y-50}" width="220" height="100" rx="14"/>')
            shapes.append(label(node['label'], x, y + 4, 24))
    else:
        width = max(520, len(nodes) * 260 + 80)
        height = 150 + len(edges) * 100
        positions = {n['id']: 170 + i * 260 for i, n in enumerate(nodes)}
        for node in nodes:
            x = positions[node['id']]
            shapes.append(f'<path d="M{x},115 V{height-20}" class="lifeline"/>')
            shapes.append(f'<rect x="{x-110}" y="15" width="220" height="100" rx="14"/>')
            shapes.append(label(node['label'], x, 69))
        for i, edge in enumerate(edges):
            x1, x2 = positions[edge['from']], positions[edge['to']]
            y = 175 + i * 100
            shapes.append(f'<path d="M{x1},{y} H{x2}" class="edge" marker-end="url(#{arrow})"/>')
            shapes.append(f'<g class="edge-label">{label(str(i+1)+". "+edge["label"], (x1+x2)/2, y-29, 25)}</g>')
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width} {height}" style="min-width:{width}px"
 role="img" aria-labelledby="{prefix}-title {prefix}-desc">
<title id="{prefix}-title">{esc(data['title'])}</title>
<desc id="{prefix}-desc">{esc(data['description'])}</desc>
<defs><marker id="{arrow}" viewBox="0 0 10 10" refX="9" refY="5"
 markerWidth="8" markerHeight="8" orient="auto-start-reverse"><path d="M0 0 L10 5 L0 10z" fill="#347064"/></marker></defs>
<style>svg{{background:#f5f8f5}} rect{{fill:#fff;stroke:#387968;stroke-width:1.5}}
text{{font:15px system-ui,sans-serif;fill:#183d35}} .edge{{fill:none;stroke:#347064;stroke-width:2}}
.lifeline{{fill:none;stroke:#9aafa7;stroke-width:1.5;stroke-dasharray:5 6}}
.edge-label text{{font-size:13px;paint-order:stroke;stroke:#f5f8f5;stroke-width:5;stroke-linejoin:round}}</style>
{''.join(shapes)}</svg>'''


if __name__ == '__main__':
    run_cli('Render a JSON flow or sequence diagram to offline SVG.', render)
