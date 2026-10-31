extends RefCounted
class_name BattleModel
## Owns logical turns, RNG, skill state and encounter state. Not visual time.
## DamagePipeline resolves hits; catalogs describe skills and enemy attacks.

const UnitScript = preload("res://scripts/combat/battle_unit.gd")
const SkillScript = preload("res://scripts/skills/skill_catalog.gd")
const DamageScript = preload("res://scripts/combat/damage_pipeline.gd")
const EncounterScript = preload("res://scripts/combat/encounter_catalog.gd")
const EffectStateScript = preload("res://scripts/combat/combat_effect_state.gd")

const HERO_HP: int = 110
const HERO_ATTACK_MIN: int = 12
const HERO_ATTACK_MAX: int = 19
const HERO_ARMOR: int = 2
const HERO_CRIT_CHANCE: float = 0.17
const CRITICAL_MULTIPLIER: float = 1.5

var hero: BattleUnit
var enemy: BattleUnit
var turn_index: int = 0
var enemy_turns: int = 0
var encounter: int = 1
var is_finished: bool = false
var winner: String = ""
var rng: RandomNumberGenerator
var owned_skills: Array[String] = []
var effect_state: CombatEffectState


func _init(seed_value: int = -1) -> void:
	rng = RandomNumberGenerator.new()
	if seed_value < 0:
		rng.randomize()
	else:
		rng.seed = seed_value
	reset()


func reset() -> void:
	owned_skills.clear()
	effect_state = EffectStateScript.new()
	hero = UnitScript.new("THE WAYFARER", HERO_HP, HERO_ATTACK_MIN, HERO_ATTACK_MAX, HERO_ARMOR, HERO_CRIT_CHANCE)
	start_encounter(1)


func start_encounter(number: int) -> void:
	encounter = number
	var info: Dictionary = EncounterScript.get_definition(number)
	enemy = UnitScript.new(
		str(info["name"]), int(info["hp"]), int(info["attack_min"]),
		int(info["attack_max"]), int(info["armor"]), float(info["crit_chance"])
	)
	turn_index = 0
	enemy_turns = 0
	effect_state.start_encounter()
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
	effect_state.begin_action()


func _defensive_modifiers(target: BattleUnit, damage_type: String, extra_defenses: Array[Dictionary]) -> Array[Dictionary]:
	var modifiers: Array[Dictionary] = []
	# Additive armor is currently a physical-only stat. Future damage types
	# can use the same generic resistance mechanism below.
	if damage_type == "physical" and target.armor > 0:
		modifiers.append({"name": "Armor", "operation": "subtract", "value": target.armor})

	if target == hero:
		for skill_id in owned_skills:
			var effect: Dictionary = SkillScript.details(skill_id).get("on_defend", {})
			if not effect.is_empty():
				modifiers.append(effect)

	var resistance: float = target.resistance_for(damage_type)
	if resistance > 0.0:
		modifiers.append({
			"name": "%s Resistance (%d%%)" % [damage_type.capitalize(), roundi(resistance * 100.0)],
			"operation": "multiply", "value": 1.0 - resistance,
		})
	modifiers.append_array(extra_defenses)
	return modifiers


func _reactive_effects_for(target: BattleUnit, extra_reactions: Array[Dictionary]) -> Array[Dictionary]:
	var definitions: Array[Dictionary] = []
	if target == hero:
		for skill_id in owned_skills:
			var reaction: Dictionary = SkillScript.details(skill_id).get("on_damage", {})
			if reaction.is_empty():
				continue
			# An effect's ID identifies its usage counter; names are only for UI.
			var instance: Dictionary = reaction.duplicate(true)
			instance["id"] = skill_id
			definitions.append(instance)
	definitions.append_array(extra_reactions)
	return effect_state.available_reactions(str(target.get_instance_id()), definitions)


func resolve_hit(
	target: BattleUnit,
	attack_power: int,
	damage_type: String,
	bonus_modifiers: Array[Dictionary] = [],
	extra_defenses: Array[Dictionary] = [],
	extra_reactions: Array[Dictionary] = []
) -> Dictionary:
	var target_key: String = str(target.get_instance_id())
	var hit: Dictionary = DamageScript.resolve(
		target, attack_power, damage_type, bonus_modifiers,
		_defensive_modifiers(target, damage_type, extra_defenses),
		_reactive_effects_for(target, extra_reactions)
	)
	effect_state.record_triggers(target_key, hit["triggered_effects"])
	return hit


func _make_event(kind: String, actor: String, critical: bool, hit: Dictionary) -> Dictionary:
	# Avoid duplicated event fields for basic, potion and extra skill attacks.
	var event: Dictionary = hit.duplicate(true)
	event["kind"] = kind
	event["attacker"] = actor
	event["critical"] = critical
	return event


func _append_attack_skills(events: Array[Dictionary], attack_roll: int) -> void:
	if not enemy.is_alive():
		return
	for skill_id in owned_skills:
		var ability: Dictionary = SkillScript.details(skill_id).get("on_attack", {})
		if ability.is_empty() or rng.randf() >= float(ability.get("chance", 0.0)):
			continue
		var empowered: int = maxi(1, roundi(float(attack_roll) * float(ability.get("power_multiplier", 1.0))))
		var bonus: Array[Dictionary] = [{
			"name": str(ability.get("modifier_name", "Ability")),
			"operation": "add", "value": empowered - attack_roll,
		}]
		var hit: Dictionary = resolve_hit(enemy, attack_roll, str(ability["damage_type"]), bonus)
		events.append(_make_event(str(ability["kind"]), "hero", false, hit))
		if not enemy.is_alive():
			break


func take_next_turn() -> Dictionary:
	if is_finished:
		return {}
	begin_action()
	var hero_attacking: bool = turn_index % 2 == 0
	var attacker: BattleUnit = hero if hero_attacking else enemy
	var target: BattleUnit = enemy if hero_attacking else hero
	var attack_roll: int = rng.randi_range(attacker.min_attack, attacker.max_attack)
	var actor: String = "hero" if hero_attacking else "enemy"
	var action: Dictionary = EncounterScript.BASIC_ATTACK
	if not hero_attacking:
		enemy_turns += 1
		action = EncounterScript.get_action(encounter, enemy_turns)
	var kind: String = str(action["kind"])
	var damage_type: String = str(action["damage_type"])
	var critical: bool = bool(action.get("can_crit", true)) and rng.randf() < attacker.crit_chance
	var attack_power: int = roundi(float(attack_roll) * CRITICAL_MULTIPLIER) if critical else attack_roll
	var bonuses: Array[Dictionary] = []
	if critical:
		bonuses.append({"name": "Critical", "operation": "add", "value": attack_power - attack_roll})
	var hit: Dictionary = resolve_hit(target, attack_roll, damage_type, bonuses)
	var events: Array[Dictionary] = [_make_event(kind, actor, critical, hit)]

	if hero_attacking:
		_append_attack_skills(events, attack_roll)

	turn_index += 1
	if not target.is_alive():
		is_finished = true
		winner = actor
	return {
		"number": turn_index, "attacker": actor, "attacker_name": attacker.title,
		"events": events, "target_hp": target.hp,
		"finished": is_finished, "winner": winner,
	}