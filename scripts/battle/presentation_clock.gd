extends RefCounted
class_name PresentationClock
## Real-world playback pacing only. Never pass this to the combat model.
## A future 2x feature changes delays, not RNG calls or logical turn count.

var speed: float = 1.0


func set_speed(multiplier: float) -> void:
	speed = clampf(multiplier, 0.25, 4.0)


func wait_seconds(base_seconds: float) -> float:
	return maxf(0.0, base_seconds) / speed