class_name SkyscraperElevator
extends AnimatableBody3D

# ==============================================================================
# SKYSCRAPER ELEVATOR - THANG MÁY KÍNH PANORAMA ĐẠI CAO ỐC MEGA-OFFICE
# Kết nối 15 tầng chuyên biệt, hỗ trợ phím [E] mở bảng chọn tầng & phím số [1-9]
# Tuân thủ nghiêm ngặt:
# 1. RULE: INTERACTIVE_OBJECT_DUAL_LAYER_SAFETY (Layer 1|2|4, fallback cự ly)
# 2. RULE: DIEGETIC_UI_PROMPT_VISIBILITY_STANDARD (Billboard, no_depth_test)
# ==============================================================================

const FLOOR_HEIGHTS: Array[float] = [
	-40.0,  # B4
	-30.0,  # B3
	-20.0,  # B2
	-10.0,  # B1
	0.0,    # 1: Sảnh Atrium & Dịch Vụ Công Một Cửa
	17.0,   # 2
	30.0,   # 3
	43.0,   # 4
	56.0,   # 5
	69.0,   # 6
	82.0,   # 7
	95.0,   # 8
	108.0,  # 9
	121.0,  # 10
	134.0,  # 11: Đại Hội Trường
	155.0,  # 12
	168.0,  # 13
	181.0,  # 14
	194.0   # 15: Skydeck mở nóc
]

const STOP_FLOOR_NUMBERS: Array[int] = [-4, -3, -2, -1, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
const FLOOR_NAMES: Array[String] = [
	"Tầng hầm B4: Hạ tầng kỹ thuật",
	"Tầng hầm B3: Kho vận & dịch vụ",
	"Tầng hầm B2: Bãi xe & tiện ích",
	"Tầng hầm B1: Sảnh Metro & kết nối",
	"Tầng 1: Đại Sảnh Grand Civic Atrium & Dịch Vụ Công Một Cửa",
	"Tầng 2: Ban Nội Vụ & Nhân Sự (Quản Trị Hộ Tịch & Căn Cước)",
	"Tầng 3: Ban Tài Chính & Kế Toán (Ngân Hàng Nhà Nước Tự Động)",
	"Tầng 4: Ban Đào Tạo & Kèm Cặp (Học Viện Bách Khoa Đỉnh Vát)",
	"Tầng 5: Ban Kế Hoạch & SCM (Chuỗi Cung Ứng Đô Thị)",
	"Tầng 6: Ban Kỹ Thuật & Bảo Trì Cơ Sở Vật Chất (Điện Lưới & Máy)",
	"Tầng 7: Ban Kiểm Chuẩn Chất Lượng & Môi Trường Sinh Thái",
	"Tầng 8: Ban Truyền Thông, Báo Chí & Cầu Kính Skybridge",
	"Tầng 9: Ban Ca Ngợi, Âm Nhạc Phụng Vụ & Thờ Phượng",
	"Tầng 10: Ban Mục Vụ, Tư Vấn Tâm Lý & Sứ Mạng Hòa Bình",
	"Tầng 11: Đại Hội Lễ Tôn Giáo & Thánh Đường Trung Tâm (21M)",
	"Tầng 12: Hội Trường Triển Lãm & Xúc Tiến Thương Mại 5 Huyện",
	"Tầng 13: Trung Tâm Hội Nghị Bàn Tròn & Chiếu Phim Anime",
	"Tầng 14: Giảng Đường Đào Tạo Lãnh Đạo & Nghiên Cứu Vĩ Mô",
	"Tầng 15: Sân Thượng Skydeck Mở Trời & Cloud Cafe (+194M)"
]

const TOTAL_FLOORS: int = 15
const TOTAL_STOPS: int = 19
const TRAVEL_SPEED: float = 8.0
@export_range(0.1, 30.0, 0.1) var travel_speed: float = TRAVEL_SPEED
@export var arrival_sound: AudioStream
var interaction_radius: float = 6.0

signal doors_opened()
signal doors_closed()
signal floor_arrived(floor_number: int)

var area: Area3D
var prompt_label: Label3D
var canvas_layer: CanvasLayer
var ui_modal: Control
var elevator_car: AnimatableBody3D
var arrival_audio_player: AudioStreamPlayer3D
var player_ref: Node = null
var is_in_range: bool = false
var is_travelling: bool = false
var are_doors_open: bool = true
var target_y_offset: float = 0.0
var target_floor_number: int = 1
var current_floor_number: int = 1
var floor_request_queue: Array[int] = []

# Stored parent for restoring the player after elevator travel
var _player_prev_parent: Node = null
var _travel_tween: Tween

# Player root is at the feet; cabin floor collider top is 0.30m with 0.02m clearance.
const PLAYER_CABIN_FLOOR_OFFSET: float = 0.32

func _ready() -> void:
	collision_layer = 1
	collision_mask = 1 | 2
	sync_to_physics = true
	add_to_group("elevators")
	add_to_group("interactive_stations")
	_setup_interaction_area()
	_setup_prompt_label()
	_setup_ui_modal()
	_setup_elevator_car()
	_setup_arrival_audio()

func _setup_interaction_area() -> void:
	area = Area3D.new()
	area.name = "ElevatorArea"
	area.collision_layer = 1 | 2 | 4
	area.collision_mask = 1 | 2 | 4
	
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(10.0, 250.0, 10.0)
	col.shape = box
	col.position.y = 80.0
	area.add_child(col)
	add_child(area)
	
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

func _setup_prompt_label() -> void:
	prompt_label = Label3D.new()
	prompt_label.name = "ElevatorPrompt3D"
	prompt_label.text = "🛗 [E] Chọn tầng • B4 đến Tầng 15"
	prompt_label.font_size = 26
	prompt_label.outline_size = 8
	prompt_label.outline_modulate = Color(0.05, 0.08, 0.14, 0.95)
	prompt_label.modulate = Color(1.0, 0.88, 0.25)
	prompt_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	prompt_label.no_depth_test = true
	prompt_label.position = Vector3(0.0, 2.4, 2.2)
	prompt_label.visible = false
	add_child(prompt_label)

func _setup_elevator_car() -> void:
	elevator_car = self

	var cabin_material = StandardMaterial3D.new()
	cabin_material.albedo_color = Color(0.22, 0.68, 0.9, 0.45)
	cabin_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cabin_material.metallic = 0.3
	cabin_material.roughness = 0.16

	var cabin = MeshInstance3D.new()
	cabin.name = "PanoramicCabin"
	var cabin_mesh = BoxMesh.new()
	cabin_mesh.size = Vector3(5.2, 4.4, 5.2)
	cabin.mesh = cabin_mesh
	cabin.material_override = cabin_material
	cabin.position.y = 2.2
	elevator_car.add_child(cabin)

	var floor = MeshInstance3D.new()
	floor.name = "CabinFloor"
	var floor_mesh = BoxMesh.new()
	floor_mesh.size = Vector3(5.2, 0.25, 5.2)
	floor.mesh = floor_mesh
	var floor_material = StandardMaterial3D.new()
	floor_material.albedo_color = Color(0.16, 0.2, 0.28)
	floor_material.metallic = 0.45
	floor_material.roughness = 0.32
	floor.material_override = floor_material
	floor.position.y = 0.15
	elevator_car.add_child(floor)

	var car_floor_collision = CollisionShape3D.new()
	car_floor_collision.name = "CabinFloorCollider"
	var car_floor_shape = BoxShape3D.new()
	car_floor_shape.size = Vector3(5.2, 0.3, 5.2)
	car_floor_collision.shape = car_floor_shape
	car_floor_collision.position.y = 0.15
	elevator_car.add_child(car_floor_collision)

	var wall_positions: Array[Vector3] = [
		Vector3(-2.6, 2.2, 0.0),
		Vector3(2.6, 2.2, 0.0),
		Vector3(0.0, 2.2, -2.6)
	]
	for wall_index in range(wall_positions.size()):
		var wall_collision = CollisionShape3D.new()
		var wall_shape = BoxShape3D.new()
		wall_shape.size = Vector3(0.18, 4.4, 5.2) if wall_index < 2 else Vector3(5.2, 4.4, 0.18)
		wall_collision.shape = wall_shape
		wall_collision.position = wall_positions[wall_index]
		elevator_car.add_child(wall_collision)

func _setup_arrival_audio() -> void:
	arrival_audio_player = AudioStreamPlayer3D.new()
	arrival_audio_player.name = "FloorArrivalAudio"
	arrival_audio_player.stream = arrival_sound
	add_child(arrival_audio_player)

func _setup_ui_modal() -> void:
	canvas_layer = CanvasLayer.new()
	canvas_layer.name = "ElevatorCanvasLayer"
	add_child(canvas_layer)
	
	ui_modal = Control.new()
	ui_modal.name = "ElevatorModal"
	ui_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_modal.visible = false
	canvas_layer.add_child(ui_modal)
	
	# Màn phủ làm mờ nền
	var overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.02, 0.05, 0.10, 0.72)
	ui_modal.add_child(overlay)
	
	# Khung bảng điều khiển thang máy trung tâm
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(720, 680)
	panel.offset_left = -360
	panel.offset_top = -340
	panel.offset_right = 360
	panel.offset_bottom = 340
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.12, 0.18, 0.95)
	sb.border_color = Color(0.96, 0.80, 0.20, 1.0)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(14)
	sb.set_content_margin_all(20)
	panel.add_theme_stylebox_override("panel", sb)
	ui_modal.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)
	
	# Tiêu đề bảng điều khiển
	var title = Label.new()
	title.text = "🛗 BẢNG ĐIỀU KHIỂN THANG MÁY KÍNH PANORAMA (15 TẦNG)"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.3))
	vbox.add_child(title)
	
	var subtitle = Label.new()
	subtitle.text = "Chọn tầng làm việc hoặc ngắm toàn cảnh Tân Thế Giới từ độ cao +130m"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
	vbox.add_child(subtitle)
	
	var hsep = HSeparator.new()
	vbox.add_child(hsep)
	
	# Scroll container chứa danh sách 15 tầng
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(680, 480)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	
	var grid = GridContainer.new()
	grid.columns = 1
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("v_separation", 6)
	scroll.add_child(grid)
	
	for floor_num in STOP_FLOOR_NUMBERS:
		var btn = Button.new()
		btn.text = FLOOR_NAMES[STOP_FLOOR_NUMBERS.find(floor_num)]
		btn.custom_minimum_size = Vector2(660, 36)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		var btn_sb = StyleBoxFlat.new()
		btn_sb.bg_color = Color(0.12, 0.16, 0.24, 0.9)
		btn_sb.set_border_width_all(1)
		btn_sb.border_color = Color(0.25, 0.45, 0.75, 0.8)
		btn_sb.set_corner_radius_all(6)
		btn_sb.set_content_margin_all(8)
		btn.add_theme_stylebox_override("normal", btn_sb)
		
		btn.pressed.connect(Callable(self, "_on_floor_selected").bind(floor_num))
		grid.add_child(btn)
		
	var close_btn = Button.new()
	close_btn.text = "✖ ĐÓNG BẢNG ĐIỀU KHIỂN [Esc]"
	close_btn.custom_minimum_size = Vector2(0, 42)
	close_btn.pressed.connect(_close_ui)
	vbox.add_child(close_btn)

func _process(_delta: float) -> void:
	# Fallback cự ly an toàn (Dual-layer safety)
	if player_ref == null or not is_instance_valid(player_ref):
		player_ref = get_tree().get_first_node_in_group("player")
		
	if player_ref and is_instance_valid(player_ref):
		var p_pos = player_ref.global_position
		var dist_xz = Vector2(p_pos.x - global_position.x, p_pos.z - global_position.z).length()
		var in_height = (p_pos.y >= global_position.y - 45.0 and p_pos.y <= global_position.y + 205.0)
		var should_be_in_range = (dist_xz <= interaction_radius and in_height)
		
		is_in_range = should_be_in_range
		prompt_label.visible = is_in_range
		if is_in_range:
			prompt_label.global_position.y = p_pos.y + 2.2
			var cur_elev = player_ref.get_meta("nearby_elevator") if player_ref.has_meta("nearby_elevator") else null
			if not is_instance_valid(cur_elev) or cur_elev == self or dist_xz < Vector2(p_pos.x - cur_elev.global_position.x, p_pos.z - cur_elev.global_position.z).length():
				player_ref.set_meta("nearby_elevator", self)
				player_ref.set_meta("nearby_interactive", self)
		else:
			if player_ref.has_meta("nearby_elevator") and player_ref.get_meta("nearby_elevator") == self:
				player_ref.remove_meta("nearby_elevator")
			if player_ref.has_meta("nearby_interactive") and player_ref.get_meta("nearby_interactive") == self:
				player_ref.remove_meta("nearby_interactive")

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_ref = body
		is_in_range = true
		prompt_label.visible = true
		prompt_label.global_position.y = body.global_position.y + 2.2
		body.set_meta("nearby_elevator", self)
		body.set_meta("nearby_interactive", self)

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		is_in_range = false
		prompt_label.visible = false
		if body.has_meta("nearby_elevator") and body.get_meta("nearby_elevator") == self:
			body.remove_meta("nearby_elevator")
		if body.has_meta("nearby_interactive") and body.get_meta("nearby_interactive") == self:
			body.remove_meta("nearby_interactive")

# Tương tác phím [E] mở bảng UI
func interact(player: Node) -> void:
	player_ref = player
	if ui_modal:
		ui_modal.visible = not ui_modal.visible
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if ui_modal.visible else Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if ui_modal and ui_modal.visible and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.physical_keycode == KEY_ESCAPE:
			_close_ui()
			get_viewport().set_input_as_handled()

func _close_ui() -> void:
	if ui_modal:
		ui_modal.visible = false
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_floor_selected(floor_num: int) -> void:
	_close_ui()
	if player_ref:
		request_floor(player_ref, floor_num)

# Chuyển tầng tức thời / lướt êm ái
func request_floor(player: Node, floor_num: int) -> void:
	var floor_index = STOP_FLOOR_NUMBERS.find(floor_num)
	if floor_index < 0:
		push_warning("SkyscraperElevator: Requested unsupported floor %d." % floor_num)
		return
	if not is_instance_valid(player):
		push_warning("SkyscraperElevator: Cannot move an invalid player.")
		return
	if player.get_parent() == null:
		push_warning("SkyscraperElevator: Cannot board a player without a parent node.")
		return

	if player_ref != null and is_instance_valid(player_ref) and player_ref != player and player_ref.get_parent() == elevator_car:
		push_warning("SkyscraperElevator: Another player already owns this elevator ride.")
		return

	if floor_num == current_floor_number and not is_travelling and floor_request_queue.is_empty():
		open_doors()
		return
	if floor_num == target_floor_number and is_travelling:
		return
	if floor_request_queue.has(floor_num):
		return

	player_ref = player
	if player.get_parent() != elevator_car:
		_player_prev_parent = player.get_parent()
		player.reparent(elevator_car, true)
		player.position = Vector3(0.0, PLAYER_CABIN_FLOOR_OFFSET, 0.0)
		player.set_physics_process(false)
		player.set_meta("occupied_elevator", self)
		if "velocity" in player:
			player.velocity = Vector3.ZERO

	floor_request_queue.append(floor_num)
	if not is_travelling:
		_start_next_floor_request()

	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_toast"):
		hud.show_toast("🛗 Thang máy đang di chuyển đến %s." % FLOOR_NAMES[floor_index])
	print("[Elevator] 🛗 Bắt đầu di chuyển đến tầng %d: %s" % [floor_num, FLOOR_NAMES[floor_index]])

func _start_next_floor_request() -> void:
	if floor_request_queue.is_empty():
		_finish_player_ride()
		return

	var floor_num: int = floor_request_queue.pop_front()
	var floor_index := STOP_FLOOR_NUMBERS.find(floor_num)
	target_floor_number = floor_num
	target_y_offset = FLOOR_HEIGHTS[floor_index]
	close_doors()

	var distance := absf(position.y - target_y_offset)
	if is_zero_approx(distance):
		_arrive_at_floor()
		return

	var speed := maxf(travel_speed, 0.1)
	is_travelling = true
	if player_ref != null and is_instance_valid(player_ref) and "velocity" in player_ref:
		player_ref.velocity = Vector3.ZERO
	_travel_tween = create_tween()
	_travel_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_travel_tween.set_trans(Tween.TRANS_QUAD)
	_travel_tween.set_ease(Tween.EASE_IN_OUT)
	_travel_tween.tween_property(self, "position:y", target_y_offset, distance / speed)
	_travel_tween.finished.connect(_arrive_at_floor)

func open_doors() -> void:
	if are_doors_open:
		return
	are_doors_open = true
	doors_opened.emit()

func close_doors() -> void:
	if not are_doors_open:
		return
	are_doors_open = false
	doors_closed.emit()

func _arrive_at_floor() -> void:
	is_travelling = false
	current_floor_number = target_floor_number
	open_doors()
	floor_arrived.emit(current_floor_number)
	if arrival_audio_player != null and arrival_audio_player.stream != null:
		arrival_audio_player.play()

	if player_ref == null or not is_instance_valid(player_ref):
		floor_request_queue.clear()
		_finish_player_ride()
		return

	if not floor_request_queue.is_empty():
		_play_arrival_feedback()
		_start_next_floor_request()
		return

	_play_arrival_feedback()
	_finish_player_ride()
	print("[Elevator] 🛗 Đã đến tầng %d (Y=%.1fm)." % [target_floor_number, global_position.y])

func _play_arrival_feedback() -> void:
	if player_ref == null or not is_instance_valid(player_ref):
		return
	var audio_synth = get_node_or_null("/root/AudioSynthesizer")
	if arrival_audio_player == null or arrival_audio_player.stream == null:
		if audio_synth and audio_synth.has_method("play_elevator_sound"):
			audio_synth.play_elevator_sound(player_ref)
		elif audio_synth and audio_synth.has_method("play_bell_sound"):
			audio_synth.play_bell_sound(player_ref)

	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_toast"):
		var floor_index = STOP_FLOOR_NUMBERS.find(current_floor_number)
		hud.show_toast("🛗 [Thang Máy Kính] Đã đến: " + FLOOR_NAMES[floor_index])

func _finish_player_ride() -> void:
	if player_ref == null or not is_instance_valid(player_ref):
		_player_prev_parent = null
		return

	var cabin_floor_position := global_transform * Vector3(0.0, PLAYER_CABIN_FLOOR_OFFSET, 0.0)
	var dest_parent: Node = _player_prev_parent
	if not is_instance_valid(dest_parent):
		dest_parent = get_tree().current_scene
	if not is_instance_valid(dest_parent):
		dest_parent = get_tree().root

	if player_ref.get_parent() == elevator_car:
		player_ref.reparent(dest_parent, true)
		player_ref.global_position = cabin_floor_position
	if "velocity" in player_ref:
		player_ref.velocity = Vector3.ZERO
	player_ref.set_physics_process(true)
	if player_ref.has_meta("occupied_elevator"):
		player_ref.remove_meta("occupied_elevator")
	_player_prev_parent = null
