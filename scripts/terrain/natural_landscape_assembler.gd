@tool
class_name NaturalLandscapeAssembler
extends Node3D

# ==============================================================================
# NATURAL LANDSCAPE ASSEMBLER - ĐẠI CAO NGUYÊN NÚI BÀN 3D TÂN THẾ GIỚI
# Khởi tạo Toàn Diện Ngọn Núi Hùng Vĩ Cao +600m & Non Nước Tự Nhiên 100%:
# 1. Khối Thân & Chân Núi Đồ Sộ (Colossal Mountain Body): Rộng 2.3km, cao 600m
# 2. Đỉnh Cao Nguyên 5x5 Chunks (320m x 320m): Thảo nguyên cỏ xanh, suối ngọc, thác đổ
# 3. Tầng Biển Mây Anime (+500m): Dập dờn ôm trọn lưng chừng vách núi
# 4. Thảm Thực Vật Phong Cách Ghibli: Rừng thông nón 3 tầng, tán lá mây, đồng hoa dại
# 5. Dãy Núi Chân Trời Xa Xăm: Ôm trọn không gian, tạo chiều sâu kỳ vĩ
# ==============================================================================

const ModularChunkScript = preload("res://scripts/terrain/modular_nature_chunk.gd")
const FloraScatterScript = preload("res://scripts/terrain/nature_flora_scatter.gd")
const DistrictsBuilderScript = preload("res://scripts/terrain/districts_builder.gd")
const SpiderwebTransitBuilderScript = preload("res://scripts/terrain/spiderweb_transit_builder.gd")
const ModelHouseBuilderScript = preload("res://scripts/terrain/model_house_builder.gd")

@export var auto_assemble: bool = true

## Cao độ tầng Biển Mây Anime trên trời cao (mặc định +4000m theo chỉ đạo)
@export var cloud_sea_altitude: float = 4000.0:
	set(val):
		cloud_sea_altitude = val
		if sea_of_clouds != null:
			sea_of_clouds.position.y = cloud_sea_altitude

var chunks: Dictionary = {} # Vector2i -> ModularNatureChunk
var mountain_body: StaticBody3D
var macro_terrain_body: StaticBody3D
var sea_of_clouds: MeshInstance3D
var cliff_wisps: MeshInstance3D
var flora_scatter: Node3D
var horizon_mountains: MeshInstance3D
var chunk_streamer: WorldChunkStreamer

func _ready() -> void:
	if auto_assemble and get_child_count() == 0:
		assemble_landscape()

func assemble_landscape() -> void:
	print("[NaturalLandscape] 🏔️ Đang kiến tạo Đại Thế Giới Mở 500 km² & Non Nước Tự Nhiên...")
	
	for child in get_children():
		child.queue_free()
	chunks.clear()
	
	# 1. Kiến tạo Lưới Địa Hình Vĩ Mô 500 km² (DistantMacroTerrain 28km x 28km)
	_build_distant_macro_terrain()
	
	# 2. Lắp ghép Cụm Chunk Trung Tâm Chi Tiết 5x5 Chunks (320m x 320m tại +600m)
	var layout: Dictionary = {
		# Hàng Bắc Xa (Z = -2, -128m) - Thảo nguyên cao nguyên xanh mướt, tầm nhìn thoáng đãng
		Vector2i(-2, -2): ModularChunkScript.ChunkType.FLAT_GRASS_PLATEAU,
		Vector2i(-1, -2): ModularChunkScript.ChunkType.FLAT_GRASS_PLATEAU,
		Vector2i(0, -2):  ModularChunkScript.ChunkType.FLAT_GRASS_PLATEAU,
		Vector2i(1, -2):  ModularChunkScript.ChunkType.FLAT_GRASS_PLATEAU,
		Vector2i(2, -2):  ModularChunkScript.ChunkType.FLAT_GRASS_PLATEAU,
		
		# Hàng Bắc (Z = -1, -64m) - Thảo nguyên bằng phẳng cao +600m
		Vector2i(-2, -1): ModularChunkScript.ChunkType.FLAT_GRASS_PLATEAU,
		Vector2i(-1, -1): ModularChunkScript.ChunkType.FLAT_GRASS_PLATEAU,
		Vector2i(0, -1):  ModularChunkScript.ChunkType.FLAT_GRASS_PLATEAU,
		Vector2i(1, -1):  ModularChunkScript.ChunkType.FLAT_GRASS_PLATEAU,
		Vector2i(2, -1):  ModularChunkScript.ChunkType.FLAT_GRASS_PLATEAU,
		
		# Hàng Giữa Trung Tâm (Z = 0, 0m) - Đô thị lõi & Quảng trường Hòa Bình bằng phẳng vững chắc
		Vector2i(-2, 0):  ModularChunkScript.ChunkType.FLAT_GRASS_PLATEAU,
		Vector2i(-1, 0):  ModularChunkScript.ChunkType.FLAT_GRASS_PLATEAU,
		Vector2i(0, 0):   ModularChunkScript.ChunkType.FLAT_GRASS_PLATEAU,
		Vector2i(1, 0):   ModularChunkScript.ChunkType.FLAT_GRASS_PLATEAU,
		Vector2i(2, 0):   ModularChunkScript.ChunkType.FLAT_GRASS_PLATEAU,
		
		# Hàng Nam Trung Gian (Z = +1, +64m) - Thảo nguyên lộng gió & vành đai thủ phủ
		Vector2i(-2, 1):  ModularChunkScript.ChunkType.FLAT_GRASS_PLATEAU,
		Vector2i(-1, 1):  ModularChunkScript.ChunkType.FLAT_GRASS_PLATEAU,
		Vector2i(0, 1):   ModularChunkScript.ChunkType.FLAT_GRASS_PLATEAU,
		Vector2i(1, 1):   ModularChunkScript.ChunkType.FLAT_GRASS_PLATEAU,
		Vector2i(2, 1):   ModularChunkScript.ChunkType.FLAT_GRASS_PLATEAU,
		
		# Hàng Nam Mở Rộng (Z = +2, +128m) - Thảo nguyên bạt ngàn hướng về chân trời Nam
		Vector2i(-2, 2):  ModularChunkScript.ChunkType.FLAT_GRASS_PLATEAU,
		Vector2i(-1, 2):  ModularChunkScript.ChunkType.FLAT_GRASS_PLATEAU,
		Vector2i(0, 2):   ModularChunkScript.ChunkType.RIVER_STREAM,
		Vector2i(1, 2):   ModularChunkScript.ChunkType.FLAT_GRASS_PLATEAU,
		Vector2i(2, 2):   ModularChunkScript.ChunkType.FLAT_GRASS_PLATEAU
	}
	
	for coord in layout.keys():
		var chunk_type = layout[coord]
		_spawn_chunk(coord, chunk_type)
		
	# 3. Gieo mầm Thảm Thực Vật Anime (Rừng thông, tán lá tròn, đồng hoa, đá cuội)
	_build_flora()
	
	# 4. Kiến tạo Tầng Biển Mây Anime trên trời cao (+4000m bao trọn 500 km²)
	_build_cloud_sea()
	
	# 5. Đưa Cư Dân Cốt Lõi 4 Độ Tuổi & 8 Ngành Nghề Vào Thế Giới
	_spawn_resident_npcs()
	
	# 6. Kiến tạo 4 Huyện Ngoại Vi Đầy Đủ Công Trình & Điểm Nhấn (Đông, Tây, Bắc, Nam)
	_spawn_four_districts()
	
	# 7. Kiến tạo Hệ Thống Giao Thông Mạng Nhện (5 Vành Đai, 8 Nan Hoa & 12 Trạm Dừng Chân)
	_build_spiderweb_transit()
	
	# 8. Kiến tạo Khu Phố Nhà Mẫu & Lô Đất Dân Cư Điển Hình (Showcase Housing Avenue)
	_build_showcase_housing()
	
	# 9. Kích hoạt Động Cơ Sinh Chunk Động 500 km² (WorldChunkStreamer)
	_setup_chunk_streamer()
	
	print("[NaturalLandscape] 🏞️ Hoàn tất kiến tạo Toàn Thể Đại Thế Giới Mở 500 km² thành công!")

func _build_distant_macro_terrain() -> void:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var extent_x: float = 15000.0 # Rộng 30km (từ -15km đến +15km)
	var min_z: float = -15000.0   # Dài 40km (từ -15km đến +25km bao trọn Cảng Nam +20km)
	var max_z: float = 25000.0
	var quads_x: int = 90
	var quads_z: int = 120
	var step_x: float = (extent_x * 2.0) / float(quads_x) # ~333m mỗi bước
	var step_z: float = (max_z - min_z) / float(quads_z)  # ~333m mỗi bước
	
	# Tính toán ma trận đỉnh toàn cầu
	var grid_pts: Array[Array] = []
	for iz in range(quads_z + 1):
		var row: Array[Vector3] = []
		var wz = min_z + float(iz) * step_z
		for ix in range(quads_x + 1):
			var wx = -extent_x + float(ix) * step_x
			var wy = ModularChunkScript.get_world_height(wx, wz)
			row.append(Vector3(wx, wy, wz))
		grid_pts.append(row)
		
	# Sinh tam giác bề mặt
	for iz in range(quads_z):
		var next_iz = iz + 1
		for ix in range(quads_x):
			var next_ix = ix + 1
			
			var v00 = grid_pts[iz][ix]
			var v10 = grid_pts[iz][next_ix]
			var v01 = grid_pts[next_iz][ix]
			var v11 = grid_pts[next_iz][next_ix]
			
			st.add_vertex(v00)
			st.add_vertex(v10)
			st.add_vertex(v01)
			
			st.add_vertex(v10)
			st.add_vertex(v11)
			st.add_vertex(v01)
			
	st.generate_normals()
	var mesh = st.commit()
	
	var rock_shader = load("res://assets/shaders/anime_mountain_rock.gdshader")
	var mat = ShaderMaterial.new()
	mat.shader = rock_shader
	mat.set_shader_parameter("grass_color", Color(0.42, 0.76, 0.36, 1.0))
	mat.set_shader_parameter("rock_color_high", Color(0.64, 0.58, 0.52, 1.0))
	mat.set_shader_parameter("rock_color_low", Color(0.46, 0.42, 0.38, 1.0))
	mat.set_shader_parameter("shadow_tint", Color(0.45, 0.52, 0.68, 1.0))
	mat.set_shader_parameter("slope_threshold", 0.55)
	mat.set_shader_parameter("plateau_altitude", 600.0)
	
	macro_terrain_body = StaticBody3D.new()
	macro_terrain_body.name = "DistantMacroTerrain"
	macro_terrain_body.add_to_group("macro_terrain")
	mountain_body = macro_terrain_body
	
	var mesh_inst = MeshInstance3D.new()
	mesh_inst.name = "MacroTerrainMesh"
	mesh_inst.mesh = mesh
	mesh_inst.material_override = mat
	macro_terrain_body.add_child(mesh_inst)
	
	var col = CollisionShape3D.new()
	col.name = "MacroTerrainCol"
	col.shape = mesh.create_trimesh_shape()
	macro_terrain_body.add_child(col)
	
	add_child(macro_terrain_body)
	print("[NaturalLandscape] 🌍 Khởi tạo thành công Lưới Địa Hình Vĩ Mô 500 km² (DistantMacroTerrain 28km x 28km)!")

func _spawn_chunk(coord: Vector2i, type: ModularChunkScript.ChunkType) -> void:
	var chunk = ModularChunkScript.new(type, coord)
	chunk.name = "Chunk_%d_%d" % [coord.x, coord.y]
	chunk.position = Vector3(coord.x * ModularChunkScript.CHUNK_SIZE, 0, coord.y * ModularChunkScript.CHUNK_SIZE)
	chunk.build_chunk()
	add_child(chunk)
	chunks[coord] = chunk

func _build_flora() -> void:
	flora_scatter = FloraScatterScript.new()
	flora_scatter.name = "NatureFlora"
	add_child(flora_scatter)
	flora_scatter.generate_flora()

func _build_cloud_sea() -> void:
	var cloud_shader = load("res://assets/shaders/anime_cloud_sea.gdshader")
	var cloud_mat = ShaderMaterial.new()
	cloud_mat.shader = cloud_shader
	cloud_mat.set_shader_parameter("cloud_color", Color(1.0, 0.98, 0.95, 0.88))
	cloud_mat.set_shader_parameter("shadow_cloud_color", Color(0.72, 0.82, 0.92, 0.75))
	cloud_mat.set_shader_parameter("speed", 0.006)
	cloud_mat.set_shader_parameter("wave_scale", 0.002)

	# Biển mây trên trời cao 4000m bao trọn 500 km² (30km x 30km)
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(30000.0, 30000.0)
	plane_mesh.subdivide_width = 48
	plane_mesh.subdivide_depth = 48

	sea_of_clouds = MeshInstance3D.new()
	sea_of_clouds.name = "SeaOfClouds"
	sea_of_clouds.mesh = plane_mesh
	sea_of_clouds.material_override = cloud_mat
	sea_of_clouds.position = Vector3(0, cloud_sea_altitude, 0)
	add_child(sea_of_clouds)
	print("[NaturalLandscape] ☁️ Khởi tạo thành công Biển Mây Anime trên trời cao tại cao độ +%.0fm (30km x 30km)!" % cloud_sea_altitude)

func _spawn_resident_npcs() -> void:
	# Tạo hồ sơ trước để mọi nhân vật 3D đều gắn với một công dân trong roster.
	var citizen_manager_script = load("res://scripts/simulation/citizen_manager.gd")
	if citizen_manager_script == null:
		push_error("[NaturalLandscape] Không thể tải CitizenManager để tạo dân cư.")
		return
	var citizen_manager = citizen_manager_script.new()
	citizen_manager.name = "CitizenManager"
	add_child(citizen_manager)

	var npc_script = load("res://scripts/characters/npc_character.gd")
	if npc_script == null:
		push_error("[NaturalLandscape] Không tìm thấy npc_character.gd!")
		return
		
	var resident_list: Array[Dictionary] = [
		{
			"id": "farmer_hai",
			"name": "Bác Hai",
			"age": 46,
			"age_group": ModularHumanoidBuilder.AgeGroup.ADULT,
			"gender": "Nam",
			"profession": ModularHumanoidBuilder.ProfessionType.FARMER,
			"job_title": "Nông Dân Sinh Thái",
			"cert_code": "CERT_AGRI_CROPS",
			"skill_level": 8,
			"cccd": "TTG-2026-0082",
			"harmony": 98.0,
			"vitality": 95.0,
			"dialogue": "Chào Thị trưởng! Đất đai quanh bờ suối màu mỡ lắm, vụ mùa lúa mạch sinh thái năm nay chắc chắn bội thu!",
			"pos": Vector3(45.0, 0.0, 42.0)
		},
		{
			"id": "carpenter_tung",
			"name": "Anh Tùng",
			"age": 27,
			"age_group": ModularHumanoidBuilder.AgeGroup.ADULT,
			"gender": "Nam",
			"profession": ModularHumanoidBuilder.ProfessionType.CARPENTER,
			"job_title": "Thợ Mộc Mỹ Nghệ",
			"cert_code": "CERT_CARPENTRY",
			"skill_level": 7,
			"cccd": "TTG-2026-0104",
			"harmony": 92.0,
			"vitality": 96.0,
			"dialogue": "Gỗ thông trên sườn đồi Tân Thế Giới thớ rất mịn. Tôi vừa hoàn thiện dãy ghế nghỉ chân ven hồ cho người dân thưởng cảnh.",
			"pos": Vector3(-55.0, 0.0, 35.0)
		},
		{
			"id": "engineer_khoa",
			"name": "Anh Khoa",
			"age": 24,
			"age_group": ModularHumanoidBuilder.AgeGroup.ADULT,
			"gender": "Nam",
			"profession": ModularHumanoidBuilder.ProfessionType.ENGINEER,
			"job_title": "Kỹ Sư Cầu Đường",
			"cert_code": "CERT_CIVIC_ADMIN",
			"skill_level": 8,
			"cccd": "TTG-2026-0033",
			"harmony": 95.0,
			"vitality": 94.0,
			"dialogue": "Thưa Thị trưởng, lối đi bộ phía sau Mega Office đã được mở rộng và giữ bằng phẳng, an toàn cho mọi cư dân!",
			"pos": Vector3(8.0, 0.0, 75.0)
		},
		{
			"id": "architect_lan",
			"name": "Cô Lan",
			"age": 25,
			"age_group": ModularHumanoidBuilder.AgeGroup.ADULT,
			"gender": "Nữ",
			"profession": ModularHumanoidBuilder.ProfessionType.ENGINEER,
			"job_title": "Kiến Trúc Sư Sinh Thái",
			"cert_code": "CERT_CIVIC_ARCH",
			"skill_level": 8,
			"cccd": "TTG-2026-0188",
			"harmony": 98.0,
			"vitality": 95.0,
			"dialogue": "Không gian quảng trường và các khu vườn treo Sky Gardens được quy hoạch thông thoáng, đón trọn ánh nắng ban mai Ghibli!",
			"pos": Vector3(52.0, 0.0, -38.0)
		},
		{
			"id": "artisan_sau",
			"name": "Bác Sáu",
			"age": 46,
			"age_group": ModularHumanoidBuilder.AgeGroup.ADULT,
			"gender": "Nam",
			"profession": ModularHumanoidBuilder.ProfessionType.CARPENTER,
			"job_title": "Nghệ Nhân Gốm Mỹ Nghệ",
			"cert_code": "CERT_CERAMIC_CRAFT",
			"skill_level": 9,
			"cccd": "TTG-2026-0062",
			"harmony": 96.0,
			"vitality": 92.0,
			"dialogue": "Đất sét cao nguyên nung men gốm rêu phong rất bền và đẹp. Các bình trà và chậu hoa quảng trường đều do xưởng chúng tôi chế tác.",
			"pos": Vector3(-52.0, 0.0, -35.0)
		},
		{
			"id": "teacher_minh",
			"name": "Thầy Minh",
			"age": 33,
			"age_group": ModularHumanoidBuilder.AgeGroup.ADULT,
			"gender": "Nam",
			"profession": ModularHumanoidBuilder.ProfessionType.TEACHER,
			"job_title": "Giáo Viên Học Viện",
			"cert_code": "CERT_EDU_PRIMARY",
			"skill_level": 8,
			"cccd": "TTG-2026-0055",
			"harmony": 96.0,
			"vitality": 93.0,
			"dialogue": "Các em học sinh hôm nay đang thực hành vẽ ký họa biển mây và nghiên cứu địa chất núi đá. Mọi em đều rất chăm ngoan!",
			"pos": Vector3(40.0, 0.0, -55.0)
		},
		{
			"id": "student_linh",
			"name": "Em Linh",
			"age": 17,
			"age_group": ModularHumanoidBuilder.AgeGroup.YOUTH,
			"gender": "Nữ",
			"profession": ModularHumanoidBuilder.ProfessionType.STUDENT,
			"job_title": "Học Viên Mỹ Thuật",
			"cert_code": "CERT_MUSIC_PERFORMANCE",
			"skill_level": 6,
			"cccd": "TTG-2026-0210",
			"harmony": 94.0,
			"vitality": 98.0,
			"dialogue": "Ánh hoàng hôn phản chiếu trên vách đá ngắm từ đây đẹp như trong tranh Ghibli vậy Thị trưởng ơi!",
			"pos": Vector3(-42.0, 0.0, -52.0)
		},
		{
			"id": "kid_bo",
			"name": "Bé Bo",
			"age": 9,
			"age_group": ModularHumanoidBuilder.AgeGroup.CHILD,
			"gender": "Nam",
			"profession": ModularHumanoidBuilder.ProfessionType.CITIZEN_KID,
			"job_title": "Cư Dân Nhí",
			"cert_code": "CERT_PRIMARY_EDU",
			"skill_level": 3,
			"cccd": "TTG-2026-0345",
			"harmony": 100.0,
			"vitality": 100.0,
			"dialogue": "Em bắt được một chú bướm xanh to đùng ở bãi hoa cúc đằng kia kìa! Em yêu thị trấn Tân Thế Giới nhất trên đời!",
			"pos": Vector3(-46.0, 0.0, 48.0)
		}
	]
	
	var npc_container = Node3D.new()
	npc_container.name = "ResidentNPCs"
	add_child(npc_container)
	
	for index in range(resident_list.size()):
		var data: Dictionary = resident_list[index]
		var citizen_id := str(1000 + index)
		var citizen: CitizenData = citizen_manager.get_citizen(citizen_id)
		if citizen == null:
			push_error("[NaturalLandscape] Thiếu hồ sơ cư dân %s cho NPC mẫu." % citizen_id)
			continue
		var npc = npc_script.new()
		npc.configure_from_citizen(citizen, data["name"])
		npc.npc_id = data["id"]
		npc.citizen_name = data["name"]
		npc.age = data["age"]
		npc.age_group = data["age_group"]
		npc.gender = data["gender"]
		npc.profession = data["profession"]
		npc.job_title = data["job_title"]
		npc.cert_code = data["cert_code"]
		npc.skill_level = data["skill_level"]
		npc.cccd_number = data["cccd"]
		npc.harmony_score = data["harmony"]
		npc.vitality = data["vitality"]
		npc.dialogue_text = data["dialogue"]
		
		# Tính toán tọa độ Y chính xác bám mặt đất
		var ground_y = ModularNatureChunk.get_world_height(data["pos"].x, data["pos"].z)
		npc.position = Vector3(data["pos"].x, ground_y, data["pos"].z)
		
		npc_container.add_child(npc)

	for index in range(resident_list.size(), citizen_manager.citizen_registry.size()):
		var citizen_id := str(1000 + index)
		var citizen: CitizenData = citizen_manager.get_citizen(citizen_id)
		if citizen == null:
			push_error("[NaturalLandscape] Thiếu hồ sơ cư dân %s khi tạo NPC." % citizen_id)
			continue
		var npc = npc_script.new()
		npc.configure_from_citizen(citizen)
		var x := citizen.home_coord_km.x * 4.0
		var z := citizen.home_coord_km.y * 4.0
		npc.position = Vector3(x, ModularChunkScript.get_world_height(x, z), z)
		npc_container.add_child(npc)

	var logistics_manager := get_node_or_null("/root/LogisticsManager")
	if logistics_manager != null and logistics_manager.has_method("attach_visuals"):
		logistics_manager.call("attach_visuals", self)

	print("[NaturalLandscape] 👥 Đã đưa %d cư dân có hồ sơ vào thế giới 3D." % npc_container.get_child_count())

func _setup_chunk_streamer() -> void:
	chunk_streamer = WorldChunkStreamer.new()
	chunk_streamer.name = "WorldChunkStreamer"
	# Đồng bộ danh sách chunk cốt lõi đã sinh sẵn
	for coord in chunks.keys():
		chunk_streamer.loaded_chunks[coord] = chunks[coord]
	add_child(chunk_streamer)
	print("[NaturalLandscape] 🌍 Đã kích hoạt WorldChunkStreamer mở rộng thế giới 500 km²!")

func _spawn_four_districts() -> void:
	var districts_container = Node3D.new()
	districts_container.name = "OuterDistricts"
	add_child(districts_container)

	# 1. Huyện Đông (Nông Trại cối xay gió & đồng lúa mạch) tại X=+10.000m, Z=0m
	var east = DistrictsBuilderScript.build_east_district()
	districts_container.add_child(east)

	# 2. Huyện Tây (Kỹ Nghệ & Năng Lượng Sạch quạt gió) tại X=-10.000m, Z=0m
	var west = DistrictsBuilderScript.build_west_district()
	districts_container.add_child(west)

	# 3. Huyện Bắc (Đại Ngàn suối khoáng Onsen & cối xay nước) tại X=0m, Z=-10.000m
	var north = DistrictsBuilderScript.build_north_district()
	districts_container.add_child(north)

	# 4. Huyện Nam (Cảng Hòa Bình, hải đăng & chợ phiên) tại X=0m, Z=+20.000m
	var south = DistrictsBuilderScript.build_south_district()
	districts_container.add_child(south)

	print("[NaturalLandscape] 🏛️ Đã kiến tạo thành công 4 Huyện Ngoại Vi (Đông, Tây, Bắc, Nam) trên đại thế giới 500 km²!")

func _build_spiderweb_transit() -> void:
	var transit = SpiderwebTransitBuilderScript.build_spiderweb_network()
	add_child(transit)

func _build_showcase_housing() -> void:
	var housing_container = Node3D.new()
	housing_container.name = "ShowcaseHousingAvenue"
	add_child(housing_container)

	# Bảng chào mừng Đại Lộ Nhà Mẫu Đỉnh Vát
	var ground_y_arch = ModularChunkScript.get_world_height(38.0, 25.0)
	var arch_sign = Label3D.new()
	arch_sign.name = "AvenueSign3D"
	arch_sign.text = "🏡 ĐẠI LỘ NHÀ MẪU & KHU DÂN CƯ ĐỈNH VÁT\n[Quy Hoạch Phân Lô Đất Ở & Xây Dựng Hoàn Thiện - 4 Kiểu Nhà Chuẩn Tân Thế Giới]"
	arch_sign.font_size = 36
	arch_sign.outline_size = 10
	arch_sign.outline_modulate = Color(0.05, 0.08, 0.14, 0.95)
	arch_sign.modulate = Color(1.0, 0.88, 0.3)
	arch_sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	arch_sign.no_depth_test = true
	arch_sign.position = Vector3(38.0, ground_y_arch + 4.2, 25.0)
	housing_container.add_child(arch_sign)

	var housing_plot_script = load("res://scripts/interactive/housing_plot.gd")
	if not housing_plot_script:
		push_error("[NaturalLandscape] Không tìm thấy housing_plot.gd!")
		return

	var plots_data = [
		# --- HUYỆN ĐỈNH VÁT (CENTRAL PLATEAU CORE) ---
		{
			"plot_id": "plot_plateau_01_studio",
			"district_id": "DISTRICT_PLATEAU_CORE",
			"house_type": "STUDIO_APARTMENT",
			"title": "Chung Cư Studio Anime (Căn Mẫu Hoàn Thiện)",
			"price": 1500.0,
			"area_sqm": 85.0,
			"status": housing_plot_script.PlotStatus.COMPLETED,
			"owner": "Thị Trưởng",
			"land_deed": "SO_DO_TTG_PL01_2026",
			"pos": Vector3(50.0, 0.0, 25.0)
		},
		{
			"plot_id": "plot_plateau_02_coliving",
			"district_id": "DISTRICT_PLATEAU_CORE",
			"house_type": "CO_LIVING_HOUSE",
			"title": "Nhà Chung & Ký Túc Xá Co-Living (Lô Mở Bán)",
			"price": 3500.0,
			"area_sqm": 140.0,
			"status": housing_plot_script.PlotStatus.AVAILABLE,
			"owner": "",
			"land_deed": "SO_DO_TTG_PL02_2026",
			"pos": Vector3(75.0, 0.0, 25.0)
		},
		{
			"plot_id": "plot_plateau_03_family",
			"district_id": "DISTRICT_PLATEAU_CORE",
			"house_type": "FAMILY_RESIDENCE",
			"title": "Căn Hộ Gia Đình Tiện Nghi (Lô Mở Bán)",
			"price": 5500.0,
			"area_sqm": 192.0,
			"status": housing_plot_script.PlotStatus.AVAILABLE,
			"owner": "",
			"land_deed": "SO_DO_TTG_PL03_2026",
			"pos": Vector3(105.0, 0.0, 25.0)
		},
		{
			"plot_id": "plot_plateau_04_cottage",
			"district_id": "DISTRICT_PLATEAU_CORE",
			"house_type": "GARDEN_COTTAGE",
			"title": "Biệt Thự Nhà Vườn Ghibli (Lô Mở Bán)",
			"price": 7500.0,
			"area_sqm": 252.0,
			"status": housing_plot_script.PlotStatus.AVAILABLE,
			"owner": "",
			"land_deed": "SO_DO_TTG_PL04_2026",
			"pos": Vector3(135.0, 0.0, 25.0)
		},

		# --- HUYỆN ĐÔNG NÔNG TRẠI (EAST FARMS) ---
		{
			"plot_id": "plot_east_farm_cottage",
			"district_id": "DISTRICT_EAST_FARMS",
			"house_type": "GARDEN_COTTAGE",
			"title": "Nhà Vườn Thảo Nguyên Huyện Đông (Lô Mở Bán)",
			"price": 6000.0,
			"area_sqm": 252.0,
			"status": housing_plot_script.PlotStatus.AVAILABLE,
			"owner": "",
			"land_deed": "SO_DO_TTG_EAST01_2026",
			"pos": Vector3(10035.0, 0.0, 25.0)
		},
		{
			"plot_id": "plot_east_02_prairie",
			"district_id": "DISTRICT_EAST_FARMS",
			"house_type": "PRAIRIE_FARMSTEAD",
			"title": "Bungalow Nông Trang Thảo Nguyên Huyện Đông (Lô Mở Bán)",
			"price": 6200.0,
			"area_sqm": 220.0,
			"status": housing_plot_script.PlotStatus.AVAILABLE,
			"owner": "",
			"land_deed": "SO_DO_TTG_EAST02_2026",
			"pos": Vector3(10070.0, 0.0, 35.0)
		},

		# --- HUYỆN BẮC RỪNG THÔNG & ONSEN (NORTH FOREST) ---
		{
			"plot_id": "plot_north_onsen_house",
			"district_id": "DISTRICT_NORTH_FOREST",
			"house_type": "CO_LIVING_HOUSE",
			"title": "Nhà Gỗ Nghỉ Dưỡng Onsen Huyện Bắc (Lô Mở Bán)",
			"price": 5000.0,
			"area_sqm": 140.0,
			"status": housing_plot_script.PlotStatus.AVAILABLE,
			"owner": "",
			"land_deed": "SO_DO_TTG_NORTH01_2026",
			"pos": Vector3(25.0, 0.0, -10035.0)
		},
		{
			"plot_id": "plot_north_02_stone",
			"district_id": "DISTRICT_NORTH_FOREST",
			"house_type": "HIGHLAND_STONE_COTTAGE",
			"title": "Nhà Đá Thô Suối Khoáng Huyện Bắc (Lô Mở Bán)",
			"price": 5800.0,
			"area_sqm": 180.0,
			"status": housing_plot_script.PlotStatus.AVAILABLE,
			"owner": "",
			"land_deed": "SO_DO_TTG_NORTH02_2026",
			"pos": Vector3(65.0, 0.0, -10050.0)
		},

		# --- HUYỆN TÂY THUNG LŨNG GIÓ (WEST VALLEY) ---
		{
			"plot_id": "plot_west_01_windmill",
			"district_id": "DISTRICT_WEST_VALLEY",
			"house_type": "VALLEY_WINDMILL_LOFT",
			"title": "Nhà Gác Lửng Thung Lũng Gió Huyện Tây (Lô Mở Bán)",
			"price": 4500.0,
			"area_sqm": 150.0,
			"status": housing_plot_script.PlotStatus.AVAILABLE,
			"owner": "",
			"land_deed": "SO_DO_TTG_WEST01_2026",
			"pos": Vector3(-10035.0, 0.0, 25.0)
		},
		{
			"plot_id": "plot_west_02_studio",
			"district_id": "DISTRICT_WEST_VALLEY",
			"house_type": "STUDIO_APARTMENT",
			"title": "Căn Hộ Nghệ Nhân Kỹ Nghệ Huyện Tây (Lô Mở Bán)",
			"price": 2200.0,
			"area_sqm": 95.0,
			"status": housing_plot_script.PlotStatus.AVAILABLE,
			"owner": "",
			"land_deed": "SO_DO_TTG_WEST02_2026",
			"pos": Vector3(-10070.0, 0.0, 35.0)
		},

		# --- HUYỆN NAM CẢNG HÒA BÌNH (SOUTH BAY & PORT) ---
		{
			"plot_id": "plot_south_01_villa",
			"district_id": "DISTRICT_SOUTH_PORT",
			"house_type": "COASTAL_VILLA",
			"title": "Biệt Thự Duyên Hải Vịnh Biển Huyện Nam (Lô Mở Bán)",
			"price": 8500.0,
			"area_sqm": 300.0,
			"status": housing_plot_script.PlotStatus.AVAILABLE,
			"owner": "",
			"land_deed": "SO_DO_TTG_SOUTH01_2026",
			"pos": Vector3(25.0, 0.0, 10035.0)
		},
		{
			"plot_id": "plot_south_02_stilt",
			"district_id": "DISTRICT_SOUTH_PORT",
			"house_type": "LAKESIDE_STILT_HOUSE",
			"title": "Nhà Sàn Sinh Thái Cửa Biển Huyện Nam (Lô Mở Bán)",
			"price": 4200.0,
			"area_sqm": 140.0,
			"status": housing_plot_script.PlotStatus.AVAILABLE,
			"owner": "",
			"land_deed": "SO_DO_TTG_SOUTH02_2026",
			"pos": Vector3(65.0, 0.0, 10050.0)
		}
	]

	for p_data in plots_data:
		var plot = housing_plot_script.new()
		plot.name = "HousingPlot_" + p_data["plot_id"]
		plot.plot_id = p_data["plot_id"]
		plot.district_id = p_data["district_id"]
		plot.house_type = p_data["house_type"]
		plot.title = p_data["title"]
		plot.price = p_data["price"]
		plot.area_sqm = p_data["area_sqm"]
		plot.current_status = p_data["status"]
		plot.owner_name = p_data["owner"]
		plot.land_deed_number = p_data.get("land_deed", "")
		
		var gy = ModularChunkScript.get_world_height(p_data["pos"].x, p_data["pos"].z)
		plot.position = Vector3(p_data["pos"].x, gy, p_data["pos"].z)
		
		housing_container.add_child(plot)

	print("[NaturalLandscape] 🏡 Đã kiến tạo thành công %d Lô Đất Nhà Mẫu & Khu Dân Cư Tân Thế Giới!" % plots_data.size())
