extends RefCounted
## T1/T2 boundary contract for future timed-effect consumers (T4/T5).
## An inclusive cast-start deadline and an exclusive grant deadline are distinct.
## Never globally clear a same-tick buff before its cast-start consumption.

static func available_at_cast_start(expires_at_ms: int, now_ms: int) -> bool:
	return now_ms <= expires_at_ms


static func expired_before_grant(expires_at_ms: int, now_ms: int) -> bool:
	return now_ms >= expires_at_ms
