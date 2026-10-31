extends RefCounted
## Presentation-only asset registry. Combat never loads or addresses rig nodes.
## Keep equipment pivots and all native animation tracks inside supplied scenes.
const DEFINITIONS: Dictionary = {
	"wayfarer": {"scene": preload("res://characters/hero/hero.tscn"), "scale": 0.9, "facing": 1},
	"skeleton_guard": {"scene": preload("res://characters/skeleton/skeleton.tscn"), "scale": 0.9, "facing": -1},
}
static func instantiate_actor(visual: String) -> Node2D:
	if not DEFINITIONS.has(visual):
		return null # Legacy procedural visuals are still supported by BattleStage.
	var definition: Dictionary = DEFINITIONS[visual]
	var actor: Node2D = definition["scene"].instantiate()
	actor.scale = Vector2.ONE * float(definition["scale"])
	actor.call("set_facing", int(definition["facing"]))
	return actor
