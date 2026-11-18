// SetDeck 3.0 app icon (concept B) as a layered Affinity document. Geometry comes from B-flat.icon
// (Assets/Card1 2.svg, Card2.svg, Card3.svg, Symbols.svg: every path transform baked in, centred on a 1024 x 1024 canvas,
// Symbols translated 11 pt right). Gradient stops at 0 and 70% of the height. Cards are #EBEBEB at 95% opacity.
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
const GEOM={
  "Card 1":[[712.007, 134.217, 712.007, 134.217, 857.198, 763.11, 857.198, 763.11, 864.199, 793.436, 845.263, 823.741, 814.936, 830.742, 814.936, 830.742, 379.279, 931.322, 379.279, 931.322, 348.953, 938.323, 318.648, 919.387, 311.646, 889.061, 311.646, 889.061, 166.455, 260.167, 166.455, 260.167, 159.454, 229.841, 178.39, 199.536, 208.717, 192.535, 208.717, 192.535, 644.374, 91.955, 644.374, 91.955, 674.7, 84.954, 705.005, 103.89, 712.007, 134.217]],
  "Card 2":[[807.398, 203.45, 807.398, 203.45, 775.279, 848.086, 775.279, 848.086, 773.73, 879.172, 747.236, 903.151, 716.15, 901.602, 716.15, 901.602, 269.587, 879.352, 269.587, 879.352, 238.502, 877.803, 214.522, 851.309, 216.071, 820.223, 216.071, 820.223, 248.19, 175.587, 248.19, 175.587, 249.739, 144.502, 276.234, 120.522, 307.319, 122.071, 307.319, 122.071, 753.882, 144.321, 753.882, 144.321, 784.968, 145.87, 808.947, 172.365, 807.398, 203.45]],
  "Card 3":[[865.584, 272.494, 865.584, 272.494, 698.183, 895.843, 698.183, 895.843, 690.111, 925.902, 659.154, 943.752, 629.095, 935.679, 629.095, 935.679, 197.277, 819.714, 197.277, 819.714, 167.219, 811.642, 149.369, 780.685, 157.441, 750.626, 157.441, 750.626, 324.842, 127.277, 324.842, 127.277, 332.914, 97.218, 363.872, 79.368, 393.931, 87.441, 393.931, 87.441, 825.748, 203.406, 825.748, 203.406, 855.807, 211.478, 873.657, 242.435, 865.584, 272.494]],
  S0:[[426.901, 791.01, 422.052, 790.395, 389.973, 786.333, 370.405, 767.758, 323.018, 722.775, 346.08, 670.221, 373.15, 602.711, 393.703, 551.454, 394.592, 546.783, 401.871, 547.645, 411.493, 548.784, 481.097, 616.937, 491.678, 628.427, 498.482, 635.815, 549.929, 691.681, 506.39, 753.115, 476.427, 795.391, 430.487, 790.971, 426.901, 791.01]],
  S1:[[675.344, 733.424, 667.948, 733.175, 619.546, 731.553, 594.882, 687.798, 572.831, 648.679, 597.335, 602.758, 600.788, 596.286, 624.847, 551.197, 641.708, 539.057, 638.592, 505.237, 636.968, 487.6, 678.575, 513.817, 688.608, 533.222, 710.241, 575.053, 674.918, 605.932, 701.077, 613.55, 712.087, 616.758, 721.476, 603.552, 722.414, 587.903, 722.442, 587.43, 720.69, 571.162, 732.804, 579.929, 781.769, 615.363, 772.841, 727.458, 675.344, 733.424]],
  S2:[[604.408, 278.574, 604.056, 278.834, 603.447, 278.365, 603.094, 278.625, 600.556, 280.49, 602.399, 281.354, 614.339, 332.942, 614.756, 334.747, 615.04, 336.582, 615.451, 338.389, 620.38, 360.061, 622.136, 366.972, 622.765, 369.446, 627.032, 386.245, 625.415, 386.651, 626.257, 387.895, 626.699, 388.545, 627.728, 388.627, 628.169, 389.278, 630.86, 412.304, 650.407, 447.154, 594.876, 454.862, 567.861, 458.612, 560.958, 428.968, 560.131, 425.419, 552.139, 391.099, 552.402, 391.084, 550.316, 385.824, 550.547, 385.012, 551.927, 385.339, 551.101, 383.062, 551.056, 382.938, 550.824, 382.296, 550.648, 381.493, 550.35, 380.137, 550.162, 378.76, 549.861, 377.405, 537.706, 322.523, 538.111, 322.126, 534.701, 318.673, 535.571, 316.23, 535.436, 315.511, 526.287, 278.604, 517.248, 242.148, 543.443, 235.914, 563.021, 232.909, 589.98, 228.77, 596.718, 257.308, 597.534, 260.761, 601.169, 276.155, 600.251, 277.341, 604.408, 278.574]],
  S3:[[321.841, 348.011, 323.044, 335.617, 296.759, 293.267, 354.027, 283.983, 393.727, 277.548, 390.382, 331.506, 398.921, 351.466, 399.13, 353.08, 398.91, 353.01, 399.326, 354.58, 400.449, 358.847, 410.564, 410.956, 415.4, 418.786, 413.965, 443.14, 452.554, 492.871, 390.11, 504.345, 346.987, 512.27, 352.291, 458.865, 345.949, 457.814, 345.426, 457.728, 344.891, 458.074, 344.369, 457.989, 347.302, 456.167, 347.435, 456.306, 347.532, 456.023, 347.537, 456.012, 323.541, 353.277, 323.485, 351.202, 323.402, 348.146, 322.18, 348.669, 321.841, 348.011]],
  S4:[[534.701, 318.673, 538.111, 322.126, 537.706, 322.523, 549.861, 377.405, 550.162, 378.76, 550.35, 380.137, 550.648, 381.493, 550.824, 382.296, 551.056, 382.938, 551.101, 383.062, 551.927, 385.339, 550.547, 385.012, 550.316, 385.824, 540.398, 386.593, 417.41, 417.776, 415.4, 418.786, 410.564, 410.956, 400.449, 358.847, 399.326, 354.58, 398.91, 353.01, 399.13, 353.08, 398.921, 351.466, 404.819, 352.012, 532.984, 319.517, 534.701, 318.673]],
  S5:[[604.408, 278.574, 631.964, 271.895, 645.333, 266.84, 653.181, 301.245, 667.787, 365.283, 670.5, 368.349, 658.826, 378.647, 651.298, 385.29, 640.847, 384.199, 628.169, 389.278, 627.728, 388.627, 626.699, 388.545, 626.257, 387.895, 625.415, 386.651, 627.032, 386.245, 622.765, 369.446, 622.136, 366.972, 620.38, 360.061, 615.451, 338.389, 615.04, 336.582, 614.756, 334.747, 614.339, 332.942, 602.399, 281.354, 600.556, 280.49, 603.094, 278.625, 603.447, 278.365, 604.056, 278.834, 604.408, 278.574]],
  S6:[[321.841, 348.011, 322.18, 348.669, 323.402, 348.146, 323.485, 351.202, 323.541, 353.277, 347.537, 456.012, 347.532, 456.023, 347.435, 456.306, 347.302, 456.167, 344.369, 457.989, 325.83, 462.235, 304.186, 472.26, 297.014, 436.432, 285.709, 379.948, 268.221, 361.098, 309.536, 351.498, 315.776, 350.049, 315.664, 350.027, 321.841, 348.011]],
};
const SYMKEYS={Dumbbell:['S2','S3','S4','S5','S6'],Drop:['S0'],Flame:['S1']};
const SYMCOL={Dumbbell:'#4FC290',Drop:'#4E9EEA',Flame:'#F2844A'};

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
for (const k of ['Card 3', 'Card 2', 'Card 1']) { const n = path(cards, k, '#EBEBEB', GEOM[k][0]); doc.setOpacity(0.95, sel(n)); }
const syms = group(ab, 'Symbols');
for (const k of ['Dumbbell', 'Drop', 'Flame']) {
  const g = group(syms, k);
  SYMKEYS[k].forEach((s, i) => path(g, SYMKEYS[k].length > 1 ? k + ' part ' + (i + 1) : k, SYMCOL[k], GEOM[s][0]));
}
run(DocumentCommand.createSetVisibility(sel(bgD), false));
doc.saveAs(DESK + '/SetDeck App Icon.af');
const abs = []; for (const a of spread.artboards) abs.push(a);
doc.export(DESK + '/AppIcon.png', FileExportOptions.createWithPresetName('PNG'), FileExportArea.createForArtboard(abs[0]));
log('built; uuid', doc.sessionUuid);
