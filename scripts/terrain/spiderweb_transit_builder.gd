class_name SpiderwebTransitBuilder
extends RefCounted

# ==============================================================================
# SPIDERWEB TRANSIT BUILDER - HỆ THỐNG GIAO THÔNG MẠNG NHỆN 500 KM²
# Bao gồm:
# - 5 Tuyến Vành Đai Đồng Tâm (5 Concentric Ring Roads: R = 1.5km, 5km, 7.5km, 16km, 28km)
# - 8 Trục Nan Hoa Hướng Tâm (8 Radial Spokes: N, NE, E, SE, S, SW, W, NW)
#   kết nối Thủ Phủ Trung Tâm (+600m) với 4 Huyện (Đông, Tây, Bắc, Nam)
# - Các trạm dừng chân nghỉ mát (Transit Waypoints / Bus-Tram Stops) dọc tuyến
# ==============================================================================

const ModularNatureChunkScript = preload("res://scripts/terrain/modular_nature_chunk.gd")

static func build_spiderweb_network() -> Node3D:
	var root = Node3D.new()
	root.name = "SpiderwebTransitNetwork"

	# Vật liệu mặt đường Anime Toon
	var mat_road = StandardMaterial3D.new()
	mat_road.albedo_color = Color(0.24, 0.27, 0.32) # Nhựa đường xám mịn Toon
	mat_road.roughness = 0.65
	mat_road.cull_mode = BaseMaterial3D.CULL_DISABLED

	var mat_spoke_major = StandardMaterial3D.new()
	mat_spoke_major.albedo_color = Color(0.26, 0.29, 0.35)
	mat_spoke_major.roughness = 0.6
	mat_spoke_major.cull_mode = BaseMaterial3D.CULL_DISABLED

	# 1. Xây dựng 5 Vành Đai Đồng Tâm
	var rings_node = Node3D.new()
	rings_node.name = "ConcentricRings"
	root.add_child(rings_node)

	var ring_configs = [
		{"name": "Ring1_CoreHub", "radius": 1500.0, "width": 10.0, "segments": 72},
		{"name": "Ring2_PlateauCity", "radius": 5000.0, "width": 12.0, "segments": 96},
		{"name": "Ring3_CliffParkway", "radius": 7500.0, "width": 12.0, "segments": 96},
		{"name": "Ring4_FoothillBelt", "radius": 16000.0, "width": 14.0, "segments": 120},
		{"name": "Ring5_FrontierLoop", "radius": 28000.0, "width": 14.0, "segments": 120}
	]

	for cfg in ring_configs:
		var ring_mesh = _build_ring_ribbon(cfg["radius"], cfg["width"], cfg["segments"], mat_road)
		ring_mesh.name = cfg["name"]
		rings_node.add_child(ring_mesh)

	# 2. Xây dựng 8 Trục Nan Hoa Hướng Tâm
	var spokes_node = Node3D.new()
	spokes_node.name = "RadialSpokes"
	root.add_child(spokes_node)

	var spoke_configs = [
		# 4 Trục Chính kết nối trực tiếp 4 Huyện
		{"id": "SPOKE_N", "name": "Đại Lộ Bắc (Huyện Đại Ngàn)", "dir": Vector2(0, -1), "length": 10000.0, "width": 14.0, "major": true},
		{"id": "SPOKE_E", "name": "Đại Lộ Đông (Huyện Nông Trại)", "dir": Vector2(1, 0), "length": 10000.0, "width": 14.0, "major": true},
		{"id": "SPOKE_S", "name": "Đại Lộ Nam (Huyện Duyên Hải)", "dir": Vector2(0, 1), "length": 20000.0, "width": 14.0, "major": true},
		{"id": "SPOKE_W", "name": "Đại Lộ Tây (Huyện Kỹ Nghệ)", "dir": Vector2(-1, 0), "length": 10000.0, "width": 14.0, "major": true},
		# 4 Nan Hoa Đường Chéo
		{"id": "SPOKE_NE", "name": "Nan Hoa Đông Bắc", "dir": Vector2(0.7071, -0.7071), "length": 16000.0, "width": 10.0, "major": false},
		{"id": "SPOKE_SE", "name": "Nan Hoa Đông Nam", "dir": Vector2(0.7071, 0.7071), "length": 16000.0, "width": 10.0, "major": false},
		{"id": "SPOKE_SW", "name": "Nan Hoa Tây Nam", "dir": Vector2(-0.7071, 0.7071), "length": 16000.0, "width": 10.0, "major": false},
		{"id": "SPOKE_NW", "name": "Nan Hoa Tây Bắc", "dir": Vector2(-0.7071, -0.7071), "length": 16000.0, "width": 10.0, "major": false}
	]

	for scfg in spoke_configs:
		var spoke_mat = mat_spoke_major if scfg["major"] else mat_road
		var spoke_mesh = _build_spoke_ribbon(scfg["dir"], scfg["length"], scfg["width"], spoke_mat)
		spoke_mesh.name = scfg["id"]
		spokes_node.add_child(spoke_mesh)

	# 3. Xây dựng các Trạm Dừng Chân Giao Thông Nan Hoa (Transit Waypoints / Shelters)
	var stops_node = Node3D.new()
	stops_node.name = "TransitWaypoints"
	root.add_child(stops_node)

	# Đặt trạm trên 4 trục chính tại các cự ly giao thoa Vành Đai 1, Vành Đai 2, Vành Đai 3
	var stop_radii = [1500.0, 5000.0, 7500.0]
	var major_dirs = [
		{"name": "Bắc", "dir": Vector2(0, -1)},
		{"name": "Đông", "dir": Vector2(1, 0)},
		{"name": "Nam", "dir": Vector2(0, 1)},
		{"name": "Tây", "dir": Vector2(-1, 0)}
	]

	for mdir in major_dirs:
		for r in stop_radii:
			var wx = mdir["dir"].x * r
			var wz = mdir["dir"].y * r
			var stop_station = _create_transit_stop(wx, wz, mdir["name"], r)
			stops_node.add_child(stop_station)

	print("[SpiderwebTransit] 🕸️ Đã kiến tạo hoàn chỉnh Mạng Lưới Giao Thông Mạng Nhện (5 Vành Đai, 8 Nan Hoa & 12 Trạm Dừng)!")
	return root

# Xây dựng dải ruy băng đường tròn vành đai khép kín
static func _build_ring_ribbon(radius: float, width: float, segments: int, mat: Material) -> MeshInstance3D:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var half_w = width * 0.5
	var angle_step = (PI * 2.0) / float(segments)

	for i in range(segments):
		var a0 = float(i) * angle_step
		var a1 = float(i + 1) * angle_step

		# Tọa độ tâm cung
		var c0 = Vector2(cos(a0), sin(a0)) * radius
		var c1 = Vector2(cos(a1), sin(a1)) * radius

		# Vector pháp tuyến hướng tâm
		var n0 = c0.normalized()
		var n1 = c1.normalized()

		# Độ cao địa hình thực tế
		var h0_in = ModularNatureChunkScript.get_world_height(c0.x - n0.x * half_w, c0.y - n0.y * half_w) + 0.16
		var h0_out = ModularNatureChunkScript.get_world_height(c0.x + n0.x * half_w, c0.y + n0.y * half_w) + 0.16
		var h1_in = ModularNatureChunkScript.get_world_height(c1.x - n1.x * half_w, c1.y - n1.y * half_w) + 0.16
		var h1_out = ModularNatureChunkScript.get_world_height(c1.x + n1.x * half_w, c1.y + n1.y * half_w) + 0.16

		var v0_in = Vector3(c0.x - n0.x * half_w, h0_in, c0.y - n0.y * half_w)
		var v0_out = Vector3(c0.x + n0.x * half_w, h0_out, c0.y + n0.y * half_w)
		var v1_in = Vector3(c1.x - n1.x * half_w, h1_in, c1.y - n1.y * half_w)
		var v1_out = Vector3(c1.x + n1.x * half_w, h1_out, c1.y + n1.y * half_w)

		# Quad: 2 tam giác Winding CCW
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(0.0, 0.0))
		st.add_vertex(v0_in)
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(1.0, 0.0))
		st.add_vertex(v0_out)
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(0.0, 1.0))
		st.add_vertex(v1_in)

		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(1.0, 0.0))
		st.add_vertex(v0_out)
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(1.0, 1.0))
		st.add_vertex(v1_out)
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(0.0, 1.0))
		st.add_vertex(v1_in)

	var mesh_inst = MeshInstance3D.new()
	mesh_inst.mesh = st.commit()
	mesh_inst.material_override = mat
	return mesh_inst

# Xây dựng trục nan hoa thẳng từ trung tâm ra ngoại vi bám sát địa hình
static func _build_spoke_ribbon(dir: Vector2, length: float, width: float, mat: Material) -> MeshInstance3D:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var dir_norm = dir.normalized()
	# Vector vuông góc ngang trên mặt phẳng XZ
	var perp = Vector2(-dir_norm.y, dir_norm.x)
	var half_w = width * 0.5

	var step_dist: float = 120.0 # Khoảng cách chia đốt mặt đường 120m
	var num_steps = int(ceil(length / step_dist))
	var start_offset: float = 24.0 # Xuất phát từ mép Quảng Trường Trung Tâm R=24m

	for i in range(num_steps):
		var d0 = start_offset + float(i) * step_dist
		var d1 = minf(start_offset + float(i + 1) * step_dist, length)

		var c0 = dir_norm * d0
		var c1 = dir_norm * d1

		var h0_l = ModularNatureChunkScript.get_world_height(c0.x - perp.x * half_w, c0.y - perp.y * half_w) + 0.18
		var h0_r = ModularNatureChunkScript.get_world_height(c0.x + perp.x * half_w, c0.y + perp.y * half_w) + 0.18
		var h1_l = ModularNatureChunkScript.get_world_height(c1.x - perp.x * half_w, c1.y - perp.y * half_w) + 0.18
		var h1_r = ModularNatureChunkScript.get_world_height(c1.x + perp.x * half_w, c1.y + perp.y * half_w) + 0.18

		var v0_l = Vector3(c0.x - perp.x * half_w, h0_l, c0.y - perp.y * half_w)
		var v0_r = Vector3(c0.x + perp.x * half_w, h0_r, c0.y + perp.y * half_w)
		var v1_l = Vector3(c1.x - perp.x * half_w, h1_l, c1.y - perp.y * half_w)
		var v1_r = Vector3(c1.x + perp.x * half_w, h1_r, c1.y + perp.y * half_w)

		# Quad Winding CCW
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(0.0, 0.0))
		st.add_vertex(v0_l)
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(1.0, 0.0))
		st.add_vertex(v0_r)
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(0.0, 1.0))
		st.add_vertex(v1_l)

		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(1.0, 0.0))
		st.add_vertex(v0_r)
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(1.0, 1.0))
		st.add_vertex(v1_r)
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(0.0, 1.0))
		st.add_vertex(v1_l)

	var mesh_inst = MeshInstance3D.new()
	mesh_inst.mesh = st.commit()
	mesh_inst.material_override = mat
	return mesh_inst

# Tạo trạm dừng chân giao thông (Shelter + Ghế + Đèn đường + Bảng tên Diegetic)
static func _create_transit_stop(wx: float, wz: float, direction_name: String, radius_m: float) -> Node3D:
	var node = Node3D.new()
	var ground_y = ModularNatureChunkScript.get_world_height(wx, wz)
	node.position = Vector3(wx, ground_y, wz)
	node.name = "TransitStop_%s_%.0fm" % [direction_name, radius_m]
	node.add_to_group("transit_stations")

	# 1. Bệ đứng chờ xe (Platform)
	var plat_mesh = BoxMesh.new()
	plat_mesh.size = Vector3(8.0, 0.3, 4.0)
	var mat_plat = StandardMaterial3D.new()
	mat_plat.albedo_color = Color(0.85, 0.85, 0.82)
	var plat_inst = MeshInstance3D.new()
	plat_inst.mesh = plat_mesh
	plat_inst.material_override = mat_plat
	plat_inst.position.y = 0.15
	node.add_child(plat_inst)

	# 2. Mái che kính đón gió Toon (Glass Canopy)
	var roof_mesh = BoxMesh.new()
	roof_mesh.size = Vector3(8.2, 0.15, 3.6)
	var mat_glass = StandardMaterial3D.new()
	mat_glass.albedo_color = Color(0.25, 0.70, 0.85, 0.70)
	mat_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var roof_inst = MeshInstance3D.new()
	roof_inst.mesh = roof_mesh
	roof_inst.material_override = mat_glass
	roof_inst.position = Vector3(0.0, 3.2, 0.0)
	node.add_child(roof_inst)

	# 2 Trụ thép vàng chống mái
	for px in [-3.6, 3.6]:
		var col_m = CylinderMesh.new()
		col_m.top_radius = 0.08
		col_m.bottom_radius = 0.08
		col_m.height = 3.2
		var mat_gold = StandardMaterial3D.new()
		mat_gold.albedo_color = Color(0.95, 0.82, 0.25)
		mat_gold.metallic = 0.8
		var col_inst = MeshInstance3D.new()
		col_inst.mesh = col_m
		col_inst.material_override = mat_gold
		col_inst.position = Vector3(px, 1.6, 0.0)
		node.add_child(col_inst)

	# 3. Ghế gỗ chờ xe
	var bench_m = BoxMesh.new()
	bench_m.size = Vector3(4.0, 0.45, 0.8)
	var mat_wood = StandardMaterial3D.new()
	mat_wood.albedo_color = Color(0.48, 0.30, 0.18)
	var bench_inst = MeshInstance3D.new()
	bench_inst.mesh = bench_m
	bench_inst.material_override = mat_wood
	bench_inst.position = Vector3(0.0, 0.45, -0.8)
	node.add_child(bench_inst)

	# 4. Đèn đường năng lượng mặt trời (Solar Streetlight)
	var lamp_light = OmniLight3D.new()
	lamp_light.light_color = Color(1.0, 0.90, 0.65)
	lamp_light.light_energy = 2.5
	lamp_light.omni_range = 15.0
	lamp_light.position = Vector3(0.0, 3.5, 0.0)
	node.add_child(lamp_light)

	# 5. Bảng thông tin 3D Diegetic hiển thị lộ trình (RULE 8: DIEGETIC_UI_PROMPT_VISIBILITY_STANDARD)
	var label_3d = Label3D.new()
	label_3d.name = "StationSign3D"
	var dist_km = radius_m / 1000.0
	label_3d.text = "🚏 TRẠM NGHỈ CHÂN NAN HOA %s (%.1f KM)\n[Bus BRT ⇄ Metro Xuyên Núi ⇄ Buggy Điện]" % [direction_name.to_upper(), dist_km]
	label_3d.font_size = 22
	label_3d.outline_size = 8
	label_3d.outline_modulate = Color(0.05, 0.08, 0.12, 0.95)
	label_3d.modulate = Color(1.0, 0.92, 0.35)
	label_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label_3d.no_depth_test = true
	label_3d.position = Vector3(0.0, 4.2, 0.0)
	node.add_child(label_3d)

	return node
