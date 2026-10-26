class_name MacroMapModal
extends PanelContainer

# ==============================================================================
# MACRO MAP & CIVIC OS TABLET (TABLET THỊ TRƯỞNG - HỆ ĐIỀU HÀNH ĐÔ THỊ 6 ỨNG DỤNG)
# Theo đúng Master Concept Section 2.2:
# 1. Ứng dụng 1: Bản Đồ & Du Hành Nhanh (City Map & Fast Travel 500 km²)
# 2. Ứng dụng 2: Sổ Bộ Hộ Tịch & 14.400 Cư Dân (Civil Registry & Demographics)
# 3. Ứng dụng 3: Doanh Nghiệp & 14 Khối Nghề (Corporate Governance & HR Quotas)
# 4. Ứng dụng 4: Kho Tài Nguyên Đô Thị (Urban Resource Pool)
# 5. Ứng dụng 5: Kho Bạc & Ngân Hàng Nhà Nước (City Treasury & Tithe Fund)
# 6. Ứng dụng 6: Giao Thông & Phụng Vụ (Transit & Liturgy Monitor)
# Hiệu Ứng Slow-Motion 20%: Khi mở Tablet, thời gian thực địa chạy chậm lại 20%!
# ==============================================================================

signal map_closed
signal fast_travel_requested(target_pos: Vector3)

const DailyScheduleManagerScript = preload("res://scripts/simulation/daily_schedule_manager.gd")
const TauPlotClass = preload("res://addons/tau-plot/plot/plot.gd")

# UI Elements
@onready var close_btn: Button = $Margin/VBox/Header/CloseButton
@onready var gps_label: Label = $Margin/VBox/Header/GPSLabel
@onready var status_feedback: Label = $Margin/VBox/Content/RightPanel/StatusFeedback if has_node("Margin/VBox/Content/RightPanel/StatusFeedback") else null

# Tab 1: Map
@onready var poi_option_list: ItemList = $Margin/VBox/Content/LeftPanel/POIList if has_node("Margin/VBox/Content/LeftPanel/POIList") else null
@onready var poi_title_label: Label = $Margin/VBox/Content/RightPanel/DetailContainer/DetailMargin/DetailVBox/POITitle if has_node("Margin/VBox/Content/RightPanel/DetailContainer/DetailMargin/DetailVBox/POITitle") else null
@onready var poi_desc_label: Label = $Margin/VBox/Content/RightPanel/DetailContainer/DetailMargin/DetailVBox/POIDesc if has_node("Margin/VBox/Content/RightPanel/DetailContainer/DetailMargin/DetailVBox/POIDesc") else null
@onready var poi_coord_label: Label = $Margin/VBox/Content/RightPanel/DetailContainer/DetailMargin/DetailVBox/POICoords if has_node("Margin/VBox/Content/RightPanel/DetailContainer/DetailMargin/DetailVBox/POICoords") else null
@onready var travel_btn: Button = $Margin/VBox/Content/RightPanel/TravelButton if has_node("Margin/VBox/Content/RightPanel/TravelButton") else null

# Dynamic Tab Views
var tab_bar: HBoxContainer
var map_view_container: Control
var civic_pages_container: Control
var current_tab_index: int = 0
var selected_has_branch: String = "materials"

var player_ref: Node3D
var selected_poi_index: int = 0

# Danh bạ 10 Địa Danh Cốt Lõi (Master Concept POIs)
var poi_catalog: Array[Dictionary] = [
	{
		"name": "🏛️ Đỉnh Núi Trung Tâm (Central Hub)",
		"pos": Vector3(0.0, 600.0, 0.0),
		"district": "Huyện Đỉnh Vát (Cao độ +600m)",
		"desc": "Mega Office Tân Thế Giới, Đại Hội Trường 15.000 chỗ và Quảng Trường Hòa Bình."
	},
	{
		"name": "🚊 Ga Tram Mega Office (Central Tram Stop)",
		"pos": Vector3(0.0, 600.0, 132.5),
		"district": "Khu trung tâm",
		"desc": "Ga tram tuyến Đông–Tây nằm ngoài Quảng Trường Hòa Bình, kết nối Mega Office với các khu vực lân cận."
	},
	{
		"name": "🌊 Hồ Đỉnh Cao Nguyên (Summit Reservoir Lake)",
		"pos": Vector3(-2000.0, 590.0, -3000.0),
		"district": "Hồ Đầu Nguồn Tây Bắc",
		"desc": "Hồ trữ nước ngọt rộng lớn 1.5 km² sâu 50m, bến thuyền gỗ và cống xả điều tiết thủy lợi cho toàn vùng."
	},
	{
		"name": "🌿 Đồng Cỏ Cao Nguyên Phía Nam (South High Meadow)",
		"pos": Vector3(0.0, 600.0, 12000.0),
		"district": "Cao Nguyên Xanh Phía Nam (+600m)",
		"desc": "Thảo nguyên bạt ngàn êm dịu, gió mát lành nhìn ngắm toàn cảnh dãy núi viền chân trời phía nam không còn vực sâu thác nước."
	},
	{
		"name": "🏞️ Mỏm Đá Ngắm Cảnh (Scenic Lookout Cliff)",
		"pos": Vector3(1000.0, 300.0, 13000.0),
		"district": "Vách Đá Sa Thạch Đông Nam",
		"desc": "Mỏm đá sa thạch nhô dài 18m giữa không trung, điểm ngắm bình minh trên biển mây đẹp nhất thế giới."
	},
	{
		"name": "🌲 Huyện Bắc Đại Ngàn & Mỏ Đá (North Forest)",
		"pos": Vector3(0.0, 50.0, -10000.0),
		"district": "Huyện Bắc (Chân Núi R=10km)",
		"desc": "Vùng đại ngàn thông reo bạt ngàn, suối khoáng nóng Onsen hồi phục sinh lực và khu mỏ đá quý sinh thái."
	},
	{
		"name": "🌾 Huyện Đông Nông Trại & Thảo Nguyên (East Farmlands)",
		"pos": Vector3(10000.0, 30.0, 0.0),
		"district": "Huyện Đông (Chân Núi R=10km)",
		"desc": "Vựa lúa mạch sinh thái bao la, các nông trang chăn nuôi hữu cơ và làng nghề chế biến nông sản phồn vinh."
	},
	{
		"name": "⚙️ Huyện Tây Kỹ Nghệ & Thung Lũng Gió (West Industry)",
		"pos": Vector3(-10000.0, 40.0, 0.0),
		"district": "Huyện Tây (Chân Núi R=10km)",
		"desc": "Thung lũng quạt gió năng lượng sạch, xưởng chế tác cơ khí chính xác, bảo dưỡng máy móc và ô tô tự hành."
	},
	{
		"name": "⚓ Huyện Nam Cảng Hòa Bình (South Peace Port)",
		"pos": Vector3(0.0, 10.0, 20000.0),
		"district": "Huyện Nam Duyên Hải (R=20km)",
		"desc": "Cảng biển mây quốc tế đón tiếp lữ khách phương xa, trung tâm giao thương thịnh vượng và hội nhập."
	},
	{
		"name": "🧗 Đường Đèo Núi Nam (Southern Mountain Pass)",
		"pos": Vector3(0.0, 140.0, 8000.0),
		"district": "Đèo Núi Trung Gian",
		"desc": "Cung đường đèo uốn lượn xuyên qua tầng mây, nối liền chân núi với đỉnh cao nguyên hùng vĩ."
	}
]

# Dữ liệu mô phỏng doanh nghiệp & nút thắt cổ chai
var east_wheat_bottleneck: bool = true
var total_scholarships_granted: int = 0

func _ready() -> void:
	visible = false
	if close_btn and not close_btn.pressed.is_connected(_on_close_pressed):
		close_btn.pressed.connect(_on_close_pressed)
	if travel_btn and not travel_btn.pressed.is_connected(_on_travel_pressed):
		travel_btn.pressed.connect(_on_travel_pressed)
	if poi_option_list:
		if not poi_option_list.item_selected.is_connected(_on_poi_selected):
			poi_option_list.item_selected.connect(_on_poi_selected)
		_populate_poi_list()

	if tab_bar == null:
		_setup_civic_tabs()

func _setup_civic_tabs() -> void:
	var vbox = $Margin/VBox
	map_view_container = $Margin/VBox/Content

	# Tạo Thanh Điều Hướng 6 Tab Ứng Dụng (Diegetic Civic OS)
	tab_bar = HBoxContainer.new()
	tab_bar.name = "CivicTabBar"
	tab_bar.add_theme_constant_override("separation", 6)

	var tab_names = [
		"🗺️ 1. Bản Đồ",
		"👥 2. Sổ Hộ Tịch",
		"🏢 3. Doanh Nghiệp",
		"🌾 4. Tài Nguyên",
		"🏛️ 5. Kho Bạc",
		"🔔 6. Phụng Vụ",
		"🔬 7. R&D Viện HAS",
		"🏡 8. Nhà Ở & Sổ Đỏ"
	]

	for i in range(tab_names.size()):
		var btn = Button.new()
		btn.text = tab_names[i]
		btn.custom_minimum_size = Vector2(115, 34)
		btn.add_theme_font_size_override("font_size", 12)
		btn.pressed.connect(_on_tab_clicked.bind(i))
		tab_bar.add_child(btn)

	# Chèn TabBar ngay dưới Header
	vbox.add_child(tab_bar)
	vbox.move_child(tab_bar, 1)

	# Container chứa các trang ứng dụng
	civic_pages_container = PanelContainer.new()
	civic_pages_container.name = "CivicPagesContainer"
	civic_pages_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	civic_pages_container.visible = false
	
	var page_style = StyleBoxFlat.new()
	page_style.bg_color = Color(0.10, 0.14, 0.22, 0.90)
	page_style.corner_radius_top_left = 8
	page_style.corner_radius_top_right = 8
	page_style.corner_radius_bottom_left = 8
	page_style.corner_radius_bottom_right = 8
	civic_pages_container.add_theme_stylebox_override("panel", page_style)
	vbox.add_child(civic_pages_container)
	# Di chuyển CivicPagesContainer xuống sau Content (tab 1 bản đồ)
	var content_idx = map_view_container.get_index()
	vbox.move_child(civic_pages_container, content_idx + 1)

func _on_tab_clicked(index: int) -> void:
	current_tab_index = index
	_highlight_active_tab(index)

	if index == 0:
		# Tab 1: Bản đồ
		map_view_container.visible = true
		civic_pages_container.visible = false
	else:
		map_view_container.visible = false
		civic_pages_container.visible = true
		_render_civic_page(index)

func _highlight_active_tab(active_idx: int) -> void:
	for i in range(tab_bar.get_child_count()):
		var b = tab_bar.get_child(i) as Button
		if b:
			if i == active_idx:
				b.modulate = Color(1.0, 0.9, 0.3)
			else:
				b.modulate = Color(1.0, 1.0, 1.0)

func _render_civic_page(idx: int) -> void:
	# Dọn dẹp nội dung cũ
	for child in civic_pages_container.get_children():
		child.queue_free()

	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	civic_pages_container.add_child(scroll)

	var margin = MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 16)
	scroll.add_child(margin)

	match idx:
		1:
			_render_page_civil_registry(margin)
		2:
			_render_page_enterprises(margin)
		3:
			_render_page_resources(margin)
		4:
			_render_page_treasury(margin)
		5:
			_render_page_liturgy(margin)
		6:
			_render_page_has_research(margin)
		7:
			_render_page_housing_plots(margin)

func _render_page_civil_registry(parent: Control) -> void:
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	parent.add_child(vbox)

	var title = Label.new()
	title.text = "👥 SỔ BỘ HỘ TỊCH ĐÔ THỊ (CIVIL REGISTRY & DEMOGRAPHICS)"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.3))
	vbox.add_child(title)

	# Lấy dữ liệu sống từ CitizenManager
	var cm = _get_citizen_manager()
	var total_pop: int = cm.get_total_population() if (cm and cm.has_method("get_total_population")) else 300
	var pop_cap: int = cm.current_population_cap if cm else 300
	var harmony: float = cm.get_harmony_index() if (cm and cm.has_method("get_harmony_index")) else 98.8
	var housing_slots: int = cm.get_available_housing_slots() if (cm and cm.has_method("get_available_housing_slots")) else 120
	var nhvc = cm.get_nhvc_counts() if (cm and cm.has_method("get_nhvc_counts")) else {"full_time": 8, "part_time": 23}
	var support_count: int = cm.get_community_support_count() if (cm and cm.has_method("get_community_support_count")) else 18

	var stats_box = HBoxContainer.new()
	stats_box.add_theme_constant_override("separation", 20)
	vbox.add_child(stats_box)

	var lbl1 = Label.new()
	lbl1.text = "🏛️ Dân số: %d / %d Cư dân (Giai đoạn 1)" % [total_pop, pop_cap]
	lbl1.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0))
	stats_box.add_child(lbl1)

	var lbl2 = Label.new()
	lbl2.text = "🕊️ Hòa Hợp: %.1f%% | Nhà trống: %d phòng" % [harmony, housing_slots]
	lbl2.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
	stats_box.add_child(lbl2)

	vbox.add_child(HSeparator.new())

	# Bảng phân bổ NHVC
	var nhvc_title = Label.new()
	nhvc_title.text = "✝️ NHÂN SỰ NHVC (NGƯỜI HẦU VIỆC CHÚA):"
	nhvc_title.add_theme_font_size_override("font_size", 13)
	nhvc_title.add_theme_color_override("font_color", Color(0.9, 0.8, 1.0))
	vbox.add_child(nhvc_title)

	var nhvc_hbox = HBoxContainer.new()
	nhvc_hbox.add_theme_constant_override("separation", 30)
	vbox.add_child(nhvc_hbox)

	var nhvc_ft = Label.new()
	nhvc_ft.text = "🏛️ Toàn Thời Gian (Full-time): %d người\nLương đồng nhất, mặc vest, chế độ dưỡng sức" % nhvc["full_time"]
	nhvc_ft.add_theme_color_override("font_color", Color(1.0, 0.88, 0.4))
	nhvc_hbox.add_child(nhvc_ft)

	var nhvc_pt = Label.new()
	nhvc_pt.text = "🤝 Tình Nguyện Viên Bán TG (Part-time): %d người\n100%% Phụng sự tự nguyện, có nghề riêng" % nhvc["part_time"]
	nhvc_pt.add_theme_color_override("font_color", Color(0.7, 0.95, 0.7))
	nhvc_hbox.add_child(nhvc_pt)

	var support_lbl = Label.new()
	support_lbl.text = "💛 Cư dân cần hỗ trợ cộng đồng: %d người" % support_count
	support_lbl.add_theme_color_override("font_color", Color(0.9, 0.75, 0.4))
	nhvc_hbox.add_child(support_lbl)

	vbox.add_child(HSeparator.new())

	# Bảng phân bổ 4 độ tuổi từ CitizenManager
	var age_grid = GridContainer.new()
	age_grid.columns = 2
	age_grid.add_theme_constant_override("h_separation", 30)
	age_grid.add_theme_constant_override("v_separation", 6)
	vbox.add_child(age_grid)

	var fellow_stats = cm.get_fellowship_stats() if (cm and cm.has_method("get_fellowship_stats")) else {}
	var au_nhi: int = fellow_stats.get("AU_NHI", 0)
	var thanh_nien: int = fellow_stats.get("THANH_NIEN", 0)
	var phu_nu: int = fellow_stats.get("PHU_NU", 0)
	var trang_nien: int = fellow_stats.get("TRANG_NIEN", 0)

	var safe_total: int = maxi(1, total_pop)
	var age_data = [
		["👶 Thiếu Nhi & Học Viên (Nhóm Âu Nhi):", "%d em (%.1f%%) - Chăm ngoan, hiếu học" % [au_nhi, float(au_nhi) / safe_total * 100.0]],
		["🎒 Thanh Niên & Người Trẻ (Nhóm Thanh Niên):", "%d bạn (%.1f%%) - Năng động, sáng tạo" % [thanh_nien, float(thanh_nien) / safe_total * 100.0]],
		["💼 Phụ Nữ & Gia Đình (Nhóm Phụ Nữ):", "%d người (%.1f%%) - Trụ cột gia đình" % [phu_nu, float(phu_nu) / safe_total * 100.0]],
		["👴 Trung Niên & Nghệ Nhân (Nhóm Tráng Niên):", "%d nghệ nhân (%.1f%%) - Truyền thụ nghề" % [trang_nien, float(trang_nien) / safe_total * 100.0]]
	]
	for row in age_data:
		var k = Label.new()
		k.text = row[0]
		k.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		age_grid.add_child(k)
		var v = Label.new()
		v.text = row[1]
		v.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
		age_grid.add_child(v)

	vbox.add_child(HSeparator.new())

	var sub_title = Label.new()
	sub_title.text = "📋 DANH BẠ 8 CƯ DÂN TIÊU BIỂU TRÊN CAO NGUYÊN:"
	sub_title.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	vbox.add_child(sub_title)

	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 180)
	vbox.add_child(scroll)

	var resident_list = VBoxContainer.new()
	resident_list.add_theme_constant_override("separation", 6)
	scroll.add_child(resident_list)

	var citizens = [
		"• Bác Hai (56t) - Nông Dân Sinh Thái (CERT_AGRI_CROPS) | CCCD: TTG-2026-0082 | Ven suối ngọc",
		"• Anh Tùng (27t) - Thợ Mộc Mỹ Nghệ (CERT_CARPENTRY) | CCCD: TTG-2026-0104 | Bờ suối phía Tây",
		"• Anh Khoa (24t) - Kỹ Sư Cầu Đường (CERT_CIVIC_ADMIN) | CCCD: TTG-2026-0033 | Đại lộ phía Nam",
		"• Chị Mai (26t) - Bác Sĩ Nghỉ Dưỡng (CERT_DOCTOR_PHYSICIAN) | CCCD: TTG-2026-0077 | Trạm y tế xanh",
		"• Bác Nam (52t) - Thợ Bánh Mì (CERT_BAKERY_CHEF) | CCCD: TTG-2026-0021 | Tiệm bánh thủ công",
		"• Thầy Minh (33t) - Giáo Viên Học Viện (CERT_EDU_PRIMARY) | CCCD: TTG-2026-0055 | Giảng đường Bắc",
		"• Em Linh (17t) - Học Viên Mỹ Thuật (CERT_MUSIC_PERFORMANCE) | CCCD: TTG-2026-0210 | Vườn tranh nghệ thuật",
		"• Bé Bo (9t) - Cư Dân Nhí (CERT_PRIMARY_EDU) | CCCD: TTG-2026-0345 | Sân chơi trẻ em"
	]
	for c in citizens:
		var lbl = Label.new()
		lbl.text = c
		lbl.add_theme_font_size_override("font_size", 13)
		resident_list.add_child(lbl)


# ------------------------------------------------------------------------------
# TRANG 3: QUẢN TRỊ DOANH NGHIỆP & HỌC VIỆN (ENTERPRISES & HR QUOTAS)
# ------------------------------------------------------------------------------
func _render_page_enterprises(parent: Control) -> void:
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	parent.add_child(vbox)

	var title = Label.new()
	title.text = "🏢 QUẢN TRỊ DOANH NGHIỆP & HỌC VIỆN POLYTECHNIC (14 KHỐI NGHỀ)"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.3))
	vbox.add_child(title)

	var desc = Label.new()
	desc.text = "Mô hình quản trị doanh nghiệp chuẩn mực: Cơ sở >= 16 nhân sự kiện toàn 8 Trưởng Ban Chuyên Ngành."
	desc.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95))
	vbox.add_child(desc)

	vbox.add_child(HSeparator.new())

	# Cơ sở 1: Nông trang Đông
	var b_box = PanelContainer.new()
	var b_style = StyleBoxFlat.new()
	b_style.bg_color = Color(0.14, 0.18, 0.28, 0.8)
	b_style.corner_radius_top_left = 6
	b_style.corner_radius_top_right = 6
	b_style.corner_radius_bottom_left = 6
	b_style.corner_radius_bottom_right = 6
	b_box.add_theme_stylebox_override("panel", b_style)
	vbox.add_child(b_box)

	var b_margin = MarginContainer.new()
	b_margin.add_theme_constant_override("margin_left", 12)
	b_margin.add_theme_constant_override("margin_top", 10)
	b_margin.add_theme_constant_override("margin_right", 12)
	b_margin.add_theme_constant_override("margin_bottom", 10)
	b_box.add_child(b_margin)

	var b_vbox = VBoxContainer.new()
	b_margin.add_child(b_vbox)

	var ent1_title = Label.new()
	ent1_title.text = "🌾 Hợp Tác Xã Lúa Mì Huyện Đông (35 nhân sự)"
	ent1_title.add_theme_font_size_override("font_size", 14)
	ent1_title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	b_vbox.add_child(ent1_title)

	var ent1_status = Label.new()
	if east_wheat_bottleneck:
		ent1_status.text = "⚠️ TRẠNG THÁI: NÚT THẮT CỔ CHAI (Thiếu 5 thợ gặt lúa CERT_AGRI_CROPS) | Năng suất: 0.7x"
		ent1_status.add_theme_color_override("font_color", Color(1.0, 0.4, 0.3))
	else:
		ent1_status.text = "✅ TRẠNG THÁI: PHỒN VINH HOÀN TOÀN (Kiện toàn đủ 8 Ban) | Năng suất: 1.5x Tối Đa"
		ent1_status.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
	b_vbox.add_child(ent1_status)

	var btn_action = Button.new()
	btn_action.text = "🎓 CẤP HẠN MỨC 10 SUẤT HỌC BỔNG NÔNG NGHIỆP [CERT_AGRI_CROPS]"
	btn_action.disabled = not east_wheat_bottleneck
	btn_action.pressed.connect(_on_grant_scholarship_pressed)
	b_vbox.add_child(btn_action)

	# Các doanh nghiệp khác
	var other_box = VBoxContainer.new()
	other_box.add_theme_constant_override("separation", 4)
	vbox.add_child(other_box)

	var ent2 = Label.new()
	ent2.text = "🥖 Tiệm Bánh Mì Bác Nam: 12 thợ thủ công | Năng suất 1.2x | Đủ bột mì và men hữu cơ."
	other_box.add_child(ent2)

	var ent3 = Label.new()
	ent3.text = "🪚 Xưởng Mộc Mỹ Nghệ Anh Tùng: 8 nghệ nhân | Năng suất 1.3x | Nguồn gỗ sồi dồi dào."
	other_box.add_child(ent3)

	var ent4 = Label.new()
	ent4.text = "⚙️ Nhà Máy Cơ Khí Sạch Huyện Tây: 28 kỹ sư | Năng suất 1.5x | Đầy đủ linh kiện bảo trì."
	other_box.add_child(ent4)

func _get_world_manager() -> Node:
	if Engine.has_singleton("WorldManager"):
		return Engine.get_singleton("WorldManager")
	if is_inside_tree():
		if has_node("/root/WorldManager"):
			return get_node("/root/WorldManager")
	return null

func _get_citizen_manager() -> Node:
	if Engine.has_singleton("CitizenManager"):
		return Engine.get_singleton("CitizenManager")
	if is_inside_tree():
		if has_node("/root/CitizenManager"):
			return get_node("/root/CitizenManager")
		var found = get_tree().get_first_node_in_group("citizen_manager")
		if found:
			return found
	return null

func _get_research_manager() -> Node:
	if Engine.has_singleton("ResearchManager"):
		return Engine.get_singleton("ResearchManager")
	if is_inside_tree():
		if has_node("/root/ResearchManager"):
			return get_node("/root/ResearchManager")
	return null

func _on_grant_scholarship_pressed() -> void:
	var cm = get_node_or_null("/root/CitizenManager")
	var wm = _get_world_manager()
	if wm == null:
		return
	if not wm.has_method("withdraw_city_budget") or not wm.withdraw_city_budget(1000.0):
		if status_feedback:
			status_feedback.text = "⚠️ Ngân sách Thành phố không đủ 1.000 Đ để cấp học bổng!"
		return
	east_wheat_bottleneck = false
	total_scholarships_granted += 10
	_render_civic_page(2) # Refresh lại trang doanh nghiệp
	print("[CivicOS] 🎓 Thị Trưởng đã phê duyệt hạn mức 10 suất học bổng CERT_AGRI_CROPS!")

# ------------------------------------------------------------------------------
# TRANG 4: KHO TÀI NGUYÊN ĐÔ THỊ & BIỂU ĐỒ SẢN LƯỢNG 5 HUYỆN (TAUPLOT INTEGRATION)
# ------------------------------------------------------------------------------
func _render_page_resources(parent: Control) -> void:
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 14)
	parent.add_child(vbox)

	var title = Label.new()
	title.text = "🌾 KHO TÀI NGUYÊN & BIỂU ĐỒ SẢN LƯỢNG 5 HUYỆN (CIVIC OUTPUT MATRIX)"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.3))
	vbox.add_child(title)

	# 1. BIỂU ĐỒ CỘT TAUPLOT: SẢN LƯỢNG THỰC TẾ VS CHỈ TIÊU 5 HUYỆN
	var chart_card = PanelContainer.new()
	var chart_style = StyleBoxFlat.new()
	chart_style.bg_color = Color(0.06, 0.09, 0.16, 0.85)
	chart_style.corner_radius_top_left = 8
	chart_style.corner_radius_top_right = 8
	chart_style.corner_radius_bottom_left = 8
	chart_style.corner_radius_bottom_right = 8
	chart_card.add_theme_stylebox_override("panel", chart_style)
	vbox.add_child(chart_card)

	var chart_margin = MarginContainer.new()
	chart_margin.add_theme_constant_override("margin_left", 12)
	chart_margin.add_theme_constant_override("margin_top", 10)
	chart_margin.add_theme_constant_override("margin_right", 12)
	chart_margin.add_theme_constant_override("margin_bottom", 10)
	chart_card.add_child(chart_margin)

	var chart_node = _create_district_production_chart()
	chart_margin.add_child(chart_node)

	vbox.add_child(HSeparator.new())

	var sub_title = Label.new()
	sub_title.text = "📦 CHI TIẾT TRỮ LƯỢNG 8 LUỒNG VẬT TƯ CỐT LÕI:"
	sub_title.add_theme_font_size_override("font_size", 14)
	sub_title.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	vbox.add_child(sub_title)

	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 35)
	grid.add_theme_constant_override("v_separation", 10)
	vbox.add_child(grid)

	var res_items = [
		["🌾 Lúa Mì Sinh Thái (Huyện Đông):", "48.500 kg (+350 kg/h) - Dồi dào"],
		["🥖 Bột Mì Hảo Hạng (Thủ Phủ):", "12.400 kg (+120 kg/h) - Dồi dào"],
		["🥛 Sữa Tươi Hữu Cơ (Huyện Đông):", "8.900 lít (+85 lít/h) - Dồi dào"],
		["🪵 Gỗ Sồi Rừng Bắc (Huyện Bắc):", "15.200 m³ (+65 m³/h) - Ổn định"],
		["💎 Sa Thạch & Đá Quý (Huyện Bắc):", "34.000 tấn (+210 tấn/h) - Dồi dào"],
		["⚙️ Linh Kiện Thay Thế (Huyện Tây):", "5.600 bộ (+45 bộ/h) - Đạt chuẩn"],
		["⚡ Điện Năng Sạch (Huyện Tây):", "4.8 MW / 4.8 MW (100% Gió & Nắng)"],
		["💧 Trữ Lượng Nước Ngọt (Đỉnh Cao Nguyên):", "75.000.000 m³ (Hồ Đỉnh Cao Nguyên)"]
	]

	for item in res_items:
		var k = Label.new()
		k.text = item[0]
		k.add_theme_font_size_override("font_size", 13)
		k.add_theme_color_override("font_color", Color(0.85, 0.95, 1.0))
		grid.add_child(k)

		var v = Label.new()
		v.text = item[1]
		v.add_theme_font_size_override("font_size", 13)
		v.add_theme_color_override("font_color", Color(0.3, 1.0, 0.6))
		grid.add_child(v)

func _create_district_production_chart() -> Control:
	var plot = TauPlotClass.new()
	plot.custom_minimum_size = Vector2(0, 230)
	plot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	plot.theme_type_variation = &"TauPlot"
	plot.title = "📊 SẢN LƯỢNG KINH TẾ 5 HUYỆN (THỰC TẾ VS CHỈ TIÊU - NGHÌN ĐƠN VỊ)"

	var y_data: Array[PackedFloat64Array] = [
		PackedFloat64Array([48.5, 48.0, 35.0, 30.0, 40.0]),
		PackedFloat64Array([40.0, 42.0, 30.0, 28.0, 35.0]),
	]
	var dataset = TauPlotClass.Dataset.make_shared_x_categorical(
		PackedStringArray(["Sản Lượng Thực Tế (Actual)", "Chỉ Tiêu Đô Thị (Target)"]),
		PackedStringArray(["🌾 Đông (Lúa Mì)", "⚡ Tây (Điện Gió)", "🌲 Bắc (Dược Liệu)", "⚓ Nam (Thủy Sản)", "🏛️ Thủ Phủ (Dịch Vụ)"]),
		y_data
	)

	var x_axis = TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CATEGORICAL

	var y_axis = TauAxisConfig.new()
	y_axis.title = "Nghìn Đơn Vị (k Units)"

	var bar_overlay_config = TauBarConfig.new()
	var overlays_arr: Array[TauPaneOverlayConfig] = [bar_overlay_config]

	var pane = TauPaneConfig.new()
	pane.y_left_axis = y_axis
	pane.overlays = overlays_arr

	var panes_arr: Array[TauPaneConfig] = [pane]
	var config = TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = panes_arr

	var b0 = TauXYSeriesBinding.new()
	b0.series_id = dataset.get_series_id_by_index(0)
	b0.pane_index = 0
	b0.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	b0.y_axis_id = TauPlotClass.AxisId.LEFT

	var b1 = TauXYSeriesBinding.new()
	b1.series_id = dataset.get_series_id_by_index(1)
	b1.pane_index = 0
	b1.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	b1.y_axis_id = TauPlotClass.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [b0, b1]
	plot.plot_xy(dataset, config, bindings)
	return plot

# ------------------------------------------------------------------------------
# TRANG 5: KHO BẠC & NGÂN HÀNG NHÀ NƯỚC (CITY TREASURY & TITHE FUND - TAUPLOT)
# ------------------------------------------------------------------------------
func _render_page_treasury(parent: Control) -> void:
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 14)
	parent.add_child(vbox)

	var title = Label.new()
	title.text = "🏛️ KHO BẠC ĐÔ THỊ & BIỂU ĐỒ DÒNG TIỀN TĂNG TRƯỞNG KINH TẾ"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.3))
	vbox.add_child(title)

	var wm = _get_world_manager()
	var city_val = wm.treasury_city if wm else 50000.0
	var tithe_val = wm.fund_tithe_church if wm else 25000.0

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 24)
	vbox.add_child(hbox)

	var p1 = PanelContainer.new()
	p1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(p1)
	var v1 = VBoxContainer.new()
	p1.add_child(v1)
	var t1 = Label.new()
	t1.text = "🏛️ KHO BẠC ĐÔ THỊ (5% Thuế)"
	t1.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0))
	v1.add_child(t1)
	var val1 = Label.new()
	val1.text = "%d Đ" % int(city_val)
	val1.add_theme_font_size_override("font_size", 22)
	val1.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	v1.add_child(val1)

	var p2 = PanelContainer.new()
	p2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(p2)
	var v2 = VBoxContainer.new()
	p2.add_child(v2)
	var t2 = Label.new()
	t2.text = "🕊️ QUỸ 1/10 DÂNG CHÚA (Tithe Fund)"
	t2.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
	v2.add_child(t2)
	var val2 = Label.new()
	val2.text = "%d Đ" % int(tithe_val)
	val2.add_theme_font_size_override("font_size", 22)
	val2.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	v2.add_child(val2)

	# 2. BIỂU ĐỒ ĐƯỜNG TAUPLOT: DÒNG TIỀN KINH TẾ 7 NGÀY
	var chart_card = PanelContainer.new()
	var chart_style = StyleBoxFlat.new()
	chart_style.bg_color = Color(0.06, 0.09, 0.16, 0.85)
	chart_style.corner_radius_top_left = 8
	chart_style.corner_radius_top_right = 8
	chart_style.corner_radius_bottom_left = 8
	chart_style.corner_radius_bottom_right = 8
	chart_card.add_theme_stylebox_override("panel", chart_style)
	vbox.add_child(chart_card)

	var chart_margin = MarginContainer.new()
	chart_margin.add_theme_constant_override("margin_left", 12)
	chart_margin.add_theme_constant_override("margin_top", 10)
	chart_margin.add_theme_constant_override("margin_right", 12)
	chart_margin.add_theme_constant_override("margin_bottom", 10)
	chart_card.add_child(chart_margin)

	var line_chart_node = _create_treasury_trend_chart(city_val, tithe_val)
	chart_margin.add_child(line_chart_node)

	vbox.add_child(HSeparator.new())

	var fund_btn = Button.new()
	fund_btn.text = "🤝 BẤM 1 CHẠM: ĐỒNG TÀI TRỢ ĐẠI DỰ ÁN DÂN SINH (5.000Đ)"
	fund_btn.custom_minimum_size = Vector2(0, 40)
	fund_btn.pressed.connect(_on_co_fund_project_pressed)
	vbox.add_child(fund_btn)

	var notice = Label.new()
	notice.text = "Cơ chế đồng tài trợ: Trích 2.500Đ từ Kho Bạc và 2.500Đ từ Quỹ 1/10 để nâng cấp phúc lợi và vườn hoa công cộng."
	notice.add_theme_font_size_override("font_size", 12)
	notice.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9))
	vbox.add_child(notice)

func _create_treasury_trend_chart(city_val: float, tithe_val: float) -> Control:
	var plot = TauPlotClass.new()
	plot.custom_minimum_size = Vector2(0, 230)
	plot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	plot.theme_type_variation = &"TauPlot"
	plot.title = "📈 DÒNG TIỀN KINH TẾ & TĂNG TRƯỞNG KHO BẠC 7 NGÀY (ĐỒNG ĐÔ)"

	var c_base = maxf(city_val, 1000.0)
	var t_base = maxf(tithe_val, 500.0)
	var y_data: Array[PackedFloat64Array] = [
		PackedFloat64Array([c_base * 0.82, c_base * 0.88, c_base * 0.94, c_base * 1.08, c_base * 0.96, c_base * 1.02, c_base]),
		PackedFloat64Array([t_base * 0.78, t_base * 0.84, t_base * 0.91, t_base * 1.15, t_base * 0.95, t_base * 0.98, t_base]),
	]
	var dataset = TauPlotClass.Dataset.make_shared_x_categorical(
		PackedStringArray(["🏛️ Kho Bạc Đô Thị", "🕊️ Quỹ 1/10 Dâng Chúa"]),
		PackedStringArray(["Thứ Hai", "Thứ Ba", "Thứ Tư (Lễ)", "Thứ Năm", "Thứ Sáu", "Thứ Bảy", "Chủ Nhật (Đại Lễ)"]),
		y_data
	)

	var x_axis = TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CATEGORICAL

	var y_axis = TauAxisConfig.new()
	y_axis.title = "Đồng Đô (Đ)"

	var line_overlay_config = TauLineConfig.new()
	var overlays_arr: Array[TauPaneOverlayConfig] = [line_overlay_config]

	var pane = TauPaneConfig.new()
	pane.y_left_axis = y_axis
	pane.overlays = overlays_arr

	var panes_arr: Array[TauPaneConfig] = [pane]
	var config = TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = panes_arr

	var b0 = TauXYSeriesBinding.new()
	b0.series_id = dataset.get_series_id_by_index(0)
	b0.pane_index = 0
	b0.overlay_type = TauXYSeriesBinding.PaneOverlayType.LINE
	b0.y_axis_id = TauPlotClass.AxisId.LEFT

	var b1 = TauXYSeriesBinding.new()
	b1.series_id = dataset.get_series_id_by_index(1)
	b1.pane_index = 0
	b1.overlay_type = TauXYSeriesBinding.PaneOverlayType.LINE
	b1.y_axis_id = TauPlotClass.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [b0, b1]
	plot.plot_xy(dataset, config, bindings)
	return plot

func _on_co_fund_project_pressed() -> void:
	var wm = _get_world_manager()
	if wm == null:
		return
	if wm.treasury_city < 2500.0 or wm.fund_tithe_church < 2500.0:
		if status_feedback:
			status_feedback.text = "⚠️ Cần tối thiểu 2.500 Đ ở cả Kho bạc Thành phố và Quỹ Dâng hiến để đồng tài trợ!"
		return
	if wm.has_method("withdraw_city_budget"):
		wm.withdraw_city_budget(2500.0)
	elif wm.has_method("withdraw_city_tax"):
		wm.withdraw_city_tax(2500.0)
	else:
		wm.deposit_city_tax(-2500.0)
	if wm.has_method("withdraw_church_tithe"):
		wm.withdraw_church_tithe(2500.0)
	else:
		wm.deposit_church_tithe(-2500.0)
	_render_civic_page(4)
	print("[CivicOS] 🤝 Đã đồng tài trợ 5.000Đ cho dự án nâng cấp cảnh quan cộng đồng!")

# ------------------------------------------------------------------------------
# TRANG 6: GIAO THÔNG & PHỤNG VỤ (TRANSIT & LITURGY MONITOR)
# ------------------------------------------------------------------------------
func _render_page_liturgy(parent: Control) -> void:
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	parent.add_child(vbox)

	var title = Label.new()
	title.text = "🔔 GIÁM SÁT GIAO THÔNG MẠNG NHỆN & PHỤNG VỤ THÁNH LỄ"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.3))
	vbox.add_child(title)

	var wm = _get_world_manager()
	var time_str = wm.get_formatted_time() if wm else "Thứ Tư 11:30"
	var is_liturgy = wm.is_liturgy_active if wm else false

	var status_lbl = Label.new()
	status_lbl.text = "🕒 Giờ thế giới: %s | Trạng thái: %s" % [
		time_str,
		"ĐANG DIỄN RA THÁNH LỄ (11:40 - 14:00)" if is_liturgy else "Giờ làm việc & sinh hoạt thanh bình"
	]
	status_lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0))
	vbox.add_child(status_lbl)

	vbox.add_child(HSeparator.new())

	var transit_info = [
		"🕸️ Tuyến Vành Đai 1 & 2 (Đỉnh Vát): 100% xe tram chạy đúng lịch trình.",
		"🚇 Tuyến Metro Hầm Xuyên Núi: Kết nối thông suốt 4 Huyện chân núi lên Đỉnh Vát.",
		"🚠 Tuyến Cáp Treo Vượt Mây: Vận hành ổn định từ mép vách đá +600m xuống chân núi.",
		"🕊️ Bữa Tiệc Bác Ái Agape: Đã chuẩn bị 14.400 phần bánh mì baguette, sữa tươi và trái cây sau lễ."
	]

	for line in transit_info:
		var l = Label.new()
		l.text = line
		l.add_theme_font_size_override("font_size", 13)
		vbox.add_child(l)

	vbox.add_child(HSeparator.new())

	var sched_title = Label.new()
	sched_title.text = "📅 THEO DÕI LỊCH TRÌNH SINH HOẠT THỜI GIAN THỰC (5 HUYỆN):"
	sched_title.add_theme_font_size_override("font_size", 14)
	sched_title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.3))
	vbox.add_child(sched_title)

	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 160)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var sched_list = VBoxContainer.new()
	sched_list.add_theme_constant_override("separation", 6)
	scroll.add_child(sched_list)

	var hr = wm.current_hour if wm else 11
	var mn = wm.current_minute if wm else 30
	var d_idx = wm.current_day_index if wm else 2
	var district_statuses = DailyScheduleManagerScript.get_district_live_status(hr, mn, d_idx)

	for dist_data in district_statuses:
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)

		var name_lbl = Label.new()
		name_lbl.text = dist_data["district"]
		name_lbl.custom_minimum_size = Vector2(230, 0)
		name_lbl.add_theme_color_override("font_color", Color(0.95, 0.9, 0.8))
		row.add_child(name_lbl)

		var act_lbl = Label.new()
		act_lbl.text = "• " + dist_data["activity"]
		act_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		act_lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0))
		row.add_child(act_lbl)

		var badge = Label.new()
		badge.text = dist_data["status_badge"]
		badge.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
		row.add_child(badge)

		sched_list.add_child(row)

# ------------------------------------------------------------------------------
# TRANG 7: VIỆN HÀN LÂM KHOA HỌC CAO NGUYÊN (HAS) - CÂY R&D 20 BẬC
# ------------------------------------------------------------------------------
func _render_page_has_research(parent: Control) -> void:
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 12)
	parent.add_child(vbox)

	var title = Label.new()
	title.text = "🔬 VIỆN HÀN LÂM KHOA HỌC CAO NGUYÊN (HAS) — CÂY R&D 20 BẬC LIÊN TỤC"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.3))
	vbox.add_child(title)

	var sub_title = Label.new()
	sub_title.text = "Tri thức dẫn dắt sự thịnh vượng • 5 Phân khoa • Giảm hao mòn máy móc -21% • Bội thu đất lành 1.85x"
	sub_title.add_theme_font_size_override("font_size", 12)
	sub_title.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
	vbox.add_child(sub_title)

	var research_mgr = _get_research_manager()
	var kbu_val: int = int(research_mgr.get("kbu_balance")) if research_mgr else 120
	var is_grant_active: bool = bool(research_mgr.get("acceleration_grant_active")) if research_mgr else false
	var active_branch: String = str(research_mgr.get("active_branch_id")) if research_mgr else "materials"
	var active_tier: int = int(research_mgr.get("active_tier")) if research_mgr else 1
	var progress_kbu: int = int(research_mgr.get("current_progress_kbu")) if research_mgr else 0
	var req_kbu: int = research_mgr.get_tier_cost(active_branch, active_tier) if (research_mgr and research_mgr.has_method("get_tier_cost")) else 60

	# 1. BẢNG TỔNG QUAN HAS & TIẾN ĐỘ ĐỀ ÁN TRỌNG ĐIỂM
	var kbu_panel = PanelContainer.new()
	var kbu_style = StyleBoxFlat.new()
	kbu_style.bg_color = Color(0.08, 0.12, 0.20, 0.90)
	kbu_style.corner_radius_top_left = 6
	kbu_style.corner_radius_top_right = 6
	kbu_style.corner_radius_bottom_left = 6
	kbu_style.corner_radius_bottom_right = 6
	kbu_panel.add_theme_stylebox_override("panel", kbu_style)
	vbox.add_child(kbu_panel)

	var kbu_margin = MarginContainer.new()
	kbu_margin.add_theme_constant_override("margin_left", 12)
	kbu_margin.add_theme_constant_override("margin_top", 10)
	kbu_margin.add_theme_constant_override("margin_right", 12)
	kbu_margin.add_theme_constant_override("margin_bottom", 10)
	kbu_panel.add_child(kbu_margin)

	var kbu_vbox = VBoxContainer.new()
	kbu_vbox.add_theme_constant_override("separation", 8)
	kbu_margin.add_child(kbu_vbox)

	var kbu_row = HBoxContainer.new()
	kbu_row.add_theme_constant_override("separation", 20)
	kbu_vbox.add_child(kbu_row)

	var kbu_lbl = Label.new()
	kbu_lbl.text = "💡 Điểm Tri Thức: %d KBU (%s)" % [
		kbu_val,
		"🚀 +20 KBU/m [Đang Tăng Tốc]" if is_grant_active else "+10 KBU/m"
	]
	kbu_lbl.add_theme_font_size_override("font_size", 14)
	kbu_lbl.add_theme_color_override("font_color", Color(0.3, 0.9, 1.0))
	kbu_row.add_child(kbu_lbl)

	var directive_lbl = Label.new()
	var active_tech_name = research_mgr.get_tech_name(active_branch, active_tier) if (research_mgr and research_mgr.has_method("get_tech_name")) else "Vật Liệu Cốt Sợi Bazan Tự Nhiên"
	directive_lbl.text = "🎯 Đề Án Trọng Điểm: %s (Bậc %d)" % [active_tech_name, active_tier]
	directive_lbl.add_theme_font_size_override("font_size", 14)
	directive_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	directive_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kbu_row.add_child(directive_lbl)

	# Thanh tiến trình KBU
	var pbar = ProgressBar.new()
	pbar.custom_minimum_size = Vector2(0, 18)
	pbar.max_value = float(maxi(1, req_kbu))
	pbar.value = float(progress_kbu)
	pbar.show_percentage = true
	kbu_vbox.add_child(pbar)

	# Hàng nút hành động nhanh
	var act_row = HBoxContainer.new()
	act_row.add_theme_constant_override("separation", 12)
	kbu_vbox.add_child(act_row)

	var grant_btn = Button.new()
	grant_btn.text = "🤝 TÀI TRỢ TĂNG TỐC HAS (5.000Đ TỪ KHO BẠC) [x2 Tốc Độ]"
	grant_btn.custom_minimum_size = Vector2(0, 32)
	grant_btn.pressed.connect(_on_has_grant_pressed)
	act_row.add_child(grant_btn)

	# 2. KHỐI HIỆU ỨNG TÍCH LŨY TOÀN ĐÔ THỊ
	var buffs_card = PanelContainer.new()
	var buffs_style = StyleBoxFlat.new()
	buffs_style.bg_color = Color(0.06, 0.09, 0.15, 0.8)
	buffs_style.corner_radius_top_left = 6
	buffs_style.corner_radius_top_right = 6
	buffs_style.corner_radius_bottom_left = 6
	buffs_style.corner_radius_bottom_right = 6
	buffs_card.add_theme_stylebox_override("panel", buffs_style)
	vbox.add_child(buffs_card)

	var buffs_margin = MarginContainer.new()
	buffs_margin.add_theme_constant_override("margin_left", 10)
	buffs_margin.add_theme_constant_override("margin_top", 8)
	buffs_margin.add_theme_constant_override("margin_right", 10)
	buffs_margin.add_theme_constant_override("margin_bottom", 8)
	buffs_card.add_child(buffs_margin)

	var buffs_grid = GridContainer.new()
	buffs_grid.columns = 3
	buffs_grid.add_theme_constant_override("h_separation", 20)
	buffs_grid.add_theme_constant_override("v_separation", 6)
	buffs_margin.add_child(buffs_grid)

	var wear_red = research_mgr.get_wear_and_tear_reduction() if (research_mgr and research_mgr.has_method("get_wear_and_tear_reduction")) else 0.0
	var agri_boost = research_mgr.get_blessed_abundance_boost() if (research_mgr and research_mgr.has_method("get_blessed_abundance_boost")) else 0.0
	var energy_boost = research_mgr.get_energy_efficiency_boost() if (research_mgr and research_mgr.has_method("get_energy_efficiency_boost")) else 0.0
	var scm_boost = research_mgr.get_scram_logistics_boost() if (research_mgr and research_mgr.has_method("get_scram_logistics_boost")) else 0.0
	var health_boost = research_mgr.get_wellness_vitality_boost() if (research_mgr and research_mgr.has_method("get_wellness_vitality_boost")) else 0.0

	var buffs_data = [
		"🛡️ Giảm hao mòn máy móc: -%.1f%% (Max -21%%)" % (wear_red * 100.0),
		"🌾 Bội thu nông nghiệp: +%.1f%% (Đất lành: %.2fx)" % [agri_boost * 100.0, 1.60 + agri_boost],
		"⚡ Hiệu suất điện SCADA: +%.1f%% (Max +21%%)" % (energy_boost * 100.0),
		"📦 Kho RAM & Logistics: +%.1f%% (Max +21%%)" % (scm_boost * 100.0),
		"💚 Phục hồi sinh lực: +%.1f%% (Max +21%%)" % (health_boost * 100.0),
		"🕊️ Phước hạnh cư dân: 100% Thuận Thiên"
	]
	for b_text in buffs_data:
		var lbl = Label.new()
		lbl.text = b_text
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color", Color(0.4, 0.95, 0.6))
		buffs_grid.add_child(lbl)

	vbox.add_child(HSeparator.new())

	# 3. CHỌN PHÂN KHOA NGHIÊN CỨU (5 NHÁNH)
	var branch_selector_title = Label.new()
	branch_selector_title.text = "🏛️ CHỌN PHÂN KHOA NGHIÊN CỨU & XEM CÂY 20 BẬC SÁNG CHẾ:"
	branch_selector_title.add_theme_font_size_override("font_size", 13)
	branch_selector_title.add_theme_color_override("font_color", Color(0.95, 0.9, 0.8))
	vbox.add_child(branch_selector_title)

	var branch_bar = HBoxContainer.new()
	branch_bar.add_theme_constant_override("separation", 8)
	vbox.add_child(branch_bar)

	var branches = [
		{"id": "materials", "title": "🛡️ Vật Liệu Mới (-21% Wear)"},
		{"id": "agri", "title": "🌾 Nông Nghiệp (+25% Yield)"},
		{"id": "energy", "title": "⚡ Năng Lượng Gió (+21% Grid)"},
		{"id": "robotics", "title": "🤖 Vật Liệu Mới & Tự Động Hóa (+21% Flow)"},
		{"id": "wellness", "title": "💚 Sinh Thái & Sức Khỏe (+21%)"}
	]

	for b_info in branches:
		var b_btn = Button.new()
		b_btn.text = b_info["title"]
		b_btn.custom_minimum_size = Vector2(0, 30)
		b_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b_btn.add_theme_font_size_override("font_size", 12)
		if b_info["id"] == selected_has_branch:
			b_btn.modulate = Color(1.0, 0.9, 0.3)
		b_btn.pressed.connect(_on_select_has_branch.bind(b_info["id"]))
		branch_bar.add_child(b_btn)

	# 4. DANH SÁCH 20 BẬC CỦA NHÁNH ĐANG CHỌN
	var tree_scroll = ScrollContainer.new()
	tree_scroll.custom_minimum_size = Vector2(0, 240)
	tree_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(tree_scroll)

	var tree_list = VBoxContainer.new()
	tree_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tree_list.add_theme_constant_override("separation", 6)
	tree_scroll.add_child(tree_list)

	var tiers = research_mgr.get_branch_tiers(selected_has_branch) if (research_mgr and research_mgr.has_method("get_branch_tiers")) else []
	for tier_data in tiers:
		var t_num: int = int(tier_data.get("t", 1))
		var t_name: String = str(tier_data.get("name", ""))
		var t_cost: int = int(tier_data.get("cost", 60))
		var t_desc: String = str(tier_data.get("desc", ""))
		var is_unlocked: bool = research_mgr.is_tech_unlocked(selected_has_branch, t_num) if (research_mgr and research_mgr.has_method("is_tech_unlocked")) else false
		var is_deployed: bool = research_mgr.is_tech_deployed(selected_has_branch, t_num) if (research_mgr and research_mgr.has_method("is_tech_deployed")) else false
		var is_active: bool = (selected_has_branch == active_branch and t_num == active_tier)

		var card = PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var c_style = StyleBoxFlat.new()
		if is_deployed:
			c_style.bg_color = Color(0.08, 0.16, 0.12, 0.85)
		elif is_unlocked:
			c_style.bg_color = Color(0.18, 0.16, 0.08, 0.85)
		elif is_active:
			c_style.bg_color = Color(0.08, 0.14, 0.22, 0.85)
		else:
			c_style.bg_color = Color(0.07, 0.09, 0.13, 0.70)
		c_style.corner_radius_top_left = 4
		c_style.corner_radius_top_right = 4
		c_style.corner_radius_bottom_left = 4
		c_style.corner_radius_bottom_right = 4
		card.add_theme_stylebox_override("panel", c_style)
		tree_list.add_child(card)

		var c_margin = MarginContainer.new()
		c_margin.add_theme_constant_override("margin_left", 8)
		c_margin.add_theme_constant_override("margin_top", 6)
		c_margin.add_theme_constant_override("margin_right", 8)
		c_margin.add_theme_constant_override("margin_bottom", 6)
		card.add_child(c_margin)

		var c_row = HBoxContainer.new()
		c_row.add_theme_constant_override("separation", 10)
		c_margin.add_child(c_row)

		var t_badge = Label.new()
		t_badge.text = "[Bậc %02d]" % t_num
		t_badge.custom_minimum_size = Vector2(70, 0)
		t_badge.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3) if is_deployed else Color(0.7, 0.75, 0.85))
		c_row.add_child(t_badge)

		var info_vbox = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		c_row.add_child(info_vbox)

		var name_lbl = Label.new()
		name_lbl.text = "%s (%d KBU)" % [t_name, t_cost]
		name_lbl.add_theme_font_size_override("font_size", 13)
		name_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0) if (is_unlocked or is_active) else Color(0.6, 0.65, 0.7))
		info_vbox.add_child(name_lbl)

		var desc_lbl = Label.new()
		desc_lbl.text = t_desc
		desc_lbl.add_theme_font_size_override("font_size", 11)
		desc_lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 0.6) if is_deployed else Color(0.65, 0.7, 0.75))
		info_vbox.add_child(desc_lbl)

		# Nút hành động tương ứng
		if is_deployed:
			var dep_lbl = Label.new()
			dep_lbl.text = "✅ ĐÃ BAN HÀNH"
			dep_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
			c_row.add_child(dep_lbl)
		elif is_unlocked:
			var dep_btn = Button.new()
			dep_btn.text = "📢 Ban Hành Bản Vẽ"
			dep_btn.custom_minimum_size = Vector2(150, 28)
			dep_btn.modulate = Color(1.0, 0.9, 0.3)
			dep_btn.pressed.connect(_on_has_deploy_pressed.bind(selected_has_branch, t_num))
			c_row.add_child(dep_btn)
		elif is_active:
			var act_lbl = Label.new()
			act_lbl.text = "⏳ ĐANG TIẾN HÀNH"
			act_lbl.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0))
			c_row.add_child(act_lbl)
		else:
			var sel_btn = Button.new()
			sel_btn.text = "🎯 Đặt Đề Án"
			sel_btn.custom_minimum_size = Vector2(110, 28)
			sel_btn.pressed.connect(_on_has_select_directive_pressed.bind(selected_has_branch, t_num))
			c_row.add_child(sel_btn)

func _on_select_has_branch(branch_id: String) -> void:
	# Normalize alias "automation" → "robotics" (tên nhánh thực tế trong ResearchManager)
	selected_has_branch = "robotics" if branch_id == "automation" else branch_id
	_render_civic_page(6)

func _on_has_grant_pressed() -> void:
	var research_mgr = _get_research_manager()
	if research_mgr:
		if research_mgr.grant_acceleration_funding():
			if status_feedback:
				status_feedback.text = "✅ Đã tài trợ 5.000Đ từ Kho Bạc: Tốc độ R&D x2 (+20 KBU/phút)!"
		else:
			if status_feedback:
				status_feedback.text = "⚠️ Kho Bạc Đô Thị không đủ 5.000Đ để giải ngân gói tài trợ."
	_render_civic_page(6)

func _on_has_deploy_pressed(branch_id: String, tier: int) -> void:
	var research_mgr = _get_research_manager()
	if research_mgr:
		research_mgr.deploy_blueprint_citywide(branch_id, tier)
		var t_name = research_mgr.get_tech_name(branch_id, tier)
		if status_feedback:
			status_feedback.text = "📢 Thị Trưởng đã Ban Hành Bản Vẽ: %s cho toàn đô thị!" % t_name
	_render_civic_page(6)

func _on_has_select_directive_pressed(branch_id: String, tier: int) -> void:
	var research_mgr = _get_research_manager()
	if research_mgr:
		research_mgr.select_active_directive(branch_id, tier)
		var t_name = research_mgr.get_tech_name(branch_id, tier)
		if status_feedback:
			status_feedback.text = "🎯 Đã chọn Đề Án Trọng Điểm: %s (Bậc %d)!" % [t_name, tier]
	_render_civic_page(6)

# ------------------------------------------------------------------------------
# QUẢN LÝ MỞ / ĐÓNG VÀ SLOW-MOTION 20%
# ------------------------------------------------------------------------------
func open_macro_map() -> void:
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if is_inside_tree():
		player_ref = get_tree().get_first_node_in_group("player")
	_update_gps_display()
	_on_tab_clicked(current_tab_index)

	# Hiệu ứng Thế Giới Chạy Chậm (Slow-Motion 20%) theo đúng Concept!
	Engine.time_scale = 0.2

	if status_feedback:
		status_feedback.text = ""

func close_macro_map() -> void:
	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# Khôi phục vận tốc thế giới bình thường
	Engine.time_scale = 1.0

	map_closed.emit()

func _update_gps_display() -> void:
	if player_ref and is_instance_valid(player_ref) and gps_label:
		var pos = player_ref.global_position
		var district = "Đỉnh Vát Cao Nguyên (+600m)"
		var dist = sqrt(pos.x * pos.x + pos.z * pos.z)
		if dist > 12600.0:
			if pos.z < -10000.0:
				district = "Huyện Bắc Đại Ngàn"
			elif pos.x > 10000.0:
				district = "Huyện Đông Nông Trại"
			elif pos.x < -10000.0:
				district = "Huyện Tây Kỹ Nghệ"
			elif pos.z > 15000.0:
				district = "Huyện Nam Duyên Hải"
		gps_label.text = "📍 GPS: (%.1f, %.1f, %.1f) | %s [Slow-Mo: 20%%]" % [
			pos.x, pos.y, pos.z, district
		]

func _populate_poi_list() -> void:
	if not poi_option_list:
		return
	poi_option_list.clear()
	for p in poi_catalog:
		poi_option_list.add_item(p["name"])
	if poi_catalog.size() > 0:
		poi_option_list.select(0)

func _on_poi_selected(index: int) -> void:
	if index < 0 or index >= poi_catalog.size():
		return
	selected_poi_index = index
	var poi = poi_catalog[index]
	if poi_title_label:
		poi_title_label.text = poi["name"]
	if poi_coord_label:
		poi_coord_label.text = "📌 Vùng: %s | Tọa độ: (%.0f, %.0f, %.0f)" % [
			poi["district"], poi["pos"].x, poi["pos"].y, poi["pos"].z
		]
	if poi_desc_label:
		poi_desc_label.text = poi["desc"]

func _on_travel_pressed() -> void:
	if selected_poi_index < 0 or selected_poi_index >= poi_catalog.size():
		return
	var target = poi_catalog[selected_poi_index]
	var target_pos: Vector3 = target["pos"]

	if not player_ref or not is_instance_valid(player_ref):
		if is_inside_tree():
			player_ref = get_tree().get_first_node_in_group("player")

	if player_ref and is_instance_valid(player_ref):
		player_ref.global_position = target_pos
		if "velocity" in player_ref:
			player_ref.velocity = Vector3.ZERO

		if is_inside_tree():
			var root = get_tree().current_scene
			var streamer = null
			if root:
				streamer = root.find_child("WorldChunkStreamer", true, false)
			if not streamer:
				streamer = get_tree().get_first_node_in_group("chunk_streamer")
			if streamer and streamer.has_method("force_refresh_at_position"):
				streamer.force_refresh_at_position(target_pos)

	fast_travel_requested.emit(target_pos)
	if status_feedback:
		status_feedback.text = "✅ Đang dịch chuyển tức thời tới: %s..." % target["name"]
	print("[MacroMap] 🚀 Thực hiện Du Hành Nhanh tới: %s | Tọa độ: %s" % [target["name"], target_pos])
	close_macro_map()

func _on_close_pressed() -> void:
	close_macro_map()

# ------------------------------------------------------------------------------
# TRANG 8: QUY HOẠCH NHÀ Ở & CẤP SỔ ĐỎ ĐÔ THỊ (12 LÔ ĐẤT 5 HUYỆN)
# ------------------------------------------------------------------------------
func _render_page_housing_plots(parent: Control) -> void:
	var vbox = VBoxContainer.new()
	vbox.name = "HousingPlotsVBox"
	vbox.add_theme_constant_override("separation", 14)
	parent.add_child(vbox)

	var title = Label.new()
	title.text = "🏡 QUY HOẠCH NHÀ Ở & CẤP SỔ ĐỎ ĐÔ THỊ (12 LÔ ĐẤT 5 HUYỆN)"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.3))
	vbox.add_child(title)

	var desc = Label.new()
	desc.text = "Quản lý 12 lô đất nhà ở quy hoạch toàn cõi Tân Thế Giới. Cấp Sổ Đỏ (Land Deed Number), điều động Thợ Mộc thi công và nghiệm thu bàn giao chính thức vào CSDL SQLite."
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_color_override("font_color", Color(0.85, 0.90, 0.95))
	vbox.add_child(desc)

	# 1. Truy vấn danh sách lô đất từ CSDL SQLite hoặc Scene Group
	var plots_list: Array[Dictionary] = []
	var db_mgr = null
	if is_inside_tree():
		db_mgr = get_node_or_null("/root/DatabaseManager")
	if db_mgr and db_mgr.has_method("get_all_housing_plots"):
		plots_list = db_mgr.get_all_housing_plots()

	# Fallback nếu CSDL chưa có dữ liệu nạp sẵn
	if plots_list.is_empty() and is_inside_tree():
		var scene_plots = get_tree().get_nodes_in_group("housing_plots")
		for p in scene_plots:
			var stat_str = "AVAILABLE"
			var st = p.get("current_status")
			if st == 2:
				stat_str = "COMPLETED"
			elif st == 1:
				stat_str = "UNDER_CONSTRUCTION"
			plots_list.append({
				"plot_id": p.get("plot_id"),
				"title": p.get("title"),
				"district_id": p.get("district_id"),
				"house_type": p.get("house_type"),
				"area_sqm": p.get("area_sqm"),
				"price": p.get("price"),
				"owner_id": p.get("owner_name"),
				"status": stat_str,
				"land_deed_number": p.get("land_deed_number"),
				"pos_x": p.global_position.x,
				"pos_y": p.global_position.y,
				"pos_z": p.global_position.z
			})

	# Thống kê tổng quan
	var count_completed: int = 0
	var count_construction: int = 0
	var count_available: int = 0
	for r in plots_list:
		var st = r.get("status", "")
		if st == "COMPLETED" or st == "OCCUPIED":
			count_completed += 1
		elif st == "UNDER_CONSTRUCTION" or st == "CONSTRUCTION":
			count_construction += 1
		else:
			count_available += 1

	var stat_hbox = HBoxContainer.new()
	stat_hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(stat_hbox)

	var stat_items = [
		{"label": "🏛️ Tổng Số Lô Đất", "val": "%d Lô" % plots_list.size(), "color": Color(0.9, 0.9, 0.95)},
		{"label": "✨ Đã Hoàn Thiện & Cấp Sổ", "val": "%d Căn" % count_completed, "color": Color(0.35, 0.95, 0.55)},
		{"label": "🏗️ Đang Thi Công", "val": "%d Công Trình" % count_construction, "color": Color(0.4, 0.85, 1.0)},
		{"label": "🏡 Đang Mở Bán", "val": "%d Lô" % count_available, "color": Color(1.0, 0.88, 0.25)}
	]

	for item in stat_items:
		var card = PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cs = StyleBoxFlat.new()
		cs.bg_color = Color(0.12, 0.16, 0.25, 0.85)
		cs.corner_radius_top_left = 6
		cs.corner_radius_top_right = 6
		cs.corner_radius_bottom_left = 6
		cs.corner_radius_bottom_right = 6
		card.add_theme_stylebox_override("panel", cs)

		var cv = VBoxContainer.new()
		cv.add_theme_constant_override("separation", 2)
		var cl = Label.new()
		cl.text = item["label"]
		cl.add_theme_font_size_override("font_size", 11)
		cl.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
		cv.add_child(cl)

		var val = Label.new()
		val.text = item["val"]
		val.add_theme_font_size_override("font_size", 15)
		val.add_theme_color_override("font_color", item["color"])
		cv.add_child(val)
		card.add_child(cv)
		stat_hbox.add_child(card)

	vbox.add_child(HSeparator.new())

	# Bảng danh mục 12 lô đất
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(grid)

	for plot_data in plots_list:
		var p_id = plot_data.get("plot_id", "")
		var p_title = plot_data.get("title", p_id)
		var p_dist = plot_data.get("district_id", "")
		var p_type = plot_data.get("house_type", "")
		var p_area = plot_data.get("area_sqm", 80.0)
		var p_price = plot_data.get("price", 1500.0)
		var p_status = plot_data.get("status", "AVAILABLE")
		var p_owner = plot_data.get("owner_id", "")
		var p_deed = plot_data.get("land_deed_number", "")
		if p_deed.is_empty():
			p_deed = "SO_DO_TTG_" + p_id.to_upper().replace("PLOT_", "") + "_2026"

		var card = PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var c_style = StyleBoxFlat.new()
		c_style.bg_color = Color(0.13, 0.17, 0.26, 0.90)
		c_style.border_width_left = 3
		if p_status == "COMPLETED" or p_status == "OCCUPIED":
			c_style.border_color = Color(0.35, 0.95, 0.55)
		elif p_status == "UNDER_CONSTRUCTION" or p_status == "CONSTRUCTION":
			c_style.border_color = Color(0.4, 0.85, 1.0)
		else:
			c_style.border_color = Color(1.0, 0.85, 0.25)

		c_style.corner_radius_top_left = 6
		c_style.corner_radius_top_right = 6
		c_style.corner_radius_bottom_left = 6
		c_style.corner_radius_bottom_right = 6
		card.add_theme_stylebox_override("panel", c_style)

		var card_vbox = VBoxContainer.new()
		card_vbox.add_theme_constant_override("separation", 4)

		var head = Label.new()
		head.text = "🏡 %s" % p_title
		head.add_theme_font_size_override("font_size", 13)
		head.add_theme_color_override("font_color", Color(0.98, 0.92, 0.82))
		card_vbox.add_child(head)

		var info = Label.new()
		info.text = "Mã: %s | Vùng: %s\nKiểu: %s | S: %.0fm² | Đơn giá: %d Đ\n📜 Sổ Đỏ Số: %s" % [
			p_id, p_dist, p_type, p_area, int(p_price), p_deed
		]
		info.add_theme_font_size_override("font_size", 11)
		info.add_theme_color_override("font_color", Color(0.78, 0.82, 0.90))
		card_vbox.add_child(info)

		var stat_lbl = Label.new()
		stat_lbl.add_theme_font_size_override("font_size", 11)
		if p_status == "COMPLETED" or p_status == "OCCUPIED":
			var owner_display = p_owner if not p_owner.is_empty() else "Thị Trưởng"
			stat_lbl.text = "✨ Trạng Thái: ĐÃ HOÀN THIỆN (Chủ sở hữu: %s)" % owner_display
			stat_lbl.add_theme_color_override("font_color", Color(0.35, 0.95, 0.55))
		elif p_status == "UNDER_CONSTRUCTION" or p_status == "CONSTRUCTION":
			stat_lbl.text = "🏗️ Trạng Thái: ĐANG THI CÔNG (Thợ mộc đang gõ búa)"
			stat_lbl.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0))
		else:
			stat_lbl.text = "🏡 Trạng Thái: ĐANG MỞ BÁN (Sẵn sàng cấp phép)"
			stat_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25))
		card_vbox.add_child(stat_lbl)

		# Nút tương tác trên Tablet
		var btn_hbox = HBoxContainer.new()
		btn_hbox.add_theme_constant_override("separation", 6)

		if p_status == "AVAILABLE":
			var buy_btn = Button.new()
			buy_btn.text = "✍️ Cấp Phép & Cấp Sổ Đỏ"
			buy_btn.add_theme_font_size_override("font_size", 11)
			buy_btn.pressed.connect(_on_civic_permit_grant.bind(p_id, p_price, p_deed))
			btn_hbox.add_child(buy_btn)
		elif p_status == "UNDER_CONSTRUCTION" or p_status == "CONSTRUCTION":
			var accept_btn = Button.new()
			accept_btn.text = "✨ Nghiệm Thu Bàn Giao"
			accept_btn.add_theme_font_size_override("font_size", 11)
			accept_btn.pressed.connect(_on_civic_inspect_complete.bind(p_id))
			btn_hbox.add_child(accept_btn)

		var pos_x = float(plot_data.get("pos_x", 0.0))
		var pos_y = float(plot_data.get("pos_y", 600.0))
		var pos_z = float(plot_data.get("pos_z", 0.0))
		var loc_btn = Button.new()
		loc_btn.text = "📍 Định Vị"
		loc_btn.add_theme_font_size_override("font_size", 11)
		loc_btn.pressed.connect(_on_civic_locate_plot.bind(Vector3(pos_x, pos_y, pos_z), p_title))
		btn_hbox.add_child(loc_btn)

		card_vbox.add_child(btn_hbox)
		card.add_child(card_vbox)
		grid.add_child(card)

## Xử lý khi Thị Trưởng cấp phép & cấp Sổ Đỏ từ xa trên Tablet
func _on_civic_permit_grant(plot_id: String, price: float, deed_no: String) -> void:
	var wm = null
	if is_inside_tree():
		wm = get_node_or_null("/root/WorldManager")
	var hud = null
	if is_inside_tree():
		hud = get_tree().get_first_node_in_group("hud")

	if wm and wm.treasury_city < price:
		if hud and hud.has_method("show_toast"):
			hud.show_toast("⚠️ Ngân khố không đủ %d Đ để cấp phép công trình %s!" % [int(price), plot_id])
		return

	if wm:
		wm.deposit_city_tax(-price)

	var db_mgr = null
	if is_inside_tree():
		db_mgr = get_node_or_null("/root/DatabaseManager")
	if db_mgr and db_mgr.has_method("update_plot_status"):
		db_mgr.update_plot_status(plot_id, "COMPLETED", "Thị Trưởng", deed_no)

	# Đồng bộ lên Node 3D thực địa nếu có
	if is_inside_tree():
		var scene_plots = get_tree().get_nodes_in_group("housing_plots")
		for p in scene_plots:
			if p.get("plot_id") == plot_id:
				p.set("current_status", 2) # COMPLETED
				p.set("owner_name", "Thị Trưởng")
				p.set("construction_progress", 100.0)
				if p.has_method("_update_visual_state"):
					p._update_visual_state()
				break

	if hud and hud.has_method("show_toast"):
		hud.show_toast("🎉 ĐÃ CẤP PHÉP & CẤP SỔ ĐỎ THÀNH CÔNG: %s [Sổ: %s]!" % [plot_id, deed_no], 4.5)
	print("[CivicOS] 🏡 Đã cấp phép và cấp Sổ Đỏ cho lô đất %s (Số Sổ: %s)" % [plot_id, deed_no])

	# Làm mới hiển thị trang
	if current_tab_index == 7 and civic_pages_container:
		_render_civic_page(7)

## Xử lý nghiệm thu công trình từ Tablet
func _on_civic_inspect_complete(plot_id: String) -> void:
	var db_mgr = null
	if is_inside_tree():
		db_mgr = get_node_or_null("/root/DatabaseManager")
	if db_mgr and db_mgr.has_method("update_plot_status"):
		db_mgr.update_plot_status(plot_id, "COMPLETED", "Thị Trưởng")

	if is_inside_tree():
		var scene_plots = get_tree().get_nodes_in_group("housing_plots")
		for p in scene_plots:
			if p.get("plot_id") == plot_id:
				p.set("current_status", 2)
				p.set("construction_progress", 100.0)
				if p.has_method("_update_visual_state"):
					p._update_visual_state()
				break

	var hud = null
	if is_inside_tree():
		hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_toast"):
		hud.show_toast("✨ ĐÃ NGHIỆM THU HOÀN CÔNG: Lô đất %s sẵn sàng dọn vào ở!" % plot_id, 4.0)

	if current_tab_index == 7 and civic_pages_container:
		_render_civic_page(7)

## Định vị lô đất: teleport Player tới tọa độ, làm mới chunk streamer, chuyển về Tab Bản Đồ
func _on_civic_locate_plot(target_pos: Vector3, plot_title: String) -> void:
	print("[CivicOS] 📍 Định vị Lô Đất: %s tại tọa độ %s" % [plot_title, target_pos])

	# --- Teleport Player ---
	if not player_ref or not is_instance_valid(player_ref):
		if is_inside_tree():
			player_ref = get_tree().get_first_node_in_group("player")

	if player_ref and is_instance_valid(player_ref):
		player_ref.global_position = target_pos
		if "velocity" in player_ref:
			player_ref.velocity = Vector3.ZERO

		# Làm mới World Chunk Streamer nếu có
		if is_inside_tree():
			var root = get_tree().current_scene
			var streamer: Node = null
			if root:
				streamer = root.find_child("WorldChunkStreamer", true, false)
			if not streamer:
				streamer = get_tree().get_first_node_in_group("chunk_streamer")
			if streamer and streamer.has_method("force_refresh_at_position"):
				streamer.force_refresh_at_position(target_pos)

	# Phát signal fast_travel để các hệ thống khác biết
	fast_travel_requested.emit(target_pos)

	# Cập nhật GPS và đóng bản đồ để chơi tiếp
	_update_gps_display()
	close_macro_map()

	# Thông báo HUD
	var hud: Node = null
	if is_inside_tree():
		hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_toast"):
		hud.show_toast("📍 Đã định vị: %s" % plot_title, 3.0)

func _exit_tree() -> void:
	if Engine.time_scale != 1.0:
		Engine.time_scale = 1.0
