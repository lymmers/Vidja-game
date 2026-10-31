extends Node2D
class_name BattleStage
## Procedural placeholder art: everything drawn in Godot, no assets to install.
## Swap this node for animated sprites later; the BattleModel won't change.

var hero_attack_offset: float = 0.0
var enemy_attack_offset: float = 0.0
var hero_hit_flash: float = 0.0
var enemy_hit_flash: float = 0.0
var active_attack: Tween
var active_impact: Tween
var enemy_kind: String = "goblin"
var flying_spell: String = ""
var spell_progress: float = 0.0


func _process(_delta: float) -> void:
	queue_redraw()


func reset_pose() -> void:
	if active_attack and active_attack.is_running():
		active_attack.kill()
	if active_impact and active_impact.is_running():
		active_impact.kill()
	hero_attack_offset = 0.0
	enemy_attack_offset = 0.0
	hero_hit_flash = 0.0
	enemy_hit_flash = 0.0
	flying_spell = ""
	spell_progress = 0.0
	queue_redraw()


func animate_attack(attacker: String) -> void:
	var moving_property: String = "hero_attack_offset" if attacker == "hero" else "enemy_attack_offset"
	var distance: float = 62.0 if attacker == "hero" else -62.0
	active_attack = create_tween()
	active_attack.tween_property(self, moving_property, distance, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	active_attack.tween_callback(Callable(self, "_show_impact").bind(attacker))
	active_attack.tween_interval(0.08)
	active_attack.tween_property(self, moving_property, 0.0, 0.27).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await active_attack.finished


func _show_impact(attacker: String) -> void:
	var hit_property: String = "enemy_hit_flash" if attacker == "hero" else "hero_hit_flash"
	set(hit_property, 1.0)
	if active_impact and active_impact.is_running():
		active_impact.kill()
	active_impact = create_tween()
	active_impact.tween_property(self, hit_property, 0.0, 0.36)


func animate_spell(kind: String) -> void:
	flying_spell = kind
	spell_progress = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(self, "spell_progress", 1.0, 0.58).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_callback(Callable(self, "_show_impact").bind("enemy" if kind == "potion" else "hero"))
	await tween.finished
	flying_spell = ""


func _draw() -> void:
	_draw_landscape()
	_draw_hero(Vector2(210.0 + hero_attack_offset, 751.0))
	if enemy_kind == "skeleton":
		_draw_skeleton(Vector2(515.0 + enemy_attack_offset, 751.0))
	else:
		_draw_goblin(Vector2(515.0 + enemy_attack_offset, 751.0))
	if not flying_spell.is_empty():
		var from_point: Vector2 = Vector2(500, 595) if flying_spell == "potion" else Vector2(248, 601)
		var to_point: Vector2 = Vector2(225, 631) if flying_spell == "potion" else Vector2(491, 625)
		var pos: Vector2 = from_point.lerp(to_point, spell_progress)
		pos.y -= sin(spell_progress * PI) * 100.0
		draw_circle(pos, 24, Color("f9aa53", 0.35))
		draw_circle(pos, 15, Color("fc6c40"))
		draw_circle(pos + Vector2(-4, -3), 7, Color("fff2b2"))


func _draw_landscape() -> void:
	# Flat-shaded fantasy scenery, designed for a portrait phone viewport.
	draw_rect(Rect2(0, 0, 720, 1280), Color("111729"))
	draw_rect(Rect2(0, 275, 720, 498), Color("25344d"))
	draw_rect(Rect2(0, 395, 720, 375), Color("3c5267"))
	draw_circle(Vector2(553, 382), 93, Color("d8b88f"))
	draw_circle(Vector2(553, 382), 77, Color("f4d4a4"))
	# Far hills.
	_poly([Vector2(0, 635), Vector2(120, 491), Vector2(230, 635)], Color("34455a"))
	_poly([Vector2(160, 648), Vector2(390, 456), Vector2(622, 648)], Color("304156"))
	_poly([Vector2(455, 650), Vector2(635, 515), Vector2(720, 614), Vector2(720, 680)], Color("34465a"))
	# Old castle walls in silhouette.
	draw_rect(Rect2(56, 477, 70, 190), Color("293949"))
	draw_rect(Rect2(46, 463, 92, 23), Color("293949"))
	draw_rect(Rect2(73, 445, 26, 24), Color("293949"))
	draw_rect(Rect2(636, 512, 56, 155), Color("293949"))
	draw_rect(Rect2(624, 498, 79, 23), Color("293949"))
	# Front hillside and battle platform.
	_poly([Vector2(0, 673), Vector2(127, 646), Vector2(254, 685), Vector2(430, 628), Vector2(620, 677), Vector2(720, 650), Vector2(720, 809), Vector2(0, 809)], Color("42545a"))
	draw_rect(Rect2(0, 750, 720, 80), Color("6f7067"))
	draw_rect(Rect2(0, 783, 720, 49), Color("56575b"))
	for x in [8.0, 111.0, 236.0, 362.0, 479.0, 609.0]:
		draw_line(Vector2(x, 790), Vector2(x + 34, 828), Color("444954"), 3)
	for x in [54.0, 192.0, 341.0, 515.0, 656.0]:
		draw_line(Vector2(x, 759), Vector2(x + 63, 759), Color("8f8a7b"), 3)
	# Warm motes floating in the atmosphere.
	for p in [Vector2(84, 392), Vector2(173, 346), Vector2(280, 429), Vector2(465, 330), Vector2(639, 450), Vector2(339, 581)]:
		draw_circle(p, 3, Color("dbbf98", 0.65))
	# Vignette-like bands framing the arena.
	draw_rect(Rect2(0, 824, 720, 456), Color("161b2d"))


func _draw_hero(feet: Vector2) -> void:
	var x: float = feet.x
	var y: float = feet.y
	# Shadows and cyan hit flash.
	draw_circle(Vector2(x, y + 3), 44, Color(0.08, 0.09, 0.13, 0.55))
	if hero_hit_flash > 0.0:
		draw_circle(Vector2(x, y - 96), 79, Color(1.0, 0.45, 0.3, 0.35 * hero_hit_flash))
	# Hero's traveling cloak.
	_poly([Vector2(x - 32, y - 89), Vector2(x + 26, y - 91), Vector2(x + 43, y - 15), Vector2(x - 51, y - 15)], Color("2e516b"))
	_poly([Vector2(x - 47, y - 22), Vector2(x - 25, y - 76), Vector2(x - 20, y - 15)], Color("254357"))
	# Boots and body.
	draw_rect(Rect2(x - 27, y - 33, 23, 36), Color("343548"))
	draw_rect(Rect2(x + 6, y - 33, 23, 36), Color("343548"))
	draw_rect(Rect2(x - 31, y - 81, 64, 57), Color("6c7891"))
	draw_rect(Rect2(x - 31, y - 48, 64, 13), Color("a88b68"))
	draw_rect(Rect2(x - 4, y - 47, 13, 13), Color("f0c876"))
	# Shield left, sword right.
	_poly([Vector2(x - 46, y - 80), Vector2(x - 17, y - 77), Vector2(x - 18, y - 34), Vector2(x - 35, y - 19), Vector2(x - 51, y - 42)], Color("b4bcc6"))
	_poly([Vector2(x - 41, y - 74), Vector2(x - 24, y - 71), Vector2(x - 26, y - 38), Vector2(x - 36, y - 29), Vector2(x - 46, y - 43)], Color("467c86"))
	draw_line(Vector2(x + 44, y - 50), Vector2(x + 81, y - 143), Color("d9e7eb"), 10)
	draw_line(Vector2(x + 45, y - 54), Vector2(x + 80, y - 144), Color("a0c6da"), 4)
	draw_line(Vector2(x + 29, y - 70), Vector2(x + 61, y - 58), Color("dfc18b"), 8)
	draw_circle(Vector2(x + 39, y - 40), 10, Color("907052"))
	# Large chibi head, hair, and helmet trim.
	draw_circle(Vector2(x, y - 116), 49, Color("c5d0dc"))
	draw_circle(Vector2(x, y - 109), 42, Color("eec9a0"))
	_poly([Vector2(x - 45, y - 125), Vector2(x - 40, y - 158), Vector2(x - 9, y - 170), Vector2(x + 22, y - 161), Vector2(x + 43, y - 137), Vector2(x + 29, y - 133), Vector2(x + 14, y - 143), Vector2(x - 13, y - 133)], Color("5a5261"))
	draw_rect(Rect2(x - 48, y - 130, 96, 10), Color("dbe4e9"))
	draw_circle(Vector2(x - 17, y - 111), 5, Color("263346"))
	draw_circle(Vector2(x + 16, y - 111), 5, Color("263346"))
	draw_line(Vector2(x - 5, y - 92), Vector2(x + 5, y - 92), Color("945d58"), 3)


func _draw_goblin(feet: Vector2) -> void:
	var x: float = feet.x
	var y: float = feet.y
	draw_circle(Vector2(x, y + 3), 44, Color(0.08, 0.09, 0.13, 0.55))
	if enemy_hit_flash > 0.0:
		draw_circle(Vector2(x, y - 108), 84, Color(1.0, 0.58, 0.40, 0.43 * enemy_hit_flash))
	# A comically threatening, chibi moss goblin.
	draw_rect(Rect2(x - 25, y - 34, 23, 36), Color("4d5553"))
	draw_rect(Rect2(x + 6, y - 34, 23, 36), Color("4d5553"))
	_poly([Vector2(x - 32, y - 88), Vector2(x + 31, y - 88), Vector2(x + 39, y - 25), Vector2(x - 39, y - 25)], Color("67545f"))
	draw_rect(Rect2(x - 34, y - 56, 68, 12), Color("9b806b"))
	# Wooden club over left shoulder.
	draw_line(Vector2(x - 30, y - 53), Vector2(x - 75, y - 138), Color("765844"), 13)
	draw_line(Vector2(x - 75, y - 138), Vector2(x - 87, y - 167), Color("806148"), 29)
	draw_circle(Vector2(x - 33, y - 61), 13, Color("80937d"))
	# Ears behind the head.
	_poly([Vector2(x - 35, y - 128), Vector2(x - 82, y - 142), Vector2(x - 42, y - 102)], Color("78a58a"))
	_poly([Vector2(x + 35, y - 128), Vector2(x + 81, y - 141), Vector2(x + 43, y - 102)], Color("78a58a"))
	draw_circle(Vector2(x, y - 116), 49, Color("7fb194"))
	# Tuft of moss-like hair.
	_poly([Vector2(x - 39, y - 140), Vector2(x - 22, y - 174), Vector2(x - 7, y - 153), Vector2(x + 7, y - 180), Vector2(x + 24, y - 151), Vector2(x + 39, y - 140)], Color("3e635b"))
	draw_circle(Vector2(x - 15, y - 112), 7, Color("fff3cf"))
	draw_circle(Vector2(x + 18, y - 112), 7, Color("fff3cf"))
	draw_circle(Vector2(x - 17, y - 111), 3, Color("353744"))
	draw_circle(Vector2(x + 16, y - 111), 3, Color("353744"))
	draw_line(Vector2(x - 8, y - 91), Vector2(x + 7, y - 94), Color("3a6256"), 4)
	draw_circle(Vector2(x - 37, y - 113), 11, Color("719d83"))


func _draw_skeleton(feet: Vector2) -> void:
	var x: float = feet.x
	var y: float = feet.y
	# Bone alchemist: a small skull, oversized hood and a flask of fire.
	draw_circle(Vector2(x, y + 3), 44, Color(0.08, 0.09, 0.13, 0.55))
	if enemy_hit_flash > 0.0:
		draw_circle(Vector2(x, y - 110), 80, Color(1.0, 0.5, 0.3, 0.4 * enemy_hit_flash))
	draw_rect(Rect2(x - 24, y - 29, 21, 30), Color("c1bea8"))
	draw_rect(Rect2(x + 5, y - 29, 21, 30), Color("c1bea8"))
	_poly([Vector2(x - 43, y - 100), Vector2(x + 40, y - 100), Vector2(x + 48, y - 28), Vector2(x - 48, y - 28)], Color("4c405c"))
	draw_rect(Rect2(x - 25, y - 86, 50, 43), Color("756c8a"))
	draw_line(Vector2(x - 42, y - 80), Vector2(x - 63, y - 44), Color("d8d0bd"), 12)
	draw_line(Vector2(x + 39, y - 83), Vector2(x + 66, y - 125), Color("d8d0bd"), 12)
	# Hood, skull, crooked toothy grin.
	draw_circle(Vector2(x, y - 130), 62, Color("302e48"))
	draw_circle(Vector2(x, y - 122), 47, Color("e4dcc5"))
	draw_circle(Vector2(x - 18, y - 124), 10, Color("313143"))
	draw_circle(Vector2(x + 19, y - 124), 10, Color("313143"))
	_poly([Vector2(x - 4, y - 106), Vector2(x + 5, y - 106), Vector2(x, y - 116)], Color("69645b"))
	draw_line(Vector2(x - 22, y - 97), Vector2(x + 21, y - 97), Color("6b6263"), 3)
	for tooth_x in [-14.0, -5.0, 5.0, 14.0]:
		draw_line(Vector2(x + tooth_x, y - 98), Vector2(x + tooth_x, y - 89), Color("6b6263"), 2)
	# Glowing orange fire potion held aloft.
	draw_circle(Vector2(x + 70, y - 147), 21, Color("9d412c"))
	draw_circle(Vector2(x + 70, y - 151), 15, Color("f18439"))
	draw_rect(Rect2(x + 63, y - 173, 14, 9), Color("e2d4b4"))
	draw_circle(Vector2(x + 64, y - 155), 5, Color("ffe298"))


func _poly(points: Array, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array(points), color)