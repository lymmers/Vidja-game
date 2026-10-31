extends RefCounted
class_name DamagePipeline
## Resolves one hit and its HP ledger. No skill names, charges, or timing.
## The caller supplies currently available reactions, as plain effect data.


static func resolve(
	target: BattleUnit,
	base_roll: int,
	damage_type: String,
	attack_modifiers: Array[Dictionary],
	defense_modifiers: Array[Dictionary],
	incoming_effects: Array[Dictionary]
) -> Dictionary:
	var base_damage: int = maxi(1, base_roll)
	var damage: int = base_damage
	var steps: Array[Dictionary] = []
	var triggered: Array[Dictionary] = []

	for modifier in attack_modifiers:
		damage = _apply_modifier(damage, modifier, steps, false)

	# "Always" reactions such as temporary invulnerability prevent the hit
	# before defenses are calculated. The adjustment still balances the ledger.
	for effect in incoming_effects:
		if not _matches_damage_type(effect, damage_type):
			continue
		if str(effect.get("trigger", "")) == "always" and str(effect.get("operation", "")) == "negate_damage":
			steps.append({"name": str(effect.get("name", "Immunity")), "amount": -damage})
			triggered.append(effect.duplicate(true))
			return _result(base_damage, steps, 0, damage_type, triggered, true)

	for modifier in defense_modifiers:
		if _matches_damage_type(modifier, damage_type):
			damage = _apply_modifier(damage, modifier, steps, true)

	# Reactive survival effects occur *after* all regular mitigations. The
	# first applicable effect wins, allowing deterministic stacking rules.
	for effect in incoming_effects:
		if not _matches_damage_type(effect, damage_type):
			continue
		if str(effect.get("trigger", "")) != "lethal" or str(effect.get("operation", "")) != "leave_hp":
			continue
		if target.hp <= 0 or damage < target.hp:
			continue
		var hp_floor: int = clampi(int(effect.get("hp_floor", 1)), 0, target.hp)
		var surviving_damage: int = target.hp - hp_floor
		if surviving_damage < damage:
			steps.append({"name": str(effect.get("name", "Survival")), "amount": surviving_damage - damage})
			damage = surviving_damage
			triggered.append(effect.duplicate(true))
		break

	# Damage displayed in the log must be *HP actually removed*, even when
	# an attack exceeds the defender's remaining health (overkill).
	if damage > target.hp:
		steps.append({"name": "Overkill", "amount": target.hp - damage})
		damage = target.hp

	target.take_damage(damage)
	return _result(base_damage, steps, damage, damage_type, triggered, false)


static func _matches_damage_type(effect: Dictionary, damage_type: String) -> bool:
	return str(effect.get("damage_type", damage_type)) == damage_type


static func _apply_modifier(current: int, modifier: Dictionary, steps: Array[Dictionary], is_defense: bool) -> int:
	var operation: String = str(modifier.get("operation", "add"))
	var value: float = float(modifier.get("value", modifier.get("amount", 0)))
	var updated: int = current
	match operation:
		"add":
			updated = current + roundi(value)
		"subtract":
			updated = current - roundi(value)
		"multiply":
			updated = roundi(float(current) * value)
		_:
			push_error("Unknown damage operation: %s" % operation)
			return current
	if is_defense:
		updated = maxi(1, updated)
	if updated != current:
		steps.append({"name": str(modifier.get("name", "Modifier")), "amount": updated - current})
	return updated


static func _result(base: int, steps: Array[Dictionary], applied: int, damage_type: String, triggered: Array[Dictionary], immune: bool) -> Dictionary:
	return {
		"base_damage": base,
		"modifiers": steps,
		"damage": applied,
		"damage_type": damage_type,
		"triggered_effects": triggered,
		"immune": immune,
	}