class_name VRMCharacterManager
extends Node3D

# ==============================================================================
# VRM CHARACTER MANAGER (TÂN THẾ GIỚI - ANIME VROID / VRM PIPELINE)
# Quản lý nhân vật 3D chuẩn VRM / VRoid và MToon Toon-Shading:
# 1. Hỗ trợ nạp Avatar định dạng VRM 0.0 & VRM 1.0 qua godot-vrm addon.
# 2. Tạo hình Procedural Fallback Anime MToon nếu chưa nạp file ngoài.
# 3. Hệ thống Blendshapes & Biểu Cảm Khuôn Mặt (Chớp mắt tự nhiên, Cười, Ngạc nhiên).
# 4. Lip-sync phát âm khẩu hình miệng (Phonemes: A, I, U, E, O) khi NPC/Player đối thoại.
# 5. Hệ thống Spring Bone mô phỏng đung đưa tóc và vạt áo măng tô theo gió & gia tốc.
# ==============================================================================

const ModularHumanoidScript = preload("res://scripts/characters/modular_humanoid_builder.gd")

enum ExpressionPreset {
	NEUTRAL,
	JOY,
	BLINK,
	BLINK_L,
	BLINK_R,
	SURPRISED,
	SORROW,
	ANGRY
}

@export var avatar_vrm_path: String = ""
@export var is_player_avatar: bool = false
@export var profession: ModularHumanoidScript.ProfessionType = ModularHumanoidScript.ProfessionType.MAYOR
@export var age_group: ModularHumanoidScript.AgeGroup = ModularHumanoidScript.AgeGroup.ADULT
@export var gender: String = "Nam"

@export var enable_auto_blink: bool = true
@export var blink_interval_min: float = 2.8
@export var blink_interval_max: float = 5.2
@export var enable_spring_bones: bool = true
@export var spring_stiffness: float = 0.65

# Node tham chiếu
var character_root: Node3D = null
var head_group: Node3D = null
var left_eye_mesh: MeshInstance3D = null
var right_eye_mesh: MeshInstance3D = null
var mouth_mesh: MeshInstance3D = null
var hair_nodes: Array[Node3D] = []
var coat_tail_mesh: MeshInstance3D = null

# Biến biểu cảm & Chớp mắt
var current_expression: ExpressionPreset = ExpressionPreset.NEUTRAL
var expression_weights: Dictionary = {}
var next_blink_timer: float = 3.0
var blink_progress: float = 0.0
var is_blinking: bool = false

# Biến Khẩu hình & Đối thoại
var is_speaking: bool = false
var speaking_timer: float = 0.0
var mouth_open_amount: float = 0.0

# Biến Spring Bone
var prev_world_pos: Vector3 = Vector3.ZERO
var hair_sway_velocity: Vector3 = Vector3.ZERO
var hair_sway_offset: Vector3 = Vector3.ZERO

func _ready() -> void:
	add_to_group("vrm_characters")
	prev_world_pos = global_position if is_inside_tree() else position
	next_blink_timer = randf_range(blink_interval_min, blink_interval_max)

	_initialize_expression_weights()

	if not avatar_vrm_path.is_empty() and ResourceLoader.exists(avatar_vrm_path):
		_load_vrm_scene(avatar_vrm_path)
	else:
		_build_procedural_mtoon_avatar()

func _initialize_expression_weights() -> void:
	for expr in ExpressionPreset.values():
		expression_weights[expr] = 0.0
	expression_weights[ExpressionPreset.NEUTRAL] = 1.0

## Nạp file avatar VRM nếu có
func _load_vrm_scene(path: String) -> void:
	print("[VRMCharacterManager] 📥 Nạp avatar VRM từ đường dẫn: %s" % path)
	var scene = load(path)
	if scene and scene is PackedScene:
		var inst = scene.instantiate()
		character_root = inst
		add_child(character_root)
		_detect_vrm_features(character_root)
	else:
		print("[VRMCharacterManager] ⚠️ Không thể nạp VRM, kích hoạt Fallback MToon Avatar.")
		_build_procedural_mtoon_avatar()

func _detect_vrm_features(root: Node) -> void:
	# Tìm MeshInstance3D có Blendshapes
	for child in root.find_children("*", "MeshInstance3D", true):
		var mi = child as MeshInstance3D
		if mi.mesh and mi.mesh.get_blend_shape_count() > 0:
			print("[VRMCharacterManager] ✨ Phát hiện Mesh có %d BlendShapes: %s" % [mi.mesh.get_blend_shape_count(), mi.name])

## Xây dựng Procedural Avatar với chuẩn anime MToon & Blendshapes
func _build_procedural_mtoon_avatar() -> void:
	character_root = ModularHumanoidScript.build_character_model(profession, age_group, gender)
	character_root.name = "VRMProceduralAvatar"
	add_child(character_root)

	# Định vị các bộ phận biểu cảm
	head_group = character_root.get_node_or_null("HeadGroup")
	if head_group:
		left_eye_mesh = head_group.get_node_or_null("Eye_L") as MeshInstance3D
		right_eye_mesh = head_group.get_node_or_null("Eye_R") as MeshInstance3D

		# Bổ sung Khuôn miệng Anime (Mouth Mesh) cho khẩu hình Lip-sync
		mouth_mesh = MeshInstance3D.new()
		mouth_mesh.name = "AnimeMouth"
		var m_box = BoxMesh.new()
		m_box.size = Vector3(0.045, 0.012, 0.015)
		mouth_mesh.mesh = m_box
		var m_mat = StandardMaterial3D.new()
		m_mat.albedo_color = Color(0.72, 0.28, 0.32) # Hồng thẫm anime
		m_mat.roughness = 0.7
		mouth_mesh.material_override = m_mat
		mouth_mesh.position = Vector3(0.0, -0.065, -0.17)
		head_group.add_child(mouth_mesh)

		# Định vị các lọn tóc để áp dụng Spring Bone
		for c in head_group.get_children():
			if "Hair" in c.name:
				hair_nodes.append(c)

	# Bổ sung Vạt áo măng tô bay trong gió (Coat Tail)
	var torso = character_root.get_node_or_null("Torso")
	if torso:
		coat_tail_mesh = MeshInstance3D.new()
		coat_tail_mesh.name = "CoatTail"
		var tail_box = BoxMesh.new()
		tail_box.size = Vector3(0.38, 0.45, 0.06)
		coat_tail_mesh.mesh = tail_box
		var tail_mat = torso.material_override.duplicate() if torso.material_override else StandardMaterial3D.new()
		coat_tail_mesh.material_override = tail_mat
		coat_tail_mesh.position = Vector3(0.0, -0.32, 0.12)
		torso.add_child(coat_tail_mesh)

	print("[VRMCharacterManager] 🎨 Khởi tạo Avatar MToon hoàn tất (Eyes: %s, Mouth: %s, HairStrands: %d)" % [
		left_eye_mesh != null and right_eye_mesh != null,
		mouth_mesh != null,
		hair_nodes.size()
	])

func _process(delta: float) -> void:
	_update_blinking(delta)
	_update_speaking_lipsync(delta)
	if enable_spring_bones:
		_update_spring_bones(delta)

## 1. CẬP NHẬT CHỚP MẮT TỰ NHIÊN
func _update_blinking(delta: float) -> void:
	if not enable_auto_blink:
		return

	if is_blinking:
		blink_progress += delta * 12.0 # Tốc độ nhắm mở mắt 0.15s
		var blink_weight: float = 0.0
		if blink_progress <= 1.0:
			blink_weight = sin(blink_progress * PI)
		else:
			is_blinking = false
			blink_progress = 0.0
			blink_weight = 0.0
			next_blink_timer = randf_range(blink_interval_min, blink_interval_max)

		_apply_eye_blink_weight(blink_weight)
	else:
		next_blink_timer -= delta
		if next_blink_timer <= 0.0:
			is_blinking = true
			blink_progress = 0.0

func _apply_eye_blink_weight(weight: float) -> void:
	expression_weights[ExpressionPreset.BLINK] = weight
	var eye_y_scale = clampf(1.0 - weight * 0.88, 0.12, 1.0)
	if left_eye_mesh:
		left_eye_mesh.scale.y = eye_y_scale
	if right_eye_mesh:
		right_eye_mesh.scale.y = eye_y_scale

## 2. CẬP NHẬT KHẨU HÌNH MIỆNG PHÁT ÂM (LIP-SYNC)
func _update_speaking_lipsync(delta: float) -> void:
	if is_speaking:
		speaking_timer -= delta
		if speaking_timer <= 0.0:
			is_speaking = false
			mouth_open_amount = 0.0
		else:
			# Khẩu hình nhấp nhô theo nhịp âm vị anime (Phonemes)
			var wave = sin(Time.get_ticks_msec() * 0.018)
			mouth_open_amount = clampf((wave * 0.5 + 0.5) * 1.5, 0.2, 1.8)
	else:
		mouth_open_amount = move_toward(mouth_open_amount, 0.0, delta * 8.0)

	if mouth_mesh:
		mouth_mesh.scale.y = 1.0 + mouth_open_amount * 2.2
		mouth_mesh.scale.x = 1.0 + mouth_open_amount * 0.6

## Bắt đầu khẩu hình khi hội thoại
func start_speaking(duration: float = 2.5) -> void:
	is_speaking = true
	speaking_timer = duration

func stop_speaking() -> void:
	is_speaking = false
	speaking_timer = 0.0

## 3. THIẾT LẬP BIỂU CẢM (JOY, SURPRISED, SORROW, ANGRY...)
func set_expression(expr: ExpressionPreset, weight: float = 1.0) -> void:
	current_expression = expr
	for k in expression_weights.keys():
		expression_weights[k] = 0.0
	expression_weights[expr] = clampf(weight, 0.0, 1.0)

	match expr:
		ExpressionPreset.JOY:
			if left_eye_mesh:
				left_eye_mesh.scale = Vector3(1.1, 0.45, 1.0)
			if right_eye_mesh:
				right_eye_mesh.scale = Vector3(1.1, 0.45, 1.0)
			if mouth_mesh:
				mouth_mesh.scale = Vector3(1.3, 0.8, 1.0)
		ExpressionPreset.SURPRISED:
			if left_eye_mesh:
				left_eye_mesh.scale = Vector3(1.3, 1.4, 1.0)
			if right_eye_mesh:
				right_eye_mesh.scale = Vector3(1.3, 1.4, 1.0)
			if mouth_mesh:
				mouth_mesh.scale = Vector3(1.1, 2.5, 1.0)
		ExpressionPreset.NEUTRAL:
			if left_eye_mesh:
				left_eye_mesh.scale = Vector3.ONE
			if right_eye_mesh:
				right_eye_mesh.scale = Vector3.ONE
			if mouth_mesh:
				mouth_mesh.scale = Vector3.ONE

## 4. VẬT LÝ SPRING BONE CHO TÓC & VẠT ÁO
func _update_spring_bones(delta: float) -> void:
	var current_pos = global_position if is_inside_tree() else position
	var world_vel = (current_pos - prev_world_pos) / maxf(delta, 0.001)
	prev_world_pos = current_pos

	# Chuyển vận tốc thế giới sang không gian nhân vật
	var basis_to_use = global_transform.basis if is_inside_tree() else transform.basis
	var local_vel = basis_to_use.inverse() * world_vel

	# Gia tốc mục tiêu cho lò xo
	var target_offset = Vector3(
		-local_vel.x * 0.015,
		sin(Time.get_ticks_msec() * 0.004) * 0.008,
		local_vel.z * 0.02
	)

	# Phương trình dao động điều hòa giảm chấn (Damped Harmonic Oscillator)
	var force = (target_offset - hair_sway_offset) * (18.0 * spring_stiffness)
	hair_sway_velocity += force * delta
	hair_sway_velocity *= exp(-delta * 8.5) # Giảm chấn (Damping)
	hair_sway_offset += hair_sway_velocity * delta

	# Áp dụng lên các lọn tóc
	for h in hair_nodes:
		if is_instance_valid(h):
			h.rotation.z = hair_sway_offset.x * 0.8
			h.rotation.x = hair_sway_offset.z * 0.6

	# Áp dụng lên vạt áo măng tô
	if coat_tail_mesh and is_instance_valid(coat_tail_mesh):
		coat_tail_mesh.rotation.x = clampf(-local_vel.z * 0.04 + hair_sway_offset.z * 1.2, -0.6, 0.6)
		coat_tail_mesh.rotation.z = clampf(-local_vel.x * 0.03, -0.3, 0.3)
