extends Node

#Scene Tree Initialize

#Save/Load/Registry
@onready var system: Node = $system

#World
@onready var level_root: Node2D = %level_root
@onready var entity_root: Node2D = %entity_root
@onready var effect_root: Node2D = %effect_root

#Canvas
@onready var hud_layer: CanvasLayer = $hud_layer
@onready var pause_layer: CanvasLayer = $pause_layer
@onready var transition_layer: CanvasLayer = $transition_layer
@onready var debug_layer: CanvasLayer = $debug_layer
@onready var registry: Registry = $system/Registry
@onready var world: Node2D = $world


func _ready() -> void:
	show_room("title")
	



func open_menu(menu_id: String) -> Node:
	var scene := registry.get_menu(menu_id)
	if scene == null:
		return null
	var menu := scene.instantiate()
	$pause_layer.add_child(menu)
	menu.closed.connect(menu.queue_free)
	return menu
	

func show_room(room_id: String) -> Node:
	var scene := registry.get_room(room_id)
	if scene == null:
		return null
	return world.load_level(scene)


func change_room(room_id: String, spawn_cell: Vector2i) -> void:
	var scene := registry.get_room(room_id)
	if scene == null:
		return
	$world/entity_root/GridMovement.clear()
	$world.load_level(scene)
	


func quit_game() -> void:
	# $system/SaveManager.save()   # add later if you have saving
	get_tree().quit()
