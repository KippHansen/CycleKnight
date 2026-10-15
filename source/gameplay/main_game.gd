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






# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
