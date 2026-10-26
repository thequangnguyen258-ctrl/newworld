@tool
class_name ModularNatureChunk
extends StaticBody3D

# ==============================================================================
# MODULAR NATURE CHUNK (64m x 64m) - TÂN THẾ GIỚI
# Khối Địa Hình Tự Nhiên Liền Mạch (Continuous World Elevation Function):
# 1. Cao nguyên trung tâm bằng phẳng cho Mega Office và Quảng Trường Hòa Bình
# 2. Đồng cỏ thảo nguyên hoa dại lộng gió (+600m)
# 3. Suối trong uốn lượn thoai thoải lội nước dễ dàng
# 4. Mép vực giật cấp & Thác nước đại ngàn nhìn xuống biển mây (+500m)
# Triệt tiêu 100% đường nối, không bao giờ có vách chắn dốc đứng dị hợm!
# ==============================================================================

enum ChunkType {
	FLAT_GRASS_PLATEAU,    # Thảo nguyên bằng phẳng có gò cỏ nhẹ
	RIVER_STREAM,          # Đoạn suối tự nhiên uốn lượn có lòng suối & nước trong
	CLIFF_EDGE_STEPPED,    # Mép vực vách đá giật cấp nhìn xuống biển mây
	WATERFALL_CASCADE,     # Thác nước tự nhiên đổ xuống vực thẳm
	SCENIC_LOOKOUT_CLIFF,  # Mỏm đá ngắm cảnh biển mây
	NORTH_BACKWALL_CLIFF   # Kiểu chunk tương thích cũ, dùng địa hình cao nguyên thông thường
}

const CHUNK_SIZE: float = 64.0
const HALF_SIZE: float = 32.0
const PLATEAU_ALTITUDE: float = 600.0

@export var chunk_type: ChunkType = ChunkType.FLAT_GRASS_PLATEAU
@export var grid_coord: Vector2i = Vector2i.ZERO

var rock_material: ShaderMaterial
var water_material: ShaderMaterial
var mesh_instance: MeshInstance3D
var collision_shape: CollisionShape3D

func _init(p_type: ChunkType = ChunkType.FLAT_GRASS_PLATEAU, p_coord: Vector2i = Vector2i.ZERO) -> void:
	chunk_type = p_type
	grid_coord = p_coord

func _ready() -> void:
	if mesh_instance == null:
		build_chunk()

func _setup_materials() -> void:
	if rock_material != null and water_material != null:
		return
		
	# Shader địa hình núi đá Toon
	var rock_shader = load("res://assets/shaders/anime_mountain_rock.gdshader")
	rock_material = ShaderMaterial.new()
	rock_material.shader = rock_shader
	rock_material.set_shader_parameter("grass_color", Color(0.42, 0.76, 0.36, 1.0))
	rock_material.set_shader_parameter("rock_color_high", Color(0.64, 0.58, 0.52, 1.0))
	rock_material.set_shader_parameter("rock_color_low", Color(0.46, 0.42, 0.38, 1.0))
	rock_material.set_shader_parameter("trail_color", Color(0.72, 0.64, 0.50, 1.0))
	rock_material.set_shader_parameter("snow_color", Color(0.94, 0.96, 1.0, 1.0))
	rock_material.set_shader_parameter("shadow_tint", Color(0.45, 0.52, 0.68, 1.0))
	rock_material.set_shader_parameter("slope_threshold", 0.52)
	rock_material.set_shader_parameter("plateau_altitude", PLATEAU_ALTITUDE)

	# Shader mặt nước suối trong
	var water_shader = load("res://assets/shaders/anime_water.gdshader")
	water_material = ShaderMaterial.new()
	water_material.shader = water_shader
	water_material.set_shader_parameter("shallow_color", Color(0.28, 0.78, 0.85, 0.85))
	water_material.set_shader_parameter("deep_color", Color(0.12, 0.45, 0.68, 0.95))
	water_material.set_shader_parameter("foam_color", Color(1.0, 1.0, 1.0, 0.9))

# ------------------------------------------------------------------------------
# HÀM TÍNH ĐỘ CAO TOÀN THẾ GIỚI LIỀN MẠCH (CONTINUOUS WORLD ELEVATION - 500 KM²)
# ------------------------------------------------------------------------------
static func get_world_height(wx: float, wz: float) -> float:
	var base_h: float = PLATEAU_ALTITUDE # 600.0m
	var dist_from_center: float = sqrt(wx * wx + wz * wz)
	
	# 1. HỒ ĐỈNH CAO NGUYÊN (Summit Reservoir Lake: X=-2000, Z=-3000)
	var lake_dx = wx - (-2000.0)
	var lake_dz = wz - (-3000.0)
	var lake_dist = sqrt(lake_dx * lake_dx + lake_dz * lake_dz)
	if lake_dist < 900.0:
		var lake_t = 1.0 - (lake_dist / 900.0)
		var lake_dip = lake_t * lake_t * (3.0 - 2.0 * lake_t) * 55.0 # Sâu 50m dưới mực nước 590m
		return base_h - 10.0 - lake_dip + sin(wx * 0.05) * 0.8

	# 2. HÀNH LANG CAO NGUYÊN & ĐỈNH VÁT TRUNG TÂM (+600m)
	# Khu vực trung tâm thủ phủ (R <= 2200m) và dải thảo nguyên Nam/Bắc (Z in [-1200, 12600m] với |X| <= 2400m)
	var in_central_hub = (wx * wx + wz * wz) <= (2200.0 * 2200.0)
	var in_south_meadow = (wz >= -1200.0 and wz <= 12600.0 and abs(wx) <= 2400.0)
	
	if in_central_hub or in_south_meadow:
		# Giữ toàn bộ cao ốc, quảng trường, tram và sân đáp trung tâm trên cùng một mặt phẳng.
		if absf(wx) <= 360.0 and absf(wz) <= 300.0:
			return base_h
		var plateau_roll = sin(wx * 0.003) * cos(wz * 0.003) * 5.0 + sin(wx * 0.012) * sin(wz * 0.012) * 2.0
		# Lòng suối tự nhiên uốn lượn xuyên qua đồng cỏ phía Nam (cách xa trung tâm)
		var river_center_x = sin(wz * 0.004) * 25.0 + sin(wz * 0.05) * 6.0
		var dist_stream = abs(wx - river_center_x)
		if dist_stream < 7.0 and wz > 80.0 and wz < 11800.0:
			var stream_depth = (1.0 - (dist_stream / 7.0)) * 1.5
			plateau_roll -= stream_depth
		return base_h + plateau_roll

	# 3. HẠ ĐỘ CAO THOAI THOẢI XUỐNG 4 HUYỆN NGOẠI VI (500 KM² CONTINUOUS SLOPES)
	# Mục tiêu cao độ từng vùng huyện ngoại vi:
	# - Đông (X = 10000, Z = 0): +35m (Vựa Nông Trại lúa mạch)
	# - Tây (X = -10000, Z = 0): +45m (Thung Lũng Kỹ Nghệ quạt gió)
	# - Bắc (X = 0, Z = -10000): +55m (Đại Ngàn suối khoáng Onsen)
	# - Nam (X = 0, Z = 20000): +15m (Cảng Hòa Bình duyên hải)
	var target_lowland_h: float = 40.0
	var dist_east = sqrt((wx - 10000.0) * (wx - 10000.0) + wz * wz)
	var dist_west = sqrt((wx + 10000.0) * (wx + 10000.0) + wz * wz)
	var dist_north = sqrt(wx * wx + (wz + 10000.0) * (wz + 10000.0))
	var dist_south = sqrt(wx * wx + (wz - 20000.0) * (wz - 20000.0))
	
	if dist_east < 4500.0:
		target_lowland_h = 35.0
	elif dist_west < 4500.0:
		target_lowland_h = 45.0
	elif dist_north < 4500.0:
		target_lowland_h = 55.0
	elif dist_south < 6000.0 or wz > 17000.0:
		target_lowland_h = 15.0
	else:
		target_lowland_h = 40.0

	# Tính khoảng cách từ mép cao nguyên gần nhất để chuyển tiếp dốc mượt mà (dốc <= 10 độ)
	var dist_to_plateau: float = 0.0
	if wz >= 0.0 and wz <= 12600.0:
		dist_to_plateau = maxf(0.0, abs(wx) - 2400.0)
	elif wz > 12600.0:
		var dz = wz - 12600.0
		var dx = maxf(0.0, abs(wx) - 2400.0)
		dist_to_plateau = sqrt(dx * dx + dz * dz)
	else:
		dist_to_plateau = maxf(0.0, sqrt(wx * wx + wz * wz) - 2200.0)

	var slope_ratio = clampf(dist_to_plateau / 4800.0, 0.0, 1.0)
	var smooth_blend = slope_ratio * slope_ratio * (3.0 - 2.0 * slope_ratio)
	
	var h = lerpf(600.0, target_lowland_h, smooth_blend)
	var rolling = sin(wx * 0.005) * cos(wz * 0.005) * 3.5 + sin(wx * 0.02) * sin(wz * 0.02) * 1.5
	return h + rolling

# ------------------------------------------------------------------------------
# KHỞI TẠO CHUNK
# ------------------------------------------------------------------------------
func build_chunk() -> void:
	if mesh_instance != null:
		return
	_setup_materials()
	
	match chunk_type:
		ChunkType.RIVER_STREAM:
			_build_terrain_mesh(20)
			_add_water_surface(Vector3(0, PLATEAU_ALTITUDE - 0.7, 0), Vector2(18.0, CHUNK_SIZE))
		ChunkType.WATERFALL_CASCADE:
			_build_terrain_mesh(20)
			_build_waterfall_sheet()
		ChunkType.SCENIC_LOOKOUT_CLIFF:
			_build_terrain_mesh(20)
			_build_lookout_platform()
		ChunkType.NORTH_BACKWALL_CLIFF:
			_build_terrain_mesh(20)
		_:
			_build_terrain_mesh(20)

func _build_terrain_mesh(res: int) -> void:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for z in range(res):
		for x in range(res):
			var x0 = -HALF_SIZE + (float(x) / res) * CHUNK_SIZE
			var x1 = -HALF_SIZE + (float(x + 1) / res) * CHUNK_SIZE
			var z0 = -HALF_SIZE + (float(z) / res) * CHUNK_SIZE
			var z1 = -HALF_SIZE + (float(z + 1) / res) * CHUNK_SIZE
			
			var wx0 = float(grid_coord.x) * CHUNK_SIZE + x0
			var wx1 = float(grid_coord.x) * CHUNK_SIZE + x1
			var wz0 = float(grid_coord.y) * CHUNK_SIZE + z0
			var wz1 = float(grid_coord.y) * CHUNK_SIZE + z1
			
			var y00 = get_world_height(wx0, wz0)
			var y10 = get_world_height(wx1, wz0)
			var y01 = get_world_height(wx0, wz1)
			var y11 = get_world_height(wx1, wz1)
			
			var v00 = Vector3(x0, y00, z0)
			var v10 = Vector3(x1, y10, z0)
			var v01 = Vector3(x0, y01, z1)
			var v11 = Vector3(x1, y11, z1)
			
			_add_quad(st, v00, v10, v01, v11)
			
	_finalize_mesh(st)

func _build_waterfall_sheet() -> void:
	var st_water = SurfaceTool.new()
	st_water.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var top_y = PLATEAU_ALTITUDE - 2.5
	var bot_y = PLATEAU_ALTITUDE - 165.0
	var z_top = 8.0
	var z_bot = 28.0
	var w = 8.0
	
	st_water.add_vertex(Vector3(-w, top_y, z_top))
	st_water.add_vertex(Vector3(w, top_y, z_top))
	st_water.add_vertex(Vector3(-w * 1.3, bot_y, z_bot))
	
	st_water.add_vertex(Vector3(w, top_y, z_top))
	st_water.add_vertex(Vector3(w * 1.3, bot_y, z_bot))
	st_water.add_vertex(Vector3(-w * 1.3, bot_y, z_bot))
	
	st_water.generate_normals()
	var w_mesh = st_water.commit()
	
	var w_inst = MeshInstance3D.new()
	w_inst.name = "WaterfallSheet"
	w_inst.mesh = w_mesh
	w_inst.material_override = water_material
	add_child(w_inst)

func _build_lookout_platform() -> void:
	var platform = MeshInstance3D.new()
	platform.name = "ScenicPlatform"
	var cyl = CylinderMesh.new()
	cyl.top_radius = 7.0
	cyl.bottom_radius = 8.0
	cyl.height = 3.0
	platform.mesh = cyl
	
	var plat_mat = StandardMaterial3D.new()
	plat_mat.albedo_color = Color(0.68, 0.64, 0.58)
	plat_mat.roughness = 0.85
	platform.material_override = plat_mat
	platform.position = Vector3(0, PLATEAU_ALTITUDE - 1.5, 12.0)
	add_child(platform)

func _add_water_surface(pos: Vector3, size: Vector2) -> void:
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = size
	plane_mesh.subdivide_width = 8
	plane_mesh.subdivide_depth = 8
	
	var water_inst = MeshInstance3D.new()
	water_inst.name = "StreamWaterMesh"
	water_inst.mesh = plane_mesh
	water_inst.material_override = water_material
	water_inst.position = pos
	add_child(water_inst)

func _add_quad(st: SurfaceTool, v00: Vector3, v10: Vector3, v01: Vector3, v11: Vector3) -> void:
	st.add_vertex(v00)
	st.add_vertex(v10)
	st.add_vertex(v01)
	
	st.add_vertex(v10)
	st.add_vertex(v11)
	st.add_vertex(v01)

func _finalize_mesh(st: SurfaceTool) -> void:
	st.generate_normals()
	var mesh = st.commit()
	
	mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "ChunkMesh"
	mesh_instance.mesh = mesh
	mesh_instance.material_override = rock_material
	add_child(mesh_instance)
	
	var shape = mesh.create_trimesh_shape()
	collision_shape = CollisionShape3D.new()
	collision_shape.name = "ChunkCol"
	collision_shape.shape = shape
	add_child(collision_shape)
