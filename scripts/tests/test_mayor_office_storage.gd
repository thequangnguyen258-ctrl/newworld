extends SceneTree

const InventoryManagerScript = preload("res://scripts/economy/inventory_manager.gd")
const MainWorldScene = preload("res://scenes/core/main_world.tscn")

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var initial_inventory: Dictionary = InventoryManagerScript.get_save_state()
	var main_world := MainWorldScene.instantiate() as Node3D
	root.add_child(main_world)
	current_scene = main_world
	await process_frame
	await physics_frame

	var player := main_world.get_node("Player") as PlayerController
	var hud := main_world.get_node("HUDOverlay") as HUDOverlay
	var office := main_world.find_child("MayorPrivateOffice", true, false) as Node3D
	var storage := main_world.find_child("MayorOfficeStorage", true, false) as Node3D
	if not _check(player != null and hud != null, "MainWorld phải khởi tạo Player và HUD."):
		return
	if not _check(office != null and storage != null, "Văn phòng và kho riêng Thị trưởng phải có trong thế giới."):
		return
	if not _check(office.get_parent().name == "Floor_13", "Văn phòng riêng Thị trưởng phải nằm trên tầng 13."):
		return
	if not _check(is_equal_approx(float(office.get_meta("floor_area_square_meters")), 600.0), "Dinh thự Thị trưởng phải có diện tích 600 m²."):
		return
	var office_floor := office.get_node("OfficeFloor") as MeshInstance3D
	var office_floor_mesh := office_floor.mesh as BoxMesh
	var actual_floor_size: Vector3 = office_floor_mesh.size * office_floor.global_transform.basis.get_scale()
	if not _check(is_equal_approx(actual_floor_size.x, 30.0) and is_equal_approx(actual_floor_size.z, 20.0), "Sàn dinh thự phải có kích thước thực 30 × 20 m."):
		return
	if not _check(int(office.get_meta("floor_number")) == 13, "Metadata dinh thự phải ghi tầng 13."):
		return

	var living_lounge := office.find_child("LivingLounge", true, false)
	var exec_office := office.find_child("ExecutiveOffice", true, false)
	var kitchen := office.find_child("KitchenArea", true, false)
	var bedroom := office.find_child("MasterBedroom", true, false)
	var bathroom := office.find_child("BathroomArea", true, false)
	var vault := office.find_child("PrivateVault", true, false)
	var bed_station := office.find_child("BedStation", true, false)
	if not _check(living_lounge != null and exec_office != null and kitchen != null and bedroom != null and bathroom != null and vault != null, "Dinh thự 600m² phải có đủ 6 phòng: Khách, Văn phòng, Bếp, Ngủ, Tắm, Kho."):
		return
	if not _check(bed_station != null and int(bed_station.get("station_type")) == int(InteractiveStation.StationType.BED), "Phòng ngủ Master phải có trạm giường ngủ Night Skip."):
		return

	if not _check(is_equal_approx(float(storage.get("interaction_radius")), 6.0), "Kho phải có fallback tương tác bán kính tối thiểu 6 m."):
		return

	var area := storage.get("interaction_area") as Area3D
	var prompt := storage.get("prompt_label") as Label3D
	if not _check(area != null and area.collision_layer == (1 | 2 | 4) and area.collision_mask == (1 | 2 | 4), "Cảm biến kho phải dùng collision layer/mask 1|2|4."):
		return
	if not _check(prompt != null and prompt.billboard == BaseMaterial3D.BILLBOARD_ENABLED and prompt.no_depth_test, "Nhắc lệnh kho phải luôn hiển thị trong thế giới."):
		return

	if not _check(InventoryManagerScript.apply_saved_state({
		"briefcase": {"item_baguette": 1},
		"office_storage": {}
	}), "Thiết lập inventory kiểm thử phải hợp lệ."):
		return

	player.global_position = storage.global_position + Vector3(0.0, 0.0, 8.0)
	for _frame in range(3):
		await physics_frame
	player.global_position = storage.global_position + Vector3(0.0, 0.0, 5.0)
	for _frame in range(4):
		await physics_frame
	await create_timer(0.2).timeout
	if not _check(area.overlaps_body(player), "Area3D của kho phải nhận diện Player sau khi bước vào vùng."):
		return
	if not _check(prompt.visible, "Prompt 3D phải hiện khi Player ở trong cự ly."):
		return
	if not _check(player.has_meta("nearby_interactive") and player.get_meta("nearby_interactive") == storage, "Fallback khoảng cách phải đăng ký kho gần nhất."):
		return

	var interact_event := InputEventKey.new()
	interact_event.keycode = KEY_E
	interact_event.physical_keycode = KEY_E
	interact_event.pressed = true
	player._input(interact_event)
	await process_frame
	if not _check(hud.get("office_storage_modal").visible, "Phím vật lý E phải mở giao diện kho."):
		return

	var store_button := hud.find_child("Store_item_baguette", true, false) as Button
	if not _check(store_button != null, "Giao diện phải hiển thị nút cất bánh mì."):
		return
	store_button.pressed.emit()
	await create_timer(1.0).timeout
	if not _check(InventoryManagerScript.get_item_count("item_baguette") == 0, "Cất đồ phải trừ vật phẩm khỏi cặp sau hoạt ảnh."):
		return
	if not _check(InventoryManagerScript.get_storage_item_count("item_baguette") == 1, "Cất đồ phải đưa vật phẩm vào kho."):
		return

	await process_frame
	var take_button := hud.find_child("Take_item_baguette", true, false) as Button
	if not _check(take_button != null, "Giao diện phải hiển thị nút lấy bánh mì khỏi kho."):
		return
	take_button.pressed.emit()
	await create_timer(1.0).timeout
	if not _check(InventoryManagerScript.get_item_count("item_baguette") == 1, "Lấy đồ phải đưa vật phẩm trở lại cặp sau hoạt ảnh."):
		return
	if not _check(InventoryManagerScript.get_storage_item_count("item_baguette") == 0, "Lấy đồ phải trừ vật phẩm khỏi kho."):
		return

	hud.close_mayor_office_storage_modal()
	var alternate_interact_event := InputEventKey.new()
	alternate_interact_event.keycode = KEY_F
	alternate_interact_event.physical_keycode = KEY_F
	alternate_interact_event.pressed = true
	player._input(alternate_interact_event)
	await process_frame
	if not _check(hud.get("office_storage_modal").visible, "Phím vật lý F cũng phải mở được kho."):
		return

	hud.close_mayor_office_storage_modal()
	if not _check(InventoryManagerScript.apply_saved_state({
		"briefcase": {"item_solar_battery": 2},
		"office_storage": {}
	}), "Thiết lập túi đầy kiểm thử phải hợp lệ."):
		return
	if not _check(
		not InventoryManagerScript.can_add_item("item_wheat_sack", 1)
		and not InventoryManagerScript.add_item("item_wheat_sack", 1)
		and InventoryManagerScript.get_item_count("item_wheat_sack") == 0,
		"Vật phẩm không được nhận nếu vượt giới hạn tải của cặp."
	):
		return
	InventoryManagerScript.apply_saved_state(initial_inventory)
	main_world.queue_free()
	await process_frame
	print("[PASS] Văn phòng tầng 13, cảm biến, prompt, E/F và chuyển đồ qua hoạt ảnh.")
	quit(0)

func _check(condition: bool, failure_message: String) -> bool:
	if condition:
		return true
	push_error(failure_message)
	quit(1)
	return false
