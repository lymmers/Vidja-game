extends RefCounted
class_name TurnScheduler
## Logical action ordering. No timers, animation callbacks, or skill-name checks.
## A round contains each living actor once, plus any explicitly queued bonus actions.

const DEFAULT_SIDE_PRIORITY: Dictionary = {"player": 100, "enemy": 0}
var roster: Array[Dictionary] = []
var modifiers: Array[Dictionary] = []
var pending: Array[String] = []
var bonus_actions: Array[String] = []
var skipped_actions: Dictionary = {}

func configure(actors: Array[Dictionary], priority_modifiers: Array[Dictionary] = []) -> void:
	roster = actors.duplicate(true)
	modifiers = priority_modifiers.duplicate(true)
	pending.clear()
	bonus_actions.clear()
	skipped_actions.clear()

func _priority(actor: Dictionary) -> int:
	var score: int = int(DEFAULT_SIDE_PRIORITY.get(actor["side"], 0)) + int(actor.get("initiative", 0))
	for modifier in modifiers:
		if modifier.get("actor_id", "") == actor["id"] or (modifier.get("actor_id", "") == "" and modifier.get("side", "") == actor["side"]):
			score += int(modifier.get("add", 0))
	return score

func _new_round(alive: Array[String]) -> void:
	var active: Array[Dictionary] = []
	for actor in roster:
		if alive.has(str(actor["id"])):
			active.append(actor)
	# Stable ties preserve registration order: hero, companion(s), then enemies.
	active.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var pa: int = _priority(a)
		var pb: int = _priority(b)
		return pa > pb if pa != pb else int(a["order"]) < int(b["order"])
	)
	for actor in active:
		pending.append(str(actor["id"]))

func next_actor(alive: Array[String]) -> String:
	if alive.is_empty():
		return ""
	# An extra action is resolved before the next scheduled action.
	while not bonus_actions.is_empty():
		var bonus: String = bonus_actions.pop_front()
		if alive.has(bonus):
			return bonus
	if pending.is_empty():
		_new_round(alive)
	while not pending.is_empty():
		var candidate: String = pending.pop_front()
		if not alive.has(candidate):
			continue
		var skips: int = int(skipped_actions.get(candidate, 0))
		if skips > 0:
			skipped_actions[candidate] = skips - 1
			continue
		return candidate
	# Every remaining actor in this round might be stunned/dead.
	return ""

func add_bonus_action(actor_id: String) -> void:
	# Callers must validate the ID. An effect handler caps action chains.
	bonus_actions.append(actor_id)

func skip_actions(actor_id: String, count: int) -> void:
	skipped_actions[actor_id] = int(skipped_actions.get(actor_id, 0)) + maxi(count, 0)