extends RefCounted
class_name BattleModel
## Turn-based rules live here, separate from animations and the skill UI.

const UnitScript = preload("res://scripts/combat/battle_unit.gd")
const SkillScript = preload("res://scripts/skills/skill_catalog.gd")

var hero: BattleUnit
var enemy: BattleUnit
var turn_index: int = 0
var enemy_turns: int = 0
var encounter: int = 1
var is_finished: bool = false
var winner: String = ""
var rng: RandomNumberGenerator
var owned_skills: Array[String] = []
var final_stand_used: bool = false
var immune_this_action: bool = false


func _init(seed_value: int = -1) -> void:
	rng = RandomNumberGenerator.new()
	if seed_value < 0:
		rng.randomize()
	else:
		rng.seed = seed_value
	reset()


func reset() -> void:
	owned_skills.clear()
	hero = UnitScript.new("THE WAYFARER", 110, 12, 19, 2, 0.17)
	start_encounter(1)


func start_encounter(number: int) -> void:
	encounter = number
	if encounter == 2:
		enemy = UnitScript.new("BONE ALCHEMIST", 75, 10, 14, 1, 0.12)
	else:
		enemy = UnitScript.new("MOSS GOBLIN", 72, 9, 13, 2, 0.14)
	turn_index = 0
	enemy_turns = 0
	final_stand_used = false
	immune_this_action = false
	is_finished = false
	winner = ""


func has_skill(id: String) -> bool:
	return owned_skills.has(id)


func select_skill(id: String) -> bool:
	if not SkillScript.DEFINITIONS.has(id) or has_skill(id):
		return false
	owned_skills.append(id)
	return true


func begin_action() -> void:
	# Invulnerability only protects against additional hits in the SAME action.
	immune_this_action = false


func resolve_hit(target: BattleUnit, attack_power: int, damage_type: String, bonus_modifiers: Array[Dictionary] = []) -> Dictionary:
	# The damage ledger travels with the hit. UI never tries to guess the arithmetic.
	var base_damage: int = maxi(1, attack_power)
	var damage: int = base_damage
	var modifiers: Array[Dictionary] = []
	for bonus in bonus_modifiers:
		var amount: int = int(bonus.get("amount", 0))
		damage += amount
		if amount != 0:
			modifiers.append({"name": str(bonus.get("name", "Bonus")), "amount": amount})

	if target == hero and immune_this_action:
		modifiers.append({"name": "Final Stand Immunity", "amount": -damage})
		return {
			"base_damage": base_damage, "modifiers": modifiers,
			"damage": 0, "damage_type": damage_type,
			"final_stand": false, "immune": true,
		}

	if damage_type == "physical":
		var after_armor: int = maxi(1, damage - target.armor)
		if after_armor != damage:
			modifiers.append({"name": "Armor", "amount": after_armor - damage})
		damage = after_armor
		if target == hero and has_skill("iron_skin"):
			var after_skin: int = maxi(1, roundi(float(damage) * 0.8))
			if after_skin != damage:
				modifiers.append({"name": "Iron Skin (20%)", "amount": after_skin - damage})
			damage = after_skin
	elif damage_type == "magic" and target.magic_resistance > 0.0:
		var resist: float = clampf(target.magic_resistance, 0.0, 1.0)
		var after_resist: int = maxi(1, roundi(float(damage) * (1.0 - resist)))
		if after_resist != damage:
			modifiers.append({"name": "Magic Resistance (%d%%)" % roundi(resist * 100.0), "amount": after_resist - damage})
		damage = after_resist

	var triggered: bool = false
	if target == hero and has_skill("final_stand") and not final_stand_used and damage >= hero.hp:
		final_stand_used = true
		immune_this_action = true
		triggered = true
		var saved_damage: int = maxi(0, hero.hp - 1)
		modifiers.append({"name": "Final Stand", "amount": saved_damage - damage})
		damage = saved_damage

	target.take_damage(damage)
	return {
		"base_damage": base_damage, "modifiers": modifiers,
		"damage": damage, "damage_type": damage_type,
		"final_stand": triggered, "immune": false,
	}


func take_next_turn() -> Dictionary:
	if is_finished:
		return {}
	begin_action()
	var hero_attacking: bool = turn_index % 2 == 0
	var attacker: BattleUnit = hero if hero_attacking else enemy
	var target: BattleUnit = enemy if hero_attacking else hero
	var attack_roll: int = rng.randi_range(attacker.min_attack, attacker.max_attack)
	var events: Array[Dictionary] = []
	var actor: String = "hero" if hero_attacking else "enemy"

	if not hero_attacking:
		enemy_turns += 1
	var potion: bool = not hero_attacking and encounter == 2 and enemy_turns % 3 == 0
	var critical: bool = not potion and rng.randf() < attacker.crit_chance
	var attack_power: int = roundi(float(attack_roll) * 1.5) if critical else attack_roll
	var damage_type: String = "magic" if potion else "physical"
	var crit_modifiers: Array[Dictionary] = []
	if critical:
		crit_modifiers.append({"name": "Critical", "amount": attack_power - attack_roll})
	var hit: Dictionary = resolve_hit(target, attack_roll, damage_type, crit_modifiers)
	events.append({
		"kind": "potion" if potion else "attack", "attacker": actor,
		"damage_type": damage_type, "damage": hit["damage"],
		"critical": critical, "final_stand": hit["final_stand"],
		"immune": hit["immune"], "base_damage": hit["base_damage"],
		"modifiers": hit["modifiers"],
	})

	# Fireball is a bonus attack after a successful basic strike, not a replacement.
	# It uses 150% of the rolled attack power, without critical multipliers.
	if hero_attacking and enemy.is_alive() and has_skill("fireball") and rng.randf() < 0.5:
		var spell_power: int = maxi(1, roundi(float(attack_roll) * 1.5))
		var spell_bonus: Array[Dictionary] = [{"name": "Fireball (150%)", "amount": spell_power - attack_roll}]
		var spell: Dictionary = resolve_hit(enemy, attack_roll, "magic", spell_bonus)
		events.append({
			"kind": "fireball", "attacker": "hero", "damage_type": "magic",
			"damage": spell["damage"], "critical": false, "final_stand": false,
			"immune": spell["immune"], "base_damage": spell["base_damage"],
			"modifiers": spell["modifiers"],
		})

	turn_index += 1
	if not target.is_alive():
		is_finished = true
		winner = actor
	return {
		"number": turn_index, "attacker": actor, "attacker_name": attacker.title,
		"events": events, "target_hp": target.hp,
		"finished": is_finished, "winner": winner,
	}