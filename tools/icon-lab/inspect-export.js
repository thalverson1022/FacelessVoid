/* Read-only handoff verification. Never edits game assets, resources or saves. */
'use strict';
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto');
const M=require('./model'),D=require('./data/catalog.json');
const hash=b=>crypto.createHash('sha256').update(b).digest('hex');
function inspect(file){
 const stat=fs.statSync(file);if(stat.size>M.MAX_JSON)throw Error('Export exceeds 30 MB.');
 const s=M.parse(fs.readFileSync(file,'utf8').replace(/^\uFEFF/,''),D);
 for(const a of D.assets){const bytes=fs.readFileSync(path.resolve(__dirname,a.url));if(hash(bytes)!==a.sha256)throw Error('Game asset changed since catalog build: '+a.resource_path);}
 for(const a of s.imported_assets){const bytes=Buffer.from(a.data_url.split(',')[1],'base64');if(hash(bytes)!==a.sha256)throw Error('Imported asset fingerprint mismatch: '+a.name);}
 return {format:'facelessvoid.icon-lab.handoff-report',schema_version:1,catalog_fingerprint:D.fingerprint,
  validated:'Catalog, identities, embedded byte fingerprints and existing game asset fingerprints. Images are decoded during browser import.',
  entry_count:D.entries.length,imported_asset_count:s.imported_assets.length,coverage:M.coverage(s,D),changes:M.changes(s,D),
  assignments:D.entries.map(e=>({entity_id:e.id,name:e.name,category:e.category,tree:e.tree,current_icon:e.current_icon,assigned_icon:s.assignments[e.id]})),
  application:'Review mappings before applying. Skills use Skill.icon; talents/buffs and some statuses need their planned mapping consumer. This command has made no game changes.'};
}
if(require.main===module){try{if(!process.argv[2])throw Error('Usage: node tools/icon-lab/inspect-export.js <workspace.json>');process.stdout.write(JSON.stringify(inspect(path.resolve(process.argv[2])),null,2)+'\n');}catch(e){console.error(e.message);process.exitCode=1;}}
module.exports={inspect};
