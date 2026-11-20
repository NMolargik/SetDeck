// SetDeck 3.0 app icon ("Fan") as a layered Affinity document, rebuilt 2026-11-19 from AppIcon.icon/Assets (left.svg, right.svg, front.svg, glyph.svg).
// 1024 x 1024 canvas. Cards: 420 x 575 rounded rects (radius 75) at x 302, y 250; front is upright, left (orange) and right (blue) are rotated
// -16 / +16 degrees about (512, 905). The white dumbbell is five rounded rects centred on (512, 537.5). Gradient stops at 0 and 70% of the height.
// Layers: Background (Default) / Background (Dark) groups, Cards group (Left, Right, Front; Left and Right at 95%), Symbol group (Dumbbell parts).
// Run from a Desktop copy (Affinity can only read the Desktop); it saves SetDeck App Icon.af and AppIcon.png into DESK.
const { Document, NewDocumentOptions, FileExportOptions, FileExportArea } = require('/document.js');
const Nodes = require('/nodes.js');
const { Colour, Gradient } = require('/colours.js');
const { Rectangle, Transform, CurveBuilder, PolyCurve } = require('/geometry.js');
const { ShapeRectangle } = require('/shapes.js');
const { FillDescriptor, GradientFill, GradientFillType, BlendMode } = require('/fills.js');
const { DocumentCommand, AddChildNodesCommandBuilder } = require('/commands.js');
const { InsertionMode } = require('affinity:commands');
const { Selection } = require('/selections.js');
const { UnitType } = require('/units.js');
const DESK = '/Users/nickmolargik/Desktop/SetDeck Icon (Claude)';
// Rounded rect as absolute cubic points, optionally rotated about (px, py) by deg and translated by (tx, ty).
function rr(x, y, w, h, r, deg, px, py, tx, ty) {
  const K = 0.5522847498 * r, a = (deg || 0) * Math.PI / 180, c = Math.cos(a), s = Math.sin(a);
  const T = (X, Y) => { const dx = X - (px || 0), dy = Y - (py || 0); return [(px || 0) + dx * c - dy * s + (tx || 0), (py || 0) + dx * s + dy * c + (ty || 0)]; };
  const x1 = x + w, y1 = y + h;
  // start top edge left end, clockwise; every segment is a cubic (straight edges use control points on the line)
  const seg = [[x + r, y], [x1 - r, y], [x1 - r + K, y], [x1, y + r - K], [x1, y + r], [x1, y1 - r], [x1, y1 - r + K], [x1 - r + K, y1], [x1 - r, y1], [x + r, y1], [x + r - K, y1], [x, y1 - r + K], [x, y1 - r], [x, y + r], [x, y + r - K], [x + r - K, y], [x + r, y]];
  // build cubics: P0 then triples
  const P = seg.map(p => T(p[0], p[1])); const out = [].concat(P[0]);
  const lin = (p, q) => [p[0] + (q[0] - p[0]) / 3, p[1] + (q[1] - p[1]) / 3, p[0] + 2 * (q[0] - p[0]) / 3, p[1] + 2 * (q[1] - p[1]) / 3];
  // top edge, corner TR, right edge, corner BR, bottom edge, corner BL, left edge, corner TL
  out.push(...lin(P[0], P[1]), ...P[1]);
  out.push(P[2][0], P[2][1], P[3][0], P[3][1], P[4][0], P[4][1]);
  out.push(...lin(P[4], P[5]), ...P[5]);
  out.push(P[6][0], P[6][1], P[7][0], P[7][1], P[8][0], P[8][1]);
  out.push(...lin(P[8], P[9]), ...P[9]);
  out.push(P[10][0], P[10][1], P[11][0], P[11][1], P[12][0], P[12][1]);
  out.push(...lin(P[12], P[13]), ...P[13]);
  out.push(P[14][0], P[14][1], P[15][0], P[15][1], P[16][0], P[16][1]);
  return out;
}
const CARD = (deg) => rr(302, 250, 420, 575, 75, deg, 512, 905);
const GEOM = { Left: CARD(-16), Right: CARD(16), Front: CARD(0) };
const CARDCOL = { Left: '#F2844A', Right: '#4E9EEA', Front: '#4FC290' };
const DB = [[-150, -15, 300, 30, 15], [-122, -75, 52, 150, 22], [70, -75, 52, 150, 22], [-168, -50, 38, 100, 17], [130, -50, 38, 100, 17]];

const log = (...a) => console.log(a.join(' '));
const o = NewDocumentOptions.createDefault();
o.units = UnitType.Pixel; o.width = 1024; o.height = 1024; o.dpi = 72; o.createArtboard = true; o.isTransparentBackground = true;
const doc = Document.createFromOptions(o);
const spread = doc.spreads.first;
const kids = n => { const out = []; for (const c of n.children) out.push(c); return out; };
const sel = n => Selection.create(doc, n);
const run = cmd => doc.executeCommand(cmd);
const rgba = hex => { const h = hex.replace('#', ''); return Colour.createRGBA8({ r: parseInt(h.slice(0, 2), 16), g: parseInt(h.slice(2, 4), 16), b: parseInt(h.slice(4, 6), 16), alpha: 255 }); };
const solid = hex => FillDescriptor.createSolid(rgba(hex));
const name = (n, s) => run(DocumentCommand.createSetDescription(sel(n), s));
function addTo(target, def, label) {
  const b = AddChildNodesCommandBuilder.create(); b.addNode(def); b.setInsertionTarget(target); b.setInsertionMode(InsertionMode.Inside_AtBack);
  const cmd = b.createCommand(false); run(cmd);
  const n = cmd.newNodes[0]; if (label) name(n, label); return n;
}
function settle(n, x, y) { const b = n.spreadBaseBox; if (Math.abs(b.x - x) > 0.01 || Math.abs(b.y - y) > 0.01) run(DocumentCommand.createTransform(sel(n), Transform.createTranslate(x - b.x, y - b.y))); return n; }
function vGradient(x, y, w, h, top, bottom) {
  const g = Gradient.create([{ position: 0, colour: rgba(top) }, { position: 1, colour: rgba(bottom) }]);
  const xf = Transform.createTranslate(x + w / 2, y).multiply(Transform.createRotate(Math.PI / 2)).multiply(Transform.createScale(h, h));
  return FillDescriptor.create(GradientFill.create(g, GradientFillType.Linear), true, xf, BlendMode.Normal, false);
}
function group(target, label) { return addTo(target, Nodes.ContainerNodeDefinition.create(label), label); }
// pts = [x0,y0, c1x,c1y, c2x,c2y, x1,y1, ...] absolute canvas coordinates; every segment is a cubic.
function path(target, label, hex, pts) {
  const b = new CurveBuilder(); b.beginXY(pts[0], pts[1]);
  for (let i = 2; i + 5 < pts.length; i += 6) b.addBezierXY(pts[i], pts[i + 1], pts[i + 2], pts[i + 3], pts[i + 4], pts[i + 5]);
  b.close();
  const pc = PolyCurve.create(); pc.addCurve(b.createCurve());
  const n = addTo(target, Nodes.PolyCurveNodeDefinition.create(pc, solid(hex), null, null, null), label);
  // true bounding box of the cubics
  let mx = 1e9, my = 1e9;
  for (let i = 0; i + 7 < pts.length; i += 6) for (let t = 0; t <= 200; t++) { const u = t / 200, v = 1 - u;
    const f = k => v*v*v*pts[i+k] + 3*v*v*u*pts[i+k+2] + 3*v*u*u*pts[i+k+4] + u*u*u*pts[i+k+6];
    mx = Math.min(mx, f(0)); my = Math.min(my, f(1)); }
  const bb = n.spreadBaseBox; if (Math.abs(bb.x - mx) > 1 || Math.abs(bb.y - my) > 1) { log('settle', label, bb.x - mx, bb.y - my); settle(n, mx, my); }
  return n;
}
const ab = kids(spread)[0];
name(ab, 'SetDeck App Icon');
// Bottom to top (Inside_AtBack adds on top).
const bgL = group(ab, 'Background (Default)');
addTo(bgL, Nodes.ShapeNodeDefinition.create(ShapeRectangle.create(), new Rectangle(0, 0, 1024, 1024), vGradient(0, 0, 1024, 716.8, '#FFFFFF', '#E9E8EF'), null, null, null), 'Gradient');
const bgD = group(ab, 'Background (Dark)');
addTo(bgD, Nodes.ShapeNodeDefinition.create(ShapeRectangle.create(), new Rectangle(0, 0, 1024, 1024), vGradient(0, 0, 1024, 716.8, '#34303D', '#121015'), null, null, null), 'Gradient');
const cards = group(ab, 'Cards');
for (const k of ['Left', 'Right', 'Front']) { const n = path(cards, k, CARDCOL[k], GEOM[k]); if (k !== 'Front') doc.setOpacity(0.95, sel(n)); }
const syms = group(ab, 'Symbol');
const dumb = group(syms, 'Dumbbell');
DB.forEach((d, i) => path(dumb, 'Dumbbell part ' + (i + 1), '#FFFFFF', rr(d[0], d[1], d[2], d[3], d[4], 0, 0, 0, 512, 537.5)));
run(DocumentCommand.createSetVisibility(sel(bgD), false));
doc.saveAs(DESK + '/SetDeck App Icon.af');
const abs = []; for (const a of spread.artboards) abs.push(a);
doc.export(DESK + '/AppIcon.png', FileExportOptions.createWithPresetName('PNG'), FileExportArea.createForArtboard(abs[0]));
log('built; uuid', doc.sessionUuid);
