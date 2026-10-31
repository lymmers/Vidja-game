extends RefCounted
class_name DataValidator
## Pure validation for editable definitions; display these errors during development.

const SUPPORTED_TRIGGERS: Array[String] = ["after_attack", "before_damage", "lethal", "always", "after_damage", "on_kill"]
const SUPPORTED_OPS: Array[String] = ["bonus_hit", "multiply", "subtract", "add", "leave_hp", "negate_damage", "heal", "extra_action"]

static func validate_skill(definition: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	if str(definition.get("name", "")).is_empty():
		errors.append("Skill name is required")
	if not definition.get("effects", null) is Array:
		errors.append("Skill effects must be an array")
		return errors
	var seen: Dictionary = {}
	for effect in definition["effects"]:
		if not effect is Dictionary:
			errors.append("Each skill effect must be a dictionary")
			continue
		var id: String = str(effect.get("id", ""))
		if id.is_empty() or seen.has(id):
			errors.append("Effect ID missing or duplicated: %s" % id)
		seen[id] = true
		var trigger: String = str(effect.get("trigger", ""))
		var operation: String = str(effect.get("operation", ""))
		if not SUPPORTED_TRIGGERS.has(trigger):
			errors.append("Unknown trigger: %s" % trigger)
		if not SUPPORTED_OPS.has(operation):
			errors.append("Unknown operation: %s" % operation)
		if effect.has("chance") and (float(effect["chance"]) < 0.0 or float(effect["chance"]) > 1.0):
			errors.append("Chance must be between 0 and 1: %s" % id)
		if operation == "leave_hp" and int(effect.get("hp_floor", 0)) < 1:
			errors.append("leave_hp requires hp_floor >= 1: %s" % id)
		if operation == "bonus_hit" and not effect.has("damage_type"):
			errors.append("bonus_hit needs a damage_type: %s" % id)
	return errors

static func validate_encounter(definition: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	for key in ["name", "hp", "attack_min", "attack_max", "armor", "crit_chance"]:
		if not definition.has(key):
			errors.append("Encounter missing %s" % key)
	if not errors.is_empty():
		return errors
	if int(definition["hp"]) <= 0 or int(definition["attack_min"]) <= 0 or int(definition["attack_max"]) < int(definition["attack_min"]):
		errors.append("Encounter health/attack values are invalid")
	if float(definition["crit_chance"]) < 0.0 or float(definition["crit_chance"]) > 1.0:
		errors.append("Encounter crit chance outside 0..1")
	var special: Dictionary = definition.get("special_action", {})
	if not special.is_empty() and (int(special.get("every", 0)) <= 0 or not special.has("damage_type")):
		errors.append("Special action requires interval and damage_type")
	return errors