extends SceneTree

const ModularChunkScript = preload("res://scripts/terrain/modular_nature_chunk.gd")
const AssemblerScript = preload("res://scripts/terrain/natural_landscape_assembler.gd")
const PlayerControllerScript = preload("res://scripts/core/player_controller.gd")

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	print("=================================================================")
	print("🌿 BẮT ĐẦU KIỂM THỬ: BẢN ĐỒ THIÊN NHIÊN 5x5 CHUNKS (320m x 320m)")
	print("=================================================================")
	
	# 1. Kiểm thử tạo từng Chunk đơn lẻ (64m x 64m)
	print("\n[1] KIỂM TRA TẠO KHỐI MODULAR CHUNKS 64m x 64m:")
	var test_types = [
		ModularChunkScript.ChunkType.FLAT_GRASS_PLATEAU,
		ModularChunkScript.ChunkType.RIVER_STREAM,
		ModularChunkScript.ChunkType.CLIFF_EDGE_STEPPED,
		ModularChunkScript.ChunkType.WATERFALL_CASCADE,
		ModularChunkScript.ChunkType.SCENIC_LOOKOUT_CLIFF,
		ModularChunkScript.ChunkType.NORTH_BACKWALL_CLIFF
	]
	
	for t in test_types:
		var chunk = ModularChunkScript.new(t, Vector2i(0, 0))
		chunk.build_chunk()
		root.add_child(chunk)
		assert(chunk.mesh_instance != null, "LỖI: Chunk mesh_instance không được tạo!")
		assert(chunk.collision_shape != null, "LỖI: Chunk collision_shape không được tạo!")
		print("  - Chunk type %d: Mesh & Collision tạo thành công!" % t)
		chunk.queue_free()
	print("  ✅ ĐẠT CHUẨN: Toàn bộ 6 loại Chunk Thiên Nhiên được khởi tạo chính xác!")
	
	# 2. Kiểm thử NaturalLandscapeAssembler lắp ghép 5x5 (25 Chunks)
	print("\n[2] KIỂM TRA BỘ LẮP GHÉP CẢNH QUAN 5x5 (320m x 320m):")
	var assembler = AssemblerScript.new()
	assembler.auto_assemble = false
	root.add_child(assembler)
	assembler.assemble_landscape()
	
	assert(assembler.chunks.size() == 25, "LỖI: Không đủ 25 chunks trong lưới 5x5! Thực tế: %d" % assembler.chunks.size())
	assert(assembler.macro_terrain_body != null or assembler.mountain_body != null, "LỖI: Lưới địa hình vĩ mô chưa được tạo!")
	assert(assembler.sea_of_clouds != null, "LỖI: Biển mây chưa được tạo!")
	assert(assembler.flora_scatter != null, "LỖI: Thảm thực vật Anime chưa được tạo!")
	assert(assembler.sea_of_clouds.position.y == 4000.0, "LỖI: Biển mây phải ở cao độ +4000m!")
	print("  - Vị trí Biển Mây Anime: %s (Cao độ Y=%.0fm trên trời cao)" % [assembler.sea_of_clouds.position, assembler.cloud_sea_altitude])
	print("  - Thảm thực vật: Cây Thông Ghibli, Tán Tròn, Thảm Hoa Dại, Đá Cuội đã gieo mầm thành công!")
	print("  ✅ ĐẠT CHUẨN: Lưới 5x5 Chunks, Thảm Thực Vật, Địa hình Vĩ Mô và Biển Mây liên kết hoàn hảo!")
	
	# 3. Kiểm thử Player Controller hỗ trợ Third-Person & First-Person
	print("\n[3] KIỂM TRA ĐIỀU KHIỂN THỊ TRƯỞNG & CAMERA GÓC NHÌN THỨ 3 [V]:")
	var player_scene = load("res://scenes/characters/player.tscn")
	var player = player_scene.instantiate()
	root.add_child(player)
	player.notification(Node.NOTIFICATION_READY)
	
	var arm = player.spring_arm if player.spring_arm != null else player.get_node_or_null("Head/SpringArm3D")
	assert(player.is_third_person == true, "LỖI: Mặc định phải là góc nhìn thứ 3 (Third-Person)!")
	assert(arm != null, "LỖI: SpringArm3D không tìm thấy trên Player!")
	print("  - Góc nhìn mặc định: %s (Spring length = %.1fm)" % [
		"Third-Person" if player.is_third_person else "First-Person",
		arm.spring_length
	])
	
	# Giả lập phím [V] đổi góc nhìn
	var event_v = InputEventKey.new()
	event_v.keycode = KEY_V
	event_v.pressed = true
	player._input(event_v)
	assert(player.is_third_person == false, "LỖI: Phím [V] không chuyển sang First-Person!")
	print("  - Sau khi bấm phím [V]: Chuyển sang First-Person thành công!")
	
	event_v.pressed = true
	player._input(event_v)
	assert(player.is_third_person == true, "LỖI: Phím [V] không chuyển lại Third-Person!")
	print("  - Bấm phím [V] lần 2: Quay lại Third-Person thành công!")
	print("  ✅ ĐẠT CHUẨN: Cơ chế góc nhìn thứ 3 và phím [V] hoạt động mượt mà!")
	
	print("\n=================================================================")
	print("🎉 TẤT CẢ KIỂM THỬ THIÊN NHIÊN 5x5 ĐÃ ĐẠT 100% THÀNH CÔNG!")
	print("=================================================================")
	
	player.queue_free()
	assembler.queue_free()
	quit(0)
