extends SceneTree

# ==============================================================================
# KIỂM THỬ TỰ ĐỘNG: MỞ RỘNG BẢN ĐỒ 500 KM² & CAO NGUYÊN PHƯƠNG NAM BẠT NGÀN
# 1. Xác nhận loại bỏ hoàn toàn vòng núi nhân tạo HorizonMountains 2.2km.
# 2. Xác nhận Lưới Địa Hình Vĩ Mô DistantMacroTerrain (28km x 28km) phủ trọn 500 km².
# 3. Xác nhận phía Nam là thảo nguyên xanh liền mạch +600m, không còn đỉnh núi nhô lên.
# 4. Mô phỏng End-to-End: Lên trực thăng bằng phím [F], bay về Nam ở độ cao +720m với vận tốc Turbo.
# ==============================================================================

var test_frames: int = 0
var test_step: int = 0
var main_world: Node3D = null
var player: PlayerController = null
var helicopter: HelicopterController = null
var macro_terrain: StaticBody3D = null

func _init() -> void:
	print("\n================================================================================")
	print("🌍 KIỂM THỬ: MỞ RỘNG BẢN ĐỒ 500 KM² & GIẢI PHÓNG CAO NGUYÊN PHƯƠNG NAM")
	print("================================================================================")

func _process(delta: float) -> bool:
	test_frames += 1

	if test_step == 0:
		var scene = load("res://scenes/core/main_world.tscn")
		assert(scene != null, "Không thể nạp main_world.tscn")
		main_world = scene.instantiate()
		root.add_child(main_world)
		current_scene = main_world

		player = main_world.get_node("Player") as PlayerController
		helicopter = main_world.get_node("Helicopter") as HelicopterController
		assert(player != null, "Player không tồn tại!")
		assert(helicopter != null, "Helicopter không tồn tại!")

		print("\n[1] KIỂM TRA LOẠI BỎ CÁC RÀO CẢN NHÂN TẠO KHÉP KÍN:")
		var horizon = main_world.find_child("HorizonMountains", true, false)
		assert(horizon == null, "HorizonMountains phải được xóa bỏ hoàn toàn để không chắn phía Nam!")
		print("  ✅ ĐẠT: Không còn vòng núi HorizonMountains (2.2km) che khuất tầm nhìn.")

		var cloud_sea = main_world.find_child("SeaOfClouds", true, false) as MeshInstance3D
		assert(cloud_sea != null and cloud_sea.position.y == 4000.0, "SeaOfClouds phải được nâng lên tầng mây cao +4000m!")
		print("  ✅ ĐẠT: Biển mây Anime đã được nâng lên cao độ +4000m (30km x 30km) trên trời cao.")

		var dir_light = main_world.find_child("DirectionalLight3D", true, false) as DirectionalLight3D
		assert(dir_light != null and dir_light.global_position.y >= 5000.0, "DirectionalLight3D phải ở cao độ +5000m!")
		print("  ✅ ĐẠT: Mặt trời (DirectionalLight3D) đã được nâng lên cao độ +5000m.")

		test_step = 1
		test_frames = 0
		return false

	if test_step == 1:
		if test_frames < 3:
			return false

		print("\n[2] KIỂM TRA LƯỚI ĐỊA HÌNH VĨ MÔ 500 KM² (DISTANT MACRO-TERRAIN):")
		macro_terrain = main_world.find_child("DistantMacroTerrain", true, false) as StaticBody3D
		assert(macro_terrain != null, "DistantMacroTerrain phải tồn tại trong scene!")
		assert(macro_terrain.is_in_group("macro_terrain"), "DistantMacroTerrain phải thuộc group 'macro_terrain'!")

		var mesh_inst = macro_terrain.get_node_or_null("MacroTerrainMesh") as MeshInstance3D
		assert(mesh_inst != null, "MacroTerrainMesh phải có trong DistantMacroTerrain!")
		var aabb = mesh_inst.get_aabb()
		print("  - Kích thước vùng bao phủ địa hình vĩ mô: X=%.0fm, Z=%.0fm (Kỳ vọng >= 26.000m)" % [aabb.size.x, aabb.size.z])
		assert(aabb.size.x >= 26000.0 and aabb.size.z >= 26000.0, "DistantMacroTerrain phải bao trọn tối thiểu 26km x 26km (676 km²)!")
		print("  ✅ ĐẠT: Lưới địa hình vĩ mô phủ trọn đại thế giới 500 km² hoàn chỉnh.")

		test_step = 2
		test_frames = 0
		return false

	if test_step == 2:
		if test_frames < 3:
			return false

		print("\n[3] KIỂM TRA ĐỘ BẰNG PHẲNG & CAO NGUYÊN XANH LIỀN MẠCH PHƯƠNG NAM:")
		# Kiểm tra cao độ dọc trục Z từ 0m đến 12.000m phía Nam
		var test_z_points = [100.0, 300.0, 600.0, 1200.0, 2500.0, 5000.0, 8000.0, 11500.0]
		for z_sample in test_z_points:
			var h = ModularNatureChunk.get_world_height(0.0, z_sample)
			print("  - Tọa độ (0, +%.0fm): Cao độ Y = %.2fm (Kỳ vọng: 594m - 612m, không có đỉnh núi)" % [z_sample, h])
			assert(h >= 594.0 and h <= 612.0, "Cao độ tại Z=%.0f phải là cao nguyên thảo mộc bằng phẳng, không được có đỉnh nhô cao!" % z_sample)

		print("  ✅ ĐẠT: Toàn bộ trục Nam kéo dài 12km là thảo nguyên cao nguyên xanh +600m bạt ngàn.")

		test_step = 3
		test_frames = 0
		return false

	if test_step == 3:
		if test_frames < 3:
			return false

		print("\n[4] KIỂM THỬ END-TO-END: LÊN TRỰC THĂNG VÀ PHI HÀNH SIÊU TỐC VỀ PHƯƠNG NAM:")
		# Đặt player lại sát trực thăng
		player.global_position = helicopter.global_position + Vector3(0.0, 0.0, 2.0)

		# Bấm phím [F] để lên trực thăng
		var ev_f = InputEventKey.new()
		ev_f.keycode = KEY_F
		ev_f.physical_keycode = KEY_F
		ev_f.pressed = true
		player._input(ev_f)

		test_step = 4
		test_frames = 0
		return false

	if test_step == 4:
		if test_frames < 5:
			return false

		assert(helicopter.is_occupied == true, "Thị Trưởng phải lên trực thăng thành công!")
		print("  ✅ Thị Trưởng đã lên trực thăng thành công.")

		# Nâng độ cao lên +720m (vượt 120m so với mặt đất) để quan sát toàn cảnh thảo nguyên
		helicopter.global_position = Vector3(0.0, 720.0, 50.0)

		# Mô phỏng phi hành 4km về phương Nam (Z = +4000m)
		print("  🚀 Bay siêu tốc về phương Nam đến tọa độ Z = +4.000m...")
		helicopter.global_position = Vector3(0.0, 720.0, 4000.0)

		test_step = 5
		test_frames = 0
		return false

	if test_step == 5:
		if test_frames < 5:
			return false

		# Kiểm tra cao độ mặt đất bên dưới trực thăng tại Z=+4000m
		var ground_y = ModularNatureChunk.get_world_height(helicopter.global_position.x, helicopter.global_position.z)
		var clear_altitude = helicopter.global_position.y - ground_y
		print("  - Vị trí trực thăng: (%.1f, %.1f, %.1f) | Mặt đất bên dưới: %.1fm | Độ cao thông thủy: %.1fm" % [
			helicopter.global_position.x, helicopter.global_position.y, helicopter.global_position.z, ground_y, clear_altitude
		])
		assert(clear_altitude > 100.0, "Trực thăng phải có khoảng không gian bay thoáng đãng, không bị đỉnh núi nào chắn!")

		# Tiếp tục bay đến Z = +10.000m
		print("  🚀 Tiếp tục phi hành tới Z = +10.000m trên cao nguyên Nam...")
		helicopter.global_position = Vector3(0.0, 720.0, 10000.0)

		test_step = 6
		test_frames = 0
		return false

	if test_step == 6:
		if test_frames < 5:
			return false

		var ground_y_10k = ModularNatureChunk.get_world_height(helicopter.global_position.x, helicopter.global_position.z)
		var clear_alt_10k = helicopter.global_position.y - ground_y_10k
		print("  - Vị trí trực thăng: (%.1f, %.1f, %.1f) | Mặt đất bên dưới: %.1fm | Độ cao thông thủy: %.1fm" % [
			helicopter.global_position.x, helicopter.global_position.y, helicopter.global_position.z, ground_y_10k, clear_alt_10k
		])
		assert(clear_alt_10k > 100.0, "Không có bất kỳ chướng ngại vật nào tại Z=+10.000m!")

		# Hạ cánh an toàn xuống thảo nguyên và rời trực thăng
		helicopter.global_position.y = ground_y_10k + 0.15
		var ev_exit = InputEventKey.new()
		ev_exit.keycode = KEY_F
		ev_exit.physical_keycode = KEY_F
		ev_exit.pressed = true
		helicopter._unhandled_input(ev_exit)

		test_step = 7
		test_frames = 0
		return false

	if test_step == 7:
		if test_frames < 5:
			return false

		assert(helicopter.is_occupied == false, "Xuống trực thăng an toàn!")
		assert(player.visible == true, "Player hiển thị lại bình thường trên thảo nguyên!")
		print("  ✅ Thị Trưởng đã hạ cánh và rời trực thăng an toàn giữa thảo nguyên phương Nam!")

		print("\n================================================================================")
		print("🎉 TOÀN BỘ KIỂM THỬ MỞ RỘNG BẢN ĐỒ 500 KM² & CAO NGUYÊN NAM ĐÃ ĐẠT 100%!")
		print("================================================================================")
		quit(0)
		return true

	return false
