class_name NPCCharacter
extends CharacterBody3D

# ==============================================================================
# NPC CHARACTER (TÂN THẾ GIỚI - DÂN CƯ CỐT LÕI)
# Quản lý nhân vật cư dân ngoài thực địa:
# 1. Hiển thị 3D Anime Humanoid theo đúng độ tuổi & trang phục ngành nghề
# 2. Bảng tên nổi 3D (Label3D Billboard) hiện Tên + Tuổi + Nghề nghiệp
# 3. Chuyển động vi mô (Idle animation: thở nhẹ, xoay mặt nhìn Thị trưởng)
# 4. Tương tác phím [E]: Mở Thẻ Căn Cước Hologram Tân Thế Giới
# ==============================================================================

const DailyScheduleManagerScript = preload("res://scripts/simulation/daily_schedule_manager.gd")

@export var npc_id: String = ""
@export var citizen_id: String = ""
@export var citizen_name: String = "Bác Hai"
@export var age: int = 56
@export var age_group: ModularHumanoidBuilder.AgeGroup = ModularHumanoidBuilder.AgeGroup.ELDER
@export var gender: String = "Nam"
@export var profession: ModularHumanoidBuilder.ProfessionType = ModularHumanoidBuilder.ProfessionType.FARMER
@export var job_title: String = "Nông Dân Sinh Thái"
@export var cert_code: String = "CERT_AGRI_CROPS"
@export var skill_level: int = 8
@export var harmony_score: float = 100.0
@export var vitality: float = 100.0
@export var cccd_number: String = "TTG-2026-0082"
@export var district_name: String = "Thủ Phủ Đỉnh Vát"
@export_multiline var dialogue_text: String = "Chào Thị trưởng! Đất lành chim đậu, hoa trái quanh dòng suối hôm nay ngọt lắm, ngài nếm thử nhé!"

var visual_model: Node3D
var nameplate: Label3D
var interact_area: Area3D
var player_ref: Node3D
var time_elapsed: float = 0.0

var current_activity: String = ""
var current_activity_icon: String = "🌿"
var current_slot_name: String = ""
var is_on_duty: bool = false
var schedule_pose: String = "idle"
var schedule_destination: String = "home"
var home_position: Vector3 = Vector3.ZERO
var target_position: Vector3 = Vector3.ZERO
var has_daily_schedule: bool = false
var citizen_data: CitizenData
var citizen_manager: Node
var use_lightweight_visuals: bool = false

var _arm_l: Node3D = null
var _arm_r: Node3D = null
var _last_prompt_state: int = -1
var _last_rendered_act: String = ""
var _lod_accum: float = 0.0

func _ready() -> void:
	add_to_group("citizens")
	home_position = global_position
	target_position = home_position
	
	# Thiết lập va chạm vật lý cơ bản
	collision_layer = 0
	collision_mask = 0
	floor_snap_length = 0.5
	floor_max_angle = deg_to_rad(60.0)
	floor_stop_on_slope = true
	floor_block_on_wall = true
	
	if not use_lightweight_visuals:
		var body_col = CollisionShape3D.new()
		body_col.name = "BodyCollision"
		var cap = CapsuleShape3D.new()
		cap.radius = 0.35
		cap.height = 1.6
		body_col.shape = cap
		body_col.position.y = 0.8
		body_col.disabled = true
		add_child(body_col)
	set_physics_process(false)
	
	_build_visuals()
	if visual_model:
		_arm_l = visual_model.get_node_or_null("Arm_L") as Node3D
		_arm_r = visual_model.get_node_or_null("Arm_R") as Node3D
	_build_nameplate()
	_build_interaction_area()
	citizen_manager = get_tree().get_first_node_in_group("citizen_manager")
	
	# Tìm tham chiếu đến Player
	player_ref = get_tree().get_first_node_in_group("player")
	
	# Kết nối đồng hồ thế giới cập nhật lịch trình
	var wm = get_node_or_null("/root/WorldManager")
	if wm:
		if wm.has_signal("time_ticked"):
			wm.time_ticked.connect(_on_world_time_ticked)
		update_schedule(wm.current_day_index, wm.current_hour, wm.current_minute)
	else:
		update_schedule(2, 11, 30)

func _on_world_time_ticked(day_idx: int, hr: int, min: int, _day_name: String) -> void:
	update_schedule(day_idx, hr, min)

func update_schedule(day_idx: int, hr: int, min: int) -> void:
	if has_daily_schedule:
		if citizen_data:
			if citizen_manager == null or not is_instance_valid(citizen_manager):
				citizen_manager = _resolve_citizen_manager()
			var monthly_meetup_active := false
			if citizen_manager != null and citizen_manager.has_method("is_monthly_meetup_active_for"):
				monthly_meetup_active = bool(citizen_manager.call("is_monthly_meetup_active_for", citizen_id))
			var citizen_schedule := DailyScheduleManagerScript.get_citizen_schedule(
				citizen_data.job_role,
				citizen_data.is_church_servant,
				day_idx,
				hr,
				min,
				_is_active_driver(),
				citizen_data.needs_community_support,
				monthly_meetup_active,
				citizen_data.workplace_id,
				citizen_data.servant_type,
				not citizen_data.social_connections.is_empty()
			)
			current_activity = citizen_schedule["activity"]
			current_activity_icon = citizen_schedule["slot_icon"]
			current_slot_name = citizen_schedule["slot_name"]
			schedule_pose = citizen_schedule["pose"]
			schedule_destination = citizen_schedule["destination"]
			is_on_duty = bool(citizen_schedule["is_on_duty"])
			_update_schedule_destination()
			return
	var sched = DailyScheduleManagerScript.get_npc_schedule(npc_id, citizen_name, job_title, district_name, day_idx, hr, min)
	current_activity = sched["activity"]
	current_activity_icon = sched["slot_icon"]
	current_slot_name = sched["slot_name"]
	dialogue_text = sched["dialogue"]
	is_on_duty = bool(sched.get("is_on_duty", false))
	schedule_pose = "work" if is_on_duty else "idle"

func _resolve_citizen_manager() -> Node:
	if citizen_manager != null and is_instance_valid(citizen_manager):
		return citizen_manager
	if not is_inside_tree():
		return null
	var tree = get_tree()
	if tree == null:
		return null
	citizen_manager = tree.get_first_node_in_group("citizen_manager")
	return citizen_manager

func _is_active_driver() -> bool:
	if citizen_manager == null or not is_instance_valid(citizen_manager):
		citizen_manager = _resolve_citizen_manager()
	if citizen_manager == null or not citizen_manager.has_method("is_weekly_driver"):
		return true
	return bool(citizen_manager.call("is_weekly_driver", citizen_id, citizen_data.job_role))

func configure_from_citizen(citizen: CitizenData, display_name: String = "") -> void:
	citizen_data = citizen
	citizen_id = citizen.citizen_id
	npc_id = "citizen_" + citizen.citizen_id
	citizen_name = display_name if not display_name.is_empty() else citizen.citizen_name
	age = citizen.age
	job_title = citizen.job_role
	district_name = "Thủ Phủ Đỉnh Vát"
	has_daily_schedule = true
	use_lightweight_visuals = display_name.is_empty()
	profession = _profession_for_job(citizen.job_role)
	age_group = _age_group_for_citizen(citizen.age)
	gender = "Nữ" if int(citizen.citizen_id) % 2 == 0 else "Nam"
	cccd_number = "TTG-%s" % citizen.citizen_id
	citizen_manager = _resolve_citizen_manager()
	if citizen_manager and citizen_manager.has_method("get_home_position_for"):
		home_position = citizen_manager.call("get_home_position_for", citizen_id)
		target_position = home_position

func _profession_for_job(job: String) -> ModularHumanoidBuilder.ProfessionType:
	match job:
		"Nông dân":
			return ModularHumanoidBuilder.ProfessionType.FARMER
		"Giáo viên", "Học sinh", "Sinh viên":
			return ModularHumanoidBuilder.ProfessionType.TEACHER
		"Bác sĩ", "Dược sĩ":
			return ModularHumanoidBuilder.ProfessionType.DOCTOR
		"Nhà bếp":
			return ModularHumanoidBuilder.ProfessionType.BAKER
		"Thợ mộc":
			return ModularHumanoidBuilder.ProfessionType.CARPENTER
		"Nhân viên văn phòng", "Kỹ sư", "Lái xe bus", "Lái tàu điện":
			return ModularHumanoidBuilder.ProfessionType.ENGINEER
		_:
			return ModularHumanoidBuilder.ProfessionType.CITIZEN_KID if age < 18 else ModularHumanoidBuilder.ProfessionType.ENGINEER

func _age_group_for_citizen(citizen_age: int) -> ModularHumanoidBuilder.AgeGroup:
	if citizen_age < 15:
		return ModularHumanoidBuilder.AgeGroup.CHILD
	if citizen_age < 20:
		return ModularHumanoidBuilder.AgeGroup.YOUTH
	return ModularHumanoidBuilder.AgeGroup.ADULT

func _update_schedule_destination() -> void:
	var manager_ref = citizen_manager
	if manager_ref == null or not is_instance_valid(manager_ref):
		manager_ref = get_tree().get_first_node_in_group("citizen_manager")
		citizen_manager = manager_ref
	if manager_ref != null and manager_ref.has_method("get_home_position_for") and citizen_id != "":
		match schedule_destination:
			"home":
				target_position = manager_ref.call("get_home_position_for", citizen_id)
			"rest":
				target_position = manager_ref.call("get_home_position_for", citizen_id)
			"family":
				target_position = manager_ref.call("get_home_position_for", citizen_id)
			"farm", "school", "transit", "mega_office", "logistics_depot", "gathering", "work", "leisure":
				if schedule_destination == "gathering":
					target_position = Vector3(0.0, ModularNatureChunk.get_world_height(0.0, 0.0), 0.0)
				elif schedule_destination == "leisure":
					target_position = Vector3(32.0, ModularNatureChunk.get_world_height(32.0, 42.0), 42.0)
				elif schedule_destination == "logistics_depot":
					target_position = manager_ref.call("get_workplace_position_for", citizen_id)
				else:
					target_position = manager_ref.call("get_workplace_position_for", citizen_id)
			_: 
				target_position = manager_ref.call("get_home_position_for", citizen_id)
		return

	var destination_offset := Vector3.ZERO
	var index := absi(citizen_id.hash()) % 30
	match schedule_destination:
		"farm":
			destination_offset = Vector3(45.0, 0.0, 42.0)
		"mega_office", "gathering":
			destination_offset = Vector3((float(index % 7) - 3.0) * 1.4, 0.0, (float(index / 7) - 2.0) * 1.4)
		"transit":
			destination_offset = Vector3(22.0 + float(index % 6) * 1.5, 0.0, 16.0)
		"school":
			destination_offset = Vector3(-28.0 + float(index % 5) * 1.5, 0.0, -20.0)
		"rest":
			destination_offset = Vector3((float(index % 8) - 4.0) * 1.2, 0.0, 20.0 + float(index / 8) * 1.2)
		"leisure":
			destination_offset = Vector3(16.0 + float(index % 8) * 1.4, 0.0, -14.0 + float(index / 8) * 1.4)
		"family":
			destination_offset = Vector3((float(index % 4) - 1.5) * 1.2, 0.0, (float(index / 4) - 1.5) * 1.2)
		"work":
			destination_offset = Vector3(-18.0 + float(index % 8) * 1.4, 0.0, -12.0 + float(index / 8) * 1.4)
		_:
			target_position = home_position
			return
	var point := home_position + destination_offset
	if schedule_destination == "mega_office" or schedule_destination == "gathering":
		point = destination_offset
	point.y = ModularNatureChunk.get_world_height(point.x, point.z)
	target_position = point

func _build_visuals() -> void:
	if use_lightweight_visuals:
		visual_model = _build_lightweight_visual_model()
	else:
		visual_model = ModularHumanoidBuilder.build_character_model(profession, age_group, gender)
	add_child(visual_model)

func _build_lightweight_visual_model() -> Node3D:
	var model := Node3D.new()
	model.name = "CharacterVisualModel"
	var outfit_color := Color(0.32, 0.48, 0.72)
	match profession:
		ModularHumanoidBuilder.ProfessionType.FARMER:
			outfit_color = Color(0.30, 0.50, 0.25)
		ModularHumanoidBuilder.ProfessionType.ENGINEER:
			outfit_color = Color(0.25, 0.42, 0.58)
		ModularHumanoidBuilder.ProfessionType.DOCTOR:
			outfit_color = Color(0.82, 0.90, 0.88)
		ModularHumanoidBuilder.ProfessionType.TEACHER, ModularHumanoidBuilder.ProfessionType.STUDENT:
			outfit_color = Color(0.48, 0.35, 0.58)
	var outfit := StandardMaterial3D.new()
	outfit.albedo_color = outfit_color
	var skin := StandardMaterial3D.new()
	skin.albedo_color = Color(1.0, 0.84, 0.73)
	var torso := MeshInstance3D.new()
	torso.name = "Torso"
	var torso_mesh := CapsuleMesh.new()
	torso_mesh.radius = 0.22
	torso_mesh.height = 0.72
	torso.mesh = torso_mesh
	torso.material_override = outfit
	torso.position.y = 0.95
	model.add_child(torso)
	var head_mesh_instance := MeshInstance3D.new()
	head_mesh_instance.name = "Head"
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.2
	head_mesh.height = 0.4
	head_mesh_instance.mesh = head_mesh
	head_mesh_instance.material_override = skin
	head_mesh_instance.position.y = 1.5
	model.add_child(head_mesh_instance)
	for side in [-1.0, 1.0]:
		var arm := MeshInstance3D.new()
		arm.name = "Arm_L" if side < 0.0 else "Arm_R"
		var arm_mesh := BoxMesh.new()
		arm_mesh.size = Vector3(0.13, 0.48, 0.14)
		arm.mesh = arm_mesh
		arm.material_override = outfit
		arm.position = Vector3(side * 0.28, 1.02, 0.0)
		model.add_child(arm)
	return model

func _build_nameplate() -> void:
	nameplate = Label3D.new()
	nameplate.name = "FloatingNameplate"
	nameplate.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	nameplate.no_depth_test = true
	nameplate.font_size = 22
	nameplate.outline_size = 8
	nameplate.outline_modulate = Color(0.05, 0.08, 0.14, 0.95)
	nameplate.modulate = Color(1.0, 0.95, 0.85)
	
	var height_offset: float = 1.9
	match age_group:
		ModularHumanoidBuilder.AgeGroup.CHILD:
			height_offset = 1.35
		ModularHumanoidBuilder.AgeGroup.YOUTH:
			height_offset = 1.75
		ModularHumanoidBuilder.AgeGroup.ADULT, ModularHumanoidBuilder.AgeGroup.ELDER:
			height_offset = 1.95
			
	nameplate.position = Vector3(0, height_offset, 0)
	var act_str = ("\n" + current_activity_icon + " " + current_activity) if current_activity != "" else ""
	nameplate.text = "%s (%dt)%s\n🏷️ %s" % [citizen_name, age, act_str, job_title]
	nameplate.visible = true
	add_child(nameplate)

func _build_interaction_area() -> void:
	interact_area = Area3D.new()
	interact_area.name = "InteractArea"
	interact_area.collision_layer = 1 | 2 | 4
	interact_area.collision_mask = 1 | 2 | 4
	
	var col = CollisionShape3D.new()
	col.name = "InteractCol"
	var sph = SphereShape3D.new()
	sph.radius = 6.0
	col.shape = sph
	col.position.y = 0.8
	interact_area.add_child(col)
	add_child(interact_area)
	
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	if player_ref == null or not is_instance_valid(player_ref):
		player_ref = get_tree().get_first_node_in_group("player")

	var dist: float = 9999.0
	if player_ref and is_instance_valid(player_ref):
		dist = global_position.distance_to(player_ref.global_position)

	# Tier 3 (dist > 220m): Ẩn visual 3D để giải phóng GPU/CPU cho Intel Iris Xe
	if dist > 220.0:
		if visible:
			visible = false
		_lod_accum += delta
		if _lod_accum < 1.0:
			return
		_lod_accum = 0.0
		if has_daily_schedule:
			_move_to_schedule_target(1.0)
		return
	else:
		if not visible:
			visible = true

	time_elapsed += delta
	if has_daily_schedule:
		_move_to_schedule_target(delta)

	# 1. Micro-animation: Nhịp thở nhấp nhô nhẹ nhàng (chỉ chạy khi cự ly gần <= 45m)
	if visual_model and dist <= 45.0:
		var visual_pose := schedule_pose
		var planar_distance := Vector2(global_position.x, global_position.z).distance_to(
			Vector2(target_position.x, target_position.z)
		)
		if planar_distance > 0.45 and (visual_pose == "sleep" or visual_pose == "sit"):
			visual_pose = "idle"
		var breath = sin(time_elapsed * 2.2) * 0.012
		var pose_offset := -0.22 if visual_pose == "sit" else (-0.35 if visual_pose == "sleep" else 0.0)
		visual_model.position.y = breath + pose_offset
		var target_pose_rotation := -PI * 0.5 if visual_pose == "sleep" else 0.0
		visual_model.rotation.x = lerp_angle(visual_model.rotation.x, target_pose_rotation, delta * 2.0)
		_apply_activity_animation(visual_pose)

	# 2. Xoay người nhìn theo Thị Trưởng & Quản lý Nameplate tối ưu
	if player_ref and is_instance_valid(player_ref):
		if interact_area:
			interact_area.monitoring = dist <= 8.0
		if nameplate:
			var should_show_nameplate: bool = (dist <= 40.0)
			if nameplate.visible != should_show_nameplate:
				nameplate.visible = should_show_nameplate

			if should_show_nameplate:
				var prompt_state: int = 1 if dist <= 6.0 else 0
				var act_str = ("\n" + current_activity_icon + " " + current_activity) if current_activity != "" else ""
				if prompt_state != _last_prompt_state or act_str != _last_rendered_act:
					_last_prompt_state = prompt_state
					_last_rendered_act = act_str
					if prompt_state == 1:
						nameplate.text = "✨ %s (%dt)%s\n🏷️ %s\n💬 [E] Trò Chuyện & Quyết Sách" % [citizen_name, age, act_str, job_title]
						nameplate.modulate = Color(1.0, 0.90, 0.3)
					else:
						nameplate.text = "%s (%dt)%s\n🏷️ %s" % [citizen_name, age, act_str, job_title]
						nameplate.modulate = Color(1.0, 0.95, 0.85)

				if prompt_state == 1:
					var nearby_npc = player_ref.get_meta("nearby_npc") if player_ref.has_meta("nearby_npc") else null
					if nearby_npc == null or not is_instance_valid(nearby_npc) or global_position.distance_squared_to(player_ref.global_position) < nearby_npc.global_position.distance_squared_to(player_ref.global_position):
						player_ref.set_meta("nearby_npc", self)

					# Quay mặt về phía người chơi mượt mà
					var look_target = player_ref.global_position
					look_target.y = global_position.y
					var target_rot_y = (look_target - global_position).normalized()
					if target_rot_y.length_squared() > 0.01:
						var desired_basis = Basis.looking_at(target_rot_y, Vector3.UP)
						basis = basis.orthonormalized().slerp(desired_basis.orthonormalized(), delta * 3.5)
				else:
					if player_ref.has_meta("nearby_npc") and player_ref.get_meta("nearby_npc") == self:
						player_ref.remove_meta("nearby_npc")
	elif interact_area:
		interact_area.monitoring = false
		if nameplate:
			nameplate.visible = false

func _move_to_schedule_target(delta: float) -> void:
	if not has_daily_schedule:
		return
	var current_planar := Vector2(global_position.x, global_position.z)
	var target_planar := Vector2(target_position.x, target_position.z)
	var planar_movement := target_planar - current_planar
	if planar_movement.length() <= 0.45:
		global_position.x = target_position.x
		global_position.z = target_position.z
		global_position.y = ModularNatureChunk.get_world_height(global_position.x, global_position.z)
		return

	var direction := planar_movement.normalized()
	var next_planar := current_planar.move_toward(target_planar, 1.6 * delta)
	global_position.x = next_planar.x
	global_position.z = next_planar.y
	global_position.y = ModularNatureChunk.get_world_height(global_position.x, global_position.z)
	rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.y), delta * 2.0)

func _apply_activity_animation(pose: String = "") -> void:
	if visual_model == null:
		return
	if _arm_l == null or _arm_r == null:
		_arm_l = visual_model.get_node_or_null("Arm_L") as Node3D
		_arm_r = visual_model.get_node_or_null("Arm_R") as Node3D
	var active_pose := pose if not pose.is_empty() else schedule_pose
	var left_angle := 0.0
	var right_angle := 0.0
	match active_pose:
		"work":
			left_angle = sin(time_elapsed * 3.2) * 0.22
			right_angle = sin(time_elapsed * 3.2 + PI) * 0.28
		"drive":
			left_angle = -0.25 + sin(time_elapsed * 1.4) * 0.04
			right_angle = -0.25 + sin(time_elapsed * 1.4 + PI) * 0.04
		"sit":
			left_angle = -0.35
			right_angle = -0.35
		"sleep":
			left_angle = 0.2 + sin(time_elapsed * 1.1) * 0.03
			right_angle = -0.2 + sin(time_elapsed * 1.1 + PI) * 0.03
		"social":
			left_angle = sin(time_elapsed * 1.8) * 0.16
			right_angle = cos(time_elapsed * 1.8) * 0.18
	if _arm_l:
		_arm_l.rotation.x = left_angle
	if _arm_r:
		_arm_r.rotation.x = right_angle

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		body.set_meta("nearby_npc", self)

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		if body.has_meta("nearby_npc") and body.get_meta("nearby_npc") == self:
			body.remove_meta("nearby_npc")

func trigger_interaction() -> void:
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("open_npc_dialogue"):
		hud.open_npc_dialogue(self)
	elif hud and hud.has_method("open_citizen_id_card"):
		hud.open_citizen_id_card(self)
	else:
		print("[NPC] 💬 %s: \"%s\"" % [citizen_name, dialogue_text])
