extends SceneTree
## Critical compatibility and extensibility tests; no graphics or timers required.

const Battle = preload("res://scripts/combat/battle_model.gd")
const Clock = preload("res://scripts/battle/presentation_clock.gd")
const Encounters = preload("res://scripts/combat/encounter_catalog.gd")
var failures: int = 0


func _initialize() -> void:
	_test_modifier_extension()
	_test_damage_type_extension()
	_test_overkill()
	_test_catalog()
	_test_seed_and_speed()
	print("PASS: foundations" if failures == 0 else "FAIL: %d foundation checks" % failures)
	quit(1 if failures > 0 else 0)


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error("FAIL: " + message)
		failures += 1


func _test_modifier_extension() -> void:
	var battle = Battle.new(7)
	var custom_effects: Array[Dictionary] = [
		{"name": "Arcane Ward (25%)", "operation": "multiply", "value": 0.75, "damage_type": "magic"},
	]
	var result: Dictionary = battle.resolve_hit(battle.hero, 20, "magic", [], custom_effects)
	_check(result["damage"] == 15, "new defense rule applies without changing battle loop")
	_check(result["modifiers"].any(func(e): return e["name"] == "Arcane Ward (25%)" and e["amount"] == -5), "new defense named in combat ledger")
	_check(battle.hero.hp == 95, "actual HP changed by 15")


func _test_damage_type_extension() -> void:
	var battle = Battle.new(8)
	battle.hero.resistances["arcane"] = 0.25
	var effect: Dictionary = battle.resolve_hit(battle.hero, 20, "arcane")
	_check(effect["damage"] == 15, "new damage type resistance works without a new damage branch")
	_check(effect["modifiers"].size() == 1, "new resistance explains itself")


func _test_overkill() -> void:
	var battle = Battle.new(9)
	battle.enemy.hp = 7
	var hit: Dictionary = battle.resolve_hit(battle.enemy, 20, "magic")
	_check(hit["damage"] == 7, "reported damage is actual 7 HP removed")
	_check(battle.enemy.hp == 0, "overkill reaches zero")
	var total: int = int(hit["base_damage"])
	for item in hit["modifiers"]:
		total += int(item["amount"])
	_check(total == 7, "ledger reconciles after overkill cap")


func _test_catalog() -> void:
	var definition: Dictionary = Encounters.get_definition(2)
	_check(definition.get("name") == "BONE ALCHEMIST", "enemy stats are defined outside battle loop")
	var action: Dictionary = Encounters.get_action(2, 3)
	_check(action.get("kind") == "potion" and action.get("damage_type") == "magic", "third action is potion in enemy data")
	_check(Encounters.get_action(2, 4).get("kind") == "attack", "fourth action returns to basic attack")


func _test_seed_and_speed() -> void:
	var clock = Clock.new()
	_check(is_equal_approx(clock.wait_seconds(0.8), 0.8), "1x wait is unchanged")
	clock.set_speed(2.0)
	_check(is_equal_approx(clock.wait_seconds(0.8), 0.4), "2x wait is half as long")
	var a = Battle.new(177)
	var b = Battle.new(177)
	a.select_skill("fireball")
	b.select_skill("fireball")
	for turn in range(8):
		var first: Dictionary = a.take_next_turn()
		var second: Dictionary = b.take_next_turn()
		_check(first == second, "seeded battle action %d is independent of speed" % turn)
		if a.is_finished:
			break