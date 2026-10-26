class_name PlayerController
extends CharacterBody3D

const InventoryManagerScript = preload("res://scripts/economy/inventory_manager.gd")
const AudioSynthesizerScript = preload("res://scripts/core/audio_synthesizer.gd")

# ==============================================================================
# PLAYER CONTROLLER - THỊ TRƯỞNG TÂN THẾ GIỚI
# 1. Tạo hình 3D Anime Stylized hoàn chỉnh (Áo măng tô xanh hoàng gia, cầu vai vàng)
# 2. Điều khiển di chuyển: [W, A, S, D] hoặc [↑, ↓] Tiến/Lùi, Dạt Trái/Phải
# 3. Xoay góc nhìn / Quay Trái - Phải: Rê Chuột 360 độ hoặc phím Mũi Tên [←, →]
# 4. Góc nhìn thứ 3 (Third-Person): Phím [V] đổi góc nhìn 1/3, Cuộn chuột zoom
# 5. Tương tác công dân [E]: Mở Thẻ Căn Cước Hologram khi lại gần NPC
# ==============================================================================

@export var walk_speed: float = 5.5
@export var sprint_speed: float = 9.0
@export var jump_velocity: float = 5.5
@export var mouse_sensitivity: float = 0.0025
@export var keyboard_turn_speed: float = 2.6
@export var third_person_distance: float = 3.6
@export var is_third_person: bool = true

@export var max_health: float = 100.0
var current_health: float = 100.0
@export var max_stamina: float = 100.0
var current_stamina: float = 100.0
@export var sprint_stamina_drain_rate: float = 20.0
@export var stamina_recovery_rate: float = 15.0
@export var max_focus: float = 100.0
var current_focus: float = 100.0
var desk_work_progress: float = 0.0
var completed_desk_sessions: int = 0
var last_announced_work_milestone: int = 0
const SPRINT_RECOVERY_THRESHOLD_RATIO: float = 0.25
var sprint_exhausted: bool = false
var speed_multiplier: float = 1.0
var speed_buff_timer: float = 0.0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

@onready var head: Node3D = $Head
@onready var spring_arm: SpringArm3D = $Head/SpringArm3D if has_node("Head/SpringArm3D") else null
@onready var camera: Camera3D = $Head/SpringArm3D/Camera3D if has_node("Head/SpringArm3D/Camera3D") else $Head/Camera3D
@onready var interaction_ray: RayCast3D = camera.get_node_or_null("InteractionRay") if camera else null
@onready var body_collision: CollisionShape3D = get_node_or_null("CollisionShape3D")

var visual_model: Node3D
var is_mouse_captured: bool = true
var life_activity: String = ""
var life_activity_station: Node3D
var saved_activity_transform: Transform3D
var saved_visual_transform: Transform3D
var saved_head_transform: Transform3D
var saved_collision_disabled: bool = false
var saved_physics_processing: bool = true

# Hệ thống Trang Phục Thị Trưởng (Wardrobe Outfits)
const OUTFIT_DEFINITIONS := {
	"formal": {
		"id": "formal",
		"name": "Âu Phục Lễ Tân Ngoại Giao",
		"icon": "👔",
		"desc": "Áo măng tô xanh hoàng gia viền vàng, quần âu trắng, giày da bóng. Tác phong đĩnh đạc khi tiếp đón đoàn ngoại giao.",
		"torso_color": Color(0.18, 0.38, 0.72),
		"pants_color": Color(0.92, 0.94, 0.96),
		"shoe_color": Color(0.12, 0.12, 0.14),
		"trim_color": Color(0.96, 0.82, 0.22)
	},
	"outdoor": {
		"id": "outdoor",
		"name": "Đồ Dã Ngoại & Thị Sát Núi Rừng",
		"icon": "🧗",
		"desc": "Áo khoác rêu dã ngoại, quần túi hộp kaki sẫm, ủng da bền chắc. Tiện lợi khi vượt dốc núi và thị sát thực địa.",
		"torso_color": Color(0.34, 0.44, 0.30),
		"pants_color": Color(0.26, 0.23, 0.19),
		"shoe_color": Color(0.38, 0.24, 0.14),
		"trim_color": Color(0.85, 0.65, 0.35)
	},
	"sleepwear": {
		"id": "sleepwear",
		"name": "Đồ Ngủ Lụa Thư Giãn",
		"icon": "🌙",
		"desc": "Bộ pyjama lụa sapphire êm dịu, dép nhung mềm ấm. Thoải mái tối đa khi nghỉ ngơi trên giường King-size qua đêm.",
		"torso_color": Color(0.24, 0.42, 0.62),
		"pants_color": Color(0.24, 0.42, 0.62),
		"shoe_color": Color(0.72, 0.70, 0.66),
		"trim_color": Color(0.95, 0.95, 0.98)
	}
}

var current_outfit: String = "formal"

# Hệ thống Vật Phẩm Cầm Tay 3D (Held Props & Hotbar 1-8)
var held_prop_mount: Node3D = null
var selected_hotbar_index: int = -1
var current_held_item_id: String = ""
var equipped_lantern_light: OmniLight3D = null
var briefcase_node: Node3D = null
var briefcase_lid_pivot: Node3D = null
var is_item_transfer_animation_active: bool = false
var lantern_is_lit: bool = true
var hotbar_item_ids: Array[String] = [
	"item_baguette",
	"item_herbal_tea",
	"item_lantern",
	"item_mayor_decree",
	"item_buggy_key",
	"item_wheat_sack",
	"item_onsen_herb",
	"item_tablet"
]

func _ready() -> void:
	add_to_group("player")
	
	# Thiết lập bám dốc & chống kẹt địa hình dốc núi
	floor_snap_length = 0.5
	floor_max_angle = deg_to_rad(60.0)
	floor_stop_on_slope = true
	floor_block_on_wall = true
	
	# Xây dựng mô hình 3D Anime Thị Trưởng nếu chưa có
	if has_node("MeshInstance3D"):
		$MeshInstance3D.queue_free()
		
	visual_model = ModularHumanoidBuilder.build_character_model(
		ModularHumanoidBuilder.ProfessionType.MAYOR,
		ModularHumanoidBuilder.AgeGroup.ADULT,
		"Nam"
	)
	visual_model.name = "MayorVisualModel"
	add_child(visual_model)

	# Giá đỡ vật phẩm 3D cầm tay trên tay phải Thị Trưởng
	held_prop_mount = Node3D.new()
	held_prop_mount.name = "HeldPropMount"
	held_prop_mount.position = Vector3(0.25, 0.72, -0.25)
	add_child(held_prop_mount)
	_setup_mayor_briefcase()
	
	# Thiết lập tầm nhìn xa 35km cho thế giới mở 500 km²
	if camera:
		camera.far = 35000.0
		
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_update_camera_mode(true)
	print("[Player] 🎮 Khởi tạo thành công: Model Thị Trưởng 3D, SpringArm = %s, Camera (Far=%.0fm) = %s" % [spring_arm != null, camera.far if camera else 0.0, camera != null])

func get_save_state() -> Dictionary:
	return {
		"position": [global_position.x, global_position.y, global_position.z],
		"rotation": [rotation.x, rotation.y, rotation.z],
		"head_pitch": head.rotation.x if head else 0.0,
		"health": current_health,
		"stamina": current_stamina,
		"focus": current_focus,
		"desk_work_progress": desk_work_progress,
		"completed_desk_sessions": completed_desk_sessions,
		"is_third_person": is_third_person,
		"third_person_distance": third_person_distance,
		"selected_hotbar_index": selected_hotbar_index,
		"lantern_is_lit": lantern_is_lit,
		"current_outfit": current_outfit
	}

func validate_saved_state(state: Dictionary) -> bool:
	if not _is_finite_vector(state.get("position")) or not _is_finite_vector(state.get("rotation")):
		return false
	if not _is_finite_number(state.get("head_pitch")):
		return false
	if not _is_finite_number(state.get("health")) or not _is_finite_number(state.get("stamina")):
		return false
	if state.has("focus") and not _is_finite_number(state["focus"]):
		return false
	if state.has("desk_work_progress") and not _is_finite_number(state["desk_work_progress"]):
		return false
	if state.has("completed_desk_sessions") and not (state["completed_desk_sessions"] is int or state["completed_desk_sessions"] is float):
		return false
	if not _is_finite_number(state.get("third_person_distance")) or not state.get("is_third_person") is bool:
		return false
	var saved_hotbar_index: Variant = state.get("selected_hotbar_index", -1)
	var saved_lantern_is_lit: Variant = state.get("lantern_is_lit", true)
	if not (saved_hotbar_index is int or saved_hotbar_index is float) or not saved_lantern_is_lit is bool:
		return false
	var saved_outfit: Variant = state.get("current_outfit", "formal")
	if not saved_outfit is String or not OUTFIT_DEFINITIONS.has(String(saved_outfit)):
		return false
	return (
		float(state["health"]) >= 0.0 and float(state["health"]) <= max_health
		and float(state["stamina"]) >= 0.0 and float(state["stamina"]) <= max_stamina
		and float(state.get("focus", max_focus)) >= 0.0 and float(state.get("focus", max_focus)) <= max_focus
		and float(state.get("desk_work_progress", 0.0)) >= 0.0 and float(state.get("desk_work_progress", 0.0)) < 1.0
		and int(state.get("completed_desk_sessions", 0)) >= 0
		and float(state["third_person_distance"]) >= 1.2 and float(state["third_person_distance"]) <= 8.0
		and int(saved_hotbar_index) >= -1
		and int(saved_hotbar_index) < hotbar_item_ids.size()
	)

func apply_saved_state(state: Dictionary) -> bool:
	if not validate_saved_state(state):
		return false
	global_position = _saved_vector3(state["position"])
	rotation = _saved_vector3(state["rotation"])
	if head:
		head.rotation.x = float(state["head_pitch"])
	current_health = float(state["health"])
	current_stamina = float(state["stamina"])
	current_focus = float(state.get("focus", max_focus))
	desk_work_progress = float(state.get("desk_work_progress", 0.0))
	completed_desk_sessions = int(state.get("completed_desk_sessions", 0))
	is_third_person = state["is_third_person"]
	third_person_distance = float(state["third_person_distance"])
	selected_hotbar_index = int(state.get("selected_hotbar_index", -1))
	lantern_is_lit = bool(state.get("lantern_is_lit", true))
	var target_outfit = String(state.get("current_outfit", "formal"))
	set_outfit(target_outfit)
	_update_camera_mode(true)
	if selected_hotbar_index >= 0:
		_equip_prop_by_id(hotbar_item_ids[selected_hotbar_index])
	var hud := get_tree().get_first_node_in_group("hud")
	if hud != null and hud.has_method("set_selected_hotbar_slot"):
		hud.set_selected_hotbar_slot(selected_hotbar_index)
	return true

func set_outfit(outfit_id: String) -> bool:
	if not OUTFIT_DEFINITIONS.has(outfit_id):
		push_warning("[Player] Không tìm thấy trang phục: %s" % outfit_id)
		return false

	current_outfit = outfit_id
	var def: Dictionary = OUTFIT_DEFINITIONS[outfit_id]
	_apply_outfit_visuals(def)
	AudioSynthesizerScript.play_sound(self, "storage_transfer")

	var tree := get_tree()
	var hud := tree.get_first_node_in_group("hud") if tree else null
	if hud != null and hud.has_method("show_toast"):
		hud.show_toast("%s Đã đổi trang phục: %s!" % [def.get("icon", "✨"), def.get("name", "")])
	print("[Player] 👔 Đã thay đổi trang phục sang: %s (%s)" % [def.get("name", ""), outfit_id])
	return true

func _apply_outfit_visuals(def: Dictionary) -> void:
	if visual_model == null:
		return

	var torso_col: Color = def.get("torso_color", Color(0.18, 0.38, 0.72))
	var pants_col: Color = def.get("pants_color", Color(0.92, 0.94, 0.96))
	var shoe_col: Color = def.get("shoe_color", Color(0.12, 0.12, 0.14))
	var trim_col: Color = def.get("trim_color", Color(0.96, 0.82, 0.22))

	var mat_torso := StandardMaterial3D.new()
	mat_torso.albedo_color = torso_col
	mat_torso.roughness = 0.75
	mat_torso.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat_torso.specular_mode = BaseMaterial3D.SPECULAR_TOON

	var mat_pants := StandardMaterial3D.new()
	mat_pants.albedo_color = pants_col
	mat_pants.roughness = 0.8
	mat_pants.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat_pants.specular_mode = BaseMaterial3D.SPECULAR_TOON

	var mat_shoe := StandardMaterial3D.new()
	mat_shoe.albedo_color = shoe_col
	mat_shoe.roughness = 0.6
	mat_shoe.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat_shoe.specular_mode = BaseMaterial3D.SPECULAR_TOON

	var mat_trim := StandardMaterial3D.new()
	mat_trim.albedo_color = trim_col
	mat_trim.metallic = 0.7
	mat_trim.roughness = 0.25

	# Cập nhật Torso và tay áo Sleeves
	var torso = visual_model.find_child("Torso", true, false) as MeshInstance3D
	if torso:
		torso.material_override = mat_torso

	for side_name in ["Arm_L", "Arm_R"]:
		var arm = visual_model.find_child(side_name, true, false)
		if arm:
			var sleeve = arm.find_child("Sleeve", true, false) as MeshInstance3D
			if sleeve:
				sleeve.material_override = mat_torso

	# Cập nhật Pants và Shoes
	for side_name in ["Leg_L", "Leg_R"]:
		var leg = visual_model.find_child(side_name, true, false)
		if leg:
			var pants = leg.find_child("Pants", true, false) as MeshInstance3D
			if pants:
				pants.material_override = mat_pants
			var shoe = leg.find_child("Shoe", true, false) as MeshInstance3D
			if shoe:
				shoe.material_override = mat_shoe

	# Cập nhật cầu vai mạ vàng cho Âu phục
	_update_shoulder_accessories(torso, mat_trim, def.get("id", "formal"))

func _update_shoulder_accessories(torso: Node3D, mat_trim: Material, outfit_id: String) -> void:
	if torso == null:
		return
	var epaulet_l = torso.find_child("Epaulet_L", true, false) as MeshInstance3D
	var epaulet_r = torso.find_child("Epaulet_R", true, false) as MeshInstance3D
	if outfit_id == "formal":
		if epaulet_l == null:
			epaulet_l = MeshInstance3D.new()
			epaulet_l.name = "Epaulet_L"
			var e_mesh := BoxMesh.new()
			e_mesh.size = Vector3(0.14, 0.04, 0.18)
			epaulet_l.mesh = e_mesh
			epaulet_l.position = Vector3(-0.24, 0.28, 0.0)
			torso.add_child(epaulet_l)
		epaulet_l.material_override = mat_trim
		epaulet_l.visible = true

		if epaulet_r == null:
			epaulet_r = MeshInstance3D.new()
			epaulet_r.name = "Epaulet_R"
			var er_mesh := BoxMesh.new()
			er_mesh.size = Vector3(0.14, 0.04, 0.18)
			epaulet_r.mesh = er_mesh
			epaulet_r.position = Vector3(0.24, 0.28, 0.0)
			torso.add_child(epaulet_r)
		epaulet_r.material_override = mat_trim
		epaulet_r.visible = true
	else:
		if epaulet_l:
			epaulet_l.visible = false
		if epaulet_r:
			epaulet_r.visible = false

func _saved_vector3(values: Array) -> Vector3:
	return Vector3(float(values[0]), float(values[1]), float(values[2]))

func _is_finite_vector(value: Variant) -> bool:
	if not value is Array or value.size() != 3:
		return false
	for component in value:
		if not _is_finite_number(component):
			return false
	return true

func _is_finite_number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))

func _setup_mayor_briefcase() -> void:
	briefcase_node = Node3D.new()
	briefcase_node.name = "MayorBriefcase"
	briefcase_node.position = Vector3(-0.34, 0.78, 0.16)
	briefcase_node.rotation_degrees = Vector3(-8.0, -12.0, -5.0)
	add_child(briefcase_node)

	var leather := StandardMaterial3D.new()
	leather.albedo_color = Color(0.19, 0.095, 0.045)
	leather.roughness = 0.78
	var brass := StandardMaterial3D.new()
	brass.albedo_color = Color(0.78, 0.58, 0.2)
	brass.metallic = 0.75

	var case_body := MeshInstance3D.new()
	case_body.name = "LeatherCase"
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(0.34, 0.2, 0.12)
	case_body.mesh = body_mesh
	case_body.material_override = leather
	briefcase_node.add_child(case_body)

	briefcase_lid_pivot = Node3D.new()
	briefcase_lid_pivot.name = "BriefcaseLidPivot"
	briefcase_lid_pivot.position = Vector3(0.0, 0.09, -0.055)
	briefcase_node.add_child(briefcase_lid_pivot)

	var lid := MeshInstance3D.new()
	lid.name = "BriefcaseLid"
	var lid_mesh := BoxMesh.new()
	lid_mesh.size = Vector3(0.34, 0.035, 0.12)
	lid.mesh = lid_mesh
	lid.position = Vector3(0.0, 0.025, 0.055)
	lid.material_override = leather
	briefcase_lid_pivot.add_child(lid)

	var handle := MeshInstance3D.new()
	handle.name = "BriefcaseHandle"
	var handle_mesh := BoxMesh.new()
	handle_mesh.size = Vector3(0.13, 0.035, 0.035)
	handle.mesh = handle_mesh
	handle.position = Vector3(0.0, 0.125, 0.0)
	handle.material_override = brass
	briefcase_node.add_child(handle)

	for side in [-1.0, 1.0]:
		var clasp := MeshInstance3D.new()
		var clasp_mesh := BoxMesh.new()
		clasp_mesh.size = Vector3(0.025, 0.045, 0.018)
		clasp.mesh = clasp_mesh
		clasp.position = Vector3(side * 0.11, 0.0, -0.068)
		clasp.material_override = brass
		briefcase_node.add_child(clasp)

func animate_item_transfer(item_id: String, on_transfer: Callable) -> bool:
	if is_item_transfer_animation_active or briefcase_node == null or held_prop_mount == null:
		return false
	if not InventoryManagerScript.ITEM_DEFINITIONS.has(item_id):
		push_error("[Player] Không thể diễn hoạt vật phẩm không xác định: %s." % item_id)
		return false

	is_item_transfer_animation_active = true
	var previous_item_id := current_held_item_id
	var hand_start := held_prop_mount.position
	var body_start := visual_model.position if visual_model else Vector3.ZERO
	var hand_to_case := briefcase_node.position + Vector3(0.28, 0.02, -0.12)
	
	AudioSynthesizerScript.play_sound(self, "briefcase_open")
	var tween := create_tween()
	tween.tween_property(briefcase_lid_pivot, "rotation:x", -1.15, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(held_prop_mount, "position", hand_to_case, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if visual_model:
		tween.parallel().tween_property(visual_model, "position:y", body_start.y - 0.06, 0.22)
	tween.tween_interval(0.12)
	tween.tween_callback(func() -> void:
		_equip_prop_by_id(item_id, true)
		AudioSynthesizerScript.play_sound(self, "storage_transfer")
		if on_transfer.is_valid():
			on_transfer.call()
	)
	tween.tween_interval(0.16)
	tween.tween_property(held_prop_mount, "position", hand_start, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(briefcase_lid_pivot, "rotation:x", 0.0, 0.2)
	if visual_model:
		tween.parallel().tween_property(visual_model, "position", body_start, 0.2)
	tween.tween_callback(func() -> void:
		AudioSynthesizerScript.play_sound(self, "briefcase_close")
		is_item_transfer_animation_active = false
		if previous_item_id != "" and InventoryManagerScript.get_item_count(previous_item_id) > 0:
			_equip_prop_by_id(previous_item_id)
		else:
			_clear_held_prop()
	)
	return true

func open_briefcase_view() -> void:
	if briefcase_lid_pivot and not is_item_transfer_animation_active:
		var tween := create_tween()
		tween.tween_property(briefcase_lid_pivot, "rotation:x", -1.25, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		AudioSynthesizerScript.play_sound(self, "briefcase_open")

func close_briefcase_view() -> void:
	if briefcase_lid_pivot and not is_item_transfer_animation_active:
		var tween := create_tween()
		tween.tween_property(briefcase_lid_pivot, "rotation:x", 0.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		AudioSynthesizerScript.play_sound(self, "briefcase_close")

func _clear_held_prop() -> void:
	if held_prop_mount:
		for child in held_prop_mount.get_children():
			child.queue_free()
	equipped_lantern_light = null
	current_held_item_id = ""

func _input(event: InputEvent) -> void:
	if life_activity != "":
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_E or event.physical_keycode == KEY_E or event.keycode == KEY_ESCAPE or event.physical_keycode == KEY_ESCAPE:
				end_life_activity()
				get_viewport().set_input_as_handled()
		return

	var life_hud := get_tree().get_first_node_in_group("hud")
	if life_hud and life_hud.has_method("is_life_activity_options_open") and life_hud.is_life_activity_options_open():
		if event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_ESCAPE or event.physical_keycode == KEY_ESCAPE):
			life_hud.close_life_activity_options()
			get_viewport().set_input_as_handled()
		return

	# 1. Nhấp chuột để bắt chuột lại nếu đang hiện con trỏ
	if event is InputEventMouseButton and event.pressed:
		if not is_mouse_captured:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			is_mouse_captured = true
			get_viewport().set_input_as_handled()
			return
			
		# Cuộn con lăn chuột để Zoom xa/gần góc nhìn thứ 3
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			third_person_distance = clampf(third_person_distance - 0.4, 1.2, 8.0)
			if not is_third_person:
				is_third_person = true
				_update_camera_mode()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			third_person_distance = clampf(third_person_distance + 0.4, 1.2, 8.0)
			if not is_third_person:
				is_third_person = true
				_update_camera_mode()

	# 2. Phím [Esc] bật/tắt con trỏ chuột
	if event.is_action_pressed("ui_cancel"):
		is_mouse_captured = not is_mouse_captured
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if is_mouse_captured else Input.MOUSE_MODE_VISIBLE)
		get_viewport().set_input_as_handled()

	# 3. Rê chuột để xoay nhân vật & camera 360 độ (Quay trái, quay phải, nhìn lên, nhìn xuống)
	if is_mouse_captured and event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clampf(head.rotation.x, deg_to_rad(-80.0), deg_to_rad(80.0))

	# 4. Phím [V] để chuyển đổi giữa góc nhìn thứ 3 và góc nhìn thứ nhất
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_V or event.physical_keycode == KEY_V:
			is_third_person = not is_third_person
			_update_camera_mode()
			print("[Player] 🎥 Chuyển góc nhìn camera: %s" % ["Thứ Ba (Third-Person)" if is_third_person else "Thứ Nhất (First-Person)"])

	# Xuống xe tram trước các xử lý tương tác E/F thông thường.
	if event is InputEventKey and event.pressed and not event.echo:
		var tram_exit_key = event.keycode == KEY_E or event.physical_keycode == KEY_E or event.keycode == KEY_F or event.physical_keycode == KEY_F
		if tram_exit_key and has_meta("occupied_metro"):
			var metro_train = get_meta("occupied_metro")
			if is_instance_valid(metro_train) and metro_train.has_method("exit_metro"):
				metro_train.exit_metro()
				get_viewport().set_input_as_handled()
				return
		if tram_exit_key and has_meta("occupied_tram"):
			var tram = get_meta("occupied_tram")
			if is_instance_valid(tram) and tram.has_method("exit_tram"):
				tram.exit_tram()
				get_viewport().set_input_as_handled()
				return

	# 5. Phím [E] tương tác với NPC hoặc Điểm Tương Tác Đô Thị (Interactive Station)
	if event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_E or event.physical_keycode == KEY_E)):
		var nearby_npc = get_meta("nearby_npc") if has_meta("nearby_npc") else null
		var nearby_st = get_meta("nearby_interactive") if has_meta("nearby_interactive") else null
		
		# Xác thực cự ly thực tế tránh stale metadata do dịch chuyển tọa độ
		if nearby_npc and is_instance_valid(nearby_npc):
			var dist_npc = global_position.distance_to(nearby_npc.global_position)
			if dist_npc > 6.5:
				remove_meta("nearby_npc")
				nearby_npc = null
				
		if nearby_st and is_instance_valid(nearby_st):
			var r_max: float = nearby_st.interaction_radius if "interaction_radius" in nearby_st else 6.0
			var dist_st: float = global_position.distance_to(nearby_st.global_position)
			if nearby_st.is_in_group("elevators") or "cabin_platform" in nearby_st:
				dist_st = Vector2(global_position.x - nearby_st.global_position.x, global_position.z - nearby_st.global_position.z).length()
			if dist_st > r_max + 0.5:
				remove_meta("nearby_interactive")
				nearby_st = null

		if nearby_npc and is_instance_valid(nearby_npc) and nearby_st and is_instance_valid(nearby_st):
			var dist_npc = global_position.distance_to(nearby_npc.global_position)
			var dist_st = global_position.distance_to(nearby_st.global_position)
			if dist_st <= dist_npc and nearby_st.has_method("interact"):
				nearby_st.interact(self)
				get_viewport().set_input_as_handled()
				return
			elif nearby_npc.has_method("trigger_interaction"):
				nearby_npc.trigger_interaction()
				get_viewport().set_input_as_handled()
				return
		elif nearby_st and is_instance_valid(nearby_st) and nearby_st.has_method("interact"):
			nearby_st.interact(self)
			get_viewport().set_input_as_handled()
			return
		elif nearby_npc and is_instance_valid(nearby_npc) and nearby_npc.has_method("trigger_interaction"):
			nearby_npc.trigger_interaction()
			get_viewport().set_input_as_handled()
			return
		elif is_inside_tree():
			# Fallback cự ly an toàn cho Interactive Station
			for st in get_tree().get_nodes_in_group("interactive_stations"):
				if is_instance_valid(st) and global_position.distance_to(st.global_position) <= st.interaction_radius:
					st.interact(self)
					get_viewport().set_input_as_handled()
					return

	# 6. Phím [M] hoặc [Tab] mở/đóng Tablet Bản Đồ Toàn Cảnh 500 km²
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_M or event.physical_keycode == KEY_M or event.keycode == KEY_TAB or event.physical_keycode == KEY_TAB:
			var hud = get_tree().get_first_node_in_group("hud")
			if hud and hud.has_method("toggle_macro_map"):
				hud.toggle_macro_map()
				get_viewport().set_input_as_handled()

	# 7. Phím [F] hoặc [E] lên Trực Thăng hoặc Xe Buggy Điện Thị Trưởng
	if event is InputEventKey and event.pressed and not event.echo:
		var is_f = (event.keycode == KEY_F or event.physical_keycode == KEY_F)
		var is_e = (event.keycode == KEY_E or event.physical_keycode == KEY_E)
		if is_f or (is_e and not has_meta("nearby_npc") and not has_meta("nearby_interactive")):
			# A. Xe Buggy Điện
			var buggy = null
			if has_meta("nearby_buggy"):
				buggy = get_meta("nearby_buggy")
			if not buggy and is_inside_tree():
				for b in get_tree().get_nodes_in_group("buggies"):
					if is_instance_valid(b) and not b.is_occupied and global_position.distance_to(b.global_position) <= 6.0:
						buggy = b
						break
			if buggy and is_instance_valid(buggy) and buggy.has_method("board"):
				buggy.board(self)
				get_viewport().set_input_as_handled()
				return

			# B. Trực Thăng Cao Tốc
			var heli = null
			if has_meta("nearby_helicopter"):
				heli = get_meta("nearby_helicopter")
			if not heli and is_inside_tree():
				for h in get_tree().get_nodes_in_group("helicopters"):
					if is_instance_valid(h) and not h.is_occupied and global_position.distance_to(h.global_position) <= 7.5:
						heli = h
						break
			if heli and is_instance_valid(heli) and heli.has_method("board"):
				heli.board(self)
				get_viewport().set_input_as_handled()
				return
			if is_f and has_meta("nearby_interactive"):
				var nearby_station = get_meta("nearby_interactive")
				if is_instance_valid(nearby_station) and nearby_station.has_method("interact"):
					var station_radius: Variant = nearby_station.get("interaction_radius")
					if (station_radius is int or station_radius is float) and global_position.distance_to(nearby_station.global_position) <= float(station_radius):
						nearby_station.interact(self)
						get_viewport().set_input_as_handled()
						return
	# Number key floor selection for elevator (keys 1-9)
	if has_meta("nearby_elevator"):
		var elevator = get_meta("nearby_elevator")
		var target_floor = -1
		if event.is_action_pressed("ui_select"):
			pass # placeholder
		# Check number keys (both physical and logical keycode)
		if event is InputEventKey and event.pressed and not event.echo:
			var code = event.physical_keycode if event.physical_keycode != 0 else event.keycode
			match code:
				KEY_1: target_floor = 1
				KEY_2: target_floor = 2
				KEY_3: target_floor = 3
				KEY_4: target_floor = 4
				KEY_5: target_floor = 5
				KEY_6: target_floor = 6
				KEY_7: target_floor = 7
				KEY_8: target_floor = 8
				KEY_9: target_floor = 9
		if target_floor != -1:
			if elevator.has_method("request_floor"):
				elevator.request_floor(self, target_floor)
				get_viewport().set_input_as_handled()
				return

	# 8. Phím [I] mở/đóng Túi Đồ Thị Trưởng (Inventory)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_I or event.physical_keycode == KEY_I:
			var hud = get_tree().get_first_node_in_group("hud")
			if hud and hud.has_method("toggle_inventory_modal"):
				hud.toggle_inventory_modal()
				get_viewport().set_input_as_handled()
				return

	# 9. Phím [1] - [8] Trang bị & Sử dụng vật phẩm cầm tay Hotbar
	if event is InputEventKey and event.pressed and not event.echo:
		var slot_target = -1
		match event.physical_keycode:
			KEY_1: slot_target = 0
			KEY_2: slot_target = 1
			KEY_3: slot_target = 2
			KEY_4: slot_target = 3
			KEY_5: slot_target = 4
			KEY_6: slot_target = 5
			KEY_7: slot_target = 6
			KEY_8: slot_target = 7
		if slot_target == -1:
			match event.keycode:
				KEY_1: slot_target = 0
				KEY_2: slot_target = 1
				KEY_3: slot_target = 2
				KEY_4: slot_target = 3
				KEY_5: slot_target = 4
				KEY_6: slot_target = 5
				KEY_7: slot_target = 6
				KEY_8: slot_target = 7

		if slot_target != -1:
			select_hotbar_slot(slot_target)
			get_viewport().set_input_as_handled()
			return

func select_hotbar_slot(slot_idx: int) -> void:
	if slot_idx < 0 or slot_idx >= hotbar_item_ids.size():
		return

	if selected_hotbar_index == slot_idx:
		# Nhấn lần 2 vào cùng slot -> Kích hoạt / Dùng vật phẩm
		_activate_held_item(slot_idx)
	else:
		# Chọn slot mới & trang bị mô hình 3D trên tay
		selected_hotbar_index = slot_idx
		var tree = get_tree()
		var hud = tree.get_first_node_in_group("hud") if tree else null
		if hud and hud.has_method("set_selected_hotbar_slot"):
			hud.set_selected_hotbar_slot(slot_idx)
		_equip_prop_by_id(hotbar_item_ids[slot_idx])

func _equip_prop_by_id(item_id: String, allow_unowned: bool = false) -> void:
	if held_prop_mount == null:
		return

	for c in held_prop_mount.get_children():
		c.queue_free()
	equipped_lantern_light = null
	current_held_item_id = item_id

	var count = InventoryManagerScript.get_item_count(item_id)
	if count <= 0 and not allow_unowned:
		var def = InventoryManagerScript.ITEM_DEFINITIONS.get(item_id, {})
		var tree = get_tree()
		var hud = tree.get_first_node_in_group("hud") if tree else null
		if hud and hud.has_method("show_toast"):
			hud.show_toast("🎒 Bạn chưa có %s trong túi đồ!" % def.get("name", "vật phẩm này"))
		return

	# Tạo mô hình 3D chi tiết cho vật phẩm trên tay
	match item_id:
		"item_baguette":
			var b = MeshInstance3D.new()
			var cyl = CylinderMesh.new()
			cyl.top_radius = 0.04
			cyl.bottom_radius = 0.045
			cyl.height = 0.36
			b.mesh = cyl
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.86, 0.58, 0.24)
			mat.roughness = 0.8
			b.material_override = mat
			b.rotation_degrees = Vector3(45, 15, -20)
			held_prop_mount.add_child(b)

		"item_herbal_tea":
			var flask = MeshInstance3D.new()
			var cyl = CylinderMesh.new()
			cyl.top_radius = 0.03
			cyl.bottom_radius = 0.06
			cyl.height = 0.18
			flask.mesh = cyl
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.18, 0.85, 0.45)
			mat.roughness = 0.2
			mat.emission_enabled = true
			mat.emission = Color(0.1, 0.6, 0.3)
			mat.emission_energy_multiplier = 0.8
			flask.material_override = mat
			held_prop_mount.add_child(flask)

		"item_lantern":
			var lantern_body = MeshInstance3D.new()
			var box = BoxMesh.new()
			box.size = Vector3(0.12, 0.20, 0.12)
			lantern_body.mesh = box
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.65, 0.50, 0.22) # Đồng cổ
			mat.metallic = 0.8
			mat.roughness = 0.3
			lantern_body.material_override = mat
			held_prop_mount.add_child(lantern_body)

			# Ngọn lửa ấm bên trong
			var flame = MeshInstance3D.new()
			var sph = SphereMesh.new()
			sph.radius = 0.035
			sph.height = 0.07
			flame.mesh = sph
			var f_mat = StandardMaterial3D.new()
			f_mat.albedo_color = Color(1.0, 0.9, 0.5)
			f_mat.emission_enabled = true
			f_mat.emission = Color(1.0, 0.8, 0.3)
			f_mat.emission_energy_multiplier = 3.0
			flame.material_override = f_mat
			held_prop_mount.add_child(flame)

			# Nguồn sáng thực tế ban đêm
			equipped_lantern_light = OmniLight3D.new()
			equipped_lantern_light.name = "LanternOmniLight"
			equipped_lantern_light.light_color = Color(1.0, 0.86, 0.52)
			equipped_lantern_light.light_energy = 2.2
			equipped_lantern_light.omni_range = 16.0
			equipped_lantern_light.shadow_enabled = true
			equipped_lantern_light.visible = lantern_is_lit
			held_prop_mount.add_child(equipped_lantern_light)

		"item_mayor_decree":
			var scroll = MeshInstance3D.new()
			var cyl = CylinderMesh.new()
			cyl.top_radius = 0.025
			cyl.bottom_radius = 0.025
			cyl.height = 0.26
			scroll.mesh = cyl
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.95, 0.88, 0.72)
			scroll.material_override = mat
			scroll.rotation_degrees = Vector3(10, 0, 75)
			held_prop_mount.add_child(scroll)

			var ribbon = MeshInstance3D.new()
			var r_box = BoxMesh.new()
			r_box.size = Vector3(0.06, 0.04, 0.06)
			ribbon.mesh = r_box
			var r_mat = StandardMaterial3D.new()
			r_mat.albedo_color = Color(0.85, 0.15, 0.15)
			ribbon.material_override = r_mat
			held_prop_mount.add_child(ribbon)

		"item_buggy_key":
			var key = MeshInstance3D.new()
			var box = BoxMesh.new()
			box.size = Vector3(0.04, 0.08, 0.016)
			key.mesh = box
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.12, 0.14, 0.18)
			key.material_override = mat
			held_prop_mount.add_child(key)

			var led = MeshInstance3D.new()
			var l_box = BoxMesh.new()
			l_box.size = Vector3(0.012, 0.012, 0.018)
			led.mesh = l_box
			var l_mat = StandardMaterial3D.new()
			l_mat.albedo_color = Color(0.2, 0.95, 0.3)
			l_mat.emission_enabled = true
			l_mat.emission = Color(0.2, 1.0, 0.4)
			l_mat.emission_energy_multiplier = 2.0
			led.material_override = l_mat
			led.position = Vector3(0, 0.025, 0)
			held_prop_mount.add_child(led)

		"item_wheat_sack":
			var sack = MeshInstance3D.new()
			var sph = SphereMesh.new()
			sph.radius = 0.12
			sph.height = 0.20
			sack.mesh = sph
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.85, 0.75, 0.48)
			sack.material_override = mat
			held_prop_mount.add_child(sack)

		"item_onsen_herb":
			var herb = MeshInstance3D.new()
			var box = BoxMesh.new()
			box.size = Vector3(0.08, 0.18, 0.08)
			herb.mesh = box
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.25, 0.75, 0.35)
			herb.material_override = mat
			held_prop_mount.add_child(herb)

		"item_tablet":
			var tab = MeshInstance3D.new()
			var box = BoxMesh.new()
			box.size = Vector3(0.18, 0.008, 0.24)
			tab.mesh = box
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.15, 0.18, 0.24)
			mat.metallic = 0.8
			tab.material_override = mat
			held_prop_mount.add_child(tab)

			var screen = MeshInstance3D.new()
			var s_box = BoxMesh.new()
			s_box.size = Vector3(0.16, 0.010, 0.21)
			screen.mesh = s_box
			var s_mat = StandardMaterial3D.new()
			s_mat.albedo_color = Color(0.05, 0.75, 0.95)
			s_mat.emission_enabled = true
			s_mat.emission = Color(0.1, 0.85, 1.0)
			s_mat.emission_energy_multiplier = 2.0
			screen.material_override = s_mat
			held_prop_mount.add_child(screen)

	AudioSynthesizerScript.play_sound(self, "step")

func _activate_held_item(slot_idx: int) -> void:
	var item_id = hotbar_item_ids[slot_idx]
	var count = InventoryManagerScript.get_item_count(item_id)
	var tree = get_tree()
	var hud = tree.get_first_node_in_group("hud") if tree else null

	if count <= 0:
		if hud and hud.has_method("show_toast"):
			hud.show_toast("🎒 Đã dùng hết vật phẩm này!")
		return

	match item_id:
		"item_baguette":
			InventoryManagerScript.use_item("item_baguette", self)
			if hud and hud.has_method("show_toast"):
				hud.show_toast("🥖 Bạn đã ăn Bánh Mì Baguette (+50 HP, +50 Thể Lực)!")
			if InventoryManagerScript.get_item_count("item_baguette") == 0:
				_equip_prop_by_id("item_baguette")

		"item_herbal_tea":
			InventoryManagerScript.use_item("item_herbal_tea", self)
			if hud and hud.has_method("show_toast"):
				hud.show_toast("🌿 Bạn đã uống Trà Thảo Mộc Tuyết Sơn (đầy HP, Thể Lực & Tăng Tốc)!")
			if InventoryManagerScript.get_item_count("item_herbal_tea") == 0:
				_equip_prop_by_id("item_herbal_tea")

		"item_lantern":
			lantern_is_lit = not lantern_is_lit
			if equipped_lantern_light:
				equipped_lantern_light.visible = lantern_is_lit
			if hud and hud.has_method("show_toast"):
				hud.show_toast("🏮 Đèn Lồng: Đã Bật sáng ban đêm!" if lantern_is_lit else "🏮 Đèn Lồng: Đã Tắt ánh sáng.")
			AudioSynthesizerScript.play_sound(self, "bell")

		"item_mayor_decree":
			if hud and hud.has_method("open_petition_modal"):
				hud.open_petition_modal()
			elif hud and hud.has_method("show_toast"):
				hud.show_toast("📋 Sắc Lệnh An Sinh Đô Thị đang được công bố tới 5 huyện!")

		"item_buggy_key":
			if hud and hud.has_method("show_toast"):
				hud.show_toast("🔑 Chìa khóa xe Buggy điện kích hoạt! Lại gần xe bấm [F] để tuần tra.")
			AudioSynthesizerScript.play_sound(self, "chime")

		"item_wheat_sack":
			if hud and hud.has_method("show_toast"):
				hud.show_toast("🌾 Bao lúa mì vàng chuẩn bị giao cho Tiệm Bánh Bác Nam tại Quảng Trường!")

		"item_onsen_herb":
			if hud and hud.has_method("show_toast"):
				hud.show_toast("♨️ Thảo dược suối khoáng quý mang về cho Trạm Xá Chị Mai!")

		"item_tablet":
			if hud and hud.has_method("toggle_macro_map"):
				hud.toggle_macro_map()

	if hud and hud.has_method("update_hotbar_display"):
		hud.update_hotbar_display()

func heal(amount: float) -> void:
	current_health = clampf(current_health + amount, 0.0, max_health)
	AudioSynthesizerScript.play_sound(self, "consume")
	print("[Player] ❤️ Hồi phục +%.0f HP! Thể lực hiện tại: %.0f/%.0f" % [amount, current_health, max_health])

func restore_stamina(amount: float = 0.0, max_stamina_ratio: float = 0.0) -> void:
	var restored_amount: float = amount
	if max_stamina_ratio > 0.0:
		restored_amount = max_stamina * max_stamina_ratio
	current_stamina = clampf(current_stamina + restored_amount, 0.0, max_stamina)
	if sprint_exhausted and current_stamina >= max_stamina * SPRINT_RECOVERY_THRESHOLD_RATIO:
		sprint_exhausted = false
	print("[Player] ⚡ Hồi phục +%.0f Thể Lực (%.0f/%.0f)" % [restored_amount, current_stamina, max_stamina])

func rest_at_bed() -> void:
	current_health = max_health
	current_stamina = max_stamina
	sprint_exhausted = false
	speed_multiplier = 1.0
	speed_buff_timer = 0.0
	AudioSynthesizerScript.play_sound(self, "consume")
	print("[Player] 🛏️ Nghỉ ngơi hoàn tất: sức khỏe và thể lực đã hồi phục.")

func begin_life_activity(activity: String, station: Node3D) -> bool:
	if life_activity != "" or not is_instance_valid(station) or not ["lying", "sitting"].has(activity):
		return false
	saved_activity_transform = global_transform
	saved_visual_transform = visual_model.transform if visual_model else Transform3D.IDENTITY
	saved_head_transform = head.transform if head else Transform3D.IDENTITY
	saved_collision_disabled = body_collision.disabled if body_collision else false
	saved_physics_processing = is_physics_processing()
	life_activity = activity
	life_activity_station = station
	last_announced_work_milestone = int(floor(desk_work_progress * 4.0))
	velocity = Vector3.ZERO

	if activity == "lying":
		global_position = station.global_position + Vector3(0.0, 0.65, 0.0)
		global_rotation = Vector3(0.0, station.global_rotation.y, 0.0)
		if visual_model:
			visual_model.position = Vector3(0.0, 0.08, 0.0)
			visual_model.rotation = Vector3(0.0, 0.0, PI * 0.5)
	else:
		var seat_position: Vector3 = station.global_position + station.global_basis * Vector3(0.0, 0.0, -2.0)
		seat_position.y = global_position.y
		global_position = seat_position
		global_rotation = Vector3(0.0, station.global_rotation.y + PI, 0.0)
		if visual_model:
			visual_model.position = Vector3(0.0, 0.05, 0.0)
			visual_model.rotation = Vector3(deg_to_rad(-8.0), 0.0, 0.0)
			visual_model.scale = Vector3(1.0, 0.72, 1.0)
		if head:
			head.position.y = 1.05

	if body_collision:
		body_collision.disabled = true
	set_physics_process(false)
	return true

func end_life_activity() -> void:
	if life_activity == "":
		return
	life_activity = ""
	life_activity_station = null
	global_transform = saved_activity_transform
	if visual_model:
		visual_model.transform = saved_visual_transform
	if head:
		head.transform = saved_head_transform
	if body_collision:
		body_collision.disabled = saved_collision_disabled
	set_physics_process(saved_physics_processing)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if is_mouse_captured else Input.MOUSE_MODE_VISIBLE)

func apply_speed_buff(mult: float, duration: float) -> void:
	speed_multiplier = mult
	speed_buff_timer = duration
	AudioSynthesizerScript.play_sound(self, "consume")
	print("[Player] ⚡ Nhận hiệu ứng Tăng Tốc Chạy x%.1f trong %.0fs!" % [mult, duration])

func _update_camera_mode(instant: bool = false) -> void:
	if spring_arm:
		var target_len = third_person_distance if is_third_person else 0.0
		if instant:
			spring_arm.spring_length = target_len
	if visual_model:
		visual_model.visible = is_third_person
	if held_prop_mount:
		held_prop_mount.visible = is_third_person

func _process(delta: float) -> void:
	if spring_arm:
		var target_len = third_person_distance if is_third_person else 0.0
		spring_arm.spring_length = lerpf(spring_arm.spring_length, target_len, delta * 12.0)
		
	# Nhịp thở nhấp nhô Toon cho Thị Trưởng & Held Prop khi đứng yên
	if life_activity == "lying":
		current_stamina = minf(max_stamina, current_stamina + stamina_recovery_rate * delta * 0.1)
		current_health = minf(max_health, current_health + 0.08 * delta)
		current_focus = minf(max_focus, current_focus + 0.15 * delta)
	elif life_activity == "sitting":
		current_stamina = minf(max_stamina, current_stamina + stamina_recovery_rate * delta * 0.02)
		current_focus = maxf(0.0, current_focus - 0.12 * delta)
		if current_focus > 0.0:
			desk_work_progress += delta / 180.0
			var milestone := mini(4, int(floor(desk_work_progress * 4.0)))
			if milestone > last_announced_work_milestone:
				last_announced_work_milestone = milestone
				var hud := get_tree().get_first_node_in_group("hud")
				if milestone == 4:
					completed_desk_sessions += 1
					desk_work_progress = 0.0
					last_announced_work_milestone = 0
					if hud and hud.has_method("show_toast"):
						hud.show_toast("📋 Hoàn thành một phiên làm việc tập trung. Phiên đã ghi nhận: %d." % completed_desk_sessions)
				elif hud and hud.has_method("show_toast"):
					hud.show_toast("📝 Đang làm việc tại bàn: %d%% tiến độ." % (milestone * 25))
		if visual_model:
			visual_model.position.y = 0.05
	elif visual_model and velocity.length_squared() < 0.1:
		var sway = sin(Time.get_ticks_msec() * 0.003) * 0.012
		visual_model.position.y = sway
		if held_prop_mount:
			held_prop_mount.position.y = 0.72 + sway
		if briefcase_node:
			briefcase_node.position.y = 0.78 + sway
	elif visual_model:
		visual_model.position.y = 0.0
		if held_prop_mount:
			held_prop_mount.position.y = 0.72
		if briefcase_node:
			briefcase_node.position.y = 0.78

func _physics_process(delta: float) -> void:
	if life_activity != "":
		return
	# Trọng lực
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Xoay người/camera bằng bàn phím: Phím Mũi Tên [←] Quay Trái, [→] Quay Phải
	var turn_key: float = 0.0
	if Input.is_physical_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_LEFT):
		turn_key += 1.0
	if Input.is_physical_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_RIGHT):
		turn_key -= 1.0
	if turn_key != 0.0:
		rotate_y(turn_key * keyboard_turn_speed * delta)

	# Nhảy [Space]
	var is_jump = Input.is_action_just_pressed("jump") or Input.is_physical_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_SPACE)
	if is_jump and is_on_floor():
		velocity.y = jump_velocity

	# Đếm lùi buff tốc độ
	if speed_buff_timer > 0.0:
		speed_buff_timer -= delta
		if speed_buff_timer <= 0.0:
			speed_multiplier = 1.0

	# Hướng di chuyển từ Action Map
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")

	# Fallback trực tiếp phần cứng (Hỗ trợ 100% Unikey/EVKey gõ tiếng Việt Telex):
	if input_dir == Vector2.ZERO:
		var fwd: float = 0.0
		var side: float = 0.0
		# Tiến: W, Up Arrow, Z (AZERTY)
		if Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP) or Input.is_physical_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_Z):
			fwd -= 1.0
		# Lùi: S, Down Arrow
		if Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN) or Input.is_physical_key_pressed(KEY_DOWN):
			fwd += 1.0
		# Dạt Trái: A, Q (AZERTY), Left Arrow
		if Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_Q) or Input.is_key_pressed(KEY_LEFT) or Input.is_physical_key_pressed(KEY_LEFT):
			side -= 1.0
		# Dạt Phải: D, Right Arrow
		if Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT) or Input.is_physical_key_pressed(KEY_RIGHT):
			side += 1.0
		input_dir = Vector2(side, fwd).normalized()

	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var sprint_requested: bool = Input.is_action_pressed("sprint") or Input.is_physical_key_pressed(KEY_SHIFT) or Input.is_key_pressed(KEY_SHIFT)
	if sprint_exhausted and current_stamina >= max_stamina * SPRINT_RECOVERY_THRESHOLD_RATIO:
		sprint_exhausted = false
	var is_sprinting: bool = sprint_requested and direction != Vector3.ZERO and current_stamina > 0.0 and not sprint_exhausted
	if is_sprinting:
		current_stamina = maxf(0.0, current_stamina - sprint_stamina_drain_rate * delta)
		if current_stamina <= 0.0:
			sprint_exhausted = true
	else:
		var wellness_boost: float = 0.0
		var rm = get_node_or_null("/root/ResearchManager")
		if rm != null and rm.has_method("get_wellness_stamina_boost"):
			wellness_boost = rm.get_wellness_stamina_boost()
		current_stamina = minf(max_stamina, current_stamina + stamina_recovery_rate * (1.0 + wellness_boost) * delta)
	var speed: float = (sprint_speed if is_sprinting else walk_speed) * speed_multiplier

	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()
