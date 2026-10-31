extends SceneTree
## Headless smoke test: the main scene and draft UI must actually run.

func _initialize() -> void:
	call_deferred("_test_screen")


func _test_screen() -> void:
	var scene: PackedScene = load("res://scenes/battle_screen.tscn")
	var screen = scene.instantiate()
	root.add_child(screen)
	await process_frame
	assert(screen.draft_overlay.visible, "Initial skill draft should pause play")
	assert(screen.draft_holder.get_child_count() == 3, "First draft offers 3 skills")

	screen._choose_skill("fireball")
	await process_frame
	assert(not screen.draft_overlay.visible, "Choosing closes the draft")
	assert(screen.battle.has_skill("fireball"), "Selected skill is active")
	assert(screen.skill_slots[0].text.contains("FIREBALL"), "Skill bar shows chosen skill")

	# Jump to the between-fights selection without relying on random combat.
	screen.run_id += 1
	screen.pending_encounter = 2
	screen._show_draft()
	await process_frame
	assert(screen.draft_overlay.visible, "Between-fights draft opens")
	assert(screen.draft_holder.get_child_count() == 2, "Two unowned skills remain")

	screen._choose_skill("iron_skin")
	await process_frame
	assert(screen.battle.encounter == 2, "Second encounter starts after selecting")
	assert(screen.stage.enemy_kind == "skeleton", "Skeleton art is selected")
	assert(screen.skill_slots[1].text.contains("IRON SKIN"), "Second skill is shown")
	print("PASS: battle screen startup, both skill drafts and skill bar")
	quit(0)
