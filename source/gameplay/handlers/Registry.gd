class_name Registry
extends Node

const ROOMS := {
	"title": "res://source/rooms/final/title.tscn"
}

const MENUS := {
	"options": "res://source/gameplay/menus/options_menu.tscn"
}

func has_room(id: String) -> bool:
	return ROOMS.has(id)

func get_room(id: String) -> PackedScene:
	return _load_from(ROOMS, id)

func get_menu(id: String) -> PackedScene:
	return _load_from(MENUS, id)
	

func _load_from(table: Dictionary, id: String) -> PackedScene:
	if not table.has(id):
		push_error("Unknown scene id '%s'" % id)
		return null
	return load(table[id]) as PackedScene
