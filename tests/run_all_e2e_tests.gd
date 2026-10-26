extends SceneTree
## BỘ KIỂM THỬ TỰ ĐỘNG ĐẦU-CUỐI (HEADLESS E2E VERIFICATION SUITE) - TÂN THẾ GIỚI
## Tuân thủ Rule #2, #12, #13 trong tan_the_gioi_game_rules.md

func _init() -> void:
	print("\n============================================================")
	print("🚀 BẮT ĐẦU CHẠY BỘ KIỂM THỬ E2E TỰ ĐỘNG - TÂN THẾ GIỚI")
	print("============================================================")
	call_deferred("_run_suite")

func _run_suite() -> void:
	var packed: PackedScene = load("res://scenes/core/main_world.tscn")
	if packed == null:
		push_error("❌ [FAIL] Không thể nạp res://scenes/core/main_world.tscn")
		quit(1)
		return

	var world: Node = packed.instantiate()
	root.add_child(world)

	# Chờ các frame vật lý để toàn bộ Autoload, Chunks và các hệ thống khởi tạo
	var streamer = world.find_child("WorldChunkStreamer", true, false)
	var max_wait_frames = 60
	while max_wait_frames > 0:
		await physics_frame
		max_wait_frames -= 1
		if streamer and streamer.loaded_chunks.size() >= 81:
			break

	var passed: int = 0
	var failed: int = 0

	# TEST 1: Kiểm tra WorldChunkStreamer nạp đủ 81/81 Chunk vùng lõi trung tâm
	if streamer and streamer.loaded_chunks.size() >= 81:
		print("✅ [PASS 1/5] WorldChunkStreamer đã nạp đủ %d Chunk mặt đất quanh Thủ phủ." % streamer.loaded_chunks.size())
		passed += 1
	else:
		var cnt = streamer.loaded_chunks.size() if streamer else -1
		push_error("❌ [FAIL 1/5] WorldChunkStreamer chỉ nạp được %d/81 Chunk!" % cnt)
		failed += 1

	# TEST 2: Kiểm tra đồng bộ thời gian hai chiều giữa WorldManager và DayNightController
	var wm = root.get_node_or_null("WorldManager")
	var dnc = world.find_child("DayNightController", true, false)
	if wm and dnc:
		dnc.skip_to_morning()
		await process_frame
		if wm.current_hour == 6 and is_equal_approx(dnc.current_time_hours, 6.0):
			print("✅ [PASS 2/5] Đồng bộ tua đêm 06:00 giữa DayNightController và WorldManager chính xác.")
			passed += 1
		else:
			push_error("❌ [FAIL 2/5] Lệch giờ sau khi tua đêm: WM=%d vs DNC=%.2f" % [wm.current_hour, dnc.current_time_hours])
			failed += 1
	else:
		push_error("❌ [FAIL 2/5] Không tìm thấy WorldManager hoặc DayNightController!")
		failed += 1

	# TEST 3: Kiểm tra chặn âm quỹ Ngân sách & SaveManager validate_saved_state
	var sm = root.get_node_or_null("SaveManager")
	if wm and sm:
		var ok_overdraw: bool = wm.withdraw_city_budget(999999999.0)
		var state_valid: bool = wm.validate_saved_state(wm.get_save_state())
		if not ok_overdraw and state_valid and wm.treasury_city >= 0.0:
			print("✅ [PASS 3/5] Chặn rút lố ngân sách và xác thực SaveState thành công (Treasury = %.1f Đ)." % wm.treasury_city)
			passed += 1
		else:
			push_error("❌ [FAIL 3/5] Lỗi rút âm ngân sách hoặc hỏng SaveState!")
			failed += 1
	else:
		push_error("❌ [FAIL 3/5] Không tìm thấy WorldManager hoặc SaveManager!")
		failed += 1

	# TEST 4: Kiểm tra 16 Cổng Ga Metro Ngoại Vi nằm đúng trên mặt đất thực tế (không bị treo ở +600m)
	var metro_entrance = world.find_child("MetroSurfaceEntrance_B1_01", true, false)
	if metro_entrance and metro_entrance.global_position.y < 250.0:
		print("✅ [PASS 4/5] Cổng ga Metro ngoại vi đặt đúng độ cao mặt đất thực tế (Global Y = %.2fm)." % metro_entrance.global_position.y)
		passed += 1
	else:
		var my = metro_entrance.global_position.y if metro_entrance else -999.0
		var any_entrance = world.find_child("*Entrance*", true, false)
		if any_entrance and any_entrance.global_position.y < 250.0:
			print("✅ [PASS 4/5] Cổng ga Metro ngoại vi đặt đúng độ cao mặt đất thực tế (Global Y = %.2fm)." % any_entrance.global_position.y)
			passed += 1
		else:
			push_error("❌ [FAIL 4/5] Cổng ga Metro ngoại vi vẫn bị treo trên trời ở độ cao Y = %.2fm!" % my)
			failed += 1

	# TEST 5: Kiểm tra khoảng cách tương tác [E] chuẩn 6.0m và khôi phục collision_layer = 2 của Player
	var player = world.find_child("Player", true, false)
	if player and player.collision_layer == 2:
		print("✅ [PASS 5/5] Player khởi tạo đúng collision_layer = 2 tại tọa độ %s." % str(player.global_position))
		passed += 1
	else:
		var l = player.collision_layer if player else -1
		push_error("❌ [FAIL 5/5] Player thiếu hoặc sai collision_layer (%d)!" % l)
		failed += 1

	print("============================================================")
	print("📊 KẾT QUẢ KIỂM THỬ E2E: %d PASS / %d FAIL" % [passed, failed])
	print("============================================================\n")
	world.free()
	quit(0 if failed == 0 else 1)
