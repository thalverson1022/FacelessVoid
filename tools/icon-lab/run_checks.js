'use strict';
const assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto');
const M=require('./model'),D=require('./data/catalog.json');let checks=0;
const test=(name,fn)=>{fn();checks++;console.log('PASS '+name);};
const initial=M.initial(D), first=D.entries[0].id, asset=D.assets[0].id;
function imported(name='same.png',file='bladedancer.png'){
 const bytes=fs.readFileSync(path.join(__dirname,'../../project/assets/subclass_icons/rogue',file));const sha256=crypto.createHash('sha256').update(bytes).digest('hex');
 return {id:'import:'+sha256,name,mime:'image/png',data_url:'data:image/png;base64,'+bytes.toString('base64'),sha256,width:bytes.readUInt32BE(16),height:bytes.readUInt32BE(20),bytes:bytes.length};
}
test('93 canonical entities in agreed category counts',()=>{assert.equal(D.entries.length,93);assert.equal(new Set(D.entries.map(e=>e.id)).size,93);assert.deepEqual(D.categories.map(c=>D.entries.filter(e=>e.category===c).length),[11,23,44,10,5]);});
test('all 585 library assets match source fingerprints',()=>{assert.equal(D.assets.length,585);for(const a of D.assets){const b=fs.readFileSync(path.resolve(__dirname,a.url));assert.equal(crypto.createHash('sha256').update(b).digest('hex'),a.sha256);}});
test('initial state has all 93 installed assignments',()=>{assert.equal(Object.values(initial.assignments).filter(Boolean).length,93);assert.deepEqual(M.validate(initial,D),initial);});
test('assign, clear and reuse do not mutate baseline or prior state',()=>{const changed=M.change(initial,first,asset,D);assert.equal(changed.assignments[first],asset);assert.equal(initial.assignments[first],D.entries[0].current_icon);assert.equal(M.change(changed,first,null,D).assignments[first],null);});
test('same filename with different contents yields two assets; identical bytes deduplicate',()=>{const a=imported(),b=imported('same.png','assassin.png');const s=M.addAssets(initial,[a,a,b],D);assert.equal(s.imported_assets.length,2);assert.notEqual(a.id,b.id);});
test('portable export/import preserves bytes, assignments and explicit clears',()=>{const a=imported();let s=M.addAssets(initial,[a],D);s=M.change(s,first,a.id,D);s=M.change(s,'skill.stab',null,D);const ex=M.exported(s,D);assert.equal(ex.catalog_snapshot.entries.length,93);assert.equal(ex.catalog_snapshot.existing_assets.length,585);assert.deepEqual(M.parse(JSON.stringify(ex),D),s);assert.equal(ex.changes.find(c=>c.entity_id==='skill.stab').to,null);});
test('referenced assets cannot be deleted',()=>{const a=imported();let s=M.change(M.addAssets(initial,[a],D),first,a.id,D);assert.throws(()=>M.removeAsset(s,a.id,D));s=M.change(s,first,null,D);assert.equal(M.removeAsset(s,a.id,D).imported_assets.length,0);});
test('unknown entities, missing assignments and missing assets are rejected',()=>{assert.throws(()=>M.change(initial,'skill.invented',asset,D));assert.throws(()=>M.change(initial,first,'missing',D));const s=structuredClone(initial);delete s.assignments[first];assert.throws(()=>M.validate(s,D));});
test('wrong catalog/version and unexpected top-level fields are rejected',()=>{for(const patch of [{schema_version:99},{catalog_fingerprint:'wrong'},{unexpected:true}])assert.throws(()=>M.validate({...initial,...patch},D));});
test('remote/script content cannot enter image sources',()=>{for(const patch of [{mime:'image/svg+xml'},{data_url:'https://example.com/a.png'},{data_url:'javascript:alert(1)'},{width:4097},{bytes:4}])assert.throws(()=>M.addAssets(initial,[{...imported(),...patch}],D));});
test('oversized JSON and broken syntax rejected atomically',()=>{assert.throws(()=>M.parse('x'.repeat(M.MAX_JSON+1),D));assert.throws(()=>M.parse('{',D));assert.deepEqual(initial,M.initial(D));});
test('undo/redo includes imported images and assignments; branch clears redo',()=>{const h=new M.History(initial);h.commit(M.addAssets(h.current,[imported()],D));h.commit(M.change(h.current,first,imported().id,D));h.undo();assert.equal(h.current.imported_assets.length,1);h.undo();assert.equal(h.current.imported_assets.length,0);h.redo();assert.equal(h.current.imported_assets.length,1);h.commit(M.change(h.current,first,null,D));assert.equal(h.future.length,0);});
test('pre-pack workspace restores with only approved buff inheritance',()=>{const old=JSON.parse(fs.readFileSync(path.join(__dirname,'reports/pre-pack-workspace.json'),'utf8'));const restored=M.validate(old,D);for(const e of D.entries)assert.equal(restored.assignments[e.id],e.id==='buff.greed'?e.current_icon:old.assignments[e.icon_source||e.id]);});
test('approved export loads and buff edits update their source',()=>{const approved=M.parse(fs.readFileSync(path.join(__dirname,'approved/full_icons.json'),'utf8'),D);assert.equal(Object.values(approved.assignments).filter(Boolean).length,93);for(const e of D.entries.filter(e=>e.icon_source)){assert.equal(approved.assignments[e.id],approved.assignments[e.icon_source]);const edited=M.change(approved,e.id,asset,D);assert.equal(edited.assignments[e.icon_source],asset);assert.equal(edited.assignments[e.id],asset);}});
test('pack assets assign and export with provenance',()=>{const a=D.assets.find(a=>a.kind==='bundled');const s=M.change(initial,'buff.footwork',a.id,D);const out=M.exported(s,D);assert.equal(M.parse(JSON.stringify(out),D).assignments['buff.footwork'],a.id);assert(out.catalog_snapshot.existing_assets.find(x=>x.id===a.id).library_path);});














test('legacy migration is exact, nonmutating and preserves explicit clears',()=>{
 const old=JSON.parse(fs.readFileSync(path.join(__dirname,'reports/pre-pack-workspace.json'),'utf8'));
 old.assignments['skill.stab']=null;const before=JSON.stringify(old);
 const migrated=M.validate(old,D);assert.equal(migrated.assignments['skill.stab'],null);
 assert.equal(migrated.assignments['buff.greed'],D.entries.find(e=>e.id==='buff.greed').current_icon);
 assert.equal(JSON.stringify(old),before);
 const bad=structuredClone(old);delete bad.assignments['skill.hold'];assert.throws(()=>M.validate(bad,D));
 const extra=structuredClone(old);extra.assignments['buff.invented']=asset;assert.throws(()=>M.validate(extra,D));
 const modern=structuredClone(initial);delete modern.assignments['buff.greed'];assert.throws(()=>M.validate(modern,D));
 assert.deepEqual(M.parse(JSON.stringify(M.exported(migrated,D)),D),migrated);
});

test('pre-framing 93-entry workspace preserves prior art choices and explicit clears',()=>{
 const old=structuredClone(initial);old.catalog_fingerprint=D.compatible_fingerprints[0];
 old.assignments['skill.stab']='res://assets/ui/assigned/skills/stab.png';old.assignments['skill.hold']=null;
 const restored=M.validate(old,D);assert.equal(restored.assignments['skill.stab'],old.assignments['skill.stab']);assert.equal(restored.assignments['skill.hold'],null);
 delete old.assignments['buff.greed'];assert.throws(()=>M.validate(old,D));
});
console.log(`${checks} model/catalog checks passed.`);
