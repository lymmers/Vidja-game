extends SceneTree
## Headless smoke test: the main scene and draft UI must actually run.

var failures: int = 0

func _check(ok: bool, message: String) -> void:
	if not ok:
		push_error("FAIL: " + message)
		failures += 1

func _initialize() -> void:
	call_deferred("_test_screen")


func _test_screen() -> void:
	var scene: PackedScene = load("res://scenes/battle_screen.tscn")
	var screen = scene.instantiate()
	root.add_child(screen)
	await process_frame
	_check(screen.draft_overlay.visible, "Initial skill draft should pause play")
	_check(screen.combat_log_entries.size() == 1, "Log starts with encounter heading")
	_check(screen.draft_holder.get_child_count() == 3, "First draft offers 3 skills")

	screen._choose_skill("fireball")
	await process_frame
	_check(not screen.draft_overlay.visible, "Choosing closes the draft")
	_check(screen.battle.has_skill("fireball"), "Selected skill is active")
	_check(screen.skill_slots[0].text.contains("FIREBALL"), "Skill bar shows chosen skill")
	_check(screen.log_text.get_parsed_text().contains("Fireball"), "Equipped skill appears in log")
	screen._open_log()
	_check(screen.log_overlay.visible, "Combat log overlay opens")
	screen._close_log()
	_check(not screen.log_overlay.visible, "Combat log overlay closes")
	var hit: Dictionary = screen.battle.take_next_turn()["events"][0]
	screen._record_hit(hit)
	_check(screen.log_text.get_parsed_text().contains("Physical damage"), "Combat log records real damage")
	_check(screen.combat_log_entries.size() >= 3, "Combat history accumulates")

	# Jump to the between-fights selection without relying on random combat.
	screen.run_id += 1
	screen.pending_encounter = 2
	screen._show_draft()
	await process_frame
	_check(screen.draft_overlay.visible, "Between-fights draft opens")
	_check(screen.draft_holder.get_child_count() == 2, "Two unowned skills remain")

	screen._choose_skill("iron_skin")
	await process_frame
	_check(screen.battle.encounter == 2, "Second encounter starts after selecting")
	_check(screen.stage.enemy_kind == "skeleton", "Skeleton art is selected")
	_check(screen.skill_slots[1].text.contains("IRON SKIN"), "Second skill is shown")
	if failures == 0:
		print("PASS: battle screen startup, both skill drafts and skill bar, combat log")
	quit(1 if failures else 0)