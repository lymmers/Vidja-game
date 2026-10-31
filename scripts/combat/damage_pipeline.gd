extends RefCounted
class_name DamagePipeline
## Resolves one hit and produces a truthful audit trail of HP changes.
## The caller supplies ordered, named modifiers; this module never knows skill names.


static func resolve(
	target: BattleUnit,
	base_roll: int,
	damage_type: String,
	attack_modifiers: Array[Dictionary],
	defense_modifiers: Array[Dictionary],
	final_stand_available: bool,
	immune_for_action: bool
) -> Dictionary:
	var base_damage: int = maxi(1, base_roll)
	var damage: int = base_damage
	var steps: Array[Dictionary] = []

	# Each step records the change actually applied *after rounding/clamping*.
	for modifier in attack_modifiers:
		damage = _apply_modifier(damage, modifier, steps, false)

	if immune_for_action:
		steps.append({"name": "Final Stand Immunity", "amount": -damage})
		return _result(base_damage, steps, 0, damage_type, false, true)

	for modifier in defense_modifiers:
		if modifier.get("damage_type", damage_type) != damage_type:
			continue
		damage = _apply_modifier(damage, modifier, steps, true)

	var used_final_stand: bool = false
	if final_stand_available and damage >= target.hp and target.hp > 0:
		var surviving_damage: int = target.hp - 1
		steps.append({"name": "Final Stand", "amount": surviving_damage - damage})
		damage = surviving_damage
		used_final_stand = true

	# A hit can calculate 30 damage but only remove 4 remaining HP.
	# Record that distinction so combat logs always reconcile to HP lost.
	if damage > target.hp:
		steps.append({"name": "Overkill", "amount": target.hp - damage})
		damage = target.hp

	target.take_damage(damage)
	return _result(base_damage, steps, damage, damage_type, used_final_stand, false)


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
		# Existing combat rule: ordinary mitigation cannot bring a hit below 1.
		updated = maxi(1, updated)
	if updated != current:
		steps.append({"name": str(modifier.get("name", "Modifier")), "amount": updated - current})
	return updated


static func _result(base: int, steps: Array[Dictionary], applied: int, damage_type: String, stand: bool, immune: bool) -> Dictionary:
	return {
		"base_damage": base,
		"modifiers": steps,
		"damage": applied,
		"damage_type": damage_type,
		"final_stand": stand,
		"immune": immune,
	}