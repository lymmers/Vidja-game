extends RefCounted
class_name SkillCatalog
## Single source of truth for skills, their descriptions and draft eligibility.

const DEFINITIONS: Dictionary = {
	"fireball": {
		"name": "FIREBALL", "symbol": "F", "color": Color("e99a5a"),
		"description": "50% chance on attack to cast a fireball dealing 150% attack damage.",
	},
	"iron_skin": {
		"name": "IRON SKIN", "symbol": "I", "color": Color("a7b9cf"),
		"description": "Take 20% less damage from physical attacks.",
	},
	"final_stand": {
		"name": "FINAL STAND", "symbol": "+", "color": Color("e4c76c"),
		"description": "Once per encounter, lethal damage leaves you at 1 HP and grants immunity for the rest of that action.",
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