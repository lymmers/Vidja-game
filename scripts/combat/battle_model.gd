extends RefCounted
class_name BattleModel
## Deterministic combat simulation: no animations, wall-clock time, or UI nodes.
## Player-side actors lead by default. Initiative modifiers can reverse that.

const UnitScript = preload("res://scripts/combat/battle_unit.gd")
const SkillScript = preload("res://scripts/skills/skill_catalog.gd")
const DamageScript = preload("res://scripts/combat/damage_pipeline.gd")
const EncounterScript = preload("res://scripts/combat/encounter_catalog.gd")
const EffectStateScript = preload("res://scripts/combat/combat_effect_state.gd")
const SchedulerScript = preload("res://scripts/combat/turn_scheduler.gd")
const ValidatorScript = preload("res://scripts/combat/data_validator.gd")

const HERO_HP: int = 110
const HERO_ATTACK_MIN: int = 12
const HERO_ATTACK_MAX: int = 19
const HERO_ARMOR: int = 2
const HERO_CRIT_CHANCE: float = 0.17
const CRITICAL_MULTIPLIER: float = 1.5
const MAX_CHAIN_EVENTS: int = 32

var hero: BattleUnit
var enemy: BattleUnit
var turn_index: int = 0
var enemy_turns: int = 0
var encounter: int = 1
var is_finished: bool = false
var winner: String = ""
var rng: RandomNumberGenerator # Compatibility alias: this is the COMBAT RNG only.
var draft_rng: RandomNumberGenerator
var cosmetic_rng: RandomNumberGenerator
var owned_skills: Array[String] = []
var effect_state: CombatEffectState
var scheduler: TurnScheduler
# IDs are durable game identifiers, never Godot get_instance_id() values.
var combatants: Dictionary = {} # id -> {unit, side, order, initiative}
var extra_effects: Dictionary = {} # actor id -> effect definitions
var initiative_modifiers: Array[Dictionary] = []
var actions_taken: Dictionary = {} # actor ID -> number of actions this encounter

func _init(seed_value: int = -1) -> void:
	rng = RandomNumberGenerator.new()
	draft_rng = RandomNumberGenerator.new()
	cosmetic_rng = RandomNumberGenerator.new()
	if seed_value < 0:
		rng.randomize()
		draft_rng.randomize()
		cosmetic_rng.randomize()
	else:
		# Separate streams: drafting/particles cannot consume a combat roll.
		rng.seed = seed_value
		draft_rng.seed = seed_value ^ 0x45A13F29
		cosmetic_rng.seed = seed_value ^ 0x5CC29AF1
	reset()

func reset() -> void:
	owned_skills.clear()
	extra_effects.clear()
	initiative_modifiers.clear()
	effect_state = EffectStateScript.new()
	scheduler = SchedulerScript.new()
	combatants.clear()
	hero = UnitScript.new("THE WAYFARER", HERO_HP, HERO_ATTACK_MIN, HERO_ATTACK_MAX, HERO_ARMOR, HERO_CRIT_CHANCE)
	_register("hero", "player", hero)
	start_encounter(1)

func _register(actor_id: String, side: String, unit: BattleUnit, initiative: int = 0) -> bool:
	if actor_id.is_empty() or combatants.has(actor_id) or (side != "player" and side != "enemy"):
		return false
	combatants[actor_id] = {
		"id": actor_id, "side": side, "unit": unit,
		"initiative": initiative, "order": combatants.size(),
	}
	return true

func _rebuild_schedule() -> void:
	var roster: Array[Dictionary] = []
	for actor in combatants.values():
		roster.append({"id": actor["id"], "side": actor["side"],
			"order": actor["order"], "initiative": actor["initiative"]})
	scheduler.configure(roster, initiative_modifiers)

func add_party_member(actor_id: String, unit: BattleUnit, initiative: int = 0) -> bool:
	# Register companions/pets before the opening action for a stable queue.
	if turn_index > 0 or not _register(actor_id, "player", unit, initiative):
		return false
	_rebuild_schedule()
	return true

func add_enemy(actor_id: String, unit: BattleUnit, initiative: int = 0) -> bool:
	if turn_index > 0 or not _register(actor_id, "enemy", unit, initiative):
		return false
	_rebuild_schedule()
	return true

func set_initiative_modifiers(modifiers: Array[Dictionary]) -> bool:
	# Changes made during an encounter take effect at its next opening, not mid-round.
	initiative_modifiers = modifiers.duplicate(true)
	if turn_index == 0:
		_rebuild_schedule()
	return true

func queue_extra_action(actor_id: String) -> bool:
	if not combatants.has(actor_id):
		return false
	scheduler.add_bonus_action(actor_id)
	return true

func skip_next_actions(actor_id: String, count: int = 1) -> bool:
	if not combatants.has(actor_id):
		return false
	scheduler.skip_actions(actor_id, count)
	return true

func start_encounter(number: int) -> void:
	var info: Dictionary = EncounterScript.get_definition(number)
	if info.is_empty():
		push_error("Unknown encounter ID: %d (not falling back to another enemy)" % number)
		is_finished = true
		return
	var errors: Array[String] = ValidatorScript.validate_encounter(info)
	if not errors.is_empty():
		push_error("Invalid encounter %d: %s" % [number, ", ".join(errors)])
		is_finished = true
		return
	encounter = number
	# Retain party HP and pet registrations; replace enemies for the next stage.
	for actor_id in combatants.keys():
		if combatants[actor_id]["side"] == "enemy":
			combatants.erase(actor_id)
			extra_effects.erase(actor_id)
	enemy = UnitScript.new(str(info["name"]), int(info["hp"]), int(info["attack_min"]),
		int(info["attack_max"]), int(info["armor"]), float(info["crit_chance"]))
	_register("enemy", "enemy", enemy)
	turn_index = 0
	enemy_turns = 0
	actions_taken.clear()
	effect_state.start_encounter()
	is_finished = false
	winner = ""
	_rebuild_schedule()

func has_skill(id: String) -> bool:
	return owned_skills.has(id)

func select_skill(id: String) -> bool:
	if not SkillScript.DEFINITIONS.has(id) or has_skill(id):
		return false
	var errors: Array[String] = ValidatorScript.validate_skill(SkillScript.details(id))
	if not errors.is_empty():
		push_error("Invalid skill %s: %s" % [id, ", ".join(errors)])
		return false
	owned_skills.append(id)
	return true

func grant_effects(actor_id: String, definitions: Array[Dictionary]) -> bool:
	# Used by equipment, status effects, pets and other external systems.
	if not combatants.has(actor_id):
		return false
	var combined: Array[Dictionary] = []
	combined.append_array(extra_effects.get(actor_id, []))
	for effect in definitions:
		var instance: Dictionary = effect.duplicate(true)
		if str(instance.get("id", "")).is_empty():
			return false
		combined.append(instance)
	extra_effects[actor_id] = combined
	return true

func _effects_for(actor_id: String, trigger: String) -> Array[Dictionary]:
	var effects: Array[Dictionary] = []
	if actor_id == "hero":
		for skill_id in owned_skills:
			effects.append_array(SkillScript.effects_for(skill_id, trigger))
	for effect in extra_effects.get(actor_id, []):
		if str(effect.get("trigger", "")) == trigger:
			effects.append(effect.duplicate(true))
	return effects

func begin_action() -> void:
	effect_state.begin_action()

func _actor_id_for(unit: BattleUnit) -> String:
	for actor_id in combatants.keys():
		if combatants[actor_id]["unit"] == unit:
			return str(actor_id)
	return "external"

func _defensive_modifiers(target: BattleUnit, damage_type: String, extra_defenses: Array[Dictionary]) -> Array[Dictionary]:
	var modifiers: Array[Dictionary] = []
	if damage_type == "physical" and target.armor > 0:
		modifiers.append({"name": "Armor", "operation": "subtract", "value": target.armor})
	# Multiple defensive effects are applied in their explicit definition order.
	modifiers.append_array(_effects_for(_actor_id_for(target), "before_damage"))
	var resistance: float = target.resistance_for(damage_type)
	if resistance > 0.0:
		modifiers.append({"name": "%s Resistance (%d%%)" % [damage_type.capitalize(), roundi(resistance * 100)],
			"operation": "multiply", "value": 1.0 - resistance})
	modifiers.append_array(extra_defenses)
	return modifiers

func resolve_hit(target: BattleUnit, attack_power: int, damage_type: String,
	bonus_modifiers: Array[Dictionary] = [], extra_defenses: Array[Dictionary] = [],
	extra_reactions: Array[Dictionary] = []) -> Dictionary:
	var target_id: String = _actor_id_for(target)
	var reactions: Array[Dictionary] = _effects_for(target_id, "lethal")
	reactions.append_array(_effects_for(target_id, "always"))
	reactions.append_array(extra_reactions)
	var hit: Dictionary = DamageScript.resolve(target, attack_power, damage_type, bonus_modifiers,
		_defensive_modifiers(target, damage_type, extra_defenses),
		effect_state.available_reactions(target_id, reactions))
	effect_state.record_triggers(target_id, hit["triggered_effects"])
	return hit

func _make_event(kind: String, actor_id: String, target_id: String, critical: bool, hit: Dictionary) -> Dictionary:
	var event: Dictionary = hit.duplicate(true)
	event["kind"] = kind
	event["actor_id"] = actor_id
	event["target_id"] = target_id
	event["attacker"] = "hero" if combatants[actor_id]["side"] == "player" else "enemy"
	event["actor_name"] = combatants[actor_id]["unit"].title
	event["target_name"] = combatants[target_id]["unit"].title
	event["critical"] = critical
	return event

func _process_trigger(trigger: String, actor_id: String, target_id: String,
	attack_roll: int, source: Dictionary, events: Array[Dictionary]) -> void:
	# Bounded chain: extra hits can trigger healing/kill effects, not infinite casts.
	if events.size() >= MAX_CHAIN_EVENTS:
		return
	for effect in _effects_for(actor_id, trigger):
		if events.size() >= MAX_CHAIN_EVENTS:
			break
		if float(effect.get("chance", 1.0)) < 1.0 and rng.randf() >= float(effect.get("chance", 1.0)):
			continue
		match str(effect.get("operation", "")):
			"bonus_hit":
				if not combatants[target_id]["unit"].is_alive():
					continue
				var empowered: int = maxi(1, roundi(float(attack_roll) * float(effect.get("power_multiplier", 1.0))))
				var modifiers: Array[Dictionary] = [{"name": str(effect.get("name", "Bonus Hit")),
					"operation": "add", "value": empowered - attack_roll}]
				var hit: Dictionary = resolve_hit(combatants[target_id]["unit"], attack_roll,
					str(effect["damage_type"]), modifiers)
				var event: Dictionary = _make_event(str(effect.get("kind", "attack")), actor_id, target_id, false, hit)
				events.append(event)
				_process_trigger("after_damage", actor_id, target_id, attack_roll, event, events)
				if not combatants[target_id]["unit"].is_alive():
					_process_trigger("on_kill", actor_id, target_id, attack_roll, event, events)
			"heal":
				var current: BattleUnit = combatants[actor_id]["unit"]
				var amount: int = roundi(float(source.get("damage", 0)) * float(effect.get("ratio", 0.0)))
				current.hp = mini(current.max_hp, current.hp + maxi(0, amount))
			"extra_action":
				queue_extra_action(actor_id)
			_:
				# Invalid operations are rejected at selection/registration; never reinterpret them.
				push_error("Unsupported %s effect operation: %s" % [trigger, str(effect.get("operation", ""))])

func _alive_ids() -> Array[String]:
	var output: Array[String] = []
	for actor_id in combatants.keys():
		if combatants[actor_id]["unit"].is_alive():
			output.append(str(actor_id))
	return output

func _side_alive(side: String) -> bool:
	for actor in combatants.values():
		if actor["side"] == side and actor["unit"].is_alive():
			return true
	return false

func _first_opponent(actor_id: String) -> String:
	var side: String = str(combatants[actor_id]["side"])
	for candidate in combatants.keys():
		if combatants[candidate]["side"] != side and combatants[candidate]["unit"].is_alive():
			return str(candidate)
	return ""

func take_next_turn() -> Dictionary:
	if is_finished:
		return {}
	if not _side_alive("player") or not _side_alive("enemy"):
		is_finished = true
		winner = "hero" if _side_alive("player") else "enemy"
		return {}
	var actor_id: String = scheduler.next_actor(_alive_ids())
	# Everybody may be stunned in a round; try the next round once.
	if actor_id.is_empty():
		actor_id = scheduler.next_actor(_alive_ids())
		if actor_id.is_empty():
			return {}
	var target_id: String = _first_opponent(actor_id)
	if target_id.is_empty():
		return {}
	begin_action()
	var attacker: BattleUnit = combatants[actor_id]["unit"]
	var target: BattleUnit = combatants[target_id]["unit"]
	var actor_side: String = str(combatants[actor_id]["side"])
	var count: int = int(actions_taken.get(actor_id, 0)) + 1
	actions_taken[actor_id] = count
	if actor_side == "enemy":
		enemy_turns += 1
	var action: Dictionary = EncounterScript.BASIC_ATTACK
	if actor_side == "enemy":
		action = EncounterScript.get_action(encounter, count)
	var attack_roll: int = rng.randi_range(attacker.min_attack, attacker.max_attack)
	var critical: bool = bool(action.get("can_crit", true)) and rng.randf() < attacker.crit_chance
	var attack_power: int = roundi(float(attack_roll) * CRITICAL_MULTIPLIER) if critical else attack_roll
	var bonuses: Array[Dictionary] = []
	if critical:
		bonuses.append({"name": "Critical", "operation": "add", "value": attack_power - attack_roll})
	var hit: Dictionary = resolve_hit(target, attack_roll, str(action["damage_type"]), bonuses)
	var event: Dictionary = _make_event(str(action["kind"]), actor_id, target_id, critical, hit)
	var events: Array[Dictionary] = [event]
	_process_trigger("after_damage", actor_id, target_id, attack_roll, event, events)
	if target.is_alive():
		_process_trigger("after_attack", actor_id, target_id, attack_roll, event, events)
	if not target.is_alive():
		_process_trigger("on_kill", actor_id, target_id, attack_roll, event, events)
	turn_index += 1
	if not _side_alive("player") or not _side_alive("enemy"):
		is_finished = true
		winner = "hero" if _side_alive("player") else "enemy"
	return {"number": turn_index, "actor_id": actor_id,
		"attacker": "hero" if actor_side == "player" else "enemy",
		"attacker_name": attacker.title, "events": events,
		"target_hp": target.hp, "finished": is_finished, "winner": winner}