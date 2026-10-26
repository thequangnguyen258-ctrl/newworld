@tool
class_name InteractiveStation
extends Node3D

# ==============================================================================
# INTERACTIVE STATION - ĐIỂM TƯƠNG TÁC ĐÔ THỊ TÂN THẾ GIỚI
# Tuân thủ nghiêm ngặt:
# 1. RULE: END_TO_END_INTERACTION_TESTING_STANDARD
# 2. RULE: INTERACTIVE_OBJECT_DUAL_LAYER_SAFETY (Layer 1|2|4, fallback distance)
# 3. RULE: DIEGETIC_UI_PROMPT_VISIBILITY_STANDARD (Billboard, no_depth_test, outline)
# ==============================================================================

signal station_interacted(station_id: String, player: Node3D)

enum StationType {
	FOUNTAIN,     # Đài Phun Nước Ước Nguyện
	BAKERY,       # Tiệm Bánh Mì Bác Nam
	CLINIC,       # Trạm Xá Sinh Thái Chị Mai
	BELL,         # Dây Rung Chuông Hòa Bình
	DESK,         # Bàn Làm Việc Sắc Lệnh Thị Trưởng
	BED,          # Giường Ngủ Hoàng Gia (Night Skip)
	PETITIONS,    # Bảng Tin Nguyện Vọng Cư Dân
	EAST_WHEAT,   # Trạm Thu Hoạch Lúa Mì Huyện Đông
	NORTH_HERB,   # Trạm Thu Hái Thảo Dược Onsen Huyện Bắc
	WEST_POWER,   # Trạm Năng Lượng Điện Gió Huyện Tây
	SOUTH_PORT,   # Trạm Cầu Cảng & Hải Sản Huyện Nam
	TRAM_STOP,    # Ga Tram Trung Tâm
	METRO_ACCESS, # Lối chuyển tầng ga Metro ngầm
	METRO_PLATFORM # Sân ga lên/xuống tàu Metro
}

const DailyScheduleManagerScript = preload("res://scripts/simulation/daily_schedule_manager.gd")

@export var station_type: StationType = StationType.FOUNTAIN
@export var station_id: String = "fountain"
@export var title_name: String = "Đài Phun Nước Ước Nguyện"
@export var prompt_text: String = "🪙 [E] Thả Đồng Xu Ước Nguyện (Cầu Chúc An Lành)"
@export var interaction_radius: float = 3.6

var area: Area3D
var prompt_label: Label3D
var player_in_range: bool = false
var player_ref: Node3D = null
var interaction_count: int = 0

func _ready() -> void:
	add_to_group("interactive_stations")
	_setup_interaction_area()
	_setup_prompt_label()
	var wm = get_node_or_null("/root/WorldManager")
	if wm and wm.has_signal("time_ticked"):
		wm.time_ticked.connect(_on_world_time_ticked)
	_refresh_facility_schedule()

func _setup_interaction_area() -> void:
	area = Area3D.new()
	area.name = "StationArea"
	area.collision_layer = 1 | 2 | 4
	area.collision_mask = 1 | 2 | 4
	
	var col = CollisionShape3D.new()
	var sph = SphereShape3D.new()
	sph.radius = interaction_radius
	col.shape = sph
	col.position.y = 1.0
	area.add_child(col)
	add_child(area)
	
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

func _setup_prompt_label() -> void:
	prompt_label = Label3D.new()
	prompt_label.name = "PromptLabel3D"
	prompt_label.text = prompt_text
	prompt_label.font_size = 28
	prompt_label.outline_size = 8
	prompt_label.outline_modulate = Color(0.05, 0.08, 0.14, 0.95)
	prompt_label.modulate = Color(1.0, 0.90, 0.3)
	prompt_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	prompt_label.no_depth_test = true
	prompt_label.position = Vector3(0.0, 2.2, 0.0)
	prompt_label.visible = false
	add_child(prompt_label)

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	# Fallback an toàn đo khoảng cách trực tiếp (Dual-Layer Safety)
	if player_ref == null or not is_instance_valid(player_ref):
		player_ref = get_tree().get_first_node_in_group("player")
		
	if player_ref and is_instance_valid(player_ref):
		var dist = global_position.distance_to(player_ref.global_position)
		var should_be_in_range = dist <= interaction_radius
		if should_be_in_range != player_in_range:
			player_in_range = should_be_in_range
			prompt_label.visible = player_in_range
			if player_in_range:
				player_ref.set_meta("nearby_interactive", self)
			else:
				if player_ref.has_meta("nearby_interactive") and player_ref.get_meta("nearby_interactive") == self:
					player_ref.remove_meta("nearby_interactive")

func _on_world_time_ticked(day_index: int, hour: int, minute: int, _day_name: String) -> void:
	_refresh_facility_schedule(day_index, hour, minute)

func _get_facility_schedule(day_index: int = -1, hour: int = -1, minute: int = -1) -> Dictionary:
	var wm = get_node_or_null("/root/WorldManager")
	if day_index < 0:
		day_index = int(wm.current_day_index) if wm else 0
	if hour < 0:
		hour = int(wm.current_hour) if wm else 11
	if minute < 0:
		minute = int(wm.current_minute) if wm else 0
	return DailyScheduleManagerScript.get_facility_schedule(station_id, day_index, hour, minute)

func _refresh_facility_schedule(day_index: int = -1, hour: int = -1, minute: int = -1) -> void:
	if prompt_label == null:
		return
	var schedule := _get_facility_schedule(day_index, hour, minute)
	if not bool(schedule.get("is_tracked", false)):
		return
	var attendant_name := String(schedule.get("attendant_name", ""))
	var attendant_activity := ""
	var attendant_id := String(schedule.get("attendant_id", ""))
	for citizen in get_tree().get_nodes_in_group("citizens"):
		if citizen.get("npc_id") == attendant_id:
			attendant_activity = String(citizen.get("current_activity"))
			break
	var attendant_status := attendant_name
	if not attendant_activity.is_empty():
		attendant_status += " • " + attendant_activity
	if bool(schedule.get("is_open", false)):
		prompt_label.text = "%s\n🟢 Đang phục vụ: %s" % [prompt_text, attendant_status]
	else:
		prompt_label.text = "%s\n🔴 Đóng cửa theo lịch • %s" % [prompt_text, attendant_name]

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		player_ref = body
		prompt_label.visible = true
		body.set_meta("nearby_interactive", self)

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		prompt_label.visible = false
		if body.has_meta("nearby_interactive") and body.get_meta("nearby_interactive") == self:
			body.remove_meta("nearby_interactive")

func interact(player: Node3D) -> void:
	var service_schedule := _get_facility_schedule()
	if bool(service_schedule.get("is_tracked", false)) and not bool(service_schedule.get("is_open", false)):
		var hud = get_tree().get_first_node_in_group("hud")
		var attendant_name := String(service_schedule.get("attendant_name", "Nhân viên"))
		var slot_name := String(service_schedule.get("slot_name", "ngoài giờ phục vụ"))
		if hud and hud.has_method("show_toast"):
			hud.show_toast("🔒 %s đang đóng cửa theo lịch %s. %s hiện chưa phục vụ." % [title_name, slot_name, attendant_name])
		return

	interaction_count += 1
	var hud = get_tree().get_first_node_in_group("hud")
	var wm = get_node_or_null("/root/WorldManager")
	
	match station_type:
		StationType.FOUNTAIN:
			if wm:
				wm.deposit_city_tax(100.0)
			if hud and hud.has_method("show_toast"):
				hud.show_toast("🪙 Bạn đã thả đồng xu vào Đài Phun Nước! Toàn thành được chúc phước, cư dân hân hoan (+100Đ)!")
			if hud and hud.has_method("mark_quest_done"):
				hud.mark_quest_done("quest_fountain")
				
		StationType.BAKERY:
			if hud and hud.has_method("show_toast"):
				hud.show_toast("🥖 Bác Nam trao bạn ổ bánh mì baguette nóng hổi! Mùi lúa mì thơm ngào ngạt (+50 Sinh Lực)!")
			if hud and hud.has_method("mark_quest_done"):
				hud.mark_quest_done("quest_bakery")
				
		StationType.CLINIC:
			if hud and hud.has_method("show_toast"):
				hud.show_toast("🌿 Chị Mai chăm sóc và mời bạn một tách trà thảo mộc! Toàn bộ mệt mỏi tiêu tan (+100% Sinh Lực)!")
			if hud and hud.has_method("mark_quest_done"):
				hud.mark_quest_done("quest_clinic")
				
		StationType.BELL:
			if wm:
				wm.trigger_bell_ringing()
			if hud and hud.has_method("show_toast"):
				hud.show_toast("🔔 CHUÔNG HÒA BÌNH NGÂN VANG! Lời chúc lành và thánh nhạc vang vọng khắp 500 km²!")
			if hud and hud.has_method("mark_quest_done"):
				hud.mark_quest_done("quest_bell")
				
		StationType.DESK:
			if station_id == "desk":
				if hud and hud.has_method("open_life_activity_options"):
					var desk_options: Array[Dictionary] = [
						{"text": "🪑 Ngồi làm việc", "action": "desk_sit"},
						{"text": "📋 Ký sắc lệnh an sinh", "action": "desk_sign"},
						{"text": "Để sau", "action": "cancel"}
					]
					hud.open_life_activity_options(
						"🏛️ Bàn làm việc Thị trưởng",
						"Bạn muốn ngồi làm việc hay ký ban hành sắc lệnh?",
						desk_options,
						player,
						self
					)
				else:
					push_error("[InteractiveStation] HUD không khả dụng để mở lựa chọn bàn làm việc.")
			elif station_id == "elevator_ground":
				var top_st = get_tree().root.find_child("StationElevatorTop", true, false)
				if top_st:
					player.global_position = top_st.global_position + Vector3(0.0, 0.8, 2.5)
				else:
					player.global_position.y += 330.0
				if "velocity" in player:
					player.velocity = Vector3.ZERO
				var audio_synth = get_node_or_null("/root/AudioSynthesizer")
				if audio_synth and audio_synth.has_method("play_bell_sound"):
					audio_synth.play_bell_sound(player)
				if hud and hud.has_method("show_toast"):
					hud.show_toast("🛗 [Thang Máy Kính] Vút lên Sân Thượng Skydeck & Penthouse (+330M)!")
			elif station_id == "elevator_top":
				var g_st = get_tree().root.find_child("StationElevatorG", true, false)
				if g_st:
					player.global_position = g_st.global_position + Vector3(0.0, 0.8, 2.5)
				else:
					player.global_position.y -= 330.0
				if "velocity" in player:
					player.velocity = Vector3.ZERO
				var audio_synth = get_node_or_null("/root/AudioSynthesizer")
				if audio_synth and audio_synth.has_method("play_bell_sound"):
					audio_synth.play_bell_sound(player)
				if hud and hud.has_method("show_toast"):
					hud.show_toast("🛗 [Thang Máy Kính] Đã hạ xuống Đại Sảnh Tầng 1 Mega Office!")
			elif station_id == "elevator_b1":
				var g_st = get_tree().root.find_child("StationElevatorG", true, false)
				if g_st:
					player.global_position = g_st.global_position + Vector3(0.0, 0.4, 2.5)
				else:
					player.global_position.y += 8.0
				if "velocity" in player:
					player.velocity = Vector3.ZERO
				var audio_synth = get_node_or_null("/root/AudioSynthesizer")
				if audio_synth and audio_synth.has_method("play_bell_sound"):
					audio_synth.play_bell_sound(player)
				if hud and hud.has_method("show_toast"):
					hud.show_toast("🛗 [Thang Máy Kính] Đã lên Đại Sảnh Cẩm Thạch Tầng 1!")
			elif station_id == "elevator_bridge":
				var bridge_st = get_tree().root.find_child("StationElevatorBridge", true, false)
				if bridge_st and player.global_position.distance_to(bridge_st.global_position) > 4.0:
					player.global_position = bridge_st.global_position + Vector3(0.0, 0.4, 2.5)
				else:
					var g_st = get_tree().root.find_child("StationElevatorG", true, false)
					if g_st:
						player.global_position = g_st.global_position + Vector3(0.0, 0.4, 2.5)
				if "velocity" in player:
					player.velocity = Vector3.ZERO
				var audio_synth = get_node_or_null("/root/AudioSynthesizer")
				if audio_synth and audio_synth.has_method("play_bell_sound"):
					audio_synth.play_bell_sound(player)
				if hud and hud.has_method("show_toast"):
					hud.show_toast("🛗 [Thang Máy Kính] Di chuyển giữa Sảnh Tầng 1 ⇄ Cầu Kính Skybridge (+35M)!")
			elif station_id == "elevator_garden":
				var garden_st = get_tree().root.find_child("StationElevatorGarden", true, false)
				if garden_st and player.global_position.distance_to(garden_st.global_position) > 4.0:
					player.global_position = garden_st.global_position + Vector3(0.0, 0.4, 2.5)
				else:
					var g_st = get_tree().root.find_child("StationElevatorG", true, false)
					if g_st:
						player.global_position = g_st.global_position + Vector3(0.0, 0.4, 2.5)
				if "velocity" in player:
					player.velocity = Vector3.ZERO
				var audio_synth = get_node_or_null("/root/AudioSynthesizer")
				if audio_synth and audio_synth.has_method("play_bell_sound"):
					audio_synth.play_bell_sound(player)
				if hud and hud.has_method("show_toast"):
					hud.show_toast("🛗 [Thang Máy Kính] Vút lên Tầng 28 Sky Garden & Quán Cà Phê Ngắm Mây (+115M)!")
			elif station_id == "desk_civic_counter":
				if wm:
					wm.deposit_city_tax(500.0)
				if hud and hud.has_method("show_toast"):
					hud.show_toast("📋 [Quầy Dịch Vụ Công Một Cửa] Tiếp nhận hồ sơ cư dân & kích hoạt thủ tục 5 bước!")
				if hud and hud.has_method("mark_quest_done"):
					hud.mark_quest_done("quest_desk")
			elif station_id == "desk_liturgy_altar" or station_id == "desk_sanctuary_liturgy":
				if wm:
					wm.deposit_church_tithe(1000.0)
				var audio_synth = get_node_or_null("/root/AudioSynthesizer")
				if audio_synth and audio_synth.has_method("play_bell_sound"):
					audio_synth.play_bell_sound(player)
				if hud and hud.has_method("show_toast"):
					hud.show_toast("🕊️ [Đại Hội Lễ Tôn Giáo & Thánh Đường] Cử hành Thánh Lễ phụng vụ và ban phước lành toàn đô thị!")
			elif station_id == "desk_cloud_cafe" or station_id == "station_cloud_cafe":
				if "health" in player:
					player.health = 100.0
				var audio_synth = get_node_or_null("/root/AudioSynthesizer")
				if audio_synth and audio_synth.has_method("play_fanfare_sound"):
					audio_synth.play_fanfare_sound(player)
				if hud and hud.has_method("show_toast"):
					hud.show_toast("☕ [Cloud Cafe Skydeck] Thưởng thức cà phê ngắm mây ở độ cao +130m, hồi phục 100% sinh lực!")
			else:
				if wm:
					wm.deposit_city_tax(5000.0)
					wm.deposit_church_tithe(2500.0)
				if hud and hud.has_method("show_toast"):
					hud.show_toast("📋 Sắc lệnh Thị trưởng ban hành thành công! Ngân khố cấp 5.000Đ phát triển an sinh đô thị!")
				if hud and hud.has_method("mark_quest_done"):
					hud.mark_quest_done("quest_desk")
				
		StationType.BED:
			if hud and hud.has_method("open_life_activity_options"):
				var options: Array[Dictionary] = [
					{"text": "🛏️ Nằm nghỉ một chút (không tua giờ)", "action": "bed_lie"}
				]
				if wm and wm.has_method("skip_night_to_morning") and DailyScheduleManagerScript.get_time_slot(wm.current_hour, wm.current_minute) == DailyScheduleManagerScript.TimeSlot.NIGHT_REST:
					options.append({"text": "🌙 Ngủ qua đêm đến 06:00", "action": "bed_sleep"})
				options.append({"text": "Để sau", "action": "cancel"})
				hud.open_life_activity_options(
					"🛏️ Giường nghỉ",
					"Nằm thư giãn mà không tua thời gian, hoặc ngủ qua đêm nếu đang trong giờ nghỉ.",
					options,
					player,
					self
				)
			else:
				push_error("[InteractiveStation] HUD không khả dụng để mở lựa chọn nghỉ ngơi.")
				
		StationType.PETITIONS:
			if station_id == "holomap":
				var audio_synth = get_node_or_null("/root/AudioSynthesizer")
				if audio_synth and audio_synth.has_method("play_fanfare_sound"):
					audio_synth.play_fanfare_sound(player)
				if hud and hud.has_method("show_toast"):
					hud.show_toast("🗺️ [Sa Bàn 3D Hologram] Bản đồ 500 km²: 4 Huyện Vệ Tinh và Thủ Phủ kết nối liên hoàn!")
			elif station_id == "telescope":
				var audio_synth = get_node_or_null("/root/AudioSynthesizer")
				if audio_synth and audio_synth.has_method("play_bell_sound"):
					audio_synth.play_bell_sound(player)
				if hud and hud.has_method("show_toast"):
					hud.show_toast("🔭 [Kính Viễn Vọng Skydeck] Chiêm ngưỡng cảnh quan 500 km²: Biển mây 4.000m, mặt trời 5.000m!")
			elif station_id == "metro_subway":
				var audio_synth = get_node_or_null("/root/AudioSynthesizer")
				if audio_synth and audio_synth.has_method("play_fanfare_sound"):
					audio_synth.play_fanfare_sound(player)
				if hud and hud.has_method("show_toast"):
					hud.show_toast("🚆 [Ga Metro Trung Tâm] Tuyến Metro Xuyên Núi kết nối trực tiếp Mạng Lưới Giao Thông 5 Huyện!")
			elif station_id == "teamlab_art":
				var audio_synth = get_node_or_null("/root/AudioSynthesizer")
				if audio_synth and audio_synth.has_method("play_fanfare_sound"):
					audio_synth.play_fanfare_sound(player)
				if hud and hud.has_method("show_toast"):
					hud.show_toast("✨ [Bảo Tàng Số teamLab Borderless] Ma Trận Ánh Sáng Vô Cực đổi màu rực rỡ theo từng bước chân bạn!")
			elif station_id == "cloud_cafe":
				if player.has_method("heal"):
					player.heal(50.0)
				elif "health" in player and "max_health" in player:
					player.health = min(player.health + 50.0, player.max_health)
				var audio_synth = get_node_or_null("/root/AudioSynthesizer")
				if audio_synth and audio_synth.has_method("play_bell_sound"):
					audio_synth.play_bell_sound(player)
				if hud and hud.has_method("show_toast"):
					hud.show_toast("☕ [Cà Phê Ngắm Mây] Thưởng thức tách trà thảo mộc thơm lừng cùng cư dân 5 huyện giữa mây trời (+50 HP)!")
			else:
				if hud and hud.has_method("open_petition_modal"):
					hud.open_petition_modal()
				elif hud and hud.has_method("show_toast"):
					hud.show_toast("📜 Bảng tin đô thị: Toàn thể cư dân 5 huyện đang sinh sống thuận hòa và hướng về trung tâm!")
			if hud and hud.has_method("mark_quest_done"):
				hud.mark_quest_done("quest_petitions")

		StationType.EAST_WHEAT:
			var inv_mgr = preload("res://scripts/economy/inventory_manager.gd")
			if inv_mgr.add_item("item_wheat_sack", 1):
				var audio_synth = get_node_or_null("/root/AudioSynthesizer")
				if audio_synth and audio_synth.has_method("play_fanfare_sound"):
					audio_synth.play_fanfare_sound(player)
				if hud and hud.has_method("show_toast"):
					hud.show_toast("🌾 Bạn đã nhận 1 Bao Lúa Mì Hữu Cơ vàng ươm từ Nông Trại Huyện Đông!")
			elif hud and hud.has_method("show_toast"):
				hud.show_toast("Cặp mang theo đã đầy; hãy cất bớt đồ trước khi nhận bao lúa mì.")

		StationType.NORTH_HERB:
			var inv_mgr = preload("res://scripts/economy/inventory_manager.gd")
			if inv_mgr.add_item("item_onsen_herb", 1):
				var audio_synth = get_node_or_null("/root/AudioSynthesizer")
				if audio_synth and audio_synth.has_method("play_fanfare_sound"):
					audio_synth.play_fanfare_sound(player)
				if hud and hud.has_method("show_toast"):
					hud.show_toast("♨️ Bạn đã thu hái Thảo Dược Suối Khoáng Onsen quý giá tại Huyện Bắc!")
			elif hud and hud.has_method("show_toast"):
				hud.show_toast("Cặp mang theo đã đầy; hãy cất bớt đồ trước khi nhận thảo dược.")

		StationType.WEST_POWER:
			var inv_mgr = preload("res://scripts/economy/inventory_manager.gd")
			if inv_mgr.add_item("item_solar_battery", 1):
				var audio_synth = get_node_or_null("/root/AudioSynthesizer")
				if audio_synth and audio_synth.has_method("play_fanfare_sound"):
					audio_synth.play_fanfare_sound(player)
				if hud and hud.has_method("show_toast"):
					hud.show_toast("⚡ Bạn đã nạp đầy Khối Pin Năng Lượng Mặt Trời tại Huyện Tây!")
			elif hud and hud.has_method("show_toast"):
				hud.show_toast("Cặp mang theo đã đầy; hãy cất bớt đồ trước khi nhận khối pin.")

		StationType.SOUTH_PORT:
			var inv_mgr = preload("res://scripts/economy/inventory_manager.gd")
			if inv_mgr.add_item("item_fresh_fish", 1):
				var audio_synth = get_node_or_null("/root/AudioSynthesizer")
				if audio_synth and audio_synth.has_method("play_fanfare_sound"):
					audio_synth.play_fanfare_sound(player)
				if hud and hud.has_method("show_toast"):
					hud.show_toast("🐟 Bạn đã nhận Thùng Hải Sản Tươi Ngon từ Cầu Cảng Huyện Nam!")
			elif hud and hud.has_method("show_toast"):
				hud.show_toast("Cặp mang theo đã đầy; hãy cất bớt đồ trước khi nhận hải sản.")

		StationType.TRAM_STOP:
			var tram = get_tree().get_first_node_in_group("trams")
			if tram and tram.has_method("board_from_stop"):
				if not tram.board_from_stop(player, global_position) and hud and hud.has_method("show_toast"):
					hud.show_toast("🚊 Tàu chưa vào ga hoặc đã đủ chỗ. Vui lòng chờ chuyến kế tiếp!")
			elif hud and hud.has_method("show_toast"):
				hud.show_toast("🚊 Tuyến tram hiện chưa hoạt động.")

		StationType.METRO_ACCESS:
			var target_station = get_meta("metro_target_station", null) as Node3D
			if target_station == null or not is_instance_valid(target_station):
				if hud and hud.has_method("show_toast"):
					hud.show_toast("🚇 Lối chuyển tầng Metro hiện chưa sẵn sàng.")
			else:
				player.global_position = target_station.global_position + Vector3.UP * 1.0
				player.global_rotation.y = target_station.global_rotation.y
				if "velocity" in player:
					player.velocity = Vector3.ZERO
				if hud and hud.has_method("show_toast"):
					hud.show_toast("🚇 Đã đến %s." % target_station.title_name)

		StationType.METRO_PLATFORM:
			var floor_number = int(get_meta("metro_floor_number", 0))
			var boarded = false
			for train in get_tree().get_nodes_in_group("metro_trains_b%d" % floor_number):
				if train.has_method("board_from_platform") and train.board_from_platform(player, global_position):
					boarded = true
					if hud and hud.has_method("show_toast"):
						hud.show_toast("🚄 Đã lên tàu Metro cao tốc. Tốc độ tuyến: 144 km/h.")
					break
			if not boarded and hud and hud.has_method("show_toast"):
				hud.show_toast("🚇 Tàu chưa vào sân ga hoặc toa đã đủ chỗ. Chờ chuyến tiếp theo.")
				
	station_interacted.emit(station_id, player)
	print("[InteractiveStation] ✨ Người chơi đã kích hoạt trạm: %s (#%d)" % [title_name, interaction_count])

func complete_bed_sleep(player: Node3D) -> void:
	var wm := get_node_or_null("/root/WorldManager")
	if wm == null or not wm.has_method("skip_night_to_morning"):
		push_error("[InteractiveStation] Không thể ngủ qua đêm: WorldManager không khả dụng.")
		if player.has_method("end_life_activity"):
			player.end_life_activity()
		return
	if DailyScheduleManagerScript.get_time_slot(wm.current_hour, wm.current_minute) != DailyScheduleManagerScript.TimeSlot.NIGHT_REST:
		var hud := get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("show_toast"):
			hud.show_toast("Đã hết giờ nghỉ đêm; hãy nằm thư giãn hoặc tiếp tục sinh hoạt.")
		if player.has_method("end_life_activity"):
			player.end_life_activity()
		return
	wm.skip_night_to_morning()
	if player.has_method("rest_at_bed"):
		player.rest_at_bed()
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_toast"):
		hud.show_toast("🌅 Bạn đã ngủ đến 06:00 và hồi phục hoàn toàn. Nhấn [E] để thức dậy.")
	if hud and hud.has_method("mark_quest_done"):
		hud.mark_quest_done("quest_bed")

func complete_desk_work(_player: Node3D) -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	var wm := get_node_or_null("/root/WorldManager")
	if wm:
		wm.deposit_city_tax(5000.0)
		wm.deposit_church_tithe(2500.0)
	if hud and hud.has_method("show_toast"):
		hud.show_toast("📋 Sắc lệnh Thị trưởng ban hành thành công! Ngân khố cấp 5.000Đ phát triển an sinh đô thị!")
	if hud and hud.has_method("mark_quest_done"):
		hud.mark_quest_done("quest_desk")
