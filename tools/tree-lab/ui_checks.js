// DOM integration tests. Supply jsdom through NODE_PATH; no browser/runtime dependency.
const {JSDOM}=require('jsdom');
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const root=__dirname,read=p=>fs.readFileSync(path.join(root,p),'utf8');
const key='faceless-void.tree-lab.draft.v1';
let count=0;
function test(name,fn){fn();console.log('PASS '+name);count++;}
function app(raw,deny=false){
  const errors=[];
  const dom=new JSDOM(read('index.html'),{url:'https://tree-lab.test/',runScripts:'outside-only',pretendToBeVisual:true});
  const w=dom.window;w.ResizeObserver=class{observe(){}};w.confirm=()=>true;w.URL.createObjectURL=()=> 'blob:test';w.URL.revokeObjectURL=()=>{};w.HTMLAnchorElement.prototype.click=function(){};
  w.addEventListener('error',e=>errors.push(e.error));
  if(raw!==undefined)w.localStorage.setItem(key,raw);
  if(deny)Object.defineProperty(w,'localStorage',{get(){throw Error('Storage denied');}});
  for(const f of ['data/bundle.js','model.js','app.js'])w.eval(read(f));
  const doc=w.document;
  const click=text=>{const b=[...doc.querySelectorAll('button')].find(b=>b.textContent.trim()===text);assert.ok(b,'Missing button '+text);assert.equal(b.disabled,false,'Disabled button '+text);b.click();};
  const field=(label,value)=>{const lab=[...doc.querySelectorAll('#inspector label.field')].find(l=>l.querySelector('span')?.textContent===label);assert.ok(lab,'Missing field '+label);const input=lab.querySelector('input,textarea,select');input.value=String(value);input.dispatchEvent(new w.Event(input.tagName==='SELECT'?'change':'input',{bubbles:true}));};
  const save=()=>click('Apply changes');
  const state=()=>JSON.parse(w.localStorage.getItem(key)).state;
  return {w,doc,click,field,save,state,errors,close:()=>dom.window.close()};
}
const a=app(),{w,doc,click,field,save,state}=a;
test('Empty first launch contains five upper levels and five empty unlocks',()=>{assert.equal(doc.querySelectorAll('.level').length,5);assert.equal(doc.querySelectorAll('.node').length,0);assert.equal(doc.querySelectorAll('.unlock').length,5);});
// Recreate the free-position source sketch exactly; grid workflows are checked below.
doc.querySelector('#snap-grid').click();
const example=JSON.parse(read('examples/assassin-sketch.json'));
test('Author all ten Assassin talents using production inspector controls',()=>{
  field('Tree name','Assassin');field('Subclass','Assassin');field('Design notes',example.tree.notes);save();
  const ids={};
  for(const n of example.tree.talents){
    click('+ Add talent');field('Name',n.name);field('Flavour text',n.flavour_text);field('Description',n.description);field('Maximum ranks',n.max_ranks);field('Level',n.level_id);field('Horizontal position (0 left — 1 right)',n.position.x);
    for(const p of n.prerequisite_ids){const target=example.tree.talents.find(n=>n.id===p).name;const label=[...doc.querySelectorAll('label.check')].find(l=>l.textContent===target);assert.ok(label);label.querySelector('input').click();}
    for(const v of n.values){click('+ Add value');const boxes=doc.querySelectorAll('fieldset'),box=boxes[boxes.length-1];for(const [label,value] of [['Label',v.label],['Unit (%, stacks, damage…)',v.unit],['Value at rank 1',v.rank_1],['Increase per extra rank',v.per_rank]]){const input=[...box.querySelectorAll('label')].find(l=>l.querySelector('span').textContent===label).querySelector('input');input.value=String(value);input.dispatchEvent(new w.Event('input',{bubbles:true}));}}
    if(n.skill_grant){const checkbox=[...doc.querySelectorAll('label.check')].find(l=>l.textContent.includes('Grants an active skill')).querySelector('input');checkbox.click();field('Skill name',n.skill_grant.name);field('Skill description',n.skill_grant.description);}
    const icon=doc.querySelector(`[data-icon="${n.icon_id}"]`);icon.click();save();assert.equal(doc.querySelector('#status').classList.contains('error'),false,doc.querySelector('#status').textContent);
    const actual=state().design.tree.talents.find(x=>x.name===n.name);ids[n.id]=actual.id;
    assert.equal(actual.description,n.description);assert.equal(actual.max_ranks,n.max_ranks);assert.equal(actual.position.x,n.position.x);assert.equal(actual.icon_id,n.icon_id);assert.deepEqual(actual.prerequisite_ids,n.prerequisite_ids.map(id=>ids[id]));assert.deepEqual(actual.values.map(({id,...rest})=>rest),n.values.map(({id,...rest})=>rest));
  }
  assert.equal(doc.querySelectorAll('.node').length,10);
});
test('Author intrinsic and four lower skills; fifth remains empty',()=>{
  doc.querySelector('#intrinsic').click();field('Intrinsic name',example.tree.intrinsic.name);field('Description',example.tree.intrinsic.description);click('+ Add value');field('Label','Increased poison damage');field('Unit (%, stacks, damage…)','%');field('Base value',0);field('Increase per tree point',1);save();
  for(let i=0;i<4;i++){doc.querySelectorAll('.unlock')[i].click();const skill=example.tree.automatic_unlocks[i].skill;field('Skill name (leave blank for empty slot)',skill.name);field('Skill description',skill.description);save();}
  assert.equal(state().design.tree.automatic_unlocks.filter(u=>u.skill).length,4);assert.equal(state().design.tree.automatic_unlocks[4].skill,null);
});
test('Allocation updates both tracks; refund cascades and Undo restores',()=>{
  click('Allocate');[...doc.querySelectorAll('.node')].find(n=>n.querySelector('.node-label').textContent==='Quick Hands').click();for(let i=0;i<3;i++)click('+ Allocate');assert.match(doc.querySelector('#points').textContent,/3 \/ 15/);assert.equal(doc.querySelectorAll('.unlock.active').length,2);
  [...doc.querySelectorAll('.node')].find(n=>n.querySelector('.node-label').textContent==='Hastened Poison').click();click('+ Allocate');[...doc.querySelectorAll('.node')].find(n=>n.querySelector('.node-label').textContent==='Quick Hands').click();click('− Refund');assert.match(doc.querySelector('#points').textContent,/2 \/ 15/);click('Undo');assert.match(doc.querySelector('#points').textContent,/4 \/ 15/);
});
test('Name text is rendered safely, bad edit is atomic, delete removes links and Undo restores',()=>{
  click('Edit');[...doc.querySelectorAll('.node')].find(n=>n.querySelector('.node-label').textContent==='Hastened Poison').click();field('Level','level.5');save();assert.equal(doc.querySelector('#status').classList.contains('error'),true);assert.equal(state().design.tree.talents.find(n=>n.name==='Hastened Poison').level_id,'level.2');click('Cancel');
  click('Delete talent');assert.ok(!state().design.tree.talents.find(n=>n.name==='Hastened Poison'));assert.equal(state().design.tree.talents.find(n=>n.name==='Accelerant').prerequisite_ids.length,0);click('Undo');assert.equal(state().design.tree.talents.find(n=>n.name==='Accelerant').prerequisite_ids.length,1);
  click('+ Add talent');field('Name','<img src=x onerror=alert(1)>');save();assert.ok(doc.querySelector('.node-label').textContent);assert.equal(doc.querySelectorAll('img[onerror]').length,0);click('Undo');
});
test('Export requests a design-only JSON download',()=>{let exported;w.Blob=class{constructor(parts){exported=parts.join('');}};click('Export JSON');const d=JSON.parse(exported);assert.deepEqual(d,state().design);assert.equal(d.ranks,undefined);});
const saved=w.localStorage.getItem(key);
test('Restore preserves layout, prerequisites, effects and preview',()=>{const b=app(saved);assert.equal(b.doc.querySelectorAll('.node').length,0);b.click('Restore draft');assert.deepEqual(b.state(),state());assert.equal(b.doc.querySelectorAll('.node').length,10);assert.equal(b.errors.length,0);b.close();});
test('Corrupt recovery cannot be silently overwritten',()=>{const b=app('{broken');assert.equal(b.doc.querySelector('#restore').disabled,true);b.click('Assassin example');assert.equal(b.w.localStorage.getItem(key),'{broken');b.click('Keep current tree instead');assert.equal(b.w.localStorage.getItem(key+'.backup'),'{broken');assert.equal(b.state().design.tree.name,'Assassin');b.close();});
test('Denied storage leaves editor and export operational',()=>{const b=app(undefined,true);b.click('Assassin example');assert.equal(b.doc.querySelectorAll('.node').length,10);assert.match(b.doc.querySelector('#save-status').textContent,/not saved/);b.click('Export JSON');assert.equal(b.errors.length,0);b.close();});
test('Grid defaults, align/undo, and toggling preserve existing designs and allocations',()=>{
  const b=app();b.click('Assassin example');const original=b.state();assert.equal(b.doc.querySelector('#snap-grid').checked,true);assert.equal(b.doc.querySelectorAll('.grid-guide').length,105);
  b.doc.querySelector('#snap-grid').click();b.doc.querySelector('#snap-grid').click();assert.deepEqual(b.state(),original);
  b.click('Allocate');assert.equal(b.doc.querySelector('#grid-controls').hidden,true);assert.equal(b.doc.querySelectorAll('.grid-guide').length,0);
  [...b.doc.querySelectorAll('.node')].find(n=>n.querySelector('.node-label').textContent==='Quick Hands').click();b.click('+ Allocate');b.click('Edit');const before=b.state();b.click('Align all to grid');
  for(const n of b.state().design.tree.talents)assert.ok(Math.abs(n.position.x*20-Math.round(n.position.x*20))<1e-10);
  assert.deepEqual(b.state().ranks,before.ranks);b.click('Undo');assert.deepEqual(b.state(),before);b.close();
});
test('Numeric movement and drop use shared snapping; free mode and unrelated edits retain positions',()=>{
  const b=app();b.click('Assassin example');const first=()=>b.state().design.tree.talents.find(n=>n.name==='Quick Hands');
  [...b.doc.querySelectorAll('.node')].find(n=>n.querySelector('.node-label').textContent==='Quick Hands').click();b.field('Description','Changed description only');b.save();assert.equal(first().position.x,.34);
  b.field('Horizontal position (0 left — 1 right)',.41);const pos=[...b.doc.querySelectorAll('label.field')].find(l=>l.textContent.includes('Horizontal position')).querySelector('input');pos.dispatchEvent(new b.w.Event('change',{bubbles:true}));b.save();assert.equal(first().position.x,.4);
  function drop(x,level='level.1'){const row=[...b.doc.querySelectorAll('.level')].find(r=>r.dataset.level===level);row.querySelector('.nodes').getBoundingClientRect=()=>({left:100,width:600});row.ondrop({preventDefault(){},dataTransfer:{getData:()=>first().id},clientX:100+x*600});}
  drop(.72);assert.equal(first().position.x,.7);b.doc.querySelector('#snap-grid').click();drop(.72);assert.equal(first().position.x,.72);
  b.field('Horizontal position (0 left — 1 right)',.41);b.save();assert.equal(first().position.x,.41);assert.equal(b.errors.length,0);b.close();
});
(async()=>{
  const input=doc.querySelector('#file');const before=state();Object.defineProperty(input,'files',{configurable:true,value:[{name:'bad.json',size:7,text:async()=>'{broken'}]});await input.onchange();assert.deepEqual(state(),before);console.log('PASS malformed import is atomic');count++;
  Object.defineProperty(input,'files',{configurable:true,value:[{name:'roundtrip.json',size:1000,text:async()=>JSON.stringify(before.design)}]});await input.onchange();assert.deepEqual(state().design,before.design);assert.deepEqual(state().ranks,{});console.log('PASS actual import round-trip preserves authored tree');count++;
  assert.deepEqual(a.errors,[]);a.close();console.log(`${count} DOM integration checks passed.`);
})().catch(e=>{console.error(e);process.exitCode=1;a.close();});
