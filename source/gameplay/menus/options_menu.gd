extends CanvasLayer

signal closed


func _on_back_button_pressed() -> void:
	closed.emit()
