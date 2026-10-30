'use strict';
// T4 documentation evidence only; this does not convert gameplay content.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const assert = require('node:assert/strict');
const validateSource = require('./source_provenance.js');
const root = path.resolve(__dirname, '../..');
const read = p => fs.readFileSync(path.join(root, p), 'utf8');
const manifest = JSON.parse(read('docs/P6M2_T4_Content_Identity_Manifest.json'));
const ids = new Set();
const keys = new Set();
const counts = {};
let rankSlots = 0;
assert.equal(manifest.schema_version, 1);
for (const source of manifest.sources) {
  const bytes = read(source.file);
  validateSource(source.file, source.sha256, bytes);
  const data = JSON.parse(bytes);
  const records = manifest.records.filter(r => r.source_file === source.file);
  const expected = new Set(['/tree', '/tree/intrinsic']);
  data.tree.talents.forEach((t, i) => {
    expected.add(`/tree/talents/${i}`);
    rankSlots += t.max_ranks;
    if (t.skill_grant) expected.add(`/tree/talents/${i}/skill_grant`);
  });
  data.tree.automatic_unlocks.forEach((u, i) => {
    expected.add(`/tree/automatic_unlocks/${i}`);
    if (u.skill) expected.add(`/tree/automatic_unlocks/${i}/skill`);
  });
  assert.equal(records.length, expected.size, source.file + ' coverage');
  for (const r of records) {
    assert(expected.delete(r.pointer), 'duplicate/unexpected pointer ' + r.pointer);
    const object = r.pointer.split('/').slice(1).reduce((o, k) => o[k], data);
    assert.equal(r.source_id, object.id ?? null);
    assert.equal(r.source_name, object.name ?? null);
    assert.equal(r.tree_id, source.tree_id);
    const key = `${source.file}:${r.pointer}`;
    assert(!keys.has(key), key); keys.add(key);
    assert(!ids.has(r.runtime_id), 'duplicate runtime ID ' + r.runtime_id); ids.add(r.runtime_id);
    assert(/^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$/.test(r.runtime_id), r.runtime_id);
    counts[r.kind] = (counts[r.kind] || 0) + 1;
    if (r.kind === 'slot') assert.equal(r.empty, object.skill === null);
    if (r.existing_resource_path) {
      const text = read('project/' + r.existing_resource_path.replace('res://', ''));
      assert.equal(text.match(/^id = "([^"]+)"/m)?.[1], r.runtime_id);
    }
  }
  assert.equal(expected.size, 0);
}
assert.deepEqual(counts, {tree: 4, intrinsic: 4, talent: 44, skill: 20, slot: 20});
assert.equal(rankSlots, 140);
const legacyPaths = new Set();
for (const r of manifest.legacy_resources) {
  assert(!legacyPaths.has(r.path)); legacyPaths.add(r.path);
  const text = read('project/' + r.path.replace('res://', ''));
  assert.equal(text.match(/^id = "([^"]+)"/m)?.[1], r.id, r.path);
}
for (const dir of ['subclass_trees', 'talents', 'skills', 'classes']) {
  const walk = folder => {
    for (const entry of fs.readdirSync(folder, {withFileTypes: true})) {
      const full = path.join(folder, entry.name);
      if (entry.isDirectory()) walk(full);
      else if (entry.name.endsWith('.tres')) {
        const resource = 'res://' + path.relative(path.join(root, 'project'), full).replaceAll('\\', '/');
        assert(legacyPaths.has(resource), 'missing legacy path ' + resource);
      }
    }
  };
  walk(path.join(root, 'project/data', dir));
}
console.log(JSON.stringify({result: 'PASS', counts, rankSlots, legacyResources: legacyPaths.size, scope: 'T4 identity documentation; no runtime migration validation'}, null, 2));
