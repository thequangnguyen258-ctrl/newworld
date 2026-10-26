class_name WorldChunkStreamer
extends Node3D

# ==============================================================================
# WORLD CHUNK STREAMER (TÂN THẾ GIỚI - QUY MÔ 1500 KM²)
# 1. Động cơ sinh địa hình động theo bước chân người chơi (Dynamic Chunk Streaming)
# 2. Duy trì lưới Chunks luôn bám sát vị trí Thị Trưởng
# 3. Tối ưu hóa đồ họa Rừng Cây Thông bằng Octahedral Impostor LOD (45m -> 2500m)
# 4. Thu hồi và giải phóng bộ nhớ RAM các chunk ở xa (bảo đảm 60 FPS trên Intel Iris Xe)
# 5. Người chơi có thể đi bộ hoặc bay trực thăng hàng chục kilomet trên đại thế giới 1500 km²!
# 6. Tự động sinh cây cối, hoa dại và đá cuội theo hạt giống xác định (Deterministic Flora)
# ==============================================================================

const CHUNK_SIZE: float = 64.0
const ACTIVE_RADIUS: int = 4 # 9x9 Chunks (Bán kính 288m bao quanh người chơi)
const UNLOAD_RADIUS: int = 6 # Khoảng cách dọn dẹp bộ nhớ

@export var player_node: Node3D

var loaded_chunks: Dictionary = {} # Vector2i -> ModularNatureChunk
var last_player_chunk: Vector2i = Vector2i(999999, 999999)
var is_streaming_active: bool = true

func _ready() -> void:
	if player_node == null:
		player_node = get_tree().get_first_node_in_group("player")
		
	# Khởi tạo cụm chunk ban đầu quanh vị trí người chơi
	_update_streaming(true)
	print("[WorldChunkStreamer] 🌍 Khởi động Động cơ Sinh Địa Hình Động 500 km² thành công!")

func _process(_delta: float) -> void:
	if not is_streaming_active:
		return
		
	if player_node == null or not is_instance_valid(player_node):
		player_node = get_tree().get_first_node_in_group("player")
		if player_node == null:
			return
			
	var p_pos = player_node.global_position
	var cur_chunk = Vector2i(
		int(round(p_pos.x / CHUNK_SIZE)),
		int(round(p_pos.z / CHUNK_SIZE))
	)
	
	if cur_chunk != last_player_chunk:
		last_player_chunk = cur_chunk
		_update_streaming(false)

func _update_streaming(force_immediate: bool = false) -> void:
	if player_node == null:
		return
		
	var p_pos = player_node.global_position
	var center = Vector2i(
		int(round(p_pos.x / CHUNK_SIZE)),
		int(round(p_pos.z / CHUNK_SIZE))
	)
	
	var needed_coords: Array[Vector2i] = []
	for cz in range(center.y - ACTIVE_RADIUS, center.y + ACTIVE_RADIUS + 1):
		for cx in range(center.x - ACTIVE_RADIUS, center.x + ACTIVE_RADIUS + 1):
			needed_coords.append(Vector2i(cx, cz))
			
	# 1. Sinh các Chunk mới cần tải
	var spawn_count: int = 0
	for coord in needed_coords:
		if not loaded_chunks.has(coord):
			_spawn_chunk(coord)
			spawn_count += 1
			if not force_immediate and spawn_count >= 4:
				# Chia nhỏ tải để giữ mượt 60 FPS
				break
				
	# 2. Dọn dẹp thu hồi các Chunk ở ngoài bán kính UNLOAD_RADIUS
	var to_remove: Array[Vector2i] = []
	for coord in loaded_chunks.keys():
		var dist_x = abs(coord.x - center.x)
		var dist_z = abs(coord.y - center.y)
		if dist_x > UNLOAD_RADIUS or dist_z > UNLOAD_RADIUS:
			to_remove.append(coord)
			
	for coord in to_remove:
		var chunk = loaded_chunks[coord]
		if is_instance_valid(chunk):
			chunk.queue_free()
		loaded_chunks.erase(coord)

func _spawn_chunk(coord: Vector2i) -> void:
	var wx = float(coord.x) * CHUNK_SIZE
	var wz = float(coord.y) * CHUNK_SIZE
	
	# Xác định kiểu chunk dựa trên vị trí địa lý 500 km²
	var c_type = ModularNatureChunk.ChunkType.FLAT_GRASS_PLATEAU
	
	# Khu vực Suối Tự Nhiên
	if abs(wx - sin(wz * 0.004) * 25.0) < 18.0 and wz > -100.0 and wz < 11800.0:
		c_type = ModularNatureChunk.ChunkType.RIVER_STREAM
	# Khu vực Mỏm Đá Ngắm Cảnh
	elif abs(wx - 1000.0) < 64.0 and abs(wz - 13000.0) < 64.0:
		c_type = ModularNatureChunk.ChunkType.SCENIC_LOOKOUT_CLIFF
	# Khu vực Vách Đá Mép Vực
	elif sqrt(wx * wx + wz * wz) > 12500.0 and sqrt(wx * wx + wz * wz) < 15500.0:
		c_type = ModularNatureChunk.ChunkType.CLIFF_EDGE_STEPPED
		
	var chunk = ModularNatureChunk.new(c_type, coord)
	chunk.name = "Chunk_%d_%d" % [coord.x, coord.y]
	chunk.position = Vector3(float(coord.x) * CHUNK_SIZE, 0.0, float(coord.y) * CHUNK_SIZE)
	add_child(chunk)
	loaded_chunks[coord] = chunk
	
	# Sinh thảm thực vật xác định cho chunk này
	_spawn_chunk_flora(chunk, coord)

func _spawn_chunk_flora(chunk: Node3D, coord: Vector2i) -> void:
	# Sử dụng seed băm xác định để cây cối luôn mọc cố định đúng chỗ
	var seed_val = abs((coord.x * 73856093) ^ (coord.y * 19349663)) % 100000
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_val
	
	var flora_container = Node3D.new()
	flora_container.name = "ChunkFlora"
	chunk.add_child(flora_container)
	
	var wx_center = float(coord.x) * CHUNK_SIZE
	var wz_center = float(coord.y) * CHUNK_SIZE
	# 1. Rừng Cây Thông & Cây Đại Thụ phân bổ theo Hệ Sinh Thái 500 km²
	var is_north_forest = (wz_center < -5000.0 and abs(wx_center) < 6000.0)
	var is_east_farmland = (wx_center > 5000.0 and abs(wz_center) < 6000.0)
	var is_south_coastal = (wz_center > 16000.0)
	
	var num_trees = rng.randi_range(2, 5)
	if is_north_forest:
		num_trees = rng.randi_range(5, 9) # Rừng thông đại ngàn rậm rạp
	elif is_east_farmland:
		num_trees = rng.randi_range(1, 3) # Vựa thảo nguyên lúa mì thoáng đãng
	elif is_south_coastal:
		num_trees = rng.randi_range(1, 3) # Duyên hải lộng gió
		
	for i in range(num_trees):
		var ox = rng.randf_range(-26.0, 26.0)
		var oz = rng.randf_range(-26.0, 26.0)
		var world_x = wx_center + ox
		var world_z = wz_center + oz
		if _is_reserved_world_area(world_x, world_z):
			continue
		var ground_y = ModularNatureChunk.get_world_height(world_x, world_z)
		
		# Tránh mọc giữa lòng suối
		var river_x = sin(world_z * 0.004) * 25.0
		if abs(world_x - river_x) < 8.0:
			continue
			
		var tree_mesh = _create_stylized_tree(rng.randf() > 0.45)
		tree_mesh.position = Vector3(ox, ground_y, oz)
		var s = rng.randf_range(0.85, 1.35)
		tree_mesh.scale = Vector3(s, s, s)
		tree_mesh.rotation.y = rng.randf_range(0.0, TAU)
		flora_container.add_child(tree_mesh)
		
	# 2. Bụi Hoa Dại & Khóm Đá Cuội (3 - 6 khóm trên mỗi chunk)
	var num_decor = rng.randi_range(3, 7)
	for i in range(num_decor):
		var ox = rng.randf_range(-28.0, 28.0)
		var oz = rng.randf_range(-28.0, 28.0)
		var world_x = wx_center + ox
		var world_z = wz_center + oz
		if _is_reserved_world_area(world_x, world_z):
			continue
		var ground_y = ModularNatureChunk.get_world_height(world_x, world_z)
		
		var decor_mesh: Node3D
		if rng.randf() > 0.4:
			decor_mesh = _create_wildflower_patch(rng)
		else:
			decor_mesh = _create_mossy_boulder(rng)
			
		decor_mesh.position = Vector3(ox, ground_y, oz)
		flora_container.add_child(decor_mesh)

func _is_reserved_world_area(world_x: float, world_z: float) -> bool:
	return (
		Vector2(world_x, world_z).length() <= 250.0
		or Vector2(world_x - 130.0, world_z - 130.0).length() <= 24.0
		or (absf(world_x) <= 325.0 and absf(world_z - 275.0) <= 10.0)
		or (absf(world_x) <= 355.0 and absf(world_z - 230.0) <= 25.0)
		or Vector2(world_x - 22.0, world_z - 205.0).length() <= 18.0
		or Vector2(world_x - 290.0, world_z - 100.0).length() <= 18.0
	)

func _create_stylized_tree(is_pine: bool) -> Node3D:
	var tree = Node3D.new()
	
	# Thân cây gỗ nâu ấm
	var trunk = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.22
	cyl.bottom_radius = 0.38
	cyl.height = 3.2
	trunk.mesh = cyl
	
	var wood_mat = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.42, 0.28, 0.18)
	wood_mat.roughness = 0.9
	trunk.material_override = wood_mat
	trunk.position.y = 1.6
	tree.add_child(trunk)
	
	var leaf_mat = StandardMaterial3D.new()
	leaf_mat.roughness = 0.7
	leaf_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	
	if is_pine:
		# Cây thông 3 tầng tán nón Ghibli
		leaf_mat.albedo_color = Color(0.24, 0.52, 0.36)
		for t in range(3):
			var foliage = MeshInstance3D.new()
			var cone = CylinderMesh.new()
			cone.top_radius = 0.05
			cone.bottom_radius = 1.9 - t * 0.45
			cone.height = 1.8
			foliage.mesh = cone
			foliage.material_override = leaf_mat
			foliage.position.y = 2.6 + t * 1.3
			tree.add_child(foliage)
		
		# Tối ưu hóa đồ họa quy mô thế giới 1500 km² bằng Octahedral Impostor LOD (45m -> 2500m)
		OctahedralPineLOD.apply_lod_to_pine_tree(tree, 45.0, 5.0)
	else:
		# Cây đại thụ tán mây tròn bồng bềnh
		leaf_mat.albedo_color = Color(0.38, 0.72, 0.34)
		var canopy = MeshInstance3D.new()
		var sph = SphereMesh.new()
		sph.radius = 1.8
		sph.height = 3.2
		canopy.mesh = sph
		canopy.material_override = leaf_mat
		canopy.position.y = 3.6
		tree.add_child(canopy)
		
	return tree

func _create_wildflower_patch(rng: RandomNumberGenerator) -> Node3D:
	var patch = Node3D.new()
	var flower_colors = [
		Color(1.0, 0.88, 0.2), # Cúc vàng rực rỡ
		Color(0.95, 0.45, 0.6), # Hoa thảo nguyên hồng
		Color(0.85, 0.95, 1.0)  # Cúc tuyết trắng lam
	]
	var col = flower_colors[rng.randi() % flower_colors.size()]
	
	var flower_mat = StandardMaterial3D.new()
	flower_mat.albedo_color = col
	flower_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	
	for i in range(rng.randi_range(3, 6)):
		var petal = MeshInstance3D.new()
		var sph = SphereMesh.new()
		sph.radius = 0.18
		sph.height = 0.35
		petal.mesh = sph
		petal.material_override = flower_mat
		petal.position = Vector3(
			rng.randf_range(-0.6, 0.6),
			0.15,
			rng.randf_range(-0.6, 0.6)
		)
		patch.add_child(petal)
		
	return patch

func _create_mossy_boulder(rng: RandomNumberGenerator) -> Node3D:
	var rock = MeshInstance3D.new()
	var box = BoxMesh.new()
	var sx = rng.randf_range(0.8, 1.8)
	var sy = rng.randf_range(0.5, 1.2)
	var sz = rng.randf_range(0.8, 1.8)
	box.size = Vector3(sx, sy, sz)
	rock.mesh = box
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.48, 0.52, 0.46) # Xám rêu phong
	mat.roughness = 0.95
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	rock.material_override = mat
	rock.position.y = sy * 0.4
	rock.rotation.y = rng.randf_range(0.0, TAU)
	return rock

func force_refresh_at_position(world_pos: Vector3) -> void:
	# Dùng khi người chơi Fast Travel đến vị trí xa hàng chục kilomet
	var center = Vector2i(
		int(round(world_pos.x / CHUNK_SIZE)),
		int(round(world_pos.z / CHUNK_SIZE))
	)
	last_player_chunk = center
	
	# Xóa toàn bộ chunk cũ
	for coord in loaded_chunks.keys():
		var chunk = loaded_chunks[coord]
		if is_instance_valid(chunk):
			chunk.queue_free()
	loaded_chunks.clear()
	
	# Sinh lưới chunk mới tức thì quanh vị trí mới
	for cz in range(center.y - ACTIVE_RADIUS, center.y + ACTIVE_RADIUS + 1):
		for cx in range(center.x - ACTIVE_RADIUS, center.x + ACTIVE_RADIUS + 1):
			_spawn_chunk(Vector2i(cx, cz))
			
	print("[WorldChunkStreamer] ⚡ Đã tải lưới địa hình mới tại tọa độ: (%.1f, %.1f)" % [world_pos.x, world_pos.z])
