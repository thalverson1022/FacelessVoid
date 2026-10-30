/* Deterministic, offline catalog builder. Run from any directory. */
'use strict';
const fs = require('node:fs'), path = require('node:path'), crypto = require('node:crypto');
const root = path.resolve(__dirname, '../..');
const read = p => fs.readFileSync(path.join(root, p), 'utf8').replace(/^\uFEFF/, '');
const json = p => JSON.parse(read(p));
const hash = b => crypto.createHash('sha256').update(b).digest('hex');
const manifest = json('docs/P6M2_T4_Content_Identity_Manifest.json');
const inventory = json('docs/P6M4_T2_Icon_Inventory.json');
const drafts = new Map(manifest.sources.map(s => [s.file, json(s.file)]));
const at = (obj, pointer) => pointer.split('/').slice(1).reduce((o, k) => o?.[k], obj);
const assets = [];
const folders = ['skill_icons/rogue', 'ui/icons/mechanics'];
const files = folders.flatMap(f => fs.readdirSync(path.join(root, 'project/assets', f)).filter(n => n.endsWith('.png')).map(n => `project/assets/${f}/${n}`));
for (const name of ['enemy_armor','resistance','poison_stack','shred','decay']) files.push(`project/assets/combat_ui_icons/${name}.png`);
for (const file of files.sort()) {
  const bytes = fs.readFileSync(path.join(root, file));
  const resource_path = file.replace('project/', 'res://');
  assets.push({id: resource_path, name: path.basename(file, '.png').replaceAll('_',' '), kind:'existing', resource_path,
    sha256:hash(bytes), width:bytes.readUInt32BE(16), height:bytes.readUInt32BE(20), bytes:bytes.length,
    url:'../../'+file, group:file.includes('/mechanics/')?'Defensive mechanics':file.includes('/skill_icons/')?'Skills':'Enemy statuses'});
}
const iconFor = id => {
  for (const f of fs.readdirSync(path.join(root,'project/data/skills')).filter(n=>n.endsWith('.tres'))) {
    const s=read('project/data/skills/'+f);
    if (s.match(/^id = "([^"]+)"/m)?.[1]!==id) continue;
    const icon=s.match(/^icon = ExtResource\("([^"]+)"\)/m)?.[1];
    if(!icon) return null;
    const line=s.split('\n').find(l=>l.startsWith('[ext_resource ') && l.includes(`id="${icon}"`));
    return line?.match(/path="([^"]+)"/)?.[1] || null;
  }
  return null;
};
const descriptions = {
  'skill.hold':'Wait for one second before advancing the macro.',
  'skill.stab':'Base Rogue physical attack. Can interact with Precision and Bypass when enabled.',
  'skill.heavy_slash':'Base Rogue physical attack. Can consume Precision when enabled.',
  'skill.quick_cut':'Physical attack. Grants enabled Precision before child triggers, and Footwork after its subtree.',
  'skill.parry_strike':'Requires and consumes Readiness at cast start. Without it, spends cast time without effects.',
  'skill.leaping_plunge':'Consumes Footwork at cast start to shorten its cast; respects its minimum cast time.',
  'skill.rending_thrust':'Rending Slash deals physical damage, then applies Shred.',
  'skill.dance_of_death':'Self Buff: grants the Dance window after activation. Five-second duration, twenty-second shared cooldown.',
  'skill.poison_strike':'Physical attack causing one forced, fueled Poison tick on a connected hit. Tick depletion is not Consume.',
  'skill.blinding_powder':'Applies Potency based on invested Assassin points, with eligible stack modifiers.',
  'skill.virulent_poison':'Self Buff: five charges per instance; doubles fueled Poison ticks and spends one charge per tick.',
  'skill.master_of_poisons':'Self Buff: ignores elemental resistance for five seconds.',
  'skill.poison_vile':'Applies twenty base Poison stacks, subject to eligible bonuses and capacity. Name retained from the manifest.',
  'skill.touch_of_darkness':'Consumes actual Poison for +10% ordinary additive attack speed per stack, for eight seconds.',
  'skill.beguiling_presence':'Consumes actual Decay for +1 base elemental damage per stack, for ten seconds.',
  'skill.mug':'Adds credited gold stolen this fight to base physical damage, capped at +100.',
  'skill.steal':'Physical attack; critical hits steal three raw gold before gold modifiers.',
  'skill.pick_pocket':'Debuff skill: steals twenty raw gold per execution; does not become an attack for repeat eligibility.',
 'skill.big_score':'90% weapon scaling. Doubles the full current critical multiplier on critical hits only.',
};
const entries = inventory.entries.map(e=>{
  const record=manifest.records.find(r=>r.kind===e.kind && r.runtime_id===e.id);
  const draft=record ? at(drafts.get(record.source_file),record.pointer):null;
  return {id:e.id,name:e.name.trim(),category:e.kind==='skill'?'Skills':'Talents',tree:e.tree_id?.replace('tree.','')||'Rogue',scope:e.scope,
    description:descriptions[e.id] || draft?.description || 'See the content reference for this entry.',
    description_source:descriptions[e.id]?'Reviewed mechanics summary':'Design draft — wording may be superseded; not a runtime specification',
    current_icon:e.kind==='skill'?iconFor(e.id):null,
    content_status:e.scope==='full_library'?'Full-library design; complete redesigned binding remains M5':'M4 candidate; redesigned playable integration pending',
    source:record?.source_file || 'project/data/skills', source_pointer:record?.pointer||null};
});
const add=(category,id,name,description,asset=null,scope='full_library')=>entries.push({category,id,name,description,current_icon:asset,scope,tree:'Shared',description_source:'Reviewed mechanics summary',content_status:'Shared mechanic; icon assignment does not promote gameplay content',source:'docs/Combat_Mechanics_Reference.md'});
const defenses={armor:['Armor','Mitigates physical damage.','combat_ui_icons/enemy_armor.png'],resistance:['Resistance','Mitigates elemental damage.','combat_ui_icons/resistance.png'],dodge:['Dodge','Chance for an attack to miss.'],crit_negation:['Critical Negation','Mitigates critical-hit amplification.'],block:['Block','Flat physical damage mitigation.'],absorb:['Absorb','Flat elemental damage mitigation.'],cleanse:['Cleanse','Removes eligible enemy statuses at its attack threshold.'],suppress:['Suppress','Slows Poison tick cadence.'],slow:['Slow','Slows skill casting.'],stun:['Stun','Delays macro progression.'],interrupt:['Interrupt','Interrupts and temporarily locks affected skill executions.']};
for(const [id,[name,desc,file]] of Object.entries(defenses)) add('Defensive Mechanics','defense.'+id,name,desc,'res://assets/'+(file||'ui/icons/mechanics/'+id+'.png'),'shared');
const buffs={footwork:['Footwork','Up to five stacks with a shared three-second timer. Leaping Plunge consumes stacks at cast start.','m4_core'],readiness:['Readiness','One untimed charge, consumed by Parry Strike.','m4_core'],precision:['Precision','One untimed charge. Eligible Stab/Heavy Slash consumes it for a guaranteed repeat.'],dance:['Dance','Five-second window for guaranteed eligible macro repeats. Separate from the skill cooldown.','m4_mixed_addition'],bypass:['Bypass','Up to three stacks, shared three-second timer; each adds a separate 10% elemental multiplier.'],virulent_poison:['Virulent Poison','Five charges per independent instance. Fueled Poison ticks spend charges; no timed expiration.'],master_of_poisons:['Master of Poisons','Five-second resistance-ignore window.'],touch_of_darkness:['Touch of Darkness','Eight-second additive attack-speed bonus from actual Poison consumed; instances expire independently.'],beguiling_presence:['Beguiling Presence','Ten-second base elemental bonus from actual Decay consumed; instances expire independently.']};
for(const [id,[name,desc,scope]] of Object.entries(buffs)) add('Player Buffs','buff.'+id,name,desc,null,scope);
for(const [id,name,desc,file] of [
  ['poison','Poison','Fuel for Poison ticks. Actual tick depletion is distinct from keyword Consume.','poison_stack'],
  ['shred','Shred','Reduces armor per stack; cap 500.','shred'],
  ['decay','Decay','Reduces resistance based on remaining stacks. Consuming it restores resistance accordingly.','decay'],
  ['penetration','Penetration','Reduces block by one per stack, cap 100; timed and cleansable.',null],
  ['potency','Potency','Reduces absorb by one per stack, cap 100; timed and cleansable.',null]]) add('Enemy Statuses','status.'+id,name,desc,file?'res://assets/combat_ui_icons/'+file+'.png':null,'shared');
const categories=['Defensive Mechanics','Skills','Talents','Player Buffs','Enemy Statuses'];
entries.sort((a,b)=>categories.indexOf(a.category)-categories.indexOf(b.category)||a.tree.localeCompare(b.tree)||a.name.localeCompare(b.name));
if(entries.length!==92 || new Set(entries.map(e=>e.id)).size!==92) throw Error('Catalog must contain 92 distinct identities');
for(const e of entries) if(e.current_icon&&!assets.some(a=>a.id===e.current_icon)) throw Error('Uncatalogued icon '+e.current_icon);
const data={schema_version:1,manifest_revision:manifest.revision,categories,entries,assets};
// Approved display-name correction only: retain the pre-rename fingerprint so
// existing icon workspaces remain valid. IDs, mechanics and assets still hash normally.
const fingerprintData=structuredClone(data);
const whetstone=fingerprintData.entries.find(e=>e.id==='talent.bladedancer.wet_stone');
if(whetstone?.name==='Whetstone') whetstone.name='Wet Stone';
data.fingerprint=hash(JSON.stringify(fingerprintData));
// Additive library packs do not change the mechanics/game-reference fingerprint.
// Existing drafts remain valid; unknown asset references are still rejected.
for(const [packId,packLabel] of [['48-character-class-role-icons','Character Class & Role Icons'],['48-elemental-icons','Elemental Icons'],['48-rpg-skill-icons-vol-2','RPG Skill Icons Vol. 2'],['pixel-spell-icons','Pixel Spell Icons'],['pixel-skill-icons-2','Pixel Skill Icons 2'],['rpg-skill-icons','RPG Skill Icons'],['custom-variants','Custom Variants'],['rpg-icon-pack-skills','RPG Icon Pack - Skills']]){
const packPath=path.join(__dirname,'assets/packs',packId);
for(const name of fs.readdirSync(packPath).filter(n=>n.endsWith('.png')).sort()){
  const bytes=fs.readFileSync(path.join(packPath,name));
  const library_path=`tools/icon-lab/assets/packs/${packId}/${name}`;
  const label=packId==='48-character-class-role-icons'?'Class & Role '+name.match(/\d+/)[0]:path.basename(name,'.png').replaceAll('_',' ');
  data.assets.push({id:`pack:${packId}/${name}`,name:label,kind:'bundled',pack_id:packId,
    group:packLabel,resource_path:null,library_path,sha256:hash(bytes),
    width:bytes.readUInt32BE(16),height:bytes.readUInt32BE(20),bytes:bytes.length,url:`assets/packs/${packId}/${name}`});
}
}
// Preserve every previous installed path for old drafts and exported snapshots.
const walkPngs=dir=>fs.readdirSync(dir,{withFileTypes:true}).flatMap(e=>e.isDirectory()?walkPngs(path.join(dir,e.name)):e.name.endsWith('.png')?[path.join(dir,e.name)]:[]);
for(const full of walkPngs(path.join(root,'project/assets/ui/assigned')).sort()){
  const file=path.relative(root,full).replaceAll('\\','/'),resource_path=file.replace('project/','res://');
  if(assets.some(a=>a.id===resource_path))continue;
  const bytes=fs.readFileSync(full);
  assets.push({id:resource_path,name:path.basename(full,'.png').replaceAll('_',' '),kind:'existing',resource_path,sha256:hash(bytes),width:bytes.readUInt32BE(16),height:bytes.readUInt32BE(20),bytes:bytes.length,url:'../../'+file,group:'Previous assigned artwork'});
}
// Installed presentation mappings overlay the original compatibility baseline.
// Keep old assets addressable so existing workspaces never lose their choices.
const assignedPath=path.join(root,'project/data/ui/icon_assignments.json');
if(fs.existsSync(assignedPath)){
  const installed=JSON.parse(fs.readFileSync(assignedPath,'utf8'));
  add('Player Buffs','buff.greed','Greed','Credited gold stolen this fight; untimed and reset each fight.',null,'shared');
  for(const e of entries){
    const mapping=installed.entries[e.id];
    if(!mapping) throw Error('Missing installed icon: '+e.id);
    e.name=mapping.name;
    e.current_icon=mapping.path;
    e.content_status='Live Phase 6 content; wording review belongs to M7-T5';
    if(e.description_source.startsWith('Design draft')) e.description='See the current in-game tooltip. Historical draft wording is excluded from this icon-authoring catalog.';
    if(mapping.inherits) e.icon_source=mapping.inherits;
    if(!assets.some(a=>a.id===mapping.path)){
      const file='project/'+mapping.path.replace('res://','');
      const bytes=fs.readFileSync(path.join(root,file));
      if(hash(bytes)!==mapping.sha256) throw Error('Installed icon changed: '+file);
      assets.push({id:mapping.path,name:mapping.name,kind:'existing',resource_path:mapping.path,
        sha256:hash(bytes),width:bytes.readUInt32BE(16),height:bytes.readUInt32BE(20),bytes:bytes.length,
        url:'../../'+file,group:'Assigned game icons'});
    }
  }
}
// Explicit migration from the frozen 92-identity catalog. No arbitrary fingerprint acceptance.
data.legacy_fingerprints=['e3fb9455e6981b64d50930656569a35d66b5a1a434035bbe1c6728e2728be0fa'];
data.compatible_fingerprints=['0c0d6cefb4afaefcf8973343854e36048246776ee791e692b19a9663316f04f9'];
const summaries={
 'skill.touch_of_darkness':'Consumes Poison for additive attack speed and physical damage; independent twelve-second instances.',
 'buff.touch_of_darkness':'Poison-fueled attack speed and physical damage; independent twelve-second instances.',
 'skill.beguiling_presence':'Consumes Decay for critical chance and base elemental damage; ten-second instances.',
 'buff.beguiling_presence':'Decay-fueled critical chance and elemental damage; ten-second instances.',
 'skill.pick_pocket':'Non-attack theft skill; raw theft is adjusted by applicable gold modifiers.',
 'skill.big_score':'On a critical hit, uses six times the full current critical multiplier.',
 'skill.mug':'Adds a capped base physical bonus from credited gold stolen this fight; excludes starting stash.',
 'status.penetration':'Reduces Block by one per stack; cap 50, timed and cleansable.',
 'status.potency':'Reduces Absorb by one per stack; cap 50, timed and cleansable.'
};
for(const e of entries) if(summaries[e.id]) e.description=summaries[e.id];
entries.sort((a,b)=>categories.indexOf(a.category)-categories.indexOf(b.category)||a.tree.localeCompare(b.tree)||a.name.localeCompare(b.name));
if(entries.length!==93 || new Set(entries.map(e=>e.id)).size!==93) throw Error('Expected 93 live identities');
data.fingerprint=hash(JSON.stringify({entries,manifest_revision:data.manifest_revision}));
data.library_fingerprint=hash(JSON.stringify(data.assets));
const outputs={'catalog.json':JSON.stringify(data,null,2)+'\n','bundle.js':'window.ICON_LAB_DATA = '+JSON.stringify(data)+';\n'};
for(const [name,contents] of Object.entries(outputs)){
  const target=path.join(__dirname,'data',name);
  if(process.argv.includes('--check')) {if(!fs.existsSync(target)||fs.readFileSync(target,'utf8')!==contents) throw Error('Stale generated data: '+name);}
  else {fs.mkdirSync(path.dirname(target),{recursive:true});fs.writeFileSync(target,contents);}
}
console.log(`Catalog: ${entries.length} entries, ${assets.length} assets. ${process.argv.includes('--check')?'Fresh.':'Built.'}`);


