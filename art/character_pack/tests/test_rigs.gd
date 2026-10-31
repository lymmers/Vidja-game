extends SceneTree

var impacts := 0
var cancellations := 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	for who in ["hero", "skeleton"]:
		var path := "res://characters/%s/%s.tscn" % [who, who]
		assert(ResourceLoader.exists(path), "Missing scene: " + path)
		var actor = load(path).instantiate()
		root.add_child(actor)
		var player: AnimationPlayer = actor.get_node("AnimationPlayer")
		for action in ["idle", "attack", "hit", "RESET"]:
			assert(player.has_animation(action))
		actor.impact.connect(func(): impacts += 1)
		actor.action_cancelled.connect(func(_a): cancellations += 1)
		player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		assert(actor.play_action("attack"))
		player.advance(0.30)
		assert(impacts == 1)
		assert(actor.play_action("hit"))
		assert(cancellations == 1)
		player.advance(0.50)
		assert(player.current_animation == "idle")
		player.advance(1.0)
		assert(impacts == 1, "Interrupted attack fired late")
		assert(not actor.play_action("nonexistent"))
		actor.set_facing(-1)
		assert(actor.get_node("Facing").scale.x == -1.0)
		actor.set_facing(1)
		assert(actor.get_node("Facing").scale.x == 1.0)
		var tex = load("res://characters/%s/parts/sword.png" % who)
		assert(actor.set_equipment_texture("weapon", tex))
		assert(not actor.set_equipment_texture("missing", tex))
		if who == "skeleton":
			assert(not actor.equipment_slots.has("helmet"))
		actor.set_armor_visible(true)
		assert(actor.get_node(actor.equipment_slots["chest"]).visible)
		actor.set_armor_visible(false)
		actor.play_action("attack")
		player.advance(.80)
		assert(player.current_animation == "idle")
		assert(impacts == 2)
		actor.queue_free()
		await process_frame
		impacts = 0
		cancellations = 0
	print("PASS: both rigs; animations, impact, interruptions, idle return, facing, equipment")
	quit()
