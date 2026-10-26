extends SceneTree

var world: Node
var player: CharacterBody3D
var step_index: int = 0
var waypoints: Array[Vector2] = [
	Vector2(0.0, 0.0),     # 0: Quảng trường trung tâm (+600m)
	Vector2(0.0, -25.0),   # 1: Lối đi phía Bắc cao nguyên
	Vector2(35.0, -50.0),  # 2: Thảo nguyên Đông Bắc
	Vector2(-35.0, -80.0), # 3: Thảo nguyên Tây Bắc
	Vector2(0.0, -120.0)   # 4: Cao nguyên phía sau Mega Office (+600m)
]

func _initialize() -> void:
	print("=================================================================")
	print("🌿 KIỂM THỬ: CAO NGUYÊN PHẲNG PHÍA SAU MEGA OFFICE")
	print("=================================================================")
	var scn = load("res://scenes/core/main_world.tscn")
	world = scn.instantiate()
	root.add_child(world)
	player = world.get_node("Player")
	assert(is_equal_approx(ModularNatureChunk.get_world_height(0.0, -120.0), 600.0), "Địa hình phía sau Mega Office không được còn đỉnh núi!")
	assert(world.find_child("SummitPillar", true, false) == null, "Không được tạo cột mốc đỉnh núi phía sau Mega Office!")

func _physics_process(delta: float) -> bool:
	if step_index >= waypoints.size():
		print("\n=================================================================")
		print("🎉 HOÀN TẤT: ĐỊA HÌNH PHÍA SAU MEGA OFFICE PHẲNG Ở +600M!")
		print("=================================================================")
		quit(0)
		return false
		
	var pt2d = waypoints[step_index]
	var ground_y = ModularNatureChunk.get_world_height(pt2d.x, pt2d.y)
	assert(is_equal_approx(ground_y, 600.0), "Cao nguyên trung tâm phía sau Mega Office phải bằng phẳng ở +600m!")
	var target_pt = Vector3(pt2d.x, ground_y, pt2d.y)
	var cur_pos = player.global_position
	
	# Đặt nhân vật đứng trên mặt đất tại từng trạm
	var d = cur_pos.distance_to(target_pt)
	if d > 2.0:
		player.global_position = target_pt + Vector3(0, 0.8, 0)
		player.velocity = Vector3.ZERO
		return false
		
	print("[Trạm %d] Tọa độ: (%5.1f, %5.1f, %5.1f) | Độ cao đất: %5.1f m | is_on_floor: %s" % [
		step_index, cur_pos.x, cur_pos.y, cur_pos.z, ground_y, player.is_on_floor()
	])
	
	step_index += 1
	return false
