class_name POIManager
extends Node

# ==============================================================================
# POI MANAGER (POINTS OF INTEREST REGISTRY) - TÂN THẾ GIỚI
# Quản trị cơ sở dữ liệu 10 Điểm Quan Trọng Cốt Lõi (POIs), Tọa độ GPS & Thủy Văn
# Tích hợp cho Tablet Thị Trưởng, HUD Bản Đồ & Điều Hướng Thực Địa
# ==============================================================================

const METERS_PER_KM: float = 1000.0

# Bảng dữ liệu 10 POIs chính thức theo Master Blueprint
const POI_REGISTRY: Array[Dictionary] = [
	{
		"id": 1,
		"key": "SUMMIT_CENTER",
		"name_vi": "Quảng Trường Trung Tâm Đỉnh Núi",
		"district": "Cao Nguyên Trung Tâm",
		"map_coord_km": Vector3(0.0, 0.0, 600.0), # (Map X km, Map Y km, Height m)
		"godot_pos": Vector3(0.0, 600.0, 0.0),    # (X m, Y height m, Z m: South=+Z)
		"description": "Mega Office Tân Thế Giới và Đại Hội Trường, trung tâm điều hành đô thị, tầm nhìn 360 độ toàn thế giới.",
		"category": "CIVIC"
	},
	{
		"id": 2,
		"key": "SUMMIT_LAKE",
		"name_vi": "Hồ Đỉnh Đầu Nguồn",
		"district": "Cao Nguyên Trung Tâm",
		"map_coord_km": Vector3(-2.0, -3.0, 590.0),
		"godot_pos": Vector3(-2000.0, 590.0, 3000.0),
		"description": "Hồ trữ nước ngọt khổng lồ (1.5 km², sâu 50m), bến thuyền chèo gỗ, cống tràn điều tiết thủy lợi cho toàn cõi.",
		"category": "WATER"
	},
	{
		"id": 3,
		"key": "MAIN_WATERFALL",
		"name_vi": "Thác Nước Chính Nam",
		"district": "Huyện Nam",
		"map_coord_km": Vector3(0.0, -12.0, 280.0),
		"godot_pos": Vector3(0.0, 280.0, 12000.0),
		"description": "Thác nước đổ hùng vĩ nhất từ +600m xuống +280m rồi tới +140m, lưu lượng 26 m³/s, hiệu ứng bọt sương anime 3D.",
		"category": "NATURE"
	},
	{
		"id": 4,
		"key": "WATERFALL_BASIN",
		"name_vi": "Hồ Chân Thác",
		"district": "Huyện Nam",
		"map_coord_km": Vector3(0.0, -13.0, 140.0),
		"godot_pos": Vector3(0.0, 140.0, 13000.0),
		"description": "Vùng nước sâu chân thác, cầu gỗ bắc ngang, bãi đá vôi trắng, khu cắm trại thưởng ngoạn và đài thiên văn ven nước.",
		"category": "NATURE"
	},
	{
		"id": 5,
		"key": "SCENIC_LOOKOUT",
		"name_vi": "Mỏm Đá Ngắm Cảnh Vươn Vực",
		"district": "Huyện Nam",
		"map_coord_km": Vector3(1.0, -13.0, 300.0),
		"godot_pos": Vector3(1000.0, 300.0, 13000.0),
		"description": "Mỏm sa thạch tự nhiên nhô ra không trung 18m, góc nhìn panorama ngoạn mục ra biển mây bồng bềnh tại +140m.",
		"category": "VIEWPOINT"
	},
	{
		"id": 6,
		"key": "NORTH_VILLAGE",
		"name_vi": "Làng Bắc",
		"district": "Huyện Bắc",
		"map_coord_km": Vector3(0.0, 10.0, 50.0),
		"godot_pos": Vector3(0.0, 50.0, -10000.0),
		"description": "Làng nông nghiệp trù phú, trại ngựa thồ, chợ nông sản sạch, cửa ngõ đường mòn phía Bắc.",
		"category": "SETTLEMENT"
	},
	{
		"id": 7,
		"key": "EAST_VILLAGE",
		"name_vi": "Làng Đông",
		"district": "Huyện Đông",
		"map_coord_km": Vector3(10.0, 0.0, 30.0),
		"godot_pos": Vector3(10000.0, 30.0, 0.0),
		"description": "Làng đồi kiến trúc gỗ cổ, nghệ nhân mộc và cơ khí chế tác, đồi chè thơm và suối róc rách.",
		"category": "SETTLEMENT"
	},
	{
		"id": 8,
		"key": "WEST_VILLAGE",
		"name_vi": "Làng Tây",
		"district": "Huyện Tây",
		"map_coord_km": Vector3(-10.0, 0.0, 40.0),
		"godot_pos": Vector3(-10000.0, 40.0, 0.0),
		"description": "Làng thảo nguyên đồng cỏ, trang trại bò sữa, cừu lông, vườn hoa bướm rập rờn đón hoàng hôn.",
		"category": "SETTLEMENT"
	},
	{
		"id": 9,
		"key": "SOUTH_VALLEY",
		"name_vi": "Thung Lũng Thương Mại Nam",
		"district": "Huyện Nam",
		"map_coord_km": Vector3(0.0, -20.0, 10.0),
		"godot_pos": Vector3(0.0, 10.0, 20000.0),
		"description": "Chợ đầu mối sông cái, cầu đá lớn, trạm trung chuyển hàng hóa thủy bộ kết nối với các lân bang.",
		"category": "COMMERCE"
	},
	{
		"id": 10,
		"key": "SOUTH_CLIFF_TRAIL",
		"name_vi": "Tuyến Đường Mòn Vách Đá Nam",
		"district": "Huyện Nam",
		"map_coord_km": Vector3(0.0, -8.0, 450.0),
		"godot_pos": Vector3(0.0, 450.0, 8000.0),
		"description": "Hệ thống đường lát đá bậc tam cấp ngoạn mục dốc 12-15 độ có lan can gỗ, trạm nghỉ chân và vòi nước nguồn.",
		"category": "TRANSIT"
	}
]

# ------------------------------------------------------------------------------
# TRUY VẤN DỮ LIỆU ĐỊA DANH (QUERY API)
# ------------------------------------------------------------------------------

static func get_all_pois() -> Array[Dictionary]:
	return POI_REGISTRY

static func get_poi_by_id(p_id: int) -> Dictionary:
	for poi in POI_REGISTRY:
		if poi["id"] == p_id:
			return poi
	return {}

static func get_poi_by_key(p_key: String) -> Dictionary:
	for poi in POI_REGISTRY:
		if poi["key"] == p_key:
			return poi
	return {}

static func get_pois_by_district(p_district: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for poi in POI_REGISTRY:
		if poi["district"] == p_district:
			result.append(poi)
	return result

static func get_nearest_poi(current_pos: Vector3) -> Dictionary:
	var nearest: Dictionary = {}
	var min_dist: float = INF
	
	for poi in POI_REGISTRY:
		var dist = current_pos.distance_to(poi["godot_pos"])
		if dist < min_dist:
			min_dist = dist
			nearest = poi
			
	return nearest

static func get_distance_to_poi(current_pos: Vector3, poi_id: int) -> float:
	var poi = get_poi_by_id(poi_id)
	if poi.is_empty():
		return -1.0
	return current_pos.distance_to(poi["godot_pos"])

# ------------------------------------------------------------------------------
# MÔ PHỎNG THỦY VĂN & LƯU LƯỢNG (HYDROLOGY SIMULATION MODEL)
# ------------------------------------------------------------------------------

static func calculate_hydrology_stats(rainfall_mm_per_year: float = 1350.0, runoff_coeff: float = 0.60) -> Dictionary:
	# Lưu vực ngọn núi: 700 km² = 700 * 1,000,000 m²
	var basin_area_m2: float = 700.0 * 1_000_000.0
	var rainfall_m: float = rainfall_mm_per_year / 1000.0
	
	# Tổng thể tích nước mưa hàng năm (m³)
	var total_annual_water_m3: float = basin_area_m2 * rainfall_m
	
	# Lượng nước chảy tràn ra suối và thác (m³/năm)
	var total_runoff_water_m3: float = total_annual_water_m3 * runoff_coeff
	
	# Lưu lượng trung bình giây (m³/s): 1 năm = 365 * 24 * 3600 = 31,536,000 giây
	var seconds_in_year: float = 31_536_000.0
	var avg_flow_rate_m3_per_s: float = total_runoff_water_m3 / seconds_in_year
	
	# Dự trữ Hồ Đỉnh (50 - 100 triệu m³)
	var reservoir_capacity_m3: float = 75_000_000.0
	
	return {
		"basin_area_km2": 700.0,
		"rainfall_mm_year": rainfall_mm_per_year,
		"total_annual_precipitation_m3": total_annual_water_m3,
		"annual_runoff_m3": total_runoff_water_m3,
		"average_flow_rate_m3_s": snappedf(avg_flow_rate_m3_per_s, 0.1),
		"flood_peak_flow_m3_s": 80.0,
		"dry_season_flow_m3_s": 8.0,
		"summit_reservoir_capacity_m3": reservoir_capacity_m3
	}
