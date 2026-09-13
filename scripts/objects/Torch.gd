extends Node3D
class_name Torch

# Ambient torch bracket with flickering warm amber light

@onready var light: OmniLight3D = $OmniLight3D
var base_energy: float = 1.3
var noise_time: float = 0.0

func _ready() -> void:
	noise_time = randf() * 100.0

func _process(delta: float) -> void:
	noise_time += delta * 8.0
	# Subtle natural flame flicker
	if light:
		light.light_energy = base_energy + sin(noise_time) * 0.15 + sin(noise_time * 2.3) * 0.08
