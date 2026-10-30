(() => {
  const source = window.TREE_LAB_PREVIEW;
  const $ = id => document.getElementById(id);
  let tree, ranks = {}, selected, mode = 'edit', history = [];
  const clone = data => JSON.parse(JSON.stringify(data));
  const spent = (r = ranks) => Object.values(r).reduce((a,b) => a+b, 0);
  const budget = () => Math.max(0, Math.min(100, Math.floor(Number($('budget').value) || 0)));
  const level = node => tree.levels.find(l => l.id === node.level_id);
  function icon(id) {
    const item = source.icons.find(i => i.id === id);
    if (!item?.path) { const span = document.createElement('span'); span.className='neutral-icon'; span.textContent='◇'; return span; }
    const img = document.createElement('img'); img.src = item.path; img.alt=''; return img;
  }
  function canBuy(n, r = ranks) { return spent(r) < budget() && (r[n.id]||0) < n.max_ranks && spent(r) >= level(n).required_points && n.prerequisite_ids.every(id => (r[id]||0)>0); }
  function normalize(target) {
    const out = {};
    const ordered = [...tree.talents].sort((a,b) => level(a).order-level(b).order || a.id.localeCompare(b.id));
    let changed;
    do { changed=false; for(const n of ordered) if((out[n.id]||0)<(target[n.id]||0) && canBuy(n,out)) {out[n.id]=(out[n.id]||0)+1;changed=true;} } while(changed);
    return out;
  }
  function remember() { history.push({ranks:clone(ranks),budget:lastBudget}); }
  let lastBudget=15;
  function updatePoints(action) {
    remember(); const before=clone(ranks); action(); ranks=normalize(ranks);
    const removed=tree.talents.filter(n=>(before[n.id]||0)>(ranks[n.id]||0)).map(n=>`${n.name}: −${before[n.id]-(ranks[n.id]||0)}`);
    $('status').textContent=removed.length ? 'Refunded '+removed.join('; ')+'. Undo restores the operation.' : 'Preview updated. Design data is unchanged.';
    lastBudget=budget(); render();
  }
  function load(name) {tree=clone(source[name].tree);ranks={};selected=tree.talents[0]?.id || 'intrinsic';history=[];lastBudget=15;$('budget').value=15;$('status').textContent=tree.name+' loaded. No changes are saved.';render();}
  function render() {
    $('tree-name').textContent=tree.name;$('points').textContent=`${spent()} / ${budget()} points`;
    $('edit').setAttribute('aria-pressed',mode==='edit');$('allocate').setAttribute('aria-pressed',mode==='allocate');
    $('mode-help').textContent=mode==='edit'?'Select a talent to inspect its fields.':'Select a talent, then use + or − in the inspector.';
    $('add').hidden=mode!=='edit';$('undo').disabled=!history.length;
    $('levels').replaceChildren();
    for(const l of [...tree.levels].reverse()) {
      const row=document.createElement('div');row.className='level';
      const label=document.createElement('div');label.className='level-label';
      const title=document.createElement('strong');title.textContent='LEVEL '+l.order;label.append(title,`${l.required_points} points in tree`);
      const state=document.createElement('em');state.textContent=mode==='allocate'?(spent()>=l.required_points?'Open':'Locked'):'Editable threshold';label.append(state);row.append(label);
      const nodes=document.createElement('div');nodes.className='nodes';
      const list=tree.talents.filter(n=>n.level_id===l.id);
      if(!list.length){const empty=document.createElement('div');empty.className='empty-row';empty.textContent='No talents yet';nodes.append(empty);}
      for(const n of list) {
        const b=document.createElement('button');b.className='node';b.id='node-'+n.id;b.style.left=(n.position.x*100)+'%';
        b.classList.toggle('selected',n.id===selected);b.classList.toggle('owned',(ranks[n.id]||0)>0);b.classList.toggle('locked',mode==='allocate'&&!canBuy(n)&&!(ranks[n.id]||0));
        b.title=n.name+'\n'+n.description+'\n'+n.values.map(v=>`${v.label}: ${v.rank_1} ${v.unit} at rank 1; ${v.per_rank>=0?'+':''}${v.per_rank} each rank`).join('\n');
        b.append(icon(n.icon_id));const name=document.createElement('span');name.className='node-label';name.textContent=n.name;
        const rank=document.createElement('span');rank.className='rank-tag';rank.textContent=`${ranks[n.id]||0} / ${n.max_ranks}`;b.append(name,rank);b.onclick=()=>{selected=n.id;render();};nodes.append(b);
      }
      row.append(nodes);$('levels').append(row);
    }
    const intr=tree.intrinsic; $('intrinsic').replaceChildren(); const title=document.createElement('strong');title.textContent=intr.name;
    $('intrinsic').append(title,intr.values.length?intr.values.map(v=>`${v.label}: ${v.base+spent()*v.per_point}${v.unit}`).join(' · '):'Describe a bonus per invested point');
    $('unlocks').replaceChildren();
    for(const u of tree.automatic_unlocks){
      const b=document.createElement('button');b.className='unlock';const active=!!u.skill&&spent()>=u.required_points;b.classList.toggle('active',active);
      const threshold=document.createElement('span');threshold.className='threshold';threshold.textContent=u.required_points+' pts';
      const text=document.createElement('span'),name=document.createElement('strong'),desc=document.createElement('small');name.textContent=u.skill?.name||'Empty unlock slot';desc.textContent=u.skill?.description||'Describe this skill when ready';text.append(name,desc);
      const state=document.createElement('span');state.className='state';state.textContent=!u.skill?'Unassigned':active?'Unlocked':'Locked';b.append(threshold,icon(u.icon_id),text,state);b.onclick=()=>{selected=u.id;render();};$('unlocks').append(b);
    }
    inspector(); requestAnimationFrame(drawConnections);
  }
  function field(label,value,type='text') {
    const box=document.createElement('label');box.className='field';box.append(label);
    const input=document.createElement(type==='textarea'?'textarea':'input');if(type!=='textarea')input.type=type;input.value=value;input.readOnly=true;box.append(input);$('fields').append(box);
  }
  function dropdown(label, options, value) {
    const box=document.createElement('label');box.className='field';box.append(label);
    const input=document.createElement('select');input.disabled=true;
    for(const item of options){const option=document.createElement('option');option.value=item.id;option.textContent=item.name;input.append(option);}
    input.value=value;box.append(input);$('fields').append(box);
  }
  function inspector() {
    const n=tree.talents.find(n=>n.id===selected),u=tree.automatic_unlocks.find(u=>u.id===selected);
    const item=n||u||tree.intrinsic;
    $('selected-name').textContent=n?.name||u?.skill?.name||(u?'Empty unlock slot':tree.intrinsic.name);
    $('selected-description').textContent=n?.description||u?.skill?.description||(u?'Automatic skill details will be editable here.':tree.intrinsic.description);
    $('rank-controls').hidden=!n||mode!=='allocate';$('rank').textContent=n?`${ranks[n.id]||0} / ${n.max_ranks}`:'';
    $('plus').disabled=!n||!canBuy(n);$('minus').disabled=!n||!(ranks[n.id]||0);
    $('eligibility').textContent=n?(mode==='edit'?'Fields shown for layout review.':canBuy(n)?'Ready to allocate a point.':(ranks[n.id]||0)>=n.max_ranks?'Maximum rank.':spent()>=budget()?'No budget remaining.':spent()<level(n).required_points?`Requires ${level(n).required_points-spent()} more tree points.`:'Requires one point in each connected source.'):'Automatic benefits do not spend points.';
    $('fields').replaceChildren();field('Name',n?.name||u?.skill?.name||(!u?tree.intrinsic.name:''));
    if(n){field('Flavour text',n.flavour_text,'textarea');field('Maximum ranks',n.max_ranks,'number');dropdown('Level',tree.levels.map(l=>({id:l.id,name:`Level ${l.order} · ${l.required_points} tree points`})),n.level_id);field('Prerequisites',n.prerequisite_ids.map(id=>tree.talents.find(t=>t.id===id).name).join(', ')||'None');dropdown('Add prerequisite',[{id:'none',name:'Choose a lower-level talent'},...tree.talents.filter(t=>level(t).order<level(n).order)],'none');if(n.skill_grant)field('Unlocks skill',n.skill_grant.name);}
    if(u)field('Tree points required',u.required_points);
    for(const v of item.values){const row=document.createElement('div');row.className='value-row';const title=document.createElement('strong');title.textContent=v.label;row.append(title);row.append(n?`Rank 1: ${v.rank_1} ${v.unit} · Per rank: ${v.per_rank>=0?'+':''}${v.per_rank}`:`Base: ${v.base} · Per tree point: +${v.per_point} ${v.unit}`);const result=document.createElement('div');const active=n?(ranks[n.id]||0)>0:!u||(!!u.skill&&spent()>=u.required_points);const value=n?v.rank_1+((ranks[n.id]||1)-1)*v.per_rank:v.base+spent()*v.per_point;result.textContent=active?`Current: ${value} ${v.unit}`:`Inactive · ${n?'Next rank: '+v.rank_1+' '+v.unit:'Unlock at '+u.required_points+' points'}`;row.append(result);$('fields').append(row);}
    $('icons').replaceChildren();
    for(const i of source.icons){const b=document.createElement('button');b.title=i.label;b.setAttribute('aria-label',i.label);b.setAttribute('aria-pressed',item.icon_id===i.id);b.append(icon(i.id));b.onclick=()=>{item.icon_id=i.id;render();};$('icons').append(b);}
  }
  function drawConnections(){
    const svg=$('connections'),bounds=$('canvas').getBoundingClientRect();svg.replaceChildren();
    svg.setAttribute('viewBox',`0 0 ${bounds.width} ${bounds.height}`);
    for(const n of tree.talents)for(const id of n.prerequisite_ids){
      const a=$('node-'+id).getBoundingClientRect(),b=$('node-'+n.id).getBoundingClientRect();
      const x1=a.left+a.width/2-bounds.left,y1=a.top-bounds.top,x2=b.left+b.width/2-bounds.left,y2=b.bottom-bounds.top;
      const line=document.createElementNS('http://www.w3.org/2000/svg','path');line.setAttribute('d',`M ${x1} ${y1} L ${x2} ${y2} m -4 7 l 4 -7 l 4 7`);line.setAttribute('stroke','#77d9d0');line.setAttribute('fill','none');line.setAttribute('stroke-width','2');svg.append(line);
    }
  }
  $('edit').onclick=()=>{mode='edit';render();};$('allocate').onclick=()=>{mode='allocate';render();};
  $('sample').onclick=()=>load('assassin');$('empty').onclick=()=>load('empty');
  $('intrinsic').onclick=()=>{selected='intrinsic';render();};
  $('plus').onclick=()=>updatePoints(()=>{ranks[selected]=(ranks[selected]||0)+1;});
  $('minus').onclick=()=>updatePoints(()=>{ranks[selected]=Math.max(0,(ranks[selected]||0)-1);});
  $('reset').onclick=()=>updatePoints(()=>{ranks={};});
  $('budget').onchange=()=>{$('budget').value=budget();updatePoints(()=>{});};
  $('undo').onclick=()=>{const old=history.pop();if(!old)return;ranks=old.ranks;$('budget').value=old.budget;lastBudget=old.budget;$('status').textContent='Point change undone.';render();};
  new ResizeObserver(drawConnections).observe($('canvas'));
  load('assassin');
})();
