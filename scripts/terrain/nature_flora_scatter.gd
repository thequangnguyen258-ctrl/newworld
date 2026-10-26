@tool
class_name NatureFloraScatter
extends Node3D

# ==============================================================================
# NATURE FLORA SCATTER (TÂN THẾ GIỚI - GHIBLI / ANIME STYLE)
# Hệ thống gieo mầm thảm thực vật tự nhiên theo độ cao thực tế của địa hình:
# 1. Cây Thông Cao Nguyên (Ghibli Conifer / Pine): Rừng thông sườn núi & ven đường mòn
# 2. Cây Tán Tròn Đại Ngàn (Anime Deciduous Tree): Rặng cây xanh ven thảo nguyên
# 3. Thảm Hoa Dại Rực Rỡ (Alpine Wildflowers): Hoa cúc vàng & hoa dại vùng cao
# 4. Tảng Đá Cuội Rêu Phong (River Boulders): Viền theo lòng suối & mép đường mòn
# Tọa độ Y bám sát 100% theo ModularNatureChunk.get_world_height(x, z)!
# ==============================================================================

@export var auto_generate: bool = true

var pine_multimesh: MultiMeshInstance3D
var deciduous_multimesh: MultiMeshInstance3D
var flower_multimesh: MultiMeshInstance3D
var boulder_multimesh: MultiMeshInstance3D

const PLAZA_EXCLUSION_RADIUS: float = 250.0
const HELIPAD_EXCLUSION_CENTER := Vector2(130.0, 130.0)
const HELIPAD_EXCLUSION_RADIUS: float = 24.0
const AVENUE_Z: float = 230.0

func _ready() -> void:
	if auto_generate and get_child_count() == 0:
		generate_flora()

func generate_flora() -> void:
	for child in get_children():
		child.queue_free()
		
	_generate_pine_trees()
	_generate_deciduous_trees()
	_generate_wildflowers()
	_generate_river_boulders()
	print("[NatureFloraScatter] 🌸 Hoàn tất gieo mầm Rừng Cây Anime, Thảm Hoa Dại & Đá Cuội Tự Nhiên!")

# ------------------------------------------------------------------------------
# 1. CÂY THÔNG CAO NGUYÊN (PINE / CONIFER)
# ------------------------------------------------------------------------------
func _generate_pine_trees() -> void:
	var pine_mesh = _build_pine_tree_mesh()
	
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = pine_mesh
	
	var rng = RandomNumberGenerator.new()
	rng.seed = 2026
	
	var tree_transforms: Array[Transform3D] = []
	
	# 1.1. Rừng thông rải rác phía Bắc cao nguyên (Z từ -20m đến -120m)
	for i in range(65):
		var x = rng.randf_range(-120.0, 120.0)
		var z = rng.randf_range(-115.0, -20.0)
		
		if _is_reserved_area(x, z):
			continue
			
		var y = ModularNatureChunk.get_world_height(x, z)
		var s = rng.randf_range(0.85, 1.4)
		var rot = rng.randf_range(0, TAU)
		
		var xform = Transform3D()
		xform = xform.rotated(Vector3.UP, rot)
		xform = xform.scaled(Vector3(s, s, s))
		xform.origin = Vector3(x, y, z)
		tree_transforms.append(xform)
		
	# 1.2. Cụm thông rải rác đồi Tây & đồi Đông trên cao nguyên
	for i in range(35):
		var side = -1.0 if (i % 2 == 0) else 1.0
		var x = side * rng.randf_range(40.0, 130.0)
		var z = rng.randf_range(-20.0, 60.0)
		if _is_reserved_area(x, z):
			continue
		var y = ModularNatureChunk.get_world_height(x, z)
		var s = rng.randf_range(0.8, 1.3)
		var rot = rng.randf_range(0, TAU)
		
		var xform = Transform3D()
		xform = xform.rotated(Vector3.UP, rot)
		xform = xform.scaled(Vector3(s, s, s))
		xform.origin = Vector3(x, y, z)
		tree_transforms.append(xform)
		
	mm.instance_count = tree_transforms.size()
	for i in range(tree_transforms.size()):
		mm.set_instance_transform(i, tree_transforms[i])
		
	pine_multimesh = MultiMeshInstance3D.new()
	pine_multimesh.name = "PineForestMultiMesh"
	pine_multimesh.multimesh = mm
	pine_multimesh.visibility_range_end = 50.0
	pine_multimesh.visibility_range_end_margin = 5.0
	pine_multimesh.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	add_child(pine_multimesh)

	# Tối ưu hóa Octahedral Impostor LOD cho rừng thông sườn núi & cao nguyên 1500 km²
	var impostor_mm = OctahedralPineLOD.create_impostor_forest_multimesh(tree_transforms)
	if impostor_mm:
		impostor_mm.name = "PineForestImpostorMultiMesh"
		add_child(impostor_mm)

func _build_pine_tree_mesh() -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var foliage_mat = StandardMaterial3D.new()
	foliage_mat.albedo_color = Color(0.18, 0.52, 0.32, 1.0)
	foliage_mat.roughness = 0.8
	foliage_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	foliage_mat.specular_mode = BaseMaterial3D.SPECULAR_TOON
	
	# 1. Thân cây gỗ nâu ấm
	_add_cone_to_st(st, Vector3(0, 0, 0), 0.35, 0.2, 1.5, 6)
	
	# 2. Tán nón 1 (Dưới cùng)
	_add_cone_to_st(st, Vector3(0, 1.2, 0), 2.2, 0.2, 2.0, 7)
	
	# 3. Tán nón 2 (Ở giữa)
	_add_cone_to_st(st, Vector3(0, 2.4, 0), 1.7, 0.15, 1.9, 7)
	
	# 4. Tán nón 3 (Trên cùng)
	_add_cone_to_st(st, Vector3(0, 3.6, 0), 1.1, 0.05, 1.8, 6)
	
	st.generate_normals()
	var mesh = st.commit()
	mesh.surface_set_material(0, foliage_mat)
	return mesh

func _add_cone_to_st(st: SurfaceTool, base_pos: Vector3, r_bot: float, r_top: float, h: float, segs: int) -> void:
	for i in range(segs):
		var a0 = (float(i) / float(segs)) * TAU
		var a1 = (float(i + 1) / float(segs)) * TAU
		
		var b0 = base_pos + Vector3(cos(a0) * r_bot, 0, sin(a0) * r_bot)
		var b1 = base_pos + Vector3(cos(a1) * r_bot, 0, sin(a1) * r_bot)
		var t0 = base_pos + Vector3(cos(a0) * r_top, h, sin(a0) * r_top)
		var t1 = base_pos + Vector3(cos(a1) * r_top, h, sin(a1) * r_top)
		
		st.add_vertex(b0)
		st.add_vertex(t0)
		st.add_vertex(b1)
		
		st.add_vertex(b1)
		st.add_vertex(t0)
		st.add_vertex(t1)
		
		st.add_vertex(base_pos)
		st.add_vertex(b1)
		st.add_vertex(b0)

# ------------------------------------------------------------------------------
# 2. CÂY ĐẠI THỤ TÁN TRÒN (ANIME DECIDUOUS TREE)
# ------------------------------------------------------------------------------
func _generate_deciduous_trees() -> void:
	var tree_mesh = _build_deciduous_mesh()
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = tree_mesh
	
	var rng = RandomNumberGenerator.new()
	rng.seed = 2027
	
	var transforms: Array[Transform3D] = []
	for i in range(40):
		var x = rng.randf_range(-105.0, 105.0)
		var z = rng.randf_range(-25.0, 50.0)
		
		var river_center_x = sin(z * 0.05) * 8.0
		var dist_stream = abs(x - river_center_x)
		if dist_stream < 9.0 or dist_stream > 65.0:
			continue
		if _is_reserved_area(x, z):
			continue
			
		var y = ModularNatureChunk.get_world_height(x, z)
		var s = rng.randf_range(0.85, 1.4)
		var rot = rng.randf_range(0, TAU)
		
		var xform = Transform3D()
		xform = xform.rotated(Vector3.UP, rot)
		xform = xform.scaled(Vector3(s, s, s))
		xform.origin = Vector3(x, y, z)
		transforms.append(xform)
		
	mm.instance_count = transforms.size()
	for i in range(transforms.size()):
		mm.set_instance_transform(i, transforms[i])
		
	deciduous_multimesh = MultiMeshInstance3D.new()
	deciduous_multimesh.name = "DeciduousGroveMultiMesh"
	deciduous_multimesh.multimesh = mm
	add_child(deciduous_multimesh)

func _build_deciduous_mesh() -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var foliage_mat = StandardMaterial3D.new()
	foliage_mat.albedo_color = Color(0.38, 0.72, 0.28, 1.0)
	foliage_mat.roughness = 0.85
	foliage_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	foliage_mat.specular_mode = BaseMaterial3D.SPECULAR_TOON
	
	_add_cone_to_st(st, Vector3(0, 0, 0), 0.5, 0.3, 3.2, 6)
	
	var spheres = [
		{"pos": Vector3(0, 4.5, 0), "r": 2.2},
		{"pos": Vector3(-0.9, 3.8, 0.7), "r": 1.6},
		{"pos": Vector3(0.9, 4.0, -0.6), "r": 1.7}
	]
	
	for sph in spheres:
		_add_sphere_to_st(st, sph["pos"], sph["r"], 8, 6)
		
	st.generate_normals()
	var mesh = st.commit()
	mesh.surface_set_material(0, foliage_mat)
	return mesh

func _add_sphere_to_st(st: SurfaceTool, center: Vector3, radius: float, segs_u: int, segs_v: int) -> void:
	for v in range(segs_v):
		var phi0 = (float(v) / float(segs_v)) * PI
		var phi1 = (float(v + 1) / float(segs_v)) * PI
		
		for u in range(segs_u):
			var theta0 = (float(u) / float(segs_u)) * TAU
			var theta1 = (float(u + 1) / float(segs_u)) * TAU
			
			var p00 = center + Vector3(sin(phi0) * cos(theta0), cos(phi0), sin(phi0) * sin(theta0)) * radius
			var p10 = center + Vector3(sin(phi0) * cos(theta1), cos(phi0), sin(phi0) * sin(theta1)) * radius
			var p01 = center + Vector3(sin(phi1) * cos(theta0), cos(phi1), sin(phi1) * sin(theta0)) * radius
			var p11 = center + Vector3(sin(phi1) * cos(theta1), cos(phi1), sin(phi1) * sin(theta1)) * radius
			
			st.add_vertex(p00)
			st.add_vertex(p10)
			st.add_vertex(p01)
			
			st.add_vertex(p10)
			st.add_vertex(p11)
			st.add_vertex(p01)

# ------------------------------------------------------------------------------
# 3. THẢM HOA DẠI RỰC RỠ (ALPINE WILDFLOWERS)
# ------------------------------------------------------------------------------
func _generate_wildflowers() -> void:
	var flower_mesh = _build_flower_cluster_mesh()
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = flower_mesh
	
	var rng = RandomNumberGenerator.new()
	rng.seed = 2028
	
	var transforms: Array[Transform3D] = []
	for i in range(130):
		var x = rng.randf_range(-115.0, 115.0)
		var z = rng.randf_range(-55.0, 60.0)
		
		var river_center_x = sin(z * 0.05) * 8.0
		if abs(x - river_center_x) < 7.0:
			continue
		if _is_reserved_area(x, z):
			continue
			
		var y = ModularNatureChunk.get_world_height(x, z)
		var s = rng.randf_range(0.7, 1.4)
		var rot = rng.randf_range(0, TAU)
		
		var xform = Transform3D()
		xform = xform.rotated(Vector3.UP, rot)
		xform = xform.scaled(Vector3(s, s, s))
		xform.origin = Vector3(x, y + 0.15, z)
		transforms.append(xform)
		
	mm.instance_count = transforms.size()
	for i in range(transforms.size()):
		mm.set_instance_transform(i, transforms[i])
		
	flower_multimesh = MultiMeshInstance3D.new()
	flower_multimesh.name = "WildflowersMultiMesh"
	flower_multimesh.multimesh = mm
	add_child(flower_multimesh)

func _build_flower_cluster_mesh() -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.85, 0.35, 1.0)
	mat.roughness = 0.6
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	
	var h = 0.45
	var w = 0.45
	
	st.add_vertex(Vector3(-w, 0, 0))
	st.add_vertex(Vector3(w, 0, 0))
	st.add_vertex(Vector3(-w, h, 0))
	
	st.add_vertex(Vector3(w, 0, 0))
	st.add_vertex(Vector3(w, h, 0))
	st.add_vertex(Vector3(-w, h, 0))
	
	st.add_vertex(Vector3(0, 0, -w))
	st.add_vertex(Vector3(0, 0, w))
	st.add_vertex(Vector3(0, h, -w))
	
	st.add_vertex(Vector3(0, 0, w))
	st.add_vertex(Vector3(0, h, w))
	st.add_vertex(Vector3(0, h, -w))
	
	st.generate_normals()
	var mesh = st.commit()
	mesh.surface_set_material(0, mat)
	return mesh

# ------------------------------------------------------------------------------
# 4. TẢNG ĐÁ CUỘI RÊU PHONG (RIVER BOULDERS)
# ------------------------------------------------------------------------------
func _generate_river_boulders() -> void:
	var boulder_mesh = _build_boulder_mesh()
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = boulder_mesh
	
	var rng = RandomNumberGenerator.new()
	rng.seed = 2029
	
	var transforms: Array[Transform3D] = []
	for z_step in range(-35, 75, 4):
		var z = float(z_step) + rng.randf_range(-1.2, 1.2)
		var river_x = sin(z * 0.05) * 8.0
		
		var side = -1.0 if rng.randf() > 0.5 else 1.0
		var x = river_x + side * rng.randf_range(5.5, 9.0)
		if _is_reserved_area(x, z):
			continue
		var y = ModularNatureChunk.get_world_height(x, z) - 0.2
		var s = rng.randf_range(0.65, 1.35)
		var rot = rng.randf_range(0, TAU)
		
		var xform = Transform3D()
		xform = xform.rotated(Vector3.UP, rot)
		xform = xform.scaled(Vector3(s, s * 0.7, s))
		xform.origin = Vector3(x, y, z)
		transforms.append(xform)
		
	mm.instance_count = transforms.size()
	for i in range(transforms.size()):
		mm.set_instance_transform(i, transforms[i])
		
	boulder_multimesh = MultiMeshInstance3D.new()
	boulder_multimesh.name = "RiverBouldersMultiMesh"
	boulder_multimesh.multimesh = mm
	add_child(boulder_multimesh)

func _is_reserved_area(x: float, z: float) -> bool:
	return (
		Vector2(x, z).length() <= PLAZA_EXCLUSION_RADIUS
		or Vector2(x - HELIPAD_EXCLUSION_CENTER.x, z - HELIPAD_EXCLUSION_CENTER.y).length() <= HELIPAD_EXCLUSION_RADIUS
		or (absf(x) <= 325.0 and absf(z - 275.0) <= 10.0)
		or (absf(x) <= 355.0 and absf(z - AVENUE_Z) <= 25.0)
		or Vector2(x - 22.0, z - 205.0).length() <= 18.0
		or Vector2(x - 290.0, z - 100.0).length() <= 18.0
	)

func _build_boulder_mesh() -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.52, 0.48, 1.0)
	mat.roughness = 0.85
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	
	_add_sphere_to_st(st, Vector3(0, 0.6, 0), 0.9, 8, 6)
	st.generate_normals()
	var mesh = st.commit()
	mesh.surface_set_material(0, mat)
	return mesh
