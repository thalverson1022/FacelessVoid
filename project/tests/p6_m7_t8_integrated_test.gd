extends "res://tests/p6_m7_mixed_cues_visual.gd"
const REPORT := "res://reports/integrated"
const RANKS_AS := {"talent.assassin.quick_hands":5,"talent.assassin.precision":3,"talent.assassin.hastened_poison":4,"talent.assassin.echoing_toxin":2,"talent.assassin.toxic_tradeoff":2,"talent.assassin.poison_strike":1,"talent.assassin.bypass":1,"talent.shadow.blind_spot":5,"talent.shadow.snake_oil":4,"talent.shadow.coated_weapons":1,"talent.shadow.deception":4,"talent.shadow.death_pact":2,"talent.shadow.death_touch":2,"talent.shadow.shadow_mastery":4,"talent.shadow.death_blade":1,"talent.shadow.dusk_strike":1,"talent.umbral_pressure":1}
const RANKS_BT := {"talent.bladedancer.wet_stone":5,"talent.bladedancer.rending_slash":1,"talent.bladedancer.fancy_footwork":2,"talent.bladedancer.weakness":5,"talent.bladedancer.opportunity":2,"talent.bladedancer.cloak_and_dagger":2,"talent.keen_eye":5,"talent.sticky_fingers":5,"talent.thief.fast_hands":2,"talent.thief.charisma":2,"talent.thief.silvered_edge":1}
class StressButton extends IconTooltipButton:
	func _make_custom_tooltip(text: String) -> Object:
		if talent_hover_provider.is_valid(): return preload("res://scripts/ui/talent_hover_panel.gd").build(self,talent_hover_provider.call(),1.25)
		if skill_hover_provider.is_valid(): return preload("res://scripts/ui/skill_hover_panel.gd").build(self,skill_hover_provider.call(),1.25)
		return super._make_custom_tooltip(text)
var evidence: Array = []
var captures: Array = []
func record(test: String, ok: bool, data = {}) -> void:
	evidence.append({"test":test,"pass":ok,"data":data})
	SaveSystem.write_json(REPORT+"/measurements.json",{"checks":evidence,"captures":captures})
	check(ok,test)
func rect(c: Control) -> Array:
	var r := c.get_global_rect()
	return [r.position.x,r.position.y,r.size.x,r.size.y]
func capture(name: String) -> void:
	await settle()
	root.get_texture().get_image().save_png(REPORT+"/"+name+".png")
	captures.append(name)
func key(code: Key, shift := false) -> void:
	var e := InputEventKey.new()
	e.keycode=code
	e.shift_pressed=shift
	e.pressed=true
	root.push_input(e,true)
	await process_frame
	e=InputEventKey.new()
	e.keycode=code
	e.shift_pressed=shift
	root.push_input(e,true)
	await settle()
func fonts(node: Node, scale: float) -> void:
	if node is Label or node is Button:
		if not node.has_meta("t8_font"): node.set_meta("t8_font",node.get_theme_font_size("font_size"))
		node.add_theme_font_size_override("font_size",roundi(node.get_meta("t8_font")*scale))
	for child in node.get_children(): fonts(child,scale)
func hover(button: IconTooltipButton, scale: float, name: String) -> void:
	if scale > 1:
		var art=button.tooltip_icon
		var talent=button.talent_hover_provider
		var skill=button.skill_hover_provider
		var provider=button.tooltip_provider
		var text=button.tooltip_text
		button.set_script(StressButton)
		button.tooltip_icon=art
		button.talent_hover_provider=talent
		button.skill_hover_provider=skill
		button.tooltip_provider=provider
		button.tooltip_text=text
	var e:=InputEventMouseMotion.new()
	e.position=Vector2(1,1)
	root.push_input(e,true)
	await create_timer(0.05).timeout
	e=InputEventMouseMotion.new()
	e.position=button.get_global_rect().get_center()
	root.push_input(e,true)
	await create_timer(0.8).timeout
	record(name+" hovered live target",root.gui_get_hovered_control()==button,{"button":rect(button)})
	await capture(name)
	for window in root.get_children(true):
		if window is Window and window.visible and window != root:
			record(name+" tooltip contained",Rect2i(Vector2i.ZERO,root.size).encloses(Rect2i(window.position,window.size)),{"position":str(window.position),"size":str(window.size)})
func run() -> void:
	DirAccess.make_dir_recursive_absolute(REPORT)
	var registry:=BuildContentRegistry.test_mode()
	var game=load("res://scenes/game_root.tscn").instantiate()
	root.add_child(game)
	await settle()
	game._on_contract_test_pressed(1234,45,"tree.assassin","tree.shadow")
	var state=root.get_node("BuildState")
	var effect_fixture=load("res://tests/p6_m7_t6_effect_display_test.gd").new()
	var enemy:=Monster.new()
	enemy.display_name="Mouthy Drunk"
	enemy.hp=100000
	enemy.block=25
	enemy.dodge_chance=0.2
	enemy.crit_negation=0.25
	for mode in ["test","adventure","practice"]:
		for width in [1280,1600,1920]:
			for scale in [1.0,1.25]:
				root.size=Vector2i(width,width*9/16)
				game._on_contract_test_pressed(1234,45,"tree.assassin","tree.shadow")
				await settle()
				if mode=="practice": game._show_training_room()
				else:
					state.is_test_mode=mode=="test"
					game._show_combat_screen()
				await settle()
				var screen=game._current_screen
				var actual=screen._state if mode=="practice" else state
				if mode!="practice":
					if screen._story_overlay.visible: screen._story_overlay._on_proceed_pressed()
					screen._contract_overlay.hide()
					screen._map_overlay.hide()
				var settings=game._settings_menu_layer
				var settings_button=settings.get_node("SettingsButton")
				for step in 100:
					if settings_button.has_focus(): break
					await key(KEY_TAB)
				record("settings reached",settings_button.has_focus())
				await key(KEY_ENTER)
				record("settings keyboard open",settings._overlay.visible)
				for step in 6:
					await key(KEY_TAB)
					record("settings Tab contained",settings._overlay.is_ancestor_of(root.gui_get_focus_owner()))
				var audio=settings._overlay.find_child("AudioButton",true,false)
				for step in 8:
					if audio.has_focus():break
					await key(KEY_TAB)
				await key(KEY_ENTER)
				record("Audio keyboard open",settings._audio_panel.visible)
				var slider=settings._overlay.find_child("MasterVolumeSlider",true,false)
				for step in 8:
					if slider.has_focus():break
					await key(KEY_TAB)
				var original_volume=slider.value
				await key(KEY_LEFT)
				record("Audio slider keyboard changes",slider.value!=original_volume)
				slider.value=original_volume
				for step in 8:
					if settings._overlay.find_child("AudioMainMenuButton",true,false).has_focus():break
					await key(KEY_TAB)
				await key(KEY_ENTER)
				record("Audio Back restores Audio option",settings._settings_panel.visible and audio.has_focus())
				await capture("%s_%d_%d_settings" % [mode,width,roundi(scale*100)])
				await key(KEY_ESCAPE)
				record("settings Escape restores opener",not settings._overlay.visible and settings_button.has_focus())
				var bt: bool=width==1600
				var pair: Array=["tree.bladedancer","tree.thief"] if bt else ["tree.assassin","tree.shadow"]
				var ranks: Dictionary=RANKS_BT if bt else RANKS_AS
				if width==1920 or (width==1600 and scale>1): pair.reverse()
				record(mode+" legal dense build",actual.ranked_build.configure(registry.trees[pair[0]],registry.trees[pair[1]],45,ranks),{"roles":pair,"ranks":ranks})
				actual._finish_rank_edit(true)
				await settle()
				record("viewport metadata",true,{"logical":str(root.get_visible_rect()),"physical":str(root.size),"canvas_transform":str(root.get_final_transform()),"window":str(DisplayServer.window_get_size())})
				var prefix: String="%s_%d_%d" % [mode,width,roundi(scale*100)]
				var active=screen.find_child("ActiveTalentsPanel",true,false)
				fonts(active,scale)
				await capture(prefix+"_hud")
				var content=screen.get_child(0)
				for panel in screen.find_children("*","PanelContainer",true,false):
					if panel.is_visible_in_tree() and not active.is_ancestor_of(panel) and panel.get_global_rect().size.x>150:
						record(prefix+" visible panel horizontal bounds",panel.get_global_rect().position.x>=0 and panel.get_global_rect().end.x<=root.get_visible_rect().end.x,{"node":str(panel.get_path()),"rect":rect(panel)})
				record(prefix+" Active Talents contained",root.get_visible_rect().encloses(active.get_global_rect()),{"rect":rect(active),"scroll":rect(active._talents_scroll),"content":rect(active._talents_box)})
				active._talents_scroll.scroll_vertical=10000
				await capture(prefix+"_active_bottom")
				# Reach the opener using actual Tab input, then activate and restore.
				var reached:=false
				for step in 100:
					if active._open_button.has_focus(): reached=true;break
					await key(KEY_TAB)
				record(prefix+" Tab reaches Talent Trees",reached)
				await key(KEY_ENTER)
				var modal=screen._talent_overlay
				record(prefix+" Enter opens Talent Trees",modal.visible)
				fonts(modal,scale)
				await settle()
				var nav=modal.get_node("TalentKeyboardNavigation")
				var scroll=screen._talent_overlay_scroll if mode=="practice" else modal._scroll
				record(prefix+" tree scroll viewport contained",root.get_visible_rect().encloses(scroll.get_global_rect()),{"rect":rect(scroll)})
				await capture(prefix+"_trees")
				var view=screen._talent_panel._ranked_view if mode=="practice" else modal._talent_panel._ranked_view
				var target: IconTooltipButton=view.actions["buy:talent.bladedancer.fancy_footwork" if bt else "buy:talent.shadow.shadow_mastery"]
				var talent_reached:=false
				for step in 90:
					if target.has_focus(): talent_reached=true;break
					await key(KEY_TAB)
				record(prefix+" Tab reaches talent",talent_reached)
				await key(KEY_F1)
				record(prefix+" F1 opens talent details",nav.details.visible)
				await capture(prefix+"_keyboard_details")
				await key(KEY_ESCAPE)
				record(prefix+" Escape closes details",not nav.details.visible)
				scroll.ensure_control_visible(target)
				await settle()
				await hover(target,scale,prefix+"_talent_hover")
				await key(KEY_ESCAPE)
				record(prefix+" Escape closes tree and restores opener",not modal.visible and active._open_button.has_focus())
				# Same legal build drives real resolver events on its actual mode surface.
				var resolved=BuildResolver.resolve_ranked_build(registry.classes["class.rogue"],actual.ranked_build,[load("res://data/gear/crude_dagger.tres")])
				var rotation: Array[Skill]=[]
				for skill in resolved.skills:
					if skill.id in (["skill.stab","skill.rending_slash","skill.steal"] if bt else ["skill.venom_jab","skill.poison_strike","skill.stab"]): rotation.append(skill)
				actual.set_rotation(rotation)
				await settle()
				var macro=screen._skill_build_panel
				await hover(macro._slot_buttons[0],scale,prefix+"_skill_hover")
				var result=CombatResolver.resolve(rotation,resolved.stats,enemy,10000,7,true)
				record(prefix+" valid real resolver",result.is_valid and result.cast_events.size()>0,{"casts":result.cast_events.size(),"ticks":result.tick_events.size(),"damage":result.total_damage})
				var playback=screen._combat_view if mode=="practice" else screen._playback_presenter
				if mode!="practice": playback.finished.disconnect(screen._on_playback_finished)
				begin(screen,playback,mode,result,enemy,1.0)
				drive(screen,playback,mode,1.8)
				await capture(prefix+"_resolver")
				for label in screen.find_children("Text","Label",true,false):
					if label.is_visible_in_tree(): evidence.append({"test":prefix+" HUD foreground","pass":true,"data":{"text":label.text,"color":label.get_theme_color("font_color").to_html(),"alpha":label.modulate.a,"rect":rect(label)}})
				# Special mixed outcomes are disclosed injections; use real popup layout.
				emit(playback,mode,diagnostic(1))
				await create_timer(0.04).timeout
				emit(playback,mode,diagnostic(2))
				await capture(prefix+"_mixed")
				for label in playback._popup_layer.get_children():
					if label is Control and label.visible and label.has_meta("cue_lane"):
						record(prefix+" popup contained",playback._combat_stage.play_area_global_rect().grow(1).encloses(label.get_global_rect()),{"rect":rect(label),"stage":str(playback._combat_stage.play_area_global_rect())})
				var icons=screen._combat_view._effect_icons if mode=="practice" else screen._effect_icons
				icons.begin(effect_fixture.fixture(10))
				icons.advance_to(1500)
				icons._inspect.add_theme_font_size_override("font_size",roundi(22*scale))
				icons._details.add_theme_font_size_override("normal_font_size",roundi(20*scale))
				await settle()
				# Tab must reach the existing overflow opener without a direct focus call.
				var overflow_reached:=false
				for step in 100:
					if icons._inspect.has_focus(): overflow_reached=true;break
					await key(KEY_TAB)
				record(prefix+" Tab reaches overflow",overflow_reached)
				await key(KEY_ENTER)
				record(prefix+" Enter opens effects",icons._dialog.visible)
				record(prefix+" inspector contained",Rect2i(Vector2i.ZERO,root.size).encloses(Rect2i(icons._dialog.position,icons._dialog.size)),{"position":str(icons._dialog.position),"size":str(icons._dialog.size),"entries":icons._details.text.count("Source:")})
				await capture(prefix+"_inspector")
				icons._details.get_v_scroll_bar().value=icons._details.get_v_scroll_bar().max_value
				await capture(prefix+"_inspector_bottom")
				await key(KEY_ESCAPE)
				record(prefix+" effects Escape restores overflow",not icons._dialog.visible and icons._inspect.has_focus())
				for popup in playback._popup_layer.get_children():
					popup.hide()
					popup.queue_free()
				CombatEffectIcons.reduced_motion=true
				emit(playback,mode,diagnostic(0))
				record(prefix+" reduced motion suppresses new popup",playback._popup_layer.get_children().filter(func(n): return n.visible and not n.is_queued_for_deletion()).is_empty())
				CombatEffectIcons.reduced_motion=false
				if mode=="practice": playback._skip()
				else: playback.skip()
				game._on_main_menu_pressed()
				await settle()
	SaveSystem.write_json(REPORT+"/measurements.json",{"checks":evidence,"captures":captures,"disclosure":"18 mode/size/text cases. 125% diagnostic overrides affect Active Talents/tree labels/buttons, structured hovers and existing effect inspector; no global enlarged-text setting. Legal ranked builds feed real resolver playback. Dense ten-effect inspector and special crit-negation/gold outcomes are injections. Adventure build is diagnostic, not earned. Reduced motion static fixture does not expose hidden controls."})
	effect_fixture.free()
	game.queue_free()
	await settle()
	print("T8 integrated PASS" if not failed else "T8 integrated FAILED")
	quit(1 if failed else 0)
