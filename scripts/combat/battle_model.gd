extends RefCounted
class_name BattleModel
## Pure combat rules, independent of animation, UI, and frame rate.

const UnitScript = preload("res://scripts/combat/battle_unit.gd")

var hero: BattleUnit
var enemy: BattleUnit
var turn_index: int = 0
var is_finished: bool = false
var winner: String = ""
var rng: RandomNumberGenerator


func _init(seed_value: int = -1) -> void:
	rng = RandomNumberGenerator.new()
	if seed_value < 0:
		rng.randomize()
	else:
		rng.seed = seed_value
	reset()


func reset() -> void:
	hero = UnitScript.new("THE WAYFARER", 100, 12, 19, 2, 0.17)
	enemy = UnitScript.new("MOSS GOBLIN", 98, 13, 20, 2, 0.14)
	turn_index = 0
	is_finished = false
	winner = ""


func take_next_turn() -> Dictionary:
	if is_finished:
		return {}

	var hero_attacking: bool = turn_index % 2 == 0
	var attacker: BattleUnit = hero if hero_attacking else enemy
	var target: BattleUnit = enemy if hero_attacking else hero
	var attack_roll: int = rng.randi_range(attacker.min_attack, attacker.max_attack)
	var critical: bool = rng.randf() < attacker.crit_chance
	var modified_attack: int = roundi(float(attack_roll) * 1.5) if critical else attack_roll
	var damage: int = maxi(1, modified_attack - target.armor)
	target.take_damage(damage)
	turn_index += 1

	if not target.is_alive():
		is_finished = true
		winner = "hero" if hero_attacking else "enemy"

	return {
		"number": turn_index,
		"attacker": "hero" if hero_attacking else "enemy",
		"attacker_name": attacker.title,
		"target": "enemy" if hero_attacking else "hero",
		"damage": damage,
		"critical": critical,
		"target_hp": target.hp,
		"finished": is_finished,
		"winner": winner
	}
