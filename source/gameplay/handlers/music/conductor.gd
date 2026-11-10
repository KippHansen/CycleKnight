extends Node

signal beat(number: int)
signal bpm_changed(new_bpm: float)

const SAVE_PATH := "user://custom_songs.json"  # User editable files, custom_songs.json holds the song settings

@onready var player: AudioStreamPlayer = $AudioStreamPlayer
@onready var detector: bpm_detector = $BPMDetector

var original_bpm := 120.0
var speed := 1.0
var first_beat_offset := 0.0
var beats_per_measure := 4
var current_level: LevelConfig
var custom_songs := {}

var _last_beat := -1

func _ready() -> void:
	load_custom_songs()

# Beat Signal
func _process(delta: float) -> void:
	if not player.playing:
		return
	var current := get_beat()
	if current < _last_beat:
		_last_beat = current - 1
	if current > _last_beat:
		_last_beat = current
		beat.emit(current)


func get_song_position() -> float:
	return player.get_playback_position() \
		+ AudioServer.get_time_since_last_mix() * speed \
		- AudioServer.get_output_latency() * speed \
		- first_beat_offset
	

func get_beat() -> int:
	return floori(get_song_position() / (60.0 / original_bpm))

# BPM and speed

func get_bpm() -> float:
	return original_bpm * speed

func seconds_per_beat() -> float:
	return 60.0 / get_bpm()

func offset_from_beat() -> float:
	var spb := 60.0 / original_bpm
	var t := fposmod(get_song_position(), spb)
	return minf(t, spb - t) / speed

func set_speed(new_speed: float) -> void:
	speed = clampf(new_speed, 0.5, 2.0)
	player.pitch_scale = speed
	bpm_changed.emit(get_bpm())

# Loading and Level
func load_song(path: String) -> bool:
	match path.get_extension().to_lower():
		"ogg":
			player.stream = AudioStreamOggVorbis.load_from_file(path)
		"mp3":
			var mp3 := AudioStreamMP3.new()
			mp3.data = FileAccess.get_file_as_bytes(path)
			player.stream = mp3
		_:
			push_error("This format is unsupported")
			return false
	return player.stream != null

func use_level(level: LevelConfig, force := false) -> void:
	var same_level := not force \
		and player.playing \
		and current_level != null \
		and current_level.level_id == level.level_id
	
	current_level = level
	beats_per_measure = level.beats_per_measure
	
	if same_level:
		return
	
	var saved: Dictionary = custom_songs.get(level.level_id, {})
	if level.allow_custom_song and not saved.is_empty() and load_song(saved["path"]):
		original_bpm = saved["bpm"]
		first_beat_offset = saved["offset"]
	else:
		player.stream = level.game_song
		original_bpm = level.game_bpm
		first_beat_offset = level.first_beat_offset
	speed = 1.0
	player.pitch_scale = 1.0
	_last_beat = -1
	player.play()
	bpm_changed.emit(get_bpm())

# Detection

func detect_current_song() -> void:
	if player.stream == null:
		return
	player.stop()
	var result: Dictionary = await detector.detect(player.stream)
	if result.confidence > 0.1:
		original_bpm = snappedf(result.bpm, 0.5)
		first_beat_offset = result.offset
		bpm_changed.emit(get_bpm())

# Custom Song Saving

func set_custom_song(path: String, bpm: float, offset := 0.0) -> void:
	if current_level == null or not current_level.allow_custom_song:
		return
	custom_songs[current_level.level_id] = {"path": path, "bpm": bpm, "offset": offset}
	save_custom_songs()
	use_level(current_level, true)

func save_custom_songs() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	f. store_string(JSON.stringify(custom_songs))

func load_custom_songs() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
		if data is  Dictionary:
			custom_songs = data
