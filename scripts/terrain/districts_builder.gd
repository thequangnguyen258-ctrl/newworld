class_name DistrictsBuilder
extends RefCounted

# ==============================================================================
# DISTRICTS BUILDER - 4 HUYỆN NGOẠI VI TÂN THẾ GIỚI (500 KM²)
# 1. Huyện Đông (X=+10.000m, Z=0m, Cao độ ~+35m): Nông trại cối xay gió & đồng lúa
# 2. Huyện Tây (X=-10.000m, Z=0m, Cao độ ~+45m): Thung lũng kỹ nghệ & quạt gió
# 3. Huyện Bắc (X=0m, Z=-10.000m, Cao độ ~+55m): Rừng đại ngàn, cối xay nước & suối Onsen
# 4. Huyện Nam (X=0m, Z=+20.000m, Cao độ ~+15m): Cảng Hòa Bình, ngọn hải đăng & chợ phiên
# ==============================================================================

const NPCCharacterScript = preload("res://scripts/characters/npc_character.gd")
const InteractiveStationScript = preload("res://scripts/interactive/interactive_station.gd")
const MayorBuggyScript = preload("res://scripts/interactive/mayor_buggy.gd")
const ModularHumanoidBuilderScript = preload("res://scripts/characters/modular_humanoid_builder.gd")

# Script xoay cánh quạt gió / cối xay
class RotatingRotor extends Node3D:
	var rotation_axis: Vector3 = Vector3(0, 0, 1)
	var speed: float = 1.2
	func _process(delta: float) -> void:
		rotate(rotation_axis, speed * delta)

# ------------------------------------------------------------------------------
# 1. HUYỆN ĐÔNG - VỰA NÔNG TRẠI & THẢO NGUYÊN (X = +10.000m, Z = 0m)
# ------------------------------------------------------------------------------
static func build_east_district() -> Node3D:
	var root = Node3D.new()
	root.name = "EastAgriculturalDistrict"

	var ground_y = ModularNatureChunk.get_world_height(10000.0, 0.0)
	root.position = Vector3(10000.0, ground_y, 0.0)

	# Vật liệu
	var mat_stone = _create_material(Color(0.76, 0.74, 0.68))
	var mat_wood_dark = _create_material(Color(0.42, 0.28, 0.18))
	var mat_barn_red = _create_material(Color(0.72, 0.22, 0.18))
	var mat_roof_straw = _create_material(Color(0.82, 0.68, 0.35))
	var mat_silo = _create_material(Color(0.85, 0.88, 0.90), 0.7, 0.3)
	var mat_wheat = _create_material(Color(0.92, 0.78, 0.22))

	# 1. Sàn quảng trường làng nông trang (R = 22m)
	var plaza = _create_box_collider("VillageSquarePlaza", Vector3(44.0, 0.4, 44.0), mat_stone)
	plaza.position.y = 0.2
	root.add_child(plaza)

	# Bảng chỉ dẫn Huyện Đông
	var sign_node = _create_district_sign("🌾 HUYỆN ĐÔNG - VỰA NÔNG TRANG & THẢO NGUYÊN", "Cự ly: 10km phía Đông | Cao độ: +35m | Nông nghiệp hữu cơ")
	sign_node.position = Vector3(0.0, 3.2, -18.0)
	root.add_child(sign_node)

	# 2. Hai Cối Xay Gió Anime khổng lồ (Windmills cao 16m)
	var wm1 = _create_windmill(mat_stone, mat_roof_straw, mat_wood_dark, 1.2)
	wm1.position = Vector3(-16.0, 0.0, -12.0)
	root.add_child(wm1)

	var wm2 = _create_windmill(mat_stone, mat_roof_straw, mat_wood_dark, 0.9)
	wm2.position = Vector3(-20.0, 0.0, 14.0)
	root.add_child(wm2)

	# 3. Nhà kho thóc & nông trại mái đỏ (Grand Barn 18m x 12m x 8m)
	var barn = _create_barn(mat_barn_red, mat_roof_straw, mat_wood_dark)
	barn.position = Vector3(16.0, 0.0, -10.0)
	root.add_child(barn)

	# 4. Tháp Silo trữ hạt giống (Cao 14m, R=3m)
	var silo = _create_cylinder_collider("GrainSilo", 3.2, 14.0, mat_silo)
	silo.position = Vector3(28.0, 7.0, -10.0)
	root.add_child(silo)

	var silo_cap = MeshInstance3D.new()
	var cap_cone = CylinderMesh.new()
	cap_cone.top_radius = 0.0
	cap_cone.bottom_radius = 3.5
	cap_cone.height = 2.2
	silo_cap.mesh = cap_cone
	silo_cap.material_override = mat_silo
	silo_cap.position = Vector3(28.0, 15.1, -10.0)
	root.add_child(silo_cap)

	# 5. Các luống lúa mạch vàng ươm & hàng rào gỗ
	for f in range(3):
		var wheat_field = _create_wheat_field(Vector3(14.0, 0.3, 10.0 + float(f) * 12.0), mat_wheat, mat_wood_dark)
		root.add_child(wheat_field)

	# 6. Sân đỗ Trực thăng Helipad nông thôn
	var helipad = _create_helipad_station("HelipadEast", Vector3(0.0, 0.25, 16.0))
	root.add_child(helipad)

	# 7. Cư dân cốt lõi: Bác Hai (Nông Dân Sinh Thái)
	var npc_hai = NPCCharacterScript.new()
	npc_hai.name = "NPC_FarmerHai"
	npc_hai.npc_id = "farmer_hai"
	npc_hai.citizen_name = "Bác Hai"
	npc_hai.age = 56
	npc_hai.age_group = ModularHumanoidBuilderScript.AgeGroup.ELDER
	npc_hai.gender = "Nam"
	npc_hai.profession = ModularHumanoidBuilderScript.ProfessionType.FARMER
	npc_hai.job_title = "Trưởng Thôn Nông Trang Huyện Đông"
	npc_hai.cert_code = "CERT_AGRI_CROPS"
	npc_hai.skill_level = 9
	npc_hai.cccd_number = "TTG-2026-0082"
	npc_hai.district_name = "Huyện Đông (Nông Trang)"
	npc_hai.position = Vector3(10.0, 0.2, 4.0)
	root.add_child(npc_hai)

	# 8. Trạm Tiếp Tế Lúa Mì Hữu Cơ
	var st_wheat = InteractiveStationScript.new()
	st_wheat.name = "StationEastWheat"
	st_wheat.station_type = InteractiveStationScript.StationType.EAST_WHEAT
	st_wheat.station_id = "east_wheat_station"
	st_wheat.title_name = "Trạm Lúa Mì Hữu Cơ Huyện Đông"
	st_wheat.prompt_text = "🌾 [E] Thu Thập Bao Lúa Mì Hữu Cơ (Tiếp Tế Tiệm Bác Nam)"
	st_wheat.position = Vector3(12.0, 0.2, 4.0)
	root.add_child(st_wheat)

	# 9. Xe Buggy Điện Tuần Tra Huyện Đông
	var buggy_east = MayorBuggyScript.new()
	buggy_east.name = "MayorBuggyEast"
	buggy_east.position = Vector3(-6.0, 0.3, 14.0)
	root.add_child(buggy_east)

	# 10. EXP-01: Tòa Trụ Sở Vệ Tinh Huyện Đông (4 tầng Tân Cổ Điển)
	_build_district_satellite_hub(root, Vector3(0.0, 0.0, -32.0), "Huyện Đông - Nông Trang & Thảo Nguyên", Color(0.92, 0.78, 0.22))

	return root

# ------------------------------------------------------------------------------
# 2. HUYỆN TÂY - KỸ NGHỆ & NĂNG LƯỢNG SẠCH (X = -10.000m, Z = 0m)
# ------------------------------------------------------------------------------
static func build_west_district() -> Node3D:
	var root = Node3D.new()
	root.name = "WestIndustrialDistrict"

	var ground_y = ModularNatureChunk.get_world_height(-10000.0, 0.0)
	root.position = Vector3(-10000.0, ground_y, 0.0)

	var mat_tech_floor = _create_material(Color(0.25, 0.28, 0.34))
	var mat_white = _create_material(Color(0.92, 0.94, 0.96))
	var mat_solar = _create_material(Color(0.12, 0.35, 0.72), 0.5, 0.1)
	var mat_metal_dark = _create_material(Color(0.20, 0.22, 0.26), 0.8, 0.3)
	var mat_glow_cyan = _create_glow_material(Color(0.2, 0.8, 1.0), 3.0)

	# 1. Sàn quảng trường công nghệ (46m x 46m)
	var plaza = _create_box_collider("TechPlaza", Vector3(46.0, 0.4, 46.0), mat_tech_floor)
	plaza.position.y = 0.2
	root.add_child(plaza)

	# Bảng chỉ dẫn Huyện Tây
	var sign_node = _create_district_sign("⚙️ HUYỆN TÂY - KỸ NGHỆ & NĂNG LƯỢNG SẠCH", "Cự ly: 10km phía Tây | Cao độ: +45m | Năng lượng tái tạo & Cơ khí")
	sign_node.position = Vector3(0.0, 3.2, -18.0)
	root.add_child(sign_node)

	# 2. 3 Trụ Quạt Gió Năng Lượng Sạch khổng lồ (Cao 28m)
	var turbine_positions = [
		Vector3(-18.0, 0.0, -15.0),
		Vector3(-24.0, 0.0, 10.0),
		Vector3(22.0, 0.0, -18.0)
	]
	for idx in range(turbine_positions.size()):
		var turb = _create_wind_turbine(mat_white, 0.8 + float(idx) * 0.25)
		turb.position = turbine_positions[idx]
		root.add_child(turb)

	# 3. Nhà xưởng chế tác & Robot thông minh (Hangar 24m x 16m x 9m)
	var hangar = _create_tech_hangar(mat_white, mat_solar, mat_metal_dark)
	hangar.position = Vector3(14.0, 0.0, 8.0)
	root.add_child(hangar)

	# 4. Trạm Sạc Nhanh Xe Điện & Tháp Pin Lưu Trữ
	var charging_station = _create_charging_hub(mat_metal_dark, mat_glow_cyan)
	charging_station.position = Vector3(-8.0, 0.0, 15.0)
	root.add_child(charging_station)

	# 5. Sân đỗ Trực thăng Helipad kỹ nghệ
	var helipad = _create_helipad_station("HelipadWest", Vector3(0.0, 0.25, 0.0))
	root.add_child(helipad)

	# 6. Cư dân cốt lõi: Kỹ Sư Khoa (Kỹ Nghệ & Năng Lượng)
	var npc_khoa = NPCCharacterScript.new()
	npc_khoa.name = "NPC_EngineerKhoa"
	npc_khoa.npc_id = "engineer_khoa"
	npc_khoa.citizen_name = "Kỹ Sư Khoa"
	npc_khoa.age = 24
	npc_khoa.age_group = ModularHumanoidBuilderScript.AgeGroup.ADULT
	npc_khoa.gender = "Nam"
	npc_khoa.profession = ModularHumanoidBuilderScript.ProfessionType.ENGINEER
	npc_khoa.job_title = "Trưởng Trạm Năng Lượng Huyện Tây"
	npc_khoa.cert_code = "CERT_POWER_GRID"
	npc_khoa.skill_level = 9
	npc_khoa.cccd_number = "TTG-2026-0104"
	npc_khoa.district_name = "Huyện Tây (Kỹ Nghệ Gió)"
	npc_khoa.position = Vector3(-8.0, 0.2, 12.0)
	root.add_child(npc_khoa)

	# 7. Trạm Sạc & Pin Năng Lượng Mặt Trời Huyện Tây
	var st_solar = InteractiveStationScript.new()
	st_solar.name = "StationWestSolar"
	st_solar.station_type = InteractiveStationScript.StationType.WEST_POWER
	st_solar.station_id = "west_solar_station"
	st_solar.title_name = "Trạm Pin Năng Lượng Mặt Trời Huyện Tây"
	st_solar.prompt_text = "⚡ [E] Kiểm Tra & Tích Pin Năng Lượng Sạch (Cấp Điện Cho Thủ Phủ)"
	st_solar.position = Vector3(-6.0, 0.2, 12.0)
	root.add_child(st_solar)

	# 8. Xe Buggy Điện Tuần Tra Huyện Tây
	var buggy_west = MayorBuggyScript.new()
	buggy_west.name = "MayorBuggyWest"
	buggy_west.position = Vector3(8.0, 0.3, 12.0)
	root.add_child(buggy_west)

	# 9. EXP-01: Tòa Trụ Sở Vệ Tinh Huyện Tây (4 tầng Tân Cổ Điển)
	_build_district_satellite_hub(root, Vector3(0.0, 0.0, -32.0), "Huyện Tây - Kỹ Nghệ & Năng Lượng", Color(0.3, 0.65, 0.85))

	return root

# ------------------------------------------------------------------------------
# 3. HUYỆN BẮC - ĐẠI NGÀN & SUỐI KHOÁNG ONSEN (X = 0m, Z = -10.000m)
# ------------------------------------------------------------------------------
static func build_north_district() -> Node3D:
	var root = Node3D.new()
	root.name = "NorthForestDistrict"

	var ground_y = ModularNatureChunk.get_world_height(0.0, -10000.0)
	root.position = Vector3(0.0, ground_y, -10000.0)

	var mat_river_stone = _create_material(Color(0.55, 0.52, 0.48))
	var mat_log = _create_material(Color(0.38, 0.25, 0.15))
	var mat_roof_cedar = _create_material(Color(0.24, 0.32, 0.22))
	var mat_onsen_water = _create_material(Color(0.30, 0.85, 0.88, 0.8), 0.1, 0.05)
	mat_onsen_water.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var mat_lantern = _create_glow_material(Color(1.0, 0.65, 0.2), 3.0)

	# 1. Sàn gỗ & đá cuội làng rừng (44m x 44m)
	var plaza = _create_box_collider("ForestPlaza", Vector3(44.0, 0.4, 44.0), mat_river_stone)
	plaza.position.y = 0.2
	root.add_child(plaza)

	# Bảng chỉ dẫn Huyện Bắc
	var sign_node = _create_district_sign("🌲 HUYỆN BẮC - ĐẠI NGÀN & SUỐI KHOÁNG ONSEN", "Cự ly: 10km phía Bắc | Cao độ: +55m | Lâm nghiệp sinh thái & Dưỡng sinh")
	sign_node.position = Vector3(0.0, 3.2, 18.0)
	root.add_child(sign_node)

	# 2. Xưởng cưa & Cối Xay Nước Gỗ cổ điển (Water Wheel R=4m)
	var mill = _create_watermill(mat_log, mat_roof_cedar)
	mill.position = Vector3(-16.0, 0.0, -8.0)
	root.add_child(mill)

	# 3. Hồ Suối Khoáng Nóng Onsen (R=6m) bốc khói dưỡng sinh
	var onsen = _create_onsen_bath(mat_river_stone, mat_onsen_water, mat_log, mat_lantern)
	onsen.position = Vector3(16.0, 0.0, -6.0)
	root.add_child(onsen)

	# 4. Tháp quan sát kiểm lâm (Cao 16m)
	var watchtower = _create_watchtower(mat_log, mat_roof_cedar)
	watchtower.position = Vector3(18.0, 0.0, 14.0)
	root.add_child(watchtower)

	# 5. Sân đỗ Trực thăng Helipad lâm nghiệp
	var helipad = _create_helipad_station("HelipadNorth", Vector3(0.0, 0.25, 0.0))
	root.add_child(helipad)

	# 6. Cư dân cốt lõi: Thợ Rừng Lâm (Kiểm Lâm & Onsen)
	var npc_lam = NPCCharacterScript.new()
	npc_lam.name = "NPC_RangerLam"
	npc_lam.npc_id = "ranger_lam"
	npc_lam.citizen_name = "Thợ Rừng Lâm"
	npc_lam.age = 33
	npc_lam.age_group = ModularHumanoidBuilderScript.AgeGroup.ADULT
	npc_lam.gender = "Nam"
	npc_lam.profession = ModularHumanoidBuilderScript.ProfessionType.CARPENTER
	npc_lam.job_title = "Kiểm Lâm & Quản Lý Onsen Huyện Bắc"
	npc_lam.cert_code = "CERT_CARPENTRY"
	npc_lam.skill_level = 9
	npc_lam.cccd_number = "TTG-2026-0063"
	npc_lam.district_name = "Huyện Bắc (Đại Ngàn & Onsen)"
	npc_lam.position = Vector3(12.0, 0.2, -6.0)
	root.add_child(npc_lam)

	# 7. Trạm Suối Khoáng Nóng Onsen & Thảo Dược
	var st_onsen = InteractiveStationScript.new()
	st_onsen.name = "StationNorthOnsen"
	st_onsen.station_type = InteractiveStationScript.StationType.NORTH_HERB
	st_onsen.station_id = "north_onsen_station"
	st_onsen.title_name = "Suối Khoáng Nóng Onsen & Thảo Dược Huyện Bắc"
	st_onsen.prompt_text = "♨️ [E] Thu Hái Thảo Dược Suối Khoáng Onsen (Tiếp Tế Trạm Xá Chị Mai)"
	st_onsen.position = Vector3(14.0, 0.2, -6.0)
	root.add_child(st_onsen)

	# 8. Xe Buggy Điện Tuần Tra Huyện Bắc
	var buggy_north = MayorBuggyScript.new()
	buggy_north.name = "MayorBuggyNorth"
	buggy_north.position = Vector3(-8.0, 0.3, 10.0)
	root.add_child(buggy_north)

	# 9. EXP-01: Tòa Trụ Sở Vệ Tinh Huyện Bắc (4 tầng Tân Cổ Điển)
	_build_district_satellite_hub(root, Vector3(0.0, 0.0, -32.0), "Huyện Bắc - Đại Ngàn & Onsen", Color(0.2, 0.6, 0.35))

	return root

# ------------------------------------------------------------------------------
# 4. HUYỆN NAM - CẢNG HÒA BÌNH QUỐC TẾ (X = 0m, Z = +20.000m)
# ------------------------------------------------------------------------------
static func build_south_district() -> Node3D:
	var root = Node3D.new()
	root.name = "SouthPeacePortDistrict"

	var ground_y = ModularNatureChunk.get_world_height(0.0, 20000.0)
	root.position = Vector3(0.0, ground_y, 20000.0)

	var mat_pier_wood = _create_material(Color(0.48, 0.36, 0.25))
	var mat_white = _create_material(Color(0.95, 0.95, 0.95))
	var mat_red = _create_material(Color(0.85, 0.20, 0.18))
	var mat_lantern = _create_glow_material(Color(1.0, 0.95, 0.4), 4.0)
	var mat_bazaar_1 = _create_material(Color(0.9, 0.2, 0.2))
	var mat_bazaar_2 = _create_material(Color(0.2, 0.4, 0.9))
	var mat_bazaar_3 = _create_material(Color(0.9, 0.75, 0.1))

	# 1. Sàn cầu cảng gỗ duyên hải (48m x 32m)
	var plaza = _create_box_collider("PortPlaza", Vector3(48.0, 0.4, 32.0), mat_pier_wood)
	plaza.position = Vector3(0.0, 0.2, -10.0)
	root.add_child(plaza)

	# Bảng chỉ dẫn Huyện Nam
	var sign_node = _create_district_sign("⚓ HUYỆN NAM - CẢNG HÒA BÌNH QUỐC TẾ", "Cự ly: 20km phía Nam | Cao độ: +15m | Cửa ngõ giao thương & Duyên hải")
	sign_node.position = Vector3(0.0, 3.2, -22.0)
	root.add_child(sign_node)

	# 2. Đại Hải Đăng Duyên Hải cao 26m (Lighthouse Tower)
	var lighthouse = _create_lighthouse(mat_white, mat_red, mat_lantern)
	lighthouse.position = Vector3(-20.0, 0.0, -8.0)
	root.add_child(lighthouse)

	# 3. Cầu tàu gỗ vươn dài ra biển (Long Pier 60m x 8m)
	var pier = _create_box_collider("LongHarborPier", Vector3(8.0, 0.5, 60.0), mat_pier_wood)
	pier.position = Vector3(0.0, 0.25, 26.0)
	root.add_child(pier)

	# 4. Hai Thuyền buồm cập bến (Moored Trading Boats)
	var boat1 = _create_boat(mat_pier_wood, mat_white)
	boat1.position = Vector3(9.0, -0.4, 20.0)
	boat1.rotation.y = deg_to_rad(-15.0)
	root.add_child(boat1)

	var boat2 = _create_boat(mat_pier_wood, mat_white)
	boat2.position = Vector3(-9.0, -0.4, 38.0)
	boat2.rotation.y = deg_to_rad(12.0)
	root.add_child(boat2)

	# 5. Dãy 4 Gian Hàng Chợ Phiên Duyên Hải (Bazaar Stalls)
	var mats_awning = [mat_bazaar_1, mat_bazaar_2, mat_bazaar_3, mat_bazaar_1]
	for s in range(4):
		var stall = _create_market_stall(mats_awning[s], mat_pier_wood)
		stall.position = Vector3(14.0 + float(s) * 4.5, 0.0, -10.0)
		root.add_child(stall)

	# 6. Sân đỗ Trực thăng Helipad duyên hải
	var helipad = _create_helipad_station("HelipadSouth", Vector3(-6.0, 0.25, -8.0))
	root.add_child(helipad)

	# 7. Cư dân cốt lõi: Thuyền Trưởng Hải (Cảng Trưởng)
	var npc_hai = NPCCharacterScript.new()
	npc_hai.name = "NPC_CaptainHai"
	npc_hai.npc_id = "captain_hai"
	npc_hai.citizen_name = "Thuyền Trưởng Hải"
	npc_hai.age = 45
	npc_hai.age_group = ModularHumanoidBuilderScript.AgeGroup.ELDER
	npc_hai.gender = "Nam"
	npc_hai.profession = ModularHumanoidBuilderScript.ProfessionType.CARPENTER
	npc_hai.job_title = "Cảng Trưởng Cảng Hòa Bình Huyện Nam"
	npc_hai.cert_code = "CERT_CIVIC_ADMIN"
	npc_hai.skill_level = 9
	npc_hai.cccd_number = "TTG-2026-0012"
	npc_hai.district_name = "Huyện Nam (Cảng Hòa Bình)"
	npc_hai.position = Vector3(2.0, 0.2, 22.0)
	root.add_child(npc_hai)

	# 8. Trạm Cầu Cảng Hòa Bình & Tiếp Nhận Hải Sản
	var st_harbor = InteractiveStationScript.new()
	st_harbor.name = "StationSouthHarbor"
	st_harbor.station_type = InteractiveStationScript.StationType.SOUTH_PORT
	st_harbor.station_id = "south_harbor_station"
	st_harbor.title_name = "Cầu Cảng Hòa Bình & Tiếp Nhận Hải Sản Huyện Nam"
	st_harbor.prompt_text = "🐟 [E] Đón Tàu Cá & Nhận Thùng Hải Sản Tươi (Cho Đại Tiệc Agape)"
	st_harbor.position = Vector3(4.0, 0.2, 22.0)
	root.add_child(st_harbor)

	# 9. Xe Buggy Điện Tuần Tra Huyện Nam
	var buggy_south = MayorBuggyScript.new()
	buggy_south.name = "MayorBuggySouth"
	buggy_south.position = Vector3(-12.0, 0.3, -12.0)
	root.add_child(buggy_south)

	# 10. EXP-01: Tòa Trụ Sở Vệ Tinh Huyện Nam (4 tầng Tân Cổ Điển)
	_build_district_satellite_hub(root, Vector3(-25.0, 0.0, -25.0), "Huyện Nam - Cảng Hòa Bình", Color(0.2, 0.45, 0.85))

	# 11. EXP-04: Nhà Ga Đón Tàu Lữ Khách & Nhập Cư Cảng Hòa Bình
	var st_ship = InteractiveStationScript.new()
	st_ship.name = "StationPassengerShipTerminal"
	st_ship.station_type = InteractiveStationScript.StationType.SOUTH_PORT
	st_ship.station_id = "passenger_ship_terminal"
	st_ship.title_name = "Nhà Ga Tàu Khách Quốc Tế — Cảng Hòa Bình"
	st_ship.prompt_text = "🚢 [E] Tiếp Nhận Lữ Khách & Cấp Thẻ CCCD Nhập Cư"
	st_ship.interaction_radius = 6.5
	st_ship.position = Vector3(0.0, 0.3, 50.0)
	root.add_child(st_ship)

	return root

# ------------------------------------------------------------------------------
# CÁC HÀM HELPER SINH HÌNH HỌC VÀ VẬT THỂ
# ------------------------------------------------------------------------------

## EXP-01: Tòa Trụ Sở Vệ Tinh & Hội Trường Huyện (4 tầng Tân Cổ Điển)
static func _build_district_satellite_hub(parent: Node3D, pos: Vector3, hub_title: String, theme_color: Color) -> Node3D:
	var hub = Node3D.new()
	hub.name = "SatelliteHub_" + hub_title.substr(0, 12).replace(" ", "_").replace("-", "_")
	hub.position = pos
	parent.add_child(hub)

	var body_mat = _create_material(Color(0.95, 0.93, 0.88), 0.1, 0.7)
	var roof_mat = _create_material(theme_color, 0.15, 0.45)
	var glass_mat = _create_material(Color(0.55, 0.78, 0.95, 0.75), 0.3, 0.15)
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	# Thân tòa nhà 4 tầng (22m rộng x 16m cao x 16m sâu)
	var body = _create_box_collider("HubMainBuilding", Vector3(22.0, 16.0, 16.0), body_mat)
	body.position.y = 8.0
	hub.add_child(body)

	# Mái vòm tân cổ điển
	var roof = _create_box_collider("HubRoof", Vector3(23.6, 1.2, 17.6), roof_mat)
	roof.position.y = 16.6
	hub.add_child(roof)

	# Dãy cửa kính 4 tầng mặt trước & mặt sau
	for fl in range(4):
		var fy: float = 2.2 + float(fl) * 3.8
		for wx in [-7.5, -2.5, 2.5, 7.5]:
			var front_win = _create_box_collider("WinF_%d_%d" % [fl, int(wx)], Vector3(3.2, 2.2, 0.2), glass_mat)
			front_win.position = Vector3(wx, fy, 8.05)
			hub.add_child(front_win)
			var back_win = _create_box_collider("WinB_%d_%d" % [fl, int(wx)], Vector3(3.2, 2.2, 0.2), glass_mat)
			back_win.position = Vector3(wx, fy, -8.05)
			hub.add_child(back_win)

	# Biển hiệu Diegetic 3D phía trước Tòa Vệ Tinh
	var sign_lbl = Label3D.new()
	sign_lbl.text = "🏛️ TÒA VỆ TINH & HỘI TRƯỜNG\n" + hub_title.to_upper()
	sign_lbl.font_size = 38
	sign_lbl.modulate = Color(1.0, 0.92, 0.45)
	sign_lbl.outline_size = 10
	sign_lbl.position = Vector3(0, 18.8, 8.2)
	sign_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign_lbl.no_depth_test = true
	hub.add_child(sign_lbl)

	# Trạm tương tác Quầy Hành Chính & Hội Trường Vệ Tinh ở sảnh chính
	var st = InteractiveStationScript.new()
	st.name = "StationSatelliteHub_" + hub_title.substr(0, 10).replace(" ", "_")
	st.station_type = InteractiveStationScript.StationType.DESK
	st.station_id = "satellite_hub_" + hub_title.to_lower().substr(0, 10).replace(" ", "_")
	st.title_name = "Tòa Hành Chính & Hội Trường Vệ Tinh — " + hub_title
	st.prompt_text = "⚡ [E] Làm Việc & Dự Lễ Tại Tòa Vệ Tinh " + hub_title
	st.interaction_radius = 6.5
	st.position = Vector3(0, 0.5, 10.5)
	hub.add_child(st)

	return hub

static func _create_windmill(mat_stone: Material, mat_roof: Material, mat_wood: Material, speed: float) -> Node3D:
	var root = Node3D.new()
	root.name = "AnimeWindmill"

	# Tháp trụ bát giác cao 14m
	var tower = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 2.4
	cyl.bottom_radius = 3.6
	cyl.height = 14.0
	tower.mesh = cyl
	tower.material_override = mat_stone
	tower.position.y = 7.0
	root.add_child(tower)

	# Mái chóp cối xay
	var roof = MeshInstance3D.new()
	var cone = CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 2.8
	cone.height = 3.5
	roof.mesh = cone
	roof.material_override = mat_roof
	roof.position.y = 15.5
	root.add_child(roof)

	# Trục quay cánh quạt
	var rotor = RotatingRotor.new()
	rotor.name = "WindmillRotor"
	rotor.position = Vector3(0.0, 13.5, 2.6)
	rotor.rotation_axis = Vector3(0, 0, 1)
	rotor.speed = speed
	root.add_child(rotor)

	# 4 Cánh cối xay gỗ
	for i in range(4):
		var blade = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(0.8, 7.5, 0.08)
		blade.mesh = box
		blade.material_override = mat_wood
		blade.position = Vector3(0.0, 3.8, 0.0)
		blade.rotation.z = deg_to_rad(float(i) * 90.0)
		rotor.add_child(blade)

	return root

static func _create_barn(mat_wall: Material, mat_roof: Material, mat_wood: Material) -> Node3D:
	var root = Node3D.new()
	root.name = "TimberBarn"

	# Thân nhà kho (18m x 12m x 7m)
	var wall = _create_box_collider("BarnWall", Vector3(18.0, 7.0, 12.0), mat_wall)
	wall.position.y = 3.5
	root.add_child(wall)

	# Mái tam giác
	var roof = MeshInstance3D.new()
	var prism = PrismMesh.new()
	prism.size = Vector3(19.0, 4.0, 13.0)
	roof.mesh = prism
	roof.material_override = mat_roof
	roof.position.y = 9.0
	root.add_child(roof)

	# Cửa kho gỗ lớn
	var door = MeshInstance3D.new()
	var door_mesh = BoxMesh.new()
	door_mesh.size = Vector3(4.5, 5.0, 0.2)
	door.mesh = door_mesh
	door.material_override = mat_wood
	door.position = Vector3(0.0, 2.5, 6.1)
	root.add_child(door)

	return root

static func _create_wheat_field(pos: Vector3, mat_wheat: Material, mat_wood: Material) -> Node3D:
	var field = Node3D.new()
	field.name = "WheatFieldPatch"
	field.position = pos

	# Luống lúa vàng
	var mesh_inst = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(12.0, 1.2, 8.0)
	mesh_inst.mesh = box
	mesh_inst.material_override = mat_wheat
	mesh_inst.position.y = 0.6
	field.add_child(mesh_inst)

	# Hàng rào gỗ bao quanh
	var fence = MeshInstance3D.new()
	var fence_box = BoxMesh.new()
	fence_box.size = Vector3(12.8, 0.9, 0.15)
	fence.mesh = fence_box
	fence.material_override = mat_wood
	fence.position = Vector3(0.0, 0.45, 4.2)
	field.add_child(fence)

	return field

static func _create_wind_turbine(mat_white: Material, speed: float) -> Node3D:
	var root = Node3D.new()
	root.name = "ModernWindTurbine"

	# Cột tháp cao 26m
	var col = _create_cylinder_collider("TurbineTower", 1.2, 26.0, mat_white)
	col.position.y = 13.0
	root.add_child(col)

	# Đỉnh tháp
	var nacelle = MeshInstance3D.new()
	var n_box = BoxMesh.new()
	n_box.size = Vector3(1.6, 1.8, 4.2)
	nacelle.mesh = n_box
	nacelle.material_override = mat_white
	nacelle.position = Vector3(0.0, 26.0, 0.0)
	root.add_child(nacelle)

	# Rô-tơ 3 cánh quay
	var rotor = RotatingRotor.new()
	rotor.name = "TurbineRotor"
	rotor.position = Vector3(0.0, 26.0, 2.2)
	rotor.rotation_axis = Vector3(0, 0, 1)
	rotor.speed = speed
	root.add_child(rotor)

	# 3 Cánh quạt khí động học dài 11m
	for i in range(3):
		var blade = MeshInstance3D.new()
		var b_box = BoxMesh.new()
		b_box.size = Vector3(0.4, 11.0, 0.08)
		blade.mesh = b_box
		blade.material_override = mat_white
		blade.position = Vector3(0.0, 5.5, 0.0)
		blade.rotation.z = deg_to_rad(float(i) * 120.0)
		rotor.add_child(blade)

	return root

static func _create_tech_hangar(mat_white: Material, mat_solar: Material, mat_dark: Material) -> Node3D:
	var root = Node3D.new()
	root.name = "TechFabricationHangar"

	var body = _create_box_collider("HangarBody", Vector3(24.0, 8.5, 16.0), mat_white)
	body.position.y = 4.25
	root.add_child(body)

	# Mái pin quang điện (Solar Roof)
	var roof = MeshInstance3D.new()
	var r_box = BoxMesh.new()
	r_box.size = Vector3(23.0, 0.4, 15.0)
	roof.mesh = r_box
	roof.material_override = mat_solar
	roof.position.y = 8.7
	root.add_child(roof)

	# Cổng cuốn công nghiệp
	var door = MeshInstance3D.new()
	var d_box = BoxMesh.new()
	d_box.size = Vector3(8.0, 6.0, 0.2)
	door.mesh = d_box
	door.material_override = mat_dark
	door.position = Vector3(0.0, 3.0, 8.1)
	root.add_child(door)

	return root

static func _create_charging_hub(mat_dark: Material, mat_glow: Material) -> Node3D:
	var hub = Node3D.new()
	hub.name = "EVChargingHub"

	for i in range(3):
		var pillar = _create_box_collider("Charger_%d" % i, Vector3(0.8, 2.2, 0.8), mat_dark)
		pillar.position = Vector3(float(i) * 3.0, 1.1, 0.0)
		hub.add_child(pillar)

		var glow = MeshInstance3D.new()
		var g_box = BoxMesh.new()
		g_box.size = Vector3(0.5, 0.3, 0.85)
		glow.mesh = g_box
		glow.material_override = mat_glow
		glow.position = Vector3(float(i) * 3.0, 1.6, 0.0)
		hub.add_child(glow)

	return hub

static func _create_watermill(mat_log: Material, mat_roof: Material) -> Node3D:
	var root = Node3D.new()
	root.name = "HistoricWaterMill"

	var house = _create_box_collider("MillHouse", Vector3(14.0, 6.5, 10.0), mat_log)
	house.position.y = 3.25
	root.add_child(house)

	var roof = MeshInstance3D.new()
	var prism = PrismMesh.new()
	prism.size = Vector3(15.0, 3.5, 11.0)
	roof.mesh = prism
	roof.material_override = mat_roof
	roof.position.y = 8.0
	root.add_child(roof)

	# Bánh xe nước xoay (Water Wheel D=7m)
	var wheel_rotor = RotatingRotor.new()
	wheel_rotor.name = "WaterWheelRotor"
	wheel_rotor.position = Vector3(-7.5, 3.5, 0.0)
	wheel_rotor.rotation_axis = Vector3(1, 0, 0)
	wheel_rotor.speed = 1.0
	root.add_child(wheel_rotor)

	var wheel_cyl = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 3.5
	cyl.bottom_radius = 3.5
	cyl.height = 1.2
	wheel_cyl.mesh = cyl
	wheel_cyl.material_override = mat_log
	wheel_cyl.rotation.z = deg_to_rad(90.0)
	wheel_rotor.add_child(wheel_cyl)

	return root

static func _create_onsen_bath(mat_stone: Material, mat_water: Material, mat_wood: Material, mat_lantern: Material) -> Node3D:
	var root = Node3D.new()
	root.name = "OnsenHotSpringPool"

	# Hồ nước khoáng tròn R=5.5m
	var pool_rim = _create_cylinder_collider("OnsenRim", 5.8, 1.2, mat_stone)
	pool_rim.position.y = 0.6
	root.add_child(pool_rim)

	var water = MeshInstance3D.new()
	var w_cyl = CylinderMesh.new()
	w_cyl.top_radius = 5.2
	w_cyl.bottom_radius = 5.2
	w_cyl.height = 0.2
	water.mesh = w_cyl
	water.material_override = mat_water
	water.position.y = 1.0
	root.add_child(water)

	# Đèn lồng Nhật Bản Toon
	var lantern_post = _create_cylinder_collider("LanternPost", 0.15, 3.2, mat_wood)
	lantern_post.position = Vector3(6.5, 1.6, 0.0)
	root.add_child(lantern_post)

	var lantern_box = MeshInstance3D.new()
	var l_mesh = BoxMesh.new()
	l_mesh.size = Vector3(0.8, 0.9, 0.8)
	lantern_box.mesh = l_mesh
	lantern_box.material_override = mat_lantern
	lantern_box.position = Vector3(6.5, 3.2, 0.0)
	root.add_child(lantern_box)

	return root

static func _create_watchtower(mat_log: Material, mat_roof: Material) -> Node3D:
	var root = Node3D.new()
	root.name = "ForestryWatchtower"

	var legs = _create_box_collider("TowerLegs", Vector3(4.0, 14.0, 4.0), mat_log)
	legs.position.y = 7.0
	root.add_child(legs)

	var cabin = _create_box_collider("TowerCabin", Vector3(5.5, 3.0, 5.5), mat_log)
	cabin.position.y = 15.5
	root.add_child(cabin)

	var roof = MeshInstance3D.new()
	var cone = CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 3.6
	cone.height = 2.4
	roof.mesh = cone
	roof.material_override = mat_roof
	roof.position.y = 18.0
	root.add_child(roof)

	return root

static func _create_lighthouse(mat_white: Material, mat_red: Material, mat_lantern: Material) -> Node3D:
	var root = Node3D.new()
	root.name = "MaritimeLighthouse"

	# Tháp hải đăng sọc trắng đỏ cao 24m
	var lower_tower = _create_cylinder_collider("LighthouseLower", 3.2, 12.0, mat_white)
	lower_tower.position.y = 6.0
	root.add_child(lower_tower)

	var upper_tower = _create_cylinder_collider("LighthouseUpper", 2.4, 12.0, mat_red)
	upper_tower.position.y = 18.0
	root.add_child(upper_tower)

	# Đèn hải đăng phát sáng
	var lamp = MeshInstance3D.new()
	var l_cyl = CylinderMesh.new()
	l_cyl.top_radius = 1.8
	l_cyl.bottom_radius = 2.0
	l_cyl.height = 2.2
	lamp.mesh = l_cyl
	lamp.material_override = mat_lantern
	lamp.position.y = 25.0
	root.add_child(lamp)

	return root

static func _create_boat(mat_wood: Material, mat_sail: Material) -> Node3D:
	var root = Node3D.new()
	root.name = "TradingBoat"

	# Thân thuyền
	var hull = _create_box_collider("BoatHull", Vector3(3.2, 1.4, 8.5), mat_wood)
	hull.position.y = 0.7
	root.add_child(hull)

	# Cột buồm
	var mast = MeshInstance3D.new()
	var m_cyl = CylinderMesh.new()
	m_cyl.top_radius = 0.1
	m_cyl.bottom_radius = 0.15
	m_cyl.height = 7.0
	mast.mesh = m_cyl
	mast.material_override = mat_wood
	mast.position.y = 4.5
	root.add_child(mast)

	# Cánh buồm trắng
	var sail = MeshInstance3D.new()
	var s_prism = PrismMesh.new()
	s_prism.size = Vector3(3.5, 5.0, 0.1)
	sail.mesh = s_prism
	sail.material_override = mat_sail
	sail.position = Vector3(0.0, 5.0, 0.8)
	root.add_child(sail)

	return root

static func _create_market_stall(mat_awning: Material, mat_wood: Material) -> Node3D:
	var root = Node3D.new()
	root.name = "MarketBazaarStall"

	# Bàn bày hàng
	var counter = _create_box_collider("StallCounter", Vector3(3.2, 1.0, 1.8), mat_wood)
	counter.position.y = 0.5
	root.add_child(counter)

	# Mái che bạt màu
	var awning = MeshInstance3D.new()
	var a_prism = PrismMesh.new()
	a_prism.size = Vector3(3.5, 0.8, 2.2)
	awning.mesh = a_prism
	awning.material_override = mat_awning
	awning.position.y = 2.6
	root.add_child(awning)

	return root

static func _create_helipad_station(name_str: String, pos: Vector3) -> Node3D:
	var helipad = Node3D.new()
	helipad.name = name_str
	helipad.position = pos

	var pad_mesh = CylinderMesh.new()
	pad_mesh.top_radius = 7.0
	pad_mesh.bottom_radius = 7.2
	pad_mesh.height = 0.3

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.20, 0.22, 0.25)
	mat.roughness = 0.8

	var inst = MeshInstance3D.new()
	inst.mesh = pad_mesh
	inst.material_override = mat
	helipad.add_child(inst)

	# Chữ H màu vàng
	var label = Label3D.new()
	label.text = "H"
	label.font_size = 180
	label.modulate = Color(1.0, 0.85, 0.2)
	label.rotation.x = deg_to_rad(-90.0)
	label.position.y = 0.2
	helipad.add_child(label)

	return helipad

static func _create_district_sign(title: String, subtitle: String) -> Node3D:
	var sign_node = Node3D.new()
	sign_node.name = "DistrictSignPost"

	# Cổng chào vòm gỗ
	var post_l = _create_box_collider("PostL", Vector3(0.5, 4.2, 0.5), _create_material(Color(0.35, 0.22, 0.14)))
	post_l.position = Vector3(-4.5, 0.0, 0.0)
	sign_node.add_child(post_l)

	var post_r = _create_box_collider("PostR", Vector3(0.5, 4.2, 0.5), _create_material(Color(0.35, 0.22, 0.14)))
	post_r.position = Vector3(4.5, 0.0, 0.0)
	sign_node.add_child(post_r)

	var beam = _create_box_collider("BeamTop", Vector3(9.5, 0.6, 0.6), _create_material(Color(0.35, 0.22, 0.14)))
	beam.position = Vector3(0.0, 2.1, 0.0)
	sign_node.add_child(beam)

	# Bảng chữ 3D Diegetic sáng rõ, no_depth_test
	var lbl = Label3D.new()
	lbl.text = "%s\n%s" % [title, subtitle]
	lbl.font_size = 36
	lbl.modulate = Color(1.0, 0.95, 0.3)
	lbl.outline_size = 10
	lbl.outline_modulate = Color(0.05, 0.05, 0.08)
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.no_depth_test = true
	lbl.position = Vector3(0.0, 1.8, 0.0)
	sign_node.add_child(lbl)

	return sign_node

static func _create_material(col: Color, metallic: float = 0.0, roughness: float = 0.6) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = col
	mat.metallic = metallic
	mat.roughness = roughness
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	return mat

static func _create_glow_material(col: Color, energy: float) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = energy
	return mat

static func _create_box_collider(node_name: String, size_vec: Vector3, mat: Material) -> StaticBody3D:
	var body = StaticBody3D.new()
	body.name = node_name

	var mi = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = size_vec
	mi.mesh = box
	mi.material_override = mat
	body.add_child(mi)

	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = size_vec
	col.shape = shape
	body.add_child(col)

	return body

static func _create_cylinder_collider(node_name: String, radius: float, height: float, mat: Material) -> StaticBody3D:
	var body = StaticBody3D.new()
	body.name = node_name

	var mi = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = height
	mi.mesh = cyl
	mi.material_override = mat
	body.add_child(mi)

	var col = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = radius
	shape.height = height
	col.shape = shape
	body.add_child(col)

	return body
