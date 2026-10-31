extends Node2D
class_name BattleStage
## Temporary procedural art. Combat calculation stays in battle_model.gd.

var hero_attack_offset: float = 0.0
var enemy_attack_offset: float = 0.0
var hero_flash: float = 0.0
var enemy_flash: float = 0.0


func _process(_delta: float) -> void:
	queue_redraw()


func reset_pose() -> void:
	hero_attack_offset = 0.0
	enemy_attack_offset = 0.0
	hero_flash = 0.0
	enemy_flash = 0.0
	queue_redraw()


func animate_attack(side: String) -> void:
	var move_property: String = "hero_attack_offset" if side == "hero" else "enemy_attack_offset"
	var flash_property: String = "enemy_flash" if side == "hero" else "hero_flash"
	var offset: float = 65.0 if side == "hero" else -65.0
	var tween: Tween = create_tween()
	tween.tween_property(self, move_property, offset, 0.16)
	tween.tween_callback(func(): set(flash_property, 1.0))
	tween.tween_property(self, move_property, 0.0, 0.28)
	tween.tween_callback(func(): set(flash_property, 0.0))
	await tween.finished


func _draw() -> void:
	draw_rect(Rect2(0, 0, 720, 1280), Color("172236"))
	draw_rect(Rect2(0, 280, 720, 480), Color("35475c"))
	draw_circle(Vector2(570, 386), 76, Color("edcba0"))
	_polygon([Vector2(0, 655), Vector2(150, 485), Vector2(330, 655)], Color("2a3c4d"))
	_polygon([Vector2(240, 670), Vector2(490, 445), Vector2(720, 680)], Color("30445a"))
	draw_rect(Rect2(0, 690, 720, 140), Color("59655e"))
	draw_rect(Rect2(0, 750, 720, 80), Color("747165"))
	draw_rect(Rect2(0, 830, 720, 450), Color("171b2e"))
	_draw_fighter(Vector2(205 + hero_attack_offset, 750), false, hero_flash)
	_draw_fighter(Vector2(520 + enemy_attack_offset, 750), true, enemy_flash)


func _draw_fighter(feet: Vector2, is_goblin: bool, flash: float) -> void:
	var x: float = feet.x
	var y: float = feet.y
	var skin: Color = Color("85b18e") if is_goblin else Color("edc9a3")
	var body: Color = Color("6b5366") if is_goblin else Color("536f92")
	draw_circle(Vector2(x, y + 2), 47, Color(0.08, 0.10, 0.13, 0.6))
	if flash > 0:
		draw_circle(Vector2(x, y - 107), 90, Color(1.0, 0.48, 0.26, flash * 0.4))
	draw_rect(Rect2(x - 25, y - 37, 19, 37), Color("343b44"))
	draw_rect(Rect2(x + 7, y - 37, 19, 37), Color("343b44"))
	_polygon([Vector2(x - 35, y - 95), Vector2(x + 36, y - 95), Vector2(x + 40, y - 35), Vector2(x - 40, y - 35)], body)
	draw_rect(Rect2(x - 34, y - 54, 68, 12), Color("b99a75"))
	if is_goblin:
		_polygon([Vector2(x - 35, y - 133), Vector2(x - 84, y - 148), Vector2(x - 42, y - 105)], skin)
		_polygon([Vector2(x + 35, y - 133), Vector2(x + 84, y - 148), Vector2(x + 42, y - 105)], skin)
		draw_line(Vector2(x - 30, y - 62), Vector2(x - 78, y - 153), Color("8c674a"), 17)
	else:
		draw_line(Vector2(x + 36, y - 66), Vector2(x + 75, y - 152), Color("d7e6ed"), 10)
		draw_line(Vector2(x + 22, y - 80), Vector2(x + 57, y - 65), Color("dfc18b"), 8)
		_polygon([Vector2(x - 48, y - 82), Vector2(x - 16, y - 80), Vector2(x - 19, y - 37), Vector2(x - 37, y - 23), Vector2(x - 53, y - 42)], Color("72999c"))
	draw_circle(Vector2(x, y - 125), 51, skin)
	draw_circle(Vector2(x - 17, y - 127), 5, Color("2c3441"))
	draw_circle(Vector2(x + 17, y - 127), 5, Color("2c3441"))
	draw_line(Vector2(x - 8, y - 105), Vector2(x + 8, y - 105), Color("6d4e55"), 3)
	if is_goblin:
		_polygon([Vector2(x - 42, y - 150), Vector2(x - 20, y - 185), Vector2(x - 5, y - 161), Vector2(x + 8, y - 184), Vector2(x + 32, y - 148)], Color("3a6353"))
	else:
		_polygon([Vector2(x - 47, y - 146), Vector2(x - 38, y - 174), Vector2(x, y - 187), Vector2(x + 37, y - 161), Vector2(x + 43, y - 141), Vector2(x + 10, y - 156)], Color("4f5060"))
		draw_rect(Rect2(x - 49, y - 146, 98, 10), Color("c9d4df"))


func _polygon(points: Array, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array(points), color)
