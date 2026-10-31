extends Control
## UI and fight sequence only; game rules live in battle_model.gd.
## Character scenes and animation are owned by the presentation stage.

const ModelScript = preload("res://scripts/combat/battle_model.gd")
const StageScript = preload("res://scripts/visuals/battle_stage.gd")
const SkillScript = preload("res://scripts/skills/skill_catalog.gd")
const EncounterScript = preload("res://scripts/combat/encounter_catalog.gd")
const LogScript = preload("res://scripts/combat/combat_log_formatter.gd")
const ClockScript = preload("res://scripts/battle/presentation_clock.gd")
const MAX_LOG_ENTRIES: int = 250

const COLOR_BG = Color("161b2d")
const COLOR_CARD = Color("222a40")
const COLOR_MUTED = Color("9daac0")
const COLOR_LIGHT = Color("f9ebd4")
const COLOR_GOLD = Color("eec78e")
const COLOR_GREEN = Color("87cead")
const COLOR_RED = Color("e89d8d")

var battle: BattleModel
var stage: BattleStage
var presentation_clock: PresentationClock
var run_id: int = 0
var pending_encounter: int = 1
var choosing: bool = false
var hero_hp_bar: Panel
var enemy_hp_bar: Panel
var hero_hp_label: Label
var enemy_hp_label: Label
var enemy_name_label: Label
var encounter_label: Label
var turn_label: Label
var message_label: Label
var status_label: Label
var replay_button: Button
var skill_slots: Array[Label] = []
var skill_slot_holder: HBoxContainer
var draft_overlay: ColorRect
var draft_holder: Control
var draft_header: Label
var draft_hint: Label
var log_button: Button
var log_overlay: ColorRect
var log_text: RichTextLabel
var combat_log_entries: Array[String] = []


func _ready() -> void:
	presentation_clock = ClockScript.new()
	stage = StageScript.new()
	add_child(stage)
	_make_interface()
	_start_run()


func _make_interface() -> void:
	_panel(Rect2(0, 0, 720, 283), COLOR_BG, 0)
	_panel(Rect2(0, 0, 720, 9), COLOR_GOLD, 0)
	_label("TINY LEGENDS", Vector2(39, 30), Vector2(642, 50), 45, COLOR_LIGHT, HORIZONTAL_ALIGNMENT_CENTER)
	_label("B A T T L E   L A B   /   P R O T O T Y P E   0 3", Vector2(20, 93), Vector2(680, 30), 17, COLOR_GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	_panel(Rect2(48, 142, 624, 4), Color("465064"), 2)
	_label("THE WAYFARER", Vector2(45, 163), Vector2(296, 31), 20, COLOR_LIGHT)
	enemy_name_label = _label("", Vector2(380, 163), Vector2(294, 31), 20, COLOR_LIGHT, HORIZONTAL_ALIGNMENT_RIGHT)
	_panel(Rect2(47, 210, 297, 25), Color("3a4555"), 13)
	_panel(Rect2(376, 210, 297, 25), Color("3a4555"), 13)
	hero_hp_bar = _panel(Rect2(49, 212, 293, 21), COLOR_GREEN, 10)
	enemy_hp_bar = _panel(Rect2(378, 212, 293, 21), COLOR_RED, 10)
	hero_hp_label = _label("110 / 110", Vector2(49, 241), Vector2(293, 26), 18, COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	enemy_hp_label = _label("72 / 72", Vector2(377, 241), Vector2(293, 26), 18, COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	_panel(Rect2(38, 855, 644, 177), COLOR_CARD, 22)
	encounter_label = _label("ENCOUNTER 01     /     ASHEN PASS", Vector2(66, 870), Vector2(480, 33), 17, COLOR_GOLD)
	turn_label = _label("TURN 01", Vector2(518, 870), Vector2(136, 33), 17, COLOR_MUTED, HORIZONTAL_ALIGNMENT_RIGHT)
	message_label = _label("Choose your first skill...", Vector2(65, 911), Vector2(590, 113), 20, COLOR_LIGHT)
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label = _label("CHOOSE A SKILL", Vector2(48, 1042), Vector2(465, 44), 18, COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	log_button = Button.new()
	log_button.text = "COMBAT LOG"
	log_button.position = Vector2(526, 1042)
	log_button.size = Vector2(151, 46)
	log_button.add_theme_font_size_override("font_size", 16)
	_style_button(log_button, Color("39465d"), COLOR_LIGHT, COLOR_GOLD)
	log_button.pressed.connect(_open_log)
	add_child(log_button)
	replay_button = Button.new()
	replay_button.text = "RESTART ADVENTURE"
	replay_button.position = Vector2(143, 972)
	replay_button.size = Vector2(434, 64)
	replay_button.add_theme_font_size_override("font_size", 26)
	_style_button(replay_button, COLOR_GOLD, COLOR_BG)
	replay_button.pressed.connect(_start_run)
	replay_button.visible = false
	add_child(replay_button)

	_panel(Rect2(24, 1098, 672, 152), Color("20283b"), 18)
	_label("ACTIVE SKILLS", Vector2(47, 1105), Vector2(626, 34), 20, COLOR_GOLD)
	# Scrollable slots grow with the build, rather than a hard-coded slot count.
	var skill_scroll := ScrollContainer.new()
	skill_scroll.position = Vector2(42, 1145)
	skill_scroll.size = Vector2(637, 93)
	skill_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(skill_scroll)
	skill_slot_holder = HBoxContainer.new()
	skill_slot_holder.add_theme_constant_override("separation", 9)
	skill_scroll.add_child(skill_slot_holder)

	_make_draft()
	_make_log_ui()


func _make_draft() -> void:
	draft_overlay = ColorRect.new()
	draft_overlay.position = Vector2.ZERO
	draft_overlay.size = Vector2(720, 1280)
	draft_overlay.color = Color(0.06, 0.08, 0.14, 0.94)
	add_child(draft_overlay)
	draft_header = _label("CHOOSE YOUR SKILL", Vector2(46, 207), Vector2(628, 67), 39, COLOR_LIGHT, HORIZONTAL_ALIGNMENT_CENTER)
	draft_hint = _label("Pick one. The battle waits for you.", Vector2(45, 283), Vector2(630, 45), 20, COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	# Move draft labels under overlay: they must render above the backdrop.
	remove_child(draft_header)
	remove_child(draft_hint)
	draft_overlay.add_child(draft_header)
	draft_overlay.add_child(draft_hint)
	draft_holder = Control.new()
	draft_holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	draft_overlay.add_child(draft_holder)
	draft_overlay.visible = false


func _make_log_ui() -> void:
	# Full-screen history is kept separate from the short live preview.
	log_overlay = ColorRect.new()
	log_overlay.position = Vector2.ZERO
	log_overlay.size = Vector2(720, 1280)
	log_overlay.color = Color(0.05, 0.07, 0.12, 0.97)
	add_child(log_overlay)

	var heading := Label.new()
	heading.text = "COMBAT LOG"
	heading.position = Vector2(36, 70)
	heading.size = Vector2(490, 65)
	heading.add_theme_font_size_override("font_size", 39)
	heading.add_theme_color_override("font_color", COLOR_LIGHT)
	log_overlay.add_child(heading)

	var close := Button.new()
	close.text = "CLOSE"
	close.position = Vector2(528, 81)
	close.size = Vector2(151, 58)
	close.add_theme_font_size_override("font_size", 20)
	_style_button(close, Color("39465d"), COLOR_LIGHT, COLOR_GOLD)
	close.pressed.connect(_close_log)
	log_overlay.add_child(close)

	var panel := Panel.new()
	panel.position = Vector2(22, 167)
	panel.size = Vector2(676, 1015)
	var background := StyleBoxFlat.new()
	background.bg_color = COLOR_CARD
	background.set_corner_radius_all(17)
	panel.add_theme_stylebox_override("panel", background)
	log_overlay.add_child(panel)

	log_text = RichTextLabel.new()
	log_text.position = Vector2(43, 185)
	log_text.size = Vector2(635, 980)
	log_text.bbcode_enabled = false
	log_text.scroll_following = true
	log_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_text.add_theme_color_override("default_color", COLOR_LIGHT)
	log_text.add_theme_font_size_override("normal_font_size", 21)
	log_overlay.add_child(log_text)
	log_overlay.visible = false


func _open_log() -> void:
	log_overlay.visible = true


func _close_log() -> void:
	log_overlay.visible = false


func _append_combat_log(entry: String) -> void:
	combat_log_entries.append(entry)
	if combat_log_entries.size() > MAX_LOG_ENTRIES:
		# Bounded history avoids an ever-growing RichTextLabel during long farming.
		combat_log_entries.pop_front()
		log_text.clear()
		for saved_entry in combat_log_entries:
			log_text.append_text(saved_entry + "\n\n")
	else:
		log_text.append_text(entry + "\n\n")


func _record_hit(action: Dictionary) -> void:
	var formatted: String = LogScript.format_event(action, battle.enemy.title)
	message_label.text = formatted
	_append_combat_log("Turn %02d  /  %s" % [battle.turn_index, formatted])


func _set_game_speed(multiplier: float) -> void:
	# This touches playback only. The combat model remains entirely unmodified.
	presentation_clock.set_speed(multiplier)
	stage.animation_speed = presentation_clock.speed


func _start_run() -> void:
	run_id += 1
	battle = ModelScript.new()
	pending_encounter = 1
	var first: Dictionary = EncounterScript.get_definition(1)
	stage.enemy_kind = str(first["visual"])
	stage.reset_pose()
	log_overlay.visible = false
	combat_log_entries.clear()
	log_text.clear()
	_append_combat_log("ENCOUNTER 1 — %s" % first["name"])
	encounter_label.text = "ENCOUNTER 01     /     %s" % first["area"]
	enemy_name_label.text = str(first["name"])
	replay_button.visible = false
	turn_label.text = "TURN 01"
	message_label.text = "Choose your first skill..."
	_update_health()
	_update_skill_bar()
	_show_draft()


func _show_draft() -> void:
	choosing = true
	status_label.text = "BATTLE PAUSED - CHOOSE A SKILL"
	for child in draft_holder.get_children():
		child.queue_free()
	var offered: Array[String] = SkillScript.get_choices(battle.owned_skills, 3, battle.draft_rng)
	if offered.is_empty():
		choosing = false
		draft_overlay.visible = false
		_advance_after_draft()
		return
	draft_header.text = "CHOOSE YOUR SKILL"
	draft_hint.text = "Before fight 1" if pending_encounter == 1 else "Victory! Choose another skill."
	# Center one, two or three available cards dynamically.
	var gap: float = 24.0
	var height: float = 132.0
	var top: float = 385.0 + (3 - offered.size()) * (height + gap) / 2.0
	for index in range(offered.size()):
		var id: String = offered[index]
		var info: Dictionary = SkillScript.details(id)
		var button := Button.new()
		button.position = Vector2(48, top + index * (height + gap))
		button.size = Vector2(624, height)
		button.text = "%s  %s\n%s" % [str(info["symbol"]), str(info["name"]), str(info["description"])]
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.add_theme_font_size_override("font_size", 22)
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		_style_button(button, Color("364056"), Color.WHITE, info["color"])
		button.pressed.connect(_choose_skill.bind(id))
		draft_holder.add_child(button)
	draft_overlay.visible = true


func _choose_skill(id: String) -> void:
	if not choosing:
		return
	if not battle.select_skill(id):
		return
	choosing = false
	draft_overlay.visible = false
	_update_skill_bar()
	_append_combat_log("Skill equipped: %s" % str(SkillScript.details(id).get("name", id)))
	_advance_after_draft()


func _advance_after_draft() -> void:
	var this_run: int = run_id
	if pending_encounter != battle.encounter:
		battle.start_encounter(pending_encounter)
		stage.reset_pose()
		_append_combat_log("ENCOUNTER %d — %s" % [battle.encounter, battle.enemy.title])
	var info: Dictionary = EncounterScript.get_definition(battle.encounter)
	stage.enemy_kind = str(info.get("visual", ""))
	encounter_label.text = "ENCOUNTER %02d     /     %s" % [battle.encounter, str(info.get("area", "UNKNOWN"))]
	enemy_name_label.text = str(info.get("name", "UNKNOWN"))
	message_label.text = str(info.get("intro", "A new enemy blocks your path!"))
	turn_label.text = "TURN 01"
	status_label.text = "AUTO BATTLE   -   WATCH THE FIGHT"
	_update_health()
	_play_battle(this_run)


func _play_battle(this_run: int) -> void:
	await get_tree().create_timer(presentation_clock.wait_seconds(0.8)).timeout
	while this_run == run_id and not battle.is_finished:
		var outcome: Dictionary = battle.take_next_turn()
		if outcome.is_empty():
			break
		turn_label.text = "TURN %02d" % int(outcome["number"])
		for action in outcome["events"]:
			var kind: String = str(action["kind"])
			_record_hit(action)
			if kind == "fireball":
				await stage.animate_spell("fireball")
			elif kind == "potion":
				await stage.animate_spell("potion")
			else:
				await stage.animate_attack(str(action["attacker"]))
			if this_run != run_id:
				return
			if not action.get("triggered_effects", []).is_empty():
				await get_tree().create_timer(presentation_clock.wait_seconds(0.42)).timeout
		_update_health()
		await get_tree().create_timer(presentation_clock.wait_seconds(0.42)).timeout
	if this_run == run_id and battle.is_finished:
		_finish_battle()


func _finish_battle() -> void:
	if battle.winner == "hero" and EncounterScript.has_definition(battle.encounter + 1):
		message_label.text = "%s defeated! Prepare for the next encounter." % battle.enemy.title.capitalize()
		_append_combat_log("VICTORY — %s DEFEATED" % battle.enemy.title)
		pending_encounter = battle.encounter + 1
		_show_draft()
	elif battle.winner == "hero":
		message_label.text = "VICTORY! Both encounters cleared!"
		_append_combat_log("VICTORY — BOTH ENCOUNTERS CLEARED")
		status_label.text = "TWO ENCOUNTERS COMPLETE"
		replay_button.visible = true
	else:
		message_label.text = "DEFEAT... Your adventure ends here."
		_append_combat_log("DEFEAT — ADVENTURE ENDED")
		status_label.text = "TRY AGAIN WITH A NEW BUILD"
		replay_button.visible = true


func _update_health() -> void:
	hero_hp_label.text = "%d / %d HP" % [battle.hero.hp, battle.hero.max_hp]
	enemy_hp_label.text = "%d / %d HP" % [battle.enemy.hp, battle.enemy.max_hp]
	hero_hp_bar.size.x = 293.0 * float(battle.hero.hp) / float(battle.hero.max_hp)
	enemy_hp_bar.size.x = 293.0 * float(battle.enemy.hp) / float(battle.enemy.max_hp)


func _update_skill_bar() -> void:
	for child in skill_slot_holder.get_children():
		skill_slot_holder.remove_child(child)
		child.queue_free()
	skill_slots.clear()
	var shown: Array[String] = battle.owned_skills.duplicate()
	if shown.is_empty():
		shown.append("") # Display one placeholder, not a fixed number of slots.
	for skill_id in shown:
		var slot := Label.new()
		slot.custom_minimum_size = Vector2(205, 83)
		slot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		slot.add_theme_font_size_override("font_size", 18)
		var style := StyleBoxFlat.new()
		style.bg_color = Color("364056")
		style.set_corner_radius_all(13)
		slot.add_theme_stylebox_override("normal", style)
		if skill_id.is_empty():
			slot.text = "+  EMPTY"
			slot.add_theme_color_override("font_color", COLOR_MUTED)
		else:
			var info: Dictionary = SkillScript.details(skill_id)
			slot.text = "%s  %s" % [str(info["symbol"]), str(info["name"])]
			slot.add_theme_color_override("font_color", info["color"])
		skill_slot_holder.add_child(slot)
		skill_slots.append(slot)


func _style_button(button: Button, background_color: Color, text_color: Color, border_color: Color = Color.TRANSPARENT) -> void:
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color)
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = background_color
	normal_style.set_corner_radius_all(16)
	normal_style.set_border_width_all(2)
	normal_style.border_color = border_color
	button.add_theme_stylebox_override("normal", normal_style)
	var hover_style: StyleBoxFlat = normal_style.duplicate() as StyleBoxFlat
	hover_style.bg_color = background_color.lightened(0.15)
	button.add_theme_stylebox_override("hover", hover_style)
	var pressed_style: StyleBoxFlat = normal_style.duplicate() as StyleBoxFlat
	pressed_style.bg_color = background_color.darkened(0.10)
	button.add_theme_stylebox_override("pressed", pressed_style)


func _panel(rectangle: Rect2, color: Color, radius: int) -> Panel:
	var panel: Panel = Panel.new()
	panel.position = rectangle.position
	panel.size = rectangle.size
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	return panel


func _label(text_value: String, at: Vector2, dimensions: Vector2, font_size: int, text_color: Color, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label: Label = Label.new()
	label.text = text_value
	label.position = at
	label.size = dimensions
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", text_color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label