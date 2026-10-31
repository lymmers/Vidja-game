extends RefCounted
class_name SkillCatalog
## Each skill can own ANY number of event-driven effect definitions.
## Effect IDs are stable per actor and serve as charge counters; names are UI only.

const DEFINITIONS: Dictionary = {
	"fireball": {
		"name": "FIREBALL", "symbol": "F", "color": Color("e99a5a"),
		"description": "50% chance on attack to cast a fireball dealing 150% attack damage.",
		"effects": [
			{"id": "fireball:bolt", "name": "Fireball (150%)", "trigger": "after_attack",
			 "operation": "bonus_hit", "kind": "fireball", "damage_type": "magic",
			 "chance": 0.5, "power_multiplier": 1.5},
		],
	},
	"iron_skin": {
		"name": "IRON SKIN", "symbol": "I", "color": Color("a7b9cf"),
		"description": "Take 20% less damage from physical attacks.",
		"effects": [
			{"id": "iron_skin:physical", "name": "Iron Skin (20%)", "trigger": "before_damage",
			 "operation": "multiply", "value": 0.8, "damage_type": "physical"},
		],
	},
	"final_stand": {
		"name": "FINAL STAND", "symbol": "+", "color": Color("e4c76c"),
		"description": "Once per encounter, lethal damage leaves you at 1 HP and grants immunity for the rest of that action.",
		"effects": [
			{"id": "final_stand:survive", "name": "Final Stand", "trigger": "lethal",
			 "operation": "leave_hp", "hp_floor": 1, "uses_per_encounter": 1,
			 "grants_immunity": "action"},
		],
	},
}

static func details(id: String) -> Dictionary:
	return DEFINITIONS.get(id, {})

static func effects_for(id: String, trigger: String) -> Array[Dictionary]:
	var output: Array[Dictionary] = []
	for effect in details(id).get("effects", []):
		if effect.get("trigger", "") == trigger:
			output.append(effect.duplicate(true))
	return output

static func get_choices(owned: Array[String], max_choices: int, rng: RandomNumberGenerator) -> Array[String]:
	var remaining: Array[String] = []
	for id in DEFINITIONS.keys():
		if not owned.has(str(id)):
			remaining.append(str(id))
	var selection: Array[String] = []
	while not remaining.is_empty() and selection.size() < maxi(0, max_choices):
		selection.append(remaining.pop_at(rng.randi_range(0, remaining.size() - 1)))
	return selection