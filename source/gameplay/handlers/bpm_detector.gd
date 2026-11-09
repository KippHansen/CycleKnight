class_name bpm_detector
extends Node

# Constants:

const BUS_NAME := "BPM_Detector"
const HOP := 512
	# BPM Search Range
const MIN_BPM := 70.0
const MAX_BPM := 180.0
	# Fold Values
const FOLD_MIN := 80.0
const FOLD_MAX := 160.0

# Variables:

var audio_capture: AudioEffectCapture
var audio_player: AudioStreamPlayer

func _ready() -> void:
	var index := AudioServer.get_bus_index(BUS_NAME)
	# Check if BPM_Detector bus exists
	if index == -1:
		# Add New Bus for BPM_Detector
		AudioServer.add_bus()
		index = AudioServer.bus_count - 1 # BPM_Detectors New Bus Index
		AudioServer.set_bus_name(index, BUS_NAME)
		
		# Instantiate Effect Capture
		var capture := AudioEffectCapture.new()
		capture.buffer_length = 0.5
		AudioServer.add_bus_effect(index, capture) # add_bus_effect adds effect to am Audio Bus. Args: (Which Bus, What Effect)
		
		# Add amp and silence audio for player to not hear anything
		# Amplify adjusts the volume of an audio bus
		var amp := AudioEffectAmplify.new()
		amp.volume_db = -80.0
		AudioServer.add_bus_effect(index, amp)
		
	# This loads the audio into
	audio_capture = AudioServer.get_bus_effect(index, 0) as AudioEffectCapture
	audio_player = AudioStreamPlayer.new()
	audio_player.bus = BUS_NAME
	add_child(audio_player)

# Return: BPM, Offstet, Confidence
func detect(stream: AudioStream, seconds := 20.0) -> Dictionary:
	audio_capture.clear_buffer()
	audio_player.stream = stream
	audio_player.play()
	
	var hop_seconds := HOP / AudioServer.get_mix_rate()
	var envelope: Array[float] = []
	var pending := PackedVector2Array() # Array of Vector2's
	var prev_energy := 0.0
	
	# While song is playing and current stamp is less than 20 seconds
	while audio_player.playing and audio_player.get_playback_position() < seconds: 
		await get_tree().process_frame # Wait for scene tree process to finish the frame
		pending.append_array(audio_capture.get_buffer(audio_capture.get_frames_available()))
		
		var i := 0
		while pending.size() - i >= HOP:
			var energy := 0.0
			var prev_sample := 0.0
			for j in HOP:
				var s := (pending[i+j].x + pending[i+j].y) * 0.5
				var d := s - prev_sample
				prev_sample = s
				energy += d * d
			i += HOP
			energy = sqrt(energy / HOP)
			envelope.append(maxf(0.0, energy - prev_energy))
			prev_energy = energy
		pending = pending.slice(i)
	
	audio_player.stop()
	return _analyze(envelope, hop_seconds)


func _analyze(env: Array[float], hop_s: float) -> Dictionary:
	return {}
