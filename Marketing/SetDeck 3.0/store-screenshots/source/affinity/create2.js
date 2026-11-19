// Creates the empty SetDeck 3.0 store document in pixels (one artboard; build.js adds the rest).
const { Document, NewDocumentOptions } = require('/document.js');
const { UnitType } = require('affinity:common');
const { DocumentCommand } = require('/commands.js');
const { Selection } = require('/selections.js');
const DESK = '/Users/nickmolargik/Desktop/SetDeck 3.0 Store (Claude)';
for (const d of Document.all) if ((d.title || '').includes('SetDeck 3.0 Artboards')) d.close();
const o = NewDocumentOptions.createDefault();
o.units = UnitType.Pixel; o.dpi = 72; o.viewDpi = 72;
o.createArtboard = true; o.width = 1320; o.height = 2868;
const doc = Document.create(o);
doc.saveAs(DESK + '/SetDeck 3.0 Artboards.af');
const first = []; for (const a of doc.spreads.first.artboards) first.push(a);
doc.executeCommand(DocumentCommand.createSetDescription(Selection.create(doc, first[0]), 'iphone 01'));
doc.save();
for (const a of doc.spreads.first.artboards) console.log('artboard', a.description, JSON.stringify(a.spreadBaseBox));
