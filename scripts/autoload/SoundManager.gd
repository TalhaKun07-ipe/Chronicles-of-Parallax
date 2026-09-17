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
		"stone_grind":
			num_samples = int(22050 * 1.4)
			for i in range(num_samples):
				var t = float(i) / 22050.0
				var rumble = sin(2.0 * PI * (65.0 + sin(t * 8.0) * 15.0) * t)
				var grit = (randf() * 2.0 - 1.0) * 0.35
				var env = minf(1.0, t / 0.2) * (1.0 - t / 1.4)
				var val = (rumble * 0.7 + grit) * env
				var s16 = int(clamp(val * 22000.0, -32767, 32767))
				data.append(s16 & 0xFF)
				data.append((s16 >> 8) & 0xFF)
		"stone_lock":
			num_samples = int(22050 * 0.4)
			for i in range(num_samples):
				var t = float(i) / 22050.0
				var thud = sin(2.0 * PI * 75.0 * t) * exp(-t * 14.0)
				var clink = sin(2.0 * PI * 520.0 * t) * exp(-t * 22.0)
				var crunch = (randf() * 2.0 - 1.0) * exp(-t * 18.0) * 0.4
				var val = thud * 0.8 + clink * 0.4 + crunch
				var s16 = int(clamp(val * 26000.0, -32767, 32767))
				data.append(s16 & 0xFF)
				data.append((s16 >> 8) & 0xFF)
		"energy_pulse":
			num_samples = int(22050 * 0.45)
			for i in range(num_samples):
				var t = float(i) / 22050.0
				var freq = 220.0 + (t / 0.45) * 440.0
				var val = (sin(2.0 * PI * freq * t) + 0.3 * sin(4.0 * PI * freq * 2.0 * t)) * (1.0 - t / 0.45)
				var s16 = int(clamp(val * 20000.0, -32767, 32767))
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
		"boss_warning":
			num_samples = int(22050 * 0.22)
			for i in range(num_samples):
				var t = float(i) / 22050.0
				var freq = 480.0 + (t / 0.22) * 360.0
				var pulse = sin(2.0 * PI * 28.0 * t) * 0.3 + 0.7
				var val = sin(2.0 * PI * freq * t) * pulse * (1.0 - t / 0.22)
				var s16 = int(clamp(val * 18000.0, -32767, 32767))
				data.append(s16 & 0xFF)
				data.append((s16 >> 8) & 0xFF)
		"boss_sweep":
			num_samples = int(22050 * 0.35)
			for i in range(num_samples):
				var t = float(i) / 22050.0
				var freq = 120.0 + sin(t / 0.35 * PI) * 280.0
				var noise = (randf() * 2.0 - 1.0) * (0.35 * (1.0 - t / 0.35))
				var val = (sin(2.0 * PI * freq * t) * 0.8 + noise) * (1.0 - t / 0.35)
				var s16 = int(clamp(val * 24000.0, -32767, 32767))
				data.append(s16 & 0xFF)
				data.append((s16 >> 8) & 0xFF)
		"boss_beam":
			num_samples = int(22050 * 0.40)
			for i in range(num_samples):
				var t = float(i) / 22050.0
				var freq = 880.0 - (t / 0.40) * 440.0
				var buzz = sin(2.0 * PI * 95.0 * t) * 0.4
				var val = (sin(2.0 * PI * freq * t) * 0.7 + buzz) * (1.0 - t / 0.40)
				var s16 = int(clamp(val * 20000.0, -32767, 32767))
				data.append(s16 & 0xFF)
				data.append((s16 >> 8) & 0xFF)
		"boss_bolts":
			num_samples = int(22050 * 0.16)
			for i in range(num_samples):
				var t = float(i) / 22050.0
				var freq = 740.0 + sin(t * 120.0) * 180.0
				var val = sin(2.0 * PI * freq * t) * exp(-t * 22.0)
				var s16 = int(clamp(val * 19000.0, -32767, 32767))
				data.append(s16 & 0xFF)
				data.append((s16 >> 8) & 0xFF)
		"boss_lane":
			num_samples = int(22050 * 0.32)
			for i in range(num_samples):
				var t = float(i) / 22050.0
				var freq = 85.0 + (t / 0.32) * 60.0
				var hum = sin(2.0 * PI * freq * t) * 0.7 + sin(2.0 * PI * freq * 2.0 * t) * 0.3
				var val = hum * (1.0 - t / 0.32)
				var s16 = int(clamp(val * 22000.0, -32767, 32767))
				data.append(s16 & 0xFF)
				data.append((s16 >> 8) & 0xFF)
		"boss_slam":
			num_samples = int(22050 * 0.45)
			for i in range(num_samples):
				var t = float(i) / 22050.0
				var freq = 90.0 * exp(-t * 6.0)
				var rumble = (randf() * 2.0 - 1.0) * 0.5 * exp(-t * 8.0)
				var val = (sin(2.0 * PI * freq * t) * 0.8 + rumble) * exp(-t * 5.0)
				var s16 = int(clamp(val * 28000.0, -32767, 32767))
				data.append(s16 & 0xFF)
				data.append((s16 >> 8) & 0xFF)
		"boss_nova":
			num_samples = int(22050 * 0.50)
			for i in range(num_samples):
				var t = float(i) / 22050.0
				var freq1 = 330.0 + (t / 0.50) * 550.0
				var freq2 = 660.0 - (t / 0.50) * 300.0
				var val = (sin(2.0 * PI * freq1 * t) * 0.5 + sin(2.0 * PI * freq2 * t) * 0.5) * (1.0 - t / 0.50)
				var s16 = int(clamp(val * 22000.0, -32767, 32767))
				data.append(s16 & 0xFF)
				data.append((s16 >> 8) & 0xFF)
		"boss_core_open":
			num_samples = int(22050 * 0.65)
			for i in range(num_samples):
				var t = float(i) / 22050.0
				var step = int(t * 3.0 / 0.65)
				var freq = 523.25 if step == 0 else (659.25 if step == 1 else 783.99)
				var val = sin(2.0 * PI * freq * t) * (1.0 - t / 0.65)
				var s16 = int(clamp(val * 20000.0, -32767, 32767))
				data.append(s16 & 0xFF)
				data.append((s16 >> 8) & 0xFF)
		"boss_hit":
			num_samples = int(22050 * 0.28)
			for i in range(num_samples):
				var t = float(i) / 22050.0
				var noise = (randf() * 2.0 - 1.0) * 0.6 * exp(-t * 14.0)
				var metallic = sin(2.0 * PI * 340.0 * t) * 0.5 * exp(-t * 9.0)
				var val = (metallic + noise) * (1.0 - t / 0.28)
				var s16 = int(clamp(val * 25000.0, -32767, 32767))
				data.append(s16 & 0xFF)
				data.append((s16 >> 8) & 0xFF)
		_:
			return null
			
	wav.data = data
	return wav
