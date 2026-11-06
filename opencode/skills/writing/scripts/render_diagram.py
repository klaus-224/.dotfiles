"""Render small flow or sequence diagrams as standalone, accessible SVG."""
import re
import textwrap
from html import escape as esc
from common import array, obj, run_cli, text


def label(value, x, y, width=24, anchor='middle'):
    lines = textwrap.wrap(value, width=width) or ['']
    start = y - (len(lines) - 1) * 9
    spans = ''.join(f'<tspan x="{x}" y="{start + i * 18}">{esc(line)}</tspan>'
                    for i, line in enumerate(lines))
    return f'<text x="{x}" y="{y}" text-anchor="{anchor}">{spans}</text>'


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
        obj(node, 'node', ['id', 'label'], ['key'] if kind == 'flow' else [])
        if not isinstance(node.get('key', False), bool):
            raise ValueError('node.key: use true or false')
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
    return [f"{names[e['from']]} → {names[e['to']]}: {e['label']}".replace('`', '') for e in edges]


NODE_W, COL_W, GAP, LINE, MARGIN = 240, 290, 104, 18, 120


def node_lines(value):
    """Wrap a node label into (text, is_mono) lines. `Backtick` parts get their own mono lines
    and wrap after slashes, so paths stay readable."""
    lines = []
    for i, part in enumerate(value.split('`')):
        part = part.strip()
        if not part:
            continue
        if i % 2:
            row = ''
            for token in re.findall(r'[^/]*/|[^/]+', part):
                if row and len(row) + len(token) > 28:
                    lines.append((row, True))
                    row = ''
                row += token
            lines.append((row, True))
        else:
            lines += [(line, False) for line in textwrap.wrap(part, width=28)]
    return lines or [('', False)]


def flow_layout(nodes, edges):
    """Rank nodes top to bottom and route edges at right angles.

    An edge that skips rows gets an empty lane in each row it passes, so it never runs
    through another node's box. Returns (width, height, boxes, routes): boxes maps node ID
    to (center x, top y, height); each route is a list of points from the source port to
    the target port."""
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
    levels = [[n['id'] for n in nodes if rank[n['id']] == r] for r in range(max(rank.values()) + 1)]
    heights = {n['id']: max(56, 22 + LINE * len(node_lines(n['label']))) for n in nodes}
    parents = {n['id']: [] for n in nodes}
    chains = []
    for i, edge in enumerate(edges):
        a, b = edge['from'], edge['to']
        chain = [a]
        for r in range(rank[a] + 1, rank[b]):
            lane = f' lane{i}-{r}'  # the space keeps it apart from valid node IDs
            levels[r].append(lane)
            parents[lane] = [chain[-1]]
            chain.append(lane)
        parents[b].append(chain[-1])
        chain.append(b)
        chains.append(chain)
    cols = max(map(len, levels))
    width = cols * COL_W + 2 * MARGIN
    row_h = [max(heights.get(nid, 56) for nid in level) for level in levels]
    tops = [20 + sum(row_h[:r]) + r * GAP for r in range(len(levels))]
    height = tops[-1] + row_h[-1] + 20
    boxes = {}
    for r, level in enumerate(levels):
        if r and any(nid.startswith(' ') for nid in level):
            # Rows with lanes are ordered by where their parents sit, so lanes stay beside
            # the column they come from. Ties keep the input order.
            level.sort(key=lambda nid: sum(boxes[q][0] for q in parents[nid]) / max(1, len(parents[nid])))
        for i, nid in enumerate(level):
            x = width / 2 + (i - (len(level) - 1) / 2) * COL_W
            boxes[nid] = (x, tops[r], heights.get(nid, row_h[r]))

    # Ports: edges leaving (or entering) one box are spread along its bottom (or top) edge,
    # ordered by where they go, so they do not share a line.
    def ports(ends):
        offsets = {}
        for nid, items in ends.items():
            items.sort(key=lambda item: item[1])
            step = min(48, (NODE_W - 40) / max(1, len(items)))
            for k, (key, _) in enumerate(items):
                offsets[key] = (k - (len(items) - 1) / 2) * step
        return offsets
    outs, ins = {}, {}
    for i, chain in enumerate(chains):
        outs.setdefault(chain[0], []).append((i, boxes[chain[1]][0]))
        ins.setdefault(chain[-1], []).append((i, boxes[chain[-2]][0]))
    out_port, in_port = ports(outs), ports(ins)

    routes = []
    for i, chain in enumerate(chains):
        x, top, h = boxes[chain[0]]
        points = [(x + out_port[i], top + h)]
        for lane in chain[1:-1]:
            x, top, h = boxes[lane]
            points += [(x, top), (x, top + row_h[levels_index(levels, lane)])]
        x, top, h = boxes[chain[-1]]
        points.append((x + in_port[i], top))
        routes.append(points)

    # Each gap between rows gets horizontal tracks; segments whose x ranges overlap go on
    # different tracks, so no two horizontal lines run on top of each other.
    bottoms = [tops[r] + row_h[r] for r in range(len(levels))]
    gaps = {}
    for i, points in enumerate(routes):
        for j in range(0, len(points) - 1, 2):
            (xa, ya), (xb, yb) = points[j], points[j + 1]
            if xa != xb:
                gap_top = min(b for b in bottoms if b >= ya - 0.5)
                gaps.setdefault(gap_top, []).append((min(xa, xb), max(xa, xb), i, j))
    elbow = {}
    for gap_top, segments in gaps.items():
        tracks = []
        for lo, hi, i, j in sorted(segments):
            for k, track in enumerate(tracks):
                if all(hi + 12 < a or lo - 12 > b for a, b in track):
                    track.append((lo, hi))
                    break
            else:
                k = len(tracks)
                tracks.append([(lo, hi)])
            elbow[(i, j)] = k
        for lo, hi, i, j in segments:
            elbow[(i, j)] = gap_top + GAP * (elbow[(i, j)] + 1) / (len(tracks) + 1)
    paths = []
    for i, points in enumerate(routes):
        full = [points[0]]
        for j in range(0, len(points) - 1, 2):
            (xa, ya), (xb, yb) = points[j], points[j + 1]
            if xa != xb:
                ym = elbow[(i, j)]
                full += [(xa, ym), (xb, ym)]
            full.append((xb, yb))
            if j + 2 < len(points):
                full.append(points[j + 2])
        paths.append(full)
    return width, height, {n['id']: boxes[n['id']] for n in nodes}, paths


def levels_index(levels, nid):
    return next(r for r, level in enumerate(levels) if nid in level)


def label_spot(path, from_fanout, source_x, target_x):
    """Where an edge label goes: beside the last vertical run when its source fans out,
    else beside the first. A run at an offset port puts its label on the outer side;
    a centered run puts it on the side away from the edge's bend."""
    runs = [(a, b) for a, b in zip(path, path[1:]) if a[0] == b[0] and b[1] - a[1] >= 24]
    if not runs:
        runs = [(path[0], path[1])]
    use_last = from_fanout and len(runs) > 0
    (xa, ya), (xb, yb) = runs[-1] if use_last else runs[0]
    center = target_x if use_last and runs[-1][1] == path[-1] else source_x if runs[0][0] == path[0] else xa
    if abs(xa - center) > 1:
        left = xa < center
    else:
        other = path[0][0] if use_last else path[-1][0]
        left = other > xa
    return (xa - 8, 'end') if left else (xa + 8, 'start'), (ya + yb) / 2


def render(data, prefix='diagram'):
    nodes, edges = validate(data)
    if not re.fullmatch(r'[A-Za-z][A-Za-z0-9_-]*', prefix):
        raise ValueError('invalid SVG prefix')
    shapes = []
    arrow = f'{prefix}-arrow'
    if data['type'] == 'flow':
        width, height, boxes, paths = flow_layout(nodes, edges)
        fanout = {}
        for edge in edges:
            fanout[edge['from']] = fanout.get(edge['from'], 0) + 1
        for edge, path in zip(edges, paths):
            d = 'M' + ' L'.join(f'{x:g},{y:g}' for x, y in path)
            shapes.append(f'<path d="{d}" class="edge" marker-end="url(#{arrow})"/>')
        for edge, path in zip(edges, paths):
            (x, anchor), y = label_spot(path, fanout[edge['from']] > 1,
                                        boxes[edge['from']][0], boxes[edge['to']][0])
            shapes.append(f'<g class="edge-label">{label(edge["label"], x, y, 22, anchor)}</g>')
        for node in nodes:
            x, top, h = boxes[node['id']]
            key = ' class="key"' if node.get('key') else ''
            shapes.append(f'<rect{key} x="{x-NODE_W/2:g}" y="{top:g}" width="{NODE_W}" height="{h}" rx="6"/>')
            lines = node_lines(node['label'])
            first = top + h / 2 - (len(lines) - 1) * LINE / 2 + 5
            spans = ''.join(f'<tspan x="{x:g}" y="{first + k * LINE:g}"{" class=\"m\"" if mono else ""}>{esc(t)}</tspan>'
                            for k, (t, mono) in enumerate(lines))
            shapes.append(f'<text x="{x:g}" y="{first:g}" text-anchor="middle">{spans}</text>')
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
 markerWidth="8" markerHeight="8" orient="auto-start-reverse"><path d="M0 0 L10 5 L0 10z" class="arrowhead"/></marker></defs>
<style>svg{{background:var(--diagram-bg,#f7f7f9)}} rect{{fill:var(--diagram-node,#fff);stroke:var(--diagram-stroke,#4a6f8c);stroke-width:1.3}}
rect.key{{fill:var(--diagram-key,#ececf0);stroke:var(--diagram-edge,#3e6584)}}
text{{font:14px var(--font-body,system-ui),sans-serif;fill:var(--diagram-text,#252530)}} .m{{font:13px var(--font-mono,ui-monospace),monospace}}
.edge{{fill:none;stroke:var(--diagram-edge,#3e6584);stroke-width:1.6}}
.arrowhead{{fill:var(--diagram-edge,#3e6584)}}
.lifeline{{fill:none;stroke:var(--diagram-lifeline,#a3a3b5);stroke-width:1.5;stroke-dasharray:5 6}}
.edge-label text{{font-size:12.5px;fill:var(--diagram-label,#4f4f63);paint-order:stroke;stroke:var(--diagram-bg,#f7f7f9);stroke-width:5;stroke-linejoin:round}}</style>
{''.join(shapes)}</svg>'''


if __name__ == '__main__':
    run_cli('Render a JSON flow or sequence diagram to offline SVG.', render)
