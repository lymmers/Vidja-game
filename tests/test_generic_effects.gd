extends SceneTree
## A skill adds a reactive effect definition; no game core knows its skill ID.

const Battle = preload("res://scripts/combat/battle_model.gd")
const Damage = preload("res://scripts/combat/damage_pipeline.gd")
const Skills = preload("res://scripts/skills/skill_catalog.gd")
var failures: int = 0


func _initialize() -> void:
	_test_final_stand_uses_definition()
	_test_new_lethal_effect_without_pipeline_changes()
	_test_generic_immunity_and_encounter_reset()
	_test_nonlethal_hits_and_defenses()
	if failures == 0:
		print("PASS: generic reactive combat effects")
	quit(1 if failures > 0 else 0)


func _check(ok: bool, message: String) -> void:
	if not ok:
		push_error("FAIL: " + message)
		failures += 1


func _test_final_stand_uses_definition() -> void:
	var effect: Dictionary = Skills.details("final_stand").get("on_damage", {})
	_check(effect.get("operation") == "leave_hp", "Final Stand is defined as a reusable leave-hp operation")
	_check(effect.get("trigger") == "lethal", "Its trigger is data, not a hardcoded skill branch")
	var battle = Battle.new(20)
	battle.select_skill("final_stand")
	battle.hero.hp = 5
	var result: Dictionary = battle.resolve_hit(battle.hero, 50, "magic")
	_check(result["damage"] == 4 and battle.hero.hp == 1, "Final Stand preserves 1 HP")
	_check(result["triggered_effects"].size() == 1, "Hit exposes a generic triggered effect list")
	if result["triggered_effects"].size() > 0:
		_check(result["triggered_effects"][0]["name"] == "Final Stand", "Audit identifies effect by supplied name")
	battle.resolve_hit(battle.hero, 50, "magic")
	_check(battle.hero.hp == 1, "Immunity protects remainder of current logical action")
	battle.begin_action()
	battle.resolve_hit(battle.hero, 50, "magic")
	_check(battle.hero.hp == 0, "One-use effect stays spent in same encounter")


func _test_new_lethal_effect_without_pipeline_changes() -> void:
	var battle = Battle.new(5)
	battle.hero.hp = 8
	var other_skill_effect: Array[Dictionary] = [{
		"id": "second_chance", "name": "Second Chance",
		"trigger": "lethal", "operation": "leave_hp", "hp_floor": 3,
		"uses_per_encounter": 1,
	}]
	var result: Dictionary = battle.resolve_hit(battle.hero, 30, "magic", [], [], other_skill_effect)
	_check(result["damage"] == 5 and battle.hero.hp == 3, "Arbitrary new skill can leave 3 HP without new branches")
	_check(result["modifiers"].any(func(m): return m["name"] == "Second Chance" and m["amount"] == -25), "Generic skill is named in modifier ledger")
	battle.resolve_hit(battle.hero, 30, "magic", [], [], other_skill_effect)
	_check(battle.hero.hp == 0, "Usage limits apply equally to injected new skill")


func _test_generic_immunity_and_encounter_reset() -> void:
	var battle = Battle.new(7)
	var effect: Array[Dictionary] = [{
		"id": "guardian_oath", "name": "Guardian Oath",
		"trigger": "lethal", "operation": "leave_hp", "hp_floor": 2,
		"uses_per_encounter": 1, "grants_immunity": "action",
	}]
	battle.hero.hp = 5
	battle.resolve_hit(battle.hero, 30, "physical", [], [], effect)
	var prevented: Dictionary = battle.resolve_hit(battle.hero, 16, "magic")
	_check(battle.hero.hp == 2 and prevented["immune"], "Immunity works without looking up its skill again")
	_check(prevented["modifiers"].any(func(m): return m["name"].contains("Guardian Oath")), "Immunity ledger uses the originating skill's name")
	battle.begin_action()
	battle.start_encounter(2)
	battle.hero.hp = 5
	var refreshed: Dictionary = battle.resolve_hit(battle.hero, 30, "physical", [], [], effect)
	_check(battle.hero.hp == 2 and refreshed["triggered_effects"].size() == 1, "Usage limits reset for next encounter")


func _test_nonlethal_hits_and_defenses() -> void:
	var battle = Battle.new(99)
	battle.select_skill("iron_skin")
	battle.select_skill("final_stand")
	var nonlethal: Dictionary = battle.resolve_hit(battle.hero, 20, "physical")
	_check(nonlethal["damage"] == 14 and nonlethal["triggered_effects"].is_empty(), "Ordinary armor and Iron Skin still work; lethal effect does not trigger")
	battle.hero.hp = 4
	var lethal: Dictionary = battle.resolve_hit(battle.hero, 20, "physical")
	_check(lethal["damage"] == 3 and battle.hero.hp == 1, "Reactive skill activates after mitigation")
	var ledger: int = int(lethal["base_damage"])
	for modifier in lethal["modifiers"]:
		ledger += int(modifier["amount"])
	_check(ledger == 3, "Every modifier still reconciles exactly to actual HP removed")