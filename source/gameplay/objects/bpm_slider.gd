extends HSlider

# Each slider position maps to one speed
const SPEEDS := [0.5, 0.75, 1.0, 1.5, 2.0]

func _ready() -> void:
	# Show the Conductor's current speed on the right stop
	value = _closest_index(Conductor.speed)
	value_changed.connect(_on_value_changed)

func _on_value_changed(index: float) -> void:
	Conductor.set_speed(SPEEDS[int(index)])

# Finds which stop matches a speed, in case the Conductor is already at one
func _closest_index(speed: float) -> int:
	var best := 0
	for i in SPEEDS.size():
		if absf(SPEEDS[i] - speed) < absf(SPEEDS[best] - speed):
			best = i
	return best
