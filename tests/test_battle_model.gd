extends SceneTree

const Model = preload("res://scripts/combat/battle_model.gd")
const Unit = preload("res://scripts/combat/battle_unit.gd")


func _initialize() -> void:
	_test_turn_order()
	_test_seed()
	_test_damage_and_end()
	print("PASS: combat model")
	quit(0)


func _test_turn_order() -> void:
	var battle = Model.new(8)
	assert(battle.take_next_turn()["attacker"] == "hero")
	assert(battle.take_next_turn()["attacker"] == "enemy")
	assert(battle.take_next_turn()["attacker"] == "hero")


func _test_seed() -> void:
	var first = Model.new(44)
	var second = Model.new(44)
	for index in range(4):
		assert(first.take_next_turn() == second.take_next_turn())


func _test_damage_and_end() -> void:
	var unit = Unit.new("TEST", 10, 1, 1, 0, 0)
	unit.take_damage(-5)
	assert(unit.hp == 10)
	unit.take_damage(99)
	assert(unit.hp == 0)
	var battle = Model.new(12)
	battle.enemy.hp = 1
	var outcome = battle.take_next_turn()
	assert(outcome["finished"])
	assert(outcome["winner"] == "hero")
	assert(battle.take_next_turn().is_empty())
	battle.reset()
	assert(not battle.is_finished)
