extends RefCounted
class_name EncounterCatalog
## Enemy balance and attack patterns live here, not in the turn loop.
## A future enemy may add a special action by editing its definition only.

const ENCOUNTERS: Dictionary = {
	1: {
		"name": "MOSS GOBLIN", "hp": 72, "visual": "goblin", "area": "ASHEN PASS",
		"attack_min": 9, "attack_max": 13, "armor": 2, "crit_chance": 0.14,
	},
	2: {
		"name": "BONE ALCHEMIST", "hp": 75, "visual": "skeleton", "area": "BONE LABORATORY",
		"attack_min": 10, "attack_max": 14, "armor": 1, "crit_chance": 0.12,
		"special_action": {
			"every": 3, "kind": "potion", "damage_type": "magic", "can_crit": false,
		},
	},
}

const BASIC_ATTACK: Dictionary = {"kind": "attack", "damage_type": "physical", "can_crit": true}


static func has_definition(number: int) -> bool:
	return ENCOUNTERS.has(number)


static func get_definition(number: int) -> Dictionary:
	# A safe fallback also keeps test runs resilient to unknown chapter ids.
	return ENCOUNTERS.get(number, {})


static func get_action(number: int, enemy_action_number: int) -> Dictionary:
	var definition: Dictionary = get_definition(number)
	var special: Dictionary = definition.get("special_action", {})
	var interval: int = int(special.get("every", 0))
	if interval > 0 and enemy_action_number > 0 and enemy_action_number % interval == 0:
		return special
	return BASIC_ATTACK