extends Node

# ==============================================================================
# RESEARCH MANAGER — VIỆN HÀN LÂM KHOA HỌC CAO NGUYÊN (HAS R&D SYSTEM)
# TÂN THẾ GIỚI — GODOT 4.6.2 (GL COMPATIBILITY)
# ==============================================================================
# Tuân thủ:
# - Master Concept GDD Section 5.7:
#   1. Đơn vị đột phá tri thức KBU (+10 KBU/phút game, +20 KBU nếu tài trợ)
#   2. Thị Trưởng chỉ đạo vĩ mô qua Đề án Trọng điểm (5 Nhánh Mũi Nhọn)
#   3. Tài trợ tăng tốc R&D Acceleration Grant (5.000Đ từ Kho Bạc Đô Thị)
#   4. Ban hành Bản vẽ Công nghệ Toàn Thành Phố (Triệt tiêu 21% hao mòn máy móc)
#   5. Tích hợp bền vững SQLite & Offline Catch-Up
# ==============================================================================

signal kbu_updated(current_kbu: int, change_amount: int)
signal directive_progress_updated(branch_id: String, tier: int, current_kbu: int, required_kbu: int, percent: float)
signal tech_unlocked(branch_id: String, tier: int, tech_name: String)
signal tech_deployed_citywide(branch_id: String, tier: int, tech_name: String, total_buff: float)
signal acceleration_grant_activated(duration_minutes: int)

const BASE_KBU_PER_GAME_MINUTE: int = 10
const GRANT_KBU_PER_GAME_MINUTE: int = 20
const ACCELERATION_GRANT_COST: float = 5000.0
const ACCELERATION_DURATION_MINUTES: int = 7 * 24 * 60 # 7 ngày game

# Trạng thái R&D
var kbu_balance: int = 120
var active_branch_id: String = "materials"
var active_tier: int = 1
var current_progress_kbu: int = 0
var acceleration_grant_active: bool = false
var grant_remaining_minutes: int = 0

# Bộ đệm dữ liệu 5 Nhánh x 20 Bậc
var tech_catalog: Dictionary = {}
var unlocked_techs: Dictionary = {} # "branch_tier": bool
var deployed_techs: Dictionary = {} # "branch_tier": bool

var is_initialized: bool = false

func _ready() -> void:
	_init_tech_catalog()
	call_deferred("_setup_research_manager")

func _setup_research_manager() -> void:
	var db = _get_database_manager()
	if db != null:
		_load_from_database(db)
	
	# Kết nối với WorldManager
	var wm = _get_world_manager()
	if wm != null and wm.has_signal("time_ticked"):
		if not wm.is_connected("time_ticked", Callable(self, "_on_world_time_ticked")):
			wm.connect("time_ticked", Callable(self, "_on_world_time_ticked"))
	
	is_initialized = true
	print("[ResearchManager] 🔬 Viện Hàn Lâm Khoa Học Cao Nguyên (HAS) khởi tạo thành công (KBU: %d)." % kbu_balance)

var cached_db: Node = null
var cached_wm: Node = null

func set_database_manager(db: Node) -> void:
	cached_db = db

func set_world_manager(wm: Node) -> void:
	cached_wm = wm
	if wm != null and wm.has_signal("time_ticked"):
		if not wm.is_connected("time_ticked", Callable(self, "_on_world_time_ticked")):
			wm.connect("time_ticked", Callable(self, "_on_world_time_ticked"))

func _get_database_manager() -> Node:
	if cached_db != null and is_instance_valid(cached_db):
		return cached_db
	if Engine.has_singleton("DatabaseManager"):
		cached_db = Engine.get_singleton("DatabaseManager")
		return cached_db
	if is_inside_tree():
		if has_node("/root/DatabaseManager"):
			cached_db = get_node("/root/DatabaseManager")
			return cached_db
		var tree = get_tree()
		if tree and tree.root and tree.root.has_node("DatabaseManager"):
			cached_db = tree.root.get_node("DatabaseManager")
			return cached_db
		if get_parent() and get_parent().has_node("DatabaseManager"):
			cached_db = get_parent().get_node("DatabaseManager")
			return cached_db
	return null

func _get_world_manager() -> Node:
	if cached_wm != null and is_instance_valid(cached_wm):
		return cached_wm
	if Engine.has_singleton("WorldManager"):
		cached_wm = Engine.get_singleton("WorldManager")
		return cached_wm
	if is_inside_tree():
		if has_node("/root/WorldManager"):
			cached_wm = get_node("/root/WorldManager")
			return cached_wm
		var tree = get_tree()
		if tree and tree.root and tree.root.has_node("WorldManager"):
			cached_wm = tree.root.get_node("WorldManager")
			return cached_wm
		if get_parent() and get_parent().has_node("WorldManager"):
			cached_wm = get_parent().get_node("WorldManager")
			return cached_wm
	return null

## Khởi tạo danh mục chuẩn mực 5 Nhánh x 20 Bậc theo đúng GDD Section 5.7
func _init_tech_catalog() -> void:
	tech_catalog = {
		"materials": {
			"name": "Khoa Học Vật Liệu & Chống Mài Mòn",
			"icon": "⚙️",
			"tiers": [
				{"t": 1, "name": "Dầu Thực Vật Bôi Trơn Bản Lề", "cost": 60, "buff": 0.005, "desc": "Giảm 0.5% tốc độ hao mòn cơ học ban đầu"},
				{"t": 2, "name": "Tinh Lọc Dầu Khoáng Suối Tự Nhiên", "cost": 120, "buff": 0.005, "desc": "Giảm thêm 0.5% hao mòn ổ bi xe tram (Lũy kế: -1.0%)"},
				{"t": 3, "name": "Đệm Cao Su Sinh Học Giảm Chấn", "cost": 180, "buff": 0.010, "desc": "Giảm 1.0% chấn động mài mòn bánh xe (Lũy kế: -2.0%)"},
				{"t": 4, "name": "Xử Lý Nhiệt Ram Bề Mặt Thép", "cost": 240, "buff": 0.010, "desc": "Tăng 1.0% độ cứng bánh răng cối xay và lò nướng (-3.0%)"},
				{"t": 5, "name": "Hợp Kim Đồng - Thiếc Chống Ma Sát", "cost": 300, "buff": 0.010, "desc": "Giảm 1.0% ma sát trục quay tuabin (Lũy kế: -4.0%)"},
				{"t": 6, "name": "Sơn Lót Gốc Nhựa Thông Tự Nhiên", "cost": 360, "buff": 0.010, "desc": "Giảm 1.0% gỉ sét khung xe do sương mù vách đá (-5.0%)"},
				{"t": 7, "name": "Dầu Bôi Trơn Chịu Nhiệt Cao", "cost": 420, "buff": 0.010, "desc": "Giảm 1.0% kẹt linh kiện lò bánh mì và máy ép (-6.0%)"},
				{"t": 8, "name": "Hợp Kim Nhôm Siêu Nhẹ Cáp Treo", "cost": 480, "buff": 0.010, "desc": "Giảm 1.0% độ giãn cáp tời trên vách đá (-7.0%)"},
				{"t": 9, "name": "Phốt Chắn Bụi Vi Hạt Xưởng Mộc", "cost": 540, "buff": 0.010, "desc": "Giảm 1.0% bụi mạt gỗ lọt vào động cơ cưa (-8.0%)"},
				{"t": 10, "name": "Lớp Mạ Crom Cứng Xi-lanh Khí", "cost": 600, "buff": 0.010, "desc": "Giảm 1.0% mài mòn máy nén khí và pít-tông (-9.0%)"},
				{"t": 11, "name": "Men Gốm Sứ Chịu Lửa Cách Nhiệt", "cost": 660, "buff": 0.010, "desc": "Giảm 1.0% nứt vỡ gạch thành lò (-10.0%)"},
				{"t": 12, "name": "Dầu Pha Hạt Graphite Mịn Bôi Trơn Ray", "cost": 720, "buff": 0.010, "desc": "Giảm 1.0% độ mài mòn ray tram (-11.0%)"},
				{"t": 13, "name": "Hợp Kim Titan Xốp Khung Gầm", "cost": 780, "buff": 0.010, "desc": "Giảm 1.0% ứng suất tải trọng lên trục bánh xe (-12.0%)"},
				{"t": 14, "name": "Polymer Kháng Kiềm & Muối Biển", "cost": 840, "buff": 0.010, "desc": "Giảm 1.0% ăn mòn tàu thuyền tại Cảng Nam (-13.0%)"},
				{"t": 15, "name": "Cảm Biến Vi Đo Độ Rung Chẩn Đoán Sớm", "cost": 920, "buff": 0.015, "desc": "Giảm 1.5% sự cố bất ngờ nhờ bảo trì đúng lúc (-14.5%)"},
				{"t": 16, "name": "Màng Oxit Nhôm Anode Hóa Bề Mặt", "cost": 1000, "buff": 0.015, "desc": "Giảm 1.5% trầy xước và ô-xy hóa vỏ máy (-16.0%)"},
				{"t": 17, "name": "Phủ Màng Kim Cương Nhân Tạo DLC", "cost": 1100, "buff": 0.015, "desc": "Tăng 1.5% tuổi thọ dao phay tiện CNC (-17.5%)"},
				{"t": 18, "name": "Hạt Nano Phân Tán Giảm Ma Sát Khô", "cost": 1200, "buff": 0.015, "desc": "Giảm 1.5% hao mòn khi khởi động nguội máy (-19.0%)"},
				{"t": 19, "name": "Polymer Vi Nang Tự Chữa Lành Vết Nứt", "cost": 1350, "buff": 0.010, "desc": "Giảm 1.0% nứt gãy vi mô kết cấu kim loại (-20.0%)"},
				{"t": 20, "name": "Lớp Phủ Nano Tự Phục Hồi Toàn Diện", "cost": 1500, "buff": 0.010, "desc": "Giảm thêm 1.0% (Tổng trọn vẹn: -21.0% hao mòn máy móc toàn đô thị!)"}
			]
		},
		"agri": {
			"name": "Nông Nghiệp Sinh Thái & Đất Lành",
			"icon": "🌾",
			"tiers": [
				{"t": 1, "name": "Sàng Lọc Hạt Giống Đều Hạt", "cost": 60, "buff": 0.005, "desc": "Tăng 0.5% sản lượng thu hoạch lúa mì đầu mùa"},
				{"t": 2, "name": "Ủ Phân Hữu Cơ Rơm Rạ Vi Sinh", "cost": 120, "buff": 0.005, "desc": "Tăng 0.5% độ phì nhiêu tầng đất mặt (Lũy kế: +1.0%)"},
				{"t": 3, "name": "Luân Canh Cây Đậu Đỗ Cố Định Đạm", "cost": 180, "buff": 0.010, "desc": "Tăng 1.0% năng suất vụ sau tự nhiên (+2.0%)"},
				{"t": 4, "name": "Bẫy Đèn Bắt Côn Trùng Sinh Học", "cost": 240, "buff": 0.010, "desc": "Giảm 1.0% thất thoát hạt lúa non (+3.0%)"},
				{"t": 5, "name": "Kênh Dẫn Nước Suối Giữ Ẩm Đất", "cost": 300, "buff": 0.010, "desc": "Tăng 1.0% sức sống mầm lúa Huyện Đông (+4.0%)"},
				{"t": 6, "name": "Giống Lúa Mì Chịu Gió Lạnh Triền Dốc", "cost": 360, "buff": 0.010, "desc": "Tăng 1.0% tỷ lệ kết hạt chắc bông (+5.0%)"},
				{"t": 7, "name": "Men Vi Sinh Kích Hoạt Đất Đỉnh Núi", "cost": 420, "buff": 0.010, "desc": "Tăng 1.0% hiệu quả hấp thụ khoáng chất (+6.0%)"},
				{"t": 8, "name": "Nhà Kính Tre Ghép Đón Sáng Tối Đa", "cost": 480, "buff": 0.010, "desc": "Tăng 1.0% năng suất rau xanh mùa sương (+7.0%)"},
				{"t": 9, "name": "Khẩu Phần Cỏ Ủ Men Cho Bò Sữa", "cost": 540, "buff": 0.010, "desc": "Tăng 1.0% sản lượng sữa tươi béo thơm (+8.0%)"},
				{"t": 10, "name": "Lưới Bẫy Sương Bổ Sung Ẩm Tự Nhiên", "cost": 600, "buff": 0.010, "desc": "Tăng 1.0% sản lượng vườn rau thủy canh (+9.0%)"},
				{"t": 11, "name": "Tỉa Cành Tán Tròn Đón Nắng Cây Quả", "cost": 660, "buff": 0.010, "desc": "Tăng 1.0% độ đường và sản lượng quả (+10.0%)"},
				{"t": 12, "name": "Vi Sinh Vật Hòa Tan Lân Tự Nhiên", "cost": 720, "buff": 0.010, "desc": "Tăng 1.0% sức phát triển rễ cây lương thực (+11.0%)"},
				{"t": 13, "name": "Giá Thể Xơ Dừa Hoạt Tính Tuần Hoàn", "cost": 780, "buff": 0.010, "desc": "Tăng 1.0% tốc độ thu hoạch rau sạch (+12.0%)"},
				{"t": 14, "name": "Men Bánh Mì Lên Men Chậm Tinh Khiết", "cost": 840, "buff": 0.010, "desc": "Tăng 1.0% độ nở xốp và dinh dưỡng bánh mì (+13.0%)"},
				{"t": 15, "name": "Đàn Ong Bản Địa Thụ Phấn Tự Nhiên", "cost": 920, "buff": 0.015, "desc": "Tăng 1.5% tỷ lệ đậu trái vườn dâu & táo (+14.5%)"},
				{"t": 16, "name": "Dung Dịch Phun Sương Ion Khoáng Sinh Học", "cost": 1000, "buff": 0.015, "desc": "Tăng 1.5% dưỡng chất và năng suất rau (+16.0%)"},
				{"t": 17, "name": "Cỏ Linh Lăng Chịu Sương Muối Huyện Bắc", "cost": 1100, "buff": 0.015, "desc": "Tăng 1.5% thức ăn xanh đàn gia súc (+17.5%)"},
				{"t": 18, "name": "Hệ Thống Thủy Canh Đa Tầng Đèn Quang Phổ", "cost": 1200, "buff": 0.015, "desc": "Tăng 1.5% sản lượng Huyện Đông (+19.0%)"},
				{"t": 19, "name": "Chế Phẩm Nấm Rễ Cộng Sinh Mycorrhiza", "cost": 1350, "buff": 0.010, "desc": "Tăng 1.0% độ trù phú đất canh tác (+20.0%)"},
				{"t": 20, "name": "Đỉnh Cao Phước Lành Nông Nghiệp Hoàn Mỹ", "cost": 1500, "buff": 0.010, "desc": "Tăng trọn vẹn +21% sản lượng, đưa bội thu 1.6x -> 1.85x!"}
			]
		},
		"energy": {
			"name": "Năng Lượng Sạch & Mạng Lưới SCADA",
			"icon": "⚡",
			"tiers": [
				{"t": 1, "name": "Cân Bằng Động Cánh Tuabin Gió", "cost": 60, "buff": 0.005, "desc": "Tăng 0.5% hiệu suất quay ở tốc độ gió thấp"},
				{"t": 2, "name": "Lõi Dây Dẫn Đồng Tinh Khiết Bện Chặt", "cost": 120, "buff": 0.005, "desc": "Giảm 0.5% tổn thất điện trở trên tuyến (+1.0%)"},
				{"t": 3, "name": "Dầu Cách Điện Biến Áp Gốc Thực Vật", "cost": 180, "buff": 0.010, "desc": "Tăng 1.0% khả năng chịu tải đỉnh trạm (+2.0%)"},
				{"t": 4, "name": "Cảm Biến Tự Động Định Hướng Gió", "cost": 240, "buff": 0.010, "desc": "Tăng 1.0% góc đón gió hữu ích của tuabin (+3.0%)"},
				{"t": 5, "name": "Chống Sét Lan Truyền Vách Đá Đỉnh Vát", "cost": 300, "buff": 0.010, "desc": "Giảm 1.0% nguy cơ ngắt điện do dông sét (+4.0%)"},
				{"t": 6, "name": "Sơn Chống Bám Bụi Cánh Quạt Tuabin", "cost": 360, "buff": 0.010, "desc": "Tăng 1.0% khí động học quay liên tục (+5.0%)"},
				{"t": 7, "name": "Rãnh Hướng Dòng Thủy Điện Suối Tự Nhiên", "cost": 420, "buff": 0.010, "desc": "Tăng 1.0% lưu lượng nước vào máy phát (+6.0%)"},
				{"t": 8, "name": "Tụ Bù Tự Động Công Suất Phản Kháng", "cost": 480, "buff": 0.010, "desc": "Giảm 1.0% sụt áp giờ cao điểm phụng vụ (+7.0%)"},
				{"t": 9, "name": "Đèn Đường LED Cảm Biến Ánh Sáng Tự Nhiên", "cost": 540, "buff": 0.010, "desc": "Tiết kiệm 1.0% điện chiếu sáng anime (+8.0%)"},
				{"t": 10, "name": "Pin Tinh Thể Đơn Lớp Hấp Thu Ánh Sáng Tán Xạ", "cost": 600, "buff": 0.010, "desc": "Tăng 1.0% điện năng ngày sương mù (+9.0%)"},
				{"t": 11, "name": "Bộ Biến Tần Inverter Sóng Sin Chuẩn", "cost": 660, "buff": 0.010, "desc": "Tăng 1.0% hiệu suất chuyển đổi dòng điện (+10.0%)"},
				{"t": 12, "name": "Cánh Tuabin Sợi Thủy Tinh Khí Động Mới", "cost": 720, "buff": 0.010, "desc": "Tăng 1.0% sản lượng điện gió Huyện Tây (+11.0%)"},
				{"t": 13, "name": "Hồ Thủy Điện Tích Năng Trên Đồi", "cost": 780, "buff": 0.010, "desc": "Tăng 1.0% nguồn dự trữ điện điều tiết (+12.0%)"},
				{"t": 14, "name": "Lưới Điện Vi Mô Phân Khu Tự Cân Bằng", "cost": 840, "buff": 0.010, "desc": "Giảm 1.0% nguy cơ quá tải cục bộ (+13.0%)"},
				{"t": 15, "name": "Giám Sát Nhiệt Hồng Ngoại Đường Cáp Ngầm", "cost": 920, "buff": 0.015, "desc": "Giảm 1.5% rủi ro phóng điện (+14.5%)"},
				{"t": 16, "name": "Pin Lưu Trữ Muối Khoáng Tự Nhiên Ban Đêm", "cost": 1000, "buff": 0.015, "desc": "Tăng 1.5% dung lượng tích điện dự phòng (+16.0%)"},
				{"t": 17, "name": "Thuật Toán SCADA Dự Báo Gió Đỉnh Núi", "cost": 1100, "buff": 0.015, "desc": "Tăng 1.5% hiệu quả điều độ điện năng (+17.5%)"},
				{"t": 18, "name": "Lớp Bán Dẫn Nano Bề Mặt Quang Năng", "cost": 1200, "buff": 0.015, "desc": "Tăng 1.5% hấp thụ quang phổ cực tím (+19.0%)"},
				{"t": 19, "name": "Pin Tinh Thể Thạch Anh Không Thoái Hóa", "cost": 1350, "buff": 0.010, "desc": "Tăng 1.0% độ ổn định điện áp vĩnh cửu (+20.0%)"},
				{"t": 20, "name": "Hệ Thống SCADA Tự Trị Toàn Đô Thị 2.0", "cost": 1500, "buff": 0.010, "desc": "Tối ưu trọn vẹn +21.0% hiệu suất năng lượng sạch toàn đô thị!"}
			]
		},
		"robotics": {
			"name": "Tự Động Hóa Nhân Đạo & SCM Kho RAM",
			"icon": "🤖",
			"tiers": [
				{"t": 1, "name": "Con Lăn Trượt Chuyển Pallet Gỗ", "cost": 60, "buff": 0.005, "desc": "Tăng 0.5% tốc độ xếp dỡ kho RAM CityResourcePool"},
				{"t": 2, "name": "Cơ Cấu Đòn Bẩy Trợ Lực Cửa Kho Nặng", "cost": 120, "buff": 0.005, "desc": "Giảm 0.5% sức kéo cơ bắp cho thủ kho (+1.0%)"},
				{"t": 3, "name": "Cân Điện Tử Đồng Bộ Tự Động", "cost": 180, "buff": 0.010, "desc": "Tăng 1.0% độ chính xác kiểm kê vật tư (+2.0%)"},
				{"t": 4, "name": "Máng Trượt Trọng Lực Cối Xay Lúa Mì", "cost": 240, "buff": 0.010, "desc": "Tăng 1.0% tốc độ nạp bột mì vào bao (+3.0%)"},
				{"t": 5, "name": "Bàn Nâng Thủy Lực Đạp Chân Xưởng Cơ Khí", "cost": 300, "buff": 0.010, "desc": "Giảm 1.0% thời gian gá đặt linh kiện (+4.0%)"},
				{"t": 6, "name": "Xe Đẩy Hàng 4 Bánh Có Phanh Tự Hãm Dốc", "cost": 360, "buff": 0.010, "desc": "Tăng 1.0% an toàn vận chuyển nội bộ (+5.0%)"},
				{"t": 7, "name": "Cần Tời Cáp Mềm Dựng Khung Gỗ", "cost": 420, "buff": 0.010, "desc": "Tăng 1.0% tốc độ dựng cột nhà ở (+6.0%)"},
				{"t": 8, "name": "Cữ Chặn Tự Động Máy Cưa Gỗ Xưởng Mộc", "cost": 480, "buff": 0.010, "desc": "Tăng 1.0% độ chuẩn xác thanh gỗ xẻ (+7.0%)"},
				{"t": 9, "name": "Băng Chuyền Cao Su Chuyển Bao Bột Mì", "cost": 540, "buff": 0.010, "desc": "Tăng 1.0% lưu lượng hàng xuất kho (+8.0%)"},
				{"t": 10, "name": "Máy Trộn Bột Hai Trục Đảo Tốc Độ", "cost": 600, "buff": 0.010, "desc": "Tăng 1.0% năng suất thợ làm bánh mì (+9.0%)"},
				{"t": 11, "name": "Xe Nâng Tay Trợ Lực Điện Kiện Đá", "cost": 660, "buff": 0.010, "desc": "Tăng 1.0% tốc độ cấp đá xây dựng (+10.0%)"},
				{"t": 12, "name": "Đồ Gá Nhanh Khí Nén Máy Tiện CNC", "cost": 720, "buff": 0.010, "desc": "Tăng 1.0% năng suất sản xuất linh kiện (+11.0%)"},
				{"t": 13, "name": "Cảm Biến Quang Học Đếm Sản Phẩm Xuất Xưởng", "cost": 780, "buff": 0.010, "desc": "Tăng 1.0% tốc độ đối soát ERP (+12.0%)"},
				{"t": 14, "name": "Tay Nâng Khí Nén Đỡ Chi Tiết Động Cơ Nặng", "cost": 840, "buff": 0.010, "desc": "Giảm 1.0% mệt mỏi cho thợ sửa xe (+13.0%)"},
				{"t": 15, "name": "Cần Cẩu Tháp Điều Khiển Từ Xa Góc Rộng", "cost": 920, "buff": 0.015, "desc": "Tăng 1.5% tốc độ cẩu lắp công trình (+14.5%)"},
				{"t": 16, "name": "Xe Kéo Điện Tự Hành Bến Cá Huyện Nam", "cost": 1000, "buff": 0.015, "desc": "Tăng 1.5% tốc độ luân chuyển cá tươi (+16.0%)"},
				{"t": 17, "name": "Cánh Tay Kẹp Hỗ Trợ Thợ Hàn Ray Tram", "cost": 1100, "buff": 0.015, "desc": "Giảm 1.5% thời gian xử lý hỏng hóc lớn (+17.5%)"},
				{"t": 18, "name": "Đầu Cắt Đĩa Xoay Thủy Lực Đào Hầm", "cost": 1200, "buff": 0.015, "desc": "Tăng 1.5% tiến độ thi công metro xuyên núi (+19.0%)"},
				{"t": 19, "name": "Robot Bò Dây Kiểm Tra An Toàn Cáp Treo", "cost": 1350, "buff": 0.010, "desc": "Tăng 1.0% độ chính xác rà soát cáp treo (+20.0%)"},
				{"t": 20, "name": "Hệ Thống Tự Động Hóa Nhân Đạo Hợp Nhất", "cost": 1500, "buff": 0.010, "desc": "Giải phóng triệt để công việc nặng nhọc (+21.0% SCM)"}
			]
		},
		"wellness": {
			"name": "Y Học Phục Hồi & Môi Trường Sinh Thái",
			"icon": "🌿",
			"tiers": [
				{"t": 1, "name": "Trà Thảo Mộc Sấy Lạnh Giữ Hương", "cost": 60, "buff": 0.005, "desc": "Hồi phục thể lực nhanh hơn 0.5% sau giờ đi bộ"},
				{"t": 2, "name": "Đệm Bông Tự Nhiên Thoáng Khí Ký Túc Xá", "cost": 120, "buff": 0.005, "desc": "Tăng 0.5% chất lượng giấc ngủ sâu (+1.0%)"},
				{"t": 3, "name": "Bể Lọc Cát Thạch Anh Nước Suối Nóng", "cost": 180, "buff": 0.010, "desc": "Tăng 1.0% độ tinh khiết dòng khoáng Onsen (+2.0%)"},
				{"t": 4, "name": "Muối Khoáng Ngâm Chân Thảo Dược Bắc Núi", "cost": 240, "buff": 0.010, "desc": "Giảm 1.0% mỏi cơ sau giờ làm việc (+3.0%)"},
				{"t": 5, "name": "Khử Khuẩn Nước Bằng Sục Khí Ozone Tự Nhiên", "cost": 300, "buff": 0.010, "desc": "Tăng 1.0% an toàn nước sinh hoạt (+4.0%)"},
				{"t": 6, "name": "Bột Khoáng Dược Thảo Ngâm Bồn Gỗ Thông", "cost": 360, "buff": 0.010, "desc": "Tăng 1.0% tốc độ hồi phục sinh lực (+5.0%)"},
				{"t": 7, "name": "Rãnh Lọc Sỏi Sinh Học Tuần Hoàn Nước Xám", "cost": 420, "buff": 0.010, "desc": "Giảm 1.0% thất thoát nước đô thị (+6.0%)"},
				{"t": 8, "name": "Sưởi Gốm Hồng Ngoại Phòng Thay Đồ Onsen", "cost": 480, "buff": 0.010, "desc": "Giảm 1.0% sốc nhiệt gió lạnh cao nguyên (+7.0%)"},
				{"t": 9, "name": "Phòng Xông Hơi Đá Muối Khoáng Huyện Bắc", "cost": 540, "buff": 0.010, "desc": "Tăng 1.0% tuần hoàn máu và sảng khoái (+8.0%)"},
				{"t": 10, "name": "Lọc Than Hoạt Tính Gáo Dừa Tự Nhiên", "cost": 600, "buff": 0.010, "desc": "Tăng 1.0% độ ngọt và khoáng nước uống (+9.0%)"},
				{"t": 11, "name": "Quy Trình Giãn Cơ Vận Động Viên Thể Thao", "cost": 660, "buff": 0.010, "desc": "Giảm 1.0% nguy cơ căng cứng cơ (+10.0%)"},
				{"t": 12, "name": "Đèn Phổ Quang Ban Mai Trong Phòng Ở", "cost": 720, "buff": 0.010, "desc": "Tăng 1.0% sảng khoái khi thức dậy (+11.0%)"},
				{"t": 13, "name": "Màng Thẩm Thấu Sinh Học Tuần Hoàn Nước 100%", "cost": 780, "buff": 0.010, "desc": "Tăng 1.0% tỷ lệ tái tạo nước ngọt (+12.0%)"},
				{"t": 14, "name": "Liệu Pháp Tinh Dầu Thông Rừng Nguyên Sinh", "cost": 840, "buff": 0.010, "desc": "Giảm 1.0% mệt mỏi tâm trí (+13.0%)"},
				{"t": 15, "name": "Bồn Tắm Bùn Khoáng Nóng Giàu Silic", "cost": 920, "buff": 0.015, "desc": "Tăng 1.5% độ dẻo dai cơ khớp (+14.5%)"},
				{"t": 16, "name": "Cảm Biến Sinh Thái Rà Soát Tự Động Nước Thải", "cost": 1000, "buff": 0.015, "desc": "Tăng 1.5% độ trong lành môi trường (+16.0%)"},
				{"t": 17, "name": "Ánh Sáng Sinh Học Bước Sóng Ấm Thư Giãn", "cost": 1100, "buff": 0.015, "desc": "Nâng cao 1.5% tâm trạng an hòa cư dân (+17.5%)"},
				{"t": 18, "name": "Hệ Thống Lọc Không Khí Bằng Rèm Cây Dương Xỉ", "cost": 1200, "buff": 0.015, "desc": "Tăng 1.5% độ trong sạch không khí (+19.0%)"},
				{"t": 19, "name": "Tuần Hoàn Sinh Thái Không Rác Thải Zero-Waste", "cost": 1350, "buff": 0.010, "desc": "Tiết kiệm 1.0% tài nguyên kho RAM (+20.0%)"},
				{"t": 20, "name": "Hòa Nhịp Sóng Âm Trị Liệu & Khoáng Vi Lượng", "cost": 1500, "buff": 0.010, "desc": "Tối ưu trọn vẹn +21.0% thể lực, hòa hợp tuyệt đối!"}
			]
		}
	}

## Nạp trạng thái từ SQLite
func _load_from_database(db: Node) -> void:
	var raw_db = db.get("db")
	if raw_db == null or not db.get("is_db_open"):
		return
	
	raw_db.query("SELECT * FROM research_state WHERE id = 1;")
	var state_res = raw_db.query_result
	if state_res != null and not state_res.is_empty():
		var row = state_res[0]
		kbu_balance = int(row.get("kbu_balance", 120))
		active_branch_id = str(row.get("active_branch_id", "materials"))
		active_tier = int(row.get("active_tier", 1))
		current_progress_kbu = int(row.get("current_progress_kbu", 0))
		acceleration_grant_active = bool(row.get("acceleration_grant_active", 0))
	
	raw_db.query("SELECT * FROM research_tech_tree;")
	var tech_res = raw_db.query_result
	if tech_res != null:
		for r in tech_res:
			var key = "%s_%d" % [r["branch_id"], int(r["tier_level"])]
			if int(r["is_unlocked"]) == 1:
				unlocked_techs[key] = true
			if int(r["is_deployed"]) == 1:
				deployed_techs[key] = true

## Lưu trạng thái vào SQLite
func save_research_state() -> void:
	var db = _get_database_manager()
	if db == null or not db.get("is_db_open"):
		return
	var raw_db = db.get("db")
	if raw_db == null:
		return
	
	var sql = """
	UPDATE research_state SET
		kbu_balance = %d,
		active_branch_id = '%s',
		active_tier = %d,
		current_progress_kbu = %d,
		acceleration_grant_active = %d,
		last_kbu_update_unix = %d
	WHERE id = 1;
	""" % [
		kbu_balance, active_branch_id, active_tier,
		current_progress_kbu, 1 if acceleration_grant_active else 0,
		int(Time.get_unix_time_from_system())
	]
	raw_db.query(sql)

## Mỗi phút game trôi qua: Sinh điểm KBU & Tích lũy vào Đề án trọng điểm
func _on_world_time_ticked(_day: int, _hour: int, _minute: int, _day_name: String) -> void:
	advance_research_minute(1)

func advance_research_minute(minutes_count: int = 1) -> void:
	var kbu_rate = GRANT_KBU_PER_GAME_MINUTE if acceleration_grant_active else BASE_KBU_PER_GAME_MINUTE
	var generated_kbu = kbu_rate * minutes_count
	kbu_balance += generated_kbu
	kbu_updated.emit(kbu_balance, generated_kbu)

	# Giảm thời gian tài trợ nếu đang kích hoạt
	if acceleration_grant_active:
		grant_remaining_minutes -= minutes_count
		if grant_remaining_minutes <= 0:
			acceleration_grant_active = false
			print("[ResearchManager] ⏳ Gói Tài Trợ Tăng Tốc R&D đã kết thúc chu kỳ 7 ngày.")

	# Tích lũy vào đề án đang chọn
	var required_kbu = get_tier_cost(active_branch_id, active_tier)
	if required_kbu > 0:
		var key = "%s_%d" % [active_branch_id, active_tier]
		if not is_tech_unlocked(active_branch_id, active_tier):
			current_progress_kbu += generated_kbu
			var pct = clampf(float(current_progress_kbu) / float(required_kbu), 0.0, 1.0)
			directive_progress_updated.emit(active_branch_id, active_tier, current_progress_kbu, required_kbu, pct)

			if current_progress_kbu >= required_kbu:
				_auto_complete_research(active_branch_id, active_tier)

## Chọn đề án trọng điểm của Thị Trưởng
func select_active_directive(branch_id: String, tier: int) -> bool:
	var b_id = _normalize_branch_id(branch_id)
	if not tech_catalog.has(b_id):
		return false
	if tier < 1 or tier > 20:
		return false
	
	active_branch_id = b_id
	active_tier = tier
	current_progress_kbu = 0
	save_research_state()
	
	var cost = get_tier_cost(b_id, tier)
	directive_progress_updated.emit(b_id, tier, 0, cost, 0.0)
	print("[ResearchManager] 🎯 Thị Trưởng ban hành Đề án Trọng điểm: %s (Bậc %d)!" % [get_tech_name(b_id, tier), tier])
	return true

## Thị Trưởng tài trợ tăng tốc (R&D Acceleration Grant - 5.000Đ)
func grant_acceleration_funding() -> bool:
	var wm = _get_world_manager()
	if wm == null:
		return false
	
	# Kiểm tra ngân khố đủ chi phí tài trợ
	if wm.treasury_city < ACCELERATION_GRANT_COST:
		print("[ResearchManager] ⚠️ Kho Bạc Đô Thị không đủ 5.000Đ để giải ngân tài trợ R&D.")
		return false

	# Trừ ngân sách và kích hoạt tài trợ
	wm.deposit_city_tax(-ACCELERATION_GRANT_COST)
	acceleration_grant_active = true
	grant_remaining_minutes = ACCELERATION_DURATION_MINUTES
	acceleration_grant_activated.emit(grant_remaining_minutes)
	save_research_state()
	print("[ResearchManager] 🚀 Thị Trưởng đã xuất 5.000Đ từ Kho Bạc Đô Thị để nhân đôi tốc độ R&D (+20 KBU/phút)!")
	return true



## Tự động mở khóa khi đạt 100% KBU
func _auto_complete_research(branch_id: String, tier: int) -> void:
	var b_id = _normalize_branch_id(branch_id)
	var key = "%s_%d" % [b_id, tier]
	unlocked_techs[key] = true
	var t_name = get_tech_name(b_id, tier)
	tech_unlocked.emit(b_id, tier, t_name)
	print("[ResearchManager] 🎉 ĐÃ HOÀN TẤT NGHIÊN CỨU: %s (Bậc %d)!" % [t_name, tier])
	
	# Lưu vào SQLite
	var db = _get_database_manager()
	if db != null and db.get("is_db_open"):
		var raw_db = db.get("db")
		if raw_db != null:
			var sql = """
			INSERT INTO research_tech_tree (branch_id, tier_level, tech_name, kbu_cost, benefit_desc, is_unlocked, unlocked_at)
			VALUES ('%s', %d, '%s', %d, '%s', 1, CURRENT_TIMESTAMP)
			ON CONFLICT(branch_id, tier_level) DO UPDATE SET is_unlocked = 1, unlocked_at = CURRENT_TIMESTAMP;
			""" % [b_id, tier, t_name, get_tier_cost(b_id, tier), get_tier_desc(b_id, tier)]
			raw_db.query(sql)
	
	# Tự động chuyển sang bậc tiếp theo nếu chưa đạt bậc 20
	if tier < 20:
		select_active_directive(b_id, tier + 1)

## Thị Trưởng bấm nút "Ban Hành Toàn Thành Phố" (City-Wide Blueprint Deployment)
func deploy_blueprint_citywide(branch_id: String, tier: int) -> bool:
	var b_id = _normalize_branch_id(branch_id)
	var key = "%s_%d" % [b_id, tier]
	if not unlocked_techs.has(key) or not unlocked_techs[key]:
		print("[ResearchManager] ⚠️ Sáng chế này chưa hoàn thành nghiên cứu, chưa thể ban hành.")
		return false
	
	deployed_techs[key] = true
	var t_name = get_tech_name(b_id, tier)
	var buff = get_total_branch_buff(b_id)
	tech_deployed_citywide.emit(b_id, tier, t_name, buff)
	print("[ResearchManager] 📢 BAN HÀNH TOÀN ĐÔ THỊ: %s! Hiệu quả tích lũy nhánh %s: +%.1f%%" % [t_name, b_id, buff * 100.0])
	
	# Cập nhật SQLite
	var db = _get_database_manager()
	if db != null and db.get("is_db_open"):
		var raw_db = db.get("db")
		if raw_db != null:
			raw_db.query("UPDATE research_tech_tree SET is_deployed = 1 WHERE branch_id = '%s' AND tier_level = %d;" % [b_id, tier])

	# Cập nhật trực tiếp vào WorldManager nếu là nhánh nông nghiệp
	if b_id == "agri":
		var wm = _get_world_manager()
		if wm != null and "blessed_abundance_multiplier" in wm:
			wm.blessed_abundance_multiplier = 1.60 + get_blessed_abundance_boost()
			print("[WorldManager] 🌾 Đất Lành được gia tăng phước hạnh: Hệ số Bội Thu đạt %.2fx!" % wm.blessed_abundance_multiplier)
		if is_inside_tree() and has_node("/root/BuildingJobRegistry"):
			var bjr = get_node("/root/BuildingJobRegistry")
			if bjr != null and "blessed_abundance_multiplier" in bjr:
				bjr.blessed_abundance_multiplier = 1.60 + get_blessed_abundance_boost()

	if b_id == "materials":
		if is_inside_tree() and has_node("/root/BuildingJobRegistry"):
			var bjr = get_node("/root/BuildingJobRegistry")
			if bjr != null and "tech_wear_reduction_ratio" in bjr:
				bjr.tech_wear_reduction_ratio = get_wear_and_tear_reduction()

	save_research_state()
	return true

## Hỗ trợ Offline Catch-Up từ UnifiedTimelineServer
func apply_offline_research_progress(game_minutes_elapsed: int) -> void:
	advance_research_minute(game_minutes_elapsed)
	save_research_state()

# ------------------------------------------------------------------------------
# CÁC HÀM TRUY VẤN CHỈ SỐ BUFF TOÀN ĐÔ THỊ
# ------------------------------------------------------------------------------

## Tỷ lệ giảm hao mòn máy móc (Nhánh Vật Liệu: Tối đa -21%)
func get_wear_and_tear_reduction() -> float:
	return get_total_branch_buff("materials")

## Tăng sản lượng nông nghiệp (Nhánh Nông Nghiệp: Tối đa +25%, đưa hệ số đất lành 1.6x -> 1.85x)
func get_blessed_abundance_boost() -> float:
	var raw_buff = get_total_branch_buff("agri")
	return (raw_buff / 0.210) * 0.250 if raw_buff > 0.0 else 0.0

## Hiệu suất năng lượng sạch SCADA (Nhánh Năng Lượng: Tối đa +21%)
func get_energy_efficiency_boost() -> float:
	return get_total_branch_buff("energy")

## Hiệu quả SCM và luân chuyển hàng hóa kho RAM (Nhánh Tự Động Hóa: Tối đa +21%)
func get_scram_logistics_boost() -> float:
	return get_total_branch_buff("robotics")

## Tốc độ hồi phục thể lực & hòa hợp (Nhánh Y Học: Tối đa +21%)
func get_wellness_stamina_boost() -> float:
	return get_total_branch_buff("wellness")

func get_wellness_vitality_boost() -> float:
	return get_wellness_stamina_boost()

func _normalize_branch_id(b_id: String) -> String:
	if b_id == "automation":
		return "robotics"
	return b_id

func get_branch_name(branch_id: String) -> String:
	var b_id = _normalize_branch_id(branch_id)
	if tech_catalog.has(b_id):
		return str(tech_catalog[b_id].get("name", ""))
	return ""

func get_branch_tiers(branch_id: String) -> Array:
	var b_id = _normalize_branch_id(branch_id)
	if tech_catalog.has(b_id):
		return tech_catalog[b_id].get("tiers", [])
	return []

func get_total_branch_buff(branch_id: String) -> float:
	var b_id = _normalize_branch_id(branch_id)
	var total: float = 0.0
	if not tech_catalog.has(b_id):
		return total
	
	var tiers = tech_catalog[b_id]["tiers"]
	for item in tiers:
		var key = "%s_%d" % [b_id, item["t"]]
		if deployed_techs.has(key) and deployed_techs[key]:
			total += float(item.get("buff", 0.0))
	return clampf(total, 0.0, 0.25)

func is_tech_unlocked(branch_id: String, tier: int) -> bool:
	var b_id = _normalize_branch_id(branch_id)
	var key = "%s_%d" % [b_id, tier]
	return unlocked_techs.has(key) and unlocked_techs[key]

func is_tech_deployed(branch_id: String, tier: int) -> bool:
	var b_id = _normalize_branch_id(branch_id)
	var key = "%s_%d" % [b_id, tier]
	return deployed_techs.has(key) and deployed_techs[key]

func get_tier_cost(branch_id: String, tier: int) -> int:
	var b_id = _normalize_branch_id(branch_id)
	if not tech_catalog.has(b_id):
		return 0
	var tiers = tech_catalog[b_id]["tiers"]
	if tier >= 1 and tier <= tiers.size():
		return int(tiers[tier - 1]["cost"])
	return 0

func get_tech_name(branch_id: String, tier: int) -> String:
	var b_id = _normalize_branch_id(branch_id)
	if not tech_catalog.has(b_id):
		return ""
	var tiers = tech_catalog[b_id]["tiers"]
	if tier >= 1 and tier <= tiers.size():
		return str(tiers[tier - 1]["name"])
	return ""

func get_tier_desc(branch_id: String, tier: int) -> String:
	var b_id = _normalize_branch_id(branch_id)
	if not tech_catalog.has(b_id):
		return ""
	var tiers = tech_catalog[b_id]["tiers"]
	if tier >= 1 and tier <= tiers.size():
		return str(tiers[tier - 1]["desc"])
	return ""

