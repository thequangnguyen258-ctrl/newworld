@tool
class_name BoulevardDecorations
extends Node3D

# ==============================================================================
# TRANG TRÍ ĐẠI LỘ TRUNG TÂM (GHIBLI TREES, VINTAGE STREETLIGHTS, TRAM TRACKS)
# Tọa độ local chính xác nằm trên bề mặt GrandBoulevard (kích thước 20m x 0.2m x 420m)
# ==============================================================================

func _ready() -> void:
	if get_child_count() == 0:
		build_decorations()

func build_decorations() -> void:
	for child in get_children():
		child.queue_free()
		
	_build_tram_rails()
	_build_avenue_trees()
	_build_vintage_streetlights()

func _build_tram_rails() -> void:
	# Ray xe tram kép chạy dọc tim đường (mặt đường local Y = 0.1m)
	var rail_len = 400.0
	var rail_mesh = BoxMesh.new()
	rail_mesh.size = Vector3(0.15, 0.08, rail_len)
	var mat_steel = StandardMaterial3D.new()
	mat_steel.albedo_color = Color(0.35, 0.38, 0.42)
	mat_steel.metallic = 0.8
	mat_steel.roughness = 0.3
	rail_mesh.material = mat_steel
	
	# Ray trái
	var rail_left = MeshInstance3D.new()
	rail_left.mesh = rail_mesh
	rail_left.transform.origin = Vector3(-1.2, 0.14, 0)
	add_child(rail_left)
	
	# Ray phải
	var rail_right = MeshInstance3D.new()
	rail_right.mesh = rail_mesh
	rail_right.transform.origin = Vector3(1.2, 0.14, 0)
	add_child(rail_right)

func _build_avenue_trees() -> void:
	# Hàng cây Anime Ghibli dọc 2 bên lề đại lộ
	var trunk_mesh = CylinderMesh.new()
	trunk_mesh.top_radius = 0.35
	trunk_mesh.bottom_radius = 0.5
	trunk_mesh.height = 3.5
	var mat_trunk = StandardMaterial3D.new()
	mat_trunk.albedo_color = Color(0.42, 0.28, 0.18)
	trunk_mesh.material = mat_trunk
	
	var foliage_mesh = SphereMesh.new()
	foliage_mesh.radius = 2.4
	foliage_mesh.height = 4.8
	var mat_foliage = StandardMaterial3D.new()
	mat_foliage.albedo_color = Color(0.32, 0.72, 0.28) # Xanh lá Ghibli tươi tắn
	mat_foliage.roughness = 0.85
	foliage_mesh.material = mat_foliage
	
	# Đặt cây cách nhau mỗi 25m dọc trục Z từ -190m đến +190m
	var z_pos = -190.0
	while z_pos <= 190.0:
		for side in [-8.5, 8.5]: # Hai bên vỉa hè
			var tree_node = Node3D.new()
			tree_node.transform.origin = Vector3(side, 0.1, z_pos)
			
			var trunk = MeshInstance3D.new()
			trunk.mesh = trunk_mesh
			trunk.transform.origin = Vector3(0, 1.75, 0)
			tree_node.add_child(trunk)
			
			var foliage = MeshInstance3D.new()
			foliage.mesh = foliage_mesh
			foliage.transform.origin = Vector3(0, 4.5, 0)
			tree_node.add_child(foliage)
			
			add_child(tree_node)
		z_pos += 25.0

func _build_vintage_streetlights() -> void:
	# Cột đèn đường cổ điển kiểu vintage
	var pole_mesh = CylinderMesh.new()
	pole_mesh.top_radius = 0.08
	pole_mesh.bottom_radius = 0.15
	pole_mesh.height = 4.2
	var mat_pole = StandardMaterial3D.new()
	mat_pole.albedo_color = Color(0.18, 0.22, 0.25)
	mat_pole.metallic = 0.6
	pole_mesh.material = mat_pole
	
	var lamp_mesh = SphereMesh.new()
	lamp_mesh.radius = 0.35
	lamp_mesh.height = 0.7
	var mat_lamp = StandardMaterial3D.new()
	mat_lamp.albedo_color = Color(1.0, 0.95, 0.75)
	mat_lamp.emission_enabled = true
	mat_lamp.emission = Color(1.0, 0.9, 0.6)
	mat_lamp.emission_energy_multiplier = 1.8
	lamp_mesh.material = mat_lamp
	
	var z_pos = -180.0
	while z_pos <= 180.0:
		for side in [-7.2, 7.2]:
			var pole = MeshInstance3D.new()
			pole.mesh = pole_mesh
			pole.transform.origin = Vector3(side, 2.2, z_pos)
			
			var lamp = MeshInstance3D.new()
			lamp.mesh = lamp_mesh
			lamp.transform.origin = Vector3(0, 2.1, 0)
			pole.add_child(lamp)
			
			add_child(pole)
		z_pos += 35.0
