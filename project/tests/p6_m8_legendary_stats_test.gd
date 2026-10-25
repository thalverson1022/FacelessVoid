extends SceneTree
const State = preload("res://scripts/systems/combat_stat_state.gd")
const Buffs = preload("res://scripts/systems/combat_self_buffs.gd")
const TalentBuffs = preload("res://scripts/systems/combat_talent_buffs.gd")
const Lifecycle = preload("res://scripts/systems/bladedancer_effect_lifecycle.gd")
const Effects = preload("res://scripts/systems/combat_effect_state.gd")
const Live = preload("res://scripts/systems/legendary_live_stats.gd")
const Gold = preload("res://scripts/systems/combat_gold.gd")
const Rule = preload("res://scripts/resources/stat_derivation_rule.gd")
var failed := false
var checks: Array[Dictionary] = []
var witnesses := {}
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, label: String, actual: Variant = null, expected: Variant = null) -> void:
	checks.append({"passed": ok, "label": label, "actual": actual, "expected": expected})
	if not ok:
		failed = true
		printerr("FAILED: %s actual=%s expected=%s" % [label, str(actual), str(expected)])
func near(actual: float, expected: float, label: String) -> void:
	check(is_equal_approx(actual, expected), label, actual, expected)
func mod(id: String, amount: float) -> StatModifier:
	var m := StatModifier.new()
	m.stat_id = id
	m.value = amount
	return m
func rule_talent(kind: String, fraction: float) -> Talent:
	var t := Talent.new()
	t.id = "test." + kind
	var r := Rule.new()
	r.kind = kind
	r.fraction = fraction
	t.stat_derivations = [r]
	return t
func skill(id: String, amount: float = 10.0) -> Skill:
	var s := Skill.new()
	s.id = id
	s.base_execution_ms = 1000
	s.min_execution_ms = 100
	var e := PhysicalDamageEffect.new()
	e.amount = amount
	s.effects = [e]
	return s
func target() -> Monster:
	var m := Monster.new()
	m.hp = 1000000
	return m
func run() -> void:
	production_wiring()
	crown()
	signet_coin()
	live_engine()
	live_sources()
	bandit()
	DirAccess.make_dir_recursive_absolute("res://reports")
	var report := {"passed": not failed, "checks": checks, "check_count": checks.size(), "witnesses": witnesses,
		"scope": "Production item-to-descriptor, effective build output and live Legendary stat/buff integration. Raw crit preserved internally and suppressed at hit resolution.",
		"limits": ["Dash is a representative temporary source through actual lifecycle; no authored Dash runtime exists in current production source.", "Acquisition/save authoring is covered by the separate production state tests."]}
	FileAccess.open("res://reports/p6_m8_legendary_stats_witness.json", FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("M8 production Legendary stats " + ("FAIL" if failed else "PASS") + " checks=" + str(checks.size()))
	quit(1 if failed else 0)
func crown() -> void:
	var p := PlayerStats.new()
	p.legendary_crown = true
	p.bypass_enabled = true
	var tb := TalentBuffs.new(p)
	for i in range(5):
		check(tb.finish_cast("skill.stab", true, i * 100, {}) == "", "Bypass real grant accepted")
	near(tb.live_player(p).elemental_damage_multiplier, 1.6, "Crown Bypass doubles additive strength; cap remains three")
	check(tb.state.snapshot("bypass").stacks == 3, "Bypass unchanged cap", tb.state.snapshot("bypass"))
	near(tb.state.snapshot("bypass").magnitude, 0.6, "Crown Bypass inspector effective strength")
	check(tb.state.advance(3400) == "", "Bypass expiration accepted")
	near(tb.live_player(p).elemental_damage_multiplier, 1.0, "Bypass strength expires normally")
	check(tb.grant_touch(3, 3500, {}) == "", "Touch actual consumed-three grant")
	near(tb.live_player(p).attack_speed, 0.6, "Touch Crown additive IAS")
	near(tb.live_player(p).bonus_physical_damage, 12.0, "Touch Crown additive flat")
	check(tb.state.snapshot("touch.1").units == 3, "Touch actual consumed quantity unchanged")
	near(tb.state.snapshot("touch.1").magnitude, 0.6, "Crown Touch inspector effective strength")
	check(preload("res://scripts/ui/combat_effect_text.gd").magnitude_for("buff.touch_of_darkness", tb.state.snapshot("touch.1")).contains("+12"), "Touch inspector reports effective physical strength")
	check(tb.state.snapshot("touch.1").expires_at_ms == 15500, "Touch duration unchanged")
	check(tb.state.advance(15500) == "", "Touch expires at original deadline")
	near(tb.live_player(p).bonus_physical_damage, 0.0, "Touch expiration removes bonus")
	var b := Buffs.new()
	b.legendary_crown = true
	check(b.grant("beguiling_presence", 0, {}, 7.0, 3) == "", "Beguiling granted")
	check(b.grant("beguiling_presence", 1000, {}, 4.0, 2) == "", "Beguiling independent second grant")
	near(b.values().elemental_base, 22.0, "Beguiling additive elemental strength")
	near(b.values().crit_chance, 0.2, "Beguiling additive crit strength")
	near(b.instances[0].magnitude, 14.0, "Crown Beguiling inspector effective elemental strength")
	near(b.instances[0].crit_chance_bonus, 0.12, "Crown Beguiling inspector effective crit strength")
	b.advance(10000)
	near(b.values().elemental_base, 8.0, "Independent first Beguiling expiration")
	b.advance(11000)
	near(b.values().crit_chance, 0.0, "Independent second Beguiling expiration")
	check(b.grant("master_of_poisons", 11000, {}) == "", "Boolean buff grant")
	check(b.values().ignore_resistance, "Boolean Crown unchanged")
	check(b.grant("virulent_poison", 11000, {}) == "", "Virulent first independent grant")
	near(b.values().poison_multiplier, 3.0, "Crown x2 becomes x3")
	b.spend_poison_charges(11000)
	check(b.grant("virulent_poison", 11001, {}) == "", "Virulent second independent grant")
	near(b.values().poison_multiplier, 9.0, "Independent Crown multipliers compose x3*x3")
	for i in range(4): b.spend_poison_charges(11002 + i)
	near(b.values().poison_multiplier, 3.0, "First instance expires after unchanged five charges")
	var remaining: Array = b.instances.filter(func(v): return v.kind == "virulent_poison")
	check(remaining.size() == 1 and remaining[0].charges == 1, "Second independent instance retains one charge")
	b.spend_poison_charges(11010)
	near(b.values().poison_multiplier, 1.0, "Virulent exhaustion removes all strength")
	b.advance(16000)
	check(not b.values().ignore_resistance, "Boolean expires at unchanged five seconds")
	var lc := Lifecycle.new(2, true, null, null, {"legendary_crown": true})
	lc.finish_cast("skill.quick_cut", true, false, 0)
	lc.finish_cast("skill.quick_cut", true, false, 0)
	near(lc.preview_execution_ms("skill.leaping_plunge", 1000, 100, 0), 680.0, "Footwork doubled reduction rank2 two stacks")
	var used: Dictionary = lc.begin_cast("skill.leaping_plunge", 1000, 100, 0)
	check(used.footwork_consumed == 2 and used.execution_ms == 680, "Footwork consumes original stack count")
	for i in range(5): lc.finish_cast("skill.quick_cut", true, false, 1)
	near(lc.preview_execution_ms("skill.leaping_plunge", 1000, 700, 1), 700.0, "Footwork respects ordinary skill minimum")
	check(lc.state.snapshot("footwork").stacks == 5, "Footwork original cap five")
	var ss := State.new(p)
	var eff := Effects.new(ss)
	check(eff.define("dash", {"source_id": "skill.dash", "duration_ms": 2000, "cap": 1, "mode": "replace", "unit": "stacks", "stat_inputs": {StatCatalog.INCREASED_ATTACK_SPEED: 0.2}}) == "", "Representative Dash uses actual stat lifecycle")
	eff.grant("dash", 1, 0)
	near(ss.snapshot().attack_speed, 0.4, "Dash additive strength doubles")
	eff.advance(2000)
	near(ss.snapshot().attack_speed, 0.0, "Dash representative duration unchanged")
	ss.replace_source("ordinary", "talent.ordinary_passive", [mod(StatCatalog.INCREASED_ATTACK_SPEED, 0.2)], 2000)
	near(ss.snapshot().attack_speed, 0.2, "Ordinary passive source not Crown buff")
	witnesses.crown = {"bypass": "cap3 +60%", "touch": "3 consumed +60% IAS +12 flat", "virulent": "x3; independent x9; five charges each", "footwork": "rank2 count2 680ms; unchanged skill minimum", "dash": "actual lifecycle representative, not authored content"}
func signet_coin() -> void:
	var c := ClassDef.new()
	c.base_stats = PlayerStats.new()
	c.base_stats.crit_chance = 0.1
	var t := Talent.new()
	t.id = "test.crit_talent"
	t.stat_modifiers = [mod(StatCatalog.CRIT_CHANCE, 0.4)]
	var g := GearItem.new()
	g.id = "test.overcap_gear"
	g.affixes = [mod(StatCatalog.CRIT_CHANCE, 1.5), mod(StatCatalog.CRIT_DAMAGE, 0.5), mod(StatCatalog.ALL_STATS_INCREASED, 1.0), mod(StatCatalog.CHANCE_FOR_RETRIGGER, 0.5), mod(StatCatalog.INCREASED_MAGIC_FIND, 0.5)]
	var talents: Array[Talent] = [t, rule_talent("double_dip", 0.5), rule_talent("fill_your_pockets", 0.5)]
	var raw := BuildResolver.resolve_stats(c, [], talents, [g], 0, [], {"signet": true, "coin": true})
	check(raw.derivation_error == "", "Actual BuildResolver test override resolves")
	near(raw.crit_chance, 2.6, "Unclamped class talent gear DoubleDip; AllStats once")
	near(raw.retrigger_chance, 0.6, "DoubleDip source global retrigger only")
	near(raw.magic_find, 1.2, "Coin total MF after AllStats doubled once")
	near(raw.elemental_damage_multiplier, 1.6, "Fill Your Pockets reads Coin total MF")
	var economy := root.get_node("BuildState")
	var depth_chance: int = economy._scaled_reward_upgrade_chance_bp(1000, 1, 0.0)
	near(economy._scaled_reward_upgrade_chance_bp(1000, 1, raw.magic_find), roundi(depth_chance * 2.2), "Existing economy consumer receives doubled total MF")
	var live := Live.resolve(raw, 0, 0)
	near(live.attack_speed, 5.2, "Overcap 260% crit gives +520% IAS")
	near(live.physical_damage_multiplier, 4.2, "Inherent x2 crit plus gear x0.6 gives +320% physical")
	near(Live.chance(live, 1.0), 0.0, "Signet effective hit no crit")
	var state := State.new(raw)
	state.replace_source("temporary.crit", "test.temporary_crit", [mod(StatCatalog.CRIT_CHANCE, 0.5)], 100)
	near(Live.resolve(state.snapshot(), 0, 0).attack_speed, 6.2, "Temporary numeric crit source feeds live Signet")
	state.remove_source("temporary.crit", 200)
	near(Live.resolve(state.snapshot(), 0, 0).attack_speed, 5.2, "Temporary numeric source removal restores conversion")
	state.replace_source("temporary.mf", "test.temporary_mf", [mod(StatCatalog.INCREASED_MAGIC_FIND, 0.2)], 300)
	near(state.snapshot().magic_find, 1.6, "Coin rebuild uses undoubled raw baseline plus source")
	near(state.snapshot().elemental_damage_multiplier, 1.8, "Coin rebuilt total feeds downstream derivation")
	state.remove_source("temporary.mf", 400)
	near(state.snapshot().magic_find, 1.2, "Coin does not accumulate across rebuilds")
	var base := BuildResolver.resolve_stats(c, [], talents, [g])
	near(base.crit_chance, 1.0, "Flags off preserves baseline crit cap")
	near(base.magic_find, 0.6, "Flags off preserves baseline MF")
	near(base.elemental_damage_multiplier, 1.3, "Flags off baseline Fill Your Pockets")
	var coin_only := BuildResolver.resolve_stats(c, [], [], [g], 0, [], {"coin": true})
	near(coin_only.magic_find, 1.2, "Coin works with no derived-stat talents")
	var gold := raw.duplicate(true) as PlayerStats
	gold.gilded_blade_enabled = true
	gold.silvered_edge_rank = 2
	gold.crit_chance_per_stolen_gold = 0.01
	gold.crit_multiplier_per_current_gold = 0.001
	var ga := Live.resolve(gold, 100, 10, {"crit_chance": 0.2})
	near(ga.attack_speed, 6.0, "Gold legacy theft Silvered and Beguiling all feed Signet")
	near(ga.physical_damage_multiplier, 6.4, "Gold Gilded and legacy stash feed Signet")
	var gb := Live.resolve(ga, 200, 30)
	near(gb.attack_speed, 6.4, "Live stash theft conversion is replacement not accumulation")
	near(gb.physical_damage_multiplier, 8.6, "Live stash replacement physical conversion")
	witnesses.signet_coin = {"raw_crit": raw.crit_chance, "ias": live.attack_speed, "physical": live.physical_damage_multiplier, "magic_find": raw.magic_find, "fill_your_pockets_elemental": raw.elemental_damage_multiplier, "baseline_crit": base.crit_chance}
func live_engine() -> void:
	var p := PlayerStats.new()
	p.legendary_signet = true
	p.crit_chance = 1.5
	p.side_step_enabled = true
	p.critical_poison_enabled = true
	p.base_poison_damage = 10.0
	p.poison_damage_per_tick = 10.0
	var parry := skill("skill.parry_strike")
	var poison := PoisonDamageEffect.new()
	poison.stacks_applied = 5
	parry.effects.append(poison)
	var result := CombatResolver.resolve([parry], p, target(), 2500, 3, true)
	check(result.cast_events.size() >= 4, "Actual engine scheduler consumes Signet IAS")
	for event in result.cast_events:
		check(not event.is_crit, "Signet suppresses actual Side Step guaranteed crit")
		near(event.stat_snapshot.get("effective_crit_chance", -1.0), 0.0, "Actual hit effective crit zero")
		near(event.stat_snapshot.attack_speed, 3.0, "Actual hit IAS not from SideStep guarantee")
	var ticks := 0
	for tick in result.tick_events:
		if tick.had_active_stack:
			ticks += 1
			check(not tick.is_crit and tick.crit_chance == 0.0, "Actual Critical Poison universally suppressed")
	check(ticks > 0, "Actual poison tick witness present")
	var ordinary := p.duplicate(true) as PlayerStats
	ordinary.legendary_signet = false
	var baseline := CombatResolver.resolve([parry], ordinary, target(), 1000, 3, true)
	check(baseline.cast_events[0].is_crit, "Flags off SideStep still guaranteed crit")
	var crown_p := PlayerStats.new()
	crown_p.legendary_crown = true
	crown_p.footwork_rank = 2
	crown_p.riposte_rank = 1
	var quick := skill("skill.quick_cut")
	var plunge := skill("skill.leaping_plunge")
	var riposte := CombatResolver.resolve([quick, plunge], crown_p, target(), 2500, 3, true)
	check(riposte.cast_events.size() >= 2, "Actual Riposte combat witness")
	near(riposte.cast_events[1].lifecycle_snapshot.get("riposte_multiplier", 0.0), 1.4, "Crown doubles Riposte bonus only")
	witnesses.engine = {"casts": result.cast_events.size(), "active_poison_ticks": ticks, "no_crits": true, "riposte_multiplier": riposte.cast_events[1].lifecycle_snapshot.get("riposte_multiplier", 0.0)}
func bandit() -> void:
	var p := PlayerStats.new()
	p.legendary_bandit = true
	p.bonus_physical_damage = 7.0
	var current := p
	for pair in [[0, 0], [9, 0], [10, 1], [19, 1], [20, 2], [999, 99], [1000, 100], [10000, 100], [9, 0], [-1, 0]]:
		current = Live.resolve(current, pair[0], 0)
		near(current.bonus_physical_damage, 7.0 + pair[1], "Bandit live floor/cap/replacement gold=" + str(pair[0]))
	var hit := skill("test.bandit", 10.0)
	p.current_gold = 19
	var theft := preload("res://scripts/resources/steal_gold_effect.gd").new()
	theft.amount = 1
	hit.effects.append(theft)
	var result := CombatResolver.resolve([hit], p, target(), 2000, 3, true)
	near(result.cast_events[0].physical_damage, 18.0, "Bandit actual pre-theft damage includes flat bucket")
	near(result.cast_events[1].physical_damage, 19.0, "Bandit recomputes actual next-hit gold crossing")
	check(p.bonus_physical_damage == 7 and p.current_gold == 19, "Bandit input resource stays immutable")
	witnesses.bandit = {"first_damage": result.cast_events[0].physical_damage, "second_damage": result.cast_events[1].physical_damage, "cap": 100, "no_accumulation": true}

func production_wiring() -> void:
	for id in BuildResolver.LEGENDARY_EFFECT_IDS:
		var item := GearItem.new()
		item.id = "test.legendary." + id
		item.legendary_effect_id = id
		var equipped := BuildResolver.resolve_stats(null, [], [], [item])
		check(bool(equipped.special_effects.legendary.get(id, false)), "Equipped signature enabled without opt-in: " + id)
		var carried := BuildResolver.resolve_stats(null, [], [], [], 0, [item])
		check(not bool(carried.special_effects.legendary.get(id, false)), "Carried item does not enable signature: " + id)
	var signet := GearItem.new()
	signet.id = "test.production.signet"
	signet.legendary_effect_id = "signet"
	signet.affixes = [mod(StatCatalog.CRIT_CHANCE, 1.5), mod(StatCatalog.CRIT_DAMAGE, 0.5)]
	var resolved := BuildResolver.resolve_stats(null, [], [], [signet])
	near(resolved.attack_speed, 3.0, "Build consumers see effective Signet IAS")
	near(resolved.physical_damage_multiplier, 4.0, "Build consumers see effective Signet physical increase")
	near(resolved.crit_chance, 1.5, "Uncapped numeric crit retained for live conversion")
	check(resolved.derivation_base != null, "Effective Signet retains raw rebuild baseline")
	near(Live.resolve(resolved, 0, 0).attack_speed, 3.0, "Effective build can enter combat without duplicate Signet IAS")
	var temporary := State.new(resolved)
	check(temporary.replace_source("crit", "test.crit", [mod(StatCatalog.CRIT_CHANCE, 0.2)], 0) == "", "Resolved Signet rebase accepts live source")
	near(Live.resolve(temporary.snapshot(), 0, 0).attack_speed, 3.4, "Signet rebuild uses raw baseline once")
	check(temporary.remove_source("crit", 1) == "", "Resolved Signet source expires")
	near(Live.resolve(temporary.snapshot(), 0, 0).attack_speed, 3.0, "Signet expiry restores converted build")
	check(temporary.replace_source("crit_damage", "test.crit_damage", [mod(StatCatalog.CRIT_DAMAGE, 0.25)], 2) == "", "Signet accepts temporary numeric Crit Damage")
	near(Live.resolve(temporary.snapshot(), 0, 0).physical_damage_multiplier, 4.5, "Signet converts temporary Crit Damage above normal hit")
	check(temporary.remove_source("crit_damage", 3) == "", "Temporary Crit Damage expires")
	near(Live.resolve(temporary.snapshot(), 0, 0).physical_damage_multiplier, 4.0, "Signet expiry removes temporary Crit Damage conversion")
	var bandit_item := GearItem.new()
	bandit_item.id = "test.production.bandit"
	bandit_item.legendary_effect_id = "bandit"
	bandit_item.physical_damage_per_gold = 0.1
	var bandit_stats := BuildResolver.resolve_stats(null, [], [], [bandit_item], 19)
	near(bandit_stats.bonus_physical_damage, 1.0, "Production Bandit replaces legacy uncapped per-gold contribution")
	var bandit_state := State.new(bandit_stats)
	near(Live.resolve(bandit_state.snapshot(), 20, 0).bonus_physical_damage, 2.0, "Bandit raw rebase reads new stash once")
	var cloak := GearItem.new()
	cloak.id = "test.production.cloak"
	cloak.legendary_effect_id = "cloak"
	var quick := skill("skill.quick_cut")
	cloak.unlocked_skills = [quick]
	var augment := SkillAugment.new()
	augment.target_skill_ids = ["skill.quick_cut"]
	augment.poison_stacks_applied = 3
	var tree := SubclassTree.new()
	tree.skill_augments = [augment]
	var cloak_stats := BuildResolver.resolve_stats(null, [tree], [], [cloak])
	var captured: Skill = cloak_stats.special_effects.legendary.quick_cut
	check(captured != quick and captured.poison_stacks_applied == 3, "Cloak captures cloned build-augmented Quick Cut without recursion")
	check(quick.poison_stacks_applied == 0, "Captured augmentation leaves authored Quick Cut immutable")
	var legacy_poison: Skill = load("res://data/skills/poison_strike.tres")
	var legacy_talent := Talent.new()
	legacy_talent.unlocked_skills = [legacy_poison]
	var poison_augment := SkillAugment.new()
	poison_augment.target_skill_ids = ["skill.poison_strike"]
	poison_augment.poison_stacks_applied = 3
	var poison_tree := SubclassTree.new()
	poison_tree.skill_augments = [poison_augment]
	var decrepit: GearItem = load("res://data/gear/decrepit_blade.tres")
	var poison_skills := BuildResolver.resolve_unlocked_skills(null, [poison_tree], [legacy_talent], [decrepit])
	check(poison_skills.size() == 1, "Legacy talent plus Decrepit keeps one shared Poison Strike ID")
	check(poison_skills[0].effects.any(func(effect): return effect.get_script() == preload("res://scripts/resources/forced_poison_tick_effect.gd")), "Equipped Decrepit canonicalizes earlier same-ID legacy skill to forced Poison definition")
	check(poison_skills[0].poison_stacks_applied == 3, "Decrepit canonicalization preserves subsequent build augmentation")
	var restored_poison := BuildResolver.resolve_unlocked_skills(null, [], [legacy_talent], [])
	check(restored_poison.size() == 1 and not restored_poison[0].effects.any(func(effect): return effect.get_script() == preload("res://scripts/resources/forced_poison_tick_effect.gd")), "Removing Decrepit restores legacy same-ID unlock behavior")
	check(legacy_poison.poison_stacks_applied == 0, "Decrepit canonicalization leaves legacy resource unchanged")
	var class_def := ClassDef.new()
	class_def.base_stats = PlayerStats.new()
	class_def.base_stats.bonus_poison_stacks = 9
	var stacks := GearItem.new()
	stacks.affixes = [mod(StatCatalog.INCREASED_ALL_STACKS, 5.0)]
	var stack_talent := Talent.new()
	stack_talent.stat_modifiers = [mod(StatCatalog.INCREASED_ALL_STACKS, 2.0)]
	var stack_stats := BuildResolver.resolve_stats(class_def, [], [stack_talent], [stacks])
	check(stack_stats.special_effects.legendary.all_stacks == 7, "Legendary grants count actual All Stacks without Poison-only bonuses")
	check(stack_stats.bonus_poison_stacks == 16, "Poison-only bonus remains eligible for Poison")
	var coin := GearItem.new()
	coin.legendary_effect_id = "coin"
	near(BuildResolver.resolve_stats(null, [], [], [coin]).magic_find, 0.0, "Coin doubles zero total MF to zero")
	coin.affixes = [mod(StatCatalog.INCREASED_MAGIC_FIND, 0.5)]
	var coin_stats := BuildResolver.resolve_stats(null, [], [], [coin])
	near(coin_stats.magic_find, 1.0, "Coin total Magic Find initially doubled once")
	var coin_state := State.new(coin_stats.duplicate(true))
	near(coin_state.snapshot().magic_find, 1.0, "Coin marker prevents double scaling after Resource copy loses runtime baseline")
	check(coin_state.replace_source("mf", "test.magic_find", [mod(StatCatalog.INCREASED_MAGIC_FIND, 0.2)], 0) == "", "Copied Coin baseline accepts temporary Magic Find")
	near(coin_state.snapshot().magic_find, 1.4, "Coin doubles rebuilt source total once")
	var coin_rebased := State.new(coin_state.snapshot())
	near(coin_rebased.snapshot().magic_find, 1.0, "Coin rebase uses raw build baseline without carrying fight-local sources")

func live_sources() -> void:
	var p := PlayerStats.new()
	p.legendary_signet = true
	p.crit_chance = 0.5
	p.bonus_decay_stacks = 9
	var apply := skill("test.apply_decay")
	apply.effects.clear()
	apply.effects.append(PoisonResistanceReductionEffect.new())
	var consume := skill("test.beguiling")
	consume.category = Skill.Category.SELF_BUFF
	consume.effects.clear()
	var effect := preload("res://scripts/resources/consume_status_effect.gd").new()
	effect.status = "decay"
	effect.elemental_per_consumed = 1.0
	consume.effects.append(effect)
	var attack := skill("test.live_beguiling_hit")
	var wait_skill := skill("test.wait")
	wait_skill.category = Skill.Category.SELF_BUFF
	wait_skill.base_execution_ms = 10000
	wait_skill.min_execution_ms = 10000
	wait_skill.effects.clear()
	var result := CombatResolver.resolve([apply, consume, attack, wait_skill, attack], p, target(), 14000, 3, true)
	var hits: Array = result.cast_events.filter(func(v): return v.skill.id == attack.id)
	check(hits.size() >= 2, "Actual Beguiling before/after expiry hits")
	if hits.size() >= 2:
		near(hits[0].stat_snapshot.attack_speed, 1.4, "Actual consumed Decay Beguiling crit converted into IAS")
		near(hits[1].stat_snapshot.attack_speed, 1.0, "Actual Beguiling expiry removes Signet IAS")
		check(hits[0].time_ms - hits[0].cast_start_ms < hits[1].time_ms - hits[1].cast_start_ms, "Actual scheduler rebuilds after Beguiling expiration")
	var expired := false
	for row in result.trace.records:
		if row.kind == "effect_lifecycle" and row.payload.get("effect_id", "") == "beguiling_presence" and row.get("lifecycle_reason", "") == "expired": expired = true
	check(expired, "Actual Beguiling expiry trace")
	var gold := PlayerStats.new()
	gold.legendary_signet = true
	gold.gilded_blade_enabled = true
	gold.silvered_edge_rank = 1
	gold.crit_chance_per_stolen_gold = 0.01
	var thief := skill("test.live_theft")
	var steal := preload("res://scripts/resources/steal_gold_effect.gd").new()
	steal.amount = 10
	thief.effects.append(steal)
	var theft := CombatResolver.resolve([thief], gold, target(), 3000, 3, true)
	check(theft.cast_events.size() >= 2, "Actual live theft witness")
	near(theft.cast_events[0].stat_snapshot.attack_speed, 0.0, "Signet initial no theft IAS")
	near(theft.cast_events[1].stat_snapshot.attack_speed, 0.4, "Actual theft Silvered and legacy crit feed next IAS")
	near(theft.cast_events[0].physical_damage, 30.0, "Signet inherent x2 gives actual +200% physical")
	near(theft.cast_events[1].physical_damage, 32.0, "Actual Gilded stash changes next-hit physical conversion")
	var mythril: GearItem = load("res://data/gear/mithril_karambit.tres")
	var built := BuildResolver.resolve_stats(null, [], [rule_talent("double_dip", 1.0)], [mythril], 0, [], {"signet": true})
	near(built.retrigger_chance, 0.0, "Mithril local 50 points excluded from global numeric retrigger")
	near(built.crit_chance, 0.15, "DoubleDip excludes Mithril local chance")
	near(Live.resolve(built, 0, 0).attack_speed, 0.45, "Mithril local chance cannot leak into Signet IAS through DoubleDip")
	witnesses.live_sources = {"beguiling_hit_ias": hits[0].stat_snapshot.attack_speed if hits.size() > 0 else -1, "expired_hit_ias": hits[1].stat_snapshot.attack_speed if hits.size() > 1 else -1, "theft_next_ias": theft.cast_events[1].stat_snapshot.attack_speed, "theft_next_physical": theft.cast_events[1].physical_damage, "mithril_numeric_retrigger": built.retrigger_chance}
