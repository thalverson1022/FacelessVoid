(() => {
  'use strict';
  const M=window.TreeLab,D=window.TreeLabData,$=id=>document.getElementById(id);
  const store=M.createStore(D.empty,D.schema,D.icons),key='faceless-void.tree-lab.draft.v1';
  let selected='tree',mode='edit',buffer=null,dirty=false,newNode=false,pendingRaw=null,pendingState=null;
  const uid=prefix=>prefix+'.'+(crypto.randomUUID?crypto.randomUUID():Date.now()+'-'+Math.random().toString(16).slice(2));
  const el=(tag,text,cls)=>{const n=document.createElement(tag);if(text!==undefined)n.textContent=text;if(cls)n.className=cls;return n;};
  const button=(text,fn,cls)=>{const b=el('button',text,cls);b.type='button';b.onclick=fn;return b;};
  const state=()=>store.get(),tree=()=>state().design.tree;
  function say(message,error=false){$('status').textContent=message;$('status').classList.toggle('error',error);}
  function guard(){return !dirty||window.confirm('Discard the unapplied changes in the inspector?');}
  function icon(id){const i=D.icons.find(i=>i.id===id);if(!i?.path)return el('span','◇','neutral-icon');const img=el('img');img.src=i.path;img.alt='';img.onerror=()=>img.replaceWith(el('span','◇','neutral-icon'));return img;}
  const format=n=>Number.isFinite(n)?String(Number(n.toFixed(4))):String(n);
  function valueText(item,rank,p,active=true){return item.values.map(v=>Object.hasOwn(v,'rank_1')?`${v.label}: ${rank?format(M.rankValue(v,rank))+' '+v.unit:'not allocated; rank 1: '+v.rank_1+' '+v.unit} (per rank ${v.per_rank>=0?'+':''}${v.per_rank})`:`${v.label}: ${active?format(M.pointValue(v,p))+' '+v.unit:'inactive'} (${v.per_point>=0?'+':''}${v.per_point} per tree point)`);}
  function tooltip(target,text){
    const show=()=>{const tip=$('tooltip');tip.textContent=text;tip.hidden=false;const r=target.getBoundingClientRect();tip.style.left=Math.max(8,Math.min(r.left,innerWidth-tip.offsetWidth-8))+'px';tip.style.top=Math.max(8,Math.min(r.bottom+8,innerHeight-tip.offsetHeight-8))+'px';target.setAttribute('aria-describedby','tooltip');};
    const hide=()=>{$('tooltip').hidden=true;target.removeAttribute('aria-describedby');};
    target.addEventListener('mouseenter',show);target.addEventListener('mouseleave',hide);target.addEventListener('focus',show);target.addEventListener('blur',hide);
  }
  function autosave(){
    if(pendingRaw!==null){$('save-status').textContent='Saved draft awaiting your choice; current work is not autosaved.';return;}
    try{localStorage.setItem(key,JSON.stringify({version:1,state:state()}));$('save-status').textContent='Draft saved in this browser';}
    catch(e){$('save-status').textContent='Draft not saved; export JSON to keep your work.';}
  }
  function transition(action,message){
    const before=state();
    try{action();const after=state();const removed=before.design.tree.talents.filter(n=>(before.ranks[n.id]||0)>(after.ranks[n.id]||0)).map(n=>`${n.name} −${before.ranks[n.id]-(after.ranks[n.id]||0)}`);dirty=false;newNode=false;buffer=null;autosave();render();say(message+(removed.length?' Removed ranks: '+removed.join(', ')+'. Undo restores them.':''));return true;}
    catch(e){say(e.message,true);return false;}
  }
  function select(id){if(!guard())return;selected=id;buffer=null;dirty=false;newNode=false;render();}
  function render(){
    const s=state(),t=s.design.tree,p=M.spent(s.ranks);$('tooltip').hidden=true;
    if(selected!=='tree'&&selected!=='intrinsic'&&!t.talents.some(n=>n.id===selected)&&!t.automatic_unlocks.some(n=>n.id===selected)&&!newNode)selected='tree';
    $('tree-name').textContent=t.name+' · Settings';$('points').textContent=`${p} / ${s.budget} points`;$('budget').value=s.budget;
    $('edit').setAttribute('aria-pressed',mode==='edit');$('allocate').setAttribute('aria-pressed',mode==='allocate');$('add').hidden=mode!=='edit';
    $('grid-controls').hidden=mode!=='edit';$('align-grid').disabled=!t.talents.length;
    $('mode-help').textContent=mode==='edit'?'Add a talent, or select a node to edit. Drag nodes between rows.':'Select a talent, then allocate or refund points in the inspector.';
    $('undo').disabled=!store.canUndo();$('redo').disabled=!store.canRedo();
    $('levels').replaceChildren();
    for(const l of [...t.levels].sort((a,b)=>b.order-a.order)){
      const row=el('div',undefined,'level');row.dataset.level=l.id;
      const label=button('',()=>select('tree'),'level-label');label.append(el('strong','LEVEL '+l.order),el('span',l.required_points+' tree points'),el('em',p>=l.required_points?'Open':'Locked'));row.append(label);
      const nodes=el('div',undefined,'nodes');const list=t.talents.filter(n=>n.level_id===l.id);
      if(mode==='edit'){const guides=el('div',undefined,'grid-guides');guides.setAttribute('aria-hidden','true');for(let col=0;col<M.GRID_COLUMNS;col++){const guide=el('span',undefined,'grid-guide');guide.style.left=(col/(M.GRID_COLUMNS-1)*100)+'%';if(l.order===5)guide.append(el('span',String(col+1),'grid-column-label'));guides.append(guide);}nodes.append(guides);}
      if(!list.length)nodes.append(el('div','No talents yet','empty-row'));
      for(const n of list){
        const b=button('',()=>select(n.id),'node');b.dataset.id=n.id;b.style.left=n.position.x*100+'%';
        b.classList.toggle('selected',selected===n.id);b.classList.toggle('owned',!!s.ranks[n.id]);b.classList.toggle('locked',mode==='allocate'&&!!M.reason(t,n,s.ranks,s.budget)&&!s.ranks[n.id]);
        b.append(icon(n.icon_id),el('span',n.name,'node-label'),el('span',`${s.ranks[n.id]||0} / ${n.max_ranks}`,'rank-tag'));
        tooltip(b,[n.name,n.flavour_text,n.description,`Level ${l.order}: ${l.required_points} tree points`,n.prerequisite_ids.length?'Requires 1 point in '+n.prerequisite_ids.map(id=>t.talents.find(n=>n.id===id).name).join(', '):'',...valueText(n,s.ranks[n.id]||0,p),n.skill_grant?'Unlocks '+n.skill_grant.name:''].filter(Boolean).join('\n'));
        b.draggable=mode==='edit';b.addEventListener('dragstart',e=>{if(!guard()){e.preventDefault();return;}e.dataTransfer.setData('text/plain',n.id);e.dataTransfer.effectAllowed='move';$('tooltip').hidden=true;});nodes.append(b);
      }
      row.append(nodes);row.ondragover=e=>{if(mode==='edit'){e.preventDefault();e.dataTransfer.dropEffect='move';}};
      row.ondrop=e=>{e.preventDefault();if(mode!=='edit')return;const id=e.dataTransfer.getData('text/plain'),d=state().design,n=d.tree.talents.find(n=>n.id===id);if(!n)return;const r=nodes.getBoundingClientRect();if(!r.width)return;n.level_id=l.id;const x=Math.max(0,Math.min(1,(e.clientX-r.left)/r.width));n.position.x=$('snap-grid').checked?M.snapX(x):x;selected=id;transition(()=>store.edit(d),'Talent moved.');};$('levels').append(row);
    }
    $('intrinsic').replaceChildren(el('strong',t.intrinsic.name||'Intrinsic'),el('span',valueText(t.intrinsic,0,p).join(' · ')||'Describe a bonus per invested point'));
    $('unlocks').replaceChildren();
    for(const u of [...t.automatic_unlocks].sort((a,b)=>a.order-b.order)){
      const active=!!u.skill&&p>=u.required_points,b=button('',()=>select(u.id),'unlock');b.classList.toggle('active',active);
      const copy=el('span');copy.append(el('strong',u.skill?.name||'Empty unlock slot'),el('small',u.skill?.description||'Select to describe this skill'));
      b.append(el('span',u.required_points+' pts','threshold'),icon(u.icon_id),copy,el('span',!u.skill?'Unassigned':active?'Unlocked':'Locked','state'));
      tooltip(b,[u.skill?.name||'Unassigned',u.skill?.description,...valueText(u,0,p,active)].filter(Boolean).join('\n'));$('unlocks').append(b);
    }
    inspector();const report=M.validate(s.design,D.schema,D.icons);$('warning-count').textContent=`Design notes (${report.warnings.length})`;$('warning-list').replaceChildren(...report.warnings.map(w=>el('li',w)));requestAnimationFrame(draw);
  }
  function draw(){const svg=$('connections'),bounds=$('canvas').getBoundingClientRect();svg.replaceChildren();svg.setAttribute('viewBox',`0 0 ${bounds.width} ${bounds.height}`);const buttons=[...$('levels').querySelectorAll('.node')];for(const n of tree().talents)for(const source of n.prerequisite_ids){const a=buttons.find(b=>b.dataset.id===source)?.getBoundingClientRect(),b=buttons.find(b=>b.dataset.id===n.id)?.getBoundingClientRect();if(!a||!b)continue;const x=a.left+a.width/2-bounds.left,y=a.top-bounds.top,x2=b.left+b.width/2-bounds.left,y2=b.bottom-bounds.top;const path=document.createElementNS('http://www.w3.org/2000/svg','path');path.setAttribute('d',`M${x} ${y} L${x2} ${y2} m-4 7 l4 -7 l4 7`);path.setAttribute('stroke','#77d9d0');path.setAttribute('stroke-width','2');path.setAttribute('fill','none');svg.append(path);}}
  function field(host,label,object,key,type='text',attrs={}){
    const wrap=el('label',undefined,'field'),input=el(type==='textarea'?'textarea':'input');if(type!=='textarea')input.type=type;input.value=object[key]??'';Object.assign(input,attrs);input.oninput=()=>{object[key]=type==='number'?(input.value===''?NaN:Number(input.value)):input.value;dirty=true;};wrap.append(el('span',label),input);host.append(wrap);return input;
  }
  function dropdown(host,label,object,key,options){const wrap=el('label',undefined,'field'),input=el('select');for(const o of options){const opt=el('option',o.name);opt.value=o.id;input.append(opt);}input.value=object[key];input.onchange=()=>{object[key]=input.value;dirty=true;};wrap.append(el('span',label),input);host.append(wrap);return input;}
  function valuesEditor(host,item,ranked){
    const area=el('section');host.append(area);
    function paint(){area.replaceChildren(el('h3',ranked?'Values per talent rank':'Values per tree point'));
      item.values.forEach((v,i)=>{const box=el('fieldset');box.append(el('legend','Value '+(i+1)));field(box,'Label',v,'label');field(box,'Unit (%, stacks, damage…)',v,'unit');const pair=el('div',undefined,'field-row');field(pair,ranked?'Value at rank 1':'Base value',v,ranked?'rank_1':'base','number',{step:'any'});field(pair,ranked?'Increase per extra rank':'Increase per tree point',v,ranked?'per_rank':'per_point','number',{step:'any'});box.append(pair,button('Remove value',()=>{item.values.splice(i,1);dirty=true;paint();}));area.append(box);});
      area.append(button('+ Add value',()=>{item.values.push(ranked?{id:uid('value'),label:'',unit:'%',rank_1:1,per_rank:1}:{id:uid('value'),label:'',unit:'%',base:0,per_point:1});dirty=true;paint();}));}
    paint();
  }
  function iconEditor(host,item){host.append(el('h3','Placeholder icon'));const bank=el('div',undefined,'icon-bank');for(const i of D.icons){const b=button('',()=>{item.icon_id=i.id;dirty=true;bank.querySelectorAll('button').forEach(b=>b.setAttribute('aria-pressed',b.dataset.icon===i.id));});b.dataset.icon=i.id;b.setAttribute('aria-label',i.label);b.setAttribute('aria-pressed',item.icon_id===i.id);b.title=i.label;b.append(icon(i.id));bank.append(b);}host.append(bank);}
  function prerequisites(host,n){host.append(el('h3','Prerequisites · one point each'));const search=el('input');search.type='search';search.placeholder='Find a lower-level talent';search.setAttribute('aria-label','Find prerequisite');const list=el('div',undefined,'prerequisite-list');
    function paint(){list.replaceChildren();for(const source of tree().talents.filter(s=>s.id!==n.id&&(M.level(tree(),s).order<(tree().levels.find(l=>l.id===n.level_id)?.order||1)||n.prerequisite_ids.includes(s.id))).filter(s=>s.name.toLowerCase().includes(search.value.toLowerCase()))){const lab=el('label',undefined,'check');const box=el('input');box.type='checkbox';box.checked=n.prerequisite_ids.includes(source.id);box.onchange=()=>{n.prerequisite_ids=box.checked?[...n.prerequisite_ids,source.id]:n.prerequisite_ids.filter(id=>id!==source.id);dirty=true;};lab.append(box,source.name);list.append(lab);}if(!list.childNodes.length)list.append(el('p','No matching lower-level talents.','small'));}search.oninput=paint;host.append(search,list);paint();return paint;
  }
  function inspector(){
    const host=$('inspector');host.replaceChildren();const s=state(),t=s.design.tree,n=t.talents.find(n=>n.id===selected),u=t.automatic_unlocks.find(u=>u.id===selected);
    if(!buffer)buffer=M.clone(n||u||(selected==='intrinsic'?t.intrinsic:t));
    const b=buffer;
    $('selected-name').textContent=newNode?'New talent':n?.name||u?.skill?.name||(u?'Automatic unlock '+u.order:selected==='intrinsic'?t.intrinsic.name:'Tree settings');
    $('inspector-kicker').textContent=mode==='allocate'?'ALLOCATION PREVIEW':dirty?'UNAPPLIED CHANGES':'DESIGN EDITOR';
    if(mode==='allocate'){
      const item=n||u||t.intrinsic,p=M.spent(s.ranks);host.append(el('p',n?.description||u?.skill?.description||(selected==='intrinsic'?t.intrinsic.description:'Select a talent to allocate points.')));
      if(n){const why=M.reason(t,n,s.ranks,s.budget),controls=el('div',undefined,'actions');const minus=button('− Refund',()=>transition(()=>store.allocate(n.id,-1),'Point refunded.')),plus=button('+ Allocate',()=>transition(()=>store.allocate(n.id,1),'Point allocated.'));minus.disabled=!s.ranks[n.id];plus.disabled=!!why;controls.append(minus,el('strong',`${s.ranks[n.id]||0} / ${n.max_ranks}`),plus);host.append(controls,el('p',why||'Ready to allocate.','small'));if(n.skill_grant)host.append(el('p',(s.ranks[n.id]?'Unlocked: ':'Unlocks at rank 1: ')+n.skill_grant.name));}
      for(const text of valueText(item,s.ranks[n?.id]||0,p,!u||!!u.skill&&p>=u.required_points))host.append(el('p',text,'value-row'));return;
    }
    if(selected==='tree'){
      field(host,'Tree name',b,'name');field(host,'Subclass',b,'subclass');field(host,'Design notes',b,'notes','textarea');host.append(el('h3','Talent level thresholds'));
      for(const l of [...b.levels].sort((a,b)=>a.order-b.order))field(host,'Level '+l.order+' · total points',l,'required_points','number',{min:'0',step:'1',readOnly:l.order===1});
      host.append(el('h3','Automatic unlock thresholds'));for(const a of [...b.automatic_unlocks].sort((a,b)=>a.order-b.order))field(host,'Slot '+a.order+' · total points',a,'required_points','number',{min:'0',step:'1'});
    }else if(n||newNode){
      field(host,'Name',b,'name');field(host,'Flavour text',b,'flavour_text','textarea');field(host,'Description',b,'description','textarea');field(host,'Maximum ranks',b,'max_ranks','number',{min:'1',step:'1'});
      const selectLevel=dropdown(host,'Level',b,'level_id',t.levels.map(l=>({id:l.id,name:`Level ${l.order} · ${l.required_points} points`})));const position=field(host,'Horizontal position (0 left — 1 right)',b.position,'x','number',{min:'0',max:'1',step:'any'});
      position.addEventListener('change',()=>{if($('snap-grid').checked&&Number.isFinite(b.position.x)&&b.position.x>=0&&b.position.x<=1){b.position.x=M.snapX(b.position.x);position.value=b.position.x;}});
      const repaint=prerequisites(host,b);selectLevel.addEventListener('change',repaint);valuesEditor(host,b,true);
      const grantArea=el('div');const check=el('input');check.type='checkbox';check.checked=!!b.skill_grant;const lab=el('label',undefined,'check');lab.append(check,'Grants an active skill at rank 1');host.append(lab,grantArea);
      const grant=()=>{grantArea.replaceChildren();if(b.skill_grant){field(grantArea,'Skill name',b.skill_grant,'name');field(grantArea,'Skill description',b.skill_grant,'description','textarea');}};
      check.onchange=()=>{b.skill_grant=check.checked?{id:uid('draft.skill'),name:'',description:''}:null;dirty=true;grant();};grant();iconEditor(host,b);
    }else if(u){
      field(host,'Total points required',b,'required_points','number',{min:'0',step:'1'});if(!b.skill)b.skill={id:uid('draft.skill'),name:'',description:''};field(host,'Skill name (leave blank for empty slot)',b.skill,'name');field(host,'Skill description',b.skill,'description','textarea');valuesEditor(host,b,false);iconEditor(host,b);
      host.append(button('Clear this unlock slot',()=>{b.skill=null;b.values=[];const d=state().design;d.tree.automatic_unlocks[d.tree.automatic_unlocks.findIndex(x=>x.id===selected)]=b;transition(()=>store.edit(d),'Automatic slot cleared.');}));
    }else{field(host,'Intrinsic name',b,'name');field(host,'Description',b,'description','textarea');valuesEditor(host,b,false);iconEditor(host,b);}
    const actions=el('div',undefined,'actions inspector-actions');const apply=el('button','Apply changes');apply.type='submit';actions.append(apply,button('Cancel',()=>{dirty=false;newNode=false;buffer=null;render();}));
    if(n)actions.append(button('Delete talent',()=>{const d=state().design;const affected=d.tree.talents.filter(x=>x.prerequisite_ids.includes(n.id)).map(x=>x.name);d.tree.talents=d.tree.talents.filter(x=>x.id!==n.id);d.tree.talents.forEach(x=>x.prerequisite_ids=x.prerequisite_ids.filter(id=>id!==n.id));if(transition(()=>store.edit(d),'Talent deleted.'+(affected.length?' Removed links to '+affected.join(', ')+'.':'')))selected='tree';}));host.append(actions);
    host.onsubmit=e=>{e.preventDefault();const d=state().design;let copy=M.clone(b);if(selected==='tree')d.tree=copy;else if(selected==='intrinsic')d.tree.intrinsic=copy;else if(n||newNode){if(newNode)d.tree.talents.push(copy);else d.tree.talents[d.tree.talents.findIndex(x=>x.id===selected)]=copy;}else {if(!copy.skill.name.trim()){copy.skill=null;copy.values=[];}d.tree.automatic_unlocks[d.tree.automatic_unlocks.findIndex(x=>x.id===selected)]=copy;}transition(()=>store.edit(d),'Changes applied.');};
  }
  function download(text,name){const blob=new Blob([text],{type:'application/json'}),url=URL.createObjectURL(blob),a=el('a');a.href=url;a.download=name;document.body.append(a);a.click();a.remove();setTimeout(()=>URL.revokeObjectURL(url),1000);}
  $('add').onclick=()=>{if(!guard())return;mode='edit';selected=uid('talent');buffer={id:selected,name:'',flavour_text:'',description:'',icon_id:'placeholder',level_id:tree().levels.find(l=>l.order===1).id,position:{x:.5},max_ranks:1,prerequisite_ids:[],values:[],skill_grant:null};newNode=true;dirty=true;render();$('inspector').querySelector('input')?.focus();};
  $('tree-name').onclick=()=>select('tree');$('intrinsic').onclick=()=>select('intrinsic');
  $('align-grid').onclick=()=>{if(!guard())return;const d=state().design;d.tree.talents.forEach(n=>{n.position.x=M.snapX(n.position.x);});transition(()=>store.edit(d),'All talents aligned to the nearest column. Undo restores their previous positions. Nodes sharing a column may overlap.');};
  for(const m of ['edit','allocate'])$(m).onclick=()=>{if(!guard())return;mode=m;buffer=null;dirty=false;newNode=false;render();};
  $('reset').onclick=()=>{if(guard())transition(()=>store.reset(),'Preview reset.');};
  $('budget').onchange=()=>{if(guard())transition(()=>store.budget(Number($('budget').value)),'Budget updated.');else $('budget').value=state().budget;};
  for(const action of ['undo','redo'])$(action).onclick=()=>{if(guard())transition(()=>store[action](),action==='undo'?'Change undone.':'Change reapplied.');};
  $('new').onclick=()=>{if(guard()){const d=M.clone(D.empty);d.tree.id=uid('draft');selected='tree';transition(()=>store.load(d),'Empty tree created. Undo restores the previous tree.');}};
  $('example').onclick=()=>{if(guard()){selected='tree';transition(()=>store.load(D.example),'Illustrative Assassin sketch loaded. Values are not approved balance.');}};
  $('import').onclick=()=>$('file').click();
  $('file').onchange=async()=>{const file=$('file').files[0];if(!file)return;try{if(file.size>2*1024*1024)throw Error('File exceeds the 2 MB design limit.');const d=JSON.parse(await file.text());if(!guard())return;transition(()=>store.load(d),'Imported '+file.name+'. Undo restores the previous tree.');}catch(e){say('Import failed: '+e.message,true);}finally{$('file').value='';}};
  $('export').onclick=()=>{if(dirty){say('Apply or cancel inspector changes before exporting.',true);return;}const d=state().design;const errors=M.validate(d,D.schema,D.icons).errors;if(errors.length){say(errors.join('\n'),true);return;}download(JSON.stringify(d,null,2)+'\n',(d.tree.name.replace(/[^a-z0-9_-]/gi,'_')||'tree')+'.json');say('JSON download requested. Preview allocations are not included.');};
  $('restore').onclick=()=>{if(!pendingState||!guard())return;const raw=pendingRaw;pendingRaw=null;if(transition(()=>store.restore(pendingState),'Draft restored.')){$('recovery').hidden=true;pendingState=null;}else pendingRaw=raw;};
  $('download-draft').onclick=()=>download(pendingRaw,'tree-lab-recovery.json');
  $('use-current').onclick=()=>{try{localStorage.setItem(key+'.backup',pendingRaw);pendingRaw=null;pendingState=null;$('recovery').hidden=true;autosave();say('Current tree saved. Previous draft retained as a browser backup.');}catch(e){say('Could not preserve a backup. Download the saved draft before clearing browser storage.',true);}};
  window.addEventListener('beforeunload',e=>{if(dirty){e.preventDefault();e.returnValue='';}});
  window.addEventListener('scroll',()=>{$('tooltip').hidden=true;},true);
  document.addEventListener('keydown',e=>{if(e.key==='Escape')$('tooltip').hidden=true;});
  new ResizeObserver(draw).observe($('canvas'));
  try{pendingRaw=localStorage.getItem(key);if(pendingRaw!==null){$('recovery').hidden=false;try{pendingState=M.parseDraft(pendingRaw,D.schema,D.icons);$('recovery-message').textContent='A saved draft is available. Restore it, download it, or keep the current tree instead.';}catch(e){$('restore').disabled=true;$('recovery-message').textContent='The saved draft cannot be loaded: '+e.message+' It is preserved for download.';}$('save-status').textContent='Saved draft awaiting recovery';}else $('save-status').textContent='Empty template loaded';}catch(e){$('save-status').textContent='Browser storage unavailable; use JSON export.';}
  render();
})();
