class_name ModelHouseBuilder
extends RefCounted

# ==============================================================================
# MODEL HOUSE BUILDER - BỘ XÂY DỰNG NHÀ MẪU & KIẾN TRÚC DÂN CƯ 3D TÂN THẾ GIỚI
# Khởi tạo kiến trúc 3D Anime Cel-shaded hoàn chỉnh theo 4 hình thức nhà ở:
# 1. STUDIO_APARTMENT: Chung Cư Studio Anime (Cư dân độc thân, ban công hoa)
# 2. CO_LIVING_HOUSE: Nhà Chung & Ký Túc Xá Co-Living (2 tầng, sinh viên/bạn trẻ)
# 3. FAMILY_RESIDENCE: Căn Hộ Gia Đình Tiện Nghi (Mái thái cam, gara xe buggy)
# 4. GARDEN_COTTAGE: Biệt Thự Nhà Vườn Ghibli (Hàng rào trắng, hoa hướng dương)
# ==============================================================================

# ------------------------------------------------------------------------------
# HỆ THỐNG VẬT LIỆU CHUẨN ANIME TOON CEL-SHADED
# ------------------------------------------------------------------------------
static func _get_mat(color: Color, roughness: float = 0.8, metallic: float = 0.0, emission: Color = Color.BLACK, emission_energy: float = 0.0) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = metallic
	if emission != Color.BLACK and emission_energy > 0.0:
		mat.emission_enabled = true
		mat.emission = emission
		mat.emission_energy_multiplier = emission_energy
	return mat

# ------------------------------------------------------------------------------
# 1. GIAI ĐOẠN LÔ ĐẤT QUY HOẠCH & BLUEPRINT HOLOGRAM (STATUS_AVAILABLE)
# ------------------------------------------------------------------------------
static func build_plot_blueprint(house_type: String, area_sqm: float) -> Node3D:
	var root = Node3D.new()
	root.name = "PlotBlueprintState"

	var mat_peg = _get_mat(Color(0.85, 0.45, 0.2)) # Cọc gỗ đỏ cam
	var mat_ribbon = _get_mat(Color(0.95, 0.85, 0.2, 0.9), 0.3, 0.1, Color(0.95, 0.85, 0.2), 1.5)
	var mat_base = _get_mat(Color(0.55, 0.65, 0.45), 0.9)
	var mat_holo = StandardMaterial3D.new()
	mat_holo.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_holo.albedo_color = Color(0.35, 0.75, 1.0, 0.4)
	mat_holo.emission_enabled = true
	mat_holo.emission = Color(0.35, 0.75, 1.0)
	mat_holo.emission_energy_multiplier = 0.8
	mat_holo.cull_mode = BaseMaterial3D.CULL_DISABLED

	var w: float = 12.0
	var d: float = 10.0
	if house_type == "STUDIO_APARTMENT":
		w = 10.0; d = 8.0
	elif house_type == "CO_LIVING_HOUSE":
		w = 14.0; d = 10.0
	elif house_type == "FAMILY_RESIDENCE":
		w = 16.0; d = 12.0
	elif house_type == "GARDEN_COTTAGE":
		w = 18.0; d = 14.0
	elif house_type == "ALPINE_PINE_CABIN":
		w = 12.0; d = 10.0
	elif house_type == "HIGHLAND_STONE_COTTAGE":
		w = 13.0; d = 11.0
	elif house_type == "LAKESIDE_STILT_HOUSE":
		w = 14.0; d = 12.0
	elif house_type == "PRAIRIE_FARMSTEAD":
		w = 17.0; d = 13.0
	elif house_type == "VALLEY_WINDMILL_LOFT":
		w = 11.0; d = 11.0
	elif house_type == "COASTAL_VILLA":
		w = 18.0; d = 15.0

	# 1. Nền móng san phẳng quy hoạch
	var ground = _create_box_collider("PlotGround", Vector3(w + 2.0, 0.25, d + 2.0), mat_base)
	ground.position.y = 0.125
	root.add_child(ground)

	# 2. Bốn cọc mốc gỗ đo đạc tại 4 góc
	var half_w = w * 0.5 + 0.8
	var half_d = d * 0.5 + 0.8
	var corners = [
		Vector3(-half_w, 0, -half_d),
		Vector3(half_w, 0, -half_d),
		Vector3(-half_w, 0, half_d),
		Vector3(half_w, 0, half_d)
	]
	for c_pos in corners:
		var peg = MeshInstance3D.new()
		var peg_mesh = CylinderMesh.new()
		peg_mesh.top_radius = 0.08
		peg_mesh.bottom_radius = 0.08
		peg_mesh.height = 1.2
		peg.mesh = peg_mesh
		peg.material_override = mat_peg
		peg.position = c_pos + Vector3(0, 0.6, 0)
		root.add_child(peg)

	# 3. Ruy băng viền ranh giới phát sáng
	var ribbon = MeshInstance3D.new()
	var ribbon_mesh = BoxMesh.new()
	ribbon_mesh.size = Vector3(w + 1.6, 0.1, d + 1.6)
	ribbon.mesh = ribbon_mesh
	ribbon.material_override = mat_ribbon
	ribbon.position.y = 0.4
	root.add_child(ribbon)

	# 4. Mô hình Hologram Blueprint thu nhỏ nhấp nháy Toon
	var holo_preview = Node3D.new()
	holo_preview.name = "HoloPreview"
	holo_preview.position = Vector3(0, 1.8, 0)

	var holo_body = MeshInstance3D.new()
	var h_box = BoxMesh.new()
	h_box.size = Vector3(w * 0.7, 3.2, d * 0.7)
	holo_body.mesh = h_box
	holo_body.material_override = mat_holo
	holo_preview.add_child(holo_body)

	var holo_roof = MeshInstance3D.new()
	var r_prism = PrismMesh.new()
	r_prism.size = Vector3(w * 0.75, 2.0, d * 0.75)
	holo_roof.mesh = r_prism
	holo_roof.material_override = mat_holo
	holo_roof.position.y = 2.4
	holo_preview.add_child(holo_roof)

	root.add_child(holo_preview)
	return root

# ------------------------------------------------------------------------------
# 2. GIAI ĐOẠN THI CÔNG XÂY DỰNG (STATUS_CONSTRUCTION)
# ------------------------------------------------------------------------------
static func build_construction_site(house_type: String, area_sqm: float) -> Node3D:
	var root = Node3D.new()
	root.name = "PlotConstructionState"

	var mat_concrete = _get_mat(Color(0.72, 0.72, 0.74), 0.9)
	var mat_timber = _get_mat(Color(0.68, 0.48, 0.28), 0.8)
	var mat_brick = _get_mat(Color(0.78, 0.32, 0.22), 0.9)
	var mat_scaffold = _get_mat(Color(0.52, 0.54, 0.58), 0.5, 0.6) # Khung kim loại
	var mat_tarp = _get_mat(Color(0.18, 0.45, 0.78), 0.6) # Bạt xanh công trường

	# 1. Nền móng bê tông đúc sẵn
	var slab = _create_box_collider("FoundationSlab", Vector3(12.0, 0.45, 10.0), mat_concrete)
	slab.position.y = 0.225
	root.add_child(slab)

	# 2. Hệ giàn giáo & xà gồ gỗ đang dựng
	for x in [-5.0, 5.0]:
		for z in [-4.0, 4.0]:
			var post = MeshInstance3D.new()
			var p_mesh = CylinderMesh.new()
			p_mesh.top_radius = 0.12
			p_mesh.bottom_radius = 0.12
			p_mesh.height = 5.5
			post.mesh = p_mesh
			post.material_override = mat_scaffold
			post.position = Vector3(x, 2.75, z)
			root.add_child(post)

	# Thanh ngang giàn giáo
	var crossbar = MeshInstance3D.new()
	var c_mesh = BoxMesh.new()
	c_mesh.size = Vector3(10.2, 0.12, 0.12)
	crossbar.mesh = c_mesh
	crossbar.material_override = mat_scaffold
	crossbar.position = Vector3(0, 3.2, 4.0)
	root.add_child(crossbar)

	# 3. Khung xà gỗ kết cấu nhà
	for fx in [-3.5, 0.0, 3.5]:
		var frame = MeshInstance3D.new()
		var f_mesh = BoxMesh.new()
		f_mesh.size = Vector3(0.3, 4.0, 0.3)
		frame.mesh = f_mesh
		frame.material_override = mat_timber
		frame.position = Vector3(fx, 2.0, 0.0)
		root.add_child(frame)

	# 4. Đống gạch đỏ và kiện gỗ tập kết
	var brick_pile = MeshInstance3D.new()
	var b_box = BoxMesh.new()
	b_box.size = Vector3(1.8, 1.2, 1.4)
	brick_pile.mesh = b_box
	brick_pile.material_override = mat_brick
	brick_pile.position = Vector3(4.5, 0.6, -3.2)
	root.add_child(brick_pile)

	# 5. Tấm bạt xanh công trình vắt ngang
	var tarp = MeshInstance3D.new()
	var t_box = BoxMesh.new()
	t_box.size = Vector3(4.5, 0.1, 3.0)
	tarp.mesh = t_box
	tarp.material_override = mat_tarp
	tarp.position = Vector3(-2.5, 3.3, 2.0)
	tarp.rotation.z = deg_to_rad(-15.0)
	root.add_child(tarp)

	# 6. Thợ Mộc Đô Thị (Artisan Carpenter NPC) đang thi công
	var carpenter = Node3D.new()
	carpenter.name = "CarpenterArtisan"
	carpenter.position = Vector3(1.5, 0.45, 1.0)
	
	var mat_overalls = _get_mat(Color(0.22, 0.45, 0.75)) # Quần yếm xanh
	var mat_helmet = _get_mat(Color(0.98, 0.82, 0.15))   # Mũ bảo hộ vàng
	var mat_skin = _get_mat(Color(0.96, 0.82, 0.72))     # Da anime
	var mat_iron = _get_mat(Color(0.40, 0.42, 0.45), 0.3, 0.8) # Búa sắt

	var body_mesh = MeshInstance3D.new()
	var b_cyl = CylinderMesh.new()
	b_cyl.top_radius = 0.28
	b_cyl.bottom_radius = 0.32
	b_cyl.height = 1.1
	body_mesh.mesh = b_cyl
	body_mesh.material_override = mat_overalls
	body_mesh.position.y = 0.55
	carpenter.add_child(body_mesh)

	var head_mesh = MeshInstance3D.new()
	var h_sph = SphereMesh.new()
	h_sph.radius = 0.22
	h_sph.height = 0.44
	head_mesh.mesh = h_sph
	head_mesh.material_override = mat_skin
	head_mesh.position.y = 1.25
	carpenter.add_child(head_mesh)

	var helmet_mesh = MeshInstance3D.new()
	var hm = SphereMesh.new()
	hm.radius = 0.25
	hm.height = 0.25
	helmet_mesh.mesh = hm
	helmet_mesh.material_override = mat_helmet
	helmet_mesh.position.y = 1.38
	carpenter.add_child(helmet_mesh)

	var hammer_arm = Node3D.new()
	hammer_arm.name = "HammerArm"
	hammer_arm.position = Vector3(0.35, 0.9, 0.2)
	
	var hammer_head = MeshInstance3D.new()
	var hh_box = BoxMesh.new()
	hh_box.size = Vector3(0.12, 0.12, 0.25)
	hammer_head.mesh = hh_box
	hammer_head.material_override = mat_iron
	hammer_head.position = Vector3(0, 0.15, 0.15)
	hammer_arm.add_child(hammer_head)
	carpenter.add_child(hammer_arm)

	# Bảng chữ 3D Diegetic thông báo thợ thi công
	var carp_label = Label3D.new()
	carp_label.text = "🔨 Thợ Mộc (CERT_CARPENTRY)\n[Đang Gõ Búa Thi Công]"
	carp_label.font_size = 24
	carp_label.outline_size = 6
	carp_label.outline_modulate = Color(0.06, 0.08, 0.14, 0.95)
	carp_label.modulate = Color(1.0, 0.88, 0.35)
	carp_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	carp_label.no_depth_test = true
	carp_label.position = Vector3(0, 1.85, 0)
	carpenter.add_child(carp_label)

	root.add_child(carpenter)

	return root

# ------------------------------------------------------------------------------
# 3. GIAI ĐOẠN NGÔI NHÀ HOÀN THIỆN 3D ANIME (STATUS_COMPLETED)
# ------------------------------------------------------------------------------
static func build_completed_house(house_type: String) -> Node3D:
	match house_type:
		"STUDIO_APARTMENT":
			return _build_studio_apartment()
		"CO_LIVING_HOUSE":
			return _build_co_living_house()
		"FAMILY_RESIDENCE":
			return _build_family_residence()
		"GARDEN_COTTAGE":
			return _build_garden_cottage()
		"ALPINE_PINE_CABIN":
			return _build_alpine_pine_cabin()
		"HIGHLAND_STONE_COTTAGE":
			return _build_highland_stone_cottage()
		"LAKESIDE_STILT_HOUSE":
			return _build_lakeside_stilt_house()
		"PRAIRIE_FARMSTEAD":
			return _build_prairie_farmstead()
		"VALLEY_WINDMILL_LOFT":
			return _build_valley_windmill_loft()
		"COASTAL_VILLA":
			return _build_coastal_villa()
		_:
			return _build_studio_apartment()

# ------------------------------------------------------------------------------
# MẪU 1: CHUNG CƯ STUDIO ANIME (10m x 8m) - Ban công hoa, mái ngói xanh biển
# ------------------------------------------------------------------------------
static func _build_studio_apartment() -> Node3D:
	var house = Node3D.new()
	house.name = "House_StudioApartment"

	var mat_wall = _get_mat(Color(0.96, 0.94, 0.90)) # Tường kem
	var mat_wood_trim = _get_mat(Color(0.55, 0.35, 0.22)) # Viền gỗ nâu
	var mat_base = _get_mat(Color(0.62, 0.58, 0.54)) # Móng đá
	var mat_roof = _get_mat(Color(0.22, 0.48, 0.78), 0.5) # Ngói gốm xanh biển
	var mat_glass = _get_mat(Color(0.65, 0.85, 0.98, 0.8), 0.1, 0.0, Color(0.65, 0.85, 0.98), 0.4)
	var mat_door = _get_mat(Color(0.42, 0.24, 0.15))
	var mat_flower = _get_mat(Color(0.95, 0.25, 0.35)) # Hoa phong lữ đỏ
	var mat_lamp = _get_mat(Color(1.0, 0.92, 0.7), 0.2, 0.0, Color(1.0, 0.92, 0.7), 3.0)

	# 1. Nền móng đá
	var base = _create_box_collider("StoneBase", Vector3(10.6, 0.4, 8.6), mat_base)
	base.position.y = 0.2
	house.add_child(base)

	# Bậc tam cấp trước cửa
	var step = _create_box_collider("EntranceStep", Vector3(2.4, 0.2, 1.2), mat_base)
	step.position = Vector3(0, 0.1, 4.8)
	house.add_child(step)

	# 2. Khối tường chính (10m x 4.2m x 8m)
	var body = _create_box_collider("HouseBody", Vector3(10.0, 4.2, 8.0), mat_wall)
	body.position.y = 2.3
	house.add_child(body)

	# Các cột gỗ viền góc Toon
	for x in [-5.05, 5.05]:
		for z in [-4.05, 4.05]:
			var pillar = MeshInstance3D.new()
			var p_box = BoxMesh.new()
			p_box.size = Vector3(0.4, 4.4, 0.4)
			pillar.mesh = p_box
			pillar.material_override = mat_wood_trim
			pillar.position = Vector3(x, 2.3, z)
			house.add_child(pillar)

	# 3. Mái dốc chữ A ngói xanh biển Toon
	var roof = MeshInstance3D.new()
	var r_mesh = PrismMesh.new()
	r_mesh.size = Vector3(10.8, 3.2, 8.8)
	roof.mesh = r_mesh
	roof.material_override = mat_roof
	roof.position = Vector3(0, 5.8, 0)
	house.add_child(roof)

	# Ống khói gạch
	var chimney = _create_box_collider("Chimney", Vector3(0.9, 2.4, 0.9), mat_base)
	chimney.position = Vector3(3.2, 6.4, -1.8)
	house.add_child(chimney)

	# 4. Ban công hoa phong lữ tầng gác lửng
	var balcony_floor = _create_box_collider("BalconyFloor", Vector3(3.6, 0.2, 1.4), mat_wood_trim)
	balcony_floor.position = Vector3(0, 3.2, 4.4)
	house.add_child(balcony_floor)

	var balcony_rail = MeshInstance3D.new()
	var rail_box = BoxMesh.new()
	rail_box.size = Vector3(3.6, 0.8, 0.1)
	balcony_rail.mesh = rail_box
	balcony_rail.material_override = mat_wood_trim
	balcony_rail.position = Vector3(0, 3.6, 5.05)
	house.add_child(balcony_rail)

	# Bồn hoa đỏ trên ban công
	var planter = MeshInstance3D.new()
	var pl_box = BoxMesh.new()
	pl_box.size = Vector3(3.4, 0.35, 0.3)
	planter.mesh = pl_box
	planter.material_override = mat_flower
	planter.position = Vector3(0, 3.7, 5.15)
	house.add_child(planter)

	# Cửa sổ gác lửng kính
	var attic_win = MeshInstance3D.new()
	var win_cyl = CylinderMesh.new()
	win_cyl.top_radius = 0.65
	win_cyl.bottom_radius = 0.65
	win_cyl.height = 0.1
	attic_win.mesh = win_cyl
	attic_win.material_override = mat_glass
	attic_win.position = Vector3(0, 5.2, 4.02)
	attic_win.rotation.x = deg_to_rad(90.0)
	house.add_child(attic_win)

	# 5. Cửa chính tương tác mở được (DoorHingePivot)
	var door_pivot = Node3D.new()
	door_pivot.name = "DoorHingePivot"
	door_pivot.position = Vector3(-0.6, 1.4, 4.02)

	var door_leaf = MeshInstance3D.new()
	var d_box = BoxMesh.new()
	d_box.size = Vector3(1.2, 2.4, 0.1)
	door_leaf.mesh = d_box
	door_leaf.material_override = mat_door
	door_leaf.position = Vector3(0.6, 0, 0)
	door_pivot.add_child(door_leaf)
	house.add_child(door_pivot)

	# Đèn hiên phát sáng ban đêm
	var porch_light = MeshInstance3D.new()
	var l_box = BoxMesh.new()
	l_box.size = Vector3(0.3, 0.4, 0.3)
	porch_light.mesh = l_box
	porch_light.material_override = mat_lamp
	porch_light.position = Vector3(1.1, 2.5, 4.2)
	house.add_child(porch_light)

	var p_light = OmniLight3D.new()
	p_light.light_color = Color(1.0, 0.92, 0.75)
	p_light.light_energy = 2.2
	p_light.omni_range = 8.0
	p_light.position = Vector3(1.1, 2.5, 4.4)
	house.add_child(p_light)

	# Hộp thư trước cổng
	var mailbox = MeshInstance3D.new()
	var mb_box = BoxMesh.new()
	mb_box.size = Vector3(0.4, 1.1, 0.4)
	mailbox.mesh = mb_box
	mailbox.material_override = mat_wood_trim
	mailbox.position = Vector3(2.5, 0.6, 5.0)
	house.add_child(mailbox)

	return house

# ------------------------------------------------------------------------------
# MẪU 2: NHÀ CHUNG & KÝ TÚC XÁ CO-LIVING (14m x 10m) - 2 Tầng, Mái ngói rêu, Đèn lồng
# ------------------------------------------------------------------------------
static func _build_co_living_house() -> Node3D:
	var house = Node3D.new()
	house.name = "House_CoLiving"

	var mat_stone = _get_mat(Color(0.64, 0.62, 0.58))
	var mat_wall_t1 = _get_mat(Color(0.92, 0.90, 0.85))
	var mat_wall_t2 = _get_mat(Color(0.58, 0.42, 0.28)) # Gỗ ấm tầng 2
	var mat_roof_moss = _get_mat(Color(0.32, 0.52, 0.35), 0.6) # Ngói xanh rêu
	var mat_wood_dark = _get_mat(Color(0.38, 0.25, 0.16))
	var mat_glass = _get_mat(Color(0.65, 0.85, 0.98, 0.8), 0.1, 0.0, Color(0.65, 0.85, 0.98), 0.4)
	var mat_lamp = _get_mat(Color(1.0, 0.88, 0.6), 0.2, 0.0, Color(1.0, 0.88, 0.6), 3.0)

	# 1. Nền móng & Sảnh hiên
	var base = _create_box_collider("BaseSlab", Vector3(14.8, 0.4, 10.8), mat_stone)
	base.position.y = 0.2
	house.add_child(base)

	# 2. Tầng 1: Phòng sinh hoạt chung & Bếp ăn (14m x 3.6m x 10m)
	var floor1 = _create_box_collider("Floor1Body", Vector3(14.0, 3.6, 10.0), mat_wall_t1)
	floor1.position.y = 2.0
	house.add_child(floor1)

	# 3. Tầng 2: Các phòng ngủ riêng biệt (12.4m x 3.4m x 8.8m)
	var floor2 = _create_box_collider("Floor2Body", Vector3(12.4, 3.4, 8.8), mat_wall_t2)
	floor2.position = Vector3(0, 5.5, 0)
	house.add_child(floor2)

	# 4. Ban công lớn tầng 2
	var balcony = _create_box_collider("UpperDeckBalcony", Vector3(7.0, 0.3, 1.8), mat_wood_dark)
	balcony.position = Vector3(0, 3.8, 5.2)
	house.add_child(balcony)

	var rail = MeshInstance3D.new()
	var rail_box = BoxMesh.new()
	rail_box.size = Vector3(7.0, 0.9, 0.1)
	rail.mesh = rail_box
	rail.material_override = mat_wood_dark
	rail.position = Vector3(0, 4.3, 6.05)
	house.add_child(rail)

	# 5. Mái ngói xanh rêu 2 chóp
	var roof = MeshInstance3D.new()
	var r_prism = PrismMesh.new()
	r_prism.size = Vector3(14.8, 3.6, 10.4)
	roof.mesh = r_prism
	roof.material_override = mat_roof_moss
	roof.position = Vector3(0, 8.5, 0)
	house.add_child(roof)

	# Ống khói đá đôi ở cạnh nhà
	var chimney = _create_box_collider("StoneChimney", Vector3(1.4, 5.5, 1.4), mat_stone)
	chimney.position = Vector3(-6.2, 5.8, -2.5)
	house.add_child(chimney)

	# 6. Sảnh hiên đón khách với 2 cột trụ gỗ
	for px in [-2.5, 2.5]:
		var col = MeshInstance3D.new()
		var col_mesh = CylinderMesh.new()
		col_mesh.top_radius = 0.2
		col_mesh.bottom_radius = 0.2
		col_mesh.height = 3.6
		col.mesh = col_mesh
		col.material_override = mat_wood_dark
		col.position = Vector3(px, 1.8, 5.6)
		house.add_child(col)

	# Ghế dài ngoài hiên
	var bench = _create_box_collider("PorchBench", Vector3(2.2, 0.5, 0.6), mat_wood_dark)
	bench.position = Vector3(-4.0, 0.5, 5.2)
	house.add_child(bench)

	# 7. Cửa chính 2 cánh trên DoorHingePivot
	var door_pivot = Node3D.new()
	door_pivot.name = "DoorHingePivot"
	door_pivot.position = Vector3(-0.9, 1.4, 5.02)

	var door_leaf = MeshInstance3D.new()
	var d_box = BoxMesh.new()
	d_box.size = Vector3(1.8, 2.6, 0.1)
	door_leaf.mesh = d_box
	door_leaf.material_override = mat_wood_dark
	door_leaf.position = Vector3(0.9, 0, 0)
	door_pivot.add_child(door_leaf)
	house.add_child(door_pivot)

	# 2 Đèn lồng treo ấm áp
	for lx in [-1.5, 1.5]:
		var lamp = MeshInstance3D.new()
		var l_cyl = CylinderMesh.new()
		l_cyl.top_radius = 0.2
		l_cyl.bottom_radius = 0.15
		l_cyl.height = 0.4
		lamp.mesh = l_cyl
		lamp.material_override = mat_lamp
		lamp.position = Vector3(lx, 2.6, 5.2)
		house.add_child(lamp)

	var lantern_light = OmniLight3D.new()
	lantern_light.light_color = Color(1.0, 0.88, 0.65)
	lantern_light.light_energy = 2.5
	lantern_light.omni_range = 10.0
	lantern_light.position = Vector3(0, 2.8, 5.4)
	house.add_child(lantern_light)

	return house

# ------------------------------------------------------------------------------
# MẪU 3: CĂN HỘ GIA ĐÌNH TIỆN NGHI (16m x 12m) - Mái ngói cam, Gara Buggy
# ------------------------------------------------------------------------------
static func _build_family_residence() -> Node3D:
	var house = Node3D.new()
	house.name = "House_FamilyResidence"

	var mat_wall = _get_mat(Color(0.95, 0.95, 0.93))
	var mat_brick = _get_mat(Color(0.52, 0.48, 0.45))
	var mat_roof_terracotta = _get_mat(Color(0.85, 0.38, 0.18), 0.6) # Ngói cam
	var mat_glass = _get_mat(Color(0.65, 0.88, 0.98, 0.75), 0.1, 0.0, Color(0.65, 0.88, 0.98), 0.5)
	var mat_wood = _get_mat(Color(0.48, 0.32, 0.20))
	var mat_pergola = _get_mat(Color(0.35, 0.35, 0.38))

	# 1. Nền móng nhà giật cấp
	var base = _create_box_collider("BaseMain", Vector3(16.6, 0.4, 12.6), mat_brick)
	base.position.y = 0.2
	house.add_child(base)

	# 2. Gian nhà chính (11m x 5.8m x 10m)
	var main_body = _create_box_collider("MainVillaBody", Vector3(11.0, 5.8, 10.0), mat_wall)
	main_body.position = Vector3(-2.0, 3.1, 0)
	house.add_child(main_body)

	# 3. Gian phụ Gara Buggy có mái kính bên hông (5m x 3.6m x 8m)
	var garage = _create_box_collider("GarageCover", Vector3(5.0, 3.2, 8.0), mat_wall)
	garage.position = Vector3(5.5, 1.8, -0.5)
	house.add_child(garage)

	# Giàn che kính gara xe buggy
	var pergola = MeshInstance3D.new()
	var p_box = BoxMesh.new()
	p_box.size = Vector3(5.2, 0.15, 8.2)
	pergola.mesh = p_box
	pergola.material_override = mat_glass
	pergola.position = Vector3(5.5, 3.45, -0.5)
	house.add_child(pergola)

	# 4. Mái ngói cam kiểu Thái giật cấp
	var roof_main = MeshInstance3D.new()
	var rm_mesh = PrismMesh.new()
	rm_mesh.size = Vector3(11.8, 3.6, 10.6)
	roof_main.mesh = rm_mesh
	roof_main.material_override = mat_roof_terracotta
	roof_main.position = Vector3(-2.0, 7.6, 0)
	house.add_child(roof_main)

	# Ống khói đá đỏ
	var chimney = _create_box_collider("VillaChimney", Vector3(1.1, 3.8, 1.1), mat_brick)
	chimney.position = Vector3(-5.5, 7.5, -2.5)
	house.add_child(chimney)

	# 5. Cửa sổ kính lớn tràn góc
	var big_window = MeshInstance3D.new()
	var bw_mesh = BoxMesh.new()
	bw_mesh.size = Vector3(4.5, 2.2, 0.15)
	big_window.mesh = bw_mesh
	big_window.material_override = mat_glass
	big_window.position = Vector3(-2.0, 4.2, 5.05)
	house.add_child(big_window)

	# 6. Cửa chính có tay nắm đồng trên DoorHingePivot
	var door_pivot = Node3D.new()
	door_pivot.name = "DoorHingePivot"
	door_pivot.position = Vector3(-3.2, 1.4, 5.02)

	var door_leaf = MeshInstance3D.new()
	var d_box = BoxMesh.new()
	d_box.size = Vector3(1.4, 2.6, 0.1)
	door_leaf.mesh = d_box
	door_leaf.material_override = mat_wood
	door_leaf.position = Vector3(0.7, 0, 0)
	door_pivot.add_child(door_leaf)
	house.add_child(door_pivot)

	# Đèn hiên hiện đại
	var porch_light = OmniLight3D.new()
	porch_light.light_color = Color(1.0, 0.95, 0.8)
	porch_light.light_energy = 2.4
	porch_light.omni_range = 9.0
	porch_light.position = Vector3(-2.0, 2.8, 5.5)
	house.add_child(porch_light)

	return house

# ------------------------------------------------------------------------------
# MẪU 4: BIỆT THỰ NHÀ VƯỜN GHIBLI (18m x 14m) - Hàng rào trắng, Hoa hướng dương, Xích đu
# ------------------------------------------------------------------------------
static func _build_garden_cottage() -> Node3D:
	var house = Node3D.new()
	house.name = "House_GardenCottage"

	var mat_wall = _get_mat(Color(0.94, 0.92, 0.86))
	var mat_timber = _get_mat(Color(0.52, 0.36, 0.22))
	var mat_roof_cottage = _get_mat(Color(0.36, 0.56, 0.34), 0.7) # Mái rêu xanh lá
	var mat_fence = _get_mat(Color(0.96, 0.96, 0.96), 0.6) # Hàng rào trắng muốt
	var mat_flower_yellow = _get_mat(Color(0.98, 0.82, 0.15)) # Hoa hướng dương
	var mat_flower_purple = _get_mat(Color(0.72, 0.35, 0.85)) # Giàn hoa leo tím
	var mat_stone = _get_mat(Color(0.65, 0.62, 0.58))
	var mat_wood = _get_mat(Color(0.44, 0.28, 0.16))

	# 1. Nền khuôn viên sân vườn (18m x 14m)
	var yard = _create_box_collider("YardBase", Vector3(18.0, 0.2, 14.0), _get_mat(Color(0.45, 0.72, 0.38)))
	yard.position.y = 0.1
	house.add_child(yard)

	# 2. Hàng rào gỗ trắng xinh xắn quanh sân
	var fence_segments = [
		Vector3(-8.8, 0.6, 0.0), Vector3(8.8, 0.6, 0.0), # Hai bên
		Vector3(0.0, 0.6, -6.8),                          # Phía sau
		Vector3(-5.0, 0.6, 6.8), Vector3(5.0, 0.6, 6.8)  # Phía trước (chừa cổng giữa)
	]
	for f_pos in fence_segments:
		var fence = MeshInstance3D.new()
		var fb = BoxMesh.new()
		if f_pos.z == 0.0:
			fb.size = Vector3(0.12, 0.9, 13.8)
		else:
			fb.size = Vector3(6.5, 0.9, 0.12)
		fence.mesh = fb
		fence.material_override = mat_fence
		fence.position = f_pos
		house.add_child(fence)

	# 3. Khối nhà chính Cottage (10m x 4.0m x 8m)
	var cottage_body = _create_box_collider("CottageBody", Vector3(10.0, 4.0, 8.0), mat_wall)
	cottage_body.position = Vector3(-2.5, 2.1, -1.5)
	house.add_child(cottage_body)

	# Mái ngói rêu duyên dáng
	var roof = MeshInstance3D.new()
	var r_mesh = PrismMesh.new()
	r_mesh.size = Vector3(10.8, 3.4, 8.8)
	roof.mesh = r_mesh
	roof.material_override = mat_roof_cottage
	roof.position = Vector3(-2.5, 5.6, -1.5)
	house.add_child(roof)

	# Ống khói gạch cổ điển
	var chimney = _create_box_collider("CottageChimney", Vector3(0.9, 2.8, 0.9), mat_stone)
	chimney.position = Vector3(1.2, 6.0, -3.2)
	house.add_child(chimney)

	# 4. Giàn hoa leo tím trên khung vòm gỗ trước cửa
	var trellis = MeshInstance3D.new()
	var tr_box = BoxMesh.new()
	tr_box.size = Vector3(3.2, 2.8, 1.8)
	trellis.mesh = tr_box
	trellis.material_override = mat_flower_purple
	trellis.position = Vector3(-2.5, 1.5, 3.2)
	house.add_child(trellis)

	# 5. Cửa chính mở trên DoorHingePivot
	var door_pivot = Node3D.new()
	door_pivot.name = "DoorHingePivot"
	door_pivot.position = Vector3(-3.1, 1.3, 2.52)

	var door_leaf = MeshInstance3D.new()
	var d_box = BoxMesh.new()
	d_box.size = Vector3(1.2, 2.2, 0.1)
	door_leaf.mesh = d_box
	door_leaf.material_override = mat_wood
	door_leaf.position = Vector3(0.6, 0, 0)
	door_pivot.add_child(door_leaf)
	house.add_child(door_pivot)

	# 6. Luống hoa hướng dương vàng rực rỡ ở góc sân
	for sx in [4.0, 5.2, 6.4]:
		for sz in [2.0, 3.5, 5.0]:
			var sun = MeshInstance3D.new()
			var sun_mesh = CylinderMesh.new()
			sun_mesh.top_radius = 0.35
			sun_mesh.bottom_radius = 0.05
			sun_mesh.height = 1.4
			sun.mesh = sun_mesh
			sun.material_override = mat_flower_yellow
			sun.position = Vector3(sx, 0.8, sz)
			house.add_child(sun)

	# 7. Xích đu gỗ dưới bóng cây
	var swing = _create_box_collider("GardenSwing", Vector3(2.4, 2.2, 1.2), mat_timber)
	swing.position = Vector3(5.5, 1.2, -2.5)
	house.add_child(swing)

	# Đèn lồng sân vườn ấm áp
	var garden_light = OmniLight3D.new()
	garden_light.light_color = Color(1.0, 0.90, 0.7)
	garden_light.light_energy = 2.2
	garden_light.omni_range = 9.0
	garden_light.position = Vector3(-2.5, 2.4, 3.5)
	house.add_child(garden_light)

	return house

# ------------------------------------------------------------------------------
# MẪU 5: NHÀ GỖ THÔNG ALPINE ĐỈNH VÁT (12m x 10m) - Gỗ Thông Tuyết, Mái Dốc Lớn, Ống Khói Đá
# ------------------------------------------------------------------------------
static func _build_alpine_pine_cabin() -> Node3D:
	var house = Node3D.new()
	house.name = "House_AlpinePineCabin"

	var mat_log = _get_mat(Color(0.58, 0.40, 0.22), 0.85)
	var mat_stone = _get_mat(Color(0.55, 0.55, 0.55), 0.9)
	var mat_roof_slate = _get_mat(Color(0.25, 0.22, 0.20), 0.6)
	var mat_glass = _get_mat(Color(0.65, 0.88, 0.98, 0.8), 0.1, 0.0, Color(0.65, 0.88, 0.98), 0.4)
	var mat_wood_dark = _get_mat(Color(0.38, 0.25, 0.16))
	var mat_lamp = _get_mat(Color(1.0, 0.88, 0.6), 0.2, 0.0, Color(1.0, 0.88, 0.6), 3.0)

	# 1. Móng đá granit sườn đồi
	var base = _create_box_collider("GraniteBase", Vector3(12.6, 0.5, 10.6), mat_stone)
	base.position.y = 0.25
	house.add_child(base)

	# 2. Khối thân nhà gỗ thông ghép mộng
	var body = _create_box_collider("LogCabinBody", Vector3(12.0, 4.2, 10.0), mat_log)
	body.position.y = 2.35
	house.add_child(body)

	# Các cọc thân gỗ tròn ở 4 góc
	for x in [-6.0, 6.0]:
		for z in [-5.0, 5.0]:
			var post = MeshInstance3D.new()
			var p_mesh = CylinderMesh.new()
			p_mesh.top_radius = 0.22
			p_mesh.bottom_radius = 0.22
			p_mesh.height = 4.4
			post.mesh = p_mesh
			post.material_override = mat_wood_dark
			post.position = Vector3(x, 2.35, z)
			house.add_child(post)

	# 3. Mái chữ A dốc tuyết Alpine
	var roof = MeshInstance3D.new()
	var r_prism = PrismMesh.new()
	r_prism.size = Vector3(13.2, 4.2, 11.2)
	roof.mesh = r_prism
	roof.material_override = mat_roof_slate
	roof.position = Vector3(0, 6.4, 0)
	house.add_child(roof)

	# Ống khói đá cuội lò sưởi
	var chimney = _create_box_collider("HearthChimney", Vector3(1.2, 4.0, 1.2), mat_stone)
	chimney.position = Vector3(3.8, 6.8, -2.5)
	house.add_child(chimney)

	# 4. Hiên gỗ ngắm rừng thông
	var deck = _create_box_collider("PineDeck", Vector3(5.0, 0.25, 2.0), mat_wood_dark)
	deck.position = Vector3(0, 0.35, 5.8)
	house.add_child(deck)

	# Lan can hiên gỗ
	var rail = MeshInstance3D.new()
	var rb = BoxMesh.new()
	rb.size = Vector3(5.0, 0.85, 0.12)
	rail.mesh = rb
	rail.material_override = mat_wood_dark
	rail.position = Vector3(0, 0.8, 6.75)
	house.add_child(rail)

	# 5. Cửa chính mở xoay trên DoorHingePivot
	var door_pivot = Node3D.new()
	door_pivot.name = "DoorHingePivot"
	door_pivot.position = Vector3(-0.7, 1.4, 5.02)

	var door_leaf = MeshInstance3D.new()
	var d_box = BoxMesh.new()
	d_box.size = Vector3(1.3, 2.5, 0.12)
	door_leaf.mesh = d_box
	door_leaf.material_override = mat_wood_dark
	door_leaf.position = Vector3(0.65, 0, 0)
	door_pivot.add_child(door_leaf)
	house.add_child(door_pivot)

	# Đèn hiên bão tuyết ấm áp
	var lamp = OmniLight3D.new()
	lamp.light_color = Color(1.0, 0.88, 0.65)
	lamp.light_energy = 2.4
	lamp.omni_range = 9.0
	lamp.position = Vector3(1.2, 2.6, 5.4)
	house.add_child(lamp)

	return house

# ------------------------------------------------------------------------------
# MẪU 6: NHÀ ĐÁ THÔ SUỐI KHOÁNG HUYỆN BẮC (13m x 11m) - Sa Thạch Xám, Hồ Onsen Mini
# ------------------------------------------------------------------------------
static func _build_highland_stone_cottage() -> Node3D:
	var house = Node3D.new()
	house.name = "House_HighlandStoneCottage"

	var mat_sandstone = _get_mat(Color(0.68, 0.65, 0.60), 0.95)
	var mat_slate = _get_mat(Color(0.35, 0.40, 0.38), 0.65)
	var mat_cedar = _get_mat(Color(0.65, 0.45, 0.28))
	var mat_onsen = _get_mat(Color(0.30, 0.75, 0.85, 0.85), 0.1, 0.0, Color(0.20, 0.60, 0.70), 0.8)
	var mat_door = _get_mat(Color(0.40, 0.25, 0.16))

	# 1. Nền đá tảng
	var base = _create_box_collider("StonePlinth", Vector3(13.6, 0.4, 11.6), mat_sandstone)
	base.position.y = 0.2
	house.add_child(base)

	# 2. Khối tường sa thạch xám kiên cố
	var body = _create_box_collider("SandstoneBody", Vector3(13.0, 4.0, 11.0), mat_sandstone)
	body.position.y = 2.2
	house.add_child(body)

	# 3. Mái ngói cách nhiệt sẫm màu
	var roof = MeshInstance3D.new()
	var r_prism = PrismMesh.new()
	r_prism.size = Vector3(13.8, 3.5, 11.8)
	roof.mesh = r_prism
	roof.material_override = mat_slate
	roof.position = Vector3(0, 5.8, 0)
	house.add_child(roof)

	# Ống khói đá đôi
	var chimney = _create_box_collider("TwinChimney", Vector3(1.3, 3.6, 1.3), mat_sandstone)
	chimney.position = Vector3(-4.5, 6.2, -2.5)
	house.add_child(chimney)

	# 4. Hồ ngâm khoáng Onsen nước nóng bằng gỗ tuyết tùng bên hông
	var tub = MeshInstance3D.new()
	var t_cyl = CylinderMesh.new()
	t_cyl.top_radius = 1.3
	t_cyl.bottom_radius = 1.2
	t_cyl.height = 0.9
	tub.mesh = t_cyl
	tub.material_override = mat_cedar
	tub.position = Vector3(5.5, 0.65, 2.5)
	house.add_child(tub)

	# Mặt nước suối khoáng phát sáng
	var water = MeshInstance3D.new()
	var w_cyl = CylinderMesh.new()
	w_cyl.top_radius = 1.2
	w_cyl.bottom_radius = 1.2
	w_cyl.height = 0.05
	water.mesh = w_cyl
	water.material_override = mat_onsen
	water.position = Vector3(5.5, 1.05, 2.5)
	house.add_child(water)

	# 5. Cửa chính kiên cố trên DoorHingePivot
	var door_pivot = Node3D.new()
	door_pivot.name = "DoorHingePivot"
	door_pivot.position = Vector3(-0.8, 1.4, 5.52)

	var door_leaf = MeshInstance3D.new()
	var d_box = BoxMesh.new()
	d_box.size = Vector3(1.4, 2.4, 0.15)
	door_leaf.mesh = d_box
	door_leaf.material_override = mat_door
	door_leaf.position = Vector3(0.7, 0, 0)
	door_pivot.add_child(door_leaf)
	house.add_child(door_pivot)

	# Đèn lồng khoáng nóng
	var light = OmniLight3D.new()
	light.light_color = Color(1.0, 0.85, 0.6)
	light.light_energy = 2.2
	light.omni_range = 8.5
	light.position = Vector3(1.2, 2.5, 5.8)
	house.add_child(light)

	return house

# ------------------------------------------------------------------------------
# MẪU 7: NHÀ SÀN VEN HỒ SINH THÁI TÂY BẮC (14m x 12m) - Trụ Nổi Cao, Mái Rơm Thơ Mộng
# ------------------------------------------------------------------------------
static func _build_lakeside_stilt_house() -> Node3D:
	var house = Node3D.new()
	house.name = "House_LakesideStiltHouse"

	var mat_stilts = _get_mat(Color(0.40, 0.28, 0.18))
	var mat_deck = _get_mat(Color(0.72, 0.58, 0.42))
	var mat_wall = _get_mat(Color(0.85, 0.78, 0.65))
	var mat_thatch = _get_mat(Color(0.72, 0.64, 0.40), 0.8)
	var mat_rope = _get_mat(Color(0.60, 0.50, 0.35))

	# 1. Sáu cọc trụ gỗ nâng sàn cao 1.4m chống ngập
	for sx in [-6.0, 0.0, 6.0]:
		for sz in [-5.0, 5.0]:
			var stilt = MeshInstance3D.new()
			var s_cyl = CylinderMesh.new()
			s_cyl.top_radius = 0.22
			s_cyl.bottom_radius = 0.22
			s_cyl.height = 2.0
			stilt.mesh = s_cyl
			stilt.material_override = mat_stilts
			stilt.position = Vector3(sx, 1.0, sz)
			house.add_child(stilt)

	# 2. Sàn gỗ nổi rộng 14m x 12m
	var platform = _create_box_collider("StiltPlatform", Vector3(14.0, 0.3, 12.0), mat_deck)
	platform.position.y = 1.95
	house.add_child(platform)

	# Cầu cảng vươn dài ra mặt hồ
	var dock = _create_box_collider("FishingPier", Vector3(3.2, 0.25, 4.5), mat_deck)
	dock.position = Vector3(0, 1.9, 7.8)
	house.add_child(dock)

	# 3. Khối nhà tre gỗ ấm cúng
	var cabin = _create_box_collider("BambooCabinBody", Vector3(10.0, 3.6, 8.0), mat_wall)
	cabin.position = Vector3(0, 3.9, -1.0)
	house.add_child(cabin)

	# 4. Mái dốc lợp rơm stylized
	var roof = MeshInstance3D.new()
	var r_mesh = PrismMesh.new()
	r_mesh.size = Vector3(11.2, 3.2, 9.2)
	roof.mesh = r_mesh
	roof.material_override = mat_thatch
	roof.position = Vector3(0, 6.9, -1.0)
	house.add_child(roof)

	# 5. Cửa trượt gỗ ven hồ trên DoorHingePivot
	var door_pivot = Node3D.new()
	door_pivot.name = "DoorHingePivot"
	door_pivot.position = Vector3(-0.8, 3.1, 3.02)

	var door_leaf = MeshInstance3D.new()
	var d_box = BoxMesh.new()
	d_box.size = Vector3(1.3, 2.2, 0.1)
	door_leaf.mesh = d_box
	door_leaf.material_override = mat_deck
	door_leaf.position = Vector3(0.65, 0, 0)
	door_pivot.add_child(door_leaf)
	house.add_child(door_pivot)

	# Đèn bão bến thuyền
	var lantern = OmniLight3D.new()
	lantern.light_color = Color(1.0, 0.88, 0.6)
	lantern.light_energy = 2.2
	lantern.omni_range = 9.0
	lantern.position = Vector3(1.0, 4.0, 3.5)
	house.add_child(lantern)

	return house

# ------------------------------------------------------------------------------
# MẪU 8: BUNGALOW NÔNG TRANG THẢO NGUYÊN HUYỆN ĐÔNG (17m x 13m) - Hiên Veranda, Silo Mini
# ------------------------------------------------------------------------------
static func _build_prairie_farmstead() -> Node3D:
	var house = Node3D.new()
	house.name = "House_PrairieFarmstead"

	var mat_cream = _get_mat(Color(0.96, 0.94, 0.88))
	var mat_barn_red = _get_mat(Color(0.75, 0.28, 0.20), 0.65)
	var mat_white_trim = _get_mat(Color(0.98, 0.98, 0.98), 0.6)
	var mat_silo = _get_mat(Color(0.68, 0.70, 0.72), 0.4, 0.5)
	var mat_wood = _get_mat(Color(0.48, 0.32, 0.20))

	# 1. Nền móng thảo nguyên
	var base = _create_box_collider("FarmBase", Vector3(17.6, 0.3, 13.6), mat_wood)
	base.position.y = 0.15
	house.add_child(base)

	# 2. Khối nhà chính nông trang
	var body = _create_box_collider("FarmBody", Vector3(11.0, 4.2, 9.0), mat_cream)
	body.position = Vector3(-2.0, 2.4, 0)
	house.add_child(body)

	# 3. Mái ngói đỏ gabled
	var roof = MeshInstance3D.new()
	var r_mesh = PrismMesh.new()
	r_mesh.size = Vector3(11.8, 3.4, 9.8)
	roof.mesh = r_mesh
	roof.material_override = mat_barn_red
	roof.position = Vector3(-2.0, 5.9, 0)
	house.add_child(roof)

	# 4. Tháp Silo trữ hạt ngũ cốc mini bên hông
	var silo = MeshInstance3D.new()
	var s_cyl = CylinderMesh.new()
	s_cyl.top_radius = 1.6
	s_cyl.bottom_radius = 1.6
	s_cyl.height = 6.2
	silo.mesh = s_cyl
	silo.material_override = mat_silo
	silo.position = Vector3(6.0, 3.2, 0)
	house.add_child(silo)

	var silo_cap = MeshInstance3D.new()
	var sc_mesh = CylinderMesh.new()
	sc_mesh.top_radius = 0.05
	sc_mesh.bottom_radius = 1.7
	sc_mesh.height = 1.2
	silo_cap.mesh = sc_mesh
	silo_cap.material_override = mat_barn_red
	silo_cap.position = Vector3(6.0, 6.8, 0)
	house.add_child(silo_cap)

	# 5. Hiên Veranda đón gió đồng
	var veranda = _create_box_collider("VerandaFloor", Vector3(11.0, 0.25, 2.2), mat_wood)
	veranda.position = Vector3(-2.0, 0.25, 5.2)
	house.add_child(veranda)

	# Ghế bập bênh / băng dài
	var bench = _create_box_collider("FarmBench", Vector3(2.0, 0.45, 0.5), mat_wood)
	bench.position = Vector3(1.5, 0.5, 5.2)
	house.add_child(bench)

	# 6. Cửa chính nông trang trên DoorHingePivot
	var door_pivot = Node3D.new()
	door_pivot.name = "DoorHingePivot"
	door_pivot.position = Vector3(-2.8, 1.4, 4.52)

	var door_leaf = MeshInstance3D.new()
	var d_box = BoxMesh.new()
	d_box.size = Vector3(1.3, 2.3, 0.1)
	door_leaf.mesh = d_box
	door_leaf.material_override = mat_white_trim
	door_leaf.position = Vector3(0.65, 0, 0)
	door_pivot.add_child(door_leaf)
	house.add_child(door_pivot)

	# Đèn hiên bão ấm áp
	var lamp = OmniLight3D.new()
	lamp.light_color = Color(1.0, 0.90, 0.7)
	lamp.light_energy = 2.2
	lamp.omni_range = 9.0
	lamp.position = Vector3(-2.0, 2.7, 5.2)
	house.add_child(lamp)

	return house

# ------------------------------------------------------------------------------
# MẪU 9: NHÀ GÁC LỬNG THUNG LŨNG GIÓ HUYỆN TÂY (11m x 11m) - Trần Kính, Cánh Quạt Mini
# ------------------------------------------------------------------------------
static func _build_valley_windmill_loft() -> Node3D:
	var house = Node3D.new()
	house.name = "House_ValleyWindmillLoft"

	var mat_white = _get_mat(Color(0.92, 0.92, 0.94))
	var mat_steel = _get_mat(Color(0.32, 0.35, 0.38), 0.4, 0.6)
	var mat_glass = _get_mat(Color(0.65, 0.88, 0.98, 0.8), 0.1, 0.0, Color(0.65, 0.88, 0.98), 0.5)
	var mat_rotor = _get_mat(Color(0.98, 0.98, 0.98))

	# 1. Móng công nghệ
	var base = _create_box_collider("LoftBase", Vector3(11.6, 0.4, 11.6), mat_steel)
	base.position.y = 0.2
	house.add_child(base)

	# 2. Khối phòng sáng tạo gác lửng
	var body = _create_box_collider("LoftBody", Vector3(11.0, 4.8, 11.0), mat_white)
	body.position.y = 2.6
	house.add_child(body)

	# 3. Mái dốc vát kính đón ánh sáng
	var glass_roof = MeshInstance3D.new()
	var gr_box = BoxMesh.new()
	gr_box.size = Vector3(9.0, 0.15, 6.0)
	glass_roof.mesh = gr_box
	glass_roof.material_override = mat_glass
	glass_roof.position = Vector3(0, 5.2, 0)
	glass_roof.rotation.x = deg_to_rad(-20.0)
	house.add_child(glass_roof)

	# 4. Trụ cối xay gió mini trên đỉnh góc mái
	var tower = MeshInstance3D.new()
	var t_cyl = CylinderMesh.new()
	t_cyl.top_radius = 0.15
	t_cyl.bottom_radius = 0.25
	t_cyl.height = 3.6
	tower.mesh = t_cyl
	tower.material_override = mat_steel
	tower.position = Vector3(4.2, 6.6, -4.2)
	house.add_child(tower)

	# Cánh quạt gió 3 lá
	var rotor_hub = Node3D.new()
	rotor_hub.name = "WindTurbineRotor"
	rotor_hub.position = Vector3(4.2, 8.4, -4.0)
	for ang in [0.0, 120.0, 240.0]:
		var blade = MeshInstance3D.new()
		var b_box = BoxMesh.new()
		b_box.size = Vector3(0.18, 1.8, 0.04)
		blade.mesh = b_box
		blade.material_override = mat_rotor
		blade.position.y = 0.9
		var blade_rot = Node3D.new()
		blade_rot.rotation.z = deg_to_rad(ang)
		blade_rot.add_child(blade)
		rotor_hub.add_child(blade_rot)
	house.add_child(rotor_hub)

	# 5. Cửa kính hiện đại trên DoorHingePivot
	var door_pivot = Node3D.new()
	door_pivot.name = "DoorHingePivot"
	door_pivot.position = Vector3(-0.7, 1.4, 5.52)

	var door_leaf = MeshInstance3D.new()
	var d_box = BoxMesh.new()
	d_box.size = Vector3(1.3, 2.4, 0.1)
	door_leaf.mesh = d_box
	door_leaf.material_override = mat_glass
	door_leaf.position = Vector3(0.65, 0, 0)
	door_pivot.add_child(door_leaf)
	house.add_child(door_pivot)

	# Đèn LED thung lũng gió
	var led = OmniLight3D.new()
	led.light_color = Color(0.9, 0.95, 1.0)
	led.light_energy = 2.5
	led.omni_range = 9.0
	led.position = Vector3(0, 3.2, 5.8)
	house.add_child(led)

	return house

# ------------------------------------------------------------------------------
# MẪU 10: BIỆT THỰ DUYÊN HẢI VỊNH BIỂN HUYỆN NAM (18m x 15m) - Tường Trắng, Mái Lam Ngọc, Vọng Hải
# ------------------------------------------------------------------------------
static func _build_coastal_villa() -> Node3D:
	var house = Node3D.new()
	house.name = "House_CoastalVilla"

	var mat_stucco = _get_mat(Color(0.98, 0.98, 1.0), 0.7)
	var mat_blue = _get_mat(Color(0.12, 0.46, 0.78), 0.5)
	var mat_terrace = _get_mat(Color(0.80, 0.48, 0.35))
	var mat_wood = _get_mat(Color(0.45, 0.30, 0.18))
	var mat_flower = _get_mat(Color(0.92, 0.18, 0.48)) # Hoa giấy hồng tím

	# 1. Nền sân thượng vọng hải
	var terrace = _create_box_collider("SeaTerrace", Vector3(18.6, 0.4, 15.6), mat_terrace)
	terrace.position.y = 0.2
	house.add_child(terrace)

	# 2. Khối biệt thự Địa Trung Hải
	var main_body = _create_box_collider("VillaWhiteBody", Vector3(13.0, 5.2, 11.0), mat_stucco)
	main_body.position = Vector3(-2.0, 2.8, 0)
	house.add_child(main_body)

	# 3. Mái ngói vòm xanh lam ngọc
	var dome_roof = MeshInstance3D.new()
	var d_mesh = PrismMesh.new()
	d_mesh.size = Vector3(13.8, 3.2, 11.8)
	dome_roof.mesh = d_mesh
	dome_roof.material_override = mat_blue
	dome_roof.position = Vector3(-2.0, 7.0, 0)
	house.add_child(dome_roof)

	# 4. Giàn Pergola che nắng với hoa giấy hồng
	var pergola = MeshInstance3D.new()
	var p_box = BoxMesh.new()
	p_box.size = Vector3(4.5, 0.2, 8.0)
	pergola.mesh = p_box
	pergola.material_override = mat_flower
	pergola.position = Vector3(6.5, 3.6, 1.5)
	house.add_child(pergola)

	for pz in [-2.0, 1.5, 5.0]:
		var col = MeshInstance3D.new()
		var col_mesh = CylinderMesh.new()
		col_mesh.top_radius = 0.15
		col_mesh.bottom_radius = 0.15
		col_mesh.height = 3.6
		col.mesh = col_mesh
		col.material_override = mat_stucco
		col.position = Vector3(8.5, 1.8, pz)
		house.add_child(col)

	# 5. Cửa vòm gỗ tếch trên DoorHingePivot
	var door_pivot = Node3D.new()
	door_pivot.name = "DoorHingePivot"
	door_pivot.position = Vector3(-2.8, 1.5, 5.52)

	var door_leaf = MeshInstance3D.new()
	var d_box = BoxMesh.new()
	d_box.size = Vector3(1.4, 2.6, 0.12)
	door_leaf.mesh = d_box
	door_leaf.material_override = mat_wood
	door_leaf.position = Vector3(0.7, 0, 0)
	door_pivot.add_child(door_leaf)
	house.add_child(door_pivot)

	# Đèn lồng hải đăng ven biển
	var lantern = OmniLight3D.new()
	lantern.light_color = Color(1.0, 0.92, 0.75)
	lantern.light_energy = 2.6
	lantern.omni_range = 10.0
	lantern.position = Vector3(-1.5, 3.2, 6.0)
	house.add_child(lantern)

	return house

# ------------------------------------------------------------------------------
# HÀM PHỤ TRỢ TẠO KHỐI VA CHẠM KÈM MESH (PHYSICS + VISUAL)
# ------------------------------------------------------------------------------
static func _create_box_collider(node_name: String, size: Vector3, mat: Material) -> StaticBody3D:
	var body = StaticBody3D.new()
	body.name = node_name
	body.collision_layer = 1
	body.collision_mask = 3

	var col = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = size
	col.shape = box_shape
	body.add_child(col)

	var mesh_inst = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = size
	mesh_inst.mesh = box_mesh
	mesh_inst.material_override = mat
	body.add_child(mesh_inst)

	return body
