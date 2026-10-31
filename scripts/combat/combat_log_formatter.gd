extends RefCounted
class_name CombatLogFormatter
## UI-ready messages from recorded hit results, not recalculated damage.

static func format_event(event: Dictionary, enemy_name: String) -> String:
	var enemy: String = enemy_name.capitalize()
	var actor: String = str(event.get("attacker", "hero"))
	var kind: String = str(event.get("kind", "attack"))
	var action_text: String
	if actor == "hero":
		action_text = "You hit %s" % enemy
		if kind == "fireball":
			action_text = "You hit %s with Fireball" % enemy
	else:
		action_text = "%s hit you" % enemy
		if kind == "potion":
			action_text = "%s hit you with Fire Potion" % enemy

	var damage: int = int(event.get("damage", 0))
	var dtype: String = str(event.get("damage_type", "physical")).capitalize()
	var breakdown: String = "%d base" % int(event.get("base_damage", damage))
	for modifier in event.get("modifiers", []):
		var amount: int = int(modifier.get("amount", 0))
		var sign: String = "+" if amount >= 0 else ""
		breakdown += " %s%d %s" % [sign, amount, str(modifier.get("name", "Modifier"))]

	var result: String = "%s for %d %s damage (%s)." % [action_text, damage, dtype, breakdown]
	if bool(event.get("critical", false)):
		result += " CRITICAL HIT!"
	if bool(event.get("final_stand", false)):
		result += " FINAL STAND! 1 HP remains."
	if bool(event.get("immune", false)):
		result += " IMMUNE!"
	return result