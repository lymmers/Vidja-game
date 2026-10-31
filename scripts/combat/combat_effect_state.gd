extends RefCounted
class_name CombatEffectState
## Tracks limited-use reactions and temporary immunity for any combatant.
## This class knows effect *operations*, never skill IDs or enemy names.

var uses_this_encounter: Dictionary = {}
var action_immunity: Dictionary = {}


func start_encounter() -> void:
	uses_this_encounter.clear()
	action_immunity.clear()


func begin_action() -> void:
	# A logical action may contain multiple hits; animation frames do not matter.
	action_immunity.clear()


func available_reactions(target_key: String, definitions: Array[Dictionary]) -> Array[Dictionary]:
	var available: Array[Dictionary] = []

	# Granted immunity is checked before armor or other mitigation. Its origin
	# is retained for the combat log even if the original skill is now spent.
	if action_immunity.has(target_key):
		var source_name: String = str(action_immunity[target_key])
		available.append({
			"id": "action_immunity", "name": "%s Immunity" % source_name,
			"trigger": "always", "operation": "negate_damage",
		})

	for effect in definitions:
		var id: String = str(effect.get("id", ""))
		if id.is_empty():
			push_error("Reactive damage effect has no id")
			continue
		var allowed: int = int(effect.get("uses_per_encounter", 0))
		var state_key: String = "%s:%s" % [target_key, id]
		if allowed > 0 and int(uses_this_encounter.get(state_key, 0)) >= allowed:
			continue
		available.append(effect)
	return available


func record_triggers(target_key: String, triggered: Array[Dictionary]) -> void:
	for effect in triggered:
		var limited_uses: int = int(effect.get("uses_per_encounter", 0))
		if limited_uses > 0:
			var state_key: String = "%s:%s" % [target_key, str(effect["id"])]
			uses_this_encounter[state_key] = int(uses_this_encounter.get(state_key, 0)) + 1
		if str(effect.get("grants_immunity", "")) == "action":
			action_immunity[target_key] = str(effect.get("name", "Effect"))