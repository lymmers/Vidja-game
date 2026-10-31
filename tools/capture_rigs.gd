extends SceneTree
## Diagnostic screenshots from the actual renderer; requires a graphical display.
## Run with --script res://tools/capture_rigs.gd -- game OUTPUT_DIRECTORY.
## For the original standalone project use an absolute script path and mode demo.
var actors: Array = []
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var args = OS.get_cmdline_user_args()
	var mode: String = args[0]
	var output: String = args[1]
	DirAccess.make_dir_recursive_absolute(output)
	if mode == "comparison":
		await capture_comparison(output)
		quit()
		return
	if mode == "combat":
		await capture_combat(output)
		quit()
		return
	var container
	if mode == "game":
		root.size = Vector2i(720, 1280)
		container = load("res://scenes/battle_screen.tscn").instantiate()
		root.add_child(container)
		container.draft_overlay.hide()
		actors = [container.stage.hero_actor, container.stage.enemy_actor]
	else:
		root.size = Vector2i(1000, 650)
		container = load("res://demo.tscn").instantiate()
		root.add_child(container)
		container.set_process(false)
		actors = [container.hero, container.enemy]
	for actor in actors:
		actor.set_block_signals(true)
		actor.animation_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	for action in ["idle", "attack", "attack_contact", "recovery", "hit", "interrupted", "reset"]:
		for actor in actors:
			actor.play_action("attack" if action in ["interrupted", "reset", "attack_contact", "recovery"] else action)
			var sample: float = 0.18 if action in ["attack", "interrupted", "reset"] else 0.07
			if action == "attack_contact": sample = 0.29
			if action == "recovery": sample = 0.55
			actor.animation_player.advance(sample)
			if action == "interrupted":
				actor.play_action("hit")
				actor.animation_player.advance(0.07)
			if action == "reset":
				actor.play_action("idle")
		await process_frame
		await RenderingServer.frame_post_draw
		var path: String = output + "/" + mode + "-" + action + ".png"
		assert(root.get_texture().get_image().save_png(path) == OK)
		print("CAPTURE: ", path)
	container.queue_free()
	await process_frame
	quit()


func capture_combat(output: String) -> void:
	root.size = Vector2i(720, 1280)
	var screen = load("res://scenes/battle_screen.tscn").instantiate()
	root.add_child(screen)
	screen.battle.rng.seed = 177
	screen._choose_skill("iron_skin")
	var captured := {}
	for frame in range(12000):
		await process_frame
		if screen.choosing:
			screen._choose_skill("fireball")
		var hero = screen.stage.hero_actor
		var enemy = screen.stage.enemy_actor
		var name: String = ""
		if enemy != null and hero.active_action == &"attack" and enemy.active_action == &"hit":
			name = "combat-hero-contact"
		elif enemy != null and enemy.active_action == &"attack" and hero.active_action == &"hit":
			name = "combat-enemy-contact"
		elif screen.battle.encounter == 2 and hero.active_action == &"hit":
			name = "combat-alchemist-hit"
		if not name.is_empty() and not captured.has(name):
			await RenderingServer.frame_post_draw
			assert(root.get_texture().get_image().save_png(output + "/" + name + ".png") == OK)
			captured[name] = true
			print("CAPTURE: ", name)
		if screen.replay_button.visible:
			break
	assert(captured.size() == 3, "All required combat captures completed")
	screen.queue_free()
	await process_frame


func capture_comparison(output: String) -> void:
	root.content_scale_size = Vector2i(990, 450)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.size = Vector2i(990, 450)
	var canvas := Control.new()
	root.add_child(canvas)
	var background := ColorRect.new()
	background.color = Color("e9e4d8")
	background.size = Vector2(990, 450)
	canvas.add_child(background)
	var panels := [
		["Original demo (unchanged)", "source-demo-idle.png", Rect2i(230, 105, 280, 330)],
		["Game before", "game-before-idle.png", Rect2i(110, 490, 250, 260)],
		["Game corrected", "game-after-idle.png", Rect2i(110, 490, 250, 260)],
	]
	for index in range(panels.size()):
		var panel: Array = panels[index]
		var label := Label.new()
		label.text = panel[0]
		label.position = Vector2(index * 330 + 10, 16)
		label.add_theme_color_override("font_color", Color("273846"))
		label.add_theme_font_size_override("font_size", 20)
		canvas.add_child(label)
		var texture := TextureRect.new()
		texture.texture = ImageTexture.create_from_image(Image.load_from_file(output + "/" + panel[1]).get_region(panel[2]))
		texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture.position = Vector2(index * 330 + 10, 55)
		texture.size = Vector2(310, 350)
		canvas.add_child(texture)
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(output + "/forearm-layering-comparison.png") == OK)
	canvas.queue_free()
	await process_frame
