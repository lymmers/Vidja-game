extends SceneTree
## Render-order contract for supplied cutout parts in every animated state.
const Scenes = [preload("res://characters/hero/hero.tscn"), preload("res://characters/skeleton/skeleton.tscn")]
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, reason: String) -> void:
	if not ok:
		failures += 1
		push_error("FAIL: " + reason)
func effective_z(item: CanvasItem) -> int:
	return item.z_index + (effective_z(item.get_parent()) if item.z_as_relative and item.get_parent() is CanvasItem else 0)
func run() -> void:
	for scene in Scenes:
		var actor = scene.instantiate()
		root.add_child(actor)
		actor.animation_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		for facing in [-1, 1]:
			actor.set_facing(facing)
			for action in ["idle", "attack", "hit", "interrupted", "reset"]:
				actor.play_action("attack" if action in ["interrupted", "reset"] else action)
				actor.animation_player.advance(0.18)
				if action in ["interrupted", "reset"]:
					actor.play_action("hit" if action == "interrupted" else "idle")
				for sample in range(20):
					actor.animation_player.advance(0.04)
					var parts := {}
					for sprite in actor.find_children("Art_*", "Sprite2D", true, false):
						parts[str(sprite.name)] = sprite
					for forearm in ["Art_forearm", "Art_far_forearm"]:
						check(effective_z(parts[forearm]) > effective_z(parts["Art_torso"]), "%s %s: %s above torso" % [actor.name, action, forearm])
						check(effective_z(parts[forearm]) > effective_z(parts["Art_pelvis"]), "%s %s: %s above pelvis" % [actor.name, action, forearm])
					check(effective_z(parts["Art_far_forearm"]) < effective_z(parts["Art_shield"]), "Shield stays above supporting forearm")
					check(effective_z(parts["Art_far_upper_arm"]) < effective_z(parts["Art_torso"]), "Far shoulder remains behind torso")
		actor.queue_free()
		await process_frame
	print("PASS: rig layering in both facings, idle, attack, hit, interruption and reset" if failures == 0 else "FAIL: rig layering")
	quit(1 if failures else 0)
