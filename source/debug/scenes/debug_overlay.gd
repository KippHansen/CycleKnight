extends Control

const VERSION_SETTING : String = "application/config/version"

@onready var version_info: Label = %version_info
@onready var fps_label: Label = %fps_label



func _ready() -> void:
	_add_version_to_label()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	fps_label.set_text("FPS: " + str(Engine.get_frames_per_second()))

func _add_version_to_label() -> void:
	var version_num = ProjectSettings.get_setting(VERSION_SETTING)
	version_info.text += str(version_num)
