extends SceneTree
const Hover = preload("res://scripts/ui/skill_hover_formatter.gd")
const View = preload("res://scripts/ui/ranked_talent_view.gd")
class Context extends RefCounted:
	var selected_class: ClassDef
	var stats := PlayerStats.new()
	var is_test_mode := true
	func current_player_stats() -> PlayerStats: return stats
var failed := false
var checks := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failed = true
		printerr("FAILED: "+message)
func find_skill_buttons(node: Node) -> Array:
	var result := []
	if node is IconTooltipButton and node.skill_hover_provider.is_valid(): result.append(node)
	for child in node.get_children(): result.append_array(find_skill_buttons(child))
	return result
func run() -> void:
	var registry := BuildContentRegistry.test_mode()
	var context := Context.new()
	context.selected_class=registry.classes["class.rogue"]
	context.stats.weapon_damage_min=100
	context.stats.weapon_damage_max=100
	context.stats.physical_damage_multiplier=1.0
	context.stats.bonus_physical_damage=0
	var skills := {}
	for skill in context.selected_class.base_skills: skills[skill.id]=skill
	for tree in registry.trees.values():
		for talent in tree.talents:
			for skill in talent.unlocked_skills: skills[skill.id]=skill
		for unlock in tree.automatic_unlocks:
			if unlock.skill!=null: skills[unlock.skill.id]=unlock.skill
	check(skills.size()==23,"All23 skills")
	for skill in skills.values():
		var data := Hover.model(skill,context)
		var text := Hover.plain_text(data)
		check(text.contains(skill.display_name) and data.cast in ["Fast","Normal","Slow","Brief"],skill.id+" header")
		check(data.damage!="" or data.effect!="",skill.id+" useful content")
		if skill.category == Skill.Category.ATTACK:
			check(data.cooldown=="" and data.duration=="",skill.id+" attack omits timing rows")
		else:
			check(data.cooldown.begins_with("Cooldown: ") and (data.duration=="" if skill.id in ["skill.pick_pocket","skill.virulent_poison","skill.poison_vile"] else data.duration.begins_with("Duration: ")),skill.id+" separate timing rows except approved duration omissions")
		check(not data.effect.contains("Cooldown:") and not data.effect.contains("Duration:"),skill.id+" effect excludes timing labels")
		for clutter in ["111%","shared cooldown","cap ","Slot ","Live stash","Unlocked by","before child","%d","%s","%.0f","charge"]:
			check(not text.contains(clutter),skill.id+" minimal "+clutter)
		if skill.category!=Skill.Category.ATTACK: check(data.damage=="",skill.id+" no direct damage")
		context.set_meta("category_preview",false)
		check(Hover.model(skill,context)==data,skill.id+" category override cannot Bypass")
		context.set_meta("category_preview",true)
	check(Hover.model(skills["skill.parry_strike"],context).effect=="Requires and consumes Readiness. Readiness is granted by any skill Retrigger","Parry explains Readiness requirement and source")
	check(Hover.model(skills["skill.dance_of_death"],context).effect=="The first hit of all attacks have 100% Retrigger Chance","Dance first-hit Retrigger scope")
	check(Hover.model(skills["skill.virulent_poison"],context).effect=="Next 5 ticks of Poison deal 2x damage","Virulent stack count and multiplier retained")
	check(Hover.model(skills["skill.venom_jab"],context).damage=="22-22 damage","Venom weapon scaling")
	check(Hover.model(skills["skill.venom_jab"],context).effect=="On hit: Apply 5 stacks of Poison","Venom basic count")
	context.stats.bonus_poison_stacks=2
	check(Hover.model(skills["skill.venom_jab"],context).effect=="On hit: Apply 7 stacks of Poison","Venom current build stacks")
	context.stats.bonus_poison_stacks=0
	check(Hover.model(skills["skill.killers_mark"],context).damage=="111-111 damage","Death planning zero Poison")
	check(Hover.model(skills["skill.killers_mark"],context).effect.contains("+2 Base Physical Damage"),"Death base before scaling")
	check(Hover.model(skills["skill.pick_pocket"],context).effect=="Steals 10 gold","Credited theft baseline without trailing period")
	check(Hover.model(skills["skill.mug"],context).effect=="+1 Base Physical Damage per gold stolen in combat","Approved Mug text")
	check(Hover.model(skills["skill.pick_pocket"],context).cooldown=="Cooldown: 8s","Pick Pocket cooldown")
	check(Hover.model(skills["skill.touch_of_darkness"],context).cooldown=="Cooldown: 30s","Touch cooldown")
	check(Hover.model(skills["skill.stab"],context).cooldown=="","Attack has no cooldown row")
	check(Hover.model(skills["skill.poison_vile"],context).cooldown=="Cooldown: None","Debuff without cooldown explicit")
	check(Hover.model(skills["skill.pick_pocket"],context).duration=="","Pick Pocket duration omitted")
	check(Hover.model(skills["skill.virulent_poison"],context).duration=="","Virulent duration omitted")
	check(Hover.model(skills["skill.poison_vile"],context).duration=="","Vile duration omitted")
	check(Hover.model(skills["skill.master_of_poisons"],context).duration=="Duration: 5s","Timed Resistance ignore")
	check(Hover.model(skills["skill.blinding_powder"],context).duration=="Duration: 3s","Potency baseline lifetime")
	check(Hover.model(skills["skill.master_of_poisons"],context).effect=="Elemental Damage ignores Resistance","Approved Master wording")
	context.stats.assassin_tree_points=10
	check(Hover.model(skills["skill.blinding_powder"],context).effect=="Apply 10 stacks of Potency","Blinding baseline live count")
	context.stats.bonus_potency_stacks=3
	check(Hover.model(skills["skill.blinding_powder"],context).effect=="Apply 13 stacks of Potency","Blinding bonus count remains live")
	context.stats.bonus_potency_stacks=0
	context.stats.assassin_tree_points=0
	context.stats.death_pact_rank=3
	check(Hover.model(skills["skill.blinding_powder"],context).duration=="Duration: 6s","Potency current-build lifetime")
	context.stats.death_pact_rank=0
	context.stats.gold_reward_multiplier=1.55
	check(Hover.model(skills["skill.pick_pocket"],context).effect=="Steals 15 gold","Theft floors current build")
	check(Hover.model(skills["skill.big_score"],context).effect=="Critical hits from this skill are increased by 6x","Source-backed Big Score factor")
	check(Hover.model(skills["skill.touch_of_darkness"],context).duration=="Duration: 12s" and not Hover.model(skills["skill.touch_of_darkness"],context).effect.contains("12s"),"Touch duration separate")
	check(Hover.model(skills["skill.beguiling_presence"],context).effect=="Consume all stacks of Decay. Each stack consumed grants +1 Base Elemental Damage","Beguiling concise base bonus, crit omitted")
	check(Hover.model(skills["skill.touch_of_darkness"],context).effect=="Consume all stacks of Poison. Each stack consumed grants x10% Attack Speed and +2 Base Physical Damage","Touch concise bonuses")
	check(not Hover.model(skills["skill.killers_mark"],context).effect.contains("Does not consume"),"Death Strike redundant line removed")
	check(Hover.model(skills["skill.toxic_flurry"],context).effect=="On hit: Apply 1 stacks of Decay","Beguiling Strike baseline dynamic Decay")
	context.stats.bonus_decay_stacks=3
	check(Hover.model(skills["skill.toxic_flurry"],context).effect=="On hit: Apply 4 stacks of Decay","Beguiling Strike current-build Decay")
	context.stats.bonus_decay_stacks=0
	check(Hover.model(skills["skill.distilled_corruption"],context).effect=="Consume up to 5 stacks of Decay to apply up to 5 stacks of Poison","Distilled base full-consumption planning maximum")
	context.stats.bonus_poison_stacks=4
	check(Hover.model(skills["skill.distilled_corruption"],context).effect=="Consume up to 5 stacks of Decay to apply up to 9 stacks of Poison","Distilled current-build additive maximum")
	context.stats.special_effects["double_applied_stacks"]=true
	check(Hover.model(skills["skill.distilled_corruption"],context).effect=="Consume up to 5 stacks of Decay to apply up to 18 stacks of Poison","Distilled doubles final application total")
	context.stats.bonus_poison_stacks=0
	context.stats.special_effects.erase("double_applied_stacks")
	# Exercise actual palette/macro/tree providers in every presentation mode.
	var state=root.get_node("BuildState")
	var game=load("res://scenes/game_root.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game._on_contract_test_pressed(1234,45,"tree.assassin","tree.shadow")
	await process_frame
	for mode in ["test","adventure","practice"]:
		if mode=="practice": game._show_training_room()
		else:
			state.is_test_mode=mode=="test"
			game._show_combat_screen()
		for i in 5: await process_frame
		var screen=game._current_screen
		var actual_state=screen._state if mode=="practice" else state
		actual_state.set_locked(false)
		var base_skill: Skill=actual_state.unlocked_skills()[1]
		var rotation: Array[Skill]=[base_skill]
		actual_state.set_rotation(rotation)
		for i in 5: await process_frame
		var macro: IconTooltipButton=screen._skill_build_panel._slot_buttons[0]
		check(macro.skill_hover_provider.is_valid(),mode+" macro structured provider")
		check(macro._get_tooltip(Vector2.ZERO)==Hover.plain_text(Hover.model(base_skill,actual_state)),mode+" macro parity/no slot clutter")
		var buttons:=find_skill_buttons(screen)
		check(buttons.size()>1,mode+" palette and tree providers")
		for button in buttons:
			var data: Dictionary=button.skill_hover_provider.call()
			check(button._get_tooltip(Vector2.ZERO)==Hover.plain_text(data),mode+" provider parity "+data.id)
			var panel: Control=button._make_custom_tooltip(button._get_tooltip(Vector2.ZERO))
			check(panel.get_theme_stylebox("panel")==button.get_theme_stylebox("panel","TooltipPanel"),mode+" item background")
			check(panel.find_child("SkillHoverName",true,false).get_theme_font_size("font_size")==22,mode+" name22")
			check(panel.find_child("SkillHoverCategory",true,false).get_theme_font_size("font_size")==18,mode+" category18")
			var cooldown_label: Label=panel.find_child("SkillHoverCooldown",true,false)
			var duration_label: Label=panel.find_child("SkillHoverDuration",true,false)
			if data.cooldown=="":
				check(cooldown_label==null and duration_label==null,mode+" attack controls omitted")
			else:
				check(cooldown_label!=null and cooldown_label.text==data.cooldown and cooldown_label.get_theme_font_size("font_size")==18,mode+" separate cooldown row")
				check(duration_label==null if data.duration=="" else duration_label!=null and duration_label.text==data.duration and duration_label.get_theme_font_size("font_size")==18,mode+" duration row respects skill exception")
			panel.free()
		var talent_button: IconTooltipButton=null
		for control in screen.find_children("*","Button",true,false):
			if control is IconTooltipButton and str(control.get_meta("action_key","")).begins_with("buy:"):
				talent_button=control
				break
		check(talent_button!=null and not talent_button.skill_hover_provider.is_valid() and talent_button.talent_hover_provider.is_valid(),mode+" separate talent provider")
		if talent_button!=null:
			var talent_popup: Control=talent_button._make_custom_tooltip(talent_button._get_tooltip(Vector2.ZERO))
			check(talent_popup.find_child("SkillHoverName",true,false)==null and talent_popup.find_child("TalentHoverName",true,false)!=null,mode+" dedicated talent renderer")
			talent_popup.free()
		if mode=="practice":
			actual_state.set_primary_tree(registry.trees["tree.shadow"])
			actual_state.set_secondary_tree(registry.trees["tree.assassin"])
		for property in ["equipped_weapon","equipped_helm","equipped_armor","equipped_charm","equipped_trinket"]: actual_state.set(property,null)
		var refresh_ranks:={"talent.shadow.blind_spot":5,"talent.shadow.snake_oil":4,"talent.shadow.coated_weapons":1}
		check(actual_state.ranked_build.configure(registry.trees["tree.shadow"],registry.trees["tree.assassin"],45,refresh_ranks),mode+" legal dynamic base fixture")
		actual_state._finish_rank_edit(true)
		var distilled: Skill=null
		for skill in actual_state.unlocked_skills():
			if skill.id=="skill.distilled_corruption": distilled=skill
		var distilled_rotation: Array[Skill]=[distilled]
		actual_state.set_rotation(distilled_rotation)
		var gear:=GearItem.new()
		gear.id="test.dynamic_stack_weapon"
		gear.tier=GearItem.Tier.LEGENDARY
		gear.display_name="Dynamic stack fixture"
		var bonus:=StatModifier.new()
		bonus.stat_id="increased_all_stacks"
		bonus.value=2
		gear.affixes=[bonus]
		for stage in 4:
			if stage==1:
				if mode=="practice": actual_state.equip_legendary(gear)
				else: actual_state.equip(gear)
			elif stage==2:
				refresh_ranks["talent.shadow.death_touch"]=2
				check(actual_state.ranked_build.configure(registry.trees["tree.shadow"],registry.trees["tree.assassin"],45,refresh_ranks),mode+" legal live talent refresh")
				actual_state._finish_rank_edit(true)
			elif stage==3:
				var doubled:=StatModifier.new()
				doubled.stat_id="double_applied_stacks"
				doubled.value=1
				gear.affixes.append(doubled)
				if mode=="practice": actual_state.equip_legendary(gear)
				else: actual_state.equip(gear)
			for i in 5: await process_frame
			var maximum: int=[5,7,13,26][stage]
			var live_stats: PlayerStats=actual_state.current_player_stats()
			check(CombatResolver._applied_poison_stacks(5,live_stats)==maximum,mode+" resolver planning count stage "+str(stage))
			var refreshed:=0
			for button in find_skill_buttons(screen):
				var value: Dictionary=button.skill_hover_provider.call()
				if value.id!="skill.distilled_corruption": continue
				refreshed+=1
				check(value.effect=="Consume up to 5 stacks of Decay to apply up to %d stacks of Poison" % maximum,mode+" provider refreshed maximum stage "+str(stage))
				check(button._get_tooltip(Vector2.ZERO).contains(value.effect),mode+" actual tooltip refreshed stage "+str(stage))
			check(refreshed>=3,mode+" palette/macro/tree all refresh")
	game.queue_free()
	await process_frame
	state.reset()
	print("PASS minimal skill hover checks: ",checks)
	quit(1 if failed else 0)
