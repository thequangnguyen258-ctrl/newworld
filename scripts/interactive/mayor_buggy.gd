class_name MayorBuggy
extends CharacterBody3D

# ==============================================================================
# MAYOR'S ELECTRIC BUGGY - XE ĐỊA HÌNH ĐIỆN THỊ TRƯỞNG TÂN THẾ GIỚI
# Tuân thủ:
# 1. RULE: END_TO_END_INTERACTION_TESTING_STANDARD
# 2. RULE: INTERACTIVE_OBJECT_DUAL_LAYER_SAFETY (Layer 1|2|4, cự ly fallback <= 6.0m)
# 3. RULE: DIEGETIC_UI_PROMPT_VISIBILITY_STANDARD (Billboard, no_depth_test, outline)
# 4. RULE: VIETNAMESE_IME_INPUT_BULLETPROOFING (quét cả physical keycode & arrow keys)
# ==============================================================================

signal player_entered_buggy(player: Node3D)
signal player_exited_buggy(player: Node3D)

@export var max_speed: float = 16.67       # 60 km/h
@export var reverse_speed: float = 7.0     # 25 km/h
@export var acceleration: float = 12.0
@export var braking: float = 18.0
@export var steer_speed: float = 2.8

var is_occupied: bool = false
var passenger_ref: Node3D = null
var _saved_passenger_layer: int = 2
var _saved_passenger_mask: int = 1
var current_speed: float = 0.0
var steer_angle: float = 0.0
@export var mechanical_wear: float = 0.0 # Tỷ lệ hao mòn máy móc (0.0% -> 100.0%)
@export var wear_rate_per_sec: float = 0.005 # Hao mòn cơ bản khi chạy ở vận tốc tối đa

var spring_arm: SpringArm3D
var chase_camera: Camera3D
var prompt_3d: Label3D
var interaction_area: Area3D
var wheels: Array[Node3D] = []
var headlights: Array[SpotLight3D] = []

func _ready() -> void:
	add_to_group("vehicles")
	add_to_group("buggies")

	collision_layer = 1 | 2
	collision_mask = 1

	floor_snap_length = 0.5
	floor_max_angle = deg_to_rad(60.0)
	floor_stop_on_slope = true

	_build_buggy_visuals()
	_setup_camera_rig()
	_setup_interaction_area()
	_setup_prompt_3d()

	print("[MayorBuggy] 🚗 Khởi tạo thành công Xe Buggy Điện Thị Trưởng tại %s" % global_position)

func _build_buggy_visuals() -> void:
	# Khung xe xanh hoàng gia phối vàng kim
	var mat_body = StandardMaterial3D.new()
	mat_body.albedo_color = Color(0.12, 0.35, 0.75) # Xanh hoàng gia
	mat_body.metallic = 0.3
	mat_body.roughness = 0.4
	mat_body.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON

	var mat_gold = StandardMaterial3D.new()
	mat_gold.albedo_color = Color(0.96, 0.78, 0.18)
	mat_gold.metallic = 0.8
	mat_gold.roughness = 0.2

	var mat_frame = StandardMaterial3D.new()
	mat_frame.albedo_color = Color(0.2, 0.22, 0.26) # Khung kim loại sẫm

	var mat_tire = StandardMaterial3D.new()
	mat_tire.albedo_color = Color(0.12, 0.12, 0.14)
	mat_tire.roughness = 0.9

	var mat_light = StandardMaterial3D.new()
	mat_light.albedo_color = Color(1.0, 0.95, 0.8)
	mat_light.emission_enabled = true
	mat_light.emission = Color(1.0, 0.95, 0.7)
	mat_light.emission_energy_multiplier = 3.0

	# 1. Thân xe chính (Chassis)
	var chassis = MeshInstance3D.new()
	var c_box = BoxMesh.new()
	c_box.size = Vector3(1.8, 0.6, 3.2)
	chassis.mesh = c_box
	chassis.material_override = mat_body
	chassis.position.y = 0.65
	add_child(chassis)

	# Nắp ca-pô viền vàng
	var hood = MeshInstance3D.new()
	var h_box = BoxMesh.new()
	h_box.size = Vector3(1.6, 0.3, 1.2)
	hood.mesh = h_box
	hood.material_override = mat_gold
	hood.position = Vector3(0.0, 0.95, -0.9)
	add_child(hood)

	# 2. Khung chống lật (Roll Cage)
	var cage_mesh = BoxMesh.new()
	cage_mesh.size = Vector3(1.7, 1.3, 1.8)
	var cage = MeshInstance3D.new()
	cage.mesh = cage_mesh
	cage.material_override = mat_frame
	cage.position = Vector3(0.0, 1.6, 0.3)
	add_child(cage)

	# 3. 2 Ghế ngồi da nâu
	var mat_leather = StandardMaterial3D.new()
	mat_leather.albedo_color = Color(0.55, 0.32, 0.18)
	for i in [-0.4, 0.4]:
		var seat = MeshInstance3D.new()
		var s_box = BoxMesh.new()
		s_box.size = Vector3(0.65, 0.8, 0.65)
		seat.mesh = s_box
		seat.material_override = mat_leather
		seat.position = Vector3(i, 1.15, 0.1)
		add_child(seat)

	# 4. 4 Bánh xe địa hình to bản
	var wheel_positions = [
		Vector3(-1.0, 0.45, -1.1), # Trước trái
		Vector3(1.0, 0.45, -1.1),  # Trước phải
		Vector3(-1.0, 0.45, 1.1),  # Sau trái
		Vector3(1.0, 0.45, 1.1)    # Sau phải
	]

	for wpos in wheel_positions:
		var wheel_pivot = Node3D.new()
		wheel_pivot.position = wpos
		add_child(wheel_pivot)

		var tire = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = 0.45
		cyl.bottom_radius = 0.45
		cyl.height = 0.35
		tire.mesh = cyl
		tire.material_override = mat_tire
		tire.rotation.z = deg_to_rad(90.0)
		wheel_pivot.add_child(tire)
		wheels.append(wheel_pivot)

	# 5. Đèn pha LED trước
	for lx in [-0.65, 0.65]:
		var lamp = MeshInstance3D.new()
		var l_box = BoxMesh.new()
		l_box.size = Vector3(0.3, 0.2, 0.1)
		lamp.mesh = l_box
		lamp.material_override = mat_light
		lamp.position = Vector3(lx, 0.8, -1.62)
		add_child(lamp)

		var light = SpotLight3D.new()
		light.light_color = Color(1.0, 0.95, 0.85)
		light.light_energy = 2.5
		light.spot_range = 35.0
		light.spot_angle = 35.0
		light.position = Vector3(lx, 0.8, -1.7)
		light.rotation.y = deg_to_rad(180.0)
		add_child(light)
		headlights.append(light)

	# Va chạm vật lý
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(2.0, 1.8, 3.4)
	col.shape = shape
	col.position.y = 1.1
	add_child(col)

func _setup_camera_rig() -> void:
	spring_arm = SpringArm3D.new()
	spring_arm.name = "BuggySpringArm"
	spring_arm.spring_length = 5.5
	spring_arm.position = Vector3(0, 1.8, 0)
	add_child(spring_arm)

	chase_camera = Camera3D.new()
	chase_camera.name = "BuggyCamera"
	chase_camera.far = 35000.0
	chase_camera.current = false
	spring_arm.add_child(chase_camera)

func _setup_interaction_area() -> void:
	interaction_area = Area3D.new()
	interaction_area.name = "InteractionArea"
	interaction_area.collision_layer = 1 | 2 | 4
	interaction_area.collision_mask = 1 | 2 | 4

	var shape = CollisionShape3D.new()
	var sph = SphereShape3D.new()
	sph.radius = 6.0
	shape.shape = sph
	interaction_area.add_child(shape)
	add_child(interaction_area)

	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)

func _setup_prompt_3d() -> void:
	prompt_3d = Label3D.new()
	prompt_3d.name = "BuggyPrompt3D"
	prompt_3d.text = "🚗 [F] hoặc [E] Lái Xe Buggy Điện Tuần Tra (60 km/h)"
	prompt_3d.font_size = 32
	prompt_3d.outline_size = 8
	prompt_3d.outline_modulate = Color(0.05, 0.08, 0.14, 0.95)
	prompt_3d.modulate = Color(1.0, 0.85, 0.2)
	prompt_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	prompt_3d.no_depth_test = true
	prompt_3d.position = Vector3(0.0, 2.6, 0.0)
	prompt_3d.visible = false
	add_child(prompt_3d)

func _process(delta: float) -> void:
	if not is_occupied:
		var player = get_tree().get_first_node_in_group("player")
		if player and is_instance_valid(player):
			var dist = global_position.distance_to(player.global_position)
			var in_range = (dist <= 6.0)
			if prompt_3d.visible != in_range:
				prompt_3d.visible = in_range
				if in_range:
					player.set_meta("nearby_buggy", self)
				else:
					if player.has_meta("nearby_buggy") and player.get_meta("nearby_buggy") == self:
						player.remove_meta("nearby_buggy")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 15.0 * delta

	if is_occupied:
		_handle_driving_input(delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, braking * delta)
		velocity.z = move_toward(velocity.z, 0.0, braking * delta)

	move_and_slide()

func _handle_driving_input(delta: float) -> void:
	var forward_input: float = 0.0
	var steer_input: float = 0.0

	# Hỗ trợ cả WASD, mũi tên, và physical keys (Vietnamese IME Bulletproof)
	if Input.is_action_pressed("move_forward") or Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		forward_input += 1.0
	if Input.is_action_pressed("move_backward") or Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		forward_input -= 1.0
	if Input.is_action_pressed("move_left") or Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		steer_input += 1.0
	if Input.is_action_pressed("move_right") or Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		steer_input -= 1.0

	# Lái xe
	if steer_input != 0.0 and abs(current_speed) > 0.5:
		rotate_y(steer_input * steer_speed * delta * sign(current_speed))

	# Tăng tốc / Phanh
	var target_speed = forward_input * (max_speed if forward_input > 0 else reverse_speed)
	current_speed = move_toward(current_speed, target_speed, acceleration * delta if forward_input != 0 else braking * delta)

	var fwd_dir = -global_transform.basis.z.normalized()
	velocity.x = fwd_dir.x * current_speed
	velocity.z = fwd_dir.z * current_speed

	# Quay bánh xe
	if wheels.size() >= 4:
		# Bánh trước bẻ lái
		wheels[0].rotation.y = steer_input * 0.4
		wheels[1].rotation.y = steer_input * 0.4
		for w in wheels:
			w.rotate_x(current_speed * delta * 2.5)

	# Hao mòn máy móc vận hành - chịu ảnh hưởng trực tiếp từ Công nghệ Vật liệu Mới HAS (giảm tối đa -21%)
	apply_driving_wear(current_speed, delta)

## Tính toán hao mòn máy móc theo vận tốc và công nghệ vật liệu HAS
func apply_driving_wear(speed: float, delta: float) -> void:
	if abs(speed) > 0.1:
		var wear_reduction: float = 0.0
		var research_mgr = null
		if is_inside_tree() and has_node("/root/ResearchManager"):
			research_mgr = get_node("/root/ResearchManager")
		if research_mgr != null and research_mgr.has_method("get_wear_and_tear_reduction"):
			wear_reduction = research_mgr.get_wear_and_tear_reduction()
		elif is_inside_tree() and has_node("/root/BuildingJobRegistry"):
			var bjr = get_node("/root/BuildingJobRegistry")
			if "tech_wear_reduction_ratio" in bjr:
				wear_reduction = bjr.tech_wear_reduction_ratio

		var effective_wear_rate: float = wear_rate_per_sec * (1.0 - wear_reduction)
		mechanical_wear = minf(1.0, mechanical_wear + effective_wear_rate * delta * (abs(speed) / max_speed))

func _input(event: InputEvent) -> void:
	if not is_occupied:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F or event.physical_keycode == KEY_F or event.keycode == KEY_E or event.physical_keycode == KEY_E:
			exit_buggy()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_H or event.physical_keycode == KEY_H:
			# Còi xe vui nhộn
			var hud = get_tree().get_first_node_in_group("hud")
			if hud and hud.has_method("show_toast"):
				hud.show_toast("📢 *BÍP BÍP!* Thị trưởng đang tuần tra bằng xe Buggy điện!")
			get_viewport().set_input_as_handled()

func board(player: Node3D) -> void:
	if is_occupied:
		return

	is_occupied = true
	passenger_ref = player
	prompt_3d.visible = false

	if player.has_meta("nearby_buggy"):
		player.remove_meta("nearby_buggy")

	if player is CollisionObject3D:
		_saved_passenger_layer = player.collision_layer
		_saved_passenger_mask = player.collision_mask
		player.collision_layer = 0
		player.collision_mask = 0

	if "visible" in player:
		player.visible = false
	if player.has_method("set_physics_process"):
		player.set_physics_process(false)

	chase_camera.current = true

	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_toast"):
		hud.show_toast("🚗 Đã lên Xe Buggy Điện! [W/S] Ga/Phanh | [A/D] Lái | [H] Còi | [F/E] Xuống xe")
	if hud and hud.has_method("mark_quest_done"):
		hud.mark_quest_done("quest_buggy")

	player_entered_buggy.emit(player)
	print("[MayorBuggy] 🚗 Thị Trưởng đã lên Xe Buggy Điện!")

func exit_buggy() -> void:
	if not is_occupied or passenger_ref == null:
		return

	is_occupied = false
	current_speed = 0.0

	var exit_pos = global_position + global_transform.basis.x * 2.2 + Vector3(0, 0.5, 0)
	passenger_ref.global_position = exit_pos

	if passenger_ref is CollisionObject3D:
		passenger_ref.collision_layer = _saved_passenger_layer if _saved_passenger_layer != 0 else 2
		passenger_ref.collision_mask = _saved_passenger_mask if _saved_passenger_mask != 0 else 1

	if "visible" in passenger_ref:
		passenger_ref.visible = true
	if passenger_ref.has_method("set_physics_process"):
		passenger_ref.set_physics_process(true)

	if passenger_ref.has_node("Head/SpringArm3D/Camera3D"):
		var p_cam = passenger_ref.get_node("Head/SpringArm3D/Camera3D") as Camera3D
		if p_cam:
			p_cam.current = true
	elif passenger_ref.has_node("Head/Camera3D"):
		var p_cam = passenger_ref.get_node("Head/Camera3D") as Camera3D
		if p_cam:
			p_cam.current = true

	chase_camera.current = false

	var p = passenger_ref
	passenger_ref = null
	player_exited_buggy.emit(p)
	print("[MayorBuggy] 🚗 Thị Trưởng đã rời Xe Buggy an toàn tại %s" % exit_pos)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and not is_occupied:
		prompt_3d.visible = true
		body.set_meta("nearby_buggy", self)

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		prompt_3d.visible = false
		if body.has_meta("nearby_buggy") and body.get_meta("nearby_buggy") == self:
			body.remove_meta("nearby_buggy")

## Truy vấn mức độ hao mòn cơ khí (0.0% -> 100.0%)
func get_mechanical_wear() -> float:
	return mechanical_wear

## Bảo dưỡng phục hồi nguyên trạng 100%
func repair_vehicle() -> void:
	mechanical_wear = 0.0

