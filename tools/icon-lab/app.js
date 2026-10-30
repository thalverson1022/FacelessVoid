/* No network, server or filesystem-write API. Portable workspaces use browser downloads. */
(function(){
  'use strict';
  const D=window.ICON_LAB_DATA, M=window.IconLabModel, $=id=>document.getElementById(id);
  const KEY='facelessvoid.icon-lab.workspace.v1';
  const history=new M.History(M.initial(D));
  let selected=D.entries[0].id, selectedAsset=D.entries[0].current_icon, savedRaw=null, recoveryPending=false, busy=false, storageOkay=true, unsaved=false;
  const broken=new Set();
  const state=()=>history.current;
  const allAssets=()=>[...D.assets,...state().imported_assets.map(a=>({...a,kind:'imported',group:'Imported'}))];
  const asset=id=>allAssets().find(a=>a.id===id);
  const currentEntry=()=>D.entries.find(e=>e.id===selected);
  const el=(tag,text,cls)=>{const n=document.createElement(tag);if(text!==undefined)n.textContent=text;if(cls)n.className=cls;return n;};
  function message(text,error=false){$('message').textContent=text;$('message').className=error?'error':'';}
  function icon(id,size){
    const a=asset(id);if(!a||broken.has(id)){const n=el('span',a?'!':'—','placeholder');n.title=a?'Image unavailable':'Unassigned';n.style.width=size+'px';n.style.height=size+'px';return n;}
    const img=el('img');img.src=a.kind==='imported'?a.data_url:a.url;img.alt=a.name;img.width=size;img.height=size;
    img.addEventListener('error',()=>{broken.add(id);const fallback=el('span','!','placeholder');fallback.title='Missing or unreadable image: '+a.name;img.replaceWith(fallback);message('An image could not be loaded. Check the coverage report for missing assets.',true);renderReport();},{once:true});return img;
  }
  function save(){
    unsaved=true;
    if(recoveryPending){$('save-status').textContent='Resolve saved-workspace recovery to enable autosave.';return;}
    try{localStorage.setItem(KEY,JSON.stringify(state()));storageOkay=true;unsaved=false;$('save-status').textContent='Saved in this browser';}
    catch(e){storageOkay=false;$('save-status').textContent='Local save unavailable — export JSON to keep your work.';}
  }
  function commit(next,text){history.commit(next);save();render();message(text);}
  function renderEntries(){
    const q=$('search').value.toLowerCase(), category=$('category').value,tree=$('tree').value,status=$('status-filter').value;
    const entries=D.entries.filter(e=>(!category||e.category===category)&&(!tree||e.tree===tree)&&(!q||(e.name+' '+e.description+' '+e.id).toLowerCase().includes(q))&&(!status||(status==='assigned'&&state().assignments[e.id])||(status==='unassigned'&&!state().assignments[e.id])||(status==='changed'&&state().assignments[e.id]!==e.current_icon)||(status==='m4'&&e.scope.startsWith('m4_'))));
    $('result-count').textContent=entries.length+' of '+D.entries.length+' entries';
    const items=entries.map(e=>{
      const b=el('button',undefined,'entry');b.dataset.entryId=e.id;b.setAttribute('aria-pressed',String(e.id===selected));
      const t=el('span',undefined,'thumb');t.append(icon(state().assignments[e.id],32));
      const c=el('span',undefined,'copy');c.append(el('strong',e.name),el('small',e.category+' · '+e.tree));
      b.append(t,c);if(state().assignments[e.id]!==e.current_icon)b.append(el('span','Edited','badge'));else if(!state().assignments[e.id])b.append(el('span','Empty','badge'));
      b.addEventListener('click',()=>{selected=e.id;selectedAsset=state().assignments[e.id];render();});return b;
    });$('entries').replaceChildren(...(items.length?items:[el('p','No matching entries. Try another filter.','empty')]));
  }
  function renderAssets(){
    const q=$('asset-search').value.toLowerCase(), filter=$('asset-filter').value;
    const items=allAssets().filter(a=>(!q||(a.name+' '+a.id+' '+a.group).toLowerCase().includes(q))&&(!filter||a.kind===filter||a.pack_id===filter||(filter==='unused'&&!Object.values(state().assignments).includes(a.id))));
    $('asset-count').textContent=items.length+' icons · '+state().imported_assets.length+' imported';
    $('asset-grid').replaceChildren(...(items.length?items.map(a=>{
      const b=el('button',undefined,'asset');b.dataset.assetId=a.id;b.setAttribute('aria-pressed',String(selectedAsset===a.id));b.title=a.name+' · '+a.width+'×'+a.height+' · '+a.id;
      b.append(icon(a.id,42),el('span',a.name),el('small',a.kind==='imported'?'Imported · '+a.sha256.slice(0,6):a.kind==='bundled'?(a.pack_id==='custom-variants'?'Custom variant':'Purchased pack'):'Game asset'));
      b.addEventListener('click',()=>{selectedAsset=a.id;render();});return b;
    }):[el('p','No matching icons. Import an image or change the filter.','empty')]));
  }
  function renderInspector(){
    const e=currentEntry(), assigned=state().assignments[e.id],a=asset(selectedAsset);
    $('entry-category').textContent=e.category+' / '+e.tree;$('entry-name').textContent=e.name;$('entry-id').textContent=e.id;
    $('description').textContent=e.description;$('description-source').textContent=e.description_source;$('content-status').textContent=e.icon_source?'Shares its icon with '+D.entries.find(x=>x.id===e.icon_source).name+'. Assigning here also updates that source.':e.content_status;
    $('current-preview').replaceChildren(icon(e.current_icon,64));$('assigned-preview').replaceChildren(icon(assigned,64));
    $('current-name').textContent=asset(e.current_icon)?.name||'No game icon reference';$('assigned-name').textContent=asset(assigned)?.name||'Unassigned';
    $('clear').disabled=assigned===null;$('reset-entry').disabled=assigned===e.current_icon;
    $('asset-detail').textContent=a?`${a.name} · ${a.width}×${a.height} · ${a.kind==='existing'?'Game asset':a.kind==='bundled'?(a.pack_id==='custom-variants'?'Custom variant':'Purchased pack'):'Imported'}\n${a.id}`:'Select an icon from the library to preview and assign it.';
    $('assign').disabled=!a||selectedAsset===assigned||broken.has(selectedAsset);
    $('remove-icon').disabled=!a||a.kind!=='imported'||Object.values(state().assignments).includes(a.id);
    $('remove-icon').title='Only unused imported icons can be removed.';
    $('sizes').replaceChildren(...[22,28,32,54,58,64].map(size=>{const n=el('div',undefined,'size-sample'),box=el('div',undefined,'size-box');box.append(icon(selectedAsset,size));n.append(box,el('span',size+' px'));return n;}));
    $('sizes').dataset.background=$('background').value;
    const context=el('div',undefined,'context-icon');context.append(icon(selectedAsset,58));
    const overlay=$('overlay').value;if(overlay!=='none')context.append(el('span',{rank:'3/5',stack:'3',timer:'2.4s'}[overlay],'overlay-badge'));
    $('context-preview').dataset.background=$('background').value;
    const copy=el('div');copy.append(el('strong',e.name),el('p','Selected library icon · preview only','muted'));$('context-preview').replaceChildren(context,copy);
    const users=selectedAsset?D.entries.filter(e=>state().assignments[e.id]===selectedAsset):[];
    $('used-by').replaceChildren(...(users.length?users.map(e=>{const b=el('button',e.name+' · '+e.category);b.onclick=()=>{selected=e.id;render();};return b;}):[el('p','No workspace assignments use this icon.','muted')]));
  }
  function renderReport(){
    const changes=M.changes(state(),D), missing=D.entries.filter(e=>!state().assignments[e.id]);
    const nodes=[el('p',`${missing.length} unassigned entries. ${broken.size} image load failures. ${changes.length} assignments differ from the game.`)];
    const m4=D.entries.filter(e=>e.scope.startsWith('m4_'));nodes.push(el('p',`M4 candidates: ${m4.filter(e=>state().assignments[e.id]).length}/${m4.length} assigned, including Footwork, Readiness and Dance buffs.`));
    if(broken.size)nodes.push(el('p','Missing/unreadable images: '+[...broken].join(', '),'error'));
    if(changes.length){const table=el('table'),head=el('tr');for(const label of ['Entry','Game reference','Workspace'])head.append(el('th',label));table.append(head);for(const c of changes){const row=el('tr');for(const value of [c.name+' · '+c.category,asset(c.from)?.name||'Unassigned',asset(c.to)?.name||'Unassigned'])row.append(el('td',value));table.append(row);}nodes.push(table);}
    if(missing.length){const details=el('details'),list=el('ul');details.append(el('summary','Unassigned entries ('+missing.length+')'));for(const e of missing)list.append(el('li',e.name+' · '+e.category));details.append(list);nodes.push(details);}
    $('report-body').replaceChildren(...nodes);
  }
  function render(){
    const focus=document.activeElement;const focusKey=focus?.dataset?.entryId||focus?.dataset?.assetId;const entryFocus=!!focus?.dataset?.entryId;
    const positions=[$('entries').scrollTop,$('asset-grid').scrollTop];
    for(const id of ['import-json','export','import-icons','clear','reset-entry','assign','remove-icon','undo','redo','restore','dismiss-saved'])$(id).disabled=false;
    renderEntries();renderAssets();renderInspector();renderReport();
    $('coverage').replaceChildren(...M.coverage(state(),D).map(c=>{const n=el('div',undefined,'coverage-item');n.append(el('strong',c.assigned+' / '+c.total),el('span',c.category));return n;}));
    $('change-count').textContent=M.changes(state(),D).length+' changed assignments';
    $('undo').disabled=!history.past.length;$('redo').disabled=!history.future.length;
    $('entries').scrollTop=positions[0];$('asset-grid').scrollTop=positions[1];
    if(focusKey){const buttons=(entryFocus?$('entries'):$('asset-grid')).querySelectorAll('button');[...buttons].find(b=>(entryFocus?b.dataset.entryId:b.dataset.assetId)===focusKey)?.focus({preventScroll:true});}
    if(busy)document.querySelectorAll('button').forEach(b=>b.disabled=true);
  }
  async function run(action){if(busy)return;busy=true;render();try{await action();}catch(e){message(e.message,true);}finally{busy=false;render();}}
  function download(raw,name,type='application/json'){const url=URL.createObjectURL(new Blob([raw],{type}));const a=el('a');a.href=url;a.download=name;document.body.append(a);a.click();a.remove();setTimeout(()=>URL.revokeObjectURL(url),10000);}
  function mimeOf(bytes){if(bytes[0]===137&&bytes[1]===80&&bytes[2]===78&&bytes[3]===71)return'image/png';if(bytes[0]===255&&bytes[1]===216&&bytes[2]===255)return'image/jpeg';if(String.fromCharCode(...bytes.slice(0,4))==='RIFF'&&String.fromCharCode(...bytes.slice(8,12))==='WEBP')return'image/webp';throw Error('Only valid PNG, JPEG or WebP images can be imported.');}
  async function digest(bytes){if(!globalThis.crypto?.subtle)throw Error('Image import requires Web Crypto. Open this file in a current desktop browser.');return [...new Uint8Array(await crypto.subtle.digest('SHA-256',bytes))].map(x=>x.toString(16).padStart(2,'0')).join('');}
  function dimensions(data){return new Promise((resolve,reject)=>{const img=new Image();img.onload=()=>resolve([img.naturalWidth,img.naturalHeight]);img.onerror=()=>reject(Error('Image could not be decoded.'));img.src=data;});}
  function dataUrl(bytes,mime){let s='';for(let i=0;i<bytes.length;i+=32768)s+=String.fromCharCode(...bytes.subarray(i,i+32768));return 'data:'+mime+';base64,'+btoa(s);}
  async function verifiedAsset(a){const bytes=Uint8Array.from(atob(a.data_url.split(',')[1]),c=>c.charCodeAt(0));if(mimeOf(bytes)!==a.mime||await digest(bytes)!==a.sha256)throw Error('Image fingerprint/type mismatch: '+a.name);const [w,h]=await dimensions(a.data_url);if(w!==a.width||h!==a.height)throw Error('Image dimension mismatch: '+a.name);}
  async function verifiedWorkspace(raw){const s=M.parse(raw,D);for(const a of s.imported_assets)await verifiedAsset(a);return s;}
  // Keep the assignment action visible while the longer details scroll.
  const assignmentBar=el('div',undefined,'assignment-bar');
  const oldHeading=[...document.querySelectorAll('.inspector-content h3')].find(n=>n.textContent==='Selected library icon');
  oldHeading.remove();assignmentBar.append(el('h3','Selected library icon'),$('asset-detail'));
  const assignmentActions=el('div',undefined,'actions');assignmentActions.append($('assign'),$('remove-icon'));assignmentBar.append(assignmentActions);
  document.querySelector('.inspector .panel-head').after(assignmentBar);
  for(const pack of [...new Set(D.assets.filter(a=>a.pack_id).map(a=>a.pack_id))])$('asset-filter').append(new Option(D.assets.find(a=>a.pack_id===pack).group,pack));
  for(const category of D.categories)$('category').append(new Option(category,category));
  for(const tree of [...new Set(D.entries.map(e=>e.tree))].sort())$('tree').append(new Option(tree,tree));
  for(const id of ['search','category','tree','status-filter','asset-search','asset-filter'])$(id).addEventListener('input',render);
  for(const id of ['background','overlay'])$(id).addEventListener('change',renderInspector);
  $('assign').onclick=()=>{if(!busy)commit(M.change(state(),selected,selectedAsset,D),'Assigned '+asset(selectedAsset).name+' to '+currentEntry().name+'.');};
  $('clear').onclick=()=>{if(!busy)commit(M.change(state(),selected,null,D),'Assignment cleared.');};
  $('reset-entry').onclick=()=>{if(!busy)commit(M.change(state(),selected,currentEntry().current_icon,D),'Restored this entry’s game reference.');};
  $('remove-icon').onclick=()=>{if(!busy){const next=M.removeAsset(state(),selectedAsset,D);selectedAsset=null;commit(next,'Unused imported icon removed. Undo can restore it.');}};
  $('undo').onclick=()=>{if(!busy&&history.undo()){if(!asset(selectedAsset))selectedAsset=null;save();render();message('Undone.');}};
  $('redo').onclick=()=>{if(!busy&&history.redo()){save();render();message('Redone.');}};
  $('import-icons').onclick=()=>$('icon-files').click();
  $('icon-files').onchange=()=>{const files=[...$('icon-files').files];$('icon-files').value='';if(!files.length)return;run(async()=>{
    if(files.length>200)throw Error('Import at most 200 images at once.');
    let total=state().imported_assets.reduce((s,a)=>s+a.bytes,0);const additions=[],known=new Set(allAssets().map(a=>a.sha256));let skipped=0,last=null;
    for(const f of files){if(f.size>M.MAX_IMAGE)throw Error(f.name+': maximum image size is 2 MB.');const bytes=new Uint8Array(await f.arrayBuffer()),mime=mimeOf(bytes),sha=await digest(bytes);
      if(known.has(sha)){skipped++;last=allAssets().find(a=>a.sha256===sha)?.id||additions.find(a=>a.sha256===sha)?.id;continue;}
      const url=dataUrl(bytes,mime),[width,height]=await dimensions(url);total+=bytes.length;if(total>M.MAX_TOTAL)throw Error('Imported images exceed 20 MB.');
      const a={id:'import:'+sha,name:f.name.slice(0,160),mime,data_url:url,sha256:sha,width,height,bytes:bytes.length};additions.push(a);known.add(sha);last=a.id;
    }
    const next=M.addAssets(state(),additions,D);selectedAsset=last||selectedAsset;$('asset-search').value='';$('asset-filter').value='';
    if(additions.length)commit(next,`Imported ${additions.length} icons. ${skipped} identical images reused. Select an entry and assign.`);else {render();message('All images already exist in the library; selected the matching icon.');}
  });};
  $('export').onclick=()=>{try{download(JSON.stringify(M.exported(state(),D),null,2),'icon-lab-workspace.json');message('JSON download requested. It includes assignments and all imported images. Check your downloads.');}catch(e){message(e.message,true);}};
  $('import-json').onclick=()=>$('json-file').click();
  $('json-file').onchange=()=>{const f=$('json-file').files[0];$('json-file').value='';if(!f)return;run(async()=>{if(f.size>M.MAX_JSON)throw Error('JSON exceeds 30 MB.');const next=await verifiedWorkspace(await f.text());if(!confirm('Replace the workspace with this JSON? Undo will restore the current workspace.'))return;commit(next,'Workspace imported and verified.');selectedAsset=state().assignments[selected];});};
  $('restore').onclick=()=>run(async()=>{const next=await verifiedWorkspace(savedRaw);recoveryPending=false;$('recovery').hidden=true;selectedAsset=next.assignments[selected];commit(next,'Saved workspace restored.');});
  $('download-saved').onclick=()=>download(savedRaw||'', 'icon-lab-recovery.json','application/octet-stream');
  $('dismiss-saved').onclick=()=>{if(!confirm('Replace the saved draft with this workspace? Download saved data first if you want to keep it.'))return;recoveryPending=false;$('recovery').hidden=true;save();message('Using the current workspace.');};
  window.addEventListener('beforeunload',e=>{if(unsaved && (!storageOkay||recoveryPending)){e.preventDefault();e.returnValue='';}});
  try{savedRaw=localStorage.getItem(KEY);if(savedRaw){recoveryPending=true;$('recovery').hidden=false;$('recovery-text').textContent='Restore your previous assignments and imported images, or download them before starting from game references.';$('save-status').textContent='Saved draft waiting for recovery';}else $('save-status').textContent='Local autosave ready';}catch(e){storageOkay=false;$('save-status').textContent='Browser storage unavailable — use JSON exports.';}
  render();
})();

