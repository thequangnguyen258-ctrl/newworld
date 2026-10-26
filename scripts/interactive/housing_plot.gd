class_name HousingPlot
extends Node3D

# ==============================================================================
# HOUSING PLOT - LÔ ĐẤT QUY HOẠCH & DỰ ÁN NHÀ MẪU TÂN THẾ GIỚI
# Quản lý 3 trạng thái chuyển hóa thực địa:
# 1. STATUS_AVAILABLE: Lô đất mở bán / làm mẫu (Cọc mốc, ruy băng phát sáng, Hologram Blueprint)
# 2. STATUS_CONSTRUCTION: Đang thi công (Giàn giáo gỗ, vật tư gạch đá, búa đục gõ nhịp nhàng)
# 3. STATUS_COMPLETED: Ngôi nhà 3D hoàn thiện (Tường kem, mái ngói Toon, đèn hiên ấm, cửa mở)
# ==============================================================================

const AudioSynthesizerScript = preload("res://scripts/core/audio_synthesizer.gd")

enum PlotStatus {
	AVAILABLE,
	CONSTRUCTION,
	COMPLETED
}

@export var plot_id: String = "plot_01"
@export var district_id: String = "DISTRICT_PLATEAU_CORE"
@export var house_type: String = "STUDIO_APARTMENT"
@export var title: String = "Chung Cư Studio Anime"
@export var price: float = 1500.0
@export var area_sqm: float = 85.0
@export var current_status: PlotStatus = PlotStatus.AVAILABLE
@export var owner_name: String = ""
@export var interaction_radius: float = 6.0
@export var land_deed_number: String = ""
@export var construction_progress: float = 0.0

# Node trực quan theo từng trạng thái
var blueprint_node: Node3D = null
var construction_node: Node3D = null
var completed_node: Node3D = null
var door_hinge_pivot: Node3D = null

# Thành phần tương tác
var interaction_area: Area3D = null
var prompt_3d: Label3D = null
var is_player_nearby: bool = false
var is_door_open: bool = false

func _ready() -> void:
	add_to_group("housing_plots")
	add_to_group("interactive_stations")
	
	if land_deed_number.is_empty():
		land_deed_number = "SO_DO_TTG_" + plot_id.to_upper().replace("PLOT_", "") + "_2026"
		
	if current_status == PlotStatus.COMPLETED:
		construction_progress = 100.0
	elif current_status == PlotStatus.CONSTRUCTION and construction_progress <= 0.0:
		construction_progress = 50.0
	
	_load_from_database()
	_setup_interaction_components()
	_update_visual_state()
	_sync_with_database()

func get_save_state() -> Dictionary:
	var status := "AVAILABLE"
	match current_status:
		PlotStatus.CONSTRUCTION:
			status = "CONSTRUCTION"
		PlotStatus.COMPLETED:
			status = "COMPLETED"
	return {
		"plot_id": plot_id,
		"status": status,
		"owner_name": owner_name,
		"land_deed_number": land_deed_number,
		"construction_progress": construction_progress,
		"position": [global_position.x, global_position.y, global_position.z]
	}

func validate_saved_state(state: Dictionary) -> bool:
	if str(state.get("plot_id", "")) != plot_id:
		return false
	if not ["AVAILABLE", "CONSTRUCTION", "COMPLETED"].has(state.get("status", "")):
		return false
	if not state.get("owner_name", "") is String or not state.get("land_deed_number", "") is String:
		return false
	if not (state.get("construction_progress") is int or state.get("construction_progress") is float):
		return false
	if not _is_finite_vector(state.get("position")):
		return false
	var progress := float(state["construction_progress"])
	return is_finite(progress) and progress >= 0.0 and progress <= 100.0

func apply_saved_state(state: Dictionary) -> bool:
	if not validate_saved_state(state):
		return false
	match state["status"]:
		"AVAILABLE":
			current_status = PlotStatus.AVAILABLE
		"CONSTRUCTION":
			current_status = PlotStatus.CONSTRUCTION
		"COMPLETED":
			current_status = PlotStatus.COMPLETED
	owner_name = state["owner_name"]
	land_deed_number = state["land_deed_number"]
	construction_progress = float(state["construction_progress"])
	var saved_position: Array = state["position"]
	global_position = Vector3(float(saved_position[0]), float(saved_position[1]), float(saved_position[2]))
	_update_visual_state()
	_update_prompt_text()
	_sync_with_database()
	return true

func _load_from_database() -> void:
	var database_manager := get_node_or_null("/root/DatabaseManager")
	if database_manager == null or not database_manager.has_method("get_housing_plot"):
		return
	var saved_plot: Dictionary = database_manager.get_housing_plot(plot_id)
	if saved_plot.is_empty():
		return
	match str(saved_plot.get("status", "")):
		"AVAILABLE":
			current_status = PlotStatus.AVAILABLE
		"UNDER_CONSTRUCTION":
			current_status = PlotStatus.CONSTRUCTION
		"COMPLETED", "OCCUPIED":
			current_status = PlotStatus.COMPLETED
		_:
			push_warning("[HousingPlot] Trạng thái lưu không hợp lệ cho lô %s." % plot_id)
			return
	owner_name = str(saved_plot.get("owner_id", owner_name))
	land_deed_number = str(saved_plot.get("land_deed_number", land_deed_number))
	construction_progress = clampf(float(saved_plot.get("construction_progress", construction_progress)), 0.0, 100.0)
	global_position = Vector3(
		float(saved_plot.get("pos_x", global_position.x)),
		float(saved_plot.get("pos_y", global_position.y)),
		float(saved_plot.get("pos_z", global_position.z))
	)

func _is_finite_vector(value: Variant) -> bool:
	if not value is Array or value.size() != 3:
		return false
	for component in value:
		if not (component is int or component is float) or not is_finite(float(component)):
			return false
	return true

func _setup_interaction_components() -> void:
	# 1. Vùng cảm biến Area3D với bảo hiểm 2 lớp
	interaction_area = Area3D.new()
	interaction_area.name = "PlotInteractionArea"
	interaction_area.collision_layer = 1 | 2 | 4
	interaction_area.collision_mask = 1 | 2 | 4
	
	var col = CollisionShape3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = interaction_radius
	col.shape = sphere
	col.position = Vector3(0, 1.2, 0)
	interaction_area.add_child(col)
	add_child(interaction_area)
	
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)
	
	# 2. Bảng chữ 3D Diegetic xuyên thấu
	prompt_3d = Label3D.new()
	prompt_3d.name = "PlotPrompt3D"
	prompt_3d.font_size = 32
	prompt_3d.outline_size = 8
	prompt_3d.outline_modulate = Color(0.06, 0.08, 0.14, 0.95)
	prompt_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	prompt_3d.no_depth_test = true
	prompt_3d.position = Vector3(0, 3.8, 0)
	prompt_3d.visible = false
	add_child(prompt_3d)

func _process(delta: float) -> void:
	# Fallback kiểm tra cự ly người chơi đảm bảo 100% tương tác được
	var player = get_tree().get_first_node_in_group("player")
	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		var in_range = (dist <= interaction_radius)
		
		if in_range != is_player_nearby:
			is_player_nearby = in_range
			if is_player_nearby:
				_update_prompt_text()
				prompt_3d.visible = true
				player.set_meta("nearby_interactive", self)
			else:
				prompt_3d.visible = false
				if player.has_meta("nearby_interactive") and player.get_meta("nearby_interactive") == self:
					player.remove_meta("nearby_interactive")

	# Hiệu ứng xoay nhẹ và nhấp nhô Toon cho Blueprint Hologram khi đang mở bán
	if current_status == PlotStatus.AVAILABLE and blueprint_node and is_instance_valid(blueprint_node):
		var holo_preview = blueprint_node.get_node_or_null("HoloPreview")
		if holo_preview:
			holo_preview.rotate_y(0.6 * delta)
			holo_preview.position.y = 1.8 + sin(Time.get_ticks_msec() * 0.003) * 0.15

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		is_player_nearby = true
		_update_prompt_text()
		prompt_3d.visible = true
		body.set_meta("nearby_interactive", self)

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		is_player_nearby = false
		prompt_3d.visible = false
		if body.has_meta("nearby_interactive") and body.get_meta("nearby_interactive") == self:
			body.remove_meta("nearby_interactive")

func _unhandled_input(event: InputEvent) -> void:
	if not is_player_nearby:
		return
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		var key = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		if key == KEY_E or key == KEY_F:
			var player = get_tree().get_first_node_in_group("player")
			if player and (not player.has_meta("nearby_interactive") or player.get_meta("nearby_interactive") == self):
				interact(player)
				get_viewport().set_input_as_handled()

func _update_prompt_text() -> void:
	if not prompt_3d:
		return
		
	match current_status:
		PlotStatus.AVAILABLE:
			prompt_3d.text = "🏡 [E] MUA ĐẤT & THI CÔNG: %s\n(Diện tích: %.0fm² | Đơn giá trọn gói: %d Đ | Sổ Đỏ: %s)" % [title, area_sqm, int(price), land_deed_number]
			prompt_3d.modulate = Color(1.0, 0.88, 0.25)
		PlotStatus.CONSTRUCTION:
			prompt_3d.text = "🏗️ [E] NGHIỆM THU & BÀN GIAO: %s\n(Sổ Đỏ: %s | Thợ mộc đang hoàn thiện nội thất)" % [title, land_deed_number]
			prompt_3d.modulate = Color(0.4, 0.85, 1.0)
		PlotStatus.COMPLETED:
			var owner_str = owner_name if not owner_name.is_empty() else "Thị Trưởng"
			prompt_3d.text = "✨ [E] VÀO NHÀ NGHỈ NGƠI: %s\n(Gia chủ: %s | Sổ Đỏ: %s | Nhấn [E] để mở cửa)" % [title, owner_str, land_deed_number]
			prompt_3d.modulate = Color(0.35, 0.95, 0.55)

func _update_visual_state() -> void:
	# Dọn sạch các node cũ nếu có
	if blueprint_node:
		blueprint_node.queue_free()
		blueprint_node = null
	if construction_node:
		construction_node.queue_free()
		construction_node = null
	if completed_node:
		completed_node.queue_free()
		completed_node = null

	var builder = load("res://scripts/terrain/model_house_builder.gd")
	if not builder:
		push_error("[HousingPlot] Không thể load model_house_builder.gd")
		return

	match current_status:
		PlotStatus.AVAILABLE:
			blueprint_node = builder.build_plot_blueprint(house_type, area_sqm)
			add_child(blueprint_node)
		PlotStatus.CONSTRUCTION:
			construction_node = builder.build_construction_site(house_type, area_sqm)
			add_child(construction_node)
		PlotStatus.COMPLETED:
			completed_node = builder.build_completed_house(house_type)
			add_child(completed_node)
			door_hinge_pivot = completed_node.get_node_or_null("DoorHingePivot")

	_update_prompt_text()

## Hàm tương tác chuẩn khi người chơi nhấn [E]
func interact(player: Node3D) -> void:
	var wm = get_node_or_null("/root/WorldManager")
	var hud = get_tree().get_first_node_in_group("hud")
	
	match current_status:
		PlotStatus.AVAILABLE:
			# Kiểm tra tài chính: Thị trưởng dùng ngân sách đô thị hoặc quỹ cá nhân
			if wm and wm.treasury_city < price:
				if hud and hud.has_method("show_toast"):
					hud.show_toast("⚠️ Ngân khố không đủ %d Đ để mua đất và ký hợp đồng thi công!" % int(price))
				AudioSynthesizerScript.play_sound(self, "horn")
				return

			# Trừ tiền ngân khố
			if wm:
				wm.withdraw_city_tax(price)
			
			owner_name = "Thị Trưởng"
			current_status = PlotStatus.COMPLETED # Hoàn thành nghiệm thu ngay cho Thị Trưởng
			construction_progress = 100.0
			_update_visual_state()
			
			AudioSynthesizerScript.play_sound(self, "fanfare")
			
			if hud and hud.has_method("show_toast"):
				hud.show_toast("🎉 KÝ HỢP ĐỒNG THÀNH CÔNG! Đã mua và hoàn thiện '%s' (Số nhà: %s) [Sổ Đỏ: %s]!" % [title, plot_id, land_deed_number], 5.0)
				
			# Đánh dấu nhiệm vụ sở hữu nhà trong Quest Tracker nếu có
			if hud and hud.has_method("mark_quest_done"):
				hud.mark_quest_done("quest_buy_house")
				
			_sync_with_database()
			print("[HousingPlot] 🏡 Đã mua và hoàn thiện ngôi nhà mẫu %s tại %s [Sổ Đỏ: %s]" % [plot_id, global_position, land_deed_number])

		PlotStatus.CONSTRUCTION:
			current_status = PlotStatus.COMPLETED
			construction_progress = 100.0
			_update_visual_state()
			AudioSynthesizerScript.play_sound(self, "fanfare")
			if hud and hud.has_method("show_toast"):
				hud.show_toast("✨ NGHIỆM THU CÔNG TRÌNH: '%s' đã chính thức khánh thành và bàn giao [Sổ Đỏ: %s]!" % [title, land_deed_number], 4.5)
			_sync_with_database()

		PlotStatus.COMPLETED:
			# Bước vào nhà: Mở/đóng cửa và hồi phục 100% sinh lực
			is_door_open = not is_door_open
			if door_hinge_pivot:
				var target_rot_y = deg_to_rad(-85.0) if is_door_open else 0.0
				var tween = create_tween()
				tween.tween_property(door_hinge_pivot, "rotation:y", target_rot_y, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				
			AudioSynthesizerScript.play_sound(self, "bell")
			
			if player and player.has_method("heal"):
				player.heal(100.0)
				
			if hud and hud.has_method("show_toast"):
				if is_door_open:
					hud.show_toast("🏠 CHÀO MỪNG VỀ NHÀ! Ngôi nhà ấm cúng giúp bạn hồi phục 100% HP & Thể lực!", 3.8)
				else:
					hud.show_toast("🚪 Đã đóng cửa nhà an toàn.", 2.0)

## Đồng bộ dữ liệu thường trực vào SQLite DatabaseManager
func _sync_with_database() -> void:
	var db_mgr = get_node_or_null("/root/DatabaseManager")
	if db_mgr and db_mgr.has_method("save_housing_plot"):
		var status_str = "AVAILABLE"
		match current_status:
			PlotStatus.AVAILABLE: status_str = "AVAILABLE"
			PlotStatus.CONSTRUCTION: status_str = "UNDER_CONSTRUCTION"
			PlotStatus.COMPLETED: status_str = "COMPLETED"
			
		var data = {
			"plot_id": plot_id,
			"district_id": district_id,
			"house_type": house_type,
			"title": title,
			"status": status_str,
			"owner_id": owner_name,
			"price": price,
			"area_sqm": area_sqm,
			"pos_x": global_position.x,
			"pos_y": global_position.y,
			"pos_z": global_position.z,
			"land_deed_number": land_deed_number,
			"construction_progress": construction_progress
		}
		db_mgr.save_housing_plot(data)
