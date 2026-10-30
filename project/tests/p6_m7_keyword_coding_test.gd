extends SceneTree
const Keywords=preload("res://scripts/ui/presentation_keywords.gd")
const Rows=preload("res://scripts/ui/talent_effect_rows.gd")
const TalentHover=preload("res://scripts/ui/talent_hover_formatter.gd")
const SkillHover=preload("res://scripts/ui/skill_hover_formatter.gd")
var checks:=0
var failed:=false
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:
		failed=true
		printerr("FAILED: "+message)
func run() -> void:
	check(Keywords.normalize("base physical damage, physical damage; increased physical damage") == "Base Physical Damage, Physical Damage; Increased Physical Damage","Longest phrases preserve their distinct words")
	check(Keywords.normalize("crit chance / critical chance / CRIT DAMAGE / critical damage") == "Crit Chance / Crit Chance / Crit Damage / Crit Damage","Canonical short Crit aliases")
	check(Keywords.normalize("gold stack attack hit damage hold steal") == "gold stack attack hit damage hold steal","Ordinary prose is not globally capitalized")
	check(Keywords.normalize("footworking precision_attacks readiness2 bypassed éFootwork") == "footworking precision_attacks readiness2 bypassed éFootwork","Whole-word Unicode boundaries avoid substrings")
	check(Keywords.normalize("FOOTWORK's, precision’s; touch OF darkness, MASTER OF POISONS") == "Footwork's, Precision’s; Touch of Darkness, Master of Poisons","Possessives and resource connective casing")
	var values:=Keywords.runs("virulent poison; poison; potency; penetration; Footwork; quick cut")
	var by_id: Dictionary={}
	for value in values:
		if value.id!="": by_id[value.id]=value
	check(by_id.has("buff.virulent_poison") and by_id["buff.virulent_poison"].text=="Virulent Poison","Longest buff name before contained status")
	for id in ["status.poison","status.potency","status.penetration"]: check(by_id[id].color==Keywords.BASIC,id+" is a cream status")
	check(by_id["buff.footwork"].color==Color("9ED5EF") and Keywords.BUFF_COLOR==preload("res://scripts/ui/skill_category_preview_style.gd").COLORS[Skill.Category.SELF_BUFF],"Buff cyan exactly matches existing Self Buff color")
	var skill_found:=false
	for value in values:
		if value.text=="Quick Cut": skill_found=value.kind=="skill" and value.color==Keywords.BASIC
	check(skill_found,"Skill references remain cream")
	check(Keywords.runs("Shred")[0].id=="status.shred","Ambiguous catalog Shred resolves to status")
	var gold:=Rows.text_runs({"key":"test","label":"footwork","value":"-20%"})
	check(gold[0].color==Keywords.BUFF_COLOR and gold[-1].color==Rows.GOLD and gold[-1].text=="-20%","Gold value precedence preserves signed numbers")
	var unlock:=Rows.text_runs({"key":"unlock_skill.master_of_poisons","label":"Unlocks Master of Poisons","value":""})
	for value in unlock: check(value.color==Keywords.BASIC,"Skill unlock reference remains cream")
	var literal:=Rows.make_row({"key":"test","label":"[i]footwork[/i]","value":"x10%"},20,280,480)
	check(literal.get_parsed_text()=="[i]Footwork[/i]: x10%" and not literal.bbcode_enabled,"Safe rich literal text does not introduce italics or parse markup")
	literal.free()
	var registry:=BuildContentRegistry.test_mode()
	var ranks_seen:=0
	for talent in registry.talents.values():
		for rank in range(1,talent.max_ranks+1):
			ranks_seen+=1
			for item in TalentHover.rank_rows(talent,rank):
				check(item.label==Keywords.normalize(item.label),talent.id+" normalized live rank")
				var assembled:=""
				for value in Rows.text_runs(item):
					assembled+=value.text
					check(value.color in [Keywords.BASIC,Keywords.BUFF_COLOR,Rows.GOLD],talent.id+" controlled palette")
				check(assembled==TalentHover.row_text(item),talent.id+" rich/plain parity")
	check(ranks_seen==140,"All140 live talent ranks")
	var skills: Dictionary={}
	for character in registry.classes.values():
		for skill in character.base_skills: skills[skill.id]=skill
	for tree in registry.trees.values():
		for talent in tree.talents:
			for skill in talent.unlocked_skills: skills[skill.id]=skill
		for point in tree.automatic_unlocks:
			if point.skill!=null: skills[point.skill.id]=point.skill
	for skill in skills.values():
		var model:=SkillHover.model(skill)
		check(model.effect==Keywords.normalize(model.effect),skill.id+" normalized useful effect")
		var owner:=Control.new()
		var panel: Control=preload("res://scripts/ui/skill_hover_panel.gd").build(owner,model)
		var body: RichTextLabel=panel.find_child("SkillHoverEffect",true,false)
		check(body==null if model.effect=="" else body!=null and body.get_parsed_text()==model.effect,skill.id+" actual rich/plain effect parity")
		check(panel.find_child("SkillHoverCategory",true,false).get_theme_color("font_color")==model.color,skill.id+" original category color")
		panel.free()
		owner.free()
	check(skills.size()==23,"All23 live skills")
	DirAccess.make_dir_recursive_absolute("res://reports/keyword_glossary")
	SaveSystem.write_json("res://reports/keyword_glossary/entries.json",{"entries":Keywords.entries()})
	print("PASS keyword coding checks: ",checks)
	quit(1 if failed else 0)
