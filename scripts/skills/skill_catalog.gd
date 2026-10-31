extends RefCounted
class_name SkillCatalog
## Single source of truth for skills, their descriptions and draft eligibility.

const DEFINITIONS: Dictionary = {
	"fireball": {
		"name": "FIREBALL", "symbol": "F", "color": Color("e99a5a"),
		"description": "50% chance on attack to cast a fireball dealing 150% attack damage.",
		"on_attack": {
			"kind": "fireball", "damage_type": "magic", "chance": 0.5,
			"power_multiplier": 1.5, "modifier_name": "Fireball (150%)",
		},
	},
	"iron_skin": {
		"name": "IRON SKIN", "symbol": "I", "color": Color("a7b9cf"),
		"description": "Take 20% less damage from physical attacks.",
		"on_defend": {
			"name": "Iron Skin (20%)", "damage_type": "physical",
			"operation": "multiply", "value": 0.8,
		},
	},
	"final_stand": {
		"name": "FINAL STAND", "symbol": "+", "color": Color("e4c76c"),
		"description": "Once per encounter, lethal damage leaves you at 1 HP and grants immunity for the rest of that action.",
		"on_damage": {
			"name": "Final Stand", "trigger": "lethal", "operation": "leave_hp",
			"hp_floor": 1, "uses_per_encounter": 1, "grants_immunity": "action",
		},
	},
}


static func get_choices(owned: Array[String], max_choices: int, rng: RandomNumberGenerator) -> Array[String]:
	var remaining: Array[String] = []
	for id in DEFINITIONS.keys():
		if not owned.has(str(id)):
			remaining.append(str(id))
	var selection: Array[String] = []
	while not remaining.is_empty() and selection.size() < max_choices:
		selection.append(remaining.pop_at(rng.randi_range(0, remaining.size() - 1)))
	return selection


static func details(id: String) -> Dictionary:
	return DEFINITIONS.get(id, {})