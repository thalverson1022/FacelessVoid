extends RefCounted
## Compact live talent presentation; complete mechanics remain in ranked_talent_view.effects.
const Keywords=preload("res://scripts/ui/presentation_keywords.gd")
const Catalog = preload("res://scripts/systems/stat_catalog.gd")
const Poison = preload("res://scripts/systems/p6_poison_contracts.gd")
const Assassin = preload("res://scripts/systems/assassin_passives.gd")
const BASIC = CardStyle.STAT_COLOR_BASIC
const SPECIAL = CardStyle.STAT_COLOR_SPECIAL
const PENALTY = CardStyle.STAT_COLOR_DRAWBACK
const LABELS := {
	"base_damage":"Base physical damage", "percent_physical_damage":"Physical damage",
	"increased_attack_speed":"Attack speed", "crit_chance":"Critical chance", "crit_damage":"Critical damage",
	"base_elemental_damage":"Base elemental damage", "percent_elemental_damage":"Elemental damage",
	"shred_value":"Armor decrease per Shred stack", "bonus_shred_stacks":"Additional Shred stacks",
	"increased_all_stacks":"Additional stacks per application", "increased_gold":"Increased Gold",
	"shop_discount":"Shop discount", "increased_magic_find":"Magic Find",
}

static func intrinsic_override(tree: SubclassTree) -> String:
	if tree.id!="tree.thief": return ""
	for modifier in tree.innate_modifiers:
		if Catalog.canonical_id_for_modifier(modifier)==Catalog.INCREASED_GOLD:
			return "x"+number(modifier.value*100)+"% Increased Gold"
	return ""

static func model(talent: Talent, tree: SubclassTree, build) -> Dictionary:
	var rank: int = build.rank_of(talent.id)
	var current := rank_rows(talent,rank) if rank > 0 else []
	var candidate := rank_rows(talent,rank+1) if rank < talent.max_ranks else []
	var base := []
	var next := []
	if rank==0:
		for item in candidate:
			if item.value=="": base.append(item)
			else: next.append(item)
	else:
		next=changed_rows(current,candidate)
	return {"id":talent.id,"name":talent.display_name,"icon":talent.icon,"tree":tree.display_name,
		"rank":rank,"max":talent.max_ranks,"base_rows":base,"current_rows":current,"next_rows":next,
		"maxed":rank==talent.max_ranks,"requires":""}

static func changed_rows(current: Array,candidate: Array) -> Array:
	var existing: Dictionary={}
	for item in current: existing[item.key]=item
	var changed:=[]
	for item in candidate:
		var previous: Dictionary=existing.get(item.key,{})
		if previous.is_empty() or previous.label!=item.label or previous.value!=item.value:
			changed.append(item)
	return changed

static func plain_text(data: Dictionary) -> String:
	var lines: PackedStringArray=[data.name,"%s | Rank %d/%d" % [data.tree,data.rank,data.max]]
	for item in data.base_rows: lines.append(row_text(item))
	for item in data.current_rows: lines.append(row_text(item))
	if not data.next_rows.is_empty():
		if not data.base_rows.is_empty() or not data.current_rows.is_empty(): lines.append("")
		lines.append("Next rank:")
		for item in data.next_rows: lines.append(row_text(item))
	return "\n".join(lines)

static func row_text(item: Dictionary) -> String:
	return item.label + (": " + item.value if item.value != "" else "")

static func row(key: String, label: String, value: String = "", color: Color = BASIC) -> Dictionary:
	return {"key":key,"label":Keywords.normalize(label),"value":value,"color":color}
static func number(value: float) -> String:
	return String.num(value,3).trim_suffix("0").trim_suffix("0").trim_suffix("0").trim_suffix(".")
static func signed(value: float, percent: bool = false) -> String:
	return ("+" if value>=0 else "") + number(value*100 if percent else value) + ("%" if percent else "")

static func rank_rows(talent: Talent, rank: int) -> Array:
	var data: TalentRank=talent.ranks[rank-1]
	var rows := []
	for modifier in data.stat_modifiers:
		var id: String=Catalog.canonical_id_for_modifier(modifier)
		if data.dusk_strike_enabled and id==Catalog.SHRED_VALUE: continue
		if Catalog.is_binary(id):
			rows.append(row(id,LABELS.get(id,Catalog.label_for(id)),"",SPECIAL))
			continue
		var kind: String=Catalog.value_kind_for(id)
		var percentage: bool=kind in [Catalog.VALUE_PERCENT,Catalog.VALUE_CHANCE]
		var color: Color=PENALTY if modifier.is_drawback else SPECIAL if Catalog.is_special(id) else BASIC
		# Toxic Tradeoff is a physical penalty even if an older resource omitted its drawback flag.
		if data.toxic_tradeoff_rank>0 and id==Catalog.PERCENT_PHYSICAL_DAMAGE: color=PENALTY
		var value:=modifier.value
		if kind==Catalog.VALUE_MULTIPLIER:
			value-=1.0
			percentage=true
		var display_value:=signed(value,percentage)
		if (talent.id=="talent.bladedancer.weapon_master" and id==Catalog.PERCENT_PHYSICAL_DAMAGE) or talent.id in ["talent.keen_eye","talent.sticky_fingers","talent.shadow.deception"]:
			display_value="x"+number(value*100)+"%"
		var display_label: String="Increased stacks" if talent.id=="talent.shadow.death_touch" and id==Catalog.INCREASED_ALL_STACKS else LABELS.get(id,Catalog.label_for(id))
		rows.append(row(id,display_label,display_value,color))
	if data.hastened_poison_rank>0:
		rows.append(row("hastened_rule","Poison tick rate is affected by your Attack Speed","",SPECIAL))
		rows.append(row("hastened","Percentage of Attack Speed converted to Tick Rate",number(10*data.hastened_poison_rank)+"%",SPECIAL))
	if data.accelerant_rank>0:
		rows.append(row("accelerant_rule","Apply more of your attack speed to Poison tick rate","",SPECIAL))
		rows.append(row("accelerant","Percentage of Attack Speed converted to Tick Rate",number(10*data.accelerant_rank)+"%",SPECIAL))
	if data.echoing_toxin_rank>0:
		rows.append(row("echoing_rule","Each Poison tick now consumes 2 stacks at the cost of slower tick rate","",SPECIAL))
		rows.append(row("suppression","Poison Suppression penalty","x"+number(Poison.echoing_suppression(data.echoing_toxin_rank)*100)+"%",PENALTY))
	if data.resonance_rank>0:
		rows.append(row("resonance_rule","Each tick of Poison now consumes 3 stacks but does more damage","",SPECIAL))
		rows.append(row("resonance","Increase Poison damage per stack consumed","x"+number(Poison.RESONANCE_DAMAGE_PER_RANK*data.resonance_rank*100)+"%"))
	if data.toxic_tradeoff_rank>0:
		rows.append(row("toxic","Poison damage",signed(Assassin.TOXIC_POISON_DAMAGE_PER_RANK*data.toxic_tradeoff_rank,true)))
	if data.critical_poison_enabled: rows.append(row("critical_poison","Poison can now critically hit based on your crit chance and crit damage","",SPECIAL))
	if data.bypass_enabled: rows.append(row("bypass","Stab grants 1 stack of Bypass. Bypass stacks up to 3 and lasts for 3 sec. Each stack of Bypass increases elemental damage by x10%","",SPECIAL))
	if data.death_pact_rank>0:
		rows.append(row("pact_rule","Consuming stacks of Poison or Decay grants the same number of stacks of both Penetration and Potency","",SPECIAL))
		rows.append(row("pact_duration","Increased duration of Penetration and Potency",number(3+data.death_pact_rank)+"s",SPECIAL))
	if data.death_blade_rank>0:
		rows.append(row("blade_rule","Stab can no longer apply Poison, but any application of Poison has a chance to trigger Stab","",SPECIAL))
		rows.append(row("blade_chance","Stab trigger chance",number(40*data.death_blade_rank)+"%",SPECIAL))
	if data.dusk_strike_enabled:
		var armor_decrease:=0.0
		for modifier in data.stat_modifiers:
			if Catalog.canonical_id_for_modifier(modifier)==Catalog.SHRED_VALUE: armor_decrease+=modifier.value
		rows.append(row("dusk",signed(armor_decrease)+" armor decrease per stack of Shred and when you apply Decay you also apply 1 stack of Shred","",SPECIAL))
	if data.umbral_presence_enabled: rows.append(row("umbral","Maximum Poison stacks increased from 20 to 80","",SPECIAL))
	for augment in data.skill_augments:
		if augment.poison_stacks_applied>0:
			rows.append(row("coated","Stab and Heavy Slash now apply "+number(augment.poison_stacks_applied)+" stacks of Poison","",SPECIAL))
	if data.footwork_rank>0:
		rows.append(row("footwork_rule","Quick Cut grants 1 stack of Footwork. Footwork stacks up to 5 and lasts for 3 sec. Leaping Plunge consumes all stacks of Footwork for decreased attack time.","",SPECIAL))
		rows.append(row("footwork","Decreased attack time per stack",number(4*data.footwork_rank)+"%",SPECIAL))
	if data.precision_enabled: rows.append(row("precision_attacks","Quick Cut grants Precision. Stab and Heavy Slash consume Precision to gain 100% Retrigger Chance","",SPECIAL))
	if data.riposte_rank>0:
		rows.append(row("riposte_rule","Consumed Footwork increases Leaping Plunge damage","",SPECIAL))
		rows.append(row("riposte","Plunge damage per consumed stack","x"+number(20*data.riposte_rank)+"%"))
	if data.side_step_enabled: rows.append(row("side_step","Parry Strike has 100% crit chance","",SPECIAL))
	if data.shred_cleanse_immune: rows.append(row("immune","Your Shred cannot be cleansed","",SPECIAL))
	if data.bribery_base_stacks>0:
		rows.append(row("bribery_rule","Stealing gold applies Shred"))
		rows.append(row("bribery","Shred stacks applied per successful theft",number(data.bribery_base_stacks),SPECIAL))
	if data.finders_keepers_rank>0:
		rows.append(row("finders_rule","Enemies start with less block"))
		rows.append(row("finders","Enemy starting block",signed(-0.5*data.finders_keepers_rank,true)))
	if data.gilded_blade_enabled:
		rows.append(row("gilded","Gain +1% Critical Damage per 1 gold in your stash","",SPECIAL))
		rows.append(row("gilded_cap","max","+500%"))
	if data.silvered_edge_rank>0:
		rows.append(row("silver_rule","Gold stolen in combat grants +1% crit chance","",SPECIAL))
		rows.append(row("silver_cap","Maximum critical chance from theft",signed(0.25*data.silvered_edge_rank,true),SPECIAL))
	for rule in data.stat_derivations:
		var text := ""
		var label := ""
		match rule.kind:
			"shadow_mastery":
				text="Increased Elemental Damage and Base Elemental Damage also grant Increased Physical Damage and Base Physical Damage"
				label="Percentage of Elemental converted to Physical"
			"fast_hands":
				text="Increased Gold also grants Increased Attack Speed"
				label="Percentage of Increased Gold converted to Attack Speed"
			"fill_your_pockets":
				text="Magic Find also grants Increased Elemental Damage"
				label="Percentage of Magic Find converted to Elemental Damage"
			"double_dip":
				text="Retrigger chance also grants critical chance"
				label="Percentage of Retrigger Chance converted to Crit Chance"
			"sharpened_edge": label="Stab and Heavy Slash physical damage"
		if text!="": rows.append(row(rule.kind+"_rule",text,"",SPECIAL))
		if label!="": rows.append(row(rule.kind,label,("x" if rule.kind=="sharpened_edge" else "")+number(rule.fraction*100)+"%",SPECIAL))
	for skill in talent.unlocked_skills: rows.append(row("unlock_"+skill.id,"Unlocks "+skill.display_name,"",SPECIAL))
	for trigger in data.triggered_skill_effects:
		rows.append(row("trigger_rule","Quick Cut can trigger "+trigger.skill.display_name+" on hit","",SPECIAL))
		rows.append(row("trigger_chance","Trigger chance",number(trigger.chance*100)+"%",SPECIAL))
	var benefits:=[]
	var penalties:=[]
	for item in rows:
		if item.color==PENALTY: penalties.append(item)
		else: benefits.append(item)
	var ordered:=benefits+penalties
	for item in ordered: item.color=BASIC
	return ordered

static func requirements(talent: Talent, tree: SubclassTree, build) -> String:
	var parts: PackedStringArray=[]
	var supporting:=0
	for other in tree.talents:
		if other.required_tree_points<talent.required_tree_points: supporting+=build.rank_of(other.id)
	if supporting<talent.required_tree_points:
		parts.append("%d lower-tier %s points (%d/%d)" % [talent.required_tree_points,tree.display_name,supporting,talent.required_tree_points])
	for id in talent.prerequisite_ids:
		if build.rank_of(id)<1:
			var prerequisite:=RankedBuild._talent(tree,id)
			if prerequisite!=null: parts.append("1 rank in "+prerequisite.display_name)
	return "; ".join(parts)
