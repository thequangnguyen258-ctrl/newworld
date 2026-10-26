class_name HelicopterModelBuilder
extends RefCounted

# ==============================================================================
# HELICOPTER MODEL BUILDER - TẠO HÌNH 3D TRỰC THĂNG CAO TỐC THỊ TRƯỞNG
# Phong cách: Anime / Ghibli Stylized Sci-Fi Tech
# Tông màu: Xanh Hoàng Gia (Royal Blue), Chỉ Vàng Kim (Gold Trim), Kính Sky-Blue
# Phụ kiện: Động cơ phản lực kép (Twin Turbo Jets), Skids crôm, Đèn hàng hải
# ==============================================================================

static func build_helicopter() -> Dictionary:
	var root = Node3D.new()
	root.name = "HelicopterVisual"

	# --------------------------------------------------------------------------
	# 1. VẬT LIỆU TOON STYLIZED (ANIME MATERIALS)
	# --------------------------------------------------------------------------
	# Vỏ thân xanh hoàng gia
	var mat_body = StandardMaterial3D.new()
	mat_body.albedo_color = Color(0.12, 0.28, 0.72) # Royal Blue
	mat_body.metallic = 0.35
	mat_body.roughness = 0.30

	# Chỉ viền & huy hiệu vàng kim Thị Trưởng
	var mat_gold = StandardMaterial3D.new()
	mat_gold.albedo_color = Color(0.96, 0.76, 0.15) # Gold
	mat_gold.metallic = 0.75
	mat_gold.roughness = 0.20

	# Vòm kính buồng lái Anime
	var mat_glass = StandardMaterial3D.new()
	mat_glass.albedo_color = Color(0.35, 0.78, 0.98, 0.50)
	mat_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_glass.roughness = 0.08
	mat_glass.metallic = 0.2

	# Kim loại xám đậm / Carbon cho cánh quạt & động cơ
	var mat_carbon = StandardMaterial3D.new()
	mat_carbon.albedo_color = Color(0.16, 0.18, 0.22)
	mat_carbon.roughness = 0.40

	# Càng đáp crôm sáng bóng
	var mat_chrome = StandardMaterial3D.new()
	mat_chrome.albedo_color = Color(0.85, 0.88, 0.92)
	mat_chrome.metallic = 0.85
	mat_chrome.roughness = 0.15

	# Mũi cánh quạt cảnh báo vàng an toàn
	var mat_warning = StandardMaterial3D.new()
	mat_warning.albedo_color = Color(1.0, 0.82, 0.05)
	mat_warning.emission_enabled = true
	mat_warning.emission = Color(1.0, 0.80, 0.0)
	mat_warning.emission_energy_multiplier = 0.4

	# Luồng xả phản lực Turbo Cyan
	var mat_turbo = StandardMaterial3D.new()
	mat_turbo.albedo_color = Color(0.2, 0.85, 1.0)
	mat_turbo.emission_enabled = true
	mat_turbo.emission = Color(0.3, 0.9, 1.0)
	mat_turbo.emission_energy_multiplier = 2.0

	# --------------------------------------------------------------------------
	# 2. THÂN CHÍNH (FUSELAGE)
	# --------------------------------------------------------------------------
	var fuselage = Node3D.new()
	fuselage.name = "Fuselage"
	root.add_child(fuselage)

	# Khoang hành khách & phi công (Bo cong mượt mà)
	var cabin_mesh = BoxMesh.new()
	cabin_mesh.size = Vector3(1.9, 1.6, 3.8)
	var cabin_inst = MeshInstance3D.new()
	cabin_inst.mesh = cabin_mesh
	cabin_inst.material_override = mat_body
	cabin_inst.position = Vector3(0, 1.1, 0)
	fuselage.add_child(cabin_inst)

	# Nắp động cơ trên nóc (Roof Cowling)
	var roof_mesh = BoxMesh.new()
	roof_mesh.size = Vector3(1.3, 0.55, 2.8)
	var roof_inst = MeshInstance3D.new()
	roof_inst.mesh = roof_mesh
	roof_inst.material_override = mat_carbon
	roof_inst.position = Vector3(0, 2.05, 0.2)
	fuselage.add_child(roof_inst)

	# Dải sọc viền vàng hoàng gia hai bên hông
	var stripe_mesh = BoxMesh.new()
	stripe_mesh.size = Vector3(1.94, 0.16, 3.4)
	var stripe_inst = MeshInstance3D.new()
	stripe_inst.mesh = stripe_mesh
	stripe_inst.material_override = mat_gold
	stripe_inst.position = Vector3(0, 1.1, 0.1)
	fuselage.add_child(stripe_inst)

	# --------------------------------------------------------------------------
	# 3. KÍNH VÒM BUỒNG LÁI (BUBBLE COCKPIT CANOPY)
	# --------------------------------------------------------------------------
	var canopy_mesh = BoxMesh.new()
	canopy_mesh.size = Vector3(1.82, 1.35, 1.7)
	var canopy_inst = MeshInstance3D.new()
	canopy_inst.mesh = canopy_mesh
	canopy_inst.material_override = mat_glass
	canopy_inst.position = Vector3(0, 1.25, -1.35)
	canopy_inst.rotation_degrees = Vector3(-15.0, 0, 0) # Vát khí động học
	fuselage.add_child(canopy_inst)

	# Ghế phi công bên trong buồng lái
	for x_side in [-0.42, 0.42]:
		var seat_mesh = BoxMesh.new()
		seat_mesh.size = Vector3(0.5, 0.7, 0.55)
		var seat_inst = MeshInstance3D.new()
		seat_inst.mesh = seat_mesh
		seat_inst.material_override = mat_carbon
		seat_inst.position = Vector3(x_side, 1.0, -1.2)
		fuselage.add_child(seat_inst)

	# --------------------------------------------------------------------------
	# 4. ĐUÔI PHI THUYỀN (TAIL BOOM & STABILIZERS)
	# --------------------------------------------------------------------------
	var boom_mesh = CylinderMesh.new()
	boom_mesh.top_radius = 0.22
	boom_mesh.bottom_radius = 0.38
	boom_mesh.height = 4.6
	var boom_inst = MeshInstance3D.new()
	boom_inst.mesh = boom_mesh
	boom_inst.material_override = mat_body
	boom_inst.rotation_degrees = Vector3(90.0, 0, 0)
	boom_inst.position = Vector3(0, 1.3, 3.8)
	fuselage.add_child(boom_inst)

	# Vây đuôi đứng (Vertical Tail Fin)
	var v_fin_mesh = BoxMesh.new()
	v_fin_mesh.size = Vector3(0.12, 1.6, 1.1)
	var v_fin_inst = MeshInstance3D.new()
	v_fin_inst.mesh = v_fin_mesh
	v_fin_inst.material_override = mat_body
	v_fin_inst.position = Vector3(0, 1.9, 6.0)
	v_fin_inst.rotation_degrees = Vector3(25.0, 0, 0) # Nghiêng về sau
	fuselage.add_child(v_fin_inst)

	# Đỉnh vây đuôi viền vàng
	var fin_top_mesh = BoxMesh.new()
	fin_top_mesh.size = Vector3(0.14, 0.22, 1.0)
	var fin_top_inst = MeshInstance3D.new()
	fin_top_inst.mesh = fin_top_mesh
	fin_top_inst.material_override = mat_gold
	fin_top_inst.position = Vector3(0, 2.65, 6.25)
	fin_top_inst.rotation_degrees = Vector3(25.0, 0, 0)
	fuselage.add_child(fin_top_inst)

	# Cánh đuôi ngang (Horizontal Stabilizers)
	var h_fin_mesh = BoxMesh.new()
	h_fin_mesh.size = Vector3(1.9, 0.08, 0.55)
	var h_fin_inst = MeshInstance3D.new()
	h_fin_inst.mesh = h_fin_mesh
	h_fin_inst.material_override = mat_gold
	h_fin_inst.position = Vector3(0, 1.5, 5.2)
	fuselage.add_child(h_fin_inst)

	# --------------------------------------------------------------------------
	# 5. CÀNG ĐÁP CRÔM (LANDING SKIDS)
	# --------------------------------------------------------------------------
	for skid_x in [-0.95, 0.95]:
		# Thanh trượt dài dưới đất
		var skid_mesh = CylinderMesh.new()
		skid_mesh.top_radius = 0.055
		skid_mesh.bottom_radius = 0.055
		skid_mesh.height = 4.2
		var skid_inst = MeshInstance3D.new()
		skid_inst.mesh = skid_mesh
		skid_inst.material_override = mat_chrome
		skid_inst.rotation_degrees = Vector3(90.0, 0, 0)
		skid_inst.position = Vector3(skid_x, 0.10, 0.1)
		fuselage.add_child(skid_inst)

		# Mũi cong phía trước
		var skid_nose_mesh = CylinderMesh.new()
		skid_nose_mesh.top_radius = 0.055
		skid_nose_mesh.bottom_radius = 0.055
		skid_nose_mesh.height = 0.65
		var skid_nose = MeshInstance3D.new()
		skid_nose.mesh = skid_nose_mesh
		skid_nose.material_override = mat_chrome
		skid_nose.rotation_degrees = Vector3(55.0, 0, 0)
		skid_nose.position = Vector3(skid_x, 0.28, -2.15)
		fuselage.add_child(skid_nose)

		# Chân chống nối lên thân (2 trụ trước/sau)
		for strut_z in [-1.0, 1.1]:
			var strut_mesh = CylinderMesh.new()
			strut_mesh.top_radius = 0.045
			strut_mesh.bottom_radius = 0.045
			strut_mesh.height = 0.85
			var strut_inst = MeshInstance3D.new()
			strut_inst.mesh = strut_mesh
			strut_inst.material_override = mat_chrome
			strut_inst.position = Vector3(skid_x * 0.75, 0.45, strut_z)
			strut_inst.rotation_degrees = Vector3(0, 0, 16.0 if skid_x < 0 else -16.0)
			fuselage.add_child(strut_inst)

	# --------------------------------------------------------------------------
	# 6. ĐỘNG CƠ PHẢN LỰC KÉP TURBO (TWIN TURBO BOOSTERS)
	# --------------------------------------------------------------------------
	var turbo_nozzles: Array[MeshInstance3D] = []
	var turbo_lights: Array[OmniLight3D] = []

	for j_side in [-1.22, 1.22]:
		var pod_mesh = CylinderMesh.new()
		pod_mesh.top_radius = 0.26
		pod_mesh.bottom_radius = 0.28
		pod_mesh.height = 1.6
		var pod_inst = MeshInstance3D.new()
		pod_inst.mesh = pod_mesh
		pod_inst.material_override = mat_carbon
		pod_inst.rotation_degrees = Vector3(90.0, 0, 0)
		pod_inst.position = Vector3(j_side, 1.2, 0.2)
		fuselage.add_child(pod_inst)

		# Vành hút khí phía trước mạ vàng
		var intake_mesh = CylinderMesh.new()
		intake_mesh.top_radius = 0.27
		intake_mesh.bottom_radius = 0.27
		intake_mesh.height = 0.15
		var intake_inst = MeshInstance3D.new()
		intake_inst.mesh = intake_mesh
		intake_inst.material_override = mat_gold
		intake_inst.rotation_degrees = Vector3(90.0, 0, 0)
		intake_inst.position = Vector3(j_side, 1.2, -0.6)
		fuselage.add_child(intake_inst)

		# Miệng ống xả phản lực phát sáng Cyan
		var nozzle_mesh = CylinderMesh.new()
		nozzle_mesh.top_radius = 0.20
		nozzle_mesh.bottom_radius = 0.22
		nozzle_mesh.height = 0.18
		var nozzle_inst = MeshInstance3D.new()
		nozzle_inst.mesh = nozzle_mesh
		nozzle_inst.material_override = mat_turbo
		nozzle_inst.rotation_degrees = Vector3(90.0, 0, 0)
		nozzle_inst.position = Vector3(j_side, 1.2, 1.05)
		fuselage.add_child(nozzle_inst)
		turbo_nozzles.append(nozzle_inst)

		# Đèn quầng sáng phản lực
		var jet_light = OmniLight3D.new()
		jet_light.light_color = Color(0.25, 0.85, 1.0)
		jet_light.light_energy = 0.8
		jet_light.omni_range = 4.0
		jet_light.position = Vector3(j_side, 1.2, 1.3)
		fuselage.add_child(jet_light)
		turbo_lights.append(jet_light)

	# --------------------------------------------------------------------------
	# 7. CỤM CÁNH QUẠT CHÍNH (MAIN ROTOR ASSEMBLY)
	# --------------------------------------------------------------------------
	var main_rotor_pivot = Node3D.new()
	main_rotor_pivot.name = "MainRotor"
	main_rotor_pivot.position = Vector3(0, 2.40, 0.2)
	fuselage.add_child(main_rotor_pivot)

	# Trục quay (Mast)
	var mast_mesh = CylinderMesh.new()
	mast_mesh.top_radius = 0.12
	mast_mesh.bottom_radius = 0.14
	mast_mesh.height = 0.55
	var mast_inst = MeshInstance3D.new()
	mast_inst.mesh = mast_mesh
	mast_inst.material_override = mat_chrome
	mast_inst.position = Vector3(0, -0.15, 0)
	main_rotor_pivot.add_child(mast_inst)

	# Trục trung tâm (Hub)
	var hub_mesh = CylinderMesh.new()
	hub_mesh.top_radius = 0.32
	hub_mesh.bottom_radius = 0.32
	hub_mesh.height = 0.18
	var hub_inst = MeshInstance3D.new()
	hub_inst.mesh = hub_mesh
	hub_inst.material_override = mat_gold
	main_rotor_pivot.add_child(hub_inst)

	# 4 Cánh quạt chính (4 Blades - Sải cánh 7.2m uy lực)
	var blade_radius: float = 3.6
	for i in range(4):
		var angle_rad = float(i) * (PI * 0.5)
		var blade_anchor = Node3D.new()
		blade_anchor.rotation.y = angle_rad
		main_rotor_pivot.add_child(blade_anchor)

		# Thân cánh carbon đen
		var blade_mesh = BoxMesh.new()
		blade_mesh.size = Vector3(0.24, 0.03, blade_radius * 0.85)
		var blade_inst = MeshInstance3D.new()
		blade_inst.mesh = blade_mesh
		blade_inst.material_override = mat_carbon
		blade_inst.position = Vector3(0, 0, (blade_radius * 0.85) * 0.5 + 0.25)
		blade_anchor.add_child(blade_inst)

		# Đầu cánh quạt vàng phản quang (Safety Tip)
		var tip_mesh = BoxMesh.new()
		tip_mesh.size = Vector3(0.26, 0.035, blade_radius * 0.15)
		var tip_inst = MeshInstance3D.new()
		tip_inst.mesh = tip_mesh
		tip_inst.material_override = mat_warning
		tip_inst.position = Vector3(0, 0, blade_radius * 0.85 + (blade_radius * 0.15) * 0.5 + 0.25)
		blade_anchor.add_child(tip_inst)

	# --------------------------------------------------------------------------
	# 8. CỤM CÁNH QUẠT ĐUÔI (TAIL ROTOR ASSEMBLY)
	# --------------------------------------------------------------------------
	var tail_rotor_pivot = Node3D.new()
	tail_rotor_pivot.name = "TailRotor"
	tail_rotor_pivot.position = Vector3(0.22, 2.1, 6.35)
	fuselage.add_child(tail_rotor_pivot)

	var tail_hub = CylinderMesh.new()
	tail_hub.top_radius = 0.12
	tail_hub.bottom_radius = 0.12
	tail_hub.height = 0.14
	var tail_hub_inst = MeshInstance3D.new()
	tail_hub_inst.mesh = tail_hub
	tail_hub_inst.material_override = mat_gold
	tail_hub_inst.rotation_degrees = Vector3(0, 0, 90.0)
	tail_rotor_pivot.add_child(tail_hub_inst)

	# 3 Cánh quạt đuôi quay tốc độ cực nhanh
	for t in range(3):
		var t_angle = float(t) * (PI * 2.0 / 3.0)
		var t_anchor = Node3D.new()
		t_anchor.rotation.x = t_angle
		tail_rotor_pivot.add_child(t_anchor)

		var t_blade_mesh = BoxMesh.new()
		t_blade_mesh.size = Vector3(0.02, 0.85, 0.11)
		var t_blade_inst = MeshInstance3D.new()
		t_blade_inst.mesh = t_blade_mesh
		t_blade_inst.material_override = mat_carbon
		t_blade_inst.position = Vector3(0, 0.42, 0)
		t_anchor.add_child(t_blade_inst)

		var t_tip_mesh = BoxMesh.new()
		t_tip_mesh.size = Vector3(0.025, 0.20, 0.12)
		var t_tip_inst = MeshInstance3D.new()
		t_tip_inst.mesh = t_tip_mesh
		t_tip_inst.material_override = mat_warning
		t_tip_inst.position = Vector3(0, 0.75, 0)
		t_anchor.add_child(t_tip_inst)

	# --------------------------------------------------------------------------
	# 9. ĐÈN TÍN HIỆU HÀNG HẢI & PHA DẪN ĐƯỜNG (NAV & SEARCH LIGHTS)
	# --------------------------------------------------------------------------
	# Đèn mạn trái (Port - Đỏ)
	var light_red = OmniLight3D.new()
	light_red.light_color = Color(1.0, 0.1, 0.1)
	light_red.light_energy = 0.9
	light_red.omni_range = 2.5
	light_red.position = Vector3(-1.05, 1.1, 0.5)
	fuselage.add_child(light_red)

	# Đèn mạn phải (Starboard - Xanh lá)
	var light_green = OmniLight3D.new()
	light_green.light_color = Color(0.1, 1.0, 0.2)
	light_green.light_energy = 0.9
	light_green.omni_range = 2.5
	light_green.position = Vector3(1.05, 1.1, 0.5)
	fuselage.add_child(light_green)

	# Đèn pha chiếu rọi mặt đất (Landing Searchlight ở mũi trực thăng)
	var search_light = SpotLight3D.new()
	search_light.name = "Searchlight"
	search_light.light_color = Color(1.0, 0.95, 0.85)
	search_light.light_energy = 2.8
	search_light.spot_range = 65.0
	search_light.spot_angle = 38.0
	search_light.position = Vector3(0, 0.6, -1.9)
	search_light.rotation_degrees = Vector3(-25.0, 0, 0) # Rọi chếch xuống mặt đất
	fuselage.add_child(search_light)

	return {
		"root": root,
		"fuselage": fuselage,
		"main_rotor": main_rotor_pivot,
		"tail_rotor": tail_rotor_pivot,
		"turbo_nozzles": turbo_nozzles,
		"turbo_lights": turbo_lights,
		"search_light": search_light
	}
