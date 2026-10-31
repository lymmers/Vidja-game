extends Node2D

var hero: Node2D
var enemy: Node2D
var speed := 1.0
var auto_battle := false
var next_turn := 0.8
var hero_turn := true
var status: Label

func _ready() -> void:
	hero = preload("res://characters/hero/hero.tscn").instantiate()
	enemy = preload("res://characters/skeleton/skeleton.tscn").instantiate()
	add_child(hero)
	add_child(enemy)
	hero.position = Vector2(355, 440)
	enemy.position = Vector2(645, 440)
	hero.scale = Vector2(1.15, 1.15)
	enemy.scale = Vector2(1.15, 1.15)
	enemy.set_facing(-1)
	hero.impact.connect(func(): enemy.play_action(&"hit"))
	enemy.impact.connect(func(): hero.play_action(&"hit"))
	var ui := CanvasLayer.new()
	add_child(ui)
	var title := Label.new()
	title.text = "TINY LEGENDS  /  CHARACTER MOTION LAB"
	title.position = Vector2(32, 24)
	title.add_theme_color_override("font_color", Color("273846"))
	title.add_theme_font_size_override("font_size", 26)
	ui.add_child(title)
	status = Label.new()
	status.text = "Idle • independent limb movement • replaceable equipment"
	status.position = Vector2(32, 65)
	status.add_theme_color_override("font_color", Color("526574"))
	ui.add_child(status)
	var row := HBoxContainer.new()
	row.position = Vector2(32, 490)
	ui.add_child(row)
	button(row, "Idle", func(): auto_battle = false; hero.play_action(&"idle"); enemy.play_action(&"idle"))
	button(row, "Hero attack", func(): auto_battle = false; hero.play_action(&"attack"))
	button(row, "Skeleton attack", func(): auto_battle = false; enemy.play_action(&"attack"))
	button(row, "Both take hit", func(): auto_battle = false; hero.play_action(&"hit"); enemy.play_action(&"hit"))
	button(row, "Auto fight", func(): auto_battle = not auto_battle; next_turn = 0.1)
	var row2 := HBoxContainer.new()
	row2.position = Vector2(32, 550)
	ui.add_child(row2)
	var armor := CheckButton.new()
	armor.text = "Alternate armour"
	armor.add_theme_color_override("font_color", Color("273846"))
	armor.toggled.connect(func(on): hero.set_armor_visible(on); enemy.set_armor_visible(on))
	row2.add_child(armor)
	button(row2, "0.5×", func(): set_speed(0.5))
	button(row2, "1×", func(): set_speed(1.0))
	button(row2, "1.5×", func(): set_speed(1.5))

func button(parent: Node, caption: String, callback: Callable) -> void:
	var b := Button.new()
	b.text = caption
	b.custom_minimum_size = Vector2(130, 42)
	b.pressed.connect(callback)
	parent.add_child(b)

func set_speed(value: float) -> void:
	speed = value
	hero.animation_player.speed_scale = value
	enemy.animation_player.speed_scale = value

func _process(delta: float) -> void:
	if auto_battle:
		next_turn -= delta * speed
		if next_turn <= 0:
			var actor = hero if hero_turn else enemy
			actor.play_action(&"attack")
			hero_turn = not hero_turn
			next_turn = 1.35

func _draw() -> void:
	draw_rect(Rect2(0, 440, 1000, 210), Color("d9d0bd"))
	draw_line(Vector2(0, 440), Vector2(1000, 440), Color("b9ad96"), 2)
	for x in [355, 645]:
		draw_set_transform(Vector2(x, 439), 0, Vector2(1, 0.16))
		draw_circle(Vector2.ZERO, 65, Color("b7ad9d"))
	draw_set_transform(Vector2.ZERO)
