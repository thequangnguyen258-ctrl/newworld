@tool
class_name ColossalMountainGenerator
extends Node3D

# Bộ Khởi Tạo Địa Hình Núi Bàn Cao Nguyên Hùng Vĩ 3D (Colossal Mountain Range)
# Tạo hình khối núi tự nhiên: Sống núi gân guốc, Vách đá giật cấp, Đỉnh nhấp nhô, Tháp đá vệ tinh & Dãy núi chân trời

const PLATEAU_ALTITUDE: float = 280.0   # Độ cao đỉnh núi (+280m trên mực nước biển)
const BASE_RADIUS: float = 380.0        # Bán kính trung bình đỉnh núi
const CLIFF_SEGMENTS: int = 64          # Số phân đoạn chi tiết vòng quanh núi

@export var generate_on_ready: bool = true

var noise: FastNoiseLite
var mountain_mesh_instance: MeshInstance3D

func _ready() -> void:
	_init_noise()
	if generate_on_ready and get_child_count() == 0:
		build_mountain_landscape()

func _init_noise() -> void:
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.seed = 1337
	noise.frequency = 0.004
	noise.fractal_octaves = 4
	noise.fractal_gain = 0.55
	noise.fractal_lacunarity = 2.0

func build_mountain_landscape() -> void:
	print("[ColossalMountain] 🏔️ Đang kiến tạo Dãy Núi Tự Nhiên (Vách giật cấp, Sống núi, Tháp đá & Chân trời)...")
	
	for child in get_children():
		child.queue_free()
	
	# 1. Khối Núi Bàn Trung Tâm (Đỉnh vát tự nhiên + Vách đá giật cấp 3 tầng)
	_build_main_plateau_mountain()
	
	# 2. Các Tháp Đá & Ngọn Núi Vệ Tinh (Karst Spires & Satellite Peaks)
	_build_satellite_peaks()
	
	# 3. Dãy Núi Chân Trời Trùng Điệp (Horizon Mountain Ranges)
	_build_horizon_mountain_ranges()
	
	# 4. Biển Mây Anime Lơ Lửng (+150m)
	_build_sea_of_clouds()
	
	# 5. Đại Dương Xanh Biếc (Sea Level Y=0m)
	_build_ocean()
	
	# 6. Thác Nước Vách Núi (Waterfall)
	_build_cliff_waterfall()
	
	# 7. Mỏm Đá Ngắm Cảnh Đỉnh Núi
	_build_scenic_lookout()
	
	print("[ColossalMountain] 🌄 Hoàn thành kiến tạo Dãy Núi Tự Nhiên cực kỳ hùng vĩ!")

func _build_main_plateau_mountain() -> void:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Cấu trúc 4 tầng giật cấp tự nhiên:
	# Tầng 0: Tâm đỉnh núi (0m đến 200m)
	# Tầng 1: Mép gờ đỉnh vát (R ~ 380m, Y ~ 280m)
	# Tầng 2: Bậc thềm vách đá lơ lửng (R ~ 480m, Y ~ 170m)
	# Tầng 3: Chân vách núi đá lở (R ~ 680m, Y ~ 45m)
	# Tầng 4: Rìa đồng bằng 4 huyện (R ~ 2200m, Y ~ 3m - 15m)
	
	var rings: Array[Array] = [[], [], [], [], []]
	
	for i in range(CLIFF_SEGMENTS):
		var angle = (float(i) / float(CLIFF_SEGMENTS)) * TAU
		var dir = Vector2(cos(angle), sin(angle))
		
		# Noise uốn lượn đường viền mép núi
		var n_rim = noise.get_noise_2d(dir.x * 250.0, dir.y * 250.0) * 85.0
		var n_height = noise.get_noise_2d(dir.x * 120.0 + 50.0, dir.y * 120.0 + 50.0) * 16.0
		
		# Tầng 0: Vòng trong đỉnh núi (R ~ 180m)
		var r0 = 180.0 + n_rim * 0.3
		var y0 = PLATEAU_ALTITUDE + n_height * 0.4
		# Giữ phẳng trục đại lộ X ~ 0 để nhà cửa và đường ổn định
		if abs(dir.x * r0) < 30.0:
			y0 = PLATEAU_ALTITUDE
		rings[0].append(Vector3(dir.x * r0, y0, dir.y * r0))
		
		# Tầng 1: Mép vực đỉnh vát (R ~ 380m)
		var r1 = BASE_RADIUS + n_rim
		var y1 = PLATEAU_ALTITUDE + n_height * 0.6
		if abs(dir.x * r1) < 25.0 and dir.y > 0.0:
			y1 = PLATEAU_ALTITUDE # Mép phía Nam phẳng để đặt đài quan sát
		rings[1].append(Vector3(dir.x * r1, y1, dir.y * r1))
		
		# Tầng 2: Thềm vách đá lơ lửng (R ~ 490m, Y ~ 170m)
		var r2 = 490.0 + n_rim * 1.2
		var y2 = 170.0 + n_height * 1.2
		rings[2].append(Vector3(dir.x * r2, y2, dir.y * r2))
		
		# Tầng 3: Chân vách đá (R ~ 720m, Y ~ 45m)
		var r3 = 720.0 + n_rim * 1.5
		var y3 = 45.0 + n_height * 0.8
		rings[3].append(Vector3(dir.x * r3, y3, dir.y * r3))
		
		# Tầng 4: Rìa ngoại vi 4 huyện (R ~ 2400m, Y ~ 2m - 18m)
		var r4 = 2400.0 + n_rim * 2.5
		var y4 = 2.0 if dir.y > 0.0 else (12.0 + n_height * 0.5)
		rings[4].append(Vector3(dir.x * r4, y4, dir.y * r4))
		
	# Vẽ Mặt Đỉnh Cao Nguyên (Tâm nối ra Tầng 0)
	var center_pt = Vector3(0, PLATEAU_ALTITUDE, 0)
	for i in range(CLIFF_SEGMENTS):
		var next_i = (i + 1) % CLIFF_SEGMENTS
		st.add_vertex(center_pt)
		st.add_vertex(rings[0][next_i])
		st.add_vertex(rings[0][i])
		
	# Nối các tầng đồng tâm (Rings 0->1, 1->2, 2->3, 3->4)
	for ring_idx in range(4):
		var cur_ring = rings[ring_idx]
		var next_ring = rings[ring_idx + 1]
		for i in range(CLIFF_SEGMENTS):
			var next_i = (i + 1) % CLIFF_SEGMENTS
			# Quad = 2 Triangles
			st.add_vertex(cur_ring[i])
			st.add_vertex(cur_ring[next_i])
			st.add_vertex(next_ring[i])
			
			st.add_vertex(cur_ring[next_i])
			st.add_vertex(next_ring[next_i])
			st.add_vertex(next_ring[i])
			
	st.generate_normals()
	
	var mountain_mesh = st.commit()
	var mat = ShaderMaterial.new()
	mat.shader = load("res://assets/shaders/anime_mountain_rock.gdshader")
	mountain_mesh.surface_set_material(0, mat)
	
	var body = StaticBody3D.new()
	body.name = "MainMountainBody"
	
	mountain_mesh_instance = MeshInstance3D.new()
	mountain_mesh_instance.name = "MountainMesh"
	mountain_mesh_instance.mesh = mountain_mesh
	body.add_child(mountain_mesh_instance)
	
	var col = CollisionShape3D.new()
	col.name = "MountainCollision"
	col.shape = mountain_mesh.create_trimesh_shape()
	body.add_child(col)
	
	add_child(body)

func _build_satellite_peaks() -> void:
	# Các ngọn tháp đá tự nhiên (Karst Spires & Needle Peaks) nhô lên quanh sườn núi
	var peak_coords = [
		{"pos": Vector2(-550, -450), "height": 260.0, "radius": 110.0, "name": "Đỉnh Tháp Đá Tây Bắc"},
		{"pos": Vector2(580, -420), "height": 240.0, "radius": 95.0, "name": "Đỉnh Ngũ Chỉ Sơn Đông Bắc"},
		{"pos": Vector2(620, 380), "height": 220.0, "radius": 120.0, "name": "Đỉnh Lam Ngọc Đông Nam"},
		{"pos": Vector2(-650, 360), "height": 210.0, "radius": 115.0, "name": "Đỉnh Hải Vân Tây Nam"},
		{"pos": Vector2(750, 0), "height": 195.0, "radius": 85.0, "name": "Cột Đá Vực Thần Đông"},
		{"pos": Vector2(-780, 0), "height": 190.0, "radius": 90.0, "name": "Cột Đá Gió Ngàn Tây"}
	]
	
	var rock_mat = ShaderMaterial.new()
	rock_mat.shader = load("res://assets/shaders/anime_mountain_rock.gdshader")
	
	for peak in peak_coords:
		var spire_mesh = CylinderMesh.new()
		spire_mesh.top_radius = peak["radius"] * 0.15 # Đỉnh nhọn hoắt
		spire_mesh.bottom_radius = peak["radius"]
		spire_mesh.height = peak["height"]
		spire_mesh.radial_segments = 16
		spire_mesh.material = rock_mat
		
		var spire_inst = MeshInstance3D.new()
		spire_inst.name = peak["name"]
		spire_inst.mesh = spire_mesh
		spire_inst.transform.origin = Vector3(peak["pos"].x, peak["height"] * 0.5, peak["pos"].y)
		
		var col = CollisionShape3D.new()
		var cyl_shape = CylinderShape3D.new()
		cyl_shape.height = peak["height"]
		cyl_shape.radius = peak["radius"]
		col.shape = cyl_shape
		col.transform.origin = spire_inst.transform.origin
		
		var spire_body = StaticBody3D.new()
		spire_body.add_child(spire_inst)
		spire_body.add_child(col)
		add_child(spire_body)

func _build_horizon_mountain_ranges() -> void:
	# Dãy núi nhấp nhô ở đường chân trời (R ~ 2000m - 2800m) tạo chiều sâu không gian
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var segments = 36
	var horizon_inner: Array[Vector3] = []
	var horizon_outer: Array[Vector3] = []
	
	for i in range(segments):
		var angle = (float(i) / float(segments)) * TAU
		var dir = Vector2(cos(angle), sin(angle))
		
		var n = noise.get_noise_2d(dir.x * 80.0 + 100.0, dir.y * 80.0 + 100.0)
		var peak_h = 90.0 + (n * 0.5 + 0.5) * 110.0
		
		horizon_inner.append(Vector3(dir.x * 2100.0, peak_h, dir.y * 2100.0))
		horizon_outer.append(Vector3(dir.x * 2900.0, 5.0, dir.y * 2900.0))
		
	for i in range(segments):
		var next_i = (i + 1) % segments
		# Hai tam giác nối thành sườn núi chân trời
		st.add_vertex(horizon_inner[i])
		st.add_vertex(horizon_inner[next_i])
		st.add_vertex(horizon_outer[i])
		
		st.add_vertex(horizon_inner[next_i])
		st.add_vertex(horizon_outer[next_i])
		st.add_vertex(horizon_outer[i])
		
	st.generate_normals()
	var horizon_mesh = st.commit()
	
	var mat = ShaderMaterial.new()
	mat.shader = load("res://assets/shaders/anime_mountain_rock.gdshader")
	horizon_mesh.surface_set_material(0, mat)
	
	var horizon_inst = MeshInstance3D.new()
	horizon_inst.name = "HorizonMountainRange"
	horizon_inst.mesh = horizon_mesh
	add_child(horizon_inst)

func _build_sea_of_clouds() -> void:
	# Tầng mây bồng bềnh ở độ cao +145m
	var cloud_mesh = PlaneMesh.new()
	cloud_mesh.size = Vector2(5000.0, 5000.0)
	cloud_mesh.subdivide_width = 32
	cloud_mesh.subdivide_depth = 32
	
	var cloud_mat = ShaderMaterial.new()
	cloud_mat.shader = load("res://assets/shaders/anime_cloud_sea.gdshader")
	cloud_mesh.material = cloud_mat
	
	var cloud_inst = MeshInstance3D.new()
	cloud_inst.name = "SeaOfClouds"
	cloud_inst.mesh = cloud_mesh
	cloud_inst.transform.origin = Vector3(0, 145.0, 0)
	add_child(cloud_inst)

func _build_ocean() -> void:
	var ocean_mesh = PlaneMesh.new()
	ocean_mesh.size = Vector2(6000.0, 6000.0)
	ocean_mesh.subdivide_width = 32
	ocean_mesh.subdivide_depth = 32
	
	var water_mat = ShaderMaterial.new()
	water_mat.shader = load("res://assets/shaders/anime_water.gdshader")
	ocean_mesh.material = water_mat
	
	var ocean_inst = MeshInstance3D.new()
	ocean_inst.name = "SouthernOcean"
	ocean_inst.mesh = ocean_mesh
	ocean_inst.transform.origin = Vector3(0, 0.0, 0)
	add_child(ocean_inst)

func _build_cliff_waterfall() -> void:
	# Dòng thác nước trắng muốt đổ từ khe nứt vách núi phía Tây Nam xuống biển mây
	var waterfall_mesh = BoxMesh.new()
	waterfall_mesh.size = Vector3(8.0, 140.0, 1.2)
	
	var mat_wf = StandardMaterial3D.new()
	mat_wf.albedo_color = Color(0.85, 0.95, 1.0, 0.9)
	mat_wf.roughness = 0.1
	mat_wf.emission_enabled = true
	mat_wf.emission = Color(0.7, 0.88, 1.0)
	mat_wf.emission_energy_multiplier = 0.8
	waterfall_mesh.material = mat_wf
	
	var wf_inst = MeshInstance3D.new()
	wf_inst.name = "MountainWaterfall"
	wf_inst.mesh = waterfall_mesh
	wf_inst.transform.origin = Vector3(-320.0, 210.0, 220.0)
	wf_inst.rotation_degrees = Vector3(12, -45, 0)
	add_child(wf_inst)

func _build_scenic_lookout() -> void:
	var lookout_root = Node3D.new()
	lookout_root.name = "ScenicLookoutPoint"
	lookout_root.transform.origin = Vector3(0, PLATEAU_ALTITUDE + 0.1, 350.0)
	
	# Mỏm đá ngắm cảnh nhô ra vực
	var platform = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(32, 2.5, 24)
	platform.mesh = box
	platform.transform.origin = Vector3(0, 0, 8)
	
	var mat_stone = StandardMaterial3D.new()
	mat_stone.albedo_color = Color(0.92, 0.9, 0.85)
	mat_stone.roughness = 0.5
	platform.set_surface_override_material(0, mat_stone)
	
	var col_box = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(32, 2.5, 24)
	col_box.shape = box_shape
	col_box.transform.origin = Vector3(0, 0, 8)
	
	var platform_body = StaticBody3D.new()
	platform_body.add_child(platform)
	platform_body.add_child(col_box)
	lookout_root.add_child(platform_body)
	
	# Lan can ngắm cảnh mép vực
	var railing = MeshInstance3D.new()
	var rail_mesh = BoxMesh.new()
	rail_mesh.size = Vector3(30, 1.3, 0.4)
	railing.mesh = rail_mesh
	railing.transform.origin = Vector3(0, 1.8, 19.5)
	var mat_rail = StandardMaterial3D.new()
	mat_rail.albedo_color = Color(0.96, 0.96, 0.98)
	mat_rail.metallic = 0.4
	mat_rail.roughness = 0.2
	railing.set_surface_override_material(0, mat_rail)
	platform_body.add_child(railing)
	
	add_child(lookout_root)
