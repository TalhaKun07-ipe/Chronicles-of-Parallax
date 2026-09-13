extends Node

# Procedural synthesizer and SFX manager for Degrees of Escape

var audio_player: AudioStreamPlayer
var rewind_player: AudioStreamPlayer
var bgm_player: AudioStreamPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	
	rewind_player = AudioStreamPlayer.new()
	add_child(rewind_player)
	
	bgm_player = AudioStreamPlayer.new()
	add_child(bgm_player)
	bgm_player.volume_db = -8.0

func play_sfx(sfx_name: String) -> void:
	var stream = generate_sound(sfx_name)
	if stream:
		var p = AudioStreamPlayer.new()
		add_child(p)
		p.stream = stream
		p.finished.connect(p.queue_free)
		p.play()

func start_rewind_loop() -> void:
	if not rewind_player.playing:
		var stream = generate_sound("rewind_loop")
		if stream:
			rewind_player.stream = stream
			rewind_player.play()

func stop_rewind_loop() -> void:
	if rewind_player.playing:
		rewind_player.stop()

func generate_sound(type: String) -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	
	var data = PackedByteArray()
	var num_samples = 0
	
	match type:
		"jump":
			num_samples = int(22050 * 0.15)
			for i in range(num_samples):
				var t = float(i) / 22050.0
				var freq = 200.0 + (t / 0.15) * 400.0
				var val = sin(2.0 * PI * freq * t) * (1.0 - t / 0.15)
				var s16 = int(clamp(val * 16000.0, -32767, 32767))
				data.append(s16 & 0xFF)
				data.append((s16 >> 8) & 0xFF)
		"transform":
			num_samples = int(22050 * 0.25)
			for i in range(num_samples):
				var t = float(i) / 22050.0
				var freq = 600.0 - (t / 0.25) * 350.0
				var val = (sin(2.0 * PI * freq * t) + 0.5 * sin(4.0 * PI * freq * t)) * (1.0 - t / 0.25)
				var s16 = int(clamp(val * 18000.0, -32767, 32767))
				data.append(s16 & 0xFF)
				data.append((s16 >> 8) & 0xFF)
		"pulse":
			num_samples = int(22050 * 0.3)
			for i in range(num_samples):
				var t = float(i) / 22050.0
				var freq = 120.0
				var val = sin(2.0 * PI * freq * t) * exp(-t * 12.0)
				var s16 = int(clamp(val * 24000.0, -32767, 32767))
				data.append(s16 & 0xFF)
				data.append((s16 >> 8) & 0xFF)
		"hurt":
			num_samples = int(22050 * 0.2)
			for i in range(num_samples):
				var t = float(i) / 22050.0
				var freq = 150.0 - (t / 0.2) * 80.0
				var noise = (randf() * 2.0 - 1.0) * 0.4
				var val = (sin(2.0 * PI * freq * t) + noise) * (1.0 - t / 0.2)
				var s16 = int(clamp(val * 22000.0, -32767, 32767))
				data.append(s16 & 0xFF)
				data.append((s16 >> 8) & 0xFF)
		"unlock":
			num_samples = int(22050 * 0.45)
			for i in range(num_samples):
				var t = float(i) / 22050.0
				var phase = int(t * 3.0 / 0.45)
				var freq = 440.0 if phase == 0 else (554.37 if phase == 1 else 659.25)
				var val = sin(2.0 * PI * freq * t) * (1.0 - t / 0.45)
				var s16 = int(clamp(val * 18000.0, -32767, 32767))
				data.append(s16 & 0xFF)
				data.append((s16 >> 8) & 0xFF)
		"error":
			num_samples = int(22050 * 0.12)
			for i in range(num_samples):
				var t = float(i) / 22050.0
				var val = sin(2.0 * PI * 130.0 * t) * (1.0 - t / 0.12)
				var s16 = int(clamp(val * 18000.0, -32767, 32767))
				data.append(s16 & 0xFF)
				data.append((s16 >> 8) & 0xFF)
		"rewind_loop":
			num_samples = int(22050 * 0.5)
			wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
			wav.loop_end = num_samples
			for i in range(num_samples):
				var t = float(i) / 22050.0
				# Reverse ticking whoosh
				var freq = 180.0 + (t / 0.5) * 220.0
				var tick = sin(2.0 * PI * freq * t) * (0.5 + 0.5 * sin(2.0 * PI * 16.0 * t))
				var s16 = int(clamp(tick * 12000.0, -32767, 32767))
				data.append(s16 & 0xFF)
				data.append((s16 >> 8) & 0xFF)
		"typewriter":
			num_samples = int(22050 * 0.038)
			for i in range(num_samples):
				var t = float(i) / 22050.0
				var env = exp(-t * 110.0)
				var val = sin(2.0 * PI * 580.0 * t) * env
				var s16 = int(clamp(val * 13000.0, -32767, 32767))
				data.append(s16 & 0xFF)
				data.append((s16 >> 8) & 0xFF)
		"story_chord":
			num_samples = int(22050 * 2.8)
			for i in range(num_samples):
				var t = float(i) / 22050.0
				var env = (1.0 - t / 2.8) * (1.0 - exp(-t * 6.0))
				var c1 = sin(2.0 * PI * 220.0 * t) * 0.35
				var c2 = sin(2.0 * PI * 261.63 * t) * 0.3
				var c3 = sin(2.0 * PI * 329.63 * t) * 0.25
				var c4 = sin(2.0 * PI * 493.88 * t) * 0.15
				var val = (c1 + c2 + c3 + c4) * env
				var s16 = int(clamp(val * 15000.0, -32767, 32767))
				data.append(s16 & 0xFF)
				data.append((s16 >> 8) & 0xFF)
		_:
			return null
			
	wav.data = data
	return wav
