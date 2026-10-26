class_name CentralCapitalBuilder
extends RefCounted

# ==============================================================================
# CENTRAL CAPITAL BUILDER - ĐÔ THỊ LÕI ĐỈNH VÁT (X=0, Z=0)
# Tuân thủ 100% GAME_DESIGN_CONCEPT.md & ai_context_system_instructions.md:
# 1. Tòa Mega-Office Skyscraper sừng sững tại tâm (X=0, Z=0), tích hợp Đại Hội Trường
#    15.000 chỗ mái vòm giếng trời bên trong (Xóa bỏ nhà thờ cổ điển tách rời sai concept).
# 2. Tuyến ray xe tram thẳng Đông - Tây chạy ngoài quảng trường, kết nối Ga Tram Trung Tâm.
# 3. Quảng Trường Hòa Bình (R=120m) phong cách Ghibli: Sàn đá hoa cương, Đài Phun Nước
#    Ước Nguyện, Tiệm Bánh Mì Bác Nam, Trạm Xá Chị Mai, Tháp Chuông Hòa Bình 42m,
#    Bảng Tin Cư Dân, Bàn Sắc Lệnh & Giường Nghỉ Thị Trưởng (Night Skip).
# 4. 5 Cư dân cốt lõi (Bác Nam, Chị Mai, Mục Tử David, Kỹ Sư Tuấn, Bác Ba).
# ==============================================================================

# Lớp Toa Xe Tram Chạy Tuyến Thẳng Đông - Tây
class VintageTramCar extends Node3D:
	var track_start_x: float = -320.0
	var track_end_x: float = 320.0
	var track_z: float = 275.0
	var speed: float = 4.0
	var direction: float = 1.0
	var station_dwell_seconds: float = 2.5
	var dwell_remaining: float = 2.5
	var passenger_ref: Node3D = null

	func _ready() -> void:
		add_to_group("trams")
		position = Vector3(0.0, 0.35, track_z)

	func _process(delta: float) -> void:
		if dwell_remaining > 0.0:
			dwell_remaining = maxf(0.0, dwell_remaining - delta)
		else:
			var previous_x = position.x
			position.x += speed * direction * delta
			if direction > 0.0 and previous_x < 0.0 and position.x >= 0.0:
				position.x = 0.0
				direction = -1.0
				dwell_remaining = station_dwell_seconds
			elif direction < 0.0 and previous_x > 0.0 and position.x <= 0.0:
				position.x = 0.0
				direction = 1.0
				dwell_remaining = station_dwell_seconds

		if position.x >= track_end_x:
			position.x = track_end_x
			direction = -1.0
		elif position.x <= track_start_x:
			position.x = track_start_x
			direction = 1.0
		if dwell_remaining <= 0.0:
			rotation.y = -PI * 0.5 if direction > 0.0 else PI * 0.5

		if passenger_ref and is_instance_valid(passenger_ref):
			passenger_ref.global_position = global_position + Vector3(0.0, 1.1, 0.0)
			passenger_ref.global_rotation.y = global_rotation.y

	func board_from_stop(player: Node3D, stop_position: Vector3) -> bool:
		if passenger_ref != null or global_position.distance_to(stop_position) > 8.0:
			return false

		passenger_ref = player
		player.visible = false
		player.set_physics_process(false)
		player.set_meta("occupied_tram", self)
		if player.has_meta("nearby_interactive"):
			player.remove_meta("nearby_interactive")
		player.global_position = global_position + Vector3(0.0, 1.1, 0.0)

		var hud = get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("show_toast"):
			hud.show_toast("🚊 Đã lên tram tuyến Đông - Tây. Nhấn [E] hoặc [F] để xuống tại điểm phù hợp.")
		return true

	func exit_tram() -> void:
		if passenger_ref == null or not is_instance_valid(passenger_ref):
			passenger_ref = null
			return

		var passenger = passenger_ref
		passenger_ref = null
		passenger.global_position = global_position + global_transform.basis.x * 3.5 + Vector3(0.0, 0.5, 0.0)
		passenger.global_rotation.y = global_rotation.y
		passenger.visible = true
		passenger.set_physics_process(true)
		if passenger.has_meta("occupied_tram"):
			passenger.remove_meta("occupied_tram")

		var hud = get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("show_toast"):
			hud.show_toast("🚊 Bạn đã xuống tram an toàn.")

static func build_capital_complex() -> Node3D:
	var root = Node3D.new()
	root.name = "CentralCapitalComplex"

	# --------------------------------------------------------------------------
	# VẬT LIỆU TOON STYLIZED (ANIME GHIBLI PALETTE)
	# --------------------------------------------------------------------------
	var mat_plaza = _create_material(Color(0.88, 0.90, 0.94), 0.65)
	var mat_plaza_border = _create_material(Color(0.35, 0.40, 0.48), 0.6)
	var mat_building_white = _create_material(Color(0.95, 0.97, 0.99), 0.35)
	var mat_glass = _create_glass_material(Color(0.22, 0.68, 0.92, 0.82))
	var mat_gold = _create_metal_material(Color(0.96, 0.78, 0.18), 0.8, 0.2)
	var mat_wood = _create_material(Color(0.48, 0.30, 0.18), 0.7)
	var mat_bread = _create_material(Color(0.88, 0.62, 0.28), 0.8)
	var mat_awning_orange = _create_material(Color(0.92, 0.45, 0.15), 0.7)
	var mat_awning_green = _create_material(Color(0.18, 0.68, 0.38), 0.7)
	var mat_water = _create_glass_material(Color(0.32, 0.82, 0.95, 0.75))
	var mat_lamp_glow = _create_emission_material(Color(1.0, 0.92, 0.55), Color(1.0, 0.88, 0.45), 2.8)
	var mat_royal_blue = _create_material(Color(0.15, 0.32, 0.72), 0.6)
	var mat_greenery = _create_material(Color(0.22, 0.62, 0.28), 0.85)
	var mat_tram_green = _create_material(Color(0.16, 0.46, 0.34), 0.4)
	var mat_tram_cream = _create_material(Color(0.95, 0.92, 0.80), 0.4)
	var mat_rail_steel = _create_metal_material(Color(0.75, 0.78, 0.82), 0.9, 0.25)
	var mat_metro_train = _create_material(Color(0.16, 0.28, 0.42), 0.3)

	# --------------------------------------------------------------------------
	# 1. ĐẠI CAO ỐC MEGA-OFFICE SKYSCRAPER SỪNG SỮNG TẠI TÂM (X=0, Z=0)
	# --------------------------------------------------------------------------
	var skyscraper_builder = preload("res://scripts/terrain/mega_office_skyscraper_builder.gd")
	var skyscraper = skyscraper_builder.build_mega_skyscraper()
	root.add_child(skyscraper)

	# --------------------------------------------------------------------------
	# 2. QUẢNG TRƯỜNG HÒA BÌNH (PEACE PLAZA R=250M)
	# --------------------------------------------------------------------------
	var plaza_mesh = CylinderMesh.new()
	plaza_mesh.top_radius = 250.0
	plaza_mesh.bottom_radius = 250.2
	plaza_mesh.height = 0.4
	var plaza_inst = MeshInstance3D.new()
	plaza_inst.name = "PeacePlaza"
	plaza_inst.mesh = plaza_mesh
	plaza_inst.material_override = mat_plaza
	plaza_inst.position = Vector3(0, 0.2, 0)
	root.add_child(plaza_inst)
	_add_cylinder_collider(root, 250.0, 0.4, Vector3(0, 0.2, 0))

	# Viền đá hoa cương ngoài cùng
	var border_mesh = TorusMesh.new()
	border_mesh.inner_radius = 249.2
	border_mesh.outer_radius = 250.0
	var border_inst = MeshInstance3D.new()
	border_inst.mesh = border_mesh
	border_inst.material_override = mat_plaza_border
	border_inst.position = Vector3(0, 0.42, 0)
	root.add_child(border_inst)

	# --------------------------------------------------------------------------
	# 3. TUYẾN TRAM THẲNG ĐÔNG - TÂY & GA TRUNG TÂM NGOÀI QUẢNG TRƯỜNG
	# --------------------------------------------------------------------------
	var track_container = Node3D.new()
	track_container.name = "TramTrackLine"
	root.add_child(track_container)

	var track_start_x = -320.0
	var track_end_x = 320.0
	var track_z = 275.0
	var tie_spacing = 2.0
	for i in range(int((track_end_x - track_start_x) / tie_spacing) + 1):
		var track_x = track_start_x + float(i) * tie_spacing
		var tie = MeshInstance3D.new()
		var tie_box = BoxMesh.new()
		tie_box.size = Vector3(0.35, 0.08, 2.2)
		tie.mesh = tie_box
		tie.material_override = mat_wood
		tie.position = Vector3(track_x, 0.41, track_z)
		track_container.add_child(tie)

		for rail_offset in [-0.75, 0.75]:
			var rail = MeshInstance3D.new()
			var rail_box = BoxMesh.new()
			rail_box.size = Vector3(tie_spacing + 0.05, 0.1, 0.08)
			rail.mesh = rail_box
			rail.material_override = mat_rail_steel
			rail.position = Vector3(track_x, 0.49, track_z + rail_offset)
			track_container.add_child(rail)

	# Ga tram và đường ray nằm ngoài footprint tòa nhà và ngoài quảng trường.
	var tram_station = Node3D.new()
	tram_station.name = "CentralTramStation"
	tram_station.position = Vector3(0.0, 0.2, track_z + 6.5)
	root.add_child(tram_station)

	var tram_stop = InteractiveStation.new()
	tram_stop.name = "CentralTramStop"
	tram_stop.station_type = InteractiveStation.StationType.TRAM_STOP
	tram_stop.station_id = "central_tram_stop"
	tram_stop.title_name = "Ga Tram Trung Tâm"
	tram_stop.prompt_text = "🚊 [E] Lên tram tuyến Đông - Tây (chờ tàu tại ga)"
	tram_stop.interaction_radius = 7.5
	tram_station.add_child(tram_stop)

	# Bục thềm ga tram
	var plat_mesh = BoxMesh.new()
	plat_mesh.size = Vector3(12.0, 0.45, 3.6)
	var plat_inst = MeshInstance3D.new()
	plat_inst.mesh = plat_mesh
	plat_inst.material_override = mat_plaza_border
	plat_inst.position = Vector3(0, 0.22, 0)
	tram_station.add_child(plat_inst)
	_add_box_collider(tram_station, plat_mesh.size, plat_inst.position)

	# Mái che Ga Tram Toon
	var t_roof = MeshInstance3D.new()
	var tr_mesh = BoxMesh.new()
	tr_mesh.size = Vector3(12.6, 0.2, 4.2)
	t_roof.mesh = tr_mesh
	t_roof.material_override = mat_tram_green
	t_roof.position = Vector3(0, 3.4, 0)
	tram_station.add_child(t_roof)

	# Biển tên Ga Tram Trung Tâm
	var tram_sign = _create_label3d("🚊 GA TRAM TRUNG TÂM\n[Tuyến thẳng Đông - Tây • Kết nối Đại lộ Nam]", Color(1.0, 0.88, 0.3), 22)
	tram_sign.position = Vector3(0, 4.0, 0)
	tram_station.add_child(tram_sign)

	# TOA XE TRAM ANIME CỔ ĐIỂN CHẠY QUA LẠI TRÊN TUYẾN THẲNG
	var tram_car = VintageTramCar.new()
	tram_car.name = "VintageTram01"
	tram_car.track_start_x = track_start_x
	tram_car.track_end_x = track_end_x
	tram_car.track_z = track_z
	root.add_child(tram_car)

	# Thân xe tram
	var car_body = MeshInstance3D.new()
	var cb_box = BoxMesh.new()
	cb_box.size = Vector3(2.4, 2.6, 6.2)
	car_body.mesh = cb_box
	car_body.material_override = mat_tram_green
	car_body.position = Vector3(0, 1.45, 0)
	tram_car.add_child(car_body)

	# Dải kem trang trí
	var car_stripe = MeshInstance3D.new()
	var cs_box = BoxMesh.new()
	cs_box.size = Vector3(2.45, 0.7, 6.25)
	car_stripe.mesh = cs_box
	car_stripe.material_override = mat_tram_cream
	car_stripe.position = Vector3(0, 1.35, 0)
	tram_car.add_child(car_stripe)

	# Cửa sổ kính Toon 2 bên
	var car_glass = MeshInstance3D.new()
	var cg_box = BoxMesh.new()
	cg_box.size = Vector3(2.5, 0.9, 5.2)
	car_glass.mesh = cg_box
	car_glass.material_override = mat_glass
	car_glass.position = Vector3(0, 2.1, 0)
	tram_car.add_child(car_glass)

	# Cần tiếp điện Pantograph trên nóc
	var panto = MeshInstance3D.new()
	var p_cyl = CylinderMesh.new()
	p_cyl.top_radius = 0.05
	p_cyl.bottom_radius = 0.05
	p_cyl.height = 1.2
	panto.mesh = p_cyl
	panto.material_override = mat_gold
	panto.position = Vector3(0, 3.3, 0)
	tram_car.add_child(panto)

	# Đèn pha xe tram phát sáng
	var tram_light = OmniLight3D.new()
	tram_light.light_color = Color(1.0, 0.9, 0.6)
	tram_light.light_energy = 2.5
	tram_light.omni_range = 8.0
	tram_light.position = Vector3(0, 1.2, 3.2)
	tram_car.add_child(tram_light)

	# --------------------------------------------------------------------------
	# 3.1 GA METRO NGẦM 4 TẦNG, 4 TRỤC CHÉO & 8 HƯỚNG
	# --------------------------------------------------------------------------
	var metro_builder = preload("res://scripts/terrain/central_metro_builder.gd")
	var metro_hub = metro_builder.build_central_metro(mat_plaza_border, mat_rail_steel, mat_metro_train, mat_tram_cream)
	root.add_child(metro_hub)

	# --------------------------------------------------------------------------
	# 4. ĐÀI PHUN NƯỚC ƯỚC NGUYỆN (FOUNTAIN STATION - VÀNH ĐAI PHÍA TÂY)
	# --------------------------------------------------------------------------
	var fountain_node = Node3D.new()
	fountain_node.name = "CentralFountain"
	fountain_node.position = Vector3(-195.0, 0.2, -72.0)
	root.add_child(fountain_node)

	var basin_mesh = CylinderMesh.new()
	basin_mesh.top_radius = 4.8
	basin_mesh.bottom_radius = 5.0
	basin_mesh.height = 0.8
	var basin_inst = MeshInstance3D.new()
	basin_inst.mesh = basin_mesh
	basin_inst.material_override = mat_plaza_border
	basin_inst.position = Vector3(0, 0.4, 0)
	fountain_node.add_child(basin_inst)
	_add_cylinder_collider(fountain_node, 4.8, 0.8, Vector3(0, 0.4, 0))

	var water_mesh = CylinderMesh.new()
	water_mesh.top_radius = 4.4
	water_mesh.bottom_radius = 4.4
	water_mesh.height = 0.1
	var water_inst = MeshInstance3D.new()
	water_inst.mesh = water_mesh
	water_inst.material_override = mat_water
	water_inst.position = Vector3(0, 0.72, 0)
	fountain_node.add_child(water_inst)

	var pillar_mesh = CylinderMesh.new()
	pillar_mesh.top_radius = 0.45
	pillar_mesh.bottom_radius = 0.65
	pillar_mesh.height = 2.4
	var pillar_inst = MeshInstance3D.new()
	pillar_inst.mesh = pillar_mesh
	pillar_inst.material_override = mat_building_white
	pillar_inst.position = Vector3(0, 1.6, 0)
	fountain_node.add_child(pillar_inst)

	var bowl_mesh = CylinderMesh.new()
	bowl_mesh.top_radius = 2.2
	bowl_mesh.bottom_radius = 1.4
	bowl_mesh.height = 0.45
	var bowl_inst = MeshInstance3D.new()
	bowl_inst.mesh = bowl_mesh
	bowl_inst.material_override = mat_plaza_border
	bowl_inst.position = Vector3(0, 2.0, 0)
	fountain_node.add_child(bowl_inst)

	var jet_mesh = CylinderMesh.new()
	jet_mesh.top_radius = 0.15
	jet_mesh.bottom_radius = 0.35
	jet_mesh.height = 1.6
	var jet_inst = MeshInstance3D.new()
	jet_inst.mesh = jet_mesh
	jet_inst.material_override = mat_water
	jet_inst.position = Vector3(0, 3.2, 0)
	fountain_node.add_child(jet_inst)

	var st_fountain = InteractiveStation.new()
	st_fountain.name = "StationFountain"
	st_fountain.station_type = InteractiveStation.StationType.FOUNTAIN
	st_fountain.station_id = "fountain"
	st_fountain.title_name = "Đài Phun Nước Ước Nguyện"
	st_fountain.prompt_text = "🪙 [E] Thả Đồng Xu Ước Nguyện (Cầu Chúc Toàn Thành An Lành)"
	st_fountain.interaction_radius = 5.2
	st_fountain.position = Vector3(-195.0, 0.4, -72.0)
	root.add_child(st_fountain)

	# --------------------------------------------------------------------------
	# 5. TIỆM BÁNH MÌ BÁC NAM (BAKERY STATION - VÀNH ĐAI PHÍA TÂY)
	# --------------------------------------------------------------------------
	var bakery_node = Node3D.new()
	bakery_node.name = "BakeryBooth"
	bakery_node.position = Vector3(-195.0, 0.2, -24.0)
	root.add_child(bakery_node)

	var b_counter = MeshInstance3D.new()
	var b_counter_box = BoxMesh.new()
	b_counter_box.size = Vector3(3.4, 1.1, 1.5)
	b_counter.mesh = b_counter_box
	b_counter.material_override = mat_wood
	b_counter.position = Vector3(0, 0.55, 0)
	bakery_node.add_child(b_counter)
	_add_box_collider(bakery_node, Vector3(3.4, 1.1, 1.5), Vector3(0, 0.55, 0))

	var b_awning = MeshInstance3D.new()
	var b_awning_box = BoxMesh.new()
	b_awning_box.size = Vector3(3.6, 0.15, 2.0)
	b_awning.mesh = b_awning_box
	b_awning.material_override = mat_awning_orange
	b_awning.position = Vector3(0, 2.4, 0.2)
	b_awning.rotation_degrees = Vector3(12.0, 0, 0)
	bakery_node.add_child(b_awning)

	for bx in [-1.0, 0.0, 1.0]:
		var loaf = MeshInstance3D.new()
		var loaf_cyl = CylinderMesh.new()
		loaf_cyl.top_radius = 0.14
		loaf_cyl.bottom_radius = 0.14
		loaf_cyl.height = 0.7
		loaf.mesh = loaf_cyl
		loaf.material_override = mat_bread
		loaf.position = Vector3(bx, 1.18, 0)
		loaf.rotation_degrees = Vector3(0, 0, 90.0)
		bakery_node.add_child(loaf)

	var b_sign = _create_label3d("🥖 TIỆM BÁNH MÌ TÂN THẾ GIỚI - BÁC NAM", Color(1.0, 0.85, 0.3), 22)
	b_sign.position = Vector3(0, 2.8, 0.3)
	bakery_node.add_child(b_sign)

	var st_bakery = InteractiveStation.new()
	st_bakery.name = "StationBakery"
	st_bakery.station_type = InteractiveStation.StationType.BAKERY
	st_bakery.station_id = "bakery"
	st_bakery.title_name = "Tiệm Bánh Mì Bác Nam"
	st_bakery.prompt_text = "🥖 [E] Nhận Bánh Mì Baguette Nóng Hổi (+50 Sinh Lực)"
	st_bakery.interaction_radius = 3.8
	st_bakery.position = Vector3(-195.0, 0.2, -24.0)
	root.add_child(st_bakery)

	# --------------------------------------------------------------------------
	# 6. TRẠM XÁ SINH THÁI CHỊ MAI (CLINIC STATION - VÀNH ĐAI PHÍA ĐÔNG)
	# --------------------------------------------------------------------------
	var clinic_node = Node3D.new()
	clinic_node.name = "ClinicBooth"
	clinic_node.position = Vector3(195.0, 0.2, -24.0)
	root.add_child(clinic_node)

	var c_counter = MeshInstance3D.new()
	var c_counter_box = BoxMesh.new()
	c_counter_box.size = Vector3(3.4, 1.1, 1.5)
	c_counter.mesh = c_counter_box
	c_counter.material_override = mat_building_white
	c_counter.position = Vector3(0, 0.55, 0)
	clinic_node.add_child(c_counter)
	_add_box_collider(clinic_node, Vector3(3.4, 1.1, 1.5), Vector3(0, 0.55, 0))

	var c_awning = MeshInstance3D.new()
	var c_awning_box = BoxMesh.new()
	c_awning_box.size = Vector3(3.6, 0.15, 2.0)
	c_awning.mesh = c_awning_box
	c_awning.material_override = mat_awning_green
	c_awning.position = Vector3(0, 2.4, 0.2)
	c_awning.rotation_degrees = Vector3(12.0, 0, 0)
	clinic_node.add_child(c_awning)

	var tea_pot = MeshInstance3D.new()
	var tea_pot_cyl = CylinderMesh.new()
	tea_pot_cyl.top_radius = 0.22
	tea_pot_cyl.bottom_radius = 0.28
	tea_pot_cyl.height = 0.4
	tea_pot.mesh = tea_pot_cyl
	tea_pot.material_override = mat_gold
	tea_pot.position = Vector3(0, 1.3, 0)
	clinic_node.add_child(tea_pot)

	var c_sign = _create_label3d("🌿 TRẠM XÁ THẢO DƯỢC CỘNG ĐỒNG - CHỊ MAI", Color(0.4, 0.95, 0.5), 22)
	c_sign.position = Vector3(0, 2.8, 0.3)
	clinic_node.add_child(c_sign)

	var st_clinic = InteractiveStation.new()
	st_clinic.name = "StationClinic"
	st_clinic.station_type = InteractiveStation.StationType.CLINIC
	st_clinic.station_id = "clinic"
	st_clinic.title_name = "Trạm Xá Sinh Thái Chị Mai"
	st_clinic.prompt_text = "🌿 [E] Uống Trà Thảo Mộc Chữa Lành (+100% Sinh Lực)"
	st_clinic.interaction_radius = 3.8
	st_clinic.position = Vector3(195.0, 0.2, -24.0)
	root.add_child(st_clinic)

	# --------------------------------------------------------------------------
	# 7. THÁP CHUÔNG HÒA BÌNH 42M & ĐẠI HỘI TRƯỜNG PHỤNG VỤ 15.000 CHỖ
	# --------------------------------------------------------------------------
	var grand_sanctuary = Node3D.new()
	grand_sanctuary.name = "GrandSanctuary"
	root.add_child(grand_sanctuary)

	var bell_tower = Node3D.new()
	bell_tower.name = "PeaceBellTower"
	bell_tower.position = Vector3(195.0, 0.0, 62.0)
	root.add_child(bell_tower)

	var tower_mesh = BoxMesh.new()
	tower_mesh.size = Vector3(6.5, 36.0, 6.5)
	var tower_inst = MeshInstance3D.new()
	tower_inst.mesh = tower_mesh
	tower_inst.material_override = mat_building_white
	tower_inst.position = Vector3(0.0, 18.0, 0.0)
	bell_tower.add_child(tower_inst)
	_add_box_collider(bell_tower, Vector3(6.5, 36.0, 6.5), Vector3(0.0, 18.0, 0.0))

	var spire_bell = MeshInstance3D.new()
	var sb_cyl = CylinderMesh.new()
	sb_cyl.top_radius = 0.05
	sb_cyl.bottom_radius = 3.6
	sb_cyl.height = 7.0
	spire_bell.mesh = sb_cyl
	spire_bell.material_override = mat_gold
	spire_bell.position = Vector3(0.0, 39.5, 0.0)
	bell_tower.add_child(spire_bell)

	var bell_inst = MeshInstance3D.new()
	var b_cyl = CylinderMesh.new()
	b_cyl.top_radius = 0.6
	b_cyl.bottom_radius = 1.2
	b_cyl.height = 1.5
	bell_inst.mesh = b_cyl
	bell_inst.material_override = mat_gold
	bell_inst.position = Vector3(0.0, 34.0, 0.0)
	bell_tower.add_child(bell_inst)

	# Dây chuông đỏ nhung buông rủ
	var rope_inst = MeshInstance3D.new()
	var rope_cyl = CylinderMesh.new()
	rope_cyl.top_radius = 0.04
	rope_cyl.bottom_radius = 0.04
	rope_cyl.height = 3.2
	rope_inst.mesh = rope_cyl
	rope_inst.material_override = mat_awning_orange
	rope_inst.position = Vector3(0, 2.6, 3.6)
	bell_tower.add_child(rope_inst)

	var ring_inst = MeshInstance3D.new()
	var ring_torus = TorusMesh.new()
	ring_torus.inner_radius = 0.12
	ring_torus.outer_radius = 0.22
	ring_inst.mesh = ring_torus
	ring_inst.material_override = mat_gold
	ring_inst.position = Vector3(0, 1.2, 3.6)
	ring_inst.rotation_degrees = Vector3(90.0, 0, 0)
	bell_tower.add_child(ring_inst)

	var bell_sign = _create_label3d("🔔 THÁP CHUÔNG HÒA BÌNH (CAO 42M)", Color(1.0, 0.88, 0.25), 22)
	bell_sign.position = Vector3(0, 4.2, 3.6)
	bell_tower.add_child(bell_sign)

	var st_bell = InteractiveStation.new()
	st_bell.name = "StationBell"
	st_bell.station_type = InteractiveStation.StationType.BELL
	st_bell.station_id = "bell"
	st_bell.title_name = "Dây Rung Chuông Hòa Bình"
	st_bell.prompt_text = "🔔 [E] Kéo Dây Rung Chuông Hòa Bình (Ngân Vang 500 km²)"
	st_bell.interaction_radius = 4.2
	st_bell.position = Vector3(195.0, 0.2, 65.6)
	root.add_child(st_bell)

	# --------------------------------------------------------------------------
	# 8. BÀN SẮC LỆNH THỊ TRƯỞNG (DESK STATION - VÀNH ĐAI PHÍA TÂY)
	# --------------------------------------------------------------------------
	var desk_node = Node3D.new()
	desk_node.name = "MayorDeskOffice"
	desk_node.position = Vector3(-195.0, 0.2, 105.0)
	root.add_child(desk_node)

	var d_table = MeshInstance3D.new()
	var d_box = BoxMesh.new()
	d_box.size = Vector3(3.2, 1.0, 1.6)
	d_table.mesh = d_box
	d_table.material_override = mat_wood
	d_table.position = Vector3(0, 0.5, 0)
	desk_node.add_child(d_table)
	_add_box_collider(desk_node, Vector3(3.2, 1.0, 1.6), Vector3(0, 0.5, 0))

	var d_chair = MeshInstance3D.new()
	var d_cbox = BoxMesh.new()
	d_cbox.size = Vector3(1.0, 1.8, 0.8)
	d_chair.mesh = d_cbox
	d_chair.material_override = mat_royal_blue
	d_chair.position = Vector3(0, 0.9, -1.1)
	desk_node.add_child(d_chair)

	var d_sign = _create_label3d("🏛️ BÀN SẮC LỆNH & ĐIỀU HÀNH CỦA THỊ TRƯỞNG", Color(1.0, 0.85, 0.3), 22)
	d_sign.position = Vector3(0, 2.2, 0.2)
	desk_node.add_child(d_sign)

	var st_desk = InteractiveStation.new()
	st_desk.name = "StationDesk"
	st_desk.station_type = InteractiveStation.StationType.DESK
	st_desk.station_id = "desk"
	st_desk.title_name = "Bàn Sắc Lệnh Thị Trưởng"
	st_desk.prompt_text = "🏛️ [E] Chọn: Ngồi làm việc hoặc Ký sắc lệnh"
	st_desk.interaction_radius = 3.6
	st_desk.position = Vector3(-195.0, 0.2, 105.0)
	root.add_child(st_desk)

	# --------------------------------------------------------------------------
	# 9. GIƯỜNG NGHỈ THỊ TRƯỞNG (BED STATION - VÀNH ĐAI PHÍA TÂY)
	# --------------------------------------------------------------------------
	var bed_node = Node3D.new()
	bed_node.name = "MayorBedSuite"
	bed_node.position = Vector3(-145.0, 0.2, 175.0)
	root.add_child(bed_node)

	var bed_frame = MeshInstance3D.new()
	var bed_box = BoxMesh.new()
	bed_box.size = Vector3(2.4, 0.6, 3.0)
	bed_frame.mesh = bed_box
	bed_frame.material_override = mat_royal_blue
	bed_frame.position = Vector3(0, 0.3, 0)
	bed_node.add_child(bed_frame)
	_add_box_collider(bed_node, Vector3(2.4, 0.6, 3.0), Vector3(0, 0.3, 0))

	var pillow = MeshInstance3D.new()
	var pillow_box = BoxMesh.new()
	pillow_box.size = Vector3(1.8, 0.2, 0.6)
	pillow.mesh = pillow_box
	pillow.material_override = mat_building_white
	pillow.position = Vector3(0, 0.65, -1.0)
	bed_node.add_child(pillow)

	var bed_sign = _create_label3d("🛏️ GIƯỜNG NGHỈ THỊ TRƯỞNG (TUA QUA ĐÊM)", Color(0.6, 0.85, 1.0), 22)
	bed_sign.position = Vector3(0, 1.8, 0)
	bed_node.add_child(bed_sign)

	var st_bed = InteractiveStation.new()
	st_bed.name = "StationBed"
	st_bed.station_type = InteractiveStation.StationType.BED
	st_bed.station_id = "bed"
	st_bed.title_name = "Giường Nghỉ Thị Trưởng"
	st_bed.prompt_text = "🛏️ [E] Nằm nghỉ hoặc chọn ngủ đến 06:00"
	st_bed.interaction_radius = 6.0
	st_bed.position = Vector3(-145.0, 0.2, 175.0)
	root.add_child(st_bed)

	# --------------------------------------------------------------------------
	# 10. BẢNG TIN NGUYỆN VỌNG CƯ DÂN (PETITIONS STATION - VÀNH ĐAI PHÍA BẮC)
	# --------------------------------------------------------------------------
	var petitions_node = Node3D.new()
	petitions_node.name = "PetitionsBoard"
	petitions_node.position = Vector3(42.0, 0.2, -210.0)
	root.add_child(petitions_node)

	for px in [-1.6, 1.6]:
		var post = MeshInstance3D.new()
		var post_cyl = CylinderMesh.new()
		post_cyl.top_radius = 0.1
		post_cyl.bottom_radius = 0.12
		post_cyl.height = 3.2
		post.mesh = post_cyl
		post.material_override = mat_wood
		post.position = Vector3(px, 1.6, 0)
		petitions_node.add_child(post)

	var board_inst = MeshInstance3D.new()
	var board_box = BoxMesh.new()
	board_box.size = Vector3(3.6, 2.0, 0.16)
	board_inst.mesh = board_box
	board_inst.material_override = mat_wood
	board_inst.position = Vector3(0, 1.8, 0)
	petitions_node.add_child(board_inst)
	_add_box_collider(petitions_node, Vector3(3.6, 2.0, 0.16), Vector3(0, 1.8, 0))

	var pet_sign = _create_label3d("📜 BẢNG TIN NGUYỆN VỌNG & Ý KIẾN CƯ DÂN 5 HUYỆN", Color(1.0, 0.9, 0.4), 22)
	pet_sign.position = Vector3(0, 3.2, 0.1)
	petitions_node.add_child(pet_sign)

	var st_pet = InteractiveStation.new()
	st_pet.name = "StationPetitions"
	st_pet.station_type = InteractiveStation.StationType.PETITIONS
	st_pet.station_id = "petitions"
	st_pet.title_name = "Bảng Tin Nguyện Vọng Cư Dân"
	st_pet.prompt_text = "📜 [E] Xem Bảng Tin Nguyện Vọng Cư Dân 5 Huyện"
	st_pet.interaction_radius = 4.2
	st_pet.position = Vector3(42.0, 0.2, -210.0)
	root.add_child(st_pet)

	# --------------------------------------------------------------------------
	# 11. HỆ THỐNG ĐÈN ĐƯỜNG CÔNG VIÊN TOON & GHẾ ĐÁ (PLAZA FURNITURE)
	# --------------------------------------------------------------------------
	var lamp_angles = [0.0, 30.0, 60.0, 90.0, 120.0, 150.0, 180.0, 210.0, 240.0, 270.0, 300.0, 330.0]
	for deg in lamp_angles:
		var rad = deg_to_rad(deg)
		var lx = cos(rad) * 238.0
		var lz = sin(rad) * 238.0

		var lamp_post = CylinderMesh.new()
		lamp_post.top_radius = 0.06
		lamp_post.bottom_radius = 0.12
		lamp_post.height = 3.8
		var lp_inst = MeshInstance3D.new()
		lp_inst.mesh = lamp_post
		lp_inst.material_override = mat_plaza_border
		lp_inst.position = Vector3(lx, 1.9, lz)
		root.add_child(lp_inst)

		var bulb = SphereMesh.new()
		bulb.radius = 0.22
		bulb.height = 0.44
		var bulb_inst = MeshInstance3D.new()
		bulb_inst.mesh = bulb
		bulb_inst.material_override = mat_lamp_glow
		bulb_inst.position = Vector3(lx, 3.8, lz)
		root.add_child(bulb_inst)

		var light = OmniLight3D.new()
		light.light_color = Color(1.0, 0.88, 0.55)
		light.light_energy = 1.4
		light.omni_range = 9.0
		light.position = Vector3(lx, 3.8, lz)
		root.add_child(light)

		var bx = cos(rad) * 232.0
		var bz = sin(rad) * 232.0
		var bench = MeshInstance3D.new()
		var bench_box = BoxMesh.new()
		bench_box.size = Vector3(2.0, 0.5, 0.7)
		bench.mesh = bench_box
		bench.material_override = mat_wood
		bench.position = Vector3(bx, 0.45, bz)
		bench.rotation.y = -rad + PI * 0.5
		root.add_child(bench)

	# --------------------------------------------------------------------------
	# 12. KHÓM HOA & CÂY XANH ĐÔ THỊ GHIBLI (URBAN GREENERY)
	# --------------------------------------------------------------------------
	var hedge_angles = [30.0, 60.0, 120.0, 150.0, 210.0, 240.0, 300.0, 330.0]
	for hdeg in hedge_angles:
		var hrad = deg_to_rad(hdeg)
		var hx = cos(hrad) * 228.0
		var hz = sin(hrad) * 228.0

		var hedge = MeshInstance3D.new()
		var hedge_sph = SphereMesh.new()
		hedge_sph.radius = 1.0
		hedge_sph.height = 1.4
		hedge.mesh = hedge_sph
		hedge.material_override = mat_greenery
		hedge.position = Vector3(hx, 0.7, hz)
		root.add_child(hedge)

	# --------------------------------------------------------------------------
	# 13. 5 NPC CƯ DÂN CỐT LÕI ĐỨNG TẠI CÁC QUẦY CHỨC NĂNG (LIVING CITIZENS)
	# --------------------------------------------------------------------------
	var npc_script = preload("res://scripts/characters/npc_character.gd")
	var citizens_container = Node3D.new()
	citizens_container.name = "CentralCitizens"
	root.add_child(citizens_container)

	# 1. Bác Nam (Tiệm Bánh Mì - đứng sau quầy bánh)
	var npc_nam = npc_script.new()
	npc_nam.name = "NPC_BakerNam"
	npc_nam.npc_id = "baker_nam"
	npc_nam.citizen_name = "Bác Nam"
	npc_nam.age = 52
	npc_nam.age_group = ModularHumanoidBuilder.AgeGroup.ELDER
	npc_nam.gender = "Nam"
	npc_nam.profession = ModularHumanoidBuilder.ProfessionType.BAKER
	npc_nam.job_title = "Nghệ Nhân Bánh Mì"
	npc_nam.cert_code = "CERT_BAKERY_CHEF"
	npc_nam.skill_level = 9
	npc_nam.cccd_number = "TTG-2026-0021"
	npc_nam.position = Vector3(-195.0, 0.2, -25.5)
	citizens_container.add_child(npc_nam)

	# 2. Chị Mai (Trạm Xá Sinh Thái - đứng sau quầy thảo dược)
	var npc_mai = npc_script.new()
	npc_mai.name = "NPC_DoctorMai"
	npc_mai.npc_id = "doctor_mai"
	npc_mai.citizen_name = "Chị Mai"
	npc_mai.age = 26
	npc_mai.age_group = ModularHumanoidBuilder.AgeGroup.ADULT
	npc_mai.gender = "Nữ"
	npc_mai.profession = ModularHumanoidBuilder.ProfessionType.DOCTOR
	npc_mai.job_title = "Bác Sĩ Nghỉ Dưỡng Sinh Thái"
	npc_mai.cert_code = "CERT_DOCTOR_PHYSICIAN"
	npc_mai.skill_level = 9
	npc_mai.cccd_number = "TTG-2026-0077"
	npc_mai.position = Vector3(195.0, 0.2, -25.5)
	citizens_container.add_child(npc_mai)

	# 3. Người Chăn Chiên David (Mục Tử Đại Hội Trường)
	var npc_david = npc_script.new()
	npc_david.name = "NPC_PastorDavid"
	npc_david.npc_id = "shepherd_david"
	npc_david.citizen_name = "Người Chăn Chiên David"
	npc_david.age = 38
	npc_david.age_group = ModularHumanoidBuilder.AgeGroup.ADULT
	npc_david.gender = "Nam"
	npc_david.profession = ModularHumanoidBuilder.ProfessionType.TEACHER
	npc_david.job_title = "Mục Tử Đại Hội Trường 15.000 Chỗ"
	npc_david.cert_code = "CERT_DIVINE_SHEPHERD"
	npc_david.skill_level = 10
	npc_david.cccd_number = "TTG-2026-0001"
	npc_david.position = Vector3(42.0, 0.2, -206.0)
	citizens_container.add_child(npc_david)

	# 4. Kỹ Sư Tuấn (Bảo Trì Phương Tiện & Năng Lượng)
	var npc_tuan = npc_script.new()
	npc_tuan.name = "NPC_MechanicTuan"
	npc_tuan.npc_id = "mechanic_tuan"
	npc_tuan.citizen_name = "Kỹ Sư Tuấn"
	npc_tuan.age = 29
	npc_tuan.age_group = ModularHumanoidBuilder.AgeGroup.ADULT
	npc_tuan.gender = "Nam"
	npc_tuan.profession = ModularHumanoidBuilder.ProfessionType.ENGINEER
	npc_tuan.job_title = "Kỹ Sư Phương Tiện & Năng Lượng"
	npc_tuan.cert_code = "CERT_POWER_GRID"
	npc_tuan.skill_level = 8
	npc_tuan.cccd_number = "TTG-2026-0099"
	npc_tuan.position = Vector3(192.0, 0.2, 98.0)
	citizens_container.add_child(npc_tuan)

	# 5. Bác Ba (Đại Diện Cư Dân 5 Huyện)
	var npc_ba = npc_script.new()
	npc_ba.name = "NPC_ElderBa"
	npc_ba.npc_id = "elder_ba"
	npc_ba.citizen_name = "Bác Ba"
	npc_ba.age = 58
	npc_ba.age_group = ModularHumanoidBuilder.AgeGroup.ELDER
	npc_ba.gender = "Nam"
	npc_ba.profession = ModularHumanoidBuilder.ProfessionType.FARMER
	npc_ba.job_title = "Đại Diện Cư Dân 5 Huyện"
	npc_ba.cert_code = "CERT_CIVIC_ADMIN"
	npc_ba.skill_level = 8
	npc_ba.cccd_number = "TTG-2026-0045"
	npc_ba.position = Vector3(-192.0, 0.2, 98.0)
	citizens_container.add_child(npc_ba)

	return root

# ------------------------------------------------------------------------------
# HÀM TIỆN ÍCH TẠO MATERIAL & COLLIDER
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
	m.metallic = 0.4
	m.roughness = 0.1
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
	lbl.outline_size = 6
	lbl.outline_modulate = Color(0.05, 0.08, 0.14, 0.95)
	lbl.modulate = modulate
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.no_depth_test = true
	return lbl

static func _add_box_collider(parent: Node3D, size: Vector3, pos: Vector3) -> StaticBody3D:
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

static func _add_cylinder_collider(parent: Node3D, radius: float, height: float, pos: Vector3) -> StaticBody3D:
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
