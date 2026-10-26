class_name HUDOverlay
extends CanvasLayer

# ==============================================================================
# HUD OVERLAY - GIAO DIỆN ĐIỀU HÀNH ĐÔ THỊ TÂN THẾ GIỚI
# Bao gồm:
# 1. Thanh trạng thái đỉnh màn hình (Đồng hồ, Thánh Lễ, Kho Bạc, Quỹ 1/10)
# 2. Hệ thống thông báo nổi Toast Notification mượt mà (show_toast)
# 3. Bảng Nhiệm Vụ Khởi Đầu & Dân Sinh 5 Huyện (QuestTracker)
# 4. Hộp thoại Anime RPG Dialogue Box (open_npc_dialogue)
# 5. Túi Đồ Thị Trưởng Phím [I] & Thanh Quick Item [1/2] (toggle_inventory_modal)
# 6. Thanh hiển thị Sinh Lực & Năng Lượng (Vitals Bar)
# 7. Bảng Tin Nguyện Vọng Cư Dân 5 Huyện (open_petition_modal)
# 8. Thanh Hướng Dẫn Phím Bấm Ngữ Cảnh Diegetic Hint
# ==============================================================================

const DialogueManagerScript = preload("res://scripts/dialogue/dialogue_manager.gd")
const InventoryManagerScript = preload("res://scripts/economy/inventory_manager.gd")
const AudioSynthesizerScript = preload("res://scripts/core/audio_synthesizer.gd")
const MiniMapRadarScript = preload("res://scripts/ui/mini_map_radar.gd")

@onready var clock_label: Label = $TopBar/Margin/HBox/ClockLabel
@onready var liturgy_banner: PanelContainer = $TopBar/Margin/HBox/LiturgyBanner
@onready var liturgy_label: Label = $TopBar/Margin/HBox/LiturgyBanner/LiturgyLabel
@onready var treasury_label: Label = $TopBar/Margin/HBox/TreasuryLabel
@onready var tithe_label: Label = $TopBar/Margin/HBox/TitheLabel
@onready var hint_label: Label = $HintLabel if has_node("HintLabel") else null

@onready var hr_modal: PanelContainer = $HRModal
@onready var ent_name_label: Label = $HRModal/Margin/VBox/Header/EntNameLabel
@onready var ent_status_badge: Label = $HRModal/Margin/VBox/Header/StatusBadge
@onready var div_list_container: VBoxContainer = $HRModal/Margin/VBox/Scroll/DivList
@onready var close_hr_button: Button = $HRModal/Margin/VBox/Header/CloseButton if has_node("HRModal/Margin/VBox/Header/CloseButton") else null
@onready var citizen_modal = $CitizenIDModal if has_node("CitizenIDModal") else null
@onready var macro_map_modal = $MacroMapModal if has_node("MacroMapModal") else null

var current_open_enterprise: EnterpriseData

# Hệ thống Mini-Map Radar 360°
var mini_map_radar: MiniMapRadar

# Hệ thống 8-Slot Hotbar Vật Phẩm Cầm Tay
var hotbar_panel: PanelContainer
var hotbar_slot_buttons: Array[Button] = []
var hotbar_slot_labels: Array[Label] = []
var hotbar_slot_icons: Array[Label] = []
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
var hotbar_selected_index: int = -1

# Hệ thống Toast
var toast_panel: PanelContainer
var toast_label: Label
var toast_timer: float = 0.0
var last_toast_message: String = ""

# Hệ thống Bảng Tin Dân Làng
var petition_modal: PanelContainer
var petition_close_btn: Button

# Hệ thống Hộp Thoại Anime RPG
var dialogue_modal: PanelContainer
var dlg_avatar_label: Label
var dlg_name_label: Label
var dlg_role_label: Label
var dlg_text_label: Label
var dlg_options_container: VBoxContainer
var current_dialogue_npc: Node3D = null
var life_activity_modal: PanelContainer
var life_activity_title: Label
var life_activity_description: Label
var life_activity_options: VBoxContainer
var life_activity_buttons: Dictionary = {}
var life_activity_player: Node3D
var life_activity_station: Node3D

# Hệ thống Túi Đồ Phím [I]
var inventory_modal: PanelContainer
var inv_items_container: VBoxContainer
var vitals_label: Label
var office_storage_modal: PanelContainer
var office_case_items_container: VBoxContainer
var office_store_items_container: VBoxContainer
var office_storage_summary_label: Label
var office_storage_source: Node3D
var wardrobe_modal: PanelContainer
var current_wardrobe_source: Node3D = null

# Hệ thống Quest Tracker Đô Thị Trung Tâm & 5 Huyện
var quest_tracker_panel: PanelContainer
var quest_title_label: Label
var quest_items: Dictionary = {}
var quests_data = {
	"quest_fountain": {"title": "🪙 Đài Phun Nước", "desc": "Thả đồng xu cầu an lành", "done": false},
	"quest_bakery": {"title": "🥖 Tiệm Bác Nam", "desc": "Nhận bánh mì nóng hồi sức", "done": false},
	"quest_clinic": {"title": "🌿 Trạm Xá Chị Mai", "desc": "Uống trà thảo mộc chữa lành", "done": false},
	"quest_bell": {"title": "🔔 Tháp Chuông", "desc": "Kéo dây rung chuông hòa bình", "done": false},
	"quest_desk": {"title": "📋 Bàn Sắc Lệnh", "desc": "Ký sắc lệnh phát triển an sinh", "done": false},
	"quest_buggy": {"title": "🚗 Xe Buggy Điện", "desc": "Lái xe buggy tuần tra quảng trường", "done": false},
	"quest_bed": {"title": "🛏️ Giường Nghỉ Ngơi", "desc": "Nghỉ ngơi tua nhanh qua đêm", "done": false},
	"quest_petitions": {"title": "📜 Bảng Tin Cư Dân", "desc": "Xem nguyện vọng cư dân 5 huyện", "done": false},
	"quest_district_east_wheat": {"title": "🌾 Tiếp Tế Huyện Đông", "desc": "Mang bao lúa mì hữu cơ về cho Bác Nam", "done": false},
	"quest_district_north_herb": {"title": "♨️ Dược Liệu Huyện Bắc", "desc": "Thu hái thảo dược Onsen cho Chị Mai", "done": false},
	"quest_district_west_power": {"title": "⚡ Điện Gió Huyện Tây", "desc": "Kiểm tra trạm sạc điện mặt trời", "done": false},
	"quest_district_south_port": {"title": "⚓ Cảng Cá Huyện Nam", "desc": "Đón tàu cá tại cầu cảng Hải Đăng", "done": false}
}

func _ready() -> void:
	add_to_group("hud")
	hr_modal.visible = false
	liturgy_banner.visible = false
	if citizen_modal:
		citizen_modal.visible = false
	if macro_map_modal:
		macro_map_modal.visible = false
	if close_hr_button:
		close_hr_button.pressed.connect(_on_close_hr_pressed)

	if hint_label:
		hint_label.offset_top = -28.0
		hint_label.offset_bottom = -6.0
		hint_label.text = "[W,A,S,D/Mũi tên] Di chuyển | [E/F] Tương tác/Kho/Trang phục/Xe | [Space] Nhảy | [F6] Lưu game | [1-8] Vật Phẩm Cầm Tay | [R] Radar 1.5km ⇄ 25km | [I] Túi đồ | [M/Tab] Bản đồ | [T/F5] Đón sáng 06:00 | [V] Góc nhìn | [Esc] Chuột"

	_setup_toast_ui()
	_setup_dialogue_modal_ui()
	_setup_life_activity_modal()
	_setup_inventory_modal_ui()
	_setup_petition_modal_ui()
	_setup_quest_tracker_ui()
	_setup_mini_map_radar()
	_setup_hotbar_ui()
	_setup_mayor_office_storage_modal_ui()
	_setup_wardrobe_modal_ui()

	var wm = get_node_or_null("/root/WorldManager")
	if wm:
		wm.time_ticked.connect(_on_time_ticked)
		wm.liturgy_started.connect(_on_liturgy_started)
		wm.liturgy_ended.connect(_on_liturgy_ended)
		wm.treasury_updated.connect(_on_treasury_updated)
		_update_clock_display()
		_update_treasury_display(wm.treasury_city, wm.fund_tithe_church)

func _process(delta: float) -> void:
	if toast_timer > 0.0:
		toast_timer -= delta
		if toast_timer <= 0.0 and toast_panel:
			toast_panel.visible = false

	# Cập nhật hiển thị Sinh Lực Thị Trưởng & Hotbar
	_update_vitals_display()
	_update_hotbar_display()

func _update_vitals_display() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player and vitals_label:
		var hp = player.get("current_health")
		var max_hp = player.get("max_health")
		var stamina = player.get("current_stamina")
		var max_stamina = player.get("max_stamina")
		var focus = player.get("current_focus")
		var buff_time = player.get("speed_buff_timer")
		if hp != null and max_hp != null:
			var buff_str = " ⚡ Buff Tốc Độ!" if (buff_time != null and buff_time > 0.0) else ""
			if stamina != null and max_stamina != null:
				var focus_text := " | 🧠 Tập Trung: %d%%" % int(focus) if focus != null else ""
				vitals_label.text = "❤️ Sinh Lực: %d/%d HP | ⚡ Thể Lực: %d/%d%s%s" % [
					int(hp), int(max_hp), int(stamina), int(max_stamina), focus_text, buff_str
				]
				vitals_label.modulate = Color(1.0, 0.68, 0.35) if float(stamina) <= float(max_stamina) * 0.2 else Color(0.4, 0.95, 0.6)
			else:
				vitals_label.text = "❤️ Sinh Lực: %d/%d HP%s" % [int(hp), int(max_hp), buff_str]

# ------------------------------------------------------------------------------
# 0. HỆ THỐNG MINI-MAP RADAR & 8-SLOT HOTBAR
# ------------------------------------------------------------------------------
func _setup_mini_map_radar() -> void:
	mini_map_radar = MiniMapRadarScript.new()
	mini_map_radar.name = "MiniMapRadar"
	mini_map_radar.anchors_preset = Control.PRESET_TOP_RIGHT
	mini_map_radar.anchor_left = 1.0
	mini_map_radar.anchor_right = 1.0
	mini_map_radar.anchor_top = 0.0
	mini_map_radar.anchor_bottom = 0.0
	mini_map_radar.offset_left = -205.0
	mini_map_radar.offset_right = -15.0
	mini_map_radar.offset_top = 58.0
	mini_map_radar.offset_bottom = 265.0
	add_child(mini_map_radar)

func _setup_hotbar_ui() -> void:
	hotbar_panel = PanelContainer.new()
	hotbar_panel.name = "HotbarPanel"

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.07, 0.12, 0.92)
	style.border_color = Color(0.2, 0.45, 0.7, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.expand_margin_left = 10.0
	style.expand_margin_right = 10.0
	style.expand_margin_top = 6.0
	style.expand_margin_bottom = 6.0
	hotbar_panel.add_theme_stylebox_override("panel", style)

	hotbar_panel.anchors_preset = Control.PRESET_BOTTOM_WIDE
	hotbar_panel.anchor_left = 0.5
	hotbar_panel.anchor_right = 0.5
	hotbar_panel.anchor_top = 1.0
	hotbar_panel.anchor_bottom = 1.0
	hotbar_panel.offset_left = -265.0
	hotbar_panel.offset_right = 265.0
	hotbar_panel.offset_top = -92.0
	hotbar_panel.offset_bottom = -34.0

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hotbar_panel.add_child(hbox)

	hotbar_slot_buttons.clear()
	hotbar_slot_labels.clear()
	hotbar_slot_icons.clear()

	for i in range(8):
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(58, 48)
		btn.flat = false

		var b_style = StyleBoxFlat.new()
		b_style.bg_color = Color(0.08, 0.13, 0.22, 0.95)
		b_style.border_color = Color(0.25, 0.4, 0.6, 0.6)
		b_style.set_border_width_all(1)
		b_style.set_corner_radius_all(6)
		btn.add_theme_stylebox_override("normal", b_style)

		# VBox chứa: số phím, icon, số lượng
		var v = VBoxContainer.new()
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		v.add_theme_constant_override("separation", 0)
		btn.add_child(v)

		var top_lbl = Label.new()
		top_lbl.text = "[%d]" % (i + 1)
		top_lbl.add_theme_font_size_override("font_size", 9)
		top_lbl.modulate = Color(0.4, 0.85, 1.0)
		top_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(top_lbl)

		var icon_lbl = Label.new()
		var item_id = hotbar_item_ids[i]
		var def = InventoryManagerScript.ITEM_DEFINITIONS.get(item_id, {})
		icon_lbl.text = def.get("icon", "📦")
		icon_lbl.add_theme_font_size_override("font_size", 16)
		icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(icon_lbl)
		hotbar_slot_icons.append(icon_lbl)

		var count_lbl = Label.new()
		count_lbl.text = "x0"
		count_lbl.add_theme_font_size_override("font_size", 9)
		count_lbl.modulate = Color(1.0, 0.95, 0.8)
		count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(count_lbl)
		hotbar_slot_labels.append(count_lbl)

		var slot_idx = i
		btn.pressed.connect(func(): _on_hotbar_slot_clicked(slot_idx))
		hbox.add_child(btn)
		hotbar_slot_buttons.append(btn)

	add_child(hotbar_panel)
	_update_hotbar_display()

var _cached_slot_style_active: StyleBoxFlat = null
var _cached_slot_style_normal: StyleBoxFlat = null

func update_hotbar_display() -> void:
	_update_hotbar_display()

func _get_slot_style(active: bool) -> StyleBoxFlat:
	if _cached_slot_style_active == null:
		_cached_slot_style_active = StyleBoxFlat.new()
		_cached_slot_style_active.set_corner_radius_all(6)
		_cached_slot_style_active.bg_color = Color(0.18, 0.28, 0.42, 0.98)
		_cached_slot_style_active.border_color = Color(1.0, 0.85, 0.25, 1.0)
		_cached_slot_style_active.set_border_width_all(2)

		_cached_slot_style_normal = StyleBoxFlat.new()
		_cached_slot_style_normal.set_corner_radius_all(6)
		_cached_slot_style_normal.bg_color = Color(0.08, 0.13, 0.22, 0.9)
		_cached_slot_style_normal.border_color = Color(0.25, 0.4, 0.6, 0.5)
		_cached_slot_style_normal.set_border_width_all(1)
	return _cached_slot_style_active if active else _cached_slot_style_normal

func _update_hotbar_display() -> void:
	if hotbar_slot_labels.is_empty():
		return
	for i in range(hotbar_item_ids.size()):
		var item_id = hotbar_item_ids[i]
		var count = InventoryManagerScript.get_item_count(item_id)
		var def = InventoryManagerScript.ITEM_DEFINITIONS.get(item_id, {})
		if i < hotbar_slot_icons.size():
			hotbar_slot_icons[i].text = def.get("icon", "📦")
		if i < hotbar_slot_labels.size():
			hotbar_slot_labels[i].text = "x%d" % count
			hotbar_slot_labels[i].modulate = Color(1.0, 0.95, 0.7) if count > 0 else Color(0.45, 0.5, 0.55)

		# Cập nhật viền nút (selected vs normal) bằng StyleBox dùng chung đã cache
		if i < hotbar_slot_buttons.size():
			var btn = hotbar_slot_buttons[i]
			btn.add_theme_stylebox_override("normal", _get_slot_style(i == hotbar_selected_index))

func set_selected_hotbar_slot(idx: int) -> void:
	hotbar_selected_index = idx
	_update_hotbar_display()

func _on_hotbar_slot_clicked(idx: int) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("select_hotbar_slot"):
		player.select_hotbar_slot(idx)

# ------------------------------------------------------------------------------
# 1. HỆ THỐNG TOAST THÔNG BÁO NỔI
# ------------------------------------------------------------------------------
func _setup_toast_ui() -> void:
	toast_panel = PanelContainer.new()
	toast_panel.name = "ToastPanel"
	toast_panel.visible = false

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.12, 0.18, 0.94)
	style.border_color = Color(0.96, 0.82, 0.25, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.expand_margin_left = 16.0
	style.expand_margin_right = 16.0
	style.expand_margin_top = 8.0
	style.expand_margin_bottom = 8.0
	toast_panel.add_theme_stylebox_override("panel", style)

	toast_panel.anchors_preset = Control.PRESET_BOTTOM_WIDE
	toast_panel.anchor_left = 0.5
	toast_panel.anchor_right = 0.5
	toast_panel.anchor_top = 1.0
	toast_panel.anchor_bottom = 1.0
	toast_panel.offset_left = -340.0
	toast_panel.offset_right = 340.0
	toast_panel.offset_top = -155.0
	toast_panel.offset_bottom = -102.0

	toast_label = Label.new()
	toast_label.name = "ToastLabel"
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toast_label.add_theme_font_size_override("font_size", 17)
	toast_label.modulate = Color(1.0, 0.95, 0.8)
	toast_label.text = ""
	toast_panel.add_child(toast_label)

	add_child(toast_panel)

func show_toast(msg: String, duration: float = 3.6) -> void:
	last_toast_message = msg
	if toast_label and toast_panel:
		toast_label.text = msg
		toast_panel.visible = true
		toast_timer = duration
	print("[HUD] 💬 Toast: %s" % msg)

func _setup_life_activity_modal() -> void:
	life_activity_modal = PanelContainer.new()
	life_activity_modal.name = "LifeActivityModal"
	life_activity_modal.visible = false
	life_activity_modal.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	life_activity_modal.custom_minimum_size = Vector2(460.0, 0.0)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.10, 0.18, 0.97)
	style.border_color = Color(0.96, 0.82, 0.25, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.content_margin_left = 24.0
	style.content_margin_right = 24.0
	style.content_margin_top = 20.0
	style.content_margin_bottom = 20.0
	life_activity_modal.add_theme_stylebox_override("panel", style)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	life_activity_modal.add_child(content)

	life_activity_title = Label.new()
	life_activity_title.add_theme_font_size_override("font_size", 22)
	life_activity_title.modulate = Color(1.0, 0.88, 0.25)
	content.add_child(life_activity_title)

	life_activity_description = Label.new()
	life_activity_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(life_activity_description)

	life_activity_options = VBoxContainer.new()
	life_activity_options.add_theme_constant_override("separation", 8)
	content.add_child(life_activity_options)
	add_child(life_activity_modal)

func open_life_activity_options(title: String, description: String, options: Array[Dictionary], player: Node3D, station: Node3D) -> void:
	life_activity_title.text = title
	life_activity_description.text = description
	life_activity_player = player
	life_activity_station = station
	life_activity_buttons.clear()
	for child in life_activity_options.get_children():
		child.queue_free()
	for option in options:
		var button := Button.new()
		button.text = String(option.get("text", "Chọn"))
		button.custom_minimum_size.y = 38.0
		var action := String(option.get("action", "cancel"))
		button.pressed.connect(_on_life_activity_option.bind(action))
		life_activity_options.add_child(button)
		life_activity_buttons[action] = button
	life_activity_modal.visible = true
	if not life_activity_options.get_children().is_empty():
		(life_activity_options.get_child(0) as Button).grab_focus()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func is_life_activity_options_open() -> bool:
	return life_activity_modal != null and life_activity_modal.visible

func close_life_activity_options() -> void:
	if life_activity_modal:
		life_activity_modal.visible = false
	life_activity_player = null
	life_activity_station = null
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_life_activity_option(action: String) -> void:
	var player := life_activity_player
	var station := life_activity_station
	close_life_activity_options()
	if player == null or not is_instance_valid(player) or station == null or not is_instance_valid(station):
		push_warning("[HUD] Hoạt động đời sống đã hủy vì người chơi hoặc địa điểm không còn khả dụng.")
		return
	match action:
		"bed_lie":
			if player.has_method("begin_life_activity"):
				player.begin_life_activity("lying", station)
				show_toast("🛏️ Bạn đang nằm thư giãn. Nhấn [E] để đứng dậy; thời gian vẫn tiếp tục.")
		"bed_sleep":
			if station.has_method("complete_bed_sleep") and player.has_method("begin_life_activity"):
				player.begin_life_activity("lying", station)
				station.complete_bed_sleep(player)
		"desk_sit":
			if player.has_method("begin_life_activity"):
				player.begin_life_activity("sitting", station)
				show_toast("🪑 Bạn đang làm việc: tiến độ tăng dần, thể lực hồi nhẹ và độ tập trung giảm tự nhiên. Nhấn [E] để đứng dậy.")
		"desk_sign":
			if station.has_method("complete_desk_work"):
				station.complete_desk_work(player)

# ------------------------------------------------------------------------------
# 2. HỆ THỐNG HỘP THOẠI ANIME RPG (NPC DIALOGUE BOX)
# ------------------------------------------------------------------------------
func _setup_dialogue_modal_ui() -> void:
	dialogue_modal = PanelContainer.new()
	dialogue_modal.name = "DialogueModal"
	dialogue_modal.visible = false

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.10, 0.18, 0.96)
	style.border_color = Color(0.96, 0.82, 0.25, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.expand_margin_left = 20.0
	style.expand_margin_right = 20.0
	style.expand_margin_top = 16.0
	style.expand_margin_bottom = 16.0
	dialogue_modal.add_theme_stylebox_override("panel", style)

	dialogue_modal.anchors_preset = Control.PRESET_BOTTOM_WIDE
	dialogue_modal.anchor_left = 0.5
	dialogue_modal.anchor_right = 0.5
	dialogue_modal.anchor_top = 1.0
	dialogue_modal.anchor_bottom = 1.0
	dialogue_modal.offset_left = -460.0
	dialogue_modal.offset_right = 460.0
	dialogue_modal.offset_top = -240.0
	dialogue_modal.offset_bottom = -30.0

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	dialogue_modal.add_child(hbox)

	# Cột chân dung Avatar
	dlg_avatar_label = Label.new()
	dlg_avatar_label.name = "AvatarLabel"
	dlg_avatar_label.text = "🧑‍🌾"
	dlg_avatar_label.add_theme_font_size_override("font_size", 54)
	dlg_avatar_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(dlg_avatar_label)

	# Cột nội dung hội thoại & danh sách nút lựa chọn
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)
	hbox.add_child(vbox)

	var header_box = HBoxContainer.new()
	vbox.add_child(header_box)

	dlg_name_label = Label.new()
	dlg_name_label.name = "SpeakerName"
	dlg_name_label.text = "Bác Nam"
	dlg_name_label.add_theme_font_size_override("font_size", 18)
	dlg_name_label.modulate = Color(1.0, 0.88, 0.25)
	header_box.add_child(dlg_name_label)

	dlg_role_label = Label.new()
	dlg_role_label.name = "SpeakerRole"
	dlg_role_label.text = "(Nghệ Nhân Bánh Mì)"
	dlg_role_label.add_theme_font_size_override("font_size", 13)
	dlg_role_label.modulate = Color(0.7, 0.85, 1.0)
	header_box.add_child(dlg_role_label)

	dlg_text_label = Label.new()
	dlg_text_label.name = "DialogueSpeech"
	dlg_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dlg_text_label.add_theme_font_size_override("font_size", 15)
	dlg_text_label.modulate = Color(0.95, 0.96, 0.98)
	dlg_text_label.text = "Lời thoại nhân vật..."
	vbox.add_child(dlg_text_label)

	var sep = HSeparator.new()
	vbox.add_child(sep)

	dlg_options_container = VBoxContainer.new()
	dlg_options_container.name = "OptionsList"
	dlg_options_container.add_theme_constant_override("separation", 6)
	vbox.add_child(dlg_options_container)

	add_child(dialogue_modal)

func open_npc_dialogue(npc: Node3D) -> void:
	current_dialogue_npc = npc
	var npc_id = npc.get("npc_id") if npc.get("npc_id") != null else "citizen"
	var data = DialogueManagerScript.get_dialogue_data_for_npc(str(npc_id))

	# Kích hoạt PhantomCamera đối thoại Anime qua vai nếu có
	var player = get_tree().get_first_node_in_group("player")
	var cam_ctrl = get_tree().get_first_node_in_group("cinematic_cameras")
	if cam_ctrl and cam_ctrl.has_method("activate_dialogue_camera") and player:
		cam_ctrl.activate_dialogue_camera(npc, player)

	# Kích hoạt khẩu hình miệng Anime Lip-sync cho NPC nếu có
	if npc.has_method("start_speaking"):
		npc.start_speaking(3.5)

	dlg_name_label.text = data["name"]
	var role_text = "(%s)" % data["role"]
	if "current_activity" in npc and npc.current_activity != "":
		role_text += " • %s %s" % [npc.current_activity_icon, npc.current_activity]
	dlg_role_label.text = role_text
	dlg_avatar_label.text = data["avatar"]
	if "dialogue_text" in npc and npc.dialogue_text != "":
		dlg_text_label.text = npc.dialogue_text
	else:
		dlg_text_label.text = data["greeting"]

	# Dọn sạch các nút cũ
	for c in dlg_options_container.get_children():
		c.queue_free()

	for opt in data["options"]:
		var btn = Button.new()
		btn.text = "▶ " + opt["text"]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var act = opt["action"]
		btn.pressed.connect(func(): _handle_dialogue_action(act))
		dlg_options_container.add_child(btn)

	dialogue_modal.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func close_npc_dialogue() -> void:
	if dialogue_modal:
		dialogue_modal.visible = false

	var cam_ctrl = get_tree().get_first_node_in_group("cinematic_cameras")
	if cam_ctrl and cam_ctrl.has_method("deactivate_dialogue_camera"):
		cam_ctrl.deactivate_dialogue_camera()

	if current_dialogue_npc and is_instance_valid(current_dialogue_npc) and current_dialogue_npc.has_method("stop_speaking"):
		current_dialogue_npc.stop_speaking()

	current_dialogue_npc = null
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _grant_item_with_toast(item_id: String, qty: int, success_message: String) -> bool:
	if not InventoryManagerScript.add_item(item_id, qty):
		show_toast("Cặp mang theo đã đầy; hãy cất bớt đồ trong kho văn phòng.")
		return false
	show_toast(success_message)
	return true

func _handle_dialogue_action(action: String) -> void:
	var player = get_tree().get_first_node_in_group("player")
	var wm = get_node_or_null("/root/WorldManager")

	match action:
		"give_baguette":
			if _grant_item_with_toast("item_baguette", 1, "🥖 Bác Nam đã trao bạn 1 Ổ Bánh Mì Baguette giòn thơm!"):
				AudioSynthesizerScript.play_sound(self, "fanfare")
				mark_quest_done("quest_bakery")
				close_npc_dialogue()

		"give_tea":
			if _grant_item_with_toast("item_herbal_tea", 1, "🌿 Chị Mai tặng bạn 1 Bình Trà Thảo Mộc Tuyết Sơn dưỡng sinh!"):
				AudioSynthesizerScript.play_sound(self, "fanfare")
				mark_quest_done("quest_clinic")
				close_npc_dialogue()

		"give_buggy_key":
			if _grant_item_with_toast("item_buggy_key", 1, "🔑 Kỹ Sư Tuấn đã trao Chìa Khóa Xe Buggy Điện! Xe sẵn sàng ở bãi đỗ."):
				AudioSynthesizerScript.play_sound(self, "fanfare")
				close_npc_dialogue()

		"open_cccd":
			var npc = current_dialogue_npc
			close_npc_dialogue()
			if npc and has_method("open_citizen_id_card"):
				open_citizen_id_card(npc)

		"open_petitions":
			close_npc_dialogue()
			open_petition_modal()

		"ring_bell":
			if wm:
				wm.trigger_bell_ringing()
			show_toast("🔔 Chuông Hòa Bình ngân vang theo lời thỉnh cầu của Mục Tử David!")
			mark_quest_done("quest_bell")
			close_npc_dialogue()

		"quest_east_wheat":
			show_toast("🌾 Đã nhận nhiệm vụ: Đến Cối Xay Gió Huyện Đông nhận bao lúa mì cho Bác Nam!")
			AudioSynthesizerScript.play_sound(self, "fanfare")
			close_npc_dialogue()

		"give_wheat_sack":
			if _grant_item_with_toast("item_wheat_sack", 1, "🌾 Bác Hai đã trao bạn 1 Bao Lúa Mì Hữu Cơ vàng ươm!"):
				AudioSynthesizerScript.play_sound(self, "fanfare")
				close_npc_dialogue()

		"deliver_wheat_sack":
			if InventoryManagerScript.exchange_items("item_wheat_sack", 1, "item_special_bread", 2):
				if wm:
					wm.deposit_city_tax(500.0)
				show_toast("🌾 Hoàn thành tiếp tế! Bác Nam tặng 2 Bánh Mì Hoa Cúc Mật Ong (+500Đ Ngân Khố)!")
				AudioSynthesizerScript.play_sound(self, "fanfare")
				mark_quest_done("quest_district_east_wheat")
			else:
				show_toast("Cần có bao lúa mì và đủ chỗ trong cặp để nhận phần thưởng.")
			close_npc_dialogue()

		"quest_north_herb":
			show_toast("♨️ Đã nhận nhiệm vụ: Đến Suối Khoáng Onsen Huyện Bắc thu hái mẫu thảo dược!")
			AudioSynthesizerScript.play_sound(self, "fanfare")
			close_npc_dialogue()

		"give_onsen_herb":
			if _grant_item_with_toast("item_onsen_herb", 1, "♨️ Thợ Rừng Lâm đã trao bạn Thảo Dược Suối Khoáng Onsen quý hiếm!"):
				AudioSynthesizerScript.play_sound(self, "fanfare")
				close_npc_dialogue()

		"bathe_onsen":
			if player and player.has_method("heal"):
				player.heal(100.0)
			show_toast("♨️ Bạn đã ngâm mình trong dòng suối Onsen ấm áp! Sinh lực hồi phục 100%!")
			AudioSynthesizerScript.play_sound(self, "bell")
			close_npc_dialogue()

		"deliver_onsen_herb":
			if InventoryManagerScript.exchange_items("item_onsen_herb", 1, "item_royal_tea", 2):
				if wm:
					wm.deposit_city_tax(500.0)
				show_toast("♨️ Hoàn thành dược liệu! Chị Mai tặng 2 Bình Trà Thảo Mộc Hoàng Gia (+500Đ Ngân Khố)!")
				AudioSynthesizerScript.play_sound(self, "fanfare")
				mark_quest_done("quest_district_north_herb")
			else:
				show_toast("Cần có thảo dược và đủ chỗ trong cặp để nhận phần thưởng.")
			close_npc_dialogue()

		"quest_west_power":
			show_toast("⚡ Đã nhận nhiệm vụ: Tuần tra trạm sạc điện mặt trời tại Đồi Quạt Gió Huyện Tây!")
			AudioSynthesizerScript.play_sound(self, "fanfare")
			close_npc_dialogue()

		"give_solar_battery":
			if _grant_item_with_toast("item_solar_battery", 1, "⚡ Kỹ Sư Khoa trao Khối Pin Năng Lượng Mặt Trời sạc đầy 100%!"):
				AudioSynthesizerScript.play_sound(self, "fanfare")
				close_npc_dialogue()

		"inspect_ev_station":
			show_toast("🚗 Trạm sạc nhanh EV và Xe Buggy Huyện Tây đang hoạt động ổn định 100%!")
			close_npc_dialogue()

		"deliver_solar_battery":
			if InventoryManagerScript.remove_item("item_solar_battery", 1):
				if wm:
					wm.deposit_city_tax(500.0)
				show_toast("⚡ Đã kết nối lưới điện Huyện Tây! Kỹ Sư Tuấn kích hoạt trạm sạc siêu tốc (+500Đ Ngân Khố)!")
				AudioSynthesizerScript.play_sound(self, "fanfare")
				mark_quest_done("quest_district_west_power")
			close_npc_dialogue()

		"quest_south_port":
			show_toast("⚓ Đã nhận nhiệm vụ: Đến Cầu Cảng Huyện Nam đón tàu cá và chúc lành cho ngư dân!")
			AudioSynthesizerScript.play_sound(self, "fanfare")
			close_npc_dialogue()

		"give_fresh_fish":
			if _grant_item_with_toast("item_fresh_fish", 1, "🐟 Thuyền Trưởng Hải trao Thùng Hải Sản Tươi Ngon vừa đánh bắt!"):
				AudioSynthesizerScript.play_sound(self, "fanfare")
				close_npc_dialogue()

		"inspect_harbor":
			show_toast("⚓ Ngọn hải đăng và bến cảng luôn sẵn sàng đón tiếp lữ khách hòa bình!")
			close_npc_dialogue()

		"deliver_fresh_fish":
			if InventoryManagerScript.remove_item("item_fresh_fish", 1):
				if wm:
					wm.deposit_church_tithe(1000.0)
					wm.trigger_bell_ringing()
				show_toast("🐟 Bàn giao hải sản chuẩn bị Đại Tiệc Agape! Mục Tử David chúc phước (+1.000Đ Quỹ 1/10)!")
				AudioSynthesizerScript.play_sound(self, "fanfare")
				mark_quest_done("quest_district_south_port")
			close_npc_dialogue()

		"tell_agape":
			dlg_text_label.text = "Mục Tử David: 'Bữa tiệc Bác Ái diễn ra sau Thánh Lễ, mọi người cùng chia sẻ bánh mì, trái ngọt và chúc lành cho sự phồn vinh của Tân Thế Giới!'"

		"close":
			close_npc_dialogue()

# ------------------------------------------------------------------------------
# 3. HỆ THỐNG TÚI ĐỒ THỊ TRƯỞNG (INVENTORY MODAL)
# ------------------------------------------------------------------------------
func _setup_inventory_modal_ui() -> void:
	inventory_modal = PanelContainer.new()
	inventory_modal.name = "InventoryModal"
	inventory_modal.visible = false

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.12, 0.18, 0.96)
	style.border_color = Color(0.35, 0.65, 0.95, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.expand_margin_left = 20.0
	style.expand_margin_right = 20.0
	style.expand_margin_top = 16.0
	style.expand_margin_bottom = 16.0
	inventory_modal.add_theme_stylebox_override("panel", style)

	inventory_modal.anchors_preset = Control.PRESET_CENTER
	inventory_modal.anchor_left = 0.5
	inventory_modal.anchor_right = 0.5
	inventory_modal.anchor_top = 0.5
	inventory_modal.anchor_bottom = 0.5
	inventory_modal.offset_left = -300.0
	inventory_modal.offset_right = 300.0
	inventory_modal.offset_top = -220.0
	inventory_modal.offset_bottom = 220.0

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	inventory_modal.add_child(vbox)

	var hbox_hdr = HBoxContainer.new()
	vbox.add_child(hbox_hdr)

	var title = Label.new()
	title.text = "🎒 TÚI ĐỒ CÁ NHÂN CỦA THỊ TRƯỞNG"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 18)
	title.modulate = Color(1.0, 0.88, 0.25)
	hbox_hdr.add_child(title)

	var close_btn = Button.new()
	close_btn.text = " ✕ "
	close_btn.pressed.connect(close_inventory_modal)
	hbox_hdr.add_child(close_btn)

	var sep = HSeparator.new()
	vbox.add_child(sep)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	inv_items_container = VBoxContainer.new()
	inv_items_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inv_items_container.add_theme_constant_override("separation", 8)
	scroll.add_child(inv_items_container)

	add_child(inventory_modal)

	# Bổ sung nhãn Vitals ở TopBar
	var topbar_hbox = get_node_or_null("TopBar/Margin/HBox")
	if topbar_hbox:
		vitals_label = Label.new()
		vitals_label.name = "VitalsLabel"
		vitals_label.text = "❤️ Sinh Lực: 100/100 HP | ⚡ Thể Lực: 100/100"
		vitals_label.add_theme_font_size_override("font_size", 14)
		vitals_label.modulate = Color(0.4, 0.95, 0.6)
		topbar_hbox.add_child(vitals_label)

func open_inventory_modal() -> void:
	_refresh_inventory_ui()
	if office_storage_modal:
		office_storage_modal.visible = false
	if wardrobe_modal:
		wardrobe_modal.visible = false
	inventory_modal.visible = true
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("open_briefcase_view"):
		player.open_briefcase_view()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func close_inventory_modal() -> void:
	if inventory_modal:
		inventory_modal.visible = false
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("close_briefcase_view"):
		player.close_briefcase_view()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func toggle_inventory_modal() -> void:
	if inventory_modal.visible:
		close_inventory_modal()
	else:
		open_inventory_modal()

func _refresh_inventory_ui() -> void:
	for c in inv_items_container.get_children():
		c.queue_free()

	var items = InventoryManagerScript.get_all_items()
	if items.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "Túi đồ hiện đang trống..."
		empty_lbl.modulate = Color(0.7, 0.7, 0.7)
		inv_items_container.add_child(empty_lbl)
		return

	for item_id in items.keys():
		var qty = items[item_id]
		var def = InventoryManagerScript.ITEM_DEFINITIONS.get(item_id, null)
		if def == null:
			continue

		var item_panel = PanelContainer.new()
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 12)

		var icon_lbl = Label.new()
		icon_lbl.text = def["icon"]
		icon_lbl.add_theme_font_size_override("font_size", 28)
		hbox.add_child(icon_lbl)

		var info_vbox = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var name_lbl = Label.new()
		name_lbl.text = "%s (x%d)" % [def["name"], qty]
		name_lbl.add_theme_font_size_override("font_size", 14)
		name_lbl.modulate = Color(0.95, 0.90, 0.4)
		info_vbox.add_child(name_lbl)

		var desc_lbl = Label.new()
		desc_lbl.text = def["desc"]
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.add_theme_font_size_override("font_size", 11)
		desc_lbl.modulate = Color(0.8, 0.85, 0.9)
		info_vbox.add_child(desc_lbl)

		hbox.add_child(info_vbox)

		if def["type"] == "consumable":
			var use_btn = Button.new()
			use_btn.text = " Dùng "
			use_btn.pressed.connect(func():
				var p = get_tree().get_first_node_in_group("player")
				InventoryManagerScript.use_item(item_id, p)
				_refresh_inventory_ui()
			)
			hbox.add_child(use_btn)

		item_panel.add_child(hbox)
		inv_items_container.add_child(item_panel)

func _setup_mayor_office_storage_modal_ui() -> void:
	office_storage_modal = PanelContainer.new()
	office_storage_modal.name = "MayorOfficeStorageModal"
	office_storage_modal.visible = false
	office_storage_modal.anchors_preset = Control.PRESET_CENTER
	office_storage_modal.anchor_left = 0.5
	office_storage_modal.anchor_right = 0.5
	office_storage_modal.anchor_top = 0.5
	office_storage_modal.anchor_bottom = 0.5
	office_storage_modal.offset_left = -420.0
	office_storage_modal.offset_right = 420.0
	office_storage_modal.offset_top = -270.0
	office_storage_modal.offset_bottom = 270.0

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.06, 0.09, 0.14, 0.98)
	panel_style.border_color = Color(0.78, 0.59, 0.24, 0.95)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(10)
	office_storage_modal.add_theme_stylebox_override("panel", panel_style)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	office_storage_modal.add_child(content)
	var header := HBoxContainer.new()
	content.add_child(header)

	var title := Label.new()
	title.text = "🗄️ KHO RIÊNG • VĂN PHÒNG THỊ TRƯỞNG"
	title.add_theme_font_size_override("font_size", 18)
	title.modulate = Color(1.0, 0.88, 0.3)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var close_button := Button.new()
	close_button.text = "Đóng"
	close_button.pressed.connect(close_mayor_office_storage_modal)
	header.add_child(close_button)

	office_storage_summary_label = Label.new()
	office_storage_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(office_storage_summary_label)
	content.add_child(HSeparator.new())

	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 14)
	content.add_child(columns)
	office_case_items_container = _create_office_storage_column(columns, "🎒 CẶP MANG THEO")
	office_store_items_container = _create_office_storage_column(columns, "🏢 KHO VĂN PHÒNG")
	add_child(office_storage_modal)

func _create_office_storage_column(parent: HBoxContainer, title_text: String) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(column)
	var title := Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 15)
	column.add_child(title)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	var items := VBoxContainer.new()
	items.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	items.add_theme_constant_override("separation", 6)
	scroll.add_child(items)
	return items

func open_mayor_office_storage_modal(storage: Node3D) -> void:
	if storage == null or not is_instance_valid(storage):
		push_error("[HUD] Không thể mở kho: điểm tương tác không còn tồn tại.")
		return
	office_storage_source = storage
	if inventory_modal:
		inventory_modal.visible = false
	if wardrobe_modal:
		wardrobe_modal.visible = false
	_refresh_mayor_office_storage_ui()
	office_storage_modal.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func close_mayor_office_storage_modal() -> void:
	if office_storage_modal:
		office_storage_modal.visible = false
	office_storage_source = null
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _refresh_mayor_office_storage_ui() -> void:
	if office_case_items_container == null or office_store_items_container == null:
		return
	for container in [office_case_items_container, office_store_items_container]:
		for child in container.get_children():
			child.queue_free()

	var case_items: Dictionary = InventoryManagerScript.get_all_items()
	var stored_items: Dictionary = InventoryManagerScript.get_office_storage_items()
	var case_weight: float = InventoryManagerScript.get_inventory_weight_kg()
	var stored_weight: float = InventoryManagerScript.get_office_storage_weight_kg()
	office_storage_summary_label.text = "Cặp: %.1f / %.0f kg     •     Kho văn phòng: %.1f / %.0f kg" % [
		case_weight,
		InventoryManagerScript.BRIEFCASE_CAPACITY_KG,
		stored_weight,
		InventoryManagerScript.OFFICE_STORAGE_CAPACITY_KG
	]
	_add_office_storage_item_rows(office_case_items_container, case_items, true, stored_weight)
	_add_office_storage_item_rows(office_store_items_container, stored_items, false, case_weight)

func _add_office_storage_item_rows(container: VBoxContainer, items: Dictionary, is_briefcase: bool, destination_weight: float) -> void:
	if items.is_empty():
		var empty_label := Label.new()
		empty_label.text = "Trống"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.modulate = Color(0.7, 0.75, 0.82)
		container.add_child(empty_label)
		return

	for item_id in items:
		var item_def: Dictionary = InventoryManagerScript.ITEM_DEFINITIONS.get(item_id, {})
		if item_def.is_empty():
			continue
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		container.add_child(row)
		var item_label := Label.new()
		item_label.text = "%s %s ×%d (%.1f kg)" % [
			item_def["icon"],
			item_def["name"],
			int(items[item_id]),
			float(item_def["weight_kg"]) * int(items[item_id])
		]
		item_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(item_label)

		var transfer_button := Button.new()
		transfer_button.name = ("Store_" if is_briefcase else "Take_") + String(item_id)
		transfer_button.text = "Cất 1 →" if is_briefcase else "← Lấy 1"
		transfer_button.disabled = _office_transfer_would_exceed_capacity(
			item_id, is_briefcase, destination_weight
		)
		transfer_button.pressed.connect(_request_office_item_transfer.bind(item_id, is_briefcase))
		row.add_child(transfer_button)

func _office_transfer_would_exceed_capacity(item_id: String, is_storing: bool, destination_weight: float) -> bool:
	var item_def: Dictionary = InventoryManagerScript.ITEM_DEFINITIONS.get(item_id, {})
	if item_def.is_empty():
		return true
	var capacity := InventoryManagerScript.OFFICE_STORAGE_CAPACITY_KG if is_storing else InventoryManagerScript.BRIEFCASE_CAPACITY_KG
	return destination_weight + float(item_def["weight_kg"]) > capacity

func _request_office_item_transfer(item_id: String, is_storing: bool) -> void:
	if office_storage_source == null or not is_instance_valid(office_storage_source):
		show_toast("Kho văn phòng không còn khả dụng.")
		close_mayor_office_storage_modal()
		return
	var player := get_tree().get_first_node_in_group("player")
	if player == null or not player.has_method("animate_item_transfer"):
		push_error("[HUD] Không thể chuyển đồ: Player thiếu hoạt ảnh chuyển vật phẩm.")
		show_toast("Không thể chuyển đồ lúc này.")
		return
	var available_count := InventoryManagerScript.get_item_count(item_id) if is_storing else InventoryManagerScript.get_storage_item_count(item_id)
	if available_count <= 0 or _office_transfer_would_exceed_capacity(
		item_id,
		is_storing,
		InventoryManagerScript.get_office_storage_weight_kg() if is_storing else InventoryManagerScript.get_inventory_weight_kg()
	):
		show_toast("Không đủ chỗ hoặc vật phẩm đã được chuyển.")
		_refresh_mayor_office_storage_ui()
		return
	if player.global_position.distance_to(office_storage_source.global_position) > float(office_storage_source.get("interaction_radius")):
		show_toast("Hãy đứng cạnh tủ hồ sơ để chuyển đồ.")
		close_mayor_office_storage_modal()
		return

	var animation_started: bool = player.animate_item_transfer(item_id, func() -> void:
		var transferred := InventoryManagerScript.store_item(item_id) if is_storing else InventoryManagerScript.take_from_office(item_id)
		if transferred:
			var item_name: String = InventoryManagerScript.ITEM_DEFINITIONS[item_id]["name"]
			var message := "Đã cất %s vào kho văn phòng." % item_name if is_storing else "Đã lấy %s vào cặp." % item_name
			show_toast(message)
		else:
			push_error("[HUD] Chuyển vật phẩm thất bại sau hoạt ảnh: %s." % item_id)
			show_toast("Chuyển đồ thất bại; vật phẩm vẫn được giữ nguyên.")
		_refresh_mayor_office_storage_ui()
	)
	if not animation_started:
		show_toast("Nhân vật đang thao tác với vật phẩm. Vui lòng đợi.")

# ------------------------------------------------------------------------------
# 3b. HỆ THỐNG TỦ TRANG PHỤC THỊ TRƯỞNG (WARDROBE OUTFIT CHANGER)
# ------------------------------------------------------------------------------
func _setup_wardrobe_modal_ui() -> void:
	wardrobe_modal = PanelContainer.new()
	wardrobe_modal.name = "WardrobeModal"
	wardrobe_modal.visible = false
	wardrobe_modal.anchors_preset = Control.PRESET_CENTER
	wardrobe_modal.anchor_left = 0.5
	wardrobe_modal.anchor_right = 0.5
	wardrobe_modal.anchor_top = 0.5
	wardrobe_modal.anchor_bottom = 0.5
	wardrobe_modal.offset_left = -280.0
	wardrobe_modal.offset_right = 280.0
	wardrobe_modal.offset_top = -180.0
	wardrobe_modal.offset_bottom = 180.0

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.06, 0.09, 0.15, 0.98)
	panel_style.border_color = Color(0.92, 0.78, 0.28, 0.95)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(10)
	panel_style.expand_margin_left = 16.0
	panel_style.expand_margin_right = 16.0
	panel_style.expand_margin_top = 16.0
	panel_style.expand_margin_bottom = 16.0
	wardrobe_modal.add_theme_stylebox_override("panel", panel_style)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	wardrobe_modal.add_child(content)

	var header := HBoxContainer.new()
	content.add_child(header)

	var title := Label.new()
	title.text = "🪞 TỦ TRANG PHỤC THỊ TRƯỞNG • PHÒNG MASTER"
	title.add_theme_font_size_override("font_size", 17)
	title.modulate = Color(1.0, 0.88, 0.3)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var close_button := Button.new()
	close_button.name = "CloseWardrobeButton"
	close_button.text = " ✕ "
	close_button.pressed.connect(close_wardrobe_modal)
	header.add_child(close_button)

	content.add_child(HSeparator.new())

	var subtitle := Label.new()
	subtitle.text = "Chọn trang phục công vụ & sinh hoạt thường nhật của Thị Trưởng:"
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.modulate = Color(0.85, 0.88, 0.95)
	content.add_child(subtitle)

	var btn_list := VBoxContainer.new()
	btn_list.add_theme_constant_override("separation", 8)
	content.add_child(btn_list)

	var outfits = [
		{
			"id": "formal",
			"name": "👔 Âu Phục Lễ Tân Ngoại Giao",
			"desc": "Áo vest xanh hoàng gia, cầu vai mạ vàng, quần tây trắng, giày da bóng."
		},
		{
			"id": "outdoor",
			"name": "🌲 Đồ Dã Ngoại & Thị Sát Rừng Núi",
			"desc": "Áo khoác rêu dã chiến, quần túi hộp kaki sẫm, ủng da lội suối."
		},
		{
			"id": "sleepwear",
			"name": "🌙 Đồ Ngủ Lụa Thư Giãn",
			"desc": "Pajamas lụa xanh sapphire thoáng mát, dép bông êm ái cho giấc ngủ ngon."
		}
	]

	for outfit in outfits:
		var outfit_id: String = outfit["id"]
		var btn := Button.new()
		btn.name = "Select_outfit_" + outfit_id
		btn.text = "%s\n  %s" % [outfit["name"], outfit["desc"]]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_font_size_override("font_size", 14)
		btn.pressed.connect(_on_select_outfit.bind(outfit_id))
		btn_list.add_child(btn)

	add_child(wardrobe_modal)

func open_wardrobe_modal(wardrobe: Node3D) -> void:
	if wardrobe == null or not is_instance_valid(wardrobe):
		push_error("[HUD] Không thể mở tủ trang phục: vật thể không tồn tại.")
		return
	current_wardrobe_source = wardrobe
	if inventory_modal:
		inventory_modal.visible = false
	if office_storage_modal:
		office_storage_modal.visible = false
	wardrobe_modal.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func close_wardrobe_modal() -> void:
	if wardrobe_modal:
		wardrobe_modal.visible = false
	current_wardrobe_source = null
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_select_outfit(outfit_id: String) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player != null and player.has_method("set_outfit"):
		player.set_outfit(outfit_id)
	close_wardrobe_modal()

# ------------------------------------------------------------------------------
# 4. HỆ THỐNG QUEST TRACKER ĐÔ THỊ TRUNG TÂM
# ------------------------------------------------------------------------------
func _setup_quest_tracker_ui() -> void:
	quest_tracker_panel = PanelContainer.new()
	quest_tracker_panel.name = "QuestTrackerPanel"

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.10, 0.16, 0.88)
	style.border_color = Color(0.35, 0.55, 0.85, 0.8)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.expand_margin_left = 12.0
	style.expand_margin_right = 12.0
	style.expand_margin_top = 10.0
	style.expand_margin_bottom = 10.0
	quest_tracker_panel.add_theme_stylebox_override("panel", style)

	quest_tracker_panel.anchors_preset = Control.PRESET_TOP_RIGHT
	quest_tracker_panel.anchor_left = 1.0
	quest_tracker_panel.anchor_right = 1.0
	quest_tracker_panel.anchor_top = 0.0
	quest_tracker_panel.anchor_bottom = 0.0
	quest_tracker_panel.offset_left = -340.0
	quest_tracker_panel.offset_right = -15.0
	quest_tracker_panel.offset_top = 278.0
	quest_tracker_panel.offset_bottom = 578.0

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	quest_tracker_panel.add_child(vbox)

	quest_title_label = Label.new()
	quest_title_label.name = "QuestTitleLabel"
	quest_title_label.text = "🎯 TIẾN ĐỘ ĐÔ THỊ & 5 HUYỆN (0/%d)" % quests_data.size()
	quest_title_label.add_theme_font_size_override("font_size", 13)
	quest_title_label.modulate = Color(0.96, 0.85, 0.3)
	vbox.add_child(quest_title_label)

	var sep = HSeparator.new()
	vbox.add_child(sep)

	for qid in quests_data.keys():
		var qdata = quests_data[qid]
		var qlbl = Label.new()
		qlbl.name = "QuestItem_" + qid
		qlbl.text = "○ %s: %s" % [qdata["title"], qdata["desc"]]
		qlbl.add_theme_font_size_override("font_size", 11)
		qlbl.modulate = Color(0.85, 0.88, 0.92)
		vbox.add_child(qlbl)
		quest_items[qid] = qlbl

	add_child(quest_tracker_panel)

func mark_quest_done(quest_id: String) -> void:
	if not quests_data.has(quest_id):
		return

	var qdata = quests_data[quest_id]
	if qdata["done"]:
		return

	qdata["done"] = true

	if quest_items.has(quest_id):
		var lbl: Label = quest_items[quest_id]
		lbl.text = "✅ %s (Xong)" % [qdata["title"]]
		lbl.modulate = Color(0.3, 0.95, 0.45)

	var completed = 0
	for q in quests_data.values():
		if q["done"]:
			completed += 1

	if quest_title_label:
		quest_title_label.text = "🎯 TIẾN ĐỘ ĐÔ THỊ & 5 HUYỆN (%d/%d)" % [completed, quests_data.size()]

	AudioSynthesizerScript.play_sound(self, "fanfare")

	if completed == quests_data.size():
		var wm = get_node_or_null("/root/WorldManager")
		if wm:
			wm.deposit_city_tax(10000.0)
			wm.deposit_church_tithe(5000.0)
		show_toast("🎉 KỲ TÍCH TÂN THẾ GIỚI! Thị Trưởng đã kết nối hoàn hảo Thủ Phủ và 4 Huyện Ngoại Vi (12/12 Nhiệm Vụ)!", 6.0)

# ------------------------------------------------------------------------------
# 5. HỘP THOẠI BẢNG TIN NGUYỆN VỌNG CƯ DÂN 5 HUYỆN
# ------------------------------------------------------------------------------
func _setup_petition_modal_ui() -> void:
	petition_modal = PanelContainer.new()
	petition_modal.name = "PetitionModal"
	petition_modal.visible = false

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.12, 0.18, 0.96)
	style.border_color = Color(0.96, 0.82, 0.25, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.expand_margin_left = 20.0
	style.expand_margin_right = 20.0
	style.expand_margin_top = 20.0
	style.expand_margin_bottom = 20.0
	petition_modal.add_theme_stylebox_override("panel", style)

	petition_modal.anchors_preset = Control.PRESET_CENTER
	petition_modal.anchor_left = 0.5
	petition_modal.anchor_right = 0.5
	petition_modal.anchor_top = 0.5
	petition_modal.anchor_bottom = 0.5
	petition_modal.offset_left = -320.0
	petition_modal.offset_right = 320.0
	petition_modal.offset_top = -220.0
	petition_modal.offset_bottom = 220.0

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	petition_modal.add_child(vbox)

	var hbox_hdr = HBoxContainer.new()
	vbox.add_child(hbox_hdr)

	var title = Label.new()
	title.text = "📜 NGUYỆN VỌNG CƯ DÂN 5 HUYỆN GỬI THỊ TRƯỞNG"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 18)
	title.modulate = Color(1.0, 0.88, 0.25)
	hbox_hdr.add_child(title)

	petition_close_btn = Button.new()
	petition_close_btn.text = " ✕ "
	petition_close_btn.pressed.connect(close_petition_modal)
	hbox_hdr.add_child(petition_close_btn)

	var sep = HSeparator.new()
	vbox.add_child(sep)

	var petitions_text = [
		"🌾 [Huyện Đông - Đồng Bằng]: Xin cấp thêm men vi sinh hữu cơ để nâng cao sản lượng lúa mì.",
		"💨 [Huyện Tây - Đồi Điện Gió]: Đề xuất lắp thêm trạm sạc điện mặt trời cho xe buggy nông nghiệp.",
		"🌊 [Huyện Bắc - Thung Lũng Cối Xay Nước]: Cần đội tình nguyện NHVC hỗ trợ gia cố guồng gỗ.",
		"⛵ [Huyện Nam - Biển & Hải Đăng]: Ngư dân báo cáo luồng cá hồi sinh dồi dào quanh cầu cảng.",
		"🕊️ [Trung Tâm Thủ Phủ]: Cư dân hân hoan đón chờ Thánh Lễ Phụng Vụ và Bữa Tiệc Bác Ái Agape."
	]

	for p in petitions_text:
		var p_lbl = Label.new()
		p_lbl.text = p
		p_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p_lbl.add_theme_font_size_override("font_size", 14)
		p_lbl.modulate = Color(0.92, 0.95, 0.98)
		vbox.add_child(p_lbl)

	add_child(petition_modal)

func open_petition_modal() -> void:
	if petition_modal:
		petition_modal.visible = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func close_petition_modal() -> void:
	if petition_modal:
		petition_modal.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# ------------------------------------------------------------------------------
# 6. CÁC HÀM TIỆN ÍCH KHÁC (ĐỒNG HỒ, HR MODAL, MACRO MAP)
# ------------------------------------------------------------------------------
func open_citizen_id_card(npc: Node3D) -> void:
	if citizen_modal:
		citizen_modal.display_citizen(npc)

func open_macro_map() -> void:
	if macro_map_modal:
		macro_map_modal.open_macro_map()

func close_macro_map() -> void:
	if macro_map_modal:
		macro_map_modal.close_macro_map()

func toggle_macro_map() -> void:
	if macro_map_modal:
		if macro_map_modal.visible:
			close_macro_map()
		else:
			open_macro_map()

func _update_clock_display() -> void:
	var wm = get_node_or_null("/root/WorldManager")
	if wm and clock_label:
		var slot_str = ""
		if wm.has_method("get_current_time_slot_name"):
			slot_str = " | %s %s" % [wm.get_current_time_slot_icon(), wm.get_current_time_slot_name()]
		clock_label.text = "🕒 " + wm.get_formatted_time() + slot_str

func _on_time_ticked(_day: int, _h: int, _m: int, _dname: String) -> void:
	_update_clock_display()

func _on_liturgy_started(day_name: String) -> void:
	liturgy_banner.visible = true
	liturgy_label.text = "🔔 THÁNH LỄ ĐANG DIỄN RA (%s: 11:40 - 14:00) TẠI TÒA NHÀ TRUNG TÂM" % day_name

func _on_liturgy_ended(_day_name: String) -> void:
	liturgy_banner.visible = false

func _on_treasury_updated(city: float, tithe: float) -> void:
	_update_treasury_display(city, tithe)

func _update_treasury_display(city: float, tithe: float) -> void:
	if treasury_label:
		treasury_label.text = "🏛️ Kho Bạc: %d Đ" % int(city)
	if tithe_label:
		tithe_label.text = "🕊️ Quỹ 1/10 Dâng Chúa: %d Đ" % int(tithe)

func open_hr_board(ent: EnterpriseData) -> void:
	current_open_enterprise = ent
	hr_modal.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_refresh_hr_display()

func close_hr_board() -> void:
	hr_modal.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_close_hr_pressed() -> void:
	close_hr_board()

func _refresh_hr_display() -> void:
	if not current_open_enterprise:
		return

	ent_name_label.text = "🏢 " + current_open_enterprise.enterprise_name

	if current_open_enterprise.is_prosperous:
		ent_status_badge.text = "✨ TỔ CHỨC PHỒN VINH (+50% Năng suất)"
		ent_status_badge.modulate = Color(0.2, 0.9, 0.4)
	elif current_open_enterprise.has_bottleneck:
		ent_status_badge.text = "⚠️ NGHẼN QUẢN TRỊ (-30% Năng suất)"
		ent_status_badge.modulate = Color(0.9, 0.3, 0.2)
	else:
		ent_status_badge.text = "🌱 Quy mô bình ổn (Năng suất: 100%)"
		ent_status_badge.modulate = Color(0.3, 0.7, 0.9)

	for child in div_list_container.get_children():
		child.queue_free()

	var div_titles = [
		{"name": "1. Ban Nội Vụ & Nhân Sự", "cert": "CERT_CIVIC_ADMIN"},
		{"name": "2. Ban Tài Chính & Kế Toán", "cert": "CERT_FINANCE_BANKING"},
		{"name": "3. Ban Đào Tạo & Kèm Cặp (L&D)", "cert": "CERT_EDU_*"},
		{"name": "4. Ban Kế Hoạch & Chiến Lược", "cert": "CERT_CIVIC_ADMIN / CERT_LOGISTICS_SUPPLY"},
		{"name": "5. Ban Kỹ Thuật & Bảo Trì CSVC", "cert": "CERT_POWER_GRID / CERT_AUTO_MECHANIC"},
		{"name": "6. Ban Kiểm Chuẩn CL & Môi Trường", "cert": "CERT_ENVIRONMENTAL_HEALTH"},
		{"name": "7. Ban Truyền Thông, Media & Sự Kiện", "cert": "CERT_JOURNALISM_MEDIA / CERT_CINEMA_VIDEOGRAPHY"},
		{"name": "8. Ban Mục Vụ, Tư Vấn Tâm Lý & Hòa Bình", "cert": "CERT_DIVINE_SHEPHERD / CERT_MEDICINE_GENERAL"},
		{"name": "9. Ban Ca Ngợi, Âm Nhạc Phụng Vụ & Thờ Phượng", "cert": "CERT_SACRED_MUSIC / CERT_LITURGICAL_ARTS"}
	]

	for i in range(div_titles.size()):
		var info = div_titles[i]
		var item_panel = PanelContainer.new()
		var hbox = HBoxContainer.new()

		var title_lbl = Label.new()
		title_lbl.text = "%s [%s]" % [info["name"], info["cert"]]
		title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(title_lbl)

		var status_lbl = Label.new()
		var head_id = current_open_enterprise.department_heads.get(i, "")
		if str(head_id).is_empty():
			status_lbl.text = "🔴 Chưa bổ nhiệm"
			status_lbl.modulate = Color(0.9, 0.4, 0.4)
		else:
			status_lbl.text = "🟢 Đã bổ nhiệm (#%s)" % str(head_id)
			status_lbl.modulate = Color(0.3, 0.9, 0.4)

		hbox.add_child(status_lbl)
		item_panel.add_child(hbox)
		div_list_container.add_child(item_panel)
