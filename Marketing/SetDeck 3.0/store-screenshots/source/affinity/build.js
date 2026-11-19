// SetDeck 3.0 store artboards. Each artboard: fill (near-black) > Background (image) > Device (framed capture) > Headline (live text).
const { Document, FileExportOptions, FileExportArea } = require('/document.js');
const { DocumentCommand, AddChildNodesCommandBuilder } = require('/commands.js');
const { InsertionMode } = require('affinity:commands');
const { Selection, TextSelection } = require('/selections.js');
const { Transform, Rectangle, Point } = require('/geometry.js');
const { Bitmap, RasterFormat } = require('/rasterobject.js');
const Nodes = require('/nodes.js');
const { ShapeRectangle } = require('/shapes.js');
const { Colour } = require('/colours.js');
const { StoryDelta, GlyphAttDoubleType, ParagraphAlignXType, CapsType } = require('/storydelta.js');
const { StoryBuilder } = require('/storybuilder.js');
const { StoryRange } = require('affinity:story');
const DESK = '/Users/nickmolargik/Desktop/SetDeck 3.0 Store (Claude)';
const JOBS = __JOBS__;
let doc = Document.all.find(d => (d.title || '').includes('SetDeck 3.0 Artboards'));
if (!doc) doc = Document.load(DESK + '/SetDeck 3.0 Artboards.af');
const spread = doc.spreads.first;
const tag = n => Object.prototype.toString.call(n).slice(8, -1);
const desc = n => { try { return n.description; } catch (e) { return null; } };
const kids = n => { const out = []; for (const c of n.children) out.push(c); return out; };
const find = name => kids(spread).find(c => desc(c) === name) || null;
const sel = n => Selection.create(doc, n);
const rgba = hex => { const h = hex.replace('#', ''); return Colour.createRGBA8({ r: parseInt(h.slice(0, 2), 16), g: parseInt(h.slice(2, 4), 16), b: parseInt(h.slice(4, 6), 16), alpha: 255 }); };
function place(ab, file, name, x, y, w, h) {
  const bm = Bitmap.loadFromFile(DESK + '/images/' + file, RasterFormat.RGBA8);
  const def = Nodes.ImageNodeDefinition.create(RasterFormat.RGBA8); def.bitmap = bm;
  const b = AddChildNodesCommandBuilder.create(); b.addImageNode(def); b.setInsertionTarget(ab); b.setInsertionMode(InsertionMode.Inside_AtFront);
  const cmd = b.createCommand(false); doc.executeCommand(cmd);
  const img = cmd.newNodes[0];
  doc.executeCommand(DocumentCommand.createSetDescription(sel(img), name));
  const ib = img.spreadBaseBox;
  doc.executeCommand(DocumentCommand.createTransform(sel(img), Transform.createTranslate(x, y).multiply(Transform.createScale(w / ib.width, h / ib.height)).multiply(Transform.createTranslate(-ib.x, -ib.y))));
  return img;
}
for (const J of JOBS) {
  try {
    let ab = find(J.name);
    if (!ab) {
      const before = new Set(kids(spread).map(desc));
      const def = Nodes.ShapeNodeDefinition.createDefault(); def.shape = ShapeRectangle.create();
      def.setBoundingRectangle(new Rectangle(J.x, J.y, J.w, J.h));
      doc.executeCommand(DocumentCommand.createAddArtboard(def));
      ab = kids(spread).find(c => !before.has(desc(c)) || (Math.abs(c.spreadBaseBox.x - J.x) < 1 && Math.abs(c.spreadBaseBox.y - J.y) < 1 && desc(c) !== J.name && !JOBS.some(o => o.name === desc(c))));
      doc.executeCommand(DocumentCommand.createSetDescription(sel(ab), J.name));
    }
    const A = ab.spreadBaseBox;
    if (Math.abs(A.width - J.w) > 0.5 || Math.abs(A.height - J.h) > 0.5) throw new Error('size mismatch ' + A.width + 'x' + A.height);
    doc.executeCommand(DocumentCommand.createSetBrushFill(sel(ab), rgba('#07090A')));
    for (const c of kids(ab)) doc.executeCommand(DocumentCommand.createDeleteSelection(sel(c)));
    const W = J.w, H = J.h;
    // headline
    const runs = []; J.lines.forEach((line, i) => { line.forEach(r => runs.push(r)); if (i < J.lines.length - 1) runs.push(['\n', '#FFFFFF']); });
    const full = runs.map(r => r[0]).join('');
    const sb = StoryBuilder.create(); sb.setToArtisticTextDefaultStyle(72, RasterFormat.RGBA8); sb.addText(full);
    const tdef = Nodes.ArtTextNodeDefinition.createFromStoryBuilder(new Point(A.x + W / 2, A.y + J.top + J.fontSize), sb);
    const tb0 = AddChildNodesCommandBuilder.create(); tb0.addNode(tdef); tb0.setInsertionTarget(ab); tb0.setInsertionMode(InsertionMode.Inside_AtFront);
    const tcmd = tb0.createCommand(false); doc.executeCommand(tcmd);
    const text = tcmd.newNodes[0];
    const whole = () => { const x = sel(text); x.addSubSelectionForNode(text, TextSelection.create([new StoryRange(0, full.length)])); return x; };
    doc.executeCommand(DocumentCommand.createFormatText(whole(), StoryDelta.createPostscriptName(J.font)));
    doc.executeCommand(DocumentCommand.createFormatText(whole(), StoryDelta.createGlyphDouble(GlyphAttDoubleType.Height, J.fontSize)));
    doc.executeCommand(DocumentCommand.createFormatText(whole(), StoryDelta.createAlignX(J.align === 'left' ? ParagraphAlignXType.Left : ParagraphAlignXType.Centre)));
    if (J.tracking) doc.executeCommand(DocumentCommand.createFormatText(whole(), StoryDelta.createGlyphDouble(GlyphAttDoubleType.CharacterSpacing, J.tracking)));
    if (J.leading) doc.executeCommand(DocumentCommand.createFormatText(whole(), StoryDelta.createGlyphDouble(GlyphAttDoubleType.AbsoluteLeading, J.leading)));
    let pos = 0;
    for (const [t, c] of runs) {
      if (t !== '\n') {
        const x = sel(text); x.addSubSelectionForNode(text, TextSelection.create([new StoryRange(pos, pos + t.length)]));
        doc.executeCommand(DocumentCommand.createSetSelection(x));
        doc.executeCommand(DocumentCommand.createSetBrushFill(x, rgba(c), { useTextSelection: true }));
      }
      pos += t.length;
    }
    doc.executeCommand(DocumentCommand.createSetDescription(sel(text), 'Headline'));
    for (const im of J.images.slice().reverse()) place(ab, im.file, im.name || 'Device', A.x + im.x, A.y + im.y, im.w, im.h);
    place(ab, J.bg, 'Background', A.x, A.y, W, H);
    const tb = text.spreadBaseBox;
    const tx = J.align === 'left' ? A.x + J.margin - tb.x : A.x + (W - tb.width) / 2 - tb.x;
    doc.executeCommand(DocumentCommand.createTransform(sel(text), Transform.createTranslate(tx, A.y + J.top - tb.y)));
    let abi = null; for (const a of spread.artboards) if (a.description === J.name) abi = a;
    const res = doc.export(DESK + '/export/' + J.out + '.png', FileExportOptions.createWithPresetName('PNG'), FileExportArea.createForArtboard(abi));
    const tb2 = text.spreadBaseBox;
    console.log(J.name, 'ok text', Math.round(tb2.width) + 'x' + Math.round(tb2.height), 'at', Math.round(tb2.x - A.x) + ',' + Math.round(tb2.y - A.y), 'layers', kids(ab).map(c => desc(c) || tag(c)).join(' > '), 'export', res.all[0].isSuccess);
  } catch (e) { console.log(J.name, 'FAILED', String(e && e.stack ? e.stack : e).slice(0, 500)); }
}
doc.save();
