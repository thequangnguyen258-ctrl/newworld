class_name MegaOfficeSkyscraperBuilder
extends RefCounted

# ==============================================================================
# MEGA-OFFICE SKYSCRAPER BUILDER - 15 TẦNG, FOOTPRINT 322M X 322M
# Tọa độ trung tâm: (X=0, Z=0) sừng sững tại lõi Đỉnh Vát theo Master Concept.
# 1. Toàn bộ 15 tầng cùng hiện diện và vận hành đồng thời 100% trong thế giới 3D.
# 2. Vườn Treo Trên Không (Sky Gardens) gián đoạn gián cấp ở Tầng 4, 8, 12.
# 3. Trái tim Đại Hội Trường Mái Vòm Giếng Trời 15.000 Chỗ (Mega-Auditorium Arena)
#    tại Tầng 10-12: Bục giảng mạ vàng Đấng Chăn Chiên, Đại Phong Cầm 14m, Bàn Thánh Lễ.
# 4. Sảnh Tầng 1 Ga Tram Trung Tâm & Grand Civic Atrium đón trả khách.
# 5. Bốn thang máy kính đi từ B4 đến Tầng 15 + cầu thang bộ thông suốt.
# ==============================================================================

const ModularHumanoidBuilderScript = preload("res://scripts/characters/modular_humanoid_builder.gd")
const SkyscraperElevatorScript = preload("res://scripts/elevator/elevator.gd")
const StairwellDoorScene: PackedScene = preload("res://scenes/structures/door_portal.tscn")
const MayorOfficeStorageScript = preload("res://scripts/interactive/mayor_office_storage.gd")
const WardrobeOutfitChangerScript = preload("res://scripts/interactive/wardrobe_outfit_changer.gd")

const FOOTPRINT_LINEAR_SCALE: float = 8.94427191
const ELEVATOR_BANK_WORLD_Z: float = 140.0
const ELEVATOR_X_POSITIONS: Array[float] = [-11.0, -3.7, 3.7, 11.0]
const STAIRWELL_WORLD_X_POSITIONS: Array[float] = [-135.0, 123.0]
const STAIRWELL_WORLD_Z: float = 140.0

const FLOOR_HEIGHTS: Array[float] = [
	0.0,    # 1: Sảnh Atrium
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

const BASEMENT_HEIGHTS: Array[float] = [-10.0, -20.0, -30.0, -40.0]

static func build_mega_skyscraper() -> Node3D:
	var skyscraper = Node3D.new()
	skyscraper.name = "MegaOfficeSkyscraper"
	skyscraper.scale = Vector3(FOOTPRINT_LINEAR_SCALE, 1.0, FOOTPRINT_LINEAR_SCALE)
	skyscraper.position = Vector3(0.0, 0.0, 0.0)

	# --------------------------------------------------------------------------
	# HỆ VẬT LIỆU TOON CEL-SHADED CAO CẤP (GHIBLI / MAKOTO SHINKAI PALETTE)
	# --------------------------------------------------------------------------
	var mat_white = _create_material(Color(0.95, 0.97, 1.0), 0.35)
	var mat_border = _create_material(Color(0.26, 0.31, 0.38), 0.5)
	var mat_glass = _create_glass_material(Color(0.18, 0.65, 0.94, 0.68))
	var mat_corridor_glass = _create_glass_material(Color(0.78, 0.91, 0.96, 0.38))
	var mat_corridor_frame = _create_metal_material(Color(0.58, 0.65, 0.71), 0.78, 0.24)
	var mat_corridor_floor = _create_material(Color(0.72, 0.77, 0.81), 0.3)
	var mat_gold = _create_metal_material(Color(0.96, 0.80, 0.20), 0.85, 0.18)
	var mat_holo = _create_emission_material(Color(0.15, 0.85, 0.95, 0.85), Color(0.2, 0.9, 1.0), 3.5)
	var mat_wood = _create_material(Color(0.45, 0.28, 0.16), 0.65)
	var mat_carpet = _create_material(Color(0.12, 0.28, 0.65), 0.9)
	var mat_carpet_red = _create_material(Color(0.62, 0.15, 0.18), 0.88)
	var mat_granite_dark = _create_material(Color(0.14, 0.16, 0.20), 0.4)
	var mat_foliage = _create_material(Color(0.22, 0.65, 0.28), 0.85)

	# --------------------------------------------------------------------------
	# KHUNG KẾT CẤU NGOẠI THẤT (FOOTPRINT GẤP 20 LẦN, CAO 135M)
	# --------------------------------------------------------------------------
	# 4 Trụ góc mạ vàng vươn thẳng lên đỉnh tháp
	for cx in [-18.0, 18.0]:
		for cz in [-18.0, 18.0]:
			var pillar = MeshInstance3D.new()
			var p_cyl = CylinderMesh.new()
			p_cyl.top_radius = 0.5
			p_cyl.bottom_radius = 0.6
			p_cyl.height = 208.0
			pillar.mesh = p_cyl
			pillar.material_override = mat_gold
			pillar.position = Vector3(cx, 104.0, cz)
			skyscraper.add_child(pillar)
			_add_cylinder_col(skyscraper, 0.6, 208.0, Vector3(cx, 104.0, cz))

	# --------------------------------------------------------------------------
	# 1. TẦNG 1: ĐẠI SẢNH GA TRAM TRUNG TÂM & GRAND CIVIC ATRIUM (Y = 0M, CAO 12M)
	# --------------------------------------------------------------------------
	var f1 = _build_floor_slab(skyscraper, 1, 0.0, 12.0, mat_white, mat_border, mat_glass, mat_gold)
	
	# Biển chào mừng mặt tiền phía Nam hướng ra Ga Tram Vành Đai 1
	var arch_sign = _create_label3d("🏢 MEGA OFFICE TÂN THẾ GIỚI (X=0, Z=0)\n[Trụ Sở Chung Thị Trưởng & Người Chăn Chiên • 9 Ban • Đại Hội Trường 15.000 Chỗ]", Color(1.0, 0.88, 0.25), 26)
	arch_sign.name = "MegaOfficeWelcomeSign"
	arch_sign.position = Vector3(0.0, 4.5, 18.2)
	f1.add_child(arch_sign)

	# Quầy Dịch Vụ Công Một Cửa 5 bước
	_add_desk_station(f1, "Quầy Dịch Vụ Công Một Cửa 5 Bước", Vector3(-6.0, 0.0, 6.0), "desk_civic_counter", "Quầy Một Cửa", "📋 [E] Nộp Hồ Sơ Căn Cước & Doanh Nghiệp (Quy Trình 5 Bước)", mat_wood, mat_border, mat_holo)
	
	# Sa Bàn 3D Hologram 500 km²
	var map_table = MeshInstance3D.new()
	var cyl_m = CylinderMesh.new()
	cyl_m.top_radius = 3.6
	cyl_m.bottom_radius = 3.6
	cyl_m.height = 0.8
	map_table.mesh = cyl_m
	map_table.material_override = mat_gold
	map_table.position = Vector3(0.0, 0.4, 0.0)
	f1.add_child(map_table)
	_add_cylinder_col(f1, 3.6, 0.8, Vector3(0.0, 0.4, 0.0))

	var holo_cone = MeshInstance3D.new()
	var c_mesh = CylinderMesh.new()
	c_mesh.top_radius = 0.0
	c_mesh.bottom_radius = 3.2
	c_mesh.height = 2.4
	holo_cone.mesh = c_mesh
	holo_cone.material_override = mat_holo
	holo_cone.position = Vector3(0.0, 1.8, 0.0)
	f1.add_child(holo_cone)

	var st_holo = InteractiveStation.new()
	st_holo.name = "Station_holomap"
	st_holo.station_type = InteractiveStation.StationType.PETITIONS
	st_holo.station_id = "holomap"
	st_holo.title_name = "Sa Bàn 3D Hologram"
	st_holo.prompt_text = "🗺️ [E] Kích Hoạt Sa Bàn 3D Hologram (Đại Thế Giới 500 km²)"
	st_holo.interaction_radius = 6.5
	st_holo.position = Vector3(0.0, 0.4, 2.2)
	f1.add_child(st_holo)

	# NPC Lễ tân & Điều hướng Ga Tram
	_add_worker_npc(f1, "Lễ Tân Mai Anh", Vector3(-6.0, 0.0, 4.2), ModularHumanoidBuilderScript.ProfessionType.STUDENT, "Điều Phối Viên Dịch Vụ Công", "Nữ")
	_add_worker_npc(f1, "Trưởng Ga Tram Việt", Vector3(6.0, 0.0, 6.0), ModularHumanoidBuilderScript.ProfessionType.ENGINEER, "Điều Hành Tuyến Tram Vành Đai 1", "Nam")

	# --------------------------------------------------------------------------
	# CÁC TẦNG 2 - 10: 9 BAN CHUYÊN NGÀNH HÀNH CHÍNH & MỤC VỤ (MỖI TẦNG CAO 8M)
	# --------------------------------------------------------------------------
	# Tầng 2: Ban Nội Vụ & Nhân Sự (+12m)
	var f2 = _build_floor_slab(skyscraper, 2, 12.0, 8.0, mat_carpet, mat_border, mat_glass, mat_gold)
	_add_desk_station(f2, "Bàn Cấp Thẻ Căn Cước Số", Vector3(-6.0, 0.0, 0.0), "desk_hr_registry", "Ban Nội Vụ", "🪪 [E] Sổ Bộ Hộ Tịch & Căn Cước Công Dân", mat_wood, mat_border, mat_holo)
	_add_worker_npc(f2, "Trưởng Ban Nội Vụ Bác Thành", Vector3(-6.0, 0.0, -1.8), ModularHumanoidBuilderScript.ProfessionType.TEACHER, "Trưởng Ban Nội Vụ & Nhân Sự", "Nam")
	_add_worker_npc(f2, "Chuyên Viên Hộ Tịch Lan", Vector3(4.0, 0.0, -1.8), ModularHumanoidBuilderScript.ProfessionType.STUDENT, "Chuyên Viên Hộ Tịch Số", "Nữ")

	# Tầng 3: Ban Tài Chính & Kế Toán - Ngân Hàng Nhà Nước (+20m)
	var f3 = _build_floor_slab(skyscraper, 3, 20.0, 8.0, mat_granite_dark, mat_border, mat_glass, mat_gold)
	_add_desk_station(f3, "Quầy Ngân Hàng Nhà Nước Tự Động", Vector3(-6.0, 0.0, 0.0), "desk_finance_bank", "Ban Tài Chính", "🏦 [E] Ngân Hàng Nhà Nước & Quyền In Tiền Tự Động", mat_wood, mat_gold, mat_holo)
	_add_worker_npc(f3, "Trưởng Ban Tài Chính Minh", Vector3(-6.0, 0.0, -1.8), ModularHumanoidBuilderScript.ProfessionType.TEACHER, "Trưởng Ban Tài Chính & Kế Toán", "Nam")
	_add_worker_npc(f3, "Giao Dịch Viên Ngân Hàng Thảo", Vector3(4.0, 0.0, -1.8), ModularHumanoidBuilderScript.ProfessionType.STUDENT, "Giao Dịch Viên Tài Chính", "Nữ")

	# Tầng 4: Ban Đào Tạo & Kèm Cặp - Học Viện Polytechnic (+28m) + VƯỜN TREO SKY GARDEN ĐÔNG/TÂY
	var f4 = _build_floor_slab(skyscraper, 4, 28.0, 8.0, mat_wood, mat_border, mat_glass, mat_gold)
	_add_desk_station(f4, "Bàn Xét Tuyển Học Bổng Nghề", Vector3(-6.0, 0.0, 0.0), "desk_polytechnic_edu", "Ban Đào Tạo", "🎓 [E] Đăng Ký Học Bổng & Thi Nâng Bậc Chứng Chỉ (CERT)", mat_wood, mat_border, mat_holo)
	_add_worker_npc(f4, "Trưởng Ban Đào Tạo Thầy Dũng", Vector3(-6.0, 0.0, -1.8), ModularHumanoidBuilderScript.ProfessionType.TEACHER, "Hiệu Trưởng Học Viện Bách Khoa", "Nam")
	_add_worker_npc(f4, "Giảng Viên Kèm Cặp Cô Hà", Vector3(4.0, 0.0, -1.8), ModularHumanoidBuilderScript.ProfessionType.DOCTOR, "Giảng Viên Kèm Cặp Nghề", "Nữ")
	_add_sky_garden(f4, Vector3(1.0, 0.0, 0.0), 12.0, 3.2, mat_wood, mat_gold)
	_add_sky_garden(f4, Vector3(-1.0, 0.0, 0.0), 12.0, 3.2, mat_wood, mat_gold)

	# Tầng 5: Ban Kế Hoạch & Chuỗi Cung Ứng SCM (+36m)
	var f5 = _build_floor_slab(skyscraper, 5, 36.0, 8.0, mat_carpet, mat_border, mat_glass, mat_gold)
	_add_desk_station(f5, "Bàn Điều Phối Kho Tài Nguyên Đô Thị", Vector3(-6.0, 0.0, 0.0), "desk_scm_logistics", "Ban Kế Hoạch SCM", "📦 [E] Giám Sát Chuỗi Cung Ứng RAM & Điều Tiết Dịu Dàng", mat_wood, mat_border, mat_holo)
	_add_worker_npc(f5, "Trưởng Ban Kế Hoạch Anh Hoàng", Vector3(-6.0, 0.0, -1.8), ModularHumanoidBuilderScript.ProfessionType.ENGINEER, "Trưởng Ban Kế Hoạch & SCM", "Nam")
	_add_worker_npc(f5, "Điều Phối Viên Kho Trang", Vector3(4.0, 0.0, -1.8), ModularHumanoidBuilderScript.ProfessionType.STUDENT, "Điều Phối Viên Vật Tư", "Nữ")

	# Tầng 6: Ban Kỹ Thuật & Bảo Trì Cơ Sở Vật Chất (+44m)
	var f6 = _build_floor_slab(skyscraper, 6, 44.0, 8.0, mat_border, mat_border, mat_glass, mat_gold)
	_add_desk_station(f6, "Bàn Giám Sát Hao Mòn Máy Móc & Điện Lưới", Vector3(-6.0, 0.0, 0.0), "desk_maintenance_tech", "Ban Kỹ Thuật", "⚡ [E] Điều Động Thợ Sửa Chữa & Cân Bằng Điện Lưới", mat_wood, mat_border, mat_holo)
	_add_worker_npc(f6, "Trưởng Ban Kỹ Thuật Bác Long", Vector3(-6.0, 0.0, -1.8), ModularHumanoidBuilderScript.ProfessionType.ENGINEER, "Trưởng Ban Kỹ Thuật Đô Thị", "Nam")
	_add_worker_npc(f6, "Thợ Điện Lưới Cao Thế Nam", Vector3(4.0, 0.0, -1.8), ModularHumanoidBuilderScript.ProfessionType.CARPENTER, "Kỹ Sư Trực Lưới Điện", "Nam")

	# Tầng 7: Ban Kiểm Chuẩn Chất Lượng & Môi Trường (+52m)
	var f7 = _build_floor_slab(skyscraper, 7, 52.0, 8.0, mat_carpet, mat_border, mat_glass, mat_gold)
	_add_desk_station(f7, "Bàn Kiểm Định An Toàn Sinh Thái", Vector3(-6.0, 0.0, 0.0), "desk_eco_inspection", "Ban Môi Trường", "🌿 [E] Giám Sát Đất Lành & An Toàn Sinh Thái 100%", mat_wood, mat_border, mat_holo)
	_add_worker_npc(f7, "Trưởng Ban Môi Trường Chị Hằng", Vector3(-6.0, 0.0, -1.8), ModularHumanoidBuilderScript.ProfessionType.DOCTOR, "Trưởng Ban Môi Trường & Sinh Thái", "Nữ")
	_add_worker_npc(f7, "Kiểm Định Viên Thực Phẩm Đức", Vector3(4.0, 0.0, -1.8), ModularHumanoidBuilderScript.ProfessionType.STUDENT, "Kiểm Định Viên Chất Lượng", "Nam")

	# Tầng 8: Ban Truyền Thông, Báo Chí & Cầu Kính Skybridge (+60m) + VƯỜN TREO NAM
	var f8 = _build_floor_slab(skyscraper, 8, 60.0, 8.0, mat_carpet, mat_border, mat_glass, mat_gold)
	_add_desk_station(f8, "Phim Trường Phát Thanh & Điện Ảnh Anime", Vector3(-6.0, 0.0, 0.0), "desk_media_broadcast", "Ban Truyền Thông", "🎬 [E] Sản Xuất Bản Tin Phát Thanh & Phim Anime Đô Thị", mat_wood, mat_border, mat_holo)
	_add_worker_npc(f8, "Trưởng Ban Truyền Thông Đạo Diễn Quân", Vector3(-6.0, 0.0, -1.8), ModularHumanoidBuilderScript.ProfessionType.TEACHER, "Tổng Biên Tập & Đạo Diễn Phim", "Nam")
	_add_worker_npc(f8, "Phóng Viên Anime Cát Tường", Vector3(4.0, 0.0, -1.8), ModularHumanoidBuilderScript.ProfessionType.STUDENT, "Phóng Viên Đô Thị", "Nữ")
	_add_sky_garden(f8, Vector3(0.0, 0.0, 1.0), 18.0, 3.6, mat_glass, mat_gold)

	# Tầng 9: Ban Ca Ngợi, Âm Nhạc Phụng Vụ & Thờ Phượng (+68m)
	var f9 = _build_floor_slab(skyscraper, 9, 68.0, 8.0, mat_wood, mat_border, mat_glass, mat_gold)
	var piano = MeshInstance3D.new()
	var p_box = BoxMesh.new()
	p_box.size = Vector3(2.6, 1.2, 3.2)
	piano.mesh = p_box
	piano.material_override = mat_gold
	piano.position = Vector3(-6.0, 0.6, 0.0)
	f9.add_child(piano)
	_add_box_col(f9, Vector3(2.6, 1.2, 3.2), Vector3(-6.0, 0.6, 0.0))

	_add_desk_station(f9, "Bàn Điều Phối Dàn Nhạc & Ca Đoàn", Vector3(6.0, 0.0, 0.0), "desk_worship_music", "Ban Ca Ngợi", "🎵 [E] Huấn Luyện Ca Đoàn & Chọn Bài Thánh Ca Tạ Ơn", mat_wood, mat_gold, mat_holo)
	_add_worker_npc(f9, "Trưởng Ban Ca Ngợi Nhạc Sĩ An", Vector3(-6.0, 0.0, -2.4), ModularHumanoidBuilderScript.ProfessionType.TEACHER, "Chỉ Huy Dàn Nhạc Phụng Vụ", "Nam")
	_add_worker_npc(f9, "Ca Viên Trưởng Thùy", Vector3(6.0, 0.0, -1.8), ModularHumanoidBuilderScript.ProfessionType.DOCTOR, "Nghệ Sĩ Đàn Piano", "Nữ")

	# Tầng 10: Ban Mục Vụ, Tư Vấn Tâm Lý & Sứ Mạng Hòa Bình (+76m)
	var f10 = _build_floor_slab(skyscraper, 10, 76.0, 8.0, mat_wood, mat_border, mat_glass, mat_gold)
	_add_desk_station(f10, "Bàn Trà Tâm Tình & Hòa Giải Huynh Đệ", Vector3(-6.0, 0.0, 0.0), "desk_pastoral_counseling", "Ban Mục Vụ", "☕ [E] Tư Vấn Tâm Lý & Kết Nối Đời Sống Huynh Đệ", mat_wood, mat_border, mat_holo)
	_add_worker_npc(f10, "Trưởng Ban Mục Vụ Bác Nhân", Vector3(-6.0, 0.0, -1.8), ModularHumanoidBuilderScript.ProfessionType.DOCTOR, "Trưởng Ban Mục Vụ & Hòa Bình", "Nam")
	_add_worker_npc(f10, "Chuyên Gia Tâm Lý Hương", Vector3(4.0, 0.0, -1.8), ModularHumanoidBuilderScript.ProfessionType.TEACHER, "Chuyên Gia Trị Liệu Tinh Thần", "Nữ")

	# --------------------------------------------------------------------------
	# TẦNG 11: ĐẠI HỘI TRƯỜNG SÂN VẬN ĐỘNG MÁI VÒM 15.000 CHỖ (MEGA-AUDITORIUM ARENA)
	# (Y = 84M, THÔNG TẦNG CAO 16M, CÓ GIẾNG TRỜI ĐÓN NẮNG THIÊN NHIÊN)
	# --------------------------------------------------------------------------
	var f11 = _build_floor_slab(skyscraper, 11, 84.0, 16.0, mat_carpet_red, mat_border, mat_glass, mat_gold)
	
	# Biển hiệu hoành tráng trong Đại Hội Trường
	var arena_sign = _create_label3d("🕊️ ĐẠI HỘI TRƯỜNG PHỤNG VỤ 15.000 CHỖ (MEGA-AUDITORIUM ARENA)\n[Thánh Lễ Thứ Tư & Chủ Nhật 11:40 • Bữa Ăn Agape Toàn Dân • Giếng Trời Thiên Nhiên]", Color(1.0, 0.9, 0.25), 24)
	arena_sign.position = Vector3(0.0, 9.5, -12.0)
	f11.add_child(arena_sign)

	# Bục giảng mạ vàng của Đấng Chăn Chiên
	var pulpit = MeshInstance3D.new()
	var pup_box = BoxMesh.new()
	pup_box.size = Vector3(3.6, 1.6, 2.2)
	pulpit.mesh = pup_box
	pulpit.material_override = mat_gold
	pulpit.position = Vector3(0.0, 0.8, -10.0)
	f11.add_child(pulpit)
	_add_box_col(f11, Vector3(3.6, 1.6, 2.2), Vector3(0.0, 0.8, -10.0))

	# Đàn Đại Phong Cầm (Pipe Organ) khổng lồ cao 14m tựa vách kính Bắc
	var organ = MeshInstance3D.new()
	var org_box = BoxMesh.new()
	org_box.size = Vector3(14.0, 14.0, 2.5)
	organ.mesh = org_box
	organ.material_override = mat_gold
	organ.position = Vector3(0.0, 7.0, -15.5)
	f11.add_child(organ)
	_add_box_col(f11, Vector3(14.0, 14.0, 2.5), Vector3(0.0, 7.0, -15.5))

	# Khán đài vòng cung nhiều bậc cho hàng ngàn người
	for tier in range(5):
		var tier_y = 0.4 + float(tier) * 0.7
		var tier_z = -3.0 + float(tier) * 3.2
		for side in [-7.5, 7.5]:
			var bench_row = MeshInstance3D.new()
			var b_mesh = BoxMesh.new()
			b_mesh.size = Vector3(9.0, 0.5, 1.2)
			bench_row.mesh = b_mesh
			bench_row.material_override = mat_wood
			bench_row.position = Vector3(side, tier_y, tier_z)
			f11.add_child(bench_row)
			_add_box_col(f11, b_mesh.size, bench_row.position)

	# Bàn Thánh Lễ Phụng Vụ & Bữa Ăn Agape
	var st_liturgy = _add_desk_station(f11, "Bàn Thánh Lễ Phụng Vụ", Vector3(0.0, 0.0, -6.5), "desk_sanctuary_liturgy", "Thánh Đường Hội Lễ", "🕊️ [E] Tham Dự Đại Lễ Chúa Nhật & Bữa Ăn Agape", mat_wood, mat_gold, mat_holo)
	
	_add_worker_npc(f11, "Người Chăn Chiên (The Shepherd)", Vector3(0.0, 0.0, -11.5), ModularHumanoidBuilderScript.ProfessionType.MAYOR, "Sứ Giả Từ Trời & Đấng Chăn Dắt", "Nam")
	_add_worker_npc(f11, "Chấp Sự Trưởng Vũ", Vector3(-4.5, 0.0, -10.0), ModularHumanoidBuilderScript.ProfessionType.TEACHER, "Điều Hành Nghi Lễ Thánh Đường", "Nam")
	_add_worker_npc(f11, "Trợ Tá Phụng Vụ Linh", Vector3(4.5, 0.0, -10.0), ModularHumanoidBuilderScript.ProfessionType.DOCTOR, "Phục Vụ Bác Ái Agape", "Nữ")

	# --------------------------------------------------------------------------
	# CÁC TẦNG 12 - 14: TRIỂN LÃM 5 HUYỆN, HỘI NGHỊ BÀN TRÒN & VIỆN R&D
	# --------------------------------------------------------------------------
	# Tầng 12: Hội Trường Triển Lãm & Xúc Tiến Thương Mại 5 Huyện (+100m) + SKY GARDEN VÀNH KHUYÊN
	var f12 = _build_floor_slab(skyscraper, 12, 100.0, 8.0, mat_granite_dark, mat_border, mat_glass, mat_gold)
	_add_desk_station(f12, "Gian Trưng Bày Nông Lâm Thủy Sản 5 Huyện", Vector3(-6.0, 0.0, 0.0), "desk_expo_trade", "Gian Triển Lãm", "🌾 [E] Tham Quan Hội Chợ Xúc Tiến Nông Nghiệp & Kỹ Nghệ", mat_wood, mat_border, mat_holo)
	_add_worker_npc(f12, "Trưởng Ban Triển Lãm Hải", Vector3(-6.0, 0.0, -1.8), ModularHumanoidBuilderScript.ProfessionType.FARMER, "Quản Lý Hội Chợ 5 Huyện", "Nam")
	_add_worker_npc(f12, "Thuyết Minh Viên Triển Lãm My", Vector3(4.0, 0.0, -1.8), ModularHumanoidBuilderScript.ProfessionType.STUDENT, "Thuyết Minh Văn Hóa Đô Thị", "Nữ")
	_add_sky_garden(f12, Vector3(0.0, 0.0, -1.0), 16.0, 3.2, mat_foliage, mat_gold)

	# Tầng 13: Trung Tâm Hội Nghị Bàn Tròn & Chiếu Phim Anime (+168m)
	var f13 = _build_floor_slab(skyscraper, 13, 108.0, 8.0, mat_carpet, mat_border, mat_glass, mat_gold)
	_build_mayor_private_office(f13, mat_wood, mat_border, mat_glass, mat_gold, mat_carpet)
	var round_table = MeshInstance3D.new()
	var rt_cyl = CylinderMesh.new()
	rt_cyl.top_radius = 4.0
	rt_cyl.bottom_radius = 4.0
	rt_cyl.height = 0.8
	round_table.mesh = rt_cyl
	round_table.material_override = mat_wood
	round_table.position = Vector3(0.0, 0.4, 0.0)
	f13.add_child(round_table)
	_add_cylinder_col(f13, 4.0, 0.8, Vector3(0.0, 0.4, 0.0))

	_add_desk_station(f13, "Bàn Nghị Quyết Kỳ Họp Bàn Tròn Quý", Vector3(0.0, 0.0, -5.5), "desk_cabinet_roundtable", "Hội Nghị Nội Các", "🗳️ [E] Mở Bàn Tròn Nội Các 9 Trưởng Ban (Định Kỳ Theo Quý)", mat_wood, mat_gold, mat_holo)
	_add_worker_npc(f13, "Thư Ký Hội Nghị Sơn", Vector3(-2.5, 0.0, -5.5), ModularHumanoidBuilderScript.ProfessionType.TEACHER, "Thư Ký Tổng Hợp Nghị Quyết", "Nam")
	_add_worker_npc(f13, "Điều Phối Viên Bàn Tròn Ngọc", Vector3(2.5, 0.0, -5.5), ModularHumanoidBuilderScript.ProfessionType.STUDENT, "Thư Ký Hành Chính", "Nữ")

	# Tầng 14: Giảng Đường Đào Tạo Lãnh Đạo & Nghiên Cứu Vĩ Mô (+116m)
	var f14 = _build_floor_slab(skyscraper, 14, 116.0, 8.0, mat_wood, mat_border, mat_glass, mat_gold)
	_add_desk_station(f14, "Bàn Viện Hàn Lâm Nghiên Cứu R&D", Vector3(-6.0, 0.0, 0.0), "desk_academy_rd", "Viện Hàn Lâm R&D", "🔬 [E] Mở Cây Công Nghệ Kiến Tạo 20 Bậc Liên Tục", mat_wood, mat_border, mat_holo)
	_add_worker_npc(f14, "Viện Trưởng GS. Trí", Vector3(-6.0, 0.0, -1.8), ModularHumanoidBuilderScript.ProfessionType.TEACHER, "Viện Trưởng Hàn Lâm Khoa Học", "Nam")
	_add_worker_npc(f14, "Nghiên Cứu Viên Khanh", Vector3(4.0, 0.0, -1.8), ModularHumanoidBuilderScript.ProfessionType.STUDENT, "Nhà Khoa Học Năng Lượng Sạch", "Nam")

	# --------------------------------------------------------------------------
	# TẦNG 15: SKYDECK SÂN THƯỢNG, CLOUD CAFE & HELIPADS VIP (+124M ĐẾN +150M)
	# --------------------------------------------------------------------------
	var f15 = _build_floor_slab(skyscraper, 15, 124.0, 10.0, mat_white, mat_border, mat_glass, mat_gold)
	
	# Quầy Bar Cloud Cafe trên sân thượng mở, không có mái che.
	var bar = MeshInstance3D.new()
	var b_box = BoxMesh.new()
	b_box.size = Vector3(6.0, 1.1, 2.0)
	bar.mesh = b_box
	bar.material_override = mat_wood
	bar.position = Vector3(0.0, 0.55, -2.0)
	f15.add_child(bar)
	_add_box_col(f15, Vector3(6.0, 1.1, 2.0), Vector3(0.0, 0.55, -2.0))

	_add_desk_station(f15, "Quầy Trà Thảo Mộc & Cloud Cafe", Vector3(0.0, 0.0, 2.0), "station_cloud_cafe", "Cloud Cafe", "☕ [E] Thưởng Thức Trà Thảo Mộc Trên Mây & Ngắm Toàn Cảnh", mat_wood, mat_gold, mat_holo)
	
	# Kính Viễn Vọng Thiên Văn Siêu Trường
	_add_desk_station(f15, "Kính Viễn Vọng Thiên Văn", Vector3(14.0, 0.0, 0.0), "telescope_skydeck", "Kính Viễn Vọng", "🔭 [E] Quan Sát Đại Thế Giới 500 km² Từ Tầng 15", mat_gold, mat_border, mat_holo)

	_add_worker_npc(f15, "Barista Bác Cường", Vector3(0.0, 0.0, -3.5), ModularHumanoidBuilderScript.ProfessionType.BAKER, "Nghệ Nhân Pha Chế Cloud Cafe", "Nam")

	for basement_index in range(BASEMENT_HEIGHTS.size()):
		_build_basement_level(skyscraper, basement_index, mat_granite_dark, mat_border)

	# --------------------------------------------------------------------------
	# CẦU THANG BỘ THÔNG TẦNG, TIẾP TỤC TỪ TẦNG HẦM B4 LÊN TẦNG 15
	# --------------------------------------------------------------------------
	var all_stair_levels: Array[float] = [-40.0, -30.0, -20.0, -10.0]
	all_stair_levels.append_array(FLOOR_HEIGHTS)
	for stairwell_index in range(STAIRWELL_WORLD_X_POSITIONS.size()):
		var stairwell = Node3D.new()
		stairwell.name = "ContinuousStairwell" if stairwell_index == 0 else "ContinuousStairwell_East"
		stairwell.position = Vector3(
			STAIRWELL_WORLD_X_POSITIONS[stairwell_index] / FOOTPRINT_LINEAR_SCALE,
			0.0,
			STAIRWELL_WORLD_Z / FOOTPRINT_LINEAR_SCALE
		)
		stairwell.scale = Vector3(1.0 / FOOTPRINT_LINEAR_SCALE, 1.0, 1.0 / FOOTPRINT_LINEAR_SCALE)
		skyscraper.add_child(stairwell)

		var stair_flight_index = 0
		for i in range(all_stair_levels.size() - 1):
			stair_flight_index += _build_staircase_flight(stairwell, all_stair_levels[i], all_stair_levels[i + 1], mat_wood, mat_border, stair_flight_index)
		_add_stairwell_privacy_partition(
			stairwell,
			stairwell_index,
			mat_corridor_glass,
			mat_corridor_frame,
			mat_corridor_floor
		)

	# --------------------------------------------------------------------------
	# BỐN THANG MÁY KÍNH CẠNH NHAU SAU CỬA NAM, CHẠY TỪ B4 LÊN TẦNG 15
	# --------------------------------------------------------------------------
	var elevator_bank = Node3D.new()
	elevator_bank.name = "FourElevatorBank"
	elevator_bank.position = Vector3(0.0, 0.0, ELEVATOR_BANK_WORLD_Z / FOOTPRINT_LINEAR_SCALE)
	elevator_bank.scale = Vector3(1.0 / FOOTPRINT_LINEAR_SCALE, 1.0, 1.0 / FOOTPRINT_LINEAR_SCALE)
	skyscraper.add_child(elevator_bank)

	for elevator_index in range(ELEVATOR_X_POSITIONS.size()):
		var elevator_inst = SkyscraperElevatorScript.new()
		elevator_inst.name = "GlassPanoramaElevator" if elevator_index == 0 else "GlassPanoramaElevator_%02d" % (elevator_index + 1)
		elevator_inst.position.x = ELEVATOR_X_POSITIONS[elevator_index]
		elevator_bank.add_child(elevator_inst)

		var shaft = MeshInstance3D.new()
		shaft.name = "ElevatorShaft"
		var shaft_mesh = BoxMesh.new()
		shaft_mesh.size = Vector3(7.2, 250.0, 7.2)
		shaft.mesh = shaft_mesh
		shaft.material_override = mat_glass
		shaft.position = Vector3(elevator_inst.position.x, 80.0, 0.0)
		elevator_bank.add_child(shaft)

		for corner_x in [-3.6, 3.6]:
			for corner_z in [-3.6, 3.6]:
				var frame = MeshInstance3D.new()
				frame.name = "ElevatorShaftFrame"
				var frame_mesh = BoxMesh.new()
				frame_mesh.size = Vector3(0.24, 250.0, 0.24)
				frame.mesh = frame_mesh
				frame.material_override = mat_gold
				frame.position = Vector3(elevator_inst.position.x + corner_x, 80.0, corner_z)
				elevator_bank.add_child(frame)

	_normalize_interaction_node_scales(skyscraper)
	skyscraper.set_meta("floor_area_multiplier", 80.0)
	skyscraper.set_meta("occupancy_capacity", 10000)
	skyscraper.set_meta("open_rooftop_floor", 15)
	print("[MegaOfficeSkyscraper] 🏢 Mega Office 15 tầng, diện tích x80, sức chứa thiết kế 10.000 người.")
	return skyscraper

static func _build_mayor_private_office(parent: Node3D, mat_wood: Material, mat_border: Material, mat_glass: Material, mat_gold: Material, mat_carpet: Material) -> void:
	var office := Node3D.new()
	office.name = "MayorPrivateOffice"
	office.position = Vector3(12.0, 0.0, -10.0)
	office.scale = Vector3(1.0 / FOOTPRINT_LINEAR_SCALE, 1.0, 1.0 / FOOTPRINT_LINEAR_SCALE)
	office.set_meta("floor_area_square_meters", 600.0)
	office.set_meta("floor_number", 13)
	office.set_meta("has_bed", true)
	office.set_meta("has_kitchen", true)
	office.set_meta("has_bathroom", true)
	office.set_meta("has_living_room", true)
	office.set_meta("has_vault", true)
	parent.add_child(office)

	# --------------------------------------------------------------------------
	# SÀN DINH THỰ 600M² (30M X 20M)
	# --------------------------------------------------------------------------
	var carpet := MeshInstance3D.new()
	carpet.name = "OfficeFloor"
	var carpet_mesh := BoxMesh.new()
	carpet_mesh.size = Vector3(30.0, 0.12, 20.0)
	carpet.mesh = carpet_mesh
	carpet.position = Vector3(0.0, 0.46, 0.0)
	carpet.material_override = mat_carpet
	office.add_child(carpet)
	_add_box_col(office, carpet_mesh.size, carpet.position)

	# --------------------------------------------------------------------------
	# VÁCH BAO NGOẠI VI (CHU VI 30M X 20M, CAO 3.8M)
	# --------------------------------------------------------------------------
	# Vách kính Panorama phía Bắc nhìn ra cao nguyên thiên nhiên +600m
	var north_wall := MeshInstance3D.new()
	north_wall.name = "NorthWall"
	var north_mesh := BoxMesh.new()
	north_mesh.size = Vector3(30.0, 3.8, 0.24)
	north_wall.mesh = north_mesh
	north_wall.position = Vector3(0.0, 2.3, -10.0)
	north_wall.material_override = mat_glass
	office.add_child(north_wall)
	_add_box_col(office, north_mesh.size, north_wall.position)

	# Khung viền mạ vàng trên vách kính Bắc
	for fx in [-10.0, 0.0, 10.0]:
		var frame := MeshInstance3D.new()
		var frame_m := BoxMesh.new()
		frame_m.size = Vector3(0.3, 3.8, 0.3)
		frame.mesh = frame_m
		frame.position = Vector3(fx, 2.3, -9.95)
		frame.material_override = mat_gold
		office.add_child(frame)

	# Vách kính phía Tây & Đông
	for side in [-1.0, 1.0]:
		var side_wall := MeshInstance3D.new()
		side_wall.name = "WestWall" if side < 0.0 else "EastWall"
		var side_mesh := BoxMesh.new()
		side_mesh.size = Vector3(0.24, 3.8, 20.0)
		side_wall.mesh = side_mesh
		side_wall.position = Vector3(side * 15.0, 2.3, 0.0)
		side_wall.material_override = mat_glass
		office.add_child(side_wall)
		_add_box_col(office, side_mesh.size, side_wall.position)

		for fz in [-5.0, 5.0]:
			var s_frame := MeshInstance3D.new()
			var sf_m := BoxMesh.new()
			sf_m.size = Vector3(0.3, 3.8, 0.3)
			s_frame.mesh = sf_m
			s_frame.position = Vector3(side * 14.95, 2.3, fz)
			s_frame.material_override = mat_gold
			office.add_child(s_frame)

	# Vách mặt tiền phía Nam (có cửa chính rộng 3.2m dẫn vào Living Lounge)
	var south_left := MeshInstance3D.new()
	south_left.name = "SouthWallLeft"
	var sl_mesh := BoxMesh.new()
	sl_mesh.size = Vector3(5.9, 3.8, 0.24)
	south_left.mesh = sl_mesh
	south_left.position = Vector3(-12.05, 2.3, 10.0)
	south_left.material_override = mat_border
	office.add_child(south_left)
	_add_box_col(office, sl_mesh.size, south_left.position)

	var south_right := MeshInstance3D.new()
	south_right.name = "SouthWallRight"
	var sr_mesh := BoxMesh.new()
	sr_mesh.size = Vector3(20.9, 3.8, 0.24)
	south_right.mesh = sr_mesh
	south_right.position = Vector3(4.55, 2.3, 10.0)
	south_right.material_override = mat_border
	office.add_child(south_right)
	_add_box_col(office, sr_mesh.size, south_right.position)

	var door_header := MeshInstance3D.new()
	door_header.name = "OfficeDoorHeader"
	var header_mesh := BoxMesh.new()
	header_mesh.size = Vector3(3.4, 0.24, 0.24)
	door_header.mesh = header_mesh
	door_header.position = Vector3(-7.5, 4.0, 10.0)
	door_header.material_override = mat_gold
	office.add_child(door_header)

	var door_sign := _create_label3d("🏛️ DINH THỰ RIÊNG THỊ TRƯỞNG • PENTHOUSE 600M² • KHO BẢO MẬT", Color(1.0, 0.88, 0.3), 20)
	door_sign.position = Vector3(-7.5, 4.4, 10.25)
	office.add_child(door_sign)

	# --------------------------------------------------------------------------
	# CÁC VÁCH NGĂN PHÂN CHIA NỘI BỘ (INTERNAL PARTITIONS)
	# --------------------------------------------------------------------------
	# 1. Trục chính X = 0 (tách nửa Trái và nửa Phải, có lối thông phòng 3.0m ở giữa Z in [-1.5, 1.5])
	var mid_north := MeshInstance3D.new()
	mid_north.mesh = BoxMesh.new()
	mid_north.mesh.size = Vector3(0.24, 3.8, 8.5)
	mid_north.position = Vector3(0.0, 2.3, -5.75)
	mid_north.material_override = mat_border
	office.add_child(mid_north)
	_add_box_col(office, mid_north.mesh.size, mid_north.position)

	var mid_south := MeshInstance3D.new()
	mid_south.mesh = BoxMesh.new()
	mid_south.mesh.size = Vector3(0.24, 3.8, 8.5)
	mid_south.position = Vector3(0.0, 2.3, 5.75)
	mid_south.material_override = mat_border
	office.add_child(mid_south)
	_add_box_col(office, mid_south.mesh.size, mid_south.position)

	# 2. Tách Living Lounge và Executive Office (Trục Z = 0 ở nửa Trái, cửa thông 2.5m tại X in [-8.5, -6.0])
	var div_west1 := MeshInstance3D.new()
	div_west1.mesh = BoxMesh.new()
	div_west1.mesh.size = Vector3(6.5, 3.8, 0.24)
	div_west1.position = Vector3(-11.75, 2.3, 0.0)
	div_west1.material_override = mat_wood
	office.add_child(div_west1)
	_add_box_col(office, div_west1.mesh.size, div_west1.position)

	var div_west2 := MeshInstance3D.new()
	div_west2.mesh = BoxMesh.new()
	div_west2.mesh.size = Vector3(6.0, 3.8, 0.24)
	div_west2.position = Vector3(-3.0, 2.3, 0.0)
	div_west2.material_override = mat_wood
	office.add_child(div_west2)
	_add_box_col(office, div_west2.mesh.size, div_west2.position)

	# 3. Tách Kitchen & Dining với Bedroom / Vault (Trục Z = 3.0 ở nửa Phải, cửa thông 2.5m tại X in [3.0, 5.5])
	var div_east1 := MeshInstance3D.new()
	div_east1.mesh = BoxMesh.new()
	div_east1.mesh.size = Vector3(3.0, 3.8, 0.24)
	div_east1.position = Vector3(1.5, 2.3, 3.0)
	div_east1.material_override = mat_border
	office.add_child(div_east1)
	_add_box_col(office, div_east1.mesh.size, div_east1.position)

	var div_east2 := MeshInstance3D.new()
	div_east2.mesh = BoxMesh.new()
	div_east2.mesh.size = Vector3(9.5, 3.8, 0.24)
	div_east2.position = Vector3(10.25, 2.3, 3.0)
	div_east2.material_override = mat_border
	office.add_child(div_east2)
	_add_box_col(office, div_east2.mesh.size, div_east2.position)

	# 4. Tách Master Bedroom với Bathroom & Private Vault (Trục X = 9.0, từ Z=-10 đến Z=3)
	var div_bed_north := MeshInstance3D.new()
	div_bed_north.mesh = BoxMesh.new()
	div_bed_north.mesh.size = Vector3(0.24, 3.8, 9.0)
	div_bed_north.position = Vector3(9.0, 2.3, -5.5)
	div_bed_north.material_override = mat_wood
	office.add_child(div_bed_north)
	_add_box_col(office, div_bed_north.mesh.size, div_bed_north.position)

	var div_bed_south := MeshInstance3D.new()
	div_bed_south.mesh = BoxMesh.new()
	div_bed_south.mesh.size = Vector3(0.24, 3.8, 1.5)
	div_bed_south.position = Vector3(9.0, 2.3, 2.25)
	div_bed_south.material_override = mat_wood
	office.add_child(div_bed_south)
	_add_box_col(office, div_bed_south.mesh.size, div_bed_south.position)

	# 5. Tách Private Vault và Bathroom (Trục Z = -4.0 tại X in [9, 15], cửa thông tại X in [10.5, 12.5])
	var div_vault1 := MeshInstance3D.new()
	div_vault1.mesh = BoxMesh.new()
	div_vault1.mesh.size = Vector3(1.5, 3.8, 0.24)
	div_vault1.position = Vector3(9.75, 2.3, -4.0)
	div_vault1.material_override = mat_border
	office.add_child(div_vault1)
	_add_box_col(office, div_vault1.mesh.size, div_vault1.position)

	var div_vault2 := MeshInstance3D.new()
	div_vault2.mesh = BoxMesh.new()
	div_vault2.mesh.size = Vector3(2.5, 3.8, 0.24)
	div_vault2.position = Vector3(13.75, 2.3, -4.0)
	div_vault2.material_override = mat_border
	office.add_child(div_vault2)
	_add_box_col(office, div_vault2.mesh.size, div_vault2.position)

	# --------------------------------------------------------------------------
	# PHÒNG 1: LIVING LOUNGE (PHÒNG KHÁCH THỊ TRƯỞNG - 150 M²)
	# --------------------------------------------------------------------------
	var living_lounge := Node3D.new()
	living_lounge.name = "LivingLounge"
	office.add_child(living_lounge)

	var lounge_sign := _create_label3d("🛋️ PHÒNG KHÁCH NGOẠI GIAO (LIVING LOUNGE)", Color(1.0, 0.88, 0.3), 18)
	lounge_sign.position = Vector3(-7.5, 3.2, 5.0)
	living_lounge.add_child(lounge_sign)

	var sofa_main := MeshInstance3D.new()
	sofa_main.name = "SofaMain"
	var sm_mesh := BoxMesh.new()
	sm_mesh.size = Vector3(5.0, 0.85, 1.2)
	sofa_main.mesh = sm_mesh
	sofa_main.position = Vector3(-10.0, 0.85, 5.0)
	sofa_main.material_override = mat_border
	living_lounge.add_child(sofa_main)
	_add_box_col(living_lounge, sm_mesh.size, sofa_main.position)

	var sofa_l := MeshInstance3D.new()
	sofa_l.name = "SofaL"
	var sl2_mesh := BoxMesh.new()
	sl2_mesh.size = Vector3(1.2, 0.85, 3.5)
	sofa_l.mesh = sl2_mesh
	sofa_l.position = Vector3(-12.0, 0.85, 2.65)
	sofa_l.material_override = mat_border
	living_lounge.add_child(sofa_l)
	_add_box_col(living_lounge, sl2_mesh.size, sofa_l.position)

	var coffee_table := MeshInstance3D.new()
	coffee_table.name = "CoffeeTable"
	var ct_mesh := BoxMesh.new()
	ct_mesh.size = Vector3(2.8, 0.45, 1.5)
	coffee_table.mesh = ct_mesh
	coffee_table.position = Vector3(-9.5, 0.65, 3.0)
	coffee_table.material_override = mat_wood
	living_lounge.add_child(coffee_table)
	_add_box_col(living_lounge, ct_mesh.size, coffee_table.position)

	var tv_display := MeshInstance3D.new()
	tv_display.name = "CivicDisplayWall"
	var tv_mesh := BoxMesh.new()
	tv_mesh.size = Vector3(4.5, 2.2, 0.1)
	tv_display.mesh = tv_mesh
	tv_display.position = Vector3(-4.0, 2.4, 9.8)
	var mat_tv := _create_emission_material(Color(0.1, 0.5, 0.9), Color(0.2, 0.8, 1.0), 2.5)
	tv_display.material_override = mat_tv
	living_lounge.add_child(tv_display)

	# --------------------------------------------------------------------------
	# PHÒNG 2: EXECUTIVE OFFICE (VĂN PHÒNG ĐIỀU HÀNH THỊ TRƯỞNG - 150 M²)
	# --------------------------------------------------------------------------
	var exec_office := Node3D.new()
	exec_office.name = "ExecutiveOffice"
	office.add_child(exec_office)

	var exec_sign := _create_label3d("🏛️ VĂN PHÒNG ĐIỀU HÀNH THỊ TRƯỞNG (EXECUTIVE OFFICE)", Color(1.0, 0.88, 0.3), 18)
	exec_sign.position = Vector3(-7.5, 3.2, -5.0)
	exec_office.add_child(exec_sign)

	var desk := MeshInstance3D.new()
	desk.name = "MayorOfficeDesk"
	var desk_mesh := BoxMesh.new()
	desk_mesh.size = Vector3(4.2, 1.05, 2.0)
	desk.mesh = desk_mesh
	desk.position = Vector3(-7.5, 0.93, -6.5)
	desk.material_override = mat_wood
	exec_office.add_child(desk)
	_add_box_col(exec_office, desk_mesh.size, desk.position)

	var desk_inlay := MeshInstance3D.new()
	desk_inlay.name = "DeskBrassInlay"
	var inlay_mesh := BoxMesh.new()
	inlay_mesh.size = Vector3(4.0, 0.035, 1.8)
	desk_inlay.mesh = inlay_mesh
	desk_inlay.position = Vector3(-7.5, 1.47, -6.5)
	desk_inlay.material_override = mat_gold
	exec_office.add_child(desk_inlay)

	var chair := MeshInstance3D.new()
	chair.name = "MayorOfficeChair"
	var chair_mesh := BoxMesh.new()
	chair_mesh.size = Vector3(1.1, 1.5, 0.9)
	chair.mesh = chair_mesh
	chair.position = Vector3(-7.5, 1.15, -8.0)
	chair.material_override = mat_border
	exec_office.add_child(chair)

	var bookcase := MeshInstance3D.new()
	bookcase.name = "MayorOfficeBookcase"
	var bookcase_mesh := BoxMesh.new()
	bookcase_mesh.size = Vector3(1.4, 3.0, 5.0)
	bookcase.mesh = bookcase_mesh
	bookcase.position = Vector3(-14.0, 1.9, -5.0)
	bookcase.material_override = mat_wood
	exec_office.add_child(bookcase)
	_add_box_col(exec_office, bookcase_mesh.size, bookcase.position)

	# --------------------------------------------------------------------------
	# PHÒNG 3: KITCHEN & DINING (BẾP & BÀN ĂN CAO CẤP - 105 M²)
	# --------------------------------------------------------------------------
	var kitchen := Node3D.new()
	kitchen.name = "KitchenArea"
	office.add_child(kitchen)

	var kitchen_sign := _create_label3d("🍽️ BẾP HIỆN ĐẠI & BÀN ĂN (KITCHEN & DINING)", Color(1.0, 0.88, 0.3), 18)
	kitchen_sign.position = Vector3(7.5, 3.2, 6.5)
	kitchen.add_child(kitchen_sign)

	var island := MeshInstance3D.new()
	island.name = "KitchenIsland"
	var isl_mesh := BoxMesh.new()
	isl_mesh.size = Vector3(4.5, 1.05, 1.6)
	island.mesh = isl_mesh
	island.position = Vector3(7.5, 0.95, 8.0)
	island.material_override = mat_border
	kitchen.add_child(island)
	_add_box_col(kitchen, isl_mesh.size, island.position)

	var dining_table := MeshInstance3D.new()
	dining_table.name = "DiningTable"
	var dt_mesh := BoxMesh.new()
	dt_mesh.size = Vector3(3.6, 0.85, 1.6)
	dining_table.mesh = dt_mesh
	dining_table.position = Vector3(7.5, 0.85, 4.5)
	dining_table.material_override = mat_wood
	kitchen.add_child(dining_table)
	_add_box_col(kitchen, dt_mesh.size, dining_table.position)

	var fridge := MeshInstance3D.new()
	fridge.name = "LuxuryFridge"
	var fr_mesh := BoxMesh.new()
	fr_mesh.size = Vector3(1.5, 2.4, 1.0)
	fridge.mesh = fr_mesh
	fridge.position = Vector3(13.8, 1.65, 8.5)
	fridge.material_override = mat_border
	kitchen.add_child(fridge)
	_add_box_col(kitchen, fr_mesh.size, fridge.position)

	# --------------------------------------------------------------------------
	# PHÒNG 4: MASTER BEDROOM (PHÒNG NGỦ RIÊNG THỊ TRƯỞNG & GIƯỜNG TUA ĐÊM - 117 M²)
	# --------------------------------------------------------------------------
	var bedroom := Node3D.new()
	bedroom.name = "MasterBedroom"
	office.add_child(bedroom)

	var bed_sign := _create_label3d("🛏️ PHÒNG NGỦ RIÊNG THỊ TRƯỞNG (MASTER BEDROOM)", Color(1.0, 0.88, 0.3), 18)
	bed_sign.position = Vector3(4.5, 3.2, -3.5)
	bedroom.add_child(bed_sign)

	var bed_frame := MeshInstance3D.new()
	bed_frame.name = "KingSizeBedFrame"
	var bf_mesh := BoxMesh.new()
	bf_mesh.size = Vector3(2.6, 0.55, 2.4)
	bed_frame.mesh = bf_mesh
	bed_frame.position = Vector3(4.5, 0.7, -6.5)
	bed_frame.material_override = mat_wood
	bedroom.add_child(bed_frame)
	_add_box_col(bedroom, bf_mesh.size, bed_frame.position)

	var mattress := MeshInstance3D.new()
	mattress.name = "BedMattress"
	var mat_mesh := BoxMesh.new()
	mat_mesh.size = Vector3(2.4, 0.35, 2.2)
	mattress.mesh = mat_mesh
	mattress.position = Vector3(4.5, 1.05, -6.5)
	mattress.material_override = _create_material(Color(0.96, 0.97, 0.98), 0.9)
	bedroom.add_child(mattress)

	var headboard := MeshInstance3D.new()
	headboard.name = "BedHeadboard"
	var hb_mesh := BoxMesh.new()
	hb_mesh.size = Vector3(2.6, 1.4, 0.25)
	headboard.mesh = hb_mesh
	headboard.position = Vector3(4.5, 1.4, -7.7)
	headboard.material_override = mat_border
	bedroom.add_child(headboard)

	# Trạm tương tác ngủ Night Skip [E] trên giường thị trưởng theo Quy tắc 5
	var bed_station := InteractiveStation.new()
	bed_station.name = "BedStation"
	bed_station.station_type = InteractiveStation.StationType.BED
	bed_station.station_id = "mayor_master_bed"
	bed_station.title_name = "Giường Ngủ Thị Trưởng"
	bed_station.prompt_text = "🛏️ [E] Nằm nghỉ hoặc chọn ngủ đến 06:00"
	bed_station.interaction_radius = 6.0
	bed_station.position = Vector3(4.5, 0.8, -5.5)
	bedroom.add_child(bed_station)

	# Tủ trang phục đổi quần áo (Wardrobe Outfit Changer)
	var wardrobe := Node3D.new()
	wardrobe.name = "WardrobeOutfitChanger"
	wardrobe.set_script(WardrobeOutfitChangerScript)
	wardrobe.position = Vector3(1.6, 0.0, -2.0)
	bedroom.add_child(wardrobe)

	# --------------------------------------------------------------------------
	# PHÒNG 5: BATHROOM (PHÒNG TẮM & VỆ SINH VIP - 42 M²)
	# --------------------------------------------------------------------------
	var bathroom := Node3D.new()
	bathroom.name = "BathroomArea"
	office.add_child(bathroom)

	var bath_sign := _create_label3d("🛁 PHÒNG TẮM & VỆ SINH VIP (BATHROOM)", Color(1.0, 0.88, 0.3), 18)
	bath_sign.position = Vector3(12.0, 3.2, 0.0)
	bathroom.add_child(bath_sign)

	var tub := MeshInstance3D.new()
	tub.name = "JacuzziBathtub"
	var tub_mesh := BoxMesh.new()
	tub_mesh.size = Vector3(2.4, 0.75, 1.3)
	tub.mesh = tub_mesh
	tub.position = Vector3(13.2, 0.8, -1.0)
	tub.material_override = _create_material(Color(0.95, 0.98, 1.0), 0.2)
	bathroom.add_child(tub)
	_add_box_col(bathroom, tub_mesh.size, tub.position)

	var vanity := MeshInstance3D.new()
	vanity.name = "DoubleVanity"
	var v_mesh := BoxMesh.new()
	v_mesh.size = Vector3(2.2, 0.9, 0.8)
	vanity.mesh = v_mesh
	vanity.position = Vector3(13.5, 0.9, 1.8)
	vanity.material_override = mat_border
	bathroom.add_child(vanity)
	_add_box_col(bathroom, v_mesh.size, vanity.position)

	# --------------------------------------------------------------------------
	# PHÒNG 6: PRIVATE VAULT & STORAGE (KHO RIÊNG & KÉT SẮT THỊ TRƯỞNG - 36 M²)
	# --------------------------------------------------------------------------
	var vault := Node3D.new()
	vault.name = "PrivateVault"
	office.add_child(vault)

	var vault_sign := _create_label3d("🔐 KHO RIÊNG & KÉT SẮT BẢO MẬT (MAYOR'S VAULT)", Color(1.0, 0.88, 0.3), 18)
	vault_sign.position = Vector3(12.0, 3.2, -7.0)
	vault.add_child(vault_sign)

	# Kệ để vali da ngoại giao của Thị Trưởng
	var luggage_stand := MeshInstance3D.new()
	luggage_stand.name = "SuitcaseLuggageStand"
	var ls_mesh := BoxMesh.new()
	ls_mesh.size = Vector3(1.6, 0.65, 0.9)
	luggage_stand.mesh = ls_mesh
	luggage_stand.position = Vector3(14.0, 0.75, -5.5)
	luggage_stand.material_override = mat_wood
	vault.add_child(luggage_stand)
	_add_box_col(vault, ls_mesh.size, luggage_stand.position)

	var stand_brass := MeshInstance3D.new()
	stand_brass.name = "StandBrassTrim"
	var sb_mesh := BoxMesh.new()
	sb_mesh.size = Vector3(1.65, 0.04, 0.95)
	stand_brass.mesh = sb_mesh
	stand_brass.position = Vector3(14.0, 1.1, -5.5)
	stand_brass.material_override = mat_gold
	vault.add_child(stand_brass)

	# Két sắt kim loại hạng nặng
	var heavy_safe := MeshInstance3D.new()
	heavy_safe.name = "HeavyVaultSafe"
	var safe_mesh := BoxMesh.new()
	safe_mesh.size = Vector3(1.6, 2.2, 1.4)
	heavy_safe.mesh = safe_mesh
	heavy_safe.position = Vector3(10.0, 1.55, -8.5)
	heavy_safe.material_override = mat_border
	vault.add_child(heavy_safe)
	_add_box_col(vault, safe_mesh.size, heavy_safe.position)

	# Điểm kho riêng MayorOfficeStorage
	var office_storage := Node3D.new()
	office_storage.name = "MayorOfficeStorage"
	office_storage.set_script(MayorOfficeStorageScript)
	office_storage.position = Vector3(12.0, 0.0, -7.0)
	vault.add_child(office_storage)

static func _normalize_interaction_node_scales(node: Node) -> void:
	if node.name == "MayorPrivateOffice":
		return
	for child in node.get_children():
		if child is InteractiveStation:
			child.scale = Vector3(1.0 / FOOTPRINT_LINEAR_SCALE, 1.0, 1.0 / FOOTPRINT_LINEAR_SCALE)
		elif child.name.begins_with("NPC_"):
			child.scale = Vector3(1.0 / FOOTPRINT_LINEAR_SCALE, 1.0, 1.0 / FOOTPRINT_LINEAR_SCALE)
		elif child is Label3D and not _has_normalized_interaction_ancestor(child):
			child.scale = Vector3(1.0 / FOOTPRINT_LINEAR_SCALE, 1.0, 1.0 / FOOTPRINT_LINEAR_SCALE)
		_normalize_interaction_node_scales(child)

static func _has_normalized_interaction_ancestor(node: Node) -> bool:
	var ancestor = node.get_parent()
	while ancestor != null:
		if ancestor is InteractiveStation or ancestor.name.begins_with("NPC_"):
			return true
		ancestor = ancestor.get_parent()
	return false

static func _build_basement_level(parent: Node3D, basement_index: int, mat_floor: Material, mat_border: Material) -> void:
	var basement_number = basement_index + 1
	var y_pos = BASEMENT_HEIGHTS[basement_index]
	var level = Node3D.new()
	level.name = "Basement_B%d" % basement_number
	level.position.y = y_pos
	level.set_meta("floor_number", -basement_number)
	parent.add_child(level)

	_build_walkable_floor(level, mat_floor, 0.2)

	var sign = _create_label3d("TẦNG HẦM B%d" % basement_number, Color(0.55, 0.9, 1.0), 22)
	sign.position = Vector3(0.0, 2.8, -10.0)
	level.add_child(sign)

	var boundary = MeshInstance3D.new()
	boundary.name = "BasementPerimeterMark"
	var boundary_mesh = BoxMesh.new()
	boundary_mesh.size = Vector3(36.0, 0.16, 0.3)
	boundary.mesh = boundary_mesh
	boundary.material_override = mat_border
	boundary.position = Vector3(0.0, 0.45, 17.7)
	level.add_child(boundary)

static func _build_walkable_floor(parent: Node3D, material: Material, center_y: float, thickness: float = 0.4) -> void:
	var panels: Array[Rect2] = [Rect2(Vector2(-18.0, -18.0), Vector2(36.0, 36.0))]
	var opening_size = Vector2(8.4 / FOOTPRINT_LINEAR_SCALE, 8.4 / FOOTPRINT_LINEAR_SCALE)
	for elevator_x in ELEVATOR_X_POSITIONS:
		var opening_center = Vector2(elevator_x / FOOTPRINT_LINEAR_SCALE, ELEVATOR_BANK_WORLD_Z / FOOTPRINT_LINEAR_SCALE)
		panels = _subtract_floor_opening(panels, Rect2(opening_center - opening_size * 0.5, opening_size))

	var stair_opening_size = Vector2(14.0 / FOOTPRINT_LINEAR_SCALE, 14.0 / FOOTPRINT_LINEAR_SCALE)
	for stair_x in STAIRWELL_WORLD_X_POSITIONS:
		var stair_opening_center = Vector2(
			(stair_x + 5.6) / FOOTPRINT_LINEAR_SCALE,
			(STAIRWELL_WORLD_Z + 3.0) / FOOTPRINT_LINEAR_SCALE
		)
		panels = _subtract_floor_opening(panels, Rect2(stair_opening_center - stair_opening_size * 0.5, stair_opening_size))

	for panel_rect in panels:
		var panel_size = Vector3(panel_rect.size.x, thickness, panel_rect.size.y)
		var panel_position = Vector3(panel_rect.position.x + panel_rect.size.x * 0.5, center_y, panel_rect.position.y + panel_rect.size.y * 0.5)
		var panel = MeshInstance3D.new()
		panel.name = "FloorPanel"
		var panel_mesh = BoxMesh.new()
		panel_mesh.size = panel_size
		panel.mesh = panel_mesh
		panel.material_override = material
		panel.position = panel_position
		parent.add_child(panel)
		_add_box_col(parent, panel_size, panel_position)

static func _subtract_floor_opening(panels: Array[Rect2], opening: Rect2) -> Array[Rect2]:
	var remaining: Array[Rect2] = []
	for panel in panels:
		if not panel.intersects(opening):
			remaining.append(panel)
			continue

		var overlap = panel.intersection(opening)
		var panel_right = panel.position.x + panel.size.x
		var panel_bottom = panel.position.y + panel.size.y
		var overlap_right = overlap.position.x + overlap.size.x
		var overlap_bottom = overlap.position.y + overlap.size.y
		if overlap.position.y > panel.position.y:
			remaining.append(Rect2(panel.position, Vector2(panel.size.x, overlap.position.y - panel.position.y)))
		if overlap_bottom < panel_bottom:
			remaining.append(Rect2(Vector2(panel.position.x, overlap_bottom), Vector2(panel.size.x, panel_bottom - overlap_bottom)))
		if overlap.position.x > panel.position.x:
			remaining.append(Rect2(Vector2(panel.position.x, overlap.position.y), Vector2(overlap.position.x - panel.position.x, overlap.size.y)))
		if overlap_right < panel_right:
			remaining.append(Rect2(Vector2(overlap_right, overlap.position.y), Vector2(panel_right - overlap_right, overlap.size.y)))
	return remaining

# ------------------------------------------------------------------------------
# HÀM XÂY DỰNG KHỐI SÀN & VÁCH KÍNH MỖI TẦNG
# ------------------------------------------------------------------------------
static func _build_floor_slab(parent: Node3D, floor_num: int, y_pos: float, f_height: float, mat_floor: Material, mat_border: Material, mat_glass: Material, _mat_gold: Material) -> Node3D:
	y_pos = FLOOR_HEIGHTS[floor_num - 1]
	f_height = FLOOR_HEIGHTS[floor_num] - y_pos if floor_num < FLOOR_HEIGHTS.size() else 13.0
	var floor_node = Node3D.new()
	floor_node.name = "Floor_%02d" % floor_num
	floor_node.position = Vector3(0.0, y_pos, 0.0)
	floor_node.set_meta("floor_area_multiplier", 80.0)
	floor_node.set_meta("open_to_sky", floor_num == 15)
	parent.add_child(floor_node)

	# Kích thước sàn gốc 36m x 36m, được mở rộng theo footprint của Mega Office.
	_build_walkable_floor(floor_node, mat_floor, 0.2)

	if floor_num < 15:
		_build_walkable_floor(floor_node, mat_border, f_height - 0.15, 0.3)

	# Kính bao tầng và lan can mở thoáng trên Skydeck.
	var perimeter_height = 1.2 if floor_num == 15 else f_height
	var perimeter_center_y = perimeter_height * 0.5 if floor_num == 15 else f_height * 0.5
	for wall_side in [Vector3(18.0, 0, 0), Vector3(-18.0, 0, 0), Vector3(0, 0, -18.0)]:
		if floor_num == 1:
			continue
		var wall = MeshInstance3D.new()
		var w_box = BoxMesh.new()
		w_box.size = Vector3(0.3, perimeter_height, 36.0) if wall_side.x != 0 else Vector3(36.0, perimeter_height, 0.3)
		wall.mesh = w_box
		wall.material_override = mat_border if floor_num == 15 else mat_glass
		wall.position = Vector3(wall_side.x, perimeter_center_y, wall_side.z)
		floor_node.add_child(wall)
		if floor_num != 15:
			_add_box_col(floor_node, w_box.size, wall.position)

	# Vách phía Nam (Mặt tiền có cửa kính)
	if floor_num == 15:
		var south_rail = MeshInstance3D.new()
		south_rail.name = "OpenSkydeckSouthGuardrail"
		var rail_mesh = BoxMesh.new()
		rail_mesh.size = Vector3(36.0, 1.2, 0.3)
		south_rail.mesh = rail_mesh
		south_rail.material_override = mat_border
		south_rail.position = Vector3(0.0, 0.6, 18.0)
		floor_node.add_child(south_rail)
		var open_roof_sign = _create_label3d("SKYDECK MỞ TRỜI • NHÌN THẲNG LÊN BẦU TRỜI", Color(0.55, 0.9, 1.0), 22)
		open_roof_sign.position = Vector3(0.0, 2.4, 15.0)
		floor_node.add_child(open_roof_sign)
	elif floor_num == 1:
		for side_name in ["South", "North", "East", "West"]:
			_build_ground_floor_facade(floor_node, side_name, f_height, mat_glass, mat_border)
	else:
		var wall_s = MeshInstance3D.new()
		var ws_box = BoxMesh.new()
		ws_box.size = Vector3(36.0, f_height, 0.3)
		wall_s.mesh = ws_box
		wall_s.material_override = mat_glass
		wall_s.position = Vector3(0.0, f_height * 0.5, 18.0)
		floor_node.add_child(wall_s)
		_add_box_col(floor_node, Vector3(36.0, f_height, 0.3), wall_s.position)

	# Biển tên Tầng 3D Diegetic gắn tường thang máy
	var sign_title = SkyscraperElevatorScript.FLOOR_NAMES[floor_num - 1]
	var floor_sign = _create_label3d(sign_title, Color(1.0, 0.88, 0.3), 20)
	floor_sign.position = Vector3(0.0, 2.6, -9.0)
	floor_node.add_child(floor_sign)

	return floor_node

static func _build_ground_floor_facade(parent: Node3D, side_name: String, wall_height: float, wall_material: Material, frame_material: Material) -> void:
	var door_centers: Array[float] = [-12.0, 0.0, 12.0]
	var door_width := 4.0
	var door_height := 4.2
	var horizontal_axis := side_name == "South" or side_name == "North"
	var wall_position := Vector3.ZERO
	match side_name:
		"South":
			wall_position.z = 18.0
		"North":
			wall_position.z = -18.0
		"East":
			wall_position.x = 18.0
		"West":
			wall_position.x = -18.0

	var previous_end := -18.0
	for door_index in range(door_centers.size()):
		var door_start := door_centers[door_index] - door_width * 0.5
		if door_start > previous_end:
			_add_ground_facade_wall(parent, side_name, previous_end, door_start, wall_height, wall_material)
		previous_end = door_centers[door_index] + door_width * 0.5
	if previous_end < 18.0:
		_add_ground_facade_wall(parent, side_name, previous_end, 18.0, wall_height, wall_material)

	for door_index in range(door_centers.size()):
		var along := door_centers[door_index]
		var entrance := Node3D.new()
		entrance.name = "MainEntrance" if side_name == "South" and door_index == 1 else "Entrance_%s_%d" % [side_name, door_index + 1]
		entrance.position = wall_position + (Vector3(along, 0.0, 0.0) if horizontal_axis else Vector3(0.0, 0.0, along))
		parent.add_child(entrance)

		var post_size := Vector3(0.35, door_height, 0.45) if horizontal_axis else Vector3(0.45, door_height, 0.35)
		for side_offset in [-1.0, 1.0]:
			var post_position := Vector3(side_offset * door_width * 0.5, door_height * 0.5, 0.0) if horizontal_axis else Vector3(0.0, door_height * 0.5, side_offset * door_width * 0.5)
			var door_post := MeshInstance3D.new()
			door_post.name = "DoorPost"
			var post_mesh := BoxMesh.new()
			post_mesh.size = post_size
			door_post.mesh = post_mesh
			door_post.material_override = frame_material
			door_post.position = post_position
			entrance.add_child(door_post)
			_add_box_col(entrance, post_size, post_position)

		var header_size := Vector3(door_width + 0.35, 0.35, 0.45) if horizontal_axis else Vector3(0.45, 0.35, door_width + 0.35)
		var header := MeshInstance3D.new()
		header.name = "DoorHeader"
		var header_mesh := BoxMesh.new()
		header_mesh.size = header_size
		header.mesh = header_mesh
		header.material_override = frame_material
		header.position = Vector3(0.0, door_height + 0.175, 0.0)
		entrance.add_child(header)
		_add_box_col(entrance, header_size, header.position)

		var side_label: String = {"South": "NAM", "North": "BẮC", "East": "ĐÔNG", "West": "TÂY"}[side_name]
		var entrance_sign := _create_label3d("CỬA %s • LỐI RA VÀO" % side_label, Color(1.0, 0.88, 0.3), 16)
		entrance_sign.position = Vector3(0.0, 5.0, 0.25) if side_name == "South" else Vector3(0.0, 5.0, -0.25) if side_name == "North" else Vector3(0.25, 5.0, 0.0) if side_name == "East" else Vector3(-0.25, 5.0, 0.0)
		entrance.add_child(entrance_sign)

static func _add_stairwell_privacy_partition(
	parent: Node3D,
	stairwell_index: int,
	glass_material: Material,
	frame_material: Material,
	floor_material: Material
) -> void:
	var floor_two_height: float = FLOOR_HEIGHTS[1]
	var floor_fifteen_height: float = FLOOR_HEIGHTS[FLOOR_HEIGHTS.size() - 1]
	var door_width := 2.0
	var door_height := 2.4
	var door_center_z := 3.0
	var wall_top := floor_fifteen_height + door_height
	var wall_height := wall_top - floor_two_height
	var wall_size := Vector3(0.3, wall_height, 12.4)
	var wall_x := 11.45
	var corridor := Node3D.new()
	corridor.name = "GlassOfficeCorridor_West" if stairwell_index == 0 else "GlassOfficeCorridor_East"
	corridor.set_meta("floor_count", FLOOR_HEIGHTS.size() - 1)
	corridor.set_meta("clear_width", 3.2)
	corridor.set_meta("length", 12.4)
	parent.add_child(corridor)

	var wall_body := StaticBody3D.new()
	wall_body.name = "StairwellPrivacyPartition_West" if stairwell_index == 0 else "StairwellPrivacyPartition_East"
	wall_body.collision_layer = 1
	wall_body.collision_mask = 1 | 2
	wall_body.position = Vector3(wall_x, (floor_two_height + wall_top) * 0.5, door_center_z)
	wall_body.set_meta("from_floor", 2)
	wall_body.set_meta("to_floor", 15)
	wall_body.set_meta("door_count", FLOOR_HEIGHTS.size() - 1)
	corridor.add_child(wall_body)

	var side_panel_size := Vector3(wall_size.x, wall_height, (wall_size.z - door_width) * 0.5)
	for side in [-1.0, 1.0]:
		_add_partition_panel(
			wall_body,
			side_panel_size,
			Vector3(0.0, 0.0, side * (door_width + side_panel_size.z) * 0.5),
			glass_material,
			"PrivacyWallSide"
		)
		_add_corridor_mullion(
			wall_body,
			Vector3(0.12, wall_height, 0.12),
			Vector3(0.0, 0.0, side * wall_size.z * 0.5),
			frame_material,
			"CorridorGlassMullion"
		)

	var panel_bottom := floor_two_height
	for floor_index in range(1, FLOOR_HEIGHTS.size()):
		var floor_height: float = FLOOR_HEIGHTS[floor_index]
		if floor_height > panel_bottom:
			var panel_height := floor_height - panel_bottom
			_add_partition_panel(
				wall_body,
				Vector3(wall_size.x, panel_height, door_width),
				Vector3(0.0, panel_bottom + panel_height * 0.5 - wall_body.position.y, 0.0),
				glass_material,
				"PrivacyWallBetweenDoors"
			)

		var stripe_y := floor_height + 1.0 - wall_body.position.y
		for stripe_offset in [0.0, 0.22]:
			for side in [-1.0, 1.0]:
				var stripe := MeshInstance3D.new()
				stripe.name = "FrostedGlassStripe"
				var stripe_mesh := BoxMesh.new()
				stripe_mesh.size = Vector3(0.035, 0.12, side_panel_size.z)
				stripe.mesh = stripe_mesh
				stripe.material_override = frame_material
				stripe.position = Vector3(0.0, stripe_y + stripe_offset, side * (door_width + side_panel_size.z) * 0.5)
				wall_body.add_child(stripe)

		var door: DoorController = StairwellDoorScene.instantiate() as DoorController
		door.name = "StairwellDoor_Floor_%02d" % (floor_index + 1)
		door.position = Vector3(wall_x, floor_height, door_center_z + door_width * 0.5)
		door.rotation.y = PI * 0.5
		door.scale = Vector3(door_width, door_height / 2.2, 1.0)
		door.auto_open_on_proximity = true
		door.open_angle_deg = 90.0
		var door_leaf := door.get_node_or_null("DoorHingePivot/DoorLeaf") as MeshInstance3D
		if door_leaf != null:
			door_leaf.material_override = glass_material
		var trigger := door.get_node_or_null("InteractionTrigger") as Area3D
		if trigger != null:
			trigger.collision_layer = 1 | 2 | 4
			trigger.collision_mask = 1 | 2 | 4
		corridor.add_child(door)

		var door_frame_height := door_height
		if floor_index + 1 < FLOOR_HEIGHTS.size():
			door_frame_height = minf(door_height, FLOOR_HEIGHTS[floor_index + 1] - floor_height)
		for side in [-1.0, 1.0]:
			_add_corridor_mullion(
				corridor,
				Vector3(0.16, door_frame_height, 0.16),
				Vector3(wall_x, floor_height + door_frame_height * 0.5, door_center_z + side * door_width * 0.5),
				frame_material,
				"CorridorDoorFrame"
			)
		_add_corridor_mullion(
			corridor,
			Vector3(0.16, 0.16, door_width + 0.16),
			Vector3(wall_x, floor_height + door_frame_height, door_center_z),
			frame_material,
			"CorridorDoorFrame"
		)

		var corridor_floor := MeshInstance3D.new()
		corridor_floor.name = "CorridorFloor_Floor_%02d" % (floor_index + 1)
		var corridor_floor_mesh := BoxMesh.new()
		corridor_floor_mesh.size = Vector3(3.2, 0.08, 12.4)
		corridor_floor.mesh = corridor_floor_mesh
		corridor_floor.material_override = floor_material
		corridor_floor.position = Vector3(wall_x + 1.9, floor_height + 0.44, door_center_z)
		corridor.add_child(corridor_floor)
		panel_bottom = floor_height + door_height

	if wall_top > panel_bottom:
		var panel_height := wall_top - panel_bottom
		_add_partition_panel(
			wall_body,
			Vector3(wall_size.x, panel_height, door_width),
			Vector3(0.0, panel_bottom + panel_height * 0.5 - wall_body.position.y, 0.0),
			glass_material,
			"PrivacyWallTop"
		)

	var outer_wall := StaticBody3D.new()
	outer_wall.name = "CorridorOuterGlassWall"
	outer_wall.collision_layer = 1
	outer_wall.collision_mask = 1 | 2
	outer_wall.position = Vector3(wall_x + 3.6, (floor_two_height + wall_top) * 0.5, door_center_z)
	corridor.add_child(outer_wall)
	_add_partition_panel(outer_wall, Vector3(0.12, wall_height, wall_size.z), Vector3.ZERO, glass_material, "CorridorOuterGlassPanel")
	for mullion_index in range(5):
		var mullion_z := -wall_size.z * 0.5 + float(mullion_index) * wall_size.z / 4.0
		_add_corridor_mullion(
			outer_wall,
			Vector3(0.16, wall_height, 0.16),
			Vector3(0.0, 0.0, mullion_z),
			frame_material,
			"CorridorOuterMullion"
		)
	for floor_index in range(1, FLOOR_HEIGHTS.size()):
		var floor_height: float = FLOOR_HEIGHTS[floor_index]
		for stripe_offset in [1.0, 1.22]:
			_add_corridor_mullion(
				outer_wall,
				Vector3(0.035, 0.12, wall_size.z),
				Vector3(0.0, floor_height + stripe_offset - outer_wall.position.y, 0.0),
				frame_material,
				"CorridorOuterFrostedStripe"
			)

static func _add_corridor_mullion(parent: Node3D, size: Vector3, position: Vector3, material: Material, mullion_name: String) -> void:
	var mullion := MeshInstance3D.new()
	mullion.name = mullion_name
	var mullion_mesh := BoxMesh.new()
	mullion_mesh.size = size
	mullion.mesh = mullion_mesh
	mullion.material_override = material
	mullion.position = position
	parent.add_child(mullion)

static func _add_partition_panel(parent: StaticBody3D, size: Vector3, position: Vector3, material: Material, panel_name: String) -> void:
	var panel := MeshInstance3D.new()
	panel.name = panel_name
	var panel_mesh := BoxMesh.new()
	panel_mesh.size = size
	panel.mesh = panel_mesh
	panel.material_override = material
	panel.position = position
	parent.add_child(panel)

	var panel_collision := CollisionShape3D.new()
	panel_collision.name = "%sCollision" % panel_name
	var panel_shape := BoxShape3D.new()
	panel_shape.size = size
	panel_collision.shape = panel_shape
	panel_collision.position = position
	parent.add_child(panel_collision)

static func _add_ground_facade_wall(parent: Node3D, side_name: String, along_start: float, along_end: float, wall_height: float, material: Material) -> void:
	var length := along_end - along_start
	var horizontal_axis := side_name == "South" or side_name == "North"
	var along_center := (along_start + along_end) * 0.5
	var wall_position := Vector3.ZERO
	var wall_size := Vector3(length, wall_height, 0.4) if horizontal_axis else Vector3(0.4, wall_height, length)
	if horizontal_axis:
		wall_position = Vector3(along_center, wall_height * 0.5, 18.0 if side_name == "South" else -18.0)
	else:
		wall_position = Vector3(18.0 if side_name == "East" else -18.0, wall_height * 0.5, along_center)

	var wall := MeshInstance3D.new()
	wall.name = "%sWallSegment" % side_name
	var wall_mesh := BoxMesh.new()
	wall_mesh.size = wall_size
	wall.mesh = wall_mesh
	wall.material_override = material
	wall.position = wall_position
	parent.add_child(wall)
	_add_box_col(parent, wall_size, wall_position)

# ------------------------------------------------------------------------------
# HÀM TẠO VƯỜN TREO TRÊN KHÔNG (SKY GARDENS)
# ------------------------------------------------------------------------------
static func _add_sky_garden(floor_node: Node3D, side_dir: Vector3, width: float, depth: float, mat_floor: Material, mat_gold: Material) -> void:
	var garden = Node3D.new()
	garden.name = "SkyGarden"
	garden.position = side_dir * (18.0 + depth * 0.5)
	floor_node.add_child(garden)

	# Sàn ban công vườn treo nhô ra ngoài
	var f_size = Vector3(width, 0.4, depth) if side_dir.z != 0 else Vector3(depth, 0.4, width)
	var f_inst = MeshInstance3D.new()
	var f_box = BoxMesh.new()
	f_box.size = f_size
	f_inst.mesh = f_box
	f_inst.material_override = mat_floor
	garden.add_child(f_inst)
	_add_box_col(garden, f_size, Vector3.ZERO)

	# Lan can mạ vàng Toon
	var rail_inst = MeshInstance3D.new()
	var r_box = BoxMesh.new()
	r_box.size = Vector3(width, 1.1, 0.1) if side_dir.z != 0 else Vector3(0.1, 1.1, width)
	rail_inst.mesh = r_box
	rail_inst.material_override = mat_gold
	var r_pos = Vector3(0, 0.65, depth * 0.45 * sign(side_dir.z)) if side_dir.z != 0 else Vector3(depth * 0.45 * sign(side_dir.x), 0.65, 0)
	rail_inst.position = r_pos
	garden.add_child(rail_inst)

	# Cây cảnh Anime và chậu hoa Ghibli
	var mat_plant = _create_material(Color(0.2, 0.68, 0.3), 0.8)
	for p in [-width * 0.32, 0.0, width * 0.32]:
		var pot = MeshInstance3D.new()
		var p_mesh = CylinderMesh.new()
		p_mesh.top_radius = 0.5
		p_mesh.bottom_radius = 0.35
		p_mesh.height = 0.7
		pot.mesh = p_mesh
		pot.material_override = mat_gold
		var pot_p = Vector3(p, 0.55, 0.0) if side_dir.z != 0 else Vector3(0.0, 0.55, p)
		pot.position = pot_p
		garden.add_child(pot)

		var bush = MeshInstance3D.new()
		var b_mesh = SphereMesh.new()
		b_mesh.radius = 0.65
		b_mesh.height = 0.9
		bush.mesh = b_mesh
		bush.material_override = mat_plant
		bush.position = pot_p + Vector3(0, 0.65, 0)
		garden.add_child(bush)

# ------------------------------------------------------------------------------
# HÀM TẠO MỘT ĐOẠN CẦU THANG BỘ THÔNG TẦNG
# ------------------------------------------------------------------------------
static func _build_staircase_flight(parent: Node3D, y_start: float, y_end: float, mat_step: Material, mat_rail: Material, starting_flight_index: int) -> int:
	var h_diff = y_end - y_start
	var stair_node = Node3D.new()
	stair_node.name = "Stairs_From_%.0f_To_%.0f" % [y_start, y_end]
	stair_node.position.y = y_start + 0.4
	parent.add_child(stair_node)

	var flight_count = maxi(1, ceili(h_diff / 2.8))
	var flight_rise = h_diff / float(flight_count)
	var flight_run = 4.8
	var flight_width = 5.6
	var lane_offset = flight_width
	var landing_width = lane_offset + flight_width + 0.2
	var landing_depth = 4.0
	var rail_height = 1.1
	var step_count = maxi(1, ceili(flight_rise / 0.18))
	var step_height = flight_rise / float(step_count)
	var step_depth = flight_run / float(step_count)

	if starting_flight_index == 0:
		var entry_landing = MeshInstance3D.new()
		entry_landing.name = "StairEntryLanding"
		var entry_size = Vector3(flight_width + 0.2, 0.3, landing_depth)
		var entry_mesh = BoxMesh.new()
		entry_mesh.size = entry_size
		entry_landing.mesh = entry_mesh
		entry_landing.material_override = mat_rail
		entry_landing.position = Vector3(0.0, -0.15, -2.0)
		stair_node.add_child(entry_landing)
		_add_box_col(stair_node, entry_size, entry_landing.position)
		_add_stair_landing_rails(stair_node, entry_landing.position, entry_size, mat_rail, 0)

	for flight_index in range(flight_count):
		var absolute_flight_index = starting_flight_index + flight_index
		var direction = 1.0 if absolute_flight_index % 2 == 0 else -1.0
		var flight_x = 0.0 if absolute_flight_index % 2 == 0 else lane_offset
		var flight_z = 0.0 if direction > 0.0 else flight_run
		var flight_y = float(flight_index) * flight_rise
		var ramp_angle = -atan2(flight_rise, flight_run) * direction
		var ramp_length = sqrt(flight_rise * flight_rise + flight_run * flight_run)
		for step_index in range(step_count):
			var step = MeshInstance3D.new()
			step.name = "Tread_%02d" % (step_index + 1)
			var step_mesh = BoxMesh.new()
			step_mesh.size = Vector3(flight_width - 0.2, maxf(0.12, step_height), step_depth + 0.05)
			step.mesh = step_mesh
			step.material_override = mat_step
			step.position = Vector3(flight_x, flight_y + float(step_index) * step_height + step_height * 0.5, flight_z + direction * (float(step_index) + 0.5) * step_depth)
			stair_node.add_child(step)

		var ramp_body = StaticBody3D.new()
		ramp_body.name = "StairRampCollider" if flight_index == 0 else "StairRampCollider_%02d" % (flight_index + 1)
		ramp_body.collision_layer = 1
		ramp_body.collision_mask = 1 | 2
		var ramp_collision = CollisionShape3D.new()
		var ramp_shape = BoxShape3D.new()
		ramp_shape.size = Vector3(flight_width, 0.22, ramp_length)
		ramp_collision.shape = ramp_shape
		ramp_collision.rotation.x = ramp_angle
		ramp_collision.position = Vector3(flight_x, flight_y + flight_rise * 0.5, flight_z + direction * flight_run * 0.5)
		ramp_body.add_child(ramp_collision)
		stair_node.add_child(ramp_body)

		for side in [-1.0, 1.0]:
			var rail = MeshInstance3D.new()
			rail.name = "StairGuardrail_%02d_%s" % [absolute_flight_index + 1, "L" if side < 0.0 else "R"]
			var rail_size = Vector3(0.14, rail_height, ramp_length)
			var rail_mesh = BoxMesh.new()
			rail_mesh.size = rail_size
			rail.mesh = rail_mesh
			rail.material_override = mat_rail
			rail.position = Vector3(
				flight_x + side * (flight_width * 0.5 - rail_size.x * 0.5),
				flight_y + flight_rise * 0.5 + rail_height * 0.5,
				flight_z + direction * flight_run * 0.5
			)
			rail.rotation.x = ramp_angle
			stair_node.add_child(rail)

			var rail_body = StaticBody3D.new()
			rail_body.name = "StairGuardrailCollision_%02d_%s" % [absolute_flight_index + 1, "L" if side < 0.0 else "R"]
			rail_body.collision_layer = 1
			rail_body.collision_mask = 1 | 2
			var rail_collision = CollisionShape3D.new()
			var rail_shape = BoxShape3D.new()
			rail_shape.size = rail_size
			rail_collision.shape = rail_shape
			rail_collision.position = rail.position
			rail_collision.rotation.x = ramp_angle
			rail_body.add_child(rail_collision)
			stair_node.add_child(rail_body)

		var landing = MeshInstance3D.new()
		landing.name = "StairLanding_%02d" % (absolute_flight_index + 1)
		var landing_size = Vector3(landing_width, 0.3, landing_depth)
		var landing_mesh = BoxMesh.new()
		landing_mesh.size = landing_size
		landing.mesh = landing_mesh
		landing.material_override = mat_rail
		var next_flight_x = 0.0 if (absolute_flight_index + 1) % 2 == 0 else lane_offset
		var landing_x = (flight_x + next_flight_x) * 0.5
		landing.position = Vector3(landing_x, flight_y + flight_rise - 0.15, flight_z + direction * flight_run)
		stair_node.add_child(landing)
		_add_box_col(stair_node, landing_size, landing.position)
		_add_stair_landing_rails(stair_node, landing.position, landing_size, mat_rail, absolute_flight_index + 1)
	return flight_count

static func _add_stair_landing_rails(parent: Node3D, landing_position: Vector3, landing_size: Vector3, material: Material, landing_index: int) -> void:
	var rail_size = Vector3(0.14, 1.1, landing_size.z)
	for side in [-1.0, 1.0]:
		var rail_position = landing_position + Vector3(side * (landing_size.x * 0.5 - rail_size.x * 0.5), 0.7, 0.0)
		var rail = MeshInstance3D.new()
		rail.name = "StairLandingGuardrail_%02d_%s" % [landing_index, "L" if side < 0.0 else "R"]
		var rail_mesh = BoxMesh.new()
		rail_mesh.size = rail_size
		rail.mesh = rail_mesh
		rail.material_override = material
		rail.position = rail_position
		parent.add_child(rail)

		var rail_body = StaticBody3D.new()
		rail_body.name = "StairLandingGuardrailCollision_%02d_%s" % [landing_index, "L" if side < 0.0 else "R"]
		rail_body.collision_layer = 1
		rail_body.collision_mask = 1 | 2
		var rail_collision = CollisionShape3D.new()
		var rail_shape = BoxShape3D.new()
		rail_shape.size = rail_size
		rail_collision.shape = rail_shape
		rail_collision.position = rail_position
		rail_body.add_child(rail_collision)
		parent.add_child(rail_body)

# ------------------------------------------------------------------------------
# HÀM TẠO BÀN LÀM VIỆC & TRẠM TƯƠNG TÁC
# ------------------------------------------------------------------------------
static func _add_desk_station(parent: Node3D, obj_name: String, pos: Vector3, st_id: String, title: String, prompt: String, mat_desk: Material, mat_border: Material, mat_holo: Material) -> InteractiveStation:
	var desk_node = Node3D.new()
	desk_node.name = obj_name
	desk_node.position = pos
	parent.add_child(desk_node)

	# Mặt bàn gỗ
	var top = MeshInstance3D.new()
	var top_box = BoxMesh.new()
	top_box.size = Vector3(3.2, 0.12, 1.6)
	top.mesh = top_box
	top.material_override = mat_desk
	top.position = Vector3(0.0, 0.76, 0.0)
	desk_node.add_child(top)
	_add_box_col(desk_node, Vector3(3.2, 0.12, 1.6), Vector3(0.0, 0.76, 0.0))

	# 4 Chân bàn
	for dx in [-1.4, 1.4]:
		for dz in [-0.65, 0.65]:
			var leg = MeshInstance3D.new()
			var l_cyl = CylinderMesh.new()
			l_cyl.top_radius = 0.05
			l_cyl.bottom_radius = 0.05
			l_cyl.height = 0.76
			leg.mesh = l_cyl
			leg.material_override = mat_border
			leg.position = Vector3(dx, 0.38, dz)
			desk_node.add_child(leg)

	# Màn hình máy tính phát sáng
	var screen = MeshInstance3D.new()
	var scr_box = BoxMesh.new()
	scr_box.size = Vector3(0.9, 0.55, 0.06)
	screen.mesh = scr_box
	screen.material_override = mat_holo
	screen.position = Vector3(0.0, 1.15, -0.4)
	desk_node.add_child(screen)

	# Trạm tương tác [E]
	var st = InteractiveStation.new()
	st.name = "Station_" + st_id
	st.station_type = InteractiveStation.StationType.DESK
	st.station_id = st_id
	st.title_name = title
	st.prompt_text = prompt
	st.interaction_radius = 6.5
	st.position = Vector3(0.0, 0.1, 0.8)
	desk_node.add_child(st)

	return st

# ------------------------------------------------------------------------------
# HÀM TẠO NHÂN VẬT ANIME LÀM VIỆC CÓ BIỂN CHỨC DANH
# ------------------------------------------------------------------------------
static func _add_worker_npc(parent: Node3D, npc_name: String, pos: Vector3, prof: ModularHumanoidBuilder.ProfessionType, job_title: String, gender: String = "Nam") -> Node3D:
	var npc_root = Node3D.new()
	npc_root.name = "NPC_" + npc_name
	npc_root.position = pos
	parent.add_child(npc_root)

	var model = ModularHumanoidBuilderScript.build_character_model(prof, ModularHumanoidBuilderScript.AgeGroup.ADULT, gender)
	npc_root.add_child(model)

	var title_label = _create_label3d("👤 " + npc_name + "\n[" + job_title + "]", Color(0.3, 0.9, 1.0), 18)
	title_label.position = Vector3(0.0, 2.2, 0.0)
	npc_root.add_child(title_label)

	return npc_root

# ------------------------------------------------------------------------------
# TIỆN ÍCH TẠO MATERIAL & COLLIDER
# ------------------------------------------------------------------------------
static func _create_material(color: Color, roughness: float = 0.5) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	return m

static func _create_glass_material(color: Color) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = color
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.metallic = 0.35
	m.roughness = 0.08
	return m

static func _create_metal_material(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = roughness
	return m

static func _create_emission_material(albedo: Color, emit_col: Color, energy: float) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = albedo
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.emission_enabled = true
	m.emission = emit_col
	m.emission_energy_multiplier = energy
	return m

static func _create_label3d(text: String, modulate: Color, font_size: int = 24) -> Label3D:
	var lbl = Label3D.new()
	lbl.text = text
	lbl.font_size = font_size
	lbl.outline_size = 8
	lbl.outline_modulate = Color(0.05, 0.08, 0.14, 0.95)
	lbl.modulate = modulate
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.no_depth_test = true
	return lbl

static func _add_box_col(parent: Node3D, size: Vector3, pos: Vector3) -> StaticBody3D:
	var sb = StaticBody3D.new()
	sb.collision_layer = 1
	sb.collision_mask = 1 | 2
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = size
	col.shape = box
	col.position = pos
	sb.add_child(col)
	parent.add_child(sb)
	return sb

static func _add_cylinder_col(parent: Node3D, radius: float, height: float, pos: Vector3) -> StaticBody3D:
	var sb = StaticBody3D.new()
	sb.collision_layer = 1
	sb.collision_mask = 1 | 2
	var col = CollisionShape3D.new()
	var cyl = CylinderShape3D.new()
	cyl.radius = radius
	cyl.height = height
	col.shape = cyl
	col.position = pos
	sb.add_child(col)
	parent.add_child(sb)
	return sb
