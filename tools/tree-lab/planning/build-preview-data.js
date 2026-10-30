// Development-only wrapper: keep the JSON fixtures canonical and file-open preview usable.
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '..');
const read = p => JSON.parse(fs.readFileSync(path.join(root, p), 'utf8'));
const data = { empty: read('templates/empty-tree.json'), assassin: read('examples/assassin-sketch.json'), icons: read('data/icon-catalog.json') };
const output = 'window.TREE_LAB_PREVIEW = ' + JSON.stringify(data, null, 2) + ';\n';
const target = path.join(__dirname, 'preview-data.js');
if (process.argv.includes('--check')) {
  if (!fs.existsSync(target) || fs.readFileSync(target, 'utf8') !== output) throw new Error('Run build-preview-data.js to refresh preview fixtures');
  console.log('Preview fixture wrapper matches canonical JSON.');
} else fs.writeFileSync(target, output);
