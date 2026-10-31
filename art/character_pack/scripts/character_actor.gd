extends Node2D
## Presentation only. Combat decides damage; impact marks the visual contact time.
signal impact
signal action_finished(action: StringName)
signal action_cancelled(action: StringName)

@export var equipment_slots: Dictionary = {}
@onready var animation_player: AnimationPlayer = $AnimationPlayer
var active_action: StringName = &"idle"

func _ready() -> void:
	animation_player.animation_finished.connect(_on_animation_finished)
	animation_player.play(&"idle")

func play_action(action: StringName) -> bool:
	if action not in [&"idle", &"attack", &"hit"] or not animation_player.has_animation(action):
		return false
	if active_action != &"idle":
		action_cancelled.emit(active_action)
	active_action = action
	animation_player.stop()
	animation_player.play(action)
	animation_player.advance(0)
	return true

func _emit_impact() -> void:
	if active_action == &"attack":
		impact.emit()

func _on_animation_finished(action: StringName) -> void:
	active_action = &"idle"
	animation_player.play(&"idle")
	action_finished.emit(action)

func set_facing(direction: int) -> void:
	$Facing.scale.x = -1.0 if direction < 0 else 1.0

func set_equipment_texture(slot: String, texture: Texture2D) -> bool:
	if not equipment_slots.has(slot) or texture == null:
		return false
	var sprite := get_node_or_null(NodePath(equipment_slots[slot])) as Sprite2D
	if sprite == null:
		return false
	var size: Vector2 = sprite.get_meta(&"display_size")
	sprite.texture = texture
	sprite.scale = size / Vector2(texture.get_size())
	sprite.visible = true
	return true

func set_armor_visible(enabled: bool) -> void:
	for slot in ["helmet", "chest"]:
		if equipment_slots.has(slot):
			get_node(NodePath(equipment_slots[slot])).visible = enabled
