'use strict';
// Planning-only T3 legality check. Does not run Godot, approve effects or prove balance.
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const crypto = require('node:crypto');
const validateSource = require('./source_provenance.js');
const root = path.resolve(__dirname, '../..');
const read = p => fs.readFileSync(path.join(root, p), 'utf8');
const data = JSON.parse(read('docs/P6M2_T5_Build_Fixtures.json'));
const manifest = JSON.parse(read('docs/P6M2_T4_Content_Identity_Manifest.json'));
assert.equal(data.schema_version, 1);
assert.equal(data.kind, 'planning_only_not_runtime_content');
assert.equal(data.identity_revision, manifest.revision);
assert.deepEqual(data.sources, manifest.sources);
const trees = new Map();
const talents = new Map();
for (const source of data.sources) {
  const raw = read(source.file);
  validateSource(source.file, source.sha256, raw);
  const tree = JSON.parse(raw).tree;
  const records = manifest.records.filter(r => r.source_file === source.file);
  const at = pointer => {
    const record = records.find(r => r.pointer === pointer);
    assert(record, pointer);
    return record.runtime_id;
  };
  const bySource = new Map(tree.talents.map((t, i) => [t.id, at(`/tree/talents/${i}`)]));
  tree.talents.forEach((t, i) => talents.set(at(`/tree/talents/${i}`), {
    tree: source.tree_id, name: t.name, max: t.max_ranks,
    gate: tree.levels.find(l => l.id === t.level_id).required_points,
    requires: t.prerequisite_ids.map(id => bySource.get(id)),
    grant: t.skill_grant ? at(`/tree/talents/${i}/skill_grant`) : null,
  }));
  trees.set(source.tree_id, tree.automatic_unlocks.filter(u => u.skill).map(u => ({
    points: u.required_points,
    id: at(`/tree/automatic_unlocks/${tree.automatic_unlocks.indexOf(u)}/skill`),
  })));
}
const profiles = new Map();
for (const [name, profile] of Object.entries(data.profiles)) {
  assert(trees.has(profile.tree_id));
  let ranks = {}, points = 0;
  const snapshots = [{}];
  for (const step of profile.purchases) {
    const talent = talents.get(step.talent_id);
    assert(talent && talent.tree === profile.tree_id, name + ' membership');
    assert(Number.isInteger(step.to_rank) && step.to_rank > (ranks[step.talent_id] || 0) && step.to_rank <= talent.max);
    while ((ranks[step.talent_id] || 0) < step.to_rank) {
      assert(points >= talent.gate, name + ': buy before gate ' + talent.name);
      assert(talent.requires.every(id => (ranks[id] || 0) >= 1), name + ': prerequisite ' + talent.name);
      ranks = {...ranks, [step.talent_id]: (ranks[step.talent_id] || 0) + 1};
      points++;
      snapshots.push(ranks);
    }
  }
  profiles.set(name, {tree: profile.tree_id, snapshots});
}
const ids = new Set();
const expanded = [];
for (const fixture of data.fixtures) {
  assert(!ids.has(fixture.id)); ids.add(fixture.id);
  assert(Number.isInteger(fixture.budget) && fixture.budget >= 0 && fixture.budget <= 45);
  const available = new Set(['skill.stab', 'skill.heavy_slash', 'skill.hold']);
  let spent = 0;
  const roles = [], ranks = {};
  for (const slot of [fixture.primary, fixture.secondary].filter(Boolean)) {
    const profile = profiles.get(slot.profile);
    assert(profile && Number.isInteger(slot.points) && slot.points >= 0 && slot.points < profile.snapshots.length);
    assert(!roles.includes(profile.tree), fixture.id + ': duplicate tree'); roles.push(profile.tree);
    const selected = profile.snapshots[slot.points];
    for (const [id, rank] of Object.entries(selected)) {
      const talent = talents.get(id);
      assert(slot.points >= talent.gate && talent.requires.every(id => (selected[id] || 0) >= 1));
      ranks[id] = rank;
      if (talent.grant) available.add(talent.grant);
    }
    for (const unlock of trees.get(profile.tree)) if (slot.points >= unlock.points) available.add(unlock.id);
    spent += slot.points;
  }
  assert(spent <= fixture.budget, fixture.id + ': overspend');
  assert(fixture.rotation_skill_ids.length > 0 && fixture.rotation_skill_ids.length <= 10);
  assert(fixture.rotation_skill_ids.every(id => available.has(id)), fixture.id + ': unavailable rotation');
  expanded.push({id: fixture.id, roles, spent, unspent: fixture.budget - spent, ranks});
}
const mixed = expanded.filter(f => f.id.startsWith('mix_'));
assert.equal(mixed.length, 36);
for (const primary of ['assassin', 'bladedancer', 'shadow', 'thief']) {
  for (const secondary of ['assassin', 'bladedancer', 'shadow', 'thief']) {
    if (primary === secondary) continue;
    for (const [a, b] of [[35, 10], [24, 21], [33, 12]]) {
      const id = `mix_${primary}_${a}_${secondary}_${b}`;
      const fixture = data.fixtures.find(f => f.id === id);
      assert(fixture, id);
      assert.equal(fixture.primary.profile, primary);
      assert.equal(fixture.primary.points, a);
      assert.equal(fixture.secondary.profile, secondary);
      assert.equal(fixture.secondary.points, b);
    }
  }
}
for (const [name, profile] of profiles) {
  if (name.includes('_')) continue;
  assert.equal(profile.snapshots.length, 36, name + ' full tree');
  for (const amount of [21, 24]) {
    assert(Object.keys(profile.snapshots[amount]).some(id => talents.get(id).gate === 20), name + ' capstone');
  }
  for (const budget of [0, 1, 3, 5, 6, 9, 10, 11, 12, 15, 20, 21, 24, 25, 30, 33, 35, 40, 45]) {
    assert(ids.has(`${name}_${budget}`));
  }
}
assert.equal(expanded.length, 121);
console.log(JSON.stringify({result: 'PASS', profiles: profiles.size, fixtures: expanded.length,
  matureMixedCases: mixed.length, m4: expanded.filter(f => f.id.startsWith('m4_')),
  scope: 'Draft allocation paths, retained legality and authored skill availability only; combat/UI/persistence untested'}, null, 2));
if (process.argv.includes('--expand')) console.log(JSON.stringify(expanded, null, 2));
