extends Node2D


@onready var level_root: Node2D = %level_root
@onready var entity_root: Node2D = %entity_root
@onready var effect_root: Node2D = %effect_root


func load_level(scene: PackedScene) -> Node:
	for child in level_root.get_children():
		child.queue_free()
	var level := scene.instantiate()
	level_root.add_child(level)
	return level
