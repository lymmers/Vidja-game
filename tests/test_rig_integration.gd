extends SceneTree
## Native asset playback and mixed-renderer regressions; no model timing dependency.
const Stage = preload("res://scripts/visuals/battle_stage.gd")
const Encounters = preload("res://scripts/combat/encounter_catalog.gd")
var failures := 0
func check(ok: bool, reason: String) -> void:
	if not ok:
		failures += 1
		push_error("FAIL: " + reason)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	check(Encounters.get_definition(1)["name"] == "SKELETON", "Enemy 1 displayed identity")
	check(Encounters.get_definition(1)["visual"] == "skeleton_guard", "Distinct cutout selector")
	check(Encounters.get_definition(2) == {
		"name": "BONE ALCHEMIST", "hp": 75, "visual": "skeleton", "area": "BONE LABORATORY",
		"intro": "A skeleton alchemist uncorks a fire potion!",
		"attack_min": 10, "attack_max": 14, "armor": 1, "crit_chance": 0.12,
		"special_action": {"every": 3, "kind": "potion", "damage_type": "magic", "can_crit": false},
	}, "Enemy 2 definition remains exactly unchanged")
	var stage = Stage.new()
	root.add_child(stage)
	if stage.get("hero_actor") == null:
		check(false, "Stage instances supplied hero rig")
		stage.free()
		quit(1)
		return
	stage.enemy_kind = "skeleton_guard"
	var hero = stage.hero_actor
	var enemy = stage.enemy_actor
	check(enemy != null, "Stage instances supplied skeleton")
	check(hero.position == Vector2(210, 751), "Hero feet align with platform")
	check(enemy.position == Vector2(515, 751), "Enemy feet align with platform")
	check(hero.get_node("Facing").scale.x == 1, "Hero faces right")
	check(enemy.get_node("Facing").scale.x == -1, "Enemy faces left")
	for actor in [hero, enemy]:
		check(actor.animation_player.current_animation == "idle", "Native idle starts")
		check(actor.get_node("Facing/Rig/Body") != null, "Supplied joint hierarchy preserved")
	var impacts := [0]
	hero.impact.connect(func(): impacts[0] += 1)
	stage.animation_speed = 2.0
	check(hero.animation_player.speed_scale == 2.0 and enemy.animation_player.speed_scale == 2.0, "Native speed follows presentation")
	stage.animate_attack("hero")
	check(hero.active_action == &"attack", "Native attack selected")
	for i in range(10):
		await process_frame
	check(impacts[0] == 1, "Exactly one native contact cue")
	check(enemy.active_action == &"hit", "Contact plays native damage recoil")
	for i in range(30):
		await process_frame
	check(hero.active_action == &"idle" and enemy.active_action == &"idle", "Actors return to idle")
	stage.animate_attack("hero")
	stage.reset_pose()
	for i in range(60):
		await process_frame
	check(impacts[0] == 1, "Reset cancels late contact")
	var enemy_impacts := [0]
	enemy.impact.connect(func(): enemy_impacts[0] += 1)
	await stage.animate_attack("enemy")
	check(enemy_impacts[0] == 1, "Integrated skeleton uses native attack contact")
	stage.enemy_kind = "skeleton"
	check(stage.enemy_actor == null, "Alchemist keeps procedural renderer")
	await stage.animate_attack("enemy")
	check(hero.active_action == &"hit", "Procedural attacker supports rig target")
	await stage.animate_spell("potion")
	check(stage.flying_spell.is_empty(), "Original potion animation completes")
	check(hero.active_action == &"hit", "Potion contact plays native hero recoil")
	stage.queue_free()
	await process_frame
	await test_overlay_order()
	await test_progression()
	print("PASS: rig integration and two-encounter progression" if failures == 0 else "FAIL: rig integration")
	quit(1 if failures else 0)
func test_progression() -> void:
	var screen = load("res://scenes/battle_screen.tscn").instantiate()
	root.add_child(screen)
	screen.battle.rng.seed = 177
	screen._set_game_speed(2.0)
	check(screen.enemy_name_label.text == "SKELETON", "Initial header follows encounter data")
	screen._choose_skill("iron_skin")
	var saw_second := false
	for frame in range(12000):
		await process_frame
		if screen.choosing:
			screen._choose_skill("fireball")
		if screen.battle.encounter == 2:
			saw_second = true
			check(screen.stage.enemy_kind == "skeleton" and screen.stage.enemy_actor == null, "Mixed rendering after transition")
			check(screen.enemy_name_label.text == "BONE ALCHEMIST", "Second identity preserved")
		if screen.replay_button.visible:
			break
	check(saw_second, "Natural combat reaches encounter two")
	check(screen.replay_button.visible, "Adventure reaches an end state")
	check(screen.battle.winner == "hero", "Seeded adventure clears both encounters")
	check(screen.combat_log_entries.any(func(e): return e.contains("Fire Potion")), "Second enemy still uses potion")
	screen._start_run()
	check(screen.stage.enemy_actor != null and screen.enemy_name_label.text == "SKELETON", "Restart restores first rig and identity")
	screen.queue_free()
	await process_frame


func effective_z(item: CanvasItem) -> int:
	var total := item.z_index
	if item.z_as_relative and item.get_parent() is CanvasItem:
		total += effective_z(item.get_parent())
	return total

func test_overlay_order() -> void:
	var screen = load("res://scenes/battle_screen.tscn").instantiate()
	root.add_child(screen)
	for rig in [screen.stage.hero_actor, screen.stage.enemy_actor]:
		for sprite in rig.find_children("*", "Sprite2D", true, false):
			check(effective_z(sprite) < effective_z(screen.draft_overlay), "Rig parts remain behind draft")
			check(effective_z(sprite) < effective_z(screen.log_overlay), "Rig parts remain behind combat log")
			check(effective_z(sprite) < effective_z(screen.hero_hp_label), "Rig parts remain behind HUD")
	screen.queue_free()
	await process_frame
