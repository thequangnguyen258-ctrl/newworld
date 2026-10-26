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

## EXP-02: Lớp xe Bus Điện BRT chạy liên huyện
class BRTBusCar extends Node3D:
	var spoke_name: String = "Đông"
	var spoke_dir: Vector2 = Vector2(1, 0)
	var min_radius: float = 1200.0
	var max_radius: float = 10000.0
	var current_radius: float = 1500.0
	var speed: float = 35.0
	var direction: float = 1.0
	var station_dwell_seconds: float = 6.0
	var dwell_remaining: float = 0.0
	var passenger_ref: Node3D = null
	var _saved_passenger_layer: int = 2
	var _saved_passenger_mask: int = 1
	var stop_radii: Array = [1500.0, 5000.0, 7500.0, 10000.0]

	func _ready() -> void:
		add_to_group("brt_buses")
		_update_bus_transform()

	func _process(delta: float) -> void:
		if dwell_remaining > 0.0:
			dwell_remaining = maxf(0.0, dwell_remaining - delta)
		else:
			var prev_r = current_radius
			current_radius += speed * direction * delta
			for r_val in stop_radii:
				var r: float = float(r_val)
				if r >= min_radius and r <= max_radius:
					if (direction > 0.0 and prev_r < r and current_radius >= r) or (direction < 0.0 and prev_r > r and current_radius <= r):
						current_radius = r
						dwell_remaining = station_dwell_seconds
						break

			if current_radius >= max_radius:
				current_radius = max_radius
				direction = -1.0
				dwell_remaining = station_dwell_seconds
			elif current_radius <= min_radius:
				current_radius = min_radius
				direction = 1.0
				dwell_remaining = station_dwell_seconds

			_update_bus_transform()

		if passenger_ref and is_instance_valid(passenger_ref):
			passenger_ref.global_position = global_position + Vector3(0.0, 1.2, 0.0)
			passenger_ref.global_rotation.y = global_rotation.y

	func _update_bus_transform() -> void:
		var wx = spoke_dir.x * current_radius
		var wz = spoke_dir.y * current_radius
		var wy = ModularNatureChunkScript.get_world_height(wx, wz) + 0.4
		global_position = Vector3(wx, wy, wz)
		var forward_xz = Vector2(spoke_dir.x * direction, spoke_dir.y * direction)
		rotation.y = atan2(-forward_xz.x, -forward_xz.y)

	func _unhandled_input(event: InputEvent) -> void:
		if passenger_ref == null:
			if event is InputEventKey and event.pressed and not event.echo:
				if event.physical_keycode == KEY_E or event.physical_keycode == KEY_F:
					var player = get_tree().get_first_node_in_group("player")
					if player and global_position.distance_to(player.global_position) <= 8.0:
						board_from_stop(player, global_position)
						get_viewport().set_input_as_handled()
			return
		if event is InputEventKey and event.pressed and not event.echo:
			if event.physical_keycode == KEY_E or event.physical_keycode == KEY_F:
				exit_bus()
				get_viewport().set_input_as_handled()
			elif event.physical_keycode >= KEY_1 and event.physical_keycode <= KEY_4:
				var target_idx = event.physical_keycode - KEY_1
				if target_idx < stop_radii.size():
					current_radius = float(stop_radii[target_idx])
					dwell_remaining = station_dwell_seconds
					_update_bus_transform()
					var hud = get_tree().get_first_node_in_group("hud")
					if hud and hud.has_method("show_toast"):
						hud.show_toast("⚡ [BRT Express] Đã di chuyển nhanh tới Trạm %s (%.1f KM)!" % [spoke_name, current_radius / 1000.0])
					get_viewport().set_input_as_handled()

	func board_from_stop(player: Node3D, stop_position: Vector3) -> bool:
		if passenger_ref != null or global_position.distance_to(stop_position) > 12.0:
			return false

		passenger_ref = player
		if player is CollisionObject3D:
			_saved_passenger_layer = player.collision_layer
			_saved_passenger_mask = player.collision_mask
			player.collision_layer = 0
			player.collision_mask = 0
		player.visible = false
		player.set_physics_process(false)
		player.set_meta("occupied_brt", self)
		if player.has_meta("nearby_interactive"):
			player.remove_meta("nearby_interactive")
		player.global_position = global_position + Vector3(0.0, 1.2, 0.0)

		var hud = get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("show_toast"):
			hud.show_toast("🚌 Đã lên Xe Bus Điện BRT (%s). [E]/[F]: Xuống xe | [1]-[4]: Chuyển nhanh giữa các trạm." % spoke_name)
		return true

	func exit_bus() -> void:
		if passenger_ref == null or not is_instance_valid(passenger_ref):
			passenger_ref = null
			return

		var passenger = passenger_ref
		passenger_ref = null
		passenger.global_position = global_position + global_transform.basis.x * 4.0 + Vector3(0.0, 0.5, 0.0)
		if passenger is CollisionObject3D:
			passenger.collision_layer = _saved_passenger_layer if _saved_passenger_layer != 0 else 2
			passenger.collision_mask = _saved_passenger_mask if _saved_passenger_mask != 0 else 1
		passenger.visible = true
		passenger.set_physics_process(true)
		if passenger.has_meta("occupied_brt"):
			passenger.remove_meta("occupied_brt")

		var hud = get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("show_toast"):
			hud.show_toast("🚌 Bạn đã xuống xe bus BRT an toàn.")

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

	# 4. EXP-02: Đội Xe Bus Điện BRT Chạy Dọc 4 Trục Hướng Tâm (Spiderweb BRT Fleet)
	var brt_node = Node3D.new()
	brt_node.name = "BRTFleet"
	root.add_child(brt_node)

	var brt_configs = [
		{"name": "Bắc", "dir": Vector2(0, -1), "max_r": 10000.0, "stops": [1500.0, 5000.0, 7500.0, 10000.0]},
		{"name": "Đông", "dir": Vector2(1, 0), "max_r": 10000.0, "stops": [1500.0, 5000.0, 7500.0, 10000.0]},
		{"name": "Nam", "dir": Vector2(0, 1), "max_r": 20000.0, "stops": [1500.0, 5000.0, 7500.0, 15000.0, 20000.0]},
		{"name": "Tây", "dir": Vector2(-1, 0), "max_r": 10000.0, "stops": [1500.0, 5000.0, 7500.0, 10000.0]}
	]

	for bcfg in brt_configs:
		var bus1 = BRTBusCar.new()
		bus1.name = "BRTBus_" + bcfg["name"] + "_01"
		bus1.spoke_name = bcfg["name"]
		bus1.spoke_dir = bcfg["dir"]
		bus1.max_radius = bcfg["max_r"]
		bus1.current_radius = 1600.0
		bus1.direction = 1.0
		bus1.stop_radii = bcfg["stops"]
		brt_node.add_child(bus1)
		_build_brt_visuals(bus1, bcfg["name"])

		var bus2 = BRTBusCar.new()
		bus2.name = "BRTBus_" + bcfg["name"] + "_02"
		bus2.spoke_name = bcfg["name"]
		bus2.spoke_dir = bcfg["dir"]
		bus2.max_radius = bcfg["max_r"]
		bus2.current_radius = bcfg["max_r"] - 600.0
		bus2.direction = -1.0
		bus2.stop_radii = bcfg["stops"]
		brt_node.add_child(bus2)
		_build_brt_visuals(bus2, bcfg["name"])

	print("[SpiderwebTransit] 🕸️ Đã kiến tạo hoàn chỉnh Mạng Lưới Giao Thông Mạng Nhện (5 Vành Đai, 8 Nan Hoa, 12 Trạm Dừng & Đội Xe BRT)!")
	return root

static func _build_brt_visuals(bus: BRTBusCar, spoke_name: String) -> void:
	var mat_bus_teal = StandardMaterial3D.new()
	mat_bus_teal.albedo_color = Color(0.16, 0.62, 0.58)
	mat_bus_teal.roughness = 0.4
	mat_bus_teal.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON

	var mat_bus_cream = StandardMaterial3D.new()
	mat_bus_cream.albedo_color = Color(0.96, 0.93, 0.82)
	mat_bus_cream.roughness = 0.5

	var mat_glass = StandardMaterial3D.new()
	mat_glass.albedo_color = Color(0.35, 0.75, 0.90, 0.75)
	mat_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	var mat_wheel = StandardMaterial3D.new()
	mat_wheel.albedo_color = Color(0.15, 0.15, 0.18)

	var body_mesh = BoxMesh.new()
	body_mesh.size = Vector3(2.8, 2.6, 9.2)
	var body_inst = MeshInstance3D.new()
	body_inst.mesh = body_mesh
	body_inst.material_override = mat_bus_teal
	body_inst.position.y = 1.6
	bus.add_child(body_inst)

	var stripe_mesh = BoxMesh.new()
	stripe_mesh.size = Vector3(2.85, 0.6, 9.25)
	var stripe_inst = MeshInstance3D.new()
	stripe_inst.mesh = stripe_mesh
	stripe_inst.material_override = mat_bus_cream
	stripe_inst.position.y = 1.2
	bus.add_child(stripe_inst)

	var glass_mesh = BoxMesh.new()
	glass_mesh.size = Vector3(2.86, 0.9, 7.8)
	var glass_inst = MeshInstance3D.new()
	glass_inst.mesh = glass_mesh
	glass_inst.material_override = mat_glass
	glass_inst.position.y = 2.1
	bus.add_child(glass_inst)

	for wz in [-2.8, 2.8]:
		for wx in [-1.45, 1.45]:
			var wh_mesh = CylinderMesh.new()
			wh_mesh.top_radius = 0.5
			wh_mesh.bottom_radius = 0.5
			wh_mesh.height = 0.35
			var wh_inst = MeshInstance3D.new()
			wh_inst.mesh = wh_mesh
			wh_inst.material_override = mat_wheel
			wh_inst.rotation.z = PI * 0.5
			wh_inst.position = Vector3(wx, 0.5, wz)
			bus.add_child(wh_inst)

	var sign_lbl = Label3D.new()
	sign_lbl.text = "🚌 BUS ĐIỆN BRT — TUYẾN %s" % spoke_name.to_upper()
	sign_lbl.font_size = 28
	sign_lbl.modulate = Color(1.0, 0.92, 0.35)
	sign_lbl.outline_size = 8
	sign_lbl.outline_modulate = Color(0.05, 0.08, 0.12)
	sign_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign_lbl.no_depth_test = true
	sign_lbl.position = Vector3(0.0, 3.4, 0.0)
	bus.add_child(sign_lbl)

	var area = Area3D.new()
	area.name = "BRTInteractionArea"
	area.collision_layer = 1 | 2 | 4
	area.collision_mask = 1 | 2 | 4
	var col = CollisionShape3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = 6.0
	col.shape = sphere
	area.add_child(col)
	bus.add_child(area)

	var prompt_lbl = Label3D.new()
	prompt_lbl.name = "BRTPromptLabel3D"
	prompt_lbl.text = "🚌 [E] Lên Xe Bus Điện BRT (%s)" % spoke_name
	prompt_lbl.font_size = 26
	prompt_lbl.modulate = Color(1.0, 0.95, 0.4)
	prompt_lbl.outline_size = 8
	prompt_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	prompt_lbl.no_depth_test = true
	prompt_lbl.position = Vector3(0.0, 2.2, 4.8)
	prompt_lbl.visible = false
	bus.add_child(prompt_lbl)

	area.body_entered.connect(func(body: Node3D):
		if body.is_in_group("player"):
			prompt_lbl.visible = true
	)
	area.body_exited.connect(func(body: Node3D):
		if body.is_in_group("player"):
			prompt_lbl.visible = false
	)

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
