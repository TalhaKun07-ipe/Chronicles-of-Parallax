extends Node
## Small synthesized cues for the standalone demo; the full game keeps its SoundManager.
var voices: Array[AudioStreamPlayer] = []
var next_voice: int = 0
var clips: Dictionary = {}

func _ready() -> void:
	for i: int in 6:
		var voice: AudioStreamPlayer = AudioStreamPlayer.new()
		voice.volume_db = -17
		add_child(voice)
		voices.append(voice)
	for cue: String in ["typewriter", "transform", "error", "hurt", "unlock", "victory"]:
		clips[cue] = synth(cue)

func synth(cue: String) -> AudioStreamWAV:
	var duration: float = 0.045 if cue == "typewriter" else 0.22
	if cue == "victory": duration = 0.8
	var frequencies: Dictionary = {"typewriter": 310.0, "transform": 540.0, "error": 130.0, "hurt": 95.0, "unlock": 780.0, "victory": 660.0}
	var hz: float = frequencies[cue]
	var samples: int = int(duration * 22050)
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(samples * 2)
	for i: int in samples:
		var t: float = float(i) / 22050.0
		var envelope: float = minf(t * 150, 1.0) * (1.0 - t / duration)
		var wave: float = sin(TAU * hz * t + (t * t * 1600 if cue == "transform" else 0.0))
		bytes.encode_s16(i * 2, int(wave * envelope * 12000))
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.data = bytes
	return stream

func play_sfx(cue: String) -> void:
	if not clips.has(cue) or voices.is_empty(): return
	var voice: AudioStreamPlayer = voices[next_voice]
	next_voice = (next_voice + 1) % voices.size()
	voice.stream = clips[cue]
	voice.play()
