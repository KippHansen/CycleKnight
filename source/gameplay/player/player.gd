extends CharacterBody2D

@export var move_distance := 1

@onready var grid := get_parent() as GridMovement

func _physics_process(delta: float) -> void:
	var dir := Vector2i.ZERO
	if Input.is_action_pressed("right"): dir = Vector2i.RIGHT
	elif Input.is_action_pressed("left"): dir = Vector2i.LEFT
	elif Input.is_action_pressed("down"): dir = Vector2i.DOWN
	elif Input.is_action_pressed("up"): dir = Vector2i.UP
	
	if dir != Vector2i.ZERO:
		grid.move(self, dir)
