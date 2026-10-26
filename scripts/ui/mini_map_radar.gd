class_name MiniMapRadar
extends Control

# ==============================================================================
# MINI-MAP RADAR 360° (TÂN THẾ GIỚI - 1500 KM²)
# Radar tròn xoay 360 độ góc trên HUD:
# 1. Tự xoay theo hướng nhìn người chơi (Player View Yaw).
# 2. Vành la bàn 4 hướng chính (Bắc [B], Nam [N], Đông [Đ], Tây [T]).
# 3. Định vị 5 Huyện: Thủ Phủ (+600m), Đông (10km), Tây (10km), Bắc (10km), Nam (20km).
# 4. Định vị Trực thăng 🚁, Xe Buggy 🚗, Trạm Giao Thông Mạng Nhện 🚏 và NPC 👥.
# 5. Chuyển đổi cự ly linh hoạt: Tầm gần (Local 1.5km) ⇄ Tầm xa (Macro 25km).
# ==============================================================================

signal zoom_mode_changed(is_macro: bool)

@export var radar_radius: float = 78.0
@export var local_range: float = 1500.0  # 1.5km
@export var macro_range: float = 25000.0 # 25km
@export var is_macro_mode: bool = false

var player_node: Node3D = null
var current_yaw: float = 0.0

var district_markers: Array[Dictionary] = [
	{"id": "capital", "name": "Thủ Phủ", "pos": Vector2(0.0, 0.0), "icon": "🏛️", "color": Color(1.0, 0.85, 0.2)},
	{"id": "east", "name": "Đông", "pos": Vector2(10000.0, 0.0), "icon": "🌾", "color": Color(0.95, 0.75, 0.2)},
	{"id": "west", "name": "Tây", "pos": Vector2(-10000.0, 0.0), "icon": "⚡", "color": Color(0.3, 0.85, 1.0)},
	{"id": "north", "name": "Bắc", "pos": Vector2(0.0, -10000.0), "icon": "🌲", "color": Color(0.3, 0.9, 0.4)},
	{"id": "south", "name": "Nam", "pos": Vector2(0.0, 20000.0), "icon": "⚓", "color": Color(0.2, 0.6, 1.0)},
]

var label_range: Label
var label_coords: Label

func _ready() -> void:
	custom_minimum_size = Vector2(radar_radius * 2.0 + 20.0, radar_radius * 2.0 + 44.0)
	size = custom_minimum_size

	# Label hiển thị tầm quét
	label_range = Label.new()
	label_range.text = "[R] 1.5 KM"
	label_range.add_theme_font_size_override("font_size", 10)
	label_range.add_theme_color_override("font_color", Color(0.3, 0.85, 1.0))
	label_range.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_range.position = Vector2(0, radar_radius * 2.0 + 2.0)
	label_range.size = Vector2(size.x, 18)
	add_child(label_range)

	# Label tọa độ
	label_coords = Label.new()
	label_coords.text = "X:0 Z:0"
	label_coords.add_theme_font_size_override("font_size", 9)
	label_coords.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9, 0.8))
	label_coords.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_coords.position = Vector2(0, radar_radius * 2.0 + 20.0)
	label_coords.size = Vector2(size.x, 16)
	add_child(label_coords)

	mouse_filter = MOUSE_FILTER_PASS

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		toggle_range_mode()

func _unhandled_input(event: InputEvent) -> void:
	var is_triggered: bool = false
	if InputMap.has_action("radar_toggle_range") and event.is_action_pressed("radar_toggle_range"):
		is_triggered = true
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_R or event.keycode == KEY_R:
			is_triggered = true
	if is_triggered:
		toggle_range_mode()

func toggle_range_mode() -> void:
	is_macro_mode = not is_macro_mode
	if label_range:
		if is_macro_mode:
			label_range.text = "[R] 25 KM (Vĩ Mô)"
			label_range.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
		else:
			label_range.text = "[R] 1.5 KM (Cục Bộ)"
			label_range.add_theme_color_override("font_color", Color(0.3, 0.85, 1.0))
	zoom_mode_changed.emit(is_macro_mode)
	queue_redraw()

func _process(_delta: float) -> void:
	if player_node == null or not is_instance_valid(player_node):
		player_node = get_tree().get_first_node_in_group("player") as Node3D
		if player_node == null:
			return

	# Lấy góc quay Yaw của người chơi (hoặc camera nếu có)
	current_yaw = player_node.rotation.y
	var cam = get_viewport().get_camera_3d()
	if cam:
		current_yaw = cam.global_rotation.y

	# Cập nhật hiển thị tọa độ
	var p_pos = player_node.global_position
	label_coords.text = "X:%d Z:%d | Y:%.0fm" % [int(p_pos.x), int(p_pos.z), p_pos.y]

	queue_redraw()

func _draw() -> void:
	var center = Vector2(radar_radius + 10.0, radar_radius + 10.0)
	var active_range = macro_range if is_macro_mode else local_range

	# 1. NỀN KÍNH MỜ TRÒN
	draw_circle(center, radar_radius, Color(0.04, 0.08, 0.16, 0.88))

	# 2. CÁC VÒNG TRÒN CỰ LY (25%, 50%, 75%, 100%)
	draw_arc(center, radar_radius * 0.33, 0.0, TAU, 32, Color(0.2, 0.4, 0.6, 0.25), 1.0)
	draw_arc(center, radar_radius * 0.66, 0.0, TAU, 48, Color(0.2, 0.4, 0.6, 0.35), 1.0)
	draw_arc(center, radar_radius, 0.0, TAU, 64, Color(0.25, 0.75, 1.0, 0.85), 2.0)

	# 3. ĐƯỜNG CHỮ THẬP TRỤC LA BÀN
	draw_line(center - Vector2(radar_radius * 0.85, 0), center + Vector2(radar_radius * 0.85, 0), Color(0.3, 0.5, 0.7, 0.25), 1.0)
	draw_line(center - Vector2(0, radar_radius * 0.85), center + Vector2(0, radar_radius * 0.85), Color(0.3, 0.5, 0.7, 0.25), 1.0)

	# 4. VÀNH LA BÀN 4 HƯỚNG XOAY THEO PLAYER YAW
	var default_font = ThemeDB.fallback_font
	var font_size = 11

	var directions = [
		{"label": "B", "angle": -PI * 0.5, "col": Color(1.0, 0.35, 0.35)}, # Bắc (North)
		{"label": "Đ", "angle": 0.0,       "col": Color(0.85, 0.95, 1.0)}, # Đông (East)
		{"label": "N", "angle": PI * 0.5,  "col": Color(0.85, 0.95, 1.0)}, # Nam (South)
		{"label": "T", "angle": PI,        "col": Color(0.85, 0.95, 1.0)}  # Tây (West)
	]

	for d in directions:
		# Góc hiển thị trên radar = góc thế giới - player yaw
		var radar_ang = d["angle"] - current_yaw - PI * 0.5
		var dir_pos = center + Vector2(cos(radar_ang), sin(radar_ang)) * (radar_radius - 10.0)
		draw_string(default_font, dir_pos + Vector2(-4, 4), d["label"], HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, d["col"])

	if player_node == null:
		return

	var p_world = Vector2(player_node.global_position.x, player_node.global_position.z)

	# 5. VẼ CÁC ĐIỂM MỐC 5 HUYỆN
	for dist in district_markers:
		var w_offset = dist["pos"] - p_world
		var w_dist = w_offset.length()
		if w_dist > active_range * 1.05 and not is_macro_mode:
			# Trong chế độ tầm gần, ghim icon ở mép radar nếu ở ngoài cự ly
			var clamped_dir = w_offset.normalized()
			var blip_screen = _world_to_radar(clamped_dir * (radar_radius * 0.90), center)
			draw_circle(blip_screen, 4.0, dist["color"])
			draw_string(default_font, blip_screen + Vector2(-6, -6), dist["icon"], HORIZONTAL_ALIGNMENT_CENTER, -1, 10, dist["color"])
		else:
			var blip_screen = _world_to_radar(w_offset * (radar_radius / active_range), center)
			if (blip_screen - center).length() <= radar_radius - 4.0:
				draw_circle(blip_screen, 5.0, dist["color"])
				draw_string(default_font, blip_screen + Vector2(-6, -6), dist["icon"], HORIZONTAL_ALIGNMENT_CENTER, -1, 11, dist["color"])

	# 6. VẼ TRỰC THĂNG & XE BUGGY (NẾU CÓ)
	for heli in get_tree().get_nodes_in_group("helicopters"):
		var heli_w = Vector2(heli.global_position.x, heli.global_position.z)
		var offset = heli_w - p_world
		var pt = _world_to_radar(offset * (radar_radius / active_range), center)
		if (pt - center).length() <= radar_radius - 4.0:
			draw_string(default_font, pt + Vector2(-5, 4), "🚁", HORIZONTAL_ALIGNMENT_CENTER, -1, 11, Color(1.0, 0.9, 0.2))

	for buggy in get_tree().get_nodes_in_group("buggies"):
		var buggy_w = Vector2(buggy.global_position.x, buggy.global_position.z)
		var offset = buggy_w - p_world
		var pt = _world_to_radar(offset * (radar_radius / active_range), center)
		if (pt - center).length() <= radar_radius - 4.0:
			draw_string(default_font, pt + Vector2(-5, 4), "🚗", HORIZONTAL_ALIGNMENT_CENTER, -1, 11, Color(0.3, 1.0, 0.7))

	# 7. VẼ CÁC TRẠM GIAO THÔNG MẠNG NHỆN
	for st in get_tree().get_nodes_in_group("transit_stations"):
		var st_w = Vector2(st.global_position.x, st.global_position.z)
		var offset = st_w - p_world
		var pt = _world_to_radar(offset * (radar_radius / active_range), center)
		if (pt - center).length() <= radar_radius - 6.0:
			draw_circle(pt, 3.0, Color(0.4, 0.8, 1.0, 0.8))

	# 8. MŨI TÊN NGƯỜI CHƠI TẠI TÂM RADAR (LUÔN HƯỚNG LÊN TRÊN)
	var arrow_pts = PackedVector2Array([
		center + Vector2(0, -9),
		center + Vector2(-6, 7),
		center + Vector2(0, 4),
		center + Vector2(6, 7)
	])
	draw_colored_polygon(arrow_pts, Color(0.1, 1.0, 0.85))
	draw_polyline(arrow_pts, Color(1.0, 1.0, 1.0), 1.5)

## Chuyển vector thế giới thành vị trí trên Radar có tính đến góc quay Yaw người chơi
func _world_to_radar(world_offset: Vector2, center: Vector2) -> Vector2:
	# Xoay ngược theo current_yaw
	var ang = -current_yaw
	var rotated_x = world_offset.x * cos(ang) - world_offset.y * sin(ang)
	var rotated_y = world_offset.x * sin(ang) + world_offset.y * cos(ang)
	return center + Vector2(rotated_x, rotated_y)
