extends SceneTree
## Regression coverage: logs must describe the actual applied damage, not guesses.
const BattleScript = preload("res://scripts/combat/battle_model.gd")
const LogScript = preload("res://scripts/combat/combat_log_formatter.gd")
var failures: int = 0

func _initialize() -> void:
	_test_iron_skin_breakdown()
	_test_magic_resistance_breakdown()
	_test_critical_breakdown()
	_test_fireball_breakdown()
	_test_final_stand_breakdown()
	_test_immunity_breakdown()
	if failures == 0:
		print("PASS: transparent damage breakdowns")
	quit(1 if failures else 0)

func _check(ok: bool, explanation: String) -> void:
	if not ok:
		push_error("FAIL: " + explanation)
		failures += 1

func _sum(event: Dictionary) -> int:
	var total: int = int(event["base_damage"])
	for modifier in event["modifiers"]:
		total += int(modifier["amount"])
	return total

func _test_iron_skin_breakdown() -> void:
	var battle = BattleScript.new(41)
	battle.select_skill("iron_skin")
	var hit: Dictionary = battle.resolve_hit(battle.hero, 20, "physical")
	_check(hit["damage"] == 14 and _sum(hit) == 14, "iron skin is 20 - 2 armor - 4 skin = 14")
	var event: Dictionary = hit.duplicate(true)
	event["kind"] = "attack"
	event["attacker"] = "enemy"
	var message: String = LogScript.format_event(event, "MOSS GOBLIN")
	_check(message.contains("Moss Goblin hit you for 14 Physical damage"), "physical hit names attacker and damage")
	_check(message.contains("20 base") and message.contains("-2 Armor") and message.contains("-4 Iron Skin (20%)"), "physical mitigation is itemized")

func _test_magic_resistance_breakdown() -> void:
	var battle = BattleScript.new(42)
	battle.select_skill("iron_skin")
	battle.hero.magic_resistance = 0.25
	var hit: Dictionary = battle.resolve_hit(battle.hero, 20, "magic")
	_check(hit["damage"] == 15 and _sum(hit) == 15, "magic resistance reduces 20 to 15, Iron Skin does not apply")
	var event: Dictionary = hit.duplicate(true)
	event["kind"] = "potion"
	event["attacker"] = "enemy"
	var message: String = LogScript.format_event(event, "BONE ALCHEMIST")
	_check(message.contains("Bone Alchemist hit you with Fire Potion for 15 Magic damage"), "potion is identified")
	_check(message.contains("-5 Magic Resistance (25%)") and not message.contains("Iron Skin"), "only applicable resistance appears")

func _test_critical_breakdown() -> void:
	var battle = BattleScript.new(43)
	battle.hero.min_attack = 16
	battle.hero.max_attack = 16
	battle.hero.crit_chance = 1.0
	var event: Dictionary = battle.take_next_turn()["events"][0]
	_check(event["damage"] == 22 and _sum(event) == 22, "critical adds 8 to 16, then enemy's 2 armor")
	var message: String = LogScript.format_event(event, "MOSS GOBLIN")
	_check(message.contains("You hit Moss Goblin for 22 Physical damage"), "critical log identifies target")
	_check(message.contains("16 base") and message.contains("+8 Critical") and message.contains("-2 Armor"), "critical is itemized")

func _test_fireball_breakdown() -> void:
	var battle = BattleScript.new(17)
	battle.select_skill("fireball")
	var fireball: Dictionary = {}
	for n in range(50):
		battle.enemy.hp = battle.enemy.max_hp
		battle.is_finished = false
		battle.turn_index = 0
		for event in battle.take_next_turn()["events"]:
			if event["kind"] == "fireball":
				fireball = event
				break
		if not fireball.is_empty():
			break
	_check(not fireball.is_empty(), "a fireball should proc in fifty forced hero attacks")
	if fireball.is_empty():
		return
	_check(_sum(fireball) == int(fireball["damage"]), "fireball ledger matches applied damage")
	var message: String = LogScript.format_event(fireball, "MOSS GOBLIN")
	_check(message.contains("Fireball") and message.contains("Magic damage") and message.contains("Fireball (150%)"), "fireball multiplier appears")

func _test_final_stand_breakdown() -> void:
	var battle = BattleScript.new(44)
	battle.select_skill("final_stand")
	battle.hero.hp = 5
	var hit: Dictionary = battle.resolve_hit(battle.hero, 20, "physical")
	_check(hit["damage"] == 4 and _sum(hit) == 4 and hit["triggered_effects"].size() == 1, "lethal hit is capped at 4 and ledger reconciles")
	var event: Dictionary = hit.duplicate(true)
	event["kind"] = "attack"
	event["attacker"] = "enemy"
	var message: String = LogScript.format_event(event, "MOSS GOBLIN")
	_check(message.contains("Final Stand") and message.contains("1 HP"), "Final Stand clearly explains survival")

func _test_immunity_breakdown() -> void:
	var battle = BattleScript.new(45)
	battle.select_skill("final_stand")
	battle.hero.hp = 1
	battle.resolve_hit(battle.hero, 20, "magic")
	var hit: Dictionary = battle.resolve_hit(battle.hero, 13, "magic")
	_check(hit["damage"] == 0 and _sum(hit) == 0 and hit["immune"], "extra hit is blocked and fully accounted for")