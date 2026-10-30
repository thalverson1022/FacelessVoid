class_name BuildProgression
extends RefCounted
## One policy shared by allocation, Adventure rewards and Practice Room.
const POINT_CAP := 45
const CONTRACT_POINTS := 3
const TAVERN_TOTAL := 6
const TAVERN_POINTS := [1, 0, 2, 3]

static func reward_amount(earned: int, amount: int) -> int:
	return mini(maxi(0, amount), maxi(0, POINT_CAP - earned))
