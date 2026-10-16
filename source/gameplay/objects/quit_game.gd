extends Button

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	var game := get_tree().get_first_node_in_group("main_game")
	if game:
		game.quit_game()
	else:
		get_tree().quit()
