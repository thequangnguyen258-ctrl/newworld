extends Node

# ==============================================================================
# AUDIO SYNTHESIZER - HỆ THỐNG ÂM THANH PROCEDURAL DIEGETIC TÂN THẾ GIỚI
# Tự động tổng hợp âm thanh bằng AudioStreamGenerator không cần file ngoài:
# 1. Tiếng Chuông Nhà Thờ Hòa Bình (Bell Chime - Trầm bổng ngân nga)
# 2. Tiếng Còi Xe Buggy (Buggy Horn - Hai âm sắc Bíp Bíp)
# 3. Tiếng Khen Thưởng Nhiệm Vụ (Quest Fanfare - Hợp âm Đô Trưởng hân hoan)
# 4. Tiếng Ăn Uống Hồi Sức (Consume Item - Âm thanh giòn tan)
# ==============================================================================

static func play_sound(parent: Node, sound_name: String, pos: Vector3 = Vector3.ZERO) -> void:
	if parent == null or not is_instance_valid(parent):
		return

	var tree = parent.get_tree()
	if tree == null:
		return

	var player: Node = null
	if pos != Vector3.ZERO:
		var p3d = AudioStreamPlayer3D.new()
		p3d.position = pos
		p3d.max_distance = 150.0
		p3d.unit_size = 12.0
		player = p3d
	else:
		player = AudioStreamPlayer.new()

	var generator = AudioStreamGenerator.new()
	generator.mix_rate = 22050.0
	generator.buffer_length = 0.8
	player.stream = generator
	parent.add_child(player)
	player.play()

	var playback = player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback:
		_fill_buffer_for_sound(playback, sound_name, generator.mix_rate)

	# Tự động hủy node sau khi phát xong
	var timer = tree.create_timer(1.2)
	timer.timeout.connect(func():
		if is_instance_valid(player):
			player.queue_free()
	)

static func _fill_buffer_for_sound(playback: AudioStreamGeneratorPlayback, sound_name: String, mix_rate: float) -> void:
	var total_frames = int(mix_rate * 0.6)
	var frames_to_push = mini(playback.get_frames_available(), total_frames)

	match sound_name:
		"bell":
			# Chuông ngân: Tần số cơ bản 440Hz (La) + 880Hz hòa âm, suy hao chậm
			var f1 = 440.0
			var f2 = 880.0
			for i in range(frames_to_push):
				var t = float(i) / mix_rate
				var decay = exp(-t * 4.5)
				var sample = (sin(TAU * f1 * t) * 0.6 + sin(TAU * f2 * t) * 0.4) * decay
				playback.push_frame(Vector2(sample, sample))

		"horn":
			# Còi xe: 2 nhịp Bíp Bíp (tần số 380Hz và 450Hz)
			var f1 = 380.0
			var f2 = 450.0
			for i in range(frames_to_push):
				var t = float(i) / mix_rate
				var gate = 1.0 if (t < 0.18 or (t > 0.25 and t < 0.43)) else 0.0
				var sample = (sin(TAU * f1 * t) * 0.5 + sin(TAU * f2 * t) * 0.5) * gate * 0.5
				playback.push_frame(Vector2(sample, sample))

		"fanfare":
			# Hợp âm Đô Trưởng thăng tiến: C5 (523Hz) -> E5 (659Hz) -> G5 (784Hz) -> C6 (1046Hz)
			for i in range(frames_to_push):
				var t = float(i) / mix_rate
				var f = 523.25
				if t > 0.12: f = 659.25
				if t > 0.24: f = 783.99
				if t > 0.36: f = 1046.50
				var decay = clampf(1.0 - (t - 0.36) * 2.0, 0.0, 1.0) if t > 0.36 else 0.8
				var sample = sin(TAU * f * t) * 0.45 * decay
				playback.push_frame(Vector2(sample, sample))

		"consume":
			# Âm thanh nhai/uống giòn tan (Pitch lướt nhanh 300 -> 600Hz)
			for i in range(frames_to_push):
				var t = float(i) / mix_rate
				var f = 300.0 + t * 900.0
				var decay = exp(-t * 8.0)
				var sample = sin(TAU * f * t) * 0.4 * decay
				playback.push_frame(Vector2(sample, sample))

		"elevator":
			# Chuông tầng thang máy kính (E6 1318Hz -> G#6 1661Hz ding-dong trong trẻo)
			var f1 = 1318.5
			var f2 = 1661.2
			for i in range(frames_to_push):
				var t = float(i) / mix_rate
				var f = f1 if t < 0.25 else f2
				var decay = exp(-(t - (0.0 if t < 0.25 else 0.25)) * 6.0)
				var sample = (sin(TAU * f * t) * 0.4 + sin(TAU * f * 2.0 * t) * 0.15) * decay
				playback.push_frame(Vector2(sample, sample))

		"briefcase_open":
			# Tiếng tách khoá vali kim loại (Double click cơ khí sắc sảo 1900Hz & 2400Hz)
			for i in range(frames_to_push):
				var t = float(i) / mix_rate
				var click1 = exp(-t * 90.0) * sin(TAU * 1900.0 * t) if t < 0.08 else 0.0
				var click2 = exp(-(t - 0.09) * 80.0) * sin(TAU * 2400.0 * (t - 0.09)) if (t >= 0.09 and t < 0.22) else 0.0
				var sample = (click1 + click2) * 0.45
				playback.push_frame(Vector2(sample, sample))

		"briefcase_close":
			# Tiếng đóng nắp da và sập khoá cặp (Thud trầm 160Hz + Click 1300Hz)
			for i in range(frames_to_push):
				var t = float(i) / mix_rate
				var thud = exp(-t * 30.0) * sin(TAU * 160.0 * t) * 0.5
				var click = exp(-(t - 0.05) * 70.0) * sin(TAU * 1300.0 * (t - 0.05)) * 0.35 if t >= 0.05 else 0.0
				var sample = (thud + click) * 0.5
				playback.push_frame(Vector2(sample, sample))

		"storage_transfer":
			# Tiếng cất/lấy đồ đĩnh đạc (Âm sắc hòa âm kim loại & gỗ 880Hz + 1320Hz)
			for i in range(frames_to_push):
				var t = float(i) / mix_rate
				var decay = exp(-t * 9.0)
				var sample = (sin(TAU * 880.0 * t) * 0.3 + sin(TAU * 1320.0 * t) * 0.2) * decay
				playback.push_frame(Vector2(sample, sample))

		"organ":
			# EXP-06: Đàn Đại Quản Cầm (Pipe Organ): Trầm bổng uy nghiêm (261.6Hz C4 + 523.2Hz C5 + 784.8Hz G5)
			var f1 = 261.63
			var f2 = 523.25
			var f3 = 783.99
			for i in range(frames_to_push):
				var t = float(i) / mix_rate
				var env = clampf(t * 15.0, 0.0, 1.0) * exp(-t * 1.5)
				var sample = (sin(TAU * f1 * t) * 0.45 + sin(TAU * f2 * t) * 0.35 + sin(TAU * f3 * t) * 0.20) * env
				playback.push_frame(Vector2(sample, sample))

		"piano":
			# EXP-06: Đại Dương Cầm (Grand Piano): Thanh tao, ngân vang trong sáng
			var f1 = 440.0
			var f2 = 880.0
			for i in range(frames_to_push):
				var t = float(i) / mix_rate
				var decay = exp(-t * 2.8)
				var sample = (sin(TAU * f1 * t) * 0.70 + sin(TAU * f2 * t) * 0.30) * decay * 0.6
				playback.push_frame(Vector2(sample, sample))

		_:
			for i in range(frames_to_push):
				playback.push_frame(Vector2.ZERO)

# Các hàm thực thể hỗ trợ gọi qua Autoload Singleton /root/AudioSynthesizer
func play_bell_sound(parent: Node = null) -> void:
	var target = parent if (parent and is_instance_valid(parent)) else self
	play_sound(target, "bell")

func play_horn_sound(parent: Node = null) -> void:
	var target = parent if (parent and is_instance_valid(parent)) else self
	play_sound(target, "horn")

func play_fanfare_sound(parent: Node = null) -> void:
	var target = parent if (parent and is_instance_valid(parent)) else self
	play_sound(target, "fanfare")

func play_consume_sound(parent: Node = null) -> void:
	var target = parent if (parent and is_instance_valid(parent)) else self
	play_sound(target, "consume")

func play_elevator_sound(parent: Node = null) -> void:
	var target = parent if (parent and is_instance_valid(parent)) else self
	play_sound(target, "elevator")

func play_briefcase_open_sound(parent: Node = null) -> void:
	var target = parent if (parent and is_instance_valid(parent)) else self
	play_sound(target, "briefcase_open")

func play_briefcase_close_sound(parent: Node = null) -> void:
	var target = parent if (parent and is_instance_valid(parent)) else self
	play_sound(target, "briefcase_close")

func play_storage_transfer_sound(parent: Node = null) -> void:
	var target = parent if (parent and is_instance_valid(parent)) else self
	play_sound(target, "storage_transfer")

## EXP-06: Phát tiến trình hòa âm đa bè cho Đàn Đại Quản Cầm / Grand Piano
static func play_polyphonic_progression(parent: Node, instrument: String = "organ", pos: Vector3 = Vector3.ZERO) -> void:
	play_sound(parent, instrument, pos)
	var tree = parent.get_tree() if (parent and is_instance_valid(parent)) else null
	if tree != null:
		var hud = tree.get_first_node_in_group("hud")
		if hud and hud.has_method("show_toast"):
			if instrument == "organ":
				hud.show_toast("🎹 [Đại Quản Cầm Tầng 11] Giai điệu Thánh Ca uy nghiêm vang vọng! (+15% Tinh Thần & Sáng Tạo)", 4.5)
			else:
				hud.show_toast("🎹 [Grand Piano Ban Ca Ngợi] Bản giao hưởng êm dịu sưởi ấm tâm hồn toàn đô thị! (+15% KBU)", 4.5)

func play_organ_sound(parent: Node = null) -> void:
	var target = parent if (parent and is_instance_valid(parent)) else self
	play_polyphonic_progression(target, "organ")

func play_piano_sound(parent: Node = null) -> void:
	var target = parent if (parent and is_instance_valid(parent)) else self
	play_polyphonic_progression(target, "piano")


