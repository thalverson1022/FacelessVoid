(function(root,factory){ const api=factory(); if(typeof module==='object')module.exports=api;else root.TreeLab=api; })(typeof globalThis!=='undefined'?globalThis:this,function(){
  'use strict';
  const clone=x=>JSON.parse(JSON.stringify(x));
  const spent=r=>Object.values(r).reduce((a,b)=>a+b,0);
  const GRID_COLUMNS=21;
  const snapX=x=>Math.round(Math.max(0,Math.min(1,x))*(GRID_COLUMNS-1))/(GRID_COLUMNS-1);
  const level=(tree,n)=>tree.levels.find(l=>l.id===n.level_id);
  function validate(data,schema,icons=[]) {
    const errors=[],warnings=[];
    function walk(v,s,p) {
      if(s.$ref)return walk(v,schema.$defs[s.$ref.split('/').pop()],p);
      if(s.anyOf){if(v===null&&s.anyOf.some(s=>s.type==='null'))return;return walk(v,s.anyOf.find(s=>s.type!=='null'),p);}
      if(Object.hasOwn(s,'const')&&v!==s.const){errors.push(p+': unsupported value/version');return;}
      const t=s.type;
      if(t&&!(t==='object'?v!==null&&typeof v==='object'&&!Array.isArray(v):t==='array'?Array.isArray(v):t==='integer'?Number.isSafeInteger(v):t==='number'?typeof v==='number'&&Number.isFinite(v):typeof v===t)) {errors.push(p+': expected '+t);return;}
      if(t==='object'){
        for(const k of s.required||[])if(!Object.hasOwn(v,k))errors.push(p+'.'+k+': required');
        for(const [k,x] of Object.entries(v))if(Object.hasOwn(s.properties,k))walk(x,s.properties[k],p+'.'+k);else if(s.additionalProperties===false)errors.push(p+'.'+k+': unknown field');
      }
      if(t==='array'){
        if(v.length<(s.minItems??0)||v.length>(s.maxItems??Infinity))errors.push(p+': invalid item count');
        if(s.uniqueItems&&new Set(v.map(x=>JSON.stringify(x))).size!==v.length)errors.push(p+': duplicate entries');
        v.forEach((x,i)=>walk(x,s.items,p+'['+i+']'));
      }
      if(t==='string'&&((s.minLength&&v.trim().length<s.minLength)||(s.pattern&&!new RegExp(s.pattern).test(v))))errors.push(p+': invalid text/ID');
      if((t==='number'||t==='integer')&&(v<(s.minimum??-Infinity)||v>(s.maximum??Infinity)))errors.push(p+': outside allowed range');
    }
    walk(data,schema,'design');if(errors.length)return {errors,warnings};
    const tree=data.tree,ids=new Set();
    const register=(id,p)=>{if(['constructor','prototype','__proto__'].includes(id))errors.push(p+': reserved ID '+id);if(ids.has(id))errors.push(p+': duplicate ID '+id);ids.add(id);};
    register(tree.id,'tree.id');
    for(const [name,track] of [['levels',tree.levels],['automatic_unlocks',tree.automatic_unlocks]]) {
      const order=[...track].sort((a,b)=>a.order-b.order);
      if(order.some((x,i)=>x.order!==i+1))errors.push(name+': orders must be 1–5 exactly');
      if(order.some((x,i)=>i&&x.required_points<order[i-1].required_points))errors.push(name+': thresholds must not decrease');
      track.forEach(x=>register(x.id,name));
    }
    if(tree.levels.find(l=>l.order===1)?.required_points!==0)errors.push('levels: first level must require zero points');
    const byId=new Map(tree.talents.map(n=>[n.id,n]));
    tree.talents.forEach((n,i)=>{
      register(n.id,'talents['+i+']');
      if(!level(tree,n))errors.push(n.name+': missing level '+n.level_id);
      for(const id of n.prerequisite_ids){const source=byId.get(id);if(!source)errors.push(n.name+': missing prerequisite '+id);else if((level(tree,source)?.order??6)>=(level(tree,n)?.order??0))errors.push(n.name+': prerequisite '+source.name+' must be on a lower level');}
    });
    for(const item of [tree.intrinsic,...tree.talents,...tree.automatic_unlocks]){
      if(new Set(item.values.map(v=>v.id)).size!==item.values.length)errors.push('values: duplicate IDs');
      const skill=item.skill||item.skill_grant;if(skill)register(skill.id,'skill');
      if(Object.hasOwn(item,'skill')&&!item.skill&&item.values.length)errors.push(item.id+': blank unlock slot cannot have values');
      if(!icons.some(i=>i.id===item.icon_id))warnings.push('Unknown icon '+item.icon_id+'; neutral placeholder used.');
    }
    if(errors.length)return {errors,warnings};
    // Grant all ranks of reachable nodes to find design dead ends without rank-by-rank work.
    const reached=new Map();let changed=true;
    while(changed){changed=false;for(const n of tree.talents)if(!reached.has(n.id)&&spent(Object.fromEntries(reached))>=level(tree,n).required_points&&n.prerequisite_ids.every(id=>reached.has(id))){reached.set(n.id,n.max_ranks);changed=true;}}
    for(const n of tree.talents){if(!reached.has(n.id))warnings.push(n.name+': unreachable with this tree.');if(!n.description.trim())warnings.push(n.name+': description unfinished.');}
    const max=spent(Object.fromEntries(reached));
    for(const l of tree.levels){if(!tree.talents.some(n=>n.level_id===l.id))warnings.push('Level '+l.order+' has no talents.');if(l.required_points>max)warnings.push('Level '+l.order+' is unreachable.');}
    for(const u of tree.automatic_unlocks)if(u.skill&&u.required_points>max)warnings.push(u.skill.name+': automatic threshold unreachable.');
    for(let i=0;i<tree.talents.length;i++)for(let j=i+1;j<tree.talents.length;j++){const a=tree.talents[i],b=tree.talents[j];if(a.level_id===b.level_id&&Math.abs(a.position.x-b.position.x)<.1)warnings.push(a.name+' / '+b.name+': nodes may overlap; adjust horizontal positions.');}
    return {errors,warnings:[...new Set(warnings)]};
  }
  function reason(tree,n,r,budget){
    if((r[n.id]||0)>=n.max_ranks)return 'Maximum rank reached.';
    if(spent(r)>=budget)return 'No points remaining in the budget.';
    if(spent(r)<level(tree,n).required_points)return 'Requires '+(level(tree,n).required_points-spent(r))+' more tree points.';
    const missing=n.prerequisite_ids.filter(id=>!(r[id]>0));
    return missing.length?'Requires 1 point in '+missing.map(id=>tree.talents.find(n=>n.id===id).name).join(', ')+'.':'';
  }
  function normalize(tree,target,budget){
    const out={};let total=0,changed=true;
    const nodes=[...tree.talents].sort((a,b)=>level(tree,a).order-level(tree,b).order||a.id.localeCompare(b.id));
    while(changed&&total<budget){changed=false;for(const n of nodes){if(total>=budget)break;if((out[n.id]||0)<Math.min(target[n.id]||0,n.max_ranks)&&total>=level(tree,n).required_points&&n.prerequisite_ids.every(id=>out[id]>0)){out[n.id]=(out[n.id]||0)+1;total++;changed=true;}}}
    return out;
  }
  const rankValue=(v,r)=>r>0?v.rank_1+(r-1)*v.per_rank:null;
  const pointValue=(v,p)=>v.base+p*v.per_point;
  function createStore(data,schema,icons){
    let state={design:clone(data),ranks:{},budget:15},history=[],future=[];
    const check=d=>{const result=validate(d,schema,icons);if(result.errors.length)throw Error(result.errors.join('\n'));};
    check(data);
    function commit(next){check(next.design);if(!Number.isSafeInteger(next.budget)||next.budget<0||next.budget>10000)throw Error('Budget must be an integer from 0 to 10,000.');next.ranks=normalize(next.design.tree,next.ranks,next.budget);history.push(clone(state));if(history.length>100)history.shift();future=[];state=clone(next);return clone(state);}
    return {get:()=>clone(state),canUndo:()=>history.length>0,canRedo:()=>future.length>0,
      edit:design=>commit({...clone(state),design}),
      load:design=>commit({design,ranks:{},budget:15}),
      restore:s=>commit(s),
      allocate:(id,delta)=>{const n=state.design.tree.talents.find(n=>n.id===id);if(!n)throw Error('Talent not found.');if(delta===1){const why=reason(state.design.tree,n,state.ranks,state.budget);if(why)throw Error(why);}const next=clone(state);next.ranks[id]=Math.max(0,(next.ranks[id]||0)+delta);return commit(next);},
      budget:value=>commit({...clone(state),budget:value}),reset:()=>commit({...clone(state),ranks:{}}),
      undo:()=>{if(history.length){future.push(clone(state));state=history.pop();}return clone(state);},
      redo:()=>{if(future.length){history.push(clone(state));state=future.pop();}return clone(state);}
    };
  }
  function parseDraft(raw,schema,icons){
    const d=JSON.parse(raw);
    if(d.version!==1||!d.state)throw Error('Unsupported draft version.');
    const result=validate(d.state.design,schema,icons);if(result.errors.length)throw Error(result.errors.join('\n'));
    if(!Number.isSafeInteger(d.state.budget)||d.state.budget<0||d.state.budget>10000)throw Error('Invalid draft budget.');
    if(!d.state.ranks||typeof d.state.ranks!=='object'||Array.isArray(d.state.ranks)||Object.values(d.state.ranks).some(n=>!Number.isSafeInteger(n)||n<0))throw Error('Invalid draft allocations.');
    d.state.ranks=normalize(d.state.design.tree,d.state.ranks,d.state.budget);return d.state;
  }
  return {clone,spent,GRID_COLUMNS,snapX,level,validate,reason,normalize,rankValue,pointValue,createStore,parseDraft};
});
