extends SceneTree
const Hover=preload("res://scripts/ui/talent_hover_formatter.gd")
const Rows=preload("res://scripts/ui/talent_effect_rows.gd")
const HoverPanel=preload("res://scripts/ui/talent_hover_panel.gd")
const SkillHover=preload("res://scripts/ui/skill_hover_formatter.gd")
class Snapshot extends RefCounted:
	var ranks: Dictionary={}
	func rank_of(id: String) -> int: return int(ranks.get(id,0))
var failed:=false
var checks:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,text: String) -> void:
	checks+=1
	if not ok:
		failed=true
		printerr("FAILED: "+text)
func keyed(rows: Array,key: String) -> Dictionary:
	for value in rows:
		if value.key==key: return value
	return {}
func talents(node: Node) -> Array:
	var result:=[]
	if node is IconTooltipButton and node.talent_hover_provider.is_valid(): result.append(node)
	for child in node.get_children(): result.append_array(talents(child))
	return result
func settle() -> void:
	for i in 5: await process_frame
func run() -> void:
	var registry:=BuildContentRegistry.test_mode()
	var fixture:=Snapshot.new()
	var inventory:=[]
	var ranks_seen:=0
	var tooltip_owner:=Control.new()
	for tree in registry.trees.values():
		for talent in tree.talents:
			var record:={"id":talent.id,"name":talent.display_name,"tree":tree.display_name,"states":[]}
			for rank in range(talent.max_ranks+1):
				fixture.ranks={talent.id:rank}
				var data:=Hover.model(talent,tree,fixture)
				var text:=Hover.plain_text(data)
				record.states.append({"rank":rank,"text":text})
				if rank>0: ranks_seen+=1
				check(not data.base_rows.is_empty() or not data.current_rows.is_empty() or not data.next_rows.is_empty(),talent.id+" every state useful")
				check(data.rank==rank and data.max==talent.max_ranks,talent.id+" rank metadata")
				check(data.current_rows.is_empty()==(rank==0),talent.id+" current section only when invested")
				check(rank!=talent.max_ranks or data.next_rows.is_empty(),talent.id+" next section removed at max")
				check(text.count("Next rank:")==(0 if data.next_rows.is_empty() else 1),talent.id+" next heading once")
				check(not text.contains(" -> ") and not text.contains("Max rank"),talent.id+" no comparison or redundant max heading")
				check(data.maxed==(rank==talent.max_ranks),talent.id+" max marker")
				for section in [data.base_rows,data.current_rows,data.next_rows]:
					var keys:=[]
					for row in section:
						check(row.key not in keys,talent.id+" no duplicated rule/stat within rank")
						keys.append(row.key)
						check(row.color==Hover.BASIC,talent.id+" neutral cream effect")
				var popup: Control=preload("res://scripts/ui/talent_hover_panel.gd").build(tooltip_owner,data)
				check((popup.find_child("TalentHoverNextRank",true,false)!=null)==(not data.next_rows.is_empty()),talent.id+" next section control lifecycle")
				check(popup.find_child("TalentHoverRequires",true,false)==null,talent.id+" no requirement control")
				check(data.requires=="" and not text.contains("Requires:"),talent.id+" no requirement text at any rank")
				var rendered:=popup.find_children("*","RichTextLabel",true,false)
				var expected: Array=data.base_rows+data.current_rows+data.next_rows
				check(rendered.size()==expected.size(),talent.id+" every selected row rendered")
				for index in expected.size():
					var item: Dictionary=expected[index]
					check(rendered[index].get_parsed_text()==Hover.row_text(item),talent.id+" rich row preserves literal text")
					check(rendered[index].get_theme_font_size("normal_font_size")==20,talent.id+" effect font remains20")
					var runs:=Rows.text_runs(item)
					var assembled:=""
					var gold_count:=0
					for run in runs:
						assembled+=run.text
						if run.kind=="value":
							gold_count+=1
							check(run.text==item.value and run.color==UIColors.TEXT_GOLD,talent.id+" operators and value gold")
						else:
							var cyan: bool=run.kind=="buff" and not item.key.begins_with("unlock_")
							check(run.color==(preload("res://scripts/ui/presentation_keywords.gd").BUFF_COLOR if cyan else Hover.BASIC),talent.id+" Buff cyan, other keywords cream")
					check(gold_count==(0 if item.value=="" else 1) and assembled==Hover.row_text(item),talent.id+" only separated value gold and literal parity")

				if rank<talent.max_ranks:
					for item in Hover.rank_rows(talent,rank+1):
						var previous:=keyed(data.current_rows,item.key)
						if rank==0:
							check((not keyed(data.base_rows,item.key).is_empty())==(item.value==""),talent.id+" rank0 full base rules outside Next")
							check((not keyed(data.next_rows,item.key).is_empty())==(item.value!=""),talent.id+" rank0 first values in Next")
						else:
							var changed: bool=previous.is_empty() or previous.label!=item.label or previous.value!=item.value
							check((not keyed(data.next_rows,item.key).is_empty())==changed,talent.id+" keyed comparison preserves only changes")
				popup.free()
				for clutter in ["talent.","tree.","after child","gear multiplier","before conversion","SCRIPT","%d","%.0f"]:
					check(not text.contains(clutter),talent.id+" no internal/verbose text")
				if rank==talent.max_ranks: check(data.requires=="",talent.id+" no buy condition at max")
			inventory.append(record)
	tooltip_owner.free()
	check(registry.talents.size()==44 and ranks_seen==140,"Full44/140 live roster")
	var assassin: SubclassTree=registry.trees["tree.assassin"]
	var precision: Talent=registry.talents["talent.assassin.precision"]
	fixture.ranks={precision.id:3}
	var data:=Hover.model(precision,assassin,fixture)
	check(keyed(data.current_rows,"crit_chance").value=="+3%" and keyed(data.next_rows,"crit_chance").value=="+4%","Precision actual1% per rank")
	var toxic: Talent=registry.talents["talent.assassin.toxic_tradeoff"]
	for rank in 5:
		fixture.ranks={toxic.id:rank+1}
		data=Hover.model(toxic,assassin,fixture)
		check(keyed(data.current_rows,"percent_physical_damage").value=="-%d%%" % (10*(rank+1)),"Toxic actual negative rank value")
		check(keyed(data.current_rows,"percent_physical_damage").color==Hover.BASIC,"Toxic penalty neutral cream")
		check(keyed(data.current_rows,"toxic").value=="+%d%%" % (10*(rank+1)),"Toxic Poison benefit")
		check(data.current_rows[-1].key=="percent_physical_damage","Toxic drawback after benefits")

	var introduced:=Talent.new()
	introduced.id="test.introduced"
	introduced.display_name="Introduced rule fixture"
	introduced.max_ranks=2
	var first:=TalentRank.new()
	var second:=TalentRank.new()
	var stat:=StatModifier.new()
	stat.stat_id="base_damage"
	stat.value=1
	first.stat_modifiers=[stat]
	second.stat_modifiers=[stat]
	second.critical_poison_enabled=true
	introduced.ranks=[first,second]
	fixture.ranks={introduced.id:1}
	check(keyed(Hover.model(introduced,assassin,fixture).next_rows,"critical_poison").label=="Poison can now critically hit based on your Crit Chance and Crit Damage","New next-rank effect retained")
	check(Hover.model(introduced,assassin,fixture).next_rows.size()==1,"New higher-rank rule retained without unchanged stat")
	var comparison_changes:=Hover.changed_rows([Hover.row("rule","Old rule."),Hover.row("value","value","+1"),Hover.row("same","same","x20%")],[Hover.row("rule","New rule."),Hover.row("value","value","+2"),Hover.row("same","same","x20%"),Hover.row("new","New effect.")])
	check(comparison_changes.size()==3 and comparison_changes[0].label=="New rule." and comparison_changes[1].value=="+2" and comparison_changes[2].key=="new","Changed rule, changed value and newly introduced key retained")
	fixture.ranks={"talent.bladedancer.fancy_footwork":0}
	var zero:=Hover.model(registry.talents["talent.bladedancer.fancy_footwork"],registry.trees["tree.bladedancer"],fixture)
	check(zero.base_rows.size()==1 and zero.next_rows.size()==1 and Hover.plain_text(zero).count("Quick Cut grants 1 stack of Footwork.")==1,"Rank0 full explanation once before first value")
	check(Hover.plain_text(zero).find("Quick Cut grants")<Hover.plain_text(zero).find("Next rank:"),"Rank0 base description outside Next")
	var zero_unlock:=Hover.model(registry.talents["talent.assassin.poison_strike"],assassin,fixture)
	check(zero_unlock.base_rows.size()==1 and zero_unlock.next_rows.is_empty() and not Hover.plain_text(zero_unlock).contains("Next rank:"),"Single unlock rule once without empty Next")
	var literal:=Rows.make_row(Hover.row("literal","[color=red]Literal[/color]","-10%"),20,280,480)
	check(literal.get_parsed_text()=="[color=red]Literal[/color]: -10%" and not literal.bbcode_enabled,"Literal row copy cannot inject markup")
	literal.free()
	var echo: Talent=registry.talents["talent.assassin.echoing_toxin"]
	for rank in 3:
		fixture.ranks={echo.id:rank+1}
		check(keyed(Hover.model(echo,assassin,fixture).current_rows,"suppression").value=="x%d%%" % (40-10*rank),"Echo actual decreasing suppression")
	var foot: Talent=registry.talents["talent.bladedancer.fancy_footwork"]
	fixture.ranks={foot.id:2}
	data=Hover.model(foot,registry.trees["tree.bladedancer"],fixture)
	check(keyed(data.current_rows,"footwork").value=="8%" and keyed(data.next_rows,"footwork").value=="12%","Footwork live cast reduction")
	check(keyed(data.current_rows,"footwork").color==Hover.BASIC,"Footwork neutral cream")
	check(keyed(data.current_rows,"footwork_rule").label=="Quick Cut grants 1 stack of Footwork. Footwork stacks up to 5 and lasts for 3 sec. Leaping Plunge consumes all stacks of Footwork for decreased Attack Time.","Approved complete Footwork rule")
	var spacing_owner:=Control.new()
	var spaced: Control=HoverPanel.build(spacing_owner,data)
	check(spaced.find_child("TalentEffectGroupGap",true,false).custom_minimum_size.y==Rows.GROUP_GAP,"Description/value group spacing")
	check(spaced.find_child("TalentHoverNextRankGap",true,false).custom_minimum_size.y==HoverPanel.NEXT_SECTION_GAP,"Separate Next section spacing")
	spaced.free()
	spacing_owner.free()

	var dancer: SubclassTree=registry.trees["tree.bladedancer"]
	for id in ["weakness","virulent_corruption"]:
		var changed: Talent=registry.talents["talent.bladedancer."+id]
		for rank in range(1,changed.max_ranks+1):
			var item:=keyed(Hover.rank_rows(changed,rank),"shred_value")
			check(item.label=="Armor decrease per Shred stack","Armor decrease label "+id)
			check(item.value==Hover.signed(changed.ranks[rank-1].stat_modifiers[0].value),"Source-backed Shred rank "+id)
	for rank in range(1,foot.max_ranks+1):
		check(keyed(Hover.rank_rows(foot,rank),"footwork").value=="%d%%" % (4*foot.ranks[rank-1].footwork_rank),"Footwork positive reduction at each rank")
	for id in ["riposte","weapon_master","sharpened_edge"]:
		var changed: Talent=registry.talents["talent.bladedancer."+id]
		for rank in range(1,changed.max_ranks+1):
			var key: String="percent_physical_damage" if id=="weapon_master" else id
			var value: float=changed.ranks[rank-1].stat_modifiers[0].value if id=="weapon_master" else changed.ranks[rank-1].stat_derivations[0].fraction if id=="sharpened_edge" else 0.2*changed.ranks[rank-1].riposte_rank
			check(keyed(Hover.rank_rows(changed,rank),key).value=="x"+Hover.number(value*100)+"%","Source-backed multiplicative prefix "+id)
	var precise: Talent=registry.talents["talent.bladedancer.precision_attacks"]
	var side_step: Talent=registry.talents["talent.bladedancer.side_step"]
	fixture.ranks={}
	var side_step_zero:=Hover.model(side_step,dancer,fixture)
	check(Hover.plain_text(side_step_zero).contains("Parry Strike has 100% Crit Chance") and side_step_zero.next_rows.is_empty(),"Single-rank Side Step uses one effect sentence without Next rank")
	check(keyed(Hover.rank_rows(precise,1),"precision_attacks").label=="Quick Cut grants Precision. Stab and Heavy Slash consume Precision to gain 100% Retrigger Chance","Approved Precision Attacks rule")
	var dip: Talent=registry.talents["talent.bladedancer.double_dip"]
	for rank in range(1,dip.max_ranks+1):
		check(keyed(Hover.rank_rows(dip,rank),"double_dip").label=="Percentage of Retrigger Chance converted to Crit Chance","Approved Double Dip label")
	var finder: Talent=registry.talents["talent.thief.finders_keepers"]
	fixture.ranks={finder.id:1}
	check(keyed(Hover.model(finder,registry.trees["tree.thief"],fixture).current_rows,"finders").color==Hover.BASIC,"Enemy Block reduction is benefit")
	var shadow: SubclassTree=registry.trees["tree.shadow"]
	var mastery: Talent=registry.talents["talent.shadow.shadow_mastery"]
	fixture.ranks={mastery.id:4}
	data=Hover.model(mastery,shadow,fixture)
	check(keyed(data.current_rows,"shadow_mastery").value=="40%" and keyed(data.next_rows,"shadow_mastery").value=="50%","Mastery numerical copy fraction")
	check(Hover.plain_text(data).count("Increased Elemental Damage and Base Elemental Damage")==1 and data.next_rows.size()==1,"Shared Mastery rule once, next scaling value only")
	check(data.requires=="" and Hover.requirements(mastery,shadow,fixture).contains("Deception"),"Requirements hidden without changing diagnostic gate math")
	fixture.ranks={"talent.shadow.blind_spot":5,"talent.shadow.snake_oil":4,"talent.shadow.coated_weapons":1,"talent.shadow.deception":5,mastery.id:4}
	check(Hover.model(mastery,shadow,fixture).requires=="","Satisfied gates suppressed")
	fixture.ranks={mastery.id:4,"talent.shadow.death_pact":3,"talent.shadow.death_touch":3}
	check(Hover.model(mastery,shadow,fixture).requires=="" and Hover.requirements(mastery,shadow,fixture).contains("6/15"),"Own/same-tier gate math retained but hidden")
	for id in ["hastened_poison","accelerant"]:
		var changed: Talent=registry.talents["talent.assassin."+id]
		var key: String="hastened" if id=="hastened_poison" else "accelerant"
		for rank in range(1,changed.max_ranks+1):
			var rows:=Hover.rank_rows(changed,rank)
			check(keyed(rows,key+"_rule").label==("Poison Tick Rate is affected by your Attack Speed" if key=="hastened" else "Apply more of your Attack Speed to Poison Tick Rate"),"Approved Assassin tick rule "+id)
			check(keyed(rows,key).label=="Percentage of Attack Speed converted to Tick Rate" and keyed(rows,key).value=="%d%%" % (10*rank),"Live Assassin tick conversion "+id)
	var resonance: Talent=registry.talents["talent.assassin.resonance"]
	for rank in range(1,resonance.max_ranks+1):
		var rows:=Hover.rank_rows(resonance,rank)
		check(keyed(rows,"resonance_rule").label=="Each tick of Poison now consumes 3 stacks but does more damage","Approved Resonance rule")
		check(keyed(rows,"resonance").label=="Increase Poison Damage per stack consumed" and keyed(rows,"resonance").value=="x%d%%" % (5*rank),"Live Resonance multiplier prefix")
	check(keyed(Hover.rank_rows(echo,1),"echoing_rule").label=="Each Poison tick now consumes 2 stacks at the cost of slower Tick Rate","Approved Echoing rule")
	check(keyed(Hover.rank_rows(echo,1),"suppression").label=="Poison Suppression penalty","Approved Suppression label")
	check(keyed(Hover.rank_rows(registry.talents["talent.assassin.bypass"],1),"bypass").label=="Stab grants 1 stack of Bypass. Bypass stacks up to 3 and lasts for 3 sec. Each stack of Bypass increases Elemental Damage by x10%","Approved Bypass rule")
	check(keyed(Hover.rank_rows(registry.talents["talent.assassin.critical_poison"],1),"critical_poison").label=="Poison can now critically hit based on your Crit Chance and Crit Damage","Approved Critical Poison rule")
	for rank in range(1,6):
		check(keyed(Hover.rank_rows(registry.talents["talent.shadow.deception"],rank),"percent_elemental_damage").value=="x%d%%" % (10*rank),"Deception actual elemental value")
	check(keyed(Hover.rank_rows(registry.talents["talent.shadow.coated_weapons"],1),"coated").label=="Stab and Heavy Slash now apply 2 stacks of Poison","Coated source augment copy")
	for rank in range(1,4):
		var item:=keyed(Hover.rank_rows(registry.talents["talent.shadow.death_touch"],rank),"increased_all_stacks")
		check(item.label=="Increased Stacks" and item.value=="+%d" % (3*rank),"Death Touch live stack value")
		var rows:=Hover.rank_rows(registry.talents["talent.shadow.death_pact"],rank)
		check(keyed(rows,"pact_rule").label=="Consuming stacks of Poison or Decay grants the same number of stacks of both Penetration and Potency","Death Pact explicit supported statuses")
		check(keyed(rows,"pact_duration").label=="Increased duration of Penetration and Potency" and keyed(rows,"pact_duration").value=="%ds" % (3+rank),"Death Pact total live duration")
	for rank in range(1,3):
		var rows:=Hover.rank_rows(registry.talents["talent.shadow.death_blade"],rank)
		check(keyed(rows,"blade_rule").label=="Stab can no longer apply Poison, but any application of Poison has a chance to trigger Stab","Death Blade complete rule")
		check(keyed(rows,"blade_chance").value=="%d%%" % (40*rank),"Death Blade plain live Trigger Chance")
	var dusk_rows:=Hover.rank_rows(registry.talents["talent.shadow.dusk_strike"],1)
	check(dusk_rows.size()==1 and dusk_rows[0].label=="+10 Armor decrease per stack of Shred and when you apply Decay you also apply 1 stack of Shred","Dusk single combined live Shred rule")
	check(keyed(Hover.rank_rows(registry.talents["talent.umbral_pressure"],1),"umbral").label=="Maximum Poison stacks increased from 20 to 80","Umbral core cap rule")
	check(keyed(data.current_rows,"shadow_mastery_rule").label=="Increased Elemental Damage and Base Elemental Damage also grant Increased Physical Damage and Base Physical Damage","Shadow Mastery complete stat names")
	check(keyed(data.current_rows,"shadow_mastery").label=="Percentage of Elemental converted to Physical","Shadow Mastery conversion label")
	var thief: SubclassTree=registry.trees["tree.thief"]
	for id in ["talent.keen_eye","talent.sticky_fingers"]:
		var changed: Talent=registry.talents[id]
		for rank in range(1,changed.max_ranks+1):
			for item in Hover.rank_rows(changed,rank):
				check(item.value=="x"+Hover.number(changed.ranks[rank-1].stat_modifiers[0].value*100)+"%","Thief source-backed x prefix "+id)
	for id in ["fast_hands","fill_your_pockets"]:
		var changed: Talent=registry.talents["talent.thief."+id]
		for rank in range(1,changed.max_ranks+1):
			var rows:=Hover.rank_rows(changed,rank)
			check(keyed(rows,id+"_rule").label==("Increased Gold also grants Increased Attack Speed" if id=="fast_hands" else "Magic Find also grants Increased Elemental Damage"),"Approved conversion rule "+id)
			check(keyed(rows,id).label==("Percentage of Increased Gold converted to Attack Speed" if id=="fast_hands" else "Percentage of Magic Find converted to Elemental Damage"),"Approved conversion label "+id)
			check(keyed(rows,id).value==Hover.number(changed.ranks[rank-1].stat_derivations[0].fraction*100)+"%","Conversion remains plain live percentage "+id)
	var gilded_rows:=Hover.rank_rows(registry.talents["talent.gilded_blade"],1)
	check(keyed(gilded_rows,"gilded").label=="Gain +1% Crit Damage per 1 gold in your stash" and Hover.row_text(keyed(gilded_rows,"gilded_cap"))=="max: +500%","Gilded cap has its own value line")
	for id in ["charisma","load_dice"]:
		var changed: Talent=registry.talents["talent.thief."+id]
		for rank in range(1,changed.max_ranks+1):
			check(Hover.rank_rows(changed,rank)[0].value.begins_with("+"),"Additive Thief talent unchanged "+id)
	var view=preload("res://scripts/ui/ranked_talent_view.gd").new()
	check(view.intrinsic_summary(thief)=="Intrinsic: x10% Increased Gold","Thief tree base intrinsic x10")
	check(view.bonus_summary(thief,true)=="Bonus: +2% Increased Gold per invested point","Thief per-point bonus additive and suffix omitted")
	check(view.bonus_summary(thief,false)=="Bonus: NONE","Secondary Thief has no primary-point bonus")
	check(not view.bonus_summary(assassin,true).contains("primary only") and view.bonus_summary(assassin,true).to_lower().contains("+0.5 base elemental damage"),"Assassin suffix omitted, live additive bonus preserved")
	check(view.bonus_summary(assassin,false)=="Bonus: NONE","Secondary Assassin unchanged")
	check(not view.bonus_summary(shadow,true).contains("primary only") and view.bonus_summary(shadow,true).contains("+2%"),"Shadow suffix omitted, live bonus preserved")
	check(view.bonus_summary(shadow,false)=="Bonus: NONE","Secondary Shadow unchanged")
	view.free()
	var unlock: Talent=registry.talents["talent.assassin.poison_strike"]
	fixture.ranks={}
	check(Hover.plain_text(Hover.model(unlock,assassin,fixture)).contains("Unlocks Poison Strike"),"Single-rank skill unlock concise")
	DirAccess.make_dir_recursive_absolute("res://reports/talent_hover")
	SaveSystem.write_json("res://reports/talent_hover/inventory.json",{"talents":inventory,"talent_count":44,"rank_count":ranks_seen})
	var state=root.get_node("BuildState")
	var game=load("res://scenes/game_root.tscn").instantiate()
	root.add_child(game)
	await settle()
	game._on_contract_test_pressed(1234,45,"tree.bladedancer","tree.thief")
	for mode in ["test","adventure","practice"]:
		if mode=="practice": game._show_training_room()
		else:
			state.is_test_mode=mode=="test"
			game._show_combat_screen()
		await settle()
		var screen=game._current_screen
		var actual=screen._state if mode=="practice" else state
		for pair in [["tree.bladedancer","tree.thief"],["tree.assassin","tree.shadow"]]:
			if mode=="practice":
				actual.set_primary_tree(registry.trees[pair[0]])
				actual.set_secondary_tree(registry.trees[pair[1]])
			check(actual.ranked_build.configure(registry.trees[pair[0]],registry.trees[pair[1]],45,{}),"Legal empty fixture")
			actual._finish_rank_edit(true)
			await settle()
			var buttons:=talents(screen)
			check(buttons.size()==registry.trees[pair[0]].talents.size()+registry.trees[pair[1]].talents.size(),mode+" all live talent providers")
			for button in buttons:
				var value: Dictionary=button.talent_hover_provider.call()
				check(button._get_tooltip(Vector2.ZERO)==Hover.plain_text(value),mode+" live parity "+value.id)
				var panel: Control=button._make_custom_tooltip(button._get_tooltip(Vector2.ZERO))
				check(panel.get_theme_stylebox("panel")==button.get_theme_stylebox("panel","TooltipPanel"),mode+" exact item background")
				check(panel.find_child("TalentHoverName",true,false).get_theme_font_size("font_size")==22,mode+" title22")
				panel.free()
			var skill: Skill=actual.unlocked_skills()[1]
			var rotation: Array[Skill]=[skill]
			actual.set_rotation(rotation)
			await settle()
			var slot: IconTooltipButton=screen._skill_build_panel._slot_buttons[0]
			check(slot._get_tooltip(Vector2.ZERO)==SkillHover.plain_text(SkillHover.model(skill,actual)),mode+" skills unchanged")
			var skill_panel: Control=slot._make_custom_tooltip(slot._get_tooltip(Vector2.ZERO))
			check(skill_panel.name=="SkillHover",mode+" existing skill branch")
			skill_panel.free()
	game.queue_free()
	await process_frame
	state.reset()
	print("PASS compact talent checks: ",checks)
	quit(1 if failed else 0)
