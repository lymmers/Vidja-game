extends Control
## Interface and presentation only. BattleModel owns combat decisions.

const ModelScript = preload("res://scripts/combat/battle_model.gd")
const StageScript = preload("res://scripts/visuals/battle_stage.gd")

var battle: BattleModel
var stage: BattleStage
var hero_bar: ProgressBar
var enemy_bar: ProgressBar
var hero_label: Label
var enemy_label: Label
var message_label: Label
var turn_label: Label
var status_label: Label
var replay_button: Button
var run_id: int = 0


func _ready() -> void:
	stage = StageScript.new()
	add_child(stage)
	_make_ui()
	_start_battle()


func _make_ui() -> void:
	_panel(Rect2(0, 0, 720, 280), Color("181e31"))
	_label("TINY LEGENDS", Vector2(30, 32), Vector2(660, 64), 46, Color("f9eacb"), HORIZONTAL_ALIGNMENT_CENTER)
	_label("BATTLE LAB / PROTOTYPE 01", Vector2(30, 108), Vector2(660, 40), 20, Color("e7ba84"), HORIZONTAL_ALIGNMENT_CENTER)
	hero_label = _label("WAYFARER", Vector2(45, 166), Vector2(300, 34), 21, Color.WHITE)
	enemy_label = _label("MOSS GOBLIN", Vector2(375, 166), Vector2(300, 34), 21, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT)
	hero_bar = _progress(Vector2(45, 211), Color("86cda9"))
	enemy_bar = _progress(Vector2(378, 211), Color("e69088"))
	_panel(Rect2(36, 854, 648, 205), Color("253047"))
	_label("ENCOUNTER 01 / ASHEN PASS", Vector2(58, 870), Vector2(470, 42), 19, Color("edc58c"))
	turn_label = _label("TURN 01", Vector2(532, 870), Vector2(130, 42), 17, Color("bec7d6"), HORIZONTAL_ALIGNMENT_RIGHT)
	message_label = _label("A moss goblin blocks your path...", Vector2(60, 926), Vector2(600, 110), 28, Color.WHITE)
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label = _label("AUTO BATTLE", Vector2(48, 1060), Vector2(624, 45), 21, Color("b0bac9"), HORIZONTAL_ALIGNMENT_CENTER)
	replay_button = Button.new()
	replay_button.text = "FIGHT AGAIN"
	replay_button.position = Vector2(130, 1132)
	replay_button.size = Vector2(460, 84)
	replay_button.add_theme_font_size_override("font_size", 29)
	replay_button.pressed.connect(_start_battle)
	replay_button.visible = false
	add_child(replay_button)
	_label("Our first playable encounter", Vector2(40, 1238), Vector2(640, 29), 17, Color("8390a7"), HORIZONTAL_ALIGNMENT_CENTER)


func _panel(area: Rect2, color: Color) -> void:
	var panel := Panel.new()
	panel.position = area.position
	panel.size = area.size
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(20)
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)


func _progress(at: Vector2, tint: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.position = at
	bar.size = Vector2(298, 31)
	bar.show_percentage = false
	bar.max_value = 100
	bar.value = 100
	var background := StyleBoxFlat.new()
	background.bg_color = Color("3e4558")
	background.set_corner_radius_all(8)
	var fill := StyleBoxFlat.new()
	fill.bg_color = tint
	fill.set_corner_radius_all(8)
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", fill)
	add_child(bar)
	return bar


func _label(content: String, at: Vector2, dimensions: Vector2, font_size: int, color: Color, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = content
	label.position = at
	label.size = dimensions
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", font_size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label


func _start_battle() -> void:
	run_id += 1
	var current_run := run_id
	stage.reset_pose()
	battle = ModelScript.new()
	_update_health()
	message_label.text = "A moss goblin blocks your path!"
	turn_label.text = "TURN 01"
	status_label.text = "AUTO BATTLE - WATCH THE FIGHT"
	replay_button.visible = false
	_run_battle(current_run)


func _run_battle(current_run: int) -> void:
	await get_tree().create_timer(0.9).timeout
	while run_id == current_run and not battle.is_finished:
		var outcome: Dictionary = battle.take_next_turn()
		if outcome.is_empty():
			break
		turn_label.text = "TURN %02d" % int(outcome["number"])
		var who: String = "You" if outcome["attacker"] == "hero" else "The goblin"
		message_label.text = "%s %s for %d damage" % [who, "CRIT!" if outcome["critical"] else "hit", int(outcome["damage"])]
		await stage.animate_attack(str(outcome["attacker"]))
		if run_id != current_run:
			return
		_update_health()
		await get_tree().create_timer(0.5).timeout
	if run_id == current_run and battle.is_finished:
		message_label.text = "VICTORY! The path is clear." if battle.winner == "hero" else "DEFEAT! Try again."
		status_label.text = "ENCOUNTER COMPLETE - PLAY AGAIN"
		replay_button.visible = true


func _update_health() -> void:
	hero_bar.max_value = battle.hero.max_hp
	hero_bar.value = battle.hero.hp
	enemy_bar.max_value = battle.enemy.max_hp
	enemy_bar.value = battle.enemy.hp
	hero_label.text = "WAYFARER  %d/%d" % [battle.hero.hp, battle.hero.max_hp]
	enemy_label.text = "MOSS GOBLIN  %d/%d" % [battle.enemy.hp, battle.enemy.max_hp]
