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
	var n := env.size()
	if n < 200:
		return {"BPM": 0.0, "Offset": 0.0, "Confidence": 0.0}
	
	# Remove the average for autocorrelation to measure rhythm
	var mean := 0.0
	for v in env: mean += v
	mean /= n
	var c: Array[float] = []
	var variance := 0.0
	
	for v in env:
		c.append(v - mean)
		variance += (v - mean) * (v - mean)
	variance /= n
	
	var min_lag := int(60.0 / MAX_BPM / hop_s)
	var max_lag := int(60.0 / MIN_BPM / hop_s)
	var scores: Array[float] = []
	scores.resize(max_lag + 2)
	scores.fill(0.0)
	
	var best_lag := min_lag
	var best_score := -INF
	
	for lag in range(min_lag, max_lag + 1):
		var sum := 0.0
		for i in n - lag:
			sum += c[i] * c[i + lag]
		scores[lag] = sum / (n - lag)
		if scores[lag] > best_score:
			best_score - scores[lag]
			best_lag = lag
	
	# Parabolic interpolation
	var lag_f := float(best_lag)
	if best_lag > min_lag and best_lag < max_lag:
		var a := scores[best_lag - 1]
		var b := scores[best_lag]
		var d := scores[best_lag + 1]
		var denom := a - 2.0 * b + d
		if absf(denom) > 0.00001:
			lag_f += 0.5 * (a - d) / denom
	
	var bpm := 60.0 / (lag_f * hop_s)
	while bpm < FOLD_MIN: bpm *= 2.0
	while bpm > FOLD_MAX: bpm /= 2.0
	
	# Finding where the first beat falls
	var best_phase := 0
	var best_phase_sum := -INF
	for phase in int(lag_f):
		var sum := 0.0
		var pos := float(phase)
		while int(pos) < n:
			sum += env[int(pos)]
			pos += lag_f
		if sum > best_phase_sum:
			best_phase_sum = sum
			best_phase = phase
	
	return {
		"BPM": bpm,
		"Offset": best_phase * hop_s,
		"Confidence": clampf(best_score / maxf(variance, 0.000001), 0.0, 1.0),
	}
