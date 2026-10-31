extends RefCounted
class_name BattleUnit
## Individual combatant's stats and HP; independent of visuals.

var title: String
var max_hp: int
var hp: int
var min_attack: int
var max_attack: int
var armor: int
var crit_chance: float


func _init(
	unit_title: String,
	unit_hp: int,
	attack_min: int,
	attack_max: int,
	unit_armor: int,
	unit_crit_chance: float
) -> void:
	title = unit_title
	max_hp = maxi(1, unit_hp)
	hp = max_hp
	min_attack = maxi(1, attack_min)
	max_attack = maxi(min_attack, attack_max)
	armor = maxi(0, unit_armor)
	crit_chance = clampf(unit_crit_chance, 0.0, 1.0)


func take_damage(amount: int) -> void:
	hp = maxi(0, hp - maxi(0, amount))


func is_alive() -> bool:
	return hp > 0
