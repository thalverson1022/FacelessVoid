extends RefCounted
## Presentation vocabulary only. IDs link terms to existing content, never gameplay rules.
const Catalog=preload("res://scripts/systems/stat_catalog.gd")
const EffectText=preload("res://scripts/ui/combat_effect_text.gd")
const BASIC=CardStyle.STAT_COLOR_BASIC
const BUFF_COLOR=preload("res://scripts/ui/skill_category_preview_style.gd").COLORS[Skill.Category.SELF_BUFF]
static var _entries: Array=[]
static var _by_alias: Dictionary={}
static var _matcher: RegEx

static func add_entry(id: String,name: String,kind: String,aliases: Array=[]) -> void:
	var forms: Array=[name]
	forms.append_array(aliases)
	var entry:={"id":id,"name":name,"kind":kind,"aliases":forms}
	_entries.append(entry)
	for form in forms:
		var key: String=str(form).to_lower()
		if not _by_alias.has(key): _by_alias[key]=entry

static func entries() -> Array:
	if _entries.is_empty():
		for id in ["buff.footwork","buff.precision","buff.bypass","buff.readiness","buff.dance","buff.touch_of_darkness","buff.beguiling_presence","buff.virulent_poison","buff.master_of_poisons","buff.greed","buff.meditation","buff.dash"]:
			add_entry(id,EffectText.name_for(id),"buff")
		for name in ["Poison","Shred","Decay","Potency","Penetration"]:
			add_entry("status."+name.to_lower(),name,"status")
		for id in [Catalog.BASE_DAMAGE,Catalog.PERCENT_PHYSICAL_DAMAGE,Catalog.INCREASED_ATTACK_SPEED,Catalog.CRIT_CHANCE,Catalog.CRIT_DAMAGE,Catalog.BASE_ELEMENTAL_DAMAGE,Catalog.PERCENT_ELEMENTAL_DAMAGE,Catalog.INCREASED_GOLD,Catalog.SHOP_DISCOUNT,Catalog.INCREASED_MAGIC_FIND,Catalog.INCREASED_ALL_STACKS]:
			var source: String=Catalog.label_for(id)
			var name: String=source
			add_entry("stat."+id,name,"stat",["Critical Chance"] if id==Catalog.CRIT_CHANCE else ["Critical Damage"] if id==Catalog.CRIT_DAMAGE else [])
		# Distinct existing phrases retain their own words; no generic Damage expansion.
		for name in ["Base Physical Damage","Physical Damage","Increased Physical Damage","Elemental Damage","Increased Elemental Damage","Attack Speed","Poison Damage","Poison Suppression","Armor","Resistance","Block","Absorb","Magic Find","Increased Stacks","Additional Shred Stacks","Retrigger Chance","Retrigger","Attack Time","Tick Rate","Cast Time","Trigger Chance"]:
			add_entry("phrase."+name.to_snake_case(),name,"stat")
		var registry:=BuildContentRegistry.test_mode()
		var skills: Dictionary={}
		for character in registry.classes.values():
			for skill in character.base_skills: skills[skill.id]=skill
		for tree in registry.trees.values():
			for talent in tree.talents:
				add_entry(talent.id,talent.display_name,"talent")
				for skill in talent.unlocked_skills: skills[skill.id]=skill
			for unlock in tree.automatic_unlocks:
				if unlock.skill!=null: skills[unlock.skill.id]=unlock.skill
		var buff_skills:={"buff.dance":"skill.dance_of_death","buff.touch_of_darkness":"skill.touch_of_darkness","buff.beguiling_presence":"skill.beguiling_presence","buff.virulent_poison":"skill.virulent_poison","buff.master_of_poisons":"skill.master_of_poisons"}
		for entry in _entries:
			if buff_skills.has(entry.id) and skills.has(buff_skills[entry.id]):
				entry.name=skills[buff_skills[entry.id]].display_name
				entry.aliases=[entry.name]
		for entry in _entries:
			if entry.id=="buff.dance": entry.name="Dance of Death"
			elif entry.id=="buff.touch_of_darkness": entry.name="Touch of Darkness"
			elif entry.id=="buff.master_of_poisons": entry.name="Master of Poisons"
			if entry.kind=="buff": entry.aliases=[entry.name]
		for skill in skills.values():
			# These one-word names are ordinary verbs in effect prose; their headers already use resource names.
			if skill.id in ["skill.steal","skill.hold"]: continue
			add_entry(skill.id,skill.display_name,"skill")
		var forms: Array=_by_alias.keys()
		forms.sort_custom(func(a: String,b: String): return a.length()>b.length() if a.length()!=b.length() else a<b)
		var escaped: PackedStringArray=[]
		for form in forms: escaped.append(escape_pattern(form))
		_matcher=RegEx.new()
		var error:=_matcher.compile("(?i)(?<![\\p{L}\\p{N}_])(?:"+"|".join(escaped)+")(?![\\p{L}\\p{N}_])")
		assert(error==OK,"Presentation keyword expression compiles")
	return _entries

static func escape_pattern(value: String) -> String:
	var result:=""
	for character in value:
		if character in ["\\",".","^","$","|","?","*","+","(",")","[","]","{","}"]: result+="\\"
		result+=character
	return result

static func runs(text: String,buff_color: bool=true) -> Array:
	entries()
	var result:=[]
	var cursor:=0
	for found in _matcher.search_all(text):
		if found.get_start()>cursor: result.append({"text":text.substr(cursor,found.get_start()-cursor),"color":BASIC,"id":"","kind":"text"})
		var entry: Dictionary=_by_alias[found.get_string().to_lower()]
		result.append({"text":entry.name,"color":BUFF_COLOR if buff_color and entry.kind=="buff" else BASIC,"id":entry.id,"kind":entry.kind})
		cursor=found.get_end()
	if cursor<text.length(): result.append({"text":text.substr(cursor),"color":BASIC,"id":"","kind":"text"})
	return result

static func normalize(text: String) -> String:
	var parts: PackedStringArray=[]
	for run in runs(text): parts.append(run.text)
	return "".join(parts)

static func append_runs(label: RichTextLabel,values: Array) -> void:
	for run in values:
		label.push_color(run.color)
		label.add_text(run.text)
		label.pop()
