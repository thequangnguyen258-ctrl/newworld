extends SceneTree

const InteractiveStationScript = preload("res://scripts/interactive/interactive_station.gd")

func _initialize() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var player_scene := load("res://scenes/characters/player.tscn")
	var hud_scene := load("res://scenes/ui/hud_overlay.tscn")
	if player_scene == null or hud_scene == null:
		push_error("[FAIL] Không tải được scene người chơi hoặc HUD.")
		quit(1)
		return

	var world := Node3D.new()
	var ground := StaticBody3D.new()
	var ground_shape := CollisionShape3D.new()
	var ground_box := BoxShape3D.new()
	ground_box.size = Vector3(40.0, 0.2, 40.0)
	ground_shape.shape = ground_box
	ground_shape.position.y = -0.1
	ground.add_child(ground_shape)
	world.add_child(ground)

	var bed = InteractiveStationScript.new()
	bed.station_type = InteractiveStationScript.StationType.BED
	bed.station_id = "daily_rest_test_bed"
	bed.title_name = "Giường Nghỉ Thị Trưởng"
	bed.interaction_radius = 6.0
	world.add_child(bed)
	var desk = InteractiveStationScript.new()
	desk.station_type = InteractiveStationScript.StationType.DESK
	desk.station_id = "desk"
	desk.title_name = "Bàn làm việc"
	desk.interaction_radius = 6.0
	desk.position = Vector3(0.0, 0.0, -12.0)
	world.add_child(desk)
	var player: CharacterBody3D = player_scene.instantiate()
	player.position = Vector3(0.0, 1.0, 10.0)
	world.add_child(player)
	var hud: HUDOverlay = hud_scene.instantiate()
	world.add_child(hud)
	root.add_child(world)

	var world_manager = root.get_node_or_null("WorldManager")
	if world_manager == null:
		push_error("[FAIL] Không tìm thấy WorldManager.")
		quit(1)
		return

	for _frame in range(3):
		await physics_frame
	player.global_position = bed.global_position + Vector3(0.0, 0.0, 2.0)
	for _frame in range(4):
		await physics_frame

	if not bed.prompt_label.visible or player.get_meta("nearby_interactive", null) != bed:
		push_error("[FAIL] Tiếp cận giường phải kích hoạt cảm biến và bảng nhắc.")
		quit(1)
		return

	world_manager.set_time_of_day(14, 0)
	player.current_health = 30.0
	player.current_stamina = 10.0
	var daytime := InputEventKey.new()
	daytime.keycode = KEY_E
	daytime.physical_keycode = KEY_E
	daytime.pressed = true
	player._input(daytime)
	if not hud.is_life_activity_options_open() or not hud.life_activity_buttons.has("bed_lie") or hud.life_activity_buttons.has("bed_sleep"):
		push_error("[FAIL] Ban ngày phải cho nằm nghỉ nhưng không hiện lựa chọn tua đêm.")
		quit(1)
		return
	hud.life_activity_buttons["bed_lie"].pressed.emit()
	if world_manager.current_hour != 14 or player.current_health != 30.0 or player.current_stamina != 10.0 or player.life_activity != "lying":
		push_error("[FAIL] Nằm nghỉ ban ngày phải giữ nguyên giờ và sinh lực.")
		quit(1)
		return
	var wake := InputEventKey.new()
	wake.keycode = KEY_E
	wake.physical_keycode = KEY_E
	wake.pressed = true
	player._input(wake)
	if player.life_activity != "":
		push_error("[FAIL] Nhấn E khi đang nằm phải giúp người chơi đứng dậy.")
		quit(1)
		return

	world_manager.set_time_of_day(22, 30)
	player.current_health = 30.0
	player.current_stamina = 10.0
	player.sprint_exhausted = true
	player.speed_multiplier = 1.4
	player.speed_buff_timer = 10.0
	var night_day_index: int = world_manager.current_day_index
	var night := InputEventKey.new()
	night.keycode = KEY_E
	night.physical_keycode = KEY_E
	night.pressed = true
	player._input(night)
	if not hud.is_life_activity_options_open() or not hud.life_activity_buttons.has("bed_sleep"):
		push_error("[FAIL] Ban đêm phải hiển thị lựa chọn ngủ đến 06:00.")
		quit(1)
		return
	hud.life_activity_buttons["bed_sleep"].pressed.emit()

	if world_manager.current_hour != 6 or world_manager.current_minute != 0:
		push_error("[FAIL] Ngủ ban đêm phải tua thời gian đến 06:00.")
		quit(1)
		return
	if world_manager.current_day_index != (night_day_index + 1) % world_manager.DAY_NAMES.size():
		push_error("[FAIL] Ngủ qua đêm phải chuyển sang ngày kế tiếp.")
		quit(1)
		return
	if player.current_health != player.max_health or player.current_stamina != player.max_stamina:
		push_error("[FAIL] Ngủ qua đêm phải hồi đầy sức khỏe và thể lực.")
		quit(1)
		return
	if player.sprint_exhausted or player.speed_multiplier != 1.0 or player.speed_buff_timer != 0.0:
		push_error("[FAIL] Nghỉ qua đêm phải xóa kiệt sức và hiệu ứng tăng tốc tạm thời.")
		quit(1)
		return
	if player.life_activity != "lying":
		push_error("[FAIL] Sau khi ngủ, nhân vật phải còn nằm trên giường cho đến khi thức dậy.")
		quit(1)
		return
	player._input(wake)
	player.global_position = desk.global_position + Vector3(0.0, 0.0, 2.0)
	for _frame in range(4):
		await physics_frame
	player._input(daytime)
	if not hud.is_life_activity_options_open() or not hud.life_activity_buttons.has("desk_sit"):
		push_error("[FAIL] Bàn làm việc phải cho chọn ngồi làm việc.")
		quit(1)
		return
	hud.life_activity_buttons["desk_sit"].pressed.emit()
	if player.life_activity != "sitting" or player.visual_model.scale.y >= 1.0:
		push_error("[FAIL] Chọn ngồi phải đặt nhân vật vào tư thế ngồi.")
		quit(1)
		return
	player.current_stamina = 10.0
	player.current_focus = 80.0
	for _work_second in range(180):
		player._process(1.0)
	if player.current_stamina <= 10.0 or player.current_focus >= 80.0 or player.completed_desk_sessions != 1:
		push_error("[FAIL] Ngồi làm việc phải hồi nhẹ thể lực, tiêu hao tập trung và ghi nhận phiên làm việc.")
		quit(1)
		return
	player._input(wake)
	if player.life_activity != "":
		push_error("[FAIL] Nhấn E khi đang ngồi phải giúp người chơi đứng dậy.")
		quit(1)
		return

	Input.action_release("interact")
	world.queue_free()
	await process_frame
	print("[PASS] Giường chỉ tua đêm, hồi sức và thể lực, đồng thời kết thúc trạng thái kiệt sức.")
	quit()
