extends Button

@export var menu_id := "options"

func _ready() -> void:
	pressed.connect(func():
		var game := get_tree().get_first_node_in_group("main_game")
		if game:
			game.open_menu(menu_id)
	)
