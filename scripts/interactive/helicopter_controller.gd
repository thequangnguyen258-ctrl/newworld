class_name HelicopterController
extends CharacterBody3D

# ==============================================================================
# HELICOPTER CONTROLLER - TRỰC THĂNG CAO TỐC THỊ TRƯỞNG TÂN THẾ GIỚI
# Tốc độ thông thường: 40.0 m/s (~144 km/h)
# Tốc độ Siêu Tốc Turbo: 194.44 m/s (700 km/h) - Phím [Shift]
# Bay lên: [Space] (18 m/s) | Hạ xuống: [Ctrl] hoặc [C] (14 m/s)
# Lên / Xuống trực thăng: Phím [F]
# Chống kẹt phím 100% tiếng Việt: Quét cả physical keycodes và arrow keys.
# ==============================================================================

signal player_entered_helicopter(player: Node3D)
signal player_exited_helicopter(player: Node3D)

@export var cruise_speed: float = 40.0         # 144 km/h
@export var turbo_speed: float = 700.0 / 3.6    # 700 km/h
@export var reverse_speed: float = 18.0        # 65 km/h
@export var vertical_climb_speed: float = 18.0 # Bay lên
@export var vertical_descend_speed: float = 14.0 # Hạ cánh
@export var yaw_turn_speed: float = 2.4        # Tốc độ quay đầu (rad/s)
@export var max_bank_angle: float = deg_to_rad(24.0)   # Nghiêng khi rẽ
@export var max_pitch_angle: float = deg_to_rad(20.0)  # Cúi đầu khi tăng tốc
@export var max_flight_altitude: float = 1600.0        # Trần bay tối đa (+1600m)

# Trạng thái phi hành
enum HeliState { PARKED, STARTING, FLYING, LANDING }
var current_state: HeliState = HeliState.PARKED

var is_occupied: bool = false
var is_turbo_active: bool = false
var passenger_ref: Node3D = null

# Vận tốc mục tiêu & mô phỏng khí động học
var current_forward_speed: float = 0.0
var current_yaw_rate: float = 0.0
var current_vertical_velocity: float = 0.0
var current_pitch: float = 0.0
var current_roll: float = 0.0

# Vận tốc góc cánh quạt
var main_rotor_rpm: float = 0.0
var target_rotor_rpm: float = 0.0
var tail_rotor_rpm: float = 0.0

# Node references
var visual_data: Dictionary
var visual_root: Node3D
var fuselage_node: Node3D
var main_rotor_pivot: Node3D
var tail_rotor_pivot: Node3D
var turbo_nozzles: Array[MeshInstance3D] = []
var turbo_lights: Array[OmniLight3D] = []

var _saved_pilot_layer: int = 2
var _saved_pilot_mask: int = 1
@export var mechanical_wear: float = 0.0
@export var wear_rate_per_sec: float = 0.004

func apply_flying_wear(speed: float, delta: float) -> void:
	if abs(speed) <= 1.0:
		return
	var wear_factor: float = clampf(abs(speed) / max_speed, 0.2, 1.5)
	var reduction: float = 0.0
	if is_inside_tree():
		var rm = get_node_or_null("/root/ResearchManager")
		if rm != null and rm.has_method("get_wear_and_tear_reduction"):
			reduction = rm.get_wear_and_tear_reduction()
	mechanical_wear = minf(1.0, mechanical_wear + wear_rate_per_sec * wear_factor * (1.0 - reduction) * delta)

var spring_arm: SpringArm3D
var chase_camera: Camera3D
var interaction_area: Area3D
var hud_layer: CanvasLayer

# UI Labels
var hud_container: Control
var speed_label: Label
var alt_label: Label
var heading_label: Label
var turbo_badge: Label
var prompt_3d: Label3D

func _ready() -> void:
	add_to_group("vehicles")
	add_to_group("helicopters")

	# Thiết lập va chạm
	collision_layer = 1 | 2
	collision_mask = 1

	# 1. Tạo hình 3D Stylized từ HelicopterModelBuilder
	visual_data = HelicopterModelBuilder.build_helicopter()
	visual_root = visual_data["root"]
	fuselage_node = visual_data["fuselage"]
	main_rotor_pivot = visual_data["main_rotor"]
	tail_rotor_pivot = visual_data["tail_rotor"]
	turbo_nozzles = visual_data["turbo_nozzles"]
	turbo_lights = visual_data["turbo_lights"]
	add_child(visual_root)

	# 2. Tạo Collision Shape cho trực thăng
	var col_shape = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(2.4, 2.6, 5.0)
	col_shape.shape = box
	col_shape.position = Vector3(0, 1.3, 0.4)
	add_child(col_shape)

	# 3. Tạo Camera đuổi (Third-Person Chase Camera)
	spring_arm = SpringArm3D.new()
	spring_arm.name = "HeliSpringArm"
	spring_arm.spring_length = 9.5
	spring_arm.margin = 0.5
	spring_arm.collision_mask = 1
	spring_arm.position = Vector3(0, 2.5, 0)

	chase_camera = Camera3D.new()
	chase_camera.name = "HeliChaseCamera"
	chase_camera.far = 35000.0 # Tầm nhìn xa bao quát 500 km²
	chase_camera.fov = 75.0
	chase_camera.current = false
	spring_arm.add_child(chase_camera)
	add_child(spring_arm)

	# 4. Vùng tương tác lên xe [Area3D]
	interaction_area = Area3D.new()
	interaction_area.name = "InteractionArea"
	interaction_area.collision_layer = 1 | 2 | 4
	interaction_area.collision_mask = 1 | 2 | 4
	var area_col = CollisionShape3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = 7.0
	area_col.shape = sphere
	area_col.position = Vector3(0, 1.0, 0)
	interaction_area.add_child(area_col)
	interaction_area.body_entered.connect(_on_interaction_area_body_entered)
	interaction_area.body_exited.connect(_on_interaction_area_body_exited)
	add_child(interaction_area)

	# 5. Bảng chữ 3D nhắc tương tác khi đi bộ lại gần
	prompt_3d = Label3D.new()
	prompt_3d.text = "🚁 [F] hoặc [E]: Lên Trực Thăng Cao Tốc Thị Trưởng"
	prompt_3d.font_size = 36
	prompt_3d.outline_size = 10
	prompt_3d.outline_modulate = Color(0.05, 0.05, 0.1, 0.95)
	prompt_3d.modulate = Color(1.0, 0.9, 0.2)
	prompt_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	prompt_3d.no_depth_test = true
	prompt_3d.position = Vector3(0, 3.2, 0)
	prompt_3d.visible = false
	add_child(prompt_3d)

	# 6. Bảng điều khiển HUD phi hành trực thăng
	_setup_flight_hud()

	# Khởi tạo độ cao ban đầu bám đất
	var cur_pos = global_position if is_inside_tree() else position
	var ground_h = ModularNatureChunk.get_world_height(cur_pos.x, cur_pos.z)
	if cur_pos.y < ground_h + 0.1:
		cur_pos.y = ground_h + 0.1
		if is_inside_tree():
			global_position = cur_pos
		else:
			position = cur_pos

	print("[Helicopter] 🚁 Khởi tạo thành công: Trực thăng cao tốc Thị Trưởng tại %s" % cur_pos)

func _setup_flight_hud() -> void:
	hud_layer = CanvasLayer.new()
	hud_layer.name = "HelicopterFlightHUD"
	hud_layer.layer = 20
	hud_layer.visible = false
	add_child(hud_layer)

	hud_container = Control.new()
	hud_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_layer.add_child(hud_container)

	# Khung bảng đồng hồ phi hành trên đỉnh màn hình
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	panel.offset_top = 18.0
	panel.offset_left = -340.0
	panel.offset_right = 340.0
	panel.offset_bottom = 120.0
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.06, 0.10, 0.20, 0.88)
	panel_style.corner_radius_bottom_left = 12
	panel_style.corner_radius_bottom_right = 12
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.25, 0.65, 0.95, 0.7)
	panel.add_theme_stylebox_override("panel", panel_style)
	hud_container.add_child(panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	# Tiêu đề
	var title = Label.new()
	title.text = "🚁 PHI THUYỀN TRỰC THĂNG THỊ TRƯỞNG - TÂN THẾ GIỚI"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color(0.95, 0.82, 0.25))
	vbox.add_child(title)

	var hbox_stats = HBoxContainer.new()
	hbox_stats.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_stats.add_theme_constant_override("separation", 24)
	vbox.add_child(hbox_stats)

	speed_label = Label.new()
	speed_label.text = "⚡ TỐC ĐỘ: 0 km/h"
	speed_label.add_theme_font_size_override("font_size", 14)
	speed_label.add_theme_color_override("font_color", Color(0.3, 0.9, 1.0))
	hbox_stats.add_child(speed_label)

	alt_label = Label.new()
	alt_label.text = "⛰️ CAO ĐỘ: +600m"
	alt_label.add_theme_font_size_override("font_size", 14)
	alt_label.add_theme_color_override("font_color", Color(0.8, 1.0, 0.4))
	hbox_stats.add_child(alt_label)

	heading_label = Label.new()
	heading_label.text = "🧭 HƯỚNG: BẮC 000°"
	heading_label.add_theme_font_size_override("font_size", 14)
	heading_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	hbox_stats.add_child(heading_label)

	turbo_badge = Label.new()
	turbo_badge.text = "🔥 TURBO BOOST READY"
	turbo_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turbo_badge.add_theme_font_size_override("font_size", 12)
	turbo_badge.add_theme_color_override("font_color", Color(0.4, 0.7, 1.0))
	vbox.add_child(turbo_badge)

	# Bảng phím tắt điều khiển ở đáy màn hình
	var guide_panel = PanelContainer.new()
	guide_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	guide_panel.offset_bottom = -20.0
	guide_panel.offset_left = -460.0
	guide_panel.offset_right = 460.0
	guide_panel.offset_top = -68.0
	guide_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var guide_style = StyleBoxFlat.new()
	guide_style.bg_color = Color(0.04, 0.08, 0.16, 0.82)
	guide_style.corner_radius_top_left = 10
	guide_style.corner_radius_top_right = 10
	guide_style.corner_radius_bottom_left = 10
	guide_style.corner_radius_bottom_right = 10
	guide_panel.add_theme_stylebox_override("panel", guide_style)
	hud_container.add_child(guide_panel)

	var guide_label = Label.new()
	guide_label.text = "🎮 ĐIỀU KHIỂN: [W / ↑] Tiến | [S / ↓] Phanh/Lùi | [A / D / ← / →] Rẽ Trái/Phải\n[Space] Bay Lên | [Ctrl / C] Hạ Xuống | [Shift] Siêu Tốc Turbo 700 km/h | [F] Xuống Trực Thăng"
	guide_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	guide_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	guide_label.add_theme_font_size_override("font_size", 13)
	guide_label.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
	guide_panel.add_child(guide_label)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var is_f = (event.keycode == KEY_F or event.physical_keycode == KEY_F)
		var is_e = (event.keycode == KEY_E or event.physical_keycode == KEY_E)
		if is_f or is_e:
			if is_occupied:
				exit_helicopter()
				get_viewport().set_input_as_handled()
			else:
				var player = get_tree().get_first_node_in_group("player") if is_inside_tree() else null
				if player and is_instance_valid(player):
					var dist = global_position.distance_to(player.global_position)
					if dist <= 7.5:
						board(player)
						get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	# 1. Quay cánh quạt mượt mà
	main_rotor_rpm = lerpf(main_rotor_rpm, target_rotor_rpm, delta * 3.5)
	tail_rotor_rpm = lerpf(tail_rotor_rpm, target_rotor_rpm * 2.8, delta * 4.0)

	if main_rotor_pivot:
		main_rotor_pivot.rotate_y(main_rotor_rpm * delta)
	if tail_rotor_pivot:
		tail_rotor_pivot.rotate_x(tail_rotor_rpm * delta)

	# 2. Hiệu ứng phụt lửa Turbo
	var target_turbo_energy = 3.2 if is_turbo_active else 0.6
	for t_light in turbo_lights:
		if t_light:
			t_light.light_energy = lerpf(t_light.light_energy, target_turbo_energy, delta * 8.0)

	# 3. Cập nhật Bảng HUD khi đang lái
	if is_occupied and hud_layer and hud_layer.visible:
		var speed_val = velocity.length()
		var speed_kmh = speed_val * 3.6
		speed_label.text = "⚡ TỐC ĐỘ: %.1f km/h (%.1f m/s)" % [speed_kmh, speed_val]
		
		var ground_h = ModularNatureChunk.get_world_height(global_position.x, global_position.z)
		var height_above_ground = maxf(0.0, global_position.y - ground_h)
		alt_label.text = "⛰️ CAO ĐỘ: +%.0fm (Cách đất: %.0fm)" % [global_position.y, height_above_ground]

		var compass_deg = wrapf(rad_to_deg(-rotation.y), 0.0, 360.0)
		var heading_str = _get_compass_heading(compass_deg)
		heading_label.text = "🧭 HƯỚNG: %s %03d°" % [heading_str, int(compass_deg)]

		if is_turbo_active:
			turbo_badge.text = "🔥 TURBO BOOST ĐANG KÍCH HOẠT (700 KM/H)!"
			turbo_badge.add_theme_color_override("font_color", Color(1.0, 0.4, 0.1))
		else:
			turbo_badge.text = "💡 GIỮ [SHIFT] ĐỂ BẬT SIÊU TỐC TURBO (700 KM/H)"
			turbo_badge.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0))
	elif not is_occupied and is_inside_tree():
		# 4. Khi chưa có người lái: quét cự ly Player để luôn hiện chữ nhắc nhở và kích hoạt tương tác
		var player = get_tree().get_first_node_in_group("player")
		if player and is_instance_valid(player):
			var dist = global_position.distance_to(player.global_position)
			if dist <= 7.0:
				player.set_meta("nearby_helicopter", self)
				if prompt_3d and not prompt_3d.visible:
					prompt_3d.visible = true
			else:
				if player.has_meta("nearby_helicopter") and player.get_meta("nearby_helicopter") == self:
					player.remove_meta("nearby_helicopter")
				if prompt_3d and prompt_3d.visible:
					prompt_3d.visible = false

func _physics_process(delta: float) -> void:
	if is_occupied:
		_process_flying_physics(delta)
	else:
		_process_parked_physics(delta)

func _process_flying_physics(delta: float) -> void:
	target_rotor_rpm = 28.0 # Cánh quạt quay hết công suất

	# 1. Quét phím điều khiển (Bulletproof IME Tiếng Việt)
	var fwd_input: float = 0.0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_UP):
		fwd_input += 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_DOWN):
		fwd_input -= 1.0

	var turn_input: float = 0.0
	if Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_LEFT):
		turn_input += 1.0 # Quay trái
	if Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_RIGHT):
		turn_input -= 1.0 # Quay phải

	var vert_input: float = 0.0
	if Input.is_physical_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_SPACE):
		vert_input += 1.0 # Bay lên
	if Input.is_physical_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_CTRL) or Input.is_physical_key_pressed(KEY_C) or Input.is_key_pressed(KEY_C):
		vert_input -= 1.0 # Hạ xuống

	# Phím Turbo Boost [Shift]
	is_turbo_active = (Input.is_physical_key_pressed(KEY_SHIFT) or Input.is_key_pressed(KEY_SHIFT)) and fwd_input > 0.0
	var current_max_speed = turbo_speed if is_turbo_active else cruise_speed

	# 2. Xử lý quay đầu (Yaw) & Nghiêng lượn (Banking Roll)
	current_yaw_rate = lerpf(current_yaw_rate, turn_input * yaw_turn_speed, delta * 5.0)
	rotate_y(current_yaw_rate * delta)

	var target_roll = -turn_input * max_bank_angle * (1.2 if is_turbo_active else 1.0)
	current_roll = lerpf(current_roll, target_roll, delta * 6.0)

	# 3. Xử lý chúi mũi khi bay tới / Ngửa mũi khi phanh (Pitch)
	var target_pitch = -fwd_input * max_pitch_angle * (1.3 if is_turbo_active else 1.0)
	current_pitch = lerpf(current_pitch, target_pitch, delta * 5.0)

	# Áp dụng góc nghiêng và chúi vào khung thân (Fuselage)
	if fuselage_node:
		fuselage_node.rotation.z = current_roll
		fuselage_node.rotation.x = current_pitch

	# 4. Tính toán vận tốc tịnh tiến
	var target_fwd_spd: float = 0.0
	if fwd_input > 0:
		target_fwd_spd = current_max_speed
	elif fwd_input < 0:
		target_fwd_spd = -reverse_speed

	var accel_factor = 4.0 if is_turbo_active else 3.0
	current_forward_speed = lerpf(current_forward_speed, target_fwd_spd, delta * accel_factor)

	# Hướng bay theo trục xoay Y của trực thăng (-basis.z là phía trước)
	var forward_dir = -transform.basis.z.normalized()
	velocity.x = forward_dir.x * current_forward_speed
	velocity.z = forward_dir.z * current_forward_speed

	# 5. Vận tốc nâng thẳng đứng (Vertical Lift)
	var target_vert_spd: float = 0.0
	if vert_input > 0:
		target_vert_spd = vertical_climb_speed
	elif vert_input < 0:
		target_vert_spd = -vertical_descend_speed
	else:
		# Giữ độ cao tự động (Auto-Hover) kèm nhấp nhô nhẹ theo gió
		target_vert_spd = sin(Time.get_ticks_msec() * 0.003) * 0.25

	current_vertical_velocity = lerpf(current_vertical_velocity, target_vert_spd, delta * 4.0)
	velocity.y = current_vertical_velocity
	velocity = velocity.limit_length(turbo_speed)

	# 6. Giới hạn độ cao và Chống chìm xuống lòng đất
	var ground_h = ModularNatureChunk.get_world_height(global_position.x, global_position.z)
	var min_h = ground_h + 0.15 # Bám chân càng đáp trên mặt đất

	if global_position.y + velocity.y * delta < min_h:
		global_position.y = min_h
		velocity.y = 0.0
		# Nếu đang ở sát đất và không có ga tới, cho tiếp đất êm dịu
		if abs(current_forward_speed) < 2.0 and vert_input <= 0.0:
			current_forward_speed = 0.0

	if global_position.y > max_flight_altitude:
		global_position.y = max_flight_altitude
		if velocity.y > 0.0:
			velocity.y = 0.0

	move_and_slide()
	apply_flying_wear(current_forward_speed, delta)

func _process_parked_physics(delta: float) -> void:
	target_rotor_rpm = 0.0 # Tắt máy khi không có người lái
	is_turbo_active = false
	current_forward_speed = 0.0
	current_vertical_velocity = 0.0

	# Đặt thân thăng bằng phẳng
	if fuselage_node:
		fuselage_node.rotation.x = lerpf(fuselage_node.rotation.x, 0.0, delta * 4.0)
		fuselage_node.rotation.z = lerpf(fuselage_node.rotation.z, 0.0, delta * 4.0)

	# Bám chặt mặt đất
	var ground_h = ModularNatureChunk.get_world_height(global_position.x, global_position.z)
	if global_position.y > ground_h + 0.15:
		velocity.y -= 9.8 * delta
		move_and_slide()
	apply_flying_wear(current_forward_speed, delta)
	else:
		global_position.y = ground_h + 0.15
		velocity = Vector3.ZERO

func board(player: Node3D) -> void:
	if is_occupied:
		return

	is_occupied = true
	passenger_ref = player

	# Ẩn và khóa tạm thời nhân vật người chơi
	player.visible = false
	player.set_physics_process(false)
	player.set_process_unhandled_input(false)
	if player is CollisionObject3D:
		_saved_pilot_layer = player.collision_layer
		_saved_pilot_mask = player.collision_mask
		player.collision_layer = 0
		player.collision_mask = 0

	# Kích hoạt camera trực thăng
	if chase_camera:
		chase_camera.current = true

	# Bật HUD phi hành
	if hud_layer:
		hud_layer.visible = true
	if prompt_3d:
		prompt_3d.visible = false

	# Nhả khóa chuột để thuận tiện quan sát nếu cần
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	emit_signal("player_entered_helicopter", player)
	print("[Helicopter] 🚁 Thị Trưởng đã lên trực thăng! Bắt đầu phi hành cao tốc.")

func exit_helicopter() -> void:
	if not is_occupied or passenger_ref == null:
		return

	var player = passenger_ref
	is_occupied = false
	passenger_ref = null

	# Tính tọa độ hạ cánh an toàn bên mạn phải trực thăng
	var cur_pos = global_position if is_inside_tree() else position
	var cur_basis = global_basis if is_inside_tree() else basis
	var exit_pos = cur_pos + cur_basis.x * 2.8
	var ground_h = ModularNatureChunk.get_world_height(exit_pos.x, exit_pos.z)
	exit_pos.y = maxf(ground_h + 0.5, cur_pos.y) # Đứng an toàn trên mặt sàn helipad hoặc mặt đất

	if player.is_inside_tree():
		player.global_position = exit_pos
	else:
		player.position = exit_pos
	player.set_meta("nearby_helicopter", self)
	if prompt_3d:
		prompt_3d.visible = true
	player.visible = true
	player.set_physics_process(true)
	player.set_process_unhandled_input(true)
	if player is CollisionObject3D:
		player.collision_layer = _saved_pilot_layer if _saved_pilot_layer != 0 else 2
		player.collision_mask = _saved_pilot_mask if _saved_pilot_mask != 0 else 1

	# Chuyển camera về lại người chơi
	if player.has_node("Head/SpringArm3D/Camera3D"):
		var p_cam: Camera3D = player.get_node("Head/SpringArm3D/Camera3D")
		p_cam.current = true
	elif player.has_node("Head/Camera3D"):
		var p_cam: Camera3D = player.get_node("Head/Camera3D")
		p_cam.current = true

	# Tắt HUD phi hành
	if hud_layer:
		hud_layer.visible = false
	if prompt_3d:
		prompt_3d.visible = true

	emit_signal("player_exited_helicopter", player)
	print("[Helicopter] 🚁 Thị Trưởng đã rời trực thăng an toàn tại %s" % exit_pos)

func _on_interaction_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and not is_occupied:
		body.set_meta("nearby_helicopter", self)
		if prompt_3d:
			prompt_3d.visible = true

func _on_interaction_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		if body.has_meta("nearby_helicopter") and body.get_meta("nearby_helicopter") == self:
			body.remove_meta("nearby_helicopter")
		if prompt_3d:
			prompt_3d.visible = false

func _get_compass_heading(deg: float) -> String:
	if deg >= 337.5 or deg < 22.5:
		return "BẮC (N)"
	elif deg < 67.5:
		return "ĐÔNG BẮC (NE)"
	elif deg < 112.5:
		return "ĐÔNG (E)"
	elif deg < 157.5:
		return "ĐÔNG NAM (SE)"
	elif deg < 202.5:
		return "NAM (S)"
	elif deg < 247.5:
		return "TÂY NAM (SW)"
	elif deg < 292.5:
		return "TÂY (W)"
	else:
		return "TÂY BẮC (NW)"
