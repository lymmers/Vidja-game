extends SceneTree
## Architecture contract: stable actors, initiative, isolated RNG, multi-effects.

const Battle = preload("res://scripts/combat/battle_model.gd")
const Unit = preload("res://scripts/combat/battle_unit.gd")
const Skills = preload("res://scripts/skills/skill_catalog.gd")
const Encounters = preload("res://scripts/combat/encounter_catalog.gd")
const Validator = preload("res://scripts/combat/data_validator.gd")

var failures: int = 0

func _initialize() -> void:
	_test_opening_side()
	_test_reversed_initiative()
	_test_party_members_and_extra_actions()
	_test_isolated_rng()
	_test_multiple_effects()
	_test_validation()
	print("PASS: initiative and system extension contracts" if failures == 0 else "FAIL: %d architecture checks" % failures)
	quit(1 if failures else 0)

func _check(ok: bool, reason: String) -> void:
	if not ok:
		push_error("FAIL: " + reason)
		failures += 1

func _test_opening_side() -> void:
	var battle = Battle.new(4)
	var first: Dictionary = battle.take_next_turn()
	_check(first.get("actor_id") == "hero", "hero acts first by default")
	_check(first.get("attacker") == "hero", "legacy hero actor label remains supported")

func _test_reversed_initiative() -> void:
	var battle = Battle.new(4)
	battle.set_initiative_modifiers([{"side": "enemy", "add": 200}])
	_check(battle.take_next_turn().get("actor_id") == "enemy", "enemy-first modifier changes opening turn")
	_check(battle.take_next_turn().get("actor_id") == "hero", "hero gets next turn")

func _test_party_members_and_extra_actions() -> void:
	var battle = Battle.new(4)
	var pet = Unit.new("EMBER FOX", 50, 1, 1, 0, 0)
	_check(battle.add_party_member("pet_ember", pet), "pet can join player team")
	battle.hero.min_attack = 1
	battle.hero.max_attack = 1
	battle.enemy.hp = 72
	_check(battle.take_next_turn().get("actor_id") == "hero", "hero starts party round")
	_check(battle.take_next_turn().get("actor_id") == "pet_ember", "pet acts before enemy")
	_check(battle.take_next_turn().get("actor_id") == "enemy", "enemy follows player-side actors")
	battle.queue_extra_action("pet_ember")
	_check(battle.take_next_turn().get("actor_id") == "pet_ember", "extra action can be inserted without changing turn arithmetic")

func _test_isolated_rng() -> void:
	var one = Battle.new(42)
	var two = Battle.new(42)
	for i in range(30):
		Skills.get_choices([], 3, one.draft_rng)
	_check(one.take_next_turn() == two.take_next_turn(), "draft RNG never changes combat results")

func _test_multiple_effects() -> void:
	var effects: Array[Dictionary] = [
		{"id": "mod_a", "trigger": "before_damage", "operation": "multiply", "value": 0.5, "damage_type": "physical", "name": "First Ward"},
		{"id": "mod_b", "trigger": "before_damage", "operation": "subtract", "value": 2, "damage_type": "physical", "name": "Second Ward"},
	]
	var battle = Battle.new(8)
	battle.grant_effects("hero", effects)
	var hit = battle.resolve_hit(battle.hero, 20, "physical")
	_check(hit.get("damage") == 7, "multiple effect definitions stack after 2 armor: (20-2)*0.5-2 = 7")
	_check(hit.get("modifiers", []).size() == 3, "combat ledger includes all three defenses")

func _test_validation() -> void:
	_check(Validator.validate_skill({"name":"BROKEN", "effects":[{"id":"x", "trigger":"lethal", "operation":"made_up"}]}).size() > 0, "invalid skill operation rejected")
	_check(Validator.validate_skill(Skills.details("final_stand")).is_empty(), "existing Final Stand definition valid")
	_check(not Validator.validate_effect({"id": "bad", "trigger": "lethal", "operation": "heal"}).is_empty(), "incompatible trigger/operation rejected")
	_check(Validator.validate_encounter(Encounters.get_definition(2)).is_empty(), "existing skeleton definition valid")
	_check(not Encounters.has_definition(999), "undefined encounter is not secretly a goblin")
	_check(Encounters.get_definition(999).is_empty(), "unknown encounter returns no definition")