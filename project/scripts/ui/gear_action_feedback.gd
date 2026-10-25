extends RefCounted
## Explanations for existing Adventure transaction guards; no state changes.
static func legendary_reason(state, item: GearItem) -> String:
	if item == null or item.tier != GearItem.Tier.LEGENDARY: return ""
	for owned in state.inventory + state.equipped_gear():
		if owned != null and owned.id == item.id: return "Already owned."
	if item.legendary_effect_id == "coin" and not state.mysterious_coin_unlocked:
		return "Not unlocked for this run."
	return ""
