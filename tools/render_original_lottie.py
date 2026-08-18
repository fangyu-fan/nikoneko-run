#!/usr/bin/env python3
import json, math, os, sys, html

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LOTTIE_DIR = os.path.join(ROOT, 'nikoneko_run', 'Characters', 'Lottie')
NAMES = ['Mushrooms', 'Potato', 'Avocado', 'Donut', 'Pothos', 'Taco']

def lerp(a, b, p):
    if isinstance(a, (int, float)) and isinstance(b, (int, float)):
        return a + (b - a) * p
    if isinstance(a, list) and isinstance(b, list):
        return [lerp(x, y, p) for x, y in zip(a, b)]
    return a

def value(prop, frame):
    if prop is None:
        return 0
    if not isinstance(prop, dict) or 'a' not in prop:
        return prop
    k = prop.get('k')
    if prop.get('a') != 1 or not isinstance(k, list):
        return k
    if not k:
        return 0
    prev = k[0]
    for nxt in k[1:]:
        if frame < nxt.get('t', 0):
            break
        prev = nxt
    t0 = prev.get('t', 0)
    if 'e' not in prev:
        return prev.get('s', 0)
    t1 = next((q.get('t', t0 + 1) for q in k if q.get('t', 0) > t0), t0 + 1)
    p = 0 if t1 == t0 else max(0, min(1, (frame - t0) / (t1 - t0)))
    return lerp(prev.get('s', 0), prev.get('e', prev.get('s', 0)), p)

def fmt(v):
    return f'{float(v):.4f}'.rstrip('0').rstrip('.')

def color(c, opacity=1):
    c = c or [0, 0, 0, 1]
    if len(c) < 3: c = [0, 0, 0, 1]
    return f'rgb({round(c[0]*255)},{round(c[1]*255)},{round(c[2]*255)})', fmt((c[3] if len(c) > 3 else 1) * opacity)

def path_d(s):
    v, i, o = s.get('v', []), s.get('i', []), s.get('o', [])
    if not v: return ''
    out = [f'M {fmt(v[0][0])} {fmt(v[0][1])}']
    n = len(v)
    for j in range(1, n + 1):
        k = j % n
        prev = j - 1
        cp1 = [v[prev][0] + o[prev][0], v[prev][1] + o[prev][1]]
        cp2 = [v[k][0] + i[k][0], v[k][1] + i[k][1]]
        out.append(f'C {fmt(cp1[0])} {fmt(cp1[1])} {fmt(cp2[0])} {fmt(cp2[1])} {fmt(v[k][0])} {fmt(v[k][1])}')
    if s.get('c', False): out.append('Z')
    return ' '.join(out)

def path_shape(prop, frame):
    x = value(prop, frame)
    if isinstance(x, list): return x[0] if x else {}
    return x or {}

def transform(prop, frame):
    p = value(prop.get('p'), frame) or [0, 0]
    a = value(prop.get('a'), frame) or [0, 0]
    s = value(prop.get('s'), frame) or [100, 100]
    r = value(prop.get('r', prop.get('rz')), frame) or 0
    o = value(prop.get('o'), frame)
    if isinstance(r, list): r = r[0] if r else 0
    if isinstance(o, list): o = o[0] if o else 100
    return f'translate({fmt(p[0])} {fmt(p[1])}) rotate({fmt(r)}) translate({fmt(-a[0])} {fmt(-a[1])}) scale({fmt(s[0]/100)} {fmt(s[1]/100)})', (float(o if o is not None else 100) / 100)

def style_for(items, frame):
    fill = stroke = None
    sw = 1
    fill_op = stroke_op = 1
    for x in items:
        if x.get('ty') == 'fl':
            fill, fill_op = color(value(x.get('c'), frame), float(value(x.get('o'), frame) or 100) / 100)
        elif x.get('ty') == 'st':
            stroke, stroke_op = color(value(x.get('c'), frame), float(value(x.get('o'), frame) or 100) / 100)
            sw = float(value(x.get('w'), frame) or 1)
    return fill, fill_op, stroke, stroke_op, sw

def render_items(items, frame, inherited=None):
    inherited = inherited or (None, 1, None, 1, 1)
    fill, fill_op, stroke, stroke_op, sw = style_for(items, frame)
    if fill is None: fill, fill_op = inherited[0], inherited[1]
    if stroke is None: stroke, stroke_op, sw = inherited[2], inherited[3], inherited[4]
    transform_item = next((x for x in items if x.get('ty') == 'tr'), None)
    tr, op = transform(transform_item, frame) if transform_item else ('', 1)
    parts = []
    for x in items:
        ty = x.get('ty')
        if ty in ('fl', 'st', 'tr', 'gf', 'gs', 'mm', 'rp'): continue
        if ty == 'gr':
            parts.append(render_group(x, frame, (fill, fill_op, stroke, stroke_op, sw)))
        elif ty == 'sh':
            s = path_shape(x.get('ks'), frame); d = path_d(s)
            if d: parts.append(f'<path d="{d}"/>')
        elif ty == 'el':
            size = value(x.get('s'), frame) or [0, 0]; pos = value(x.get('p'), frame) or [0, 0]
            parts.append(f'<ellipse cx="{fmt(pos[0])}" cy="{fmt(pos[1])}" rx="{fmt(size[0]/2)}" ry="{fmt(size[1]/2)}"/>')
    if not parts: return ''
    attrs = []
    if tr: attrs.append(f'transform="{tr}"')
    if op != 1: attrs.append(f'opacity="{fmt(op)}"')
    attrs.append(f'fill="{fill or "none"}" fill-opacity="{fmt(fill_op)}"')
    attrs.append(f'stroke="{stroke or "none"}" stroke-opacity="{fmt(stroke_op)}" stroke-width="{fmt(sw)}" stroke-linecap="round" stroke-linejoin="round"')
    return '<g ' + ' '.join(attrs) + '>' + ''.join(parts) + '</g>'

def render_group(group, frame, inherited):
    return render_items(group.get('it', []), frame, inherited)

def layer_transform(layer, frame):
    return transform(layer.get('ks', {}), frame)

def layer_chain(layer, by_id, frame):
    chain = []
    seen = set()
    cur = layer
    while cur and cur.get('ind') not in seen:
        seen.add(cur.get('ind')); chain.append(cur); cur = by_id.get(cur.get('parent'))
    tr = []
    op = 1
    for l in reversed(chain):
        t, o = layer_transform(l, frame); tr.append(t); op *= o
    return ' '.join(tr), op

def render_anim(d, frame):
    by_id = {l.get('ind'): l for l in d.get('layers', [])}
    parts = []
    # Lottie layer order is back-to-front in the JSON.
    for layer in reversed(d.get('layers', [])):
        if layer.get('ty') != 4: continue
        ip, opf, st = layer.get('ip', 0), layer.get('op', 10**9), layer.get('st', 0)
        if frame < ip or frame >= opf: continue
        local = frame - st
        t, op = layer_chain(layer, by_id, local)
        body = render_items(layer.get('shapes', []), local)
        if body:
            parts.append(f'<g transform="{t}" opacity="{fmt(op)}">{body}</g>')
    return ''.join(parts)

def main(out_dir):
    os.makedirs(out_dir, exist_ok=True)
    docs = [json.load(open(os.path.join(LOTTIE_DIR, n + '.json'))) for n in NAMES]
    fps, duration = 30, 4
    for i in range(fps * duration):
        cells = []
        for idx, d in enumerate(docs):
            frame = (i / fps * d.get('fr', 30)) % d.get('op', 1)
            x = 32 + idx * 169
            # The source Lottie canvases have generous padding; enlarge while keeping the feet on one baseline.
            zoom = 1.75
            tx, ty = d['w'] * (1 - zoom) / 2, d['h'] * (1 - zoom)
            cells.append(f'<svg x="{x}" y="320" width="169" height="430" viewBox="0 0 {d["w"]} {d["h"]}" preserveAspectRatio="xMidYMax meet"><g transform="translate({fmt(tx)} {fmt(ty)}) scale({fmt(zoom)})">{render_anim(d, frame)}</g></svg>')
        svg = '<svg xmlns="http://www.w3.org/2000/svg" width="1080" height="1080" viewBox="0 0 1080 1080"><rect width="1080" height="1080" fill="white"/>' + ''.join(cells) + '<rect x="42" y="748" width="996" height="3" rx="2" fill="#eeeeef"/></svg>'
        open(os.path.join(out_dir, f'frame_{i:04d}.svg'), 'w').write(svg)
    print(f'Wrote {fps*duration} original-Lottie SVG frames to {out_dir}')

if __name__ == '__main__': main(sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, 'build', 'lottie_svg_frames'))
