extends SceneTree

const BattleScript = preload("res://scripts/combat/battle_model.gd")
const SkillScript = preload("res://scripts/skills/skill_catalog.gd")

var failures: int = 0

func _initialize() -> void:
	_test_draft_pool()
	_test_damage_types()
	_test_final_stand()
	_test_fireball()
	_test_alchemist_cycle()
	_test_two_encounters()
	if failures == 0:
		print("PASS: six combat/skill tests")
	quit(1 if failures else 0)

func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error("FAIL: " + message)
		failures += 1

func _test_draft_pool() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var choices: Array[String] = SkillScript.get_choices([], 3, rng)
	_check(choices.size() == 3, "first draft gives three choices")
	_check(choices.has("fireball") and choices.has("iron_skin") and choices.has("final_stand"), "all skills can appear")
	choices = SkillScript.get_choices(["fireball"], 3, rng)
	_check(choices.size() == 2 and not choices.has("fireball"), "later draft shows two without duplicate")
	choices = SkillScript.get_choices(["fireball", "iron_skin", "final_stand"], 3, rng)
	_check(choices.is_empty(), "empty pool offers zero choices")
	choices = SkillScript.get_choices(["fireball", "iron_skin"], 3, rng)
	_check(choices.size() == 1 and choices[0] == "final_stand", "single remaining skill displays")

func _test_damage_types() -> void:
	var battle = BattleScript.new(40)
	battle.select_skill("iron_skin")
	var hp_before: int = battle.hero.hp
	var physical: Dictionary = battle.resolve_hit(battle.hero, 20, "physical")
	_check(int(physical["damage"]) == 14, "20 physical - 2 armor => 18, then 20% reduced => 14")
	battle.hero.hp = hp_before
	var magical: Dictionary = battle.resolve_hit(battle.hero, 20, "magic")
	_check(int(magical["damage"]) == 20, "magic bypasses iron skin and armor")

func _test_final_stand() -> void:
	var battle = BattleScript.new(21)
	battle.select_skill("final_stand")
	battle.hero.hp = 5
	var lethal: Dictionary = battle.resolve_hit(battle.hero, 100, "magic")
	_check(int(lethal["damage"]) == 4 and bool(lethal["final_stand"]), "final stand leaves 1 hp")
	_check(battle.hero.hp == 1, "final stand hp exactly 1")
	var followup: Dictionary = battle.resolve_hit(battle.hero, 50, "physical")
	_check(int(followup["damage"]) == 0 and battle.hero.hp == 1, "immune to follow-up in same action")
	battle.begin_action()
	var second: Dictionary = battle.resolve_hit(battle.hero, 100, "magic")
	_check(battle.hero.hp == 0 and not bool(second["final_stand"]), "final stand once per encounter")

func _test_fireball() -> void:
	var battle = BattleScript.new(17)
	battle.select_skill("fireball")
	battle.rng.seed = 1
	# Forced high probability via rerolled seeds; at least one proc across 30 attacks.
	var proc_seen := false
	for index in range(30):
		battle.enemy.hp = battle.enemy.max_hp
		battle.is_finished = false
		battle.turn_index = 0
		var result: Dictionary = battle.take_next_turn()
		for event in result["events"]:
			if event["kind"] == "fireball":
				proc_seen = true
				_check(event["damage_type"] == "magic", "fireball uses magic damage")
				_check(int(event["damage"]) > 0, "fireball damages enemy")
	_check(proc_seen, "50% fireball can trigger")

func _test_alchemist_cycle() -> void:
	var battle = BattleScript.new(8)
	battle.start_encounter(2)
	battle.hero.max_hp = 1000
	battle.hero.hp = 1000
	battle.hero.min_attack = 1
	battle.hero.max_attack = 1
	var kinds: Array[String] = []
	for index in range(6):
		battle.take_next_turn() # hero
		var enemy_action: Dictionary = battle.take_next_turn()
		kinds.append(str(enemy_action["events"][0]["kind"]))
	_check(kinds == ["attack", "attack", "potion", "attack", "attack", "potion"], "potion every third skeleton action")
	var third_turn = BattleScript.new(9)
	third_turn.start_encounter(2)
	third_turn.hero.max_hp = 1000
	third_turn.hero.hp = 1000
	third_turn.hero.min_attack = 1
	third_turn.hero.max_attack = 1
	for index in range(5):
		third_turn.take_next_turn()
	var event: Dictionary = third_turn.take_next_turn()["events"][0]
	_check(event["kind"] == "potion" and event["damage_type"] == "magic", "potion is magic damage")

func _test_two_encounters() -> void:
	var battle = BattleScript.new(1)
	battle.select_skill("iron_skin")
	battle.hero.hp = 72
	battle.start_encounter(2)
	_check(battle.encounter == 2 and battle.enemy.title == "BONE ALCHEMIST", "new skeleton enemy")
	_check(battle.hero.hp == 72, "HP persists between encounters")
	_check(battle.has_skill("iron_skin"), "skills persist between encounters")
	battle.start_encounter(1)
	_check(battle.enemy.title == "MOSS GOBLIN", "goblin encounter")