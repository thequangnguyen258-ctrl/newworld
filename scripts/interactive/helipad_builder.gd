class_name HelipadBuilder
extends RefCounted

# ==============================================================================
# HELIPAD BUILDER - TẠO SÂN ĐỖ TRỰC THĂNG ANIME CHUẨN ĐỒ HỌA CAO CẤP
# Nền bê tông xám đậm, vòng tròn vàng, ký hiệu chữ [ H ], 4 đèn tín hiệu chớp
# ==============================================================================

static func build_helipad() -> Node3D:
	var helipad_node = Node3D.new()
	helipad_node.name = "Helipad"

	# 1. Mặt sàn bê tông tròn bát giác (Bán kính 6.5m)
	var pad_mesh = CylinderMesh.new()
	pad_mesh.top_radius = 6.5
	pad_mesh.bottom_radius = 6.6
	pad_mesh.height = 0.25
	
	var mat_concrete = StandardMaterial3D.new()
	mat_concrete.albedo_color = Color(0.22, 0.25, 0.30)
	mat_concrete.roughness = 0.85
	
	var pad_inst = MeshInstance3D.new()
	pad_inst.mesh = pad_mesh
	pad_inst.material_override = mat_concrete
	pad_inst.position = Vector3(0, 0.125, 0)
	helipad_node.add_child(pad_inst)

	# 2. Vòng tròn biên cảnh báo sơn vàng phản quang (Radius 5.5m)
	var ring_mesh = TorusMesh.new()
	ring_mesh.inner_radius = 5.2
	ring_mesh.outer_radius = 5.6
	
	var mat_yellow = StandardMaterial3D.new()
	mat_yellow.albedo_color = Color(0.96, 0.82, 0.15)
	mat_yellow.roughness = 0.3
	mat_yellow.emission_enabled = true
	mat_yellow.emission = Color(0.96, 0.82, 0.15)
	mat_yellow.emission_energy_multiplier = 0.4
	
	var ring_inst = MeshInstance3D.new()
	ring_inst.mesh = ring_mesh
	ring_inst.material_override = mat_yellow
	ring_inst.position = Vector3(0, 0.26, 0)
	helipad_node.add_child(ring_inst)

	# 3. Ký hiệu chữ [ H ] màu vàng lớn ở tâm (Chiều rộng 3.2m, Chiều cao 3.8m)
	# Hai vạch đứng
	for x_offset in [-1.4, 1.4]:
		var bar_mesh = BoxMesh.new()
		bar_mesh.size = Vector3(0.55, 0.04, 3.6)
		var bar_inst = MeshInstance3D.new()
		bar_inst.mesh = bar_mesh
		bar_inst.material_override = mat_yellow
		bar_inst.position = Vector3(x_offset, 0.26, 0)
		helipad_node.add_child(bar_inst)

	# Thanh ngang nối giữa chữ H
	var cross_mesh = BoxMesh.new()
	cross_mesh.size = Vector3(2.4, 0.04, 0.55)
	var cross_inst = MeshInstance3D.new()
	cross_inst.mesh = cross_mesh
	cross_inst.material_override = mat_yellow
	cross_inst.position = Vector3(0, 0.26, 0)
	helipad_node.add_child(cross_inst)

	# 4. Bốn góc đèn hạ cánh Amber (Vàng hổ phách)
	var corners = [
		Vector3(-5.2, 0.35, -5.2),
		Vector3(5.2, 0.35, -5.2),
		Vector3(-5.2, 0.35, 5.2),
		Vector3(5.2, 0.35, 5.2)
	]
	
	var mat_beacon = StandardMaterial3D.new()
	mat_beacon.albedo_color = Color(1.0, 0.65, 0.1)
	mat_beacon.emission_enabled = true
	mat_beacon.emission = Color(1.0, 0.65, 0.1)
	mat_beacon.emission_energy_multiplier = 2.0

	for c_pos in corners:
		var post_mesh = CylinderMesh.new()
		post_mesh.top_radius = 0.08
		post_mesh.bottom_radius = 0.12
		post_mesh.height = 0.4
		var post_inst = MeshInstance3D.new()
		post_inst.mesh = post_mesh
		post_inst.material_override = mat_concrete
		post_inst.position = Vector3(c_pos.x, 0.2, c_pos.z)
		helipad_node.add_child(post_inst)

		var bulb_mesh = SphereMesh.new()
		bulb_mesh.radius = 0.12
		bulb_mesh.height = 0.24
		var bulb_inst = MeshInstance3D.new()
		bulb_inst.mesh = bulb_mesh
		bulb_inst.material_override = mat_beacon
		bulb_inst.position = c_pos
		helipad_node.add_child(bulb_inst)

		var light = OmniLight3D.new()
		light.light_color = Color(1.0, 0.7, 0.15)
		light.light_energy = 1.2
		light.omni_range = 6.0
		light.position = c_pos + Vector3(0, 0.1, 0)
		helipad_node.add_child(light)

	return helipad_node
