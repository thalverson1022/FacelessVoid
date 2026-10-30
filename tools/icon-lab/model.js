(function(root){
  'use strict';
  const FORMAT='facelessvoid.icon-lab', VERSION=1, MAX_IMAGE=2*1024*1024, MAX_TOTAL=20*1024*1024, MAX_JSON=30*1024*1024;
  const own=(o,k)=>Object.prototype.hasOwnProperty.call(o,k);
  const fail=m=>{throw new Error(m);};
  const obj=o=>o!==null && typeof o==='object'&&!Array.isArray(o);
  const exact=(o,keys,label)=>{if(!obj(o)||Object.keys(o).some(k=>!keys.includes(k))) fail('Invalid '+label+' fields.');};
  function initial(data){return {format:FORMAT,schema_version:VERSION,catalog_fingerprint:data.fingerprint,assignments:Object.fromEntries(data.entries.map(e=>[e.id,e.current_icon])),imported_assets:[]};}
  function validate(state,data){
    exact(state,['format','schema_version','catalog_fingerprint','assignments','imported_assets','exported_at','catalog_snapshot','changes'],'workspace');
    if(state.format!==FORMAT||state.schema_version!==VERSION) fail('Unsupported Icon Lab JSON format or version.');
    const legacy=(data.legacy_fingerprints||[]).includes(state.catalog_fingerprint);
    if(legacy && obj(state.assignments)) {
      const expected=data.entries.filter(e=>e.id!=='buff.greed').map(e=>e.id);
      if(Object.keys(state.assignments).length!==expected.length || expected.some(id=>!own(state.assignments,id))) fail('Invalid legacy assignment set.');
      state={...state,catalog_fingerprint:data.fingerprint,assignments:{...state.assignments,'buff.greed':data.entries.find(e=>e.id==='buff.greed').current_icon}};
    }
    if((data.compatible_fingerprints||[]).includes(state.catalog_fingerprint)) state={...state,catalog_fingerprint:data.fingerprint};
    if(state.catalog_fingerprint!==data.fingerprint) fail('This workspace belongs to a different catalog snapshot. Keep the file; reconcile it with this catalog before importing.');
    if(!obj(state.assignments)||Object.keys(state.assignments).length!==data.entries.length) fail('Assignments must contain all '+data.entries.length+' entries.');
    if(!Array.isArray(state.imported_assets)||state.imported_assets.length>200) fail('Invalid imported asset library (maximum 200).');
    const ids=new Set(data.assets.map(a=>a.id));let total=0;
    for(const a of state.imported_assets){
      exact(a,['id','name','mime','data_url','sha256','width','height','bytes'],'imported asset');
      if(typeof a.sha256!=='string'||!/^([a-f0-9]{64})$/.test(a.sha256)||a.id!=='import:'+a.sha256||ids.has(a.id)) fail('Invalid or duplicate asset identity.');
      if(typeof a.name!=='string'||!a.name.trim()||a.name.length>160) fail('Icon filename must be 1â€“160 characters.');
      if(!['image/png','image/jpeg','image/webp'].includes(a.mime)) fail('Only PNG, JPEG and WebP icons are supported.');
      if(typeof a.data_url!=='string'||!a.data_url.startsWith('data:'+a.mime+';base64,')) fail('Icon data must be an embedded image.');
      const b64=a.data_url.split(',')[1];
      if(!b64||b64.length%4||!/^[A-Za-z0-9+/]*={0,2}$/.test(b64)) fail('Invalid image encoding.');
      const bytes=b64.length/4*3-(b64.endsWith('==')?2:b64.endsWith('=')?1:0);
      if(!Number.isInteger(a.bytes)||a.bytes!==bytes||bytes>MAX_IMAGE||bytes<12) fail('Invalid image size (maximum 2 MB each).');
      if(!Number.isInteger(a.width)||!Number.isInteger(a.height)||a.width<1||a.height<1||a.width>4096||a.height>4096) fail('Icon dimensions must be 1â€“4096 pixels.');
      total+=bytes;ids.add(a.id);
    }
    if(total>MAX_TOTAL) fail('Imported images exceed the 20 MB workspace limit.');
    for(const e of data.entries) if(!own(state.assignments,e.id)||(state.assignments[e.id]!==null&&!ids.has(state.assignments[e.id]))) fail('Missing or unknown icon assignment for '+e.id+'.');
    // Return only authoritative fields. Export snapshots and change summaries are informational.
    const assignments={...state.assignments};
    for(const e of data.entries) if(e.icon_source) assignments[e.id]=assignments[e.icon_source];
    return {format:FORMAT,schema_version:VERSION,catalog_fingerprint:data.fingerprint,assignments,imported_assets:state.imported_assets.map(a=>({...a}))};
  }
  function parse(raw,data){if(typeof raw!=='string'||raw.length>MAX_JSON) fail('JSON exceeds the 30 MB import limit.');return validate(JSON.parse(raw),data);}
  function change(state,id,asset,data){const entry=data.entries.find(e=>e.id===id);if(!entry) fail('Unknown entry.');return validate({...state,assignments:{...state.assignments,[entry.icon_source||id]:asset}},data);}
  function addAssets(state,assets,data){const existing=new Set(state.imported_assets.map(a=>a.id));return validate({...state,imported_assets:[...state.imported_assets,...assets.filter(a=>!existing.has(a.id)&&existing.add(a.id))]},data);}
  function removeAsset(state,id,data){if(Object.values(state.assignments).includes(id)) fail('Clear or replace this iconâ€™s assignments before removing it.');return validate({...state,imported_assets:state.imported_assets.filter(a=>a.id!==id)},data);}
  const changes=(s,d)=>d.entries.filter(e=>s.assignments[e.id]!==e.current_icon).map(e=>({entity_id:e.id,name:e.name,category:e.category,from:e.current_icon,to:s.assignments[e.id]}));
  function coverage(s,d){return d.categories.map(category=>{const entries=d.entries.filter(e=>e.category===category);return {category,total:entries.length,assigned:entries.filter(e=>s.assignments[e.id]!==null).length};});}
  function exported(s,d){return {...validate(s,d),exported_at:new Date().toISOString(),catalog_snapshot:{fingerprint:d.fingerprint,library_fingerprint:d.library_fingerprint,manifest_revision:d.manifest_revision,entries:d.entries.map(e=>({id:e.id,name:e.name,category:e.category,tree:e.tree,current_icon:e.current_icon,content_status:e.content_status})),existing_assets:d.assets.map(({id,name,kind,resource_path,library_path,pack_id,sha256,width,height})=>({id,name,kind,resource_path,library_path,pack_id,sha256,width,height}))},changes:changes(s,d)};}
  class History{
    constructor(s){this.current=s;this.past=[];this.future=[];}
    commit(s){this.past.push(this.current);if(this.past.length>30)this.past.shift();this.current=s;this.future=[];}
    undo(){if(!this.past.length)return false;this.future.push(this.current);this.current=this.past.pop();return true;}
    redo(){if(!this.future.length)return false;this.past.push(this.current);this.current=this.future.pop();return true;}
  }
  const api={FORMAT,VERSION,MAX_IMAGE,MAX_TOTAL,MAX_JSON,initial,validate,parse,change,addAssets,removeAsset,changes,coverage,exported,History};
  if(typeof module!=='undefined')module.exports=api;else root.IconLabModel=api;
})(typeof window!=='undefined'?window:globalThis);
