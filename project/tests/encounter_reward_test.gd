extends SceneTree
## Headless P2:R3:T2 check for authored encounter reward data. Run with:
##   godot --headless --path project -s res://tests/encounter_reward_test.gd


func _initialize() -> void:
	var mouthy: Encounter = load("res://data/encounters/01_mouthy_drunk.tres")
	var buddy: Encounter = load("res://data/encounters/02_drunk_buddy.tres")
	var bouncer: Encounter = load("res://data/encounters/03_tavern_bouncer.tres")
	var goon: Encounter = load("res://data/encounters/04_hired_goon.tres")

	assert(mouthy.reward != null)
	print("Mouthy Drunk reward: %dg, %d talent point(s)" % [
		mouthy.reward.gold_amount, mouthy.reward.talent_points
	])
	assert(mouthy.reward.gold_amount == 12)
	assert(mouthy.reward.talent_points == 1)
	assert(not mouthy.reward.unlocks_shop)

	assert(buddy.reward != null)
	print("Drunk Buddy reward: %dg, fixed gear=%d, unlocks_shop=%s" % [
		buddy.reward.gold_amount,
		buddy.reward.fixed_gear_rewards.size(),
		buddy.reward.unlocks_shop,
	])
	assert(buddy.reward.gold_amount == 18)
	assert(buddy.reward.fixed_gear_rewards.size() == 1)
	var lucky_coin: GearItem = buddy.reward.fixed_gear_rewards[0]
	assert(lucky_coin.id == "gear.lucky_coin")
	assert(lucky_coin.display_name == "Lucky Coin")
	assert(lucky_coin.slot == GearItem.SlotType.TRINKET)
	assert(lucky_coin.tier == GearItem.Tier.BASIC)
	assert(lucky_coin.item_family == "Ring")
	assert(lucky_coin.source_kind == GearItem.SourceKind.FIXED)
	assert(lucky_coin.affixes.size() == 1)
	assert(lucky_coin.affixes[0].stat_id == "crit_chance")
	assert(lucky_coin.affixes[0].stat == StatModifier.StatType.CRIT_CHANCE)
	assert(is_equal_approx(lucky_coin.affixes[0].value, 0.05))
	assert(buddy.reward.unlocks_shop)

	assert(bouncer.reward != null)
	print("Tavern Bouncer reward: %dg, %d talent point(s)" % [
		bouncer.reward.gold_amount, bouncer.reward.talent_points
	])
	assert(bouncer.reward.gold_amount == 24)
	assert(bouncer.reward.talent_points == 2)

	assert(goon.reward != null)
	print("Hired Goon reward: %dg, %d talent point(s)" % [
		goon.reward.gold_amount, goon.reward.talent_points
	])
	assert(goon.reward.gold_amount == 36)
	assert(goon.reward.talent_points == 3)

	print("")
	print("Encounter reward data check: OK")
	quit()
