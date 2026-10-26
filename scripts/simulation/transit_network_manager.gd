extends Node

# Autoload Singleton: TransitNetworkManager
# Quản lý Đồ thị Giao thông Mạng Nhện (Spiderweb Transit Graph) & 5 Huyện

signal transit_rush_hour_started(destination: String, reason: String)
signal transit_congestion_changed(spoke_name: String, congestion_level: float)

# 5 Địa Bàn Quận Huyện
const DISTRICT_PLATEAU_CORE: String = "DISTRICT_PLATEAU_CORE"       # Huyện Đỉnh Vát (Dân cư chủ yếu, R <= 7.5km)
const DISTRICT_EAST_FARMS: String = "DISTRICT_EAST_FARMS"           # Huyện Đông (Thảo nguyên & Nông trại, R ~ 25km)
const DISTRICT_NORTH_FOREST: String = "DISTRICT_NORTH_FOREST"       # Huyện Bắc (Đại ngàn, Onsen & Mỏ đá quý, R ~ 25km)
const DISTRICT_WEST_INDUSTRY: String = "DISTRICT_WEST_INDUSTRY"     # Huyện Tây (Kỹ nghệ sạch & Điện gió, R ~ 25km)
const DISTRICT_SOUTH_COAST: String = "DISTRICT_SOUTH_COAST"         # Huyện Nam (Duyên hải & Cảng biển, R ~ 25km)

# Danh mục 5 Phương Tiện Giao Thông
enum TransitMode {
	WALKING = 0,        # Đi bộ: ~4 km/h (Cả ngày chưa hết)
	BICYCLE = 1,        # Xe đạp: ~13 km/h (Khoảng 4 tiếng từ ngoại vi)
	BUS = 2,            # Xe bus BRT: ~45 km/h (40 phút nếu không tắc)
	CAR_MOTORBIKE = 3,  # Xe máy / Ô tô: ~60 km/h (30 phút nếu không tắc)
	METRO_EXPRESS = 4   # Tàu ngầm Metro cao tốc: 144 km/h (15-20 phút nếu không dừng)
}

# Tốc độ trung bình tiêu chuẩn (km/h)
const SPEED_KMH: Dictionary = {
	TransitMode.WALKING: 4.0,
	TransitMode.BICYCLE: 13.0,
	TransitMode.BUS: 45.0,
	TransitMode.CAR_MOTORBIKE: 60.0,
	TransitMode.METRO_EXPRESS: 144.0
}

# 5 Tuyến Vành Đai Đồng Tâm (Bán kính km & độ cao y mét)
const RINGS: Dictionary = {
	1: {"name": "Vành Đai 1 - Lõi Đỉnh Vát", "radius_km": 1.5, "altitude_y": 600.0},
	2: {"name": "Vành Đai 2 - Đô Thị Đỉnh Vát", "radius_km": 5.0, "altitude_y": 600.0},
	3: {"name": "Vành Đai 3 - Mép Vách Núi Parkway", "radius_km": 7.5, "altitude_y": 590.0},
	4: {"name": "Vành Đai 4 - Chân Núi Vành Tròn", "radius_km": 16.0, "altitude_y": 60.0},
	5: {"name": "Vành Đai 5 - Ngoại Vi Biên Giới", "radius_km": 30.0, "altitude_y": 20.0}
}

# 8 Trục Nan Hoa Hướng Tâm (Góc xoay độ trên mặt phẳng XZ)
const SPOKES: Dictionary = {
	"SPOKE_N": {"name": "Đại Lộ Bắc (Huyện Đại Ngàn & Mỏ Quý)", "angle_deg": 0.0, "direction": Vector2(0, -1)},
	"SPOKE_NE": {"name": "Nan Hoa Đông Bắc (Lâm trường cao nguyên)", "angle_deg": 45.0, "direction": Vector2(0.707, -0.707)},
	"SPOKE_E": {"name": "Đại Lộ Đông (Huyện Nông Nghiệp Vựa Lúa)", "angle_deg": 90.0, "direction": Vector2(1, 0)},
	"SPOKE_SE": {"name": "Nan Hoa Đông Nam (Trang trại bò sữa ven biển)", "angle_deg": 135.0, "direction": Vector2(0.707, 0.707)},
	"SPOKE_S": {"name": "Đại Lộ Nam (Huyện Duyên Hải & Bến Cảng)", "angle_deg": 180.0, "direction": Vector2(0, 1)},
	"SPOKE_SW": {"name": "Nan Hoa Tây Nam (Vùng ven biển & Đầm lầy muối)", "angle_deg": 225.0, "direction": Vector2(-0.707, 0.707)},
	"SPOKE_W": {"name": "Đại Lộ Tây (Huyện Kỹ Nghệ & Điện Gió)", "angle_deg": 270.0, "direction": Vector2(-1, 0)},
	"SPOKE_NW": {"name": "Nan Hoa Tây Bắc (Đồi thông & Công nghệ sạch)", "angle_deg": 315.0, "direction": Vector2(-0.707, -0.707)}
}

# Tọa độ trung tâm từng Huyện (tính bằng km)
const DISTRICT_COORDINATES_KM: Dictionary = {
	DISTRICT_PLATEAU_CORE: Vector3(0.0, 600.0, 0.0),
	DISTRICT_EAST_FARMS: Vector3(22.0, 40.0, 0.0),
	DISTRICT_NORTH_FOREST: Vector3(0.0, 80.0, -22.0),
	DISTRICT_WEST_INDUSTRY: Vector3(-22.0, 50.0, 0.0),
	DISTRICT_SOUTH_COAST: Vector3(0.0, 10.0, 24.0)
}

func _ready() -> void:
	print("[TransitNetworkManager] Khởi tạo Hệ Thống Giao Thông Mạng Nhện (5 Huyện, 5 Vành Đai, 8 Nan Hoa).")
	var world_mgr: Node = get_node_or_null("/root/WorldManager")
	if world_mgr:
		world_mgr.liturgy_started.connect(_on_world_liturgy_rush)

func _on_world_liturgy_rush(_day_name: String) -> void:
	transit_rush_hour_started.emit("Mega Office Trung Tâm", "Thánh Lễ Định Kỳ")
	print("[TransitNetworkManager] 🕸️ MẠNG NHỆN KÍCH HOẠT DÒNG NGƯỜI: Toàn bộ cư dân 4 huyện chân núi và huyện đỉnh đổ dồn về Tâm Ga Trung Tâm!")

## Tính toán thời gian di chuyển (In-Game Minutes) theo chuẩn thiết kế
func calculate_travel_time_minutes(distance_km: float, mode: TransitMode, is_congested: bool = false) -> float:
	var speed: float = SPEED_KMH.get(mode, 4.0)
	var congestion_factor: float = 1.0
	
	if is_congested:
		match mode:
			TransitMode.CAR_MOTORBIKE:
				congestion_factor = 1.6 # Kẹt xe làm chậm 60%
			TransitMode.BUS:
				congestion_factor = 1.3 # Bus có làn ưu tiên nhẹ, chậm 30%
			TransitMode.METRO_EXPRESS:
				congestion_factor = 1.0 # Metro ngầm không bao giờ kẹt xe!
			TransitMode.BICYCLE:
				congestion_factor = 1.05 # Xe đạp ít bị kẹt
			TransitMode.WALKING:
				congestion_factor = 1.0 # Đi bộ không kẹt xe
				
	var hours: float = (distance_km / speed) * congestion_factor
	return hours * 60.0

## Quy đổi thời gian In-Game sang thời gian thực người chơi trải nghiệm (Seconds)
## Theo tỷ lệ vàng 1:20 (1 phút in-game = 3 giây thực)
func convert_game_minutes_to_real_seconds(game_minutes: float) -> float:
	return game_minutes * 3.0

## Tính toán lộ trình từ vị trí bất kỳ về Ga Lõi Trung Tâm Mega Office
func calculate_route_to_central_hub(from_pos_km: Vector2, mode: TransitMode, is_congested: bool = false) -> Dictionary:
	var straight_line_dist: float = from_pos_km.length()
	# Theo mô hình mạng nhện, khoảng cách thực tế uốn lượn và leo dốc vách núi ~ 1.15x - 1.25x khoảng cách đường chim bay
	var spiderweb_travel_dist: float = straight_line_dist * 1.2
	if straight_line_dist < 1.0:
		spiderweb_travel_dist = straight_line_dist
		
	var game_minutes: float = calculate_travel_time_minutes(spiderweb_travel_dist, mode, is_congested)
	var real_seconds: float = convert_game_minutes_to_real_seconds(game_minutes)
	
	var mode_name: String = ""
	match mode:
		TransitMode.METRO_EXPRESS: mode_name = "Tàu Ngầm Metro Xuyên Núi"
		TransitMode.CAR_MOTORBIKE: mode_name = "Ô tô / Xe Máy Đại Lộ"
		TransitMode.BUS: mode_name = "Xe Bus BRT Hướng Tâm"
		TransitMode.BICYCLE: mode_name = "Xe Đạp Làn Xanh"
		TransitMode.WALKING: mode_name = "Đi Bộ Vỉa Hè & Bậc Thang"
		
	return {
		"distance_km": spiderweb_travel_dist,
		"mode": mode,
		"mode_name": mode_name,
		"travel_time_game_minutes": game_minutes,
		"travel_time_real_seconds": real_seconds,
		"is_congested": is_congested
	}

## Xác định huyện theo vị trí (XZ km)
func get_district_by_coord(pos_km: Vector2) -> String:
	var dist: float = pos_km.length()
	if dist <= 7.5:
		return DISTRICT_PLATEAU_CORE
		
	var angle_deg: float = rad_to_deg(atan2(pos_km.y, pos_km.x))
	if angle_deg < 0:
		angle_deg += 360.0
		
	# Phân chia 4 hướng chân núi (mỗi hướng 90 độ)
	# 45 đến 135: Huyện Nam (Coast)
	# 135 đến 225: Huyện Tây (Industry)
	# 225 đến 315: Huyện Bắc (Forest)
	# 315 đến 45: Huyện Đông (Farms)
	if angle_deg >= 45.0 and angle_deg < 135.0:
		return DISTRICT_SOUTH_COAST
	elif angle_deg >= 135.0 and angle_deg < 225.0:
		return DISTRICT_WEST_INDUSTRY
	elif angle_deg >= 225.0 and angle_deg < 315.0:
		return DISTRICT_NORTH_FOREST
	else:
		return DISTRICT_EAST_FARMS
