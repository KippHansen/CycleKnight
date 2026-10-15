class_name GridMovement
extends Node2D

const GRID_SIZE       := 64
@export var move_time := 0.2

var occupied := {}    #Cells that are occupied
var moving   := {}    #Which entities are moving


func _ready() -> void:
	for actor in get_children():
		if actor is CharacterBody2D:
			var cell := to_cell(actor.position)
			actor.position = to_world(cell)
			occupied[cell] = actor

func move(actor: CharacterBody2D, dir: Vector2i) -> bool:
	if moving.has(actor):
		return false
	
	var prev := to_cell(actor.position)
	var steps: int = actor.get("move_distance") if actor.get("move_distance") != null else 1
	var target := prev
	
	for i in steps:
		var next := target + dir
		var t := actor.global_transform
		t.origin = to_global(to_world(target))
		if occupied.has(next) or actor.test_move(t, Vector2(dir) * GRID_SIZE):
			break
		target = next
	
	if target == prev:
		return false
	
	occupied.erase(prev)
	occupied[target] = actor
	moving[actor] = true
	
	#Learn about tweens
	var distance := (target - prev).length()
	var tween := create_tween()
	tween.tween_property(actor, "position", to_world(target), move_time * distance)
	tween.finished.connect(func(): moving.erase(actor))
	return true
	




func to_cell(pos: Vector2) -> Vector2i:
	return Vector2i((pos / GRID_SIZE).round())

func to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell) * GRID_SIZE
