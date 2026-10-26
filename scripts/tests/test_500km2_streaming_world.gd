extends SceneTree

var world: Node
var player: CharacterBody3D
var streamer: WorldChunkStreamer
var hud: HUDOverlay
var test_step: int = 0
var test_frames: int = 0
var test_done: bool = false

var test_destinations = [
	{
		"name": "🏛️ Đỉnh Núi Trung Tâm (Spawn Area)",
		"pos": Vector3(16.0, 600.0, 10.0),
		"expected_min_y": 595.0,
		"expected_max_y": 605.0
	},
	{
		"name": "🌿 Cao nguyên phía sau Mega Office",
		"pos": Vector3(0.0, 600.0, -120.0),
		"expected_min_y": 598.0,
		"expected_max_y": 602.0
	},
	{
		"name": "🌊 Hồ Đỉnh Cao Nguyên (-2km, -3km)",
		"pos": Vector3(-2000.0, 535.0, -3000.0),
		"expected_min_y": 530.0,
		"expected_max_y": 550.0
	},
	{
		"name": "🌾 Huyện Đông Nông Trại (+10km)",
		"pos": Vector3(10000.0, 35.0, 0.0),
		"expected_min_y": 25.0,
		"expected_max_y": 45.0
	},
	{
		"name": "🌿 Đồng Cỏ Cao Nguyên Nam (+12km)",
		"pos": Vector3(0.0, 600.0, 12000.0),
		"expected_min_y": 580.0,
		"expected_max_y": 615.0
	},
	{
		"name": "🌿 Thảo Nguyên Nam (+13km)",
		"pos": Vector3(0.0, 600.0, 13000.0),
		"expected_min_y": 580.0,
		"expected_max_y": 615.0
	},
	{
		"name": "⚓ Huyện Nam Cảng Hòa Bình (+20km)",
		"pos": Vector3(0.0, 15.0, 20000.0),
		"expected_min_y": 10.0,
		"expected_max_y": 30.0
	}
]

func _initialize() -> void:
	print("=================================================================")
	print("🌍 BẮT ĐẦU KIỂM THỬ: ĐẠI THẾ GIỚI MỞ 500 KM² & DYNAMIC STREAMING")
	print("=================================================================")
	
	var scn = load("res://scenes/core/main_world.tscn")
	assert(scn != null, "Không load được main_world.tscn")
	world = scn.instantiate()
	root.add_child(world)
	player = world.get_node("Player")
	hud = world.get_node("HUDOverlay")
	
	var landscape = world.get_node("NaturalLandscape")
	streamer = landscape.get_node_or_null("WorldChunkStreamer")

func _physics_process(delta: float) -> bool:
	if test_done:
		return true
		
	test_frames += 1
	if test_frames < 4:
		return false
		
	if test_step < test_destinations.size():
		var dest = test_destinations[test_step]
		var target_pos = dest["pos"]
		var ground_h = ModularNatureChunk.get_world_height(target_pos.x, target_pos.z)
		
		# Đặt người chơi đến địa danh mới
		player.global_position = Vector3(target_pos.x, ground_h + 1.2, target_pos.z)
		player.velocity = Vector3.ZERO
		
		# Cho WorldChunkStreamer cập nhật lưới địa hình tại tọa độ mới
		if streamer:
			streamer.force_refresh_at_position(player.global_position)
			var loaded_count = streamer.loaded_chunks.size()
			assert(loaded_count > 0, "Lưới chunk phải có các ô địa hình hoạt động!")
			print("  📍 [Trạm %d] %s: Tọa độ (%.0f, %.0f, %.0f) | Độ cao đất: %.1fm | Số chunk nạp: %d" % [
				test_step + 1, dest["name"], player.global_position.x, player.global_position.y, player.global_position.z,
				ground_h, loaded_count
			])
			
		assert(ground_h >= dest["expected_min_y"] - 15.0 and ground_h <= dest["expected_max_y"] + 15.0,
			"Độ cao đất không nằm trong khoảng dự kiến tại %s!" % dest["name"])
			
		test_step += 1
		test_frames = 0
		return false
		
	# --- KIỂM THỬ TABLET BẢN ĐỒ TOÀN CẢNH (MACRO MAP MODAL) ---
	print("\n--- KIỂM TRA TABLET BẢN ĐỒ [M] & DU HÀNH NHANH (FAST TRAVEL) ---")
	var map_modal = hud.macro_map_modal as MacroMapModal
	assert(map_modal != null, "MacroMapModal phải có trong HUDOverlay!")
	assert(map_modal.visible == false, "Bản đồ ban đầu phải ẩn")
	
	hud.open_macro_map()
	assert(map_modal.visible == true, "Bản đồ phải hiển thị sau khi mở")
	assert(map_modal.poi_catalog.size() == 10, "Phải có đầy đủ 10 POIs theo đúng Concept!")
	print("  ✅ Tablet hiển thị danh bạ 10 Địa danh (POIs) cốt lõi thành công.")
	
	# Thử nghiệm Fast Travel đến Hồ Đỉnh Cao Nguyên (Index = 2)
	map_modal.selected_poi_index = 2
	map_modal._on_travel_pressed()
	
	assert(map_modal.visible == false, "Bản đồ phải đóng sau khi Fast Travel")
	var new_dist_to_lake = player.global_position.distance_to(Vector3(-2000.0, 590.0, -3000.0))
	print("  🚀 Du hành nhanh đến Hồ Đỉnh Cao Nguyên: Khoảng cách tới tâm hồ = %.1fm (Kỳ vọng < 100m)" % new_dist_to_lake)
	assert(new_dist_to_lake < 100.0, "Vị trí Player sau Fast Travel phải nằm sát tâm hồ!")
	
	print("\n=================================================================")
	print("🎉 TOÀN BỘ KIỂM THỬ THẾ GIỚI MỞ 500 KM² & FAST TRAVEL ĐÃ ĐẠT 100%!")
	print("=================================================================")
	test_done = true
	quit(0)
	return true
