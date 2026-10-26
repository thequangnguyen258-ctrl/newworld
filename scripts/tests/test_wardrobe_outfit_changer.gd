extends SceneTree

# ==============================================================================
# TEST AUTOMATION: WARDROBE OUTFIT CHANGER (PHÒNG NGỦ MASTER TẦNG 13)
# Tuân thủ nghiêm ngặt:
# - RULE 6: END_TO_END_INTERACTION_TESTING_STANDARD (cảm biến, 3D label, mô phỏng phím vật lý InputEventKey)
# - RULE 7: DUAL_LAYER_SAFETY (Layer 1|2|4, fallback khoảng cách R >= 6.0m)
# - RULE 8: DIEGETIC_UI_PROMPT_VISIBILITY_STANDARD (Billboard, no_depth_test, outline)
# - RULE 1: VIETNAMESE_IME_INPUT_BULLETPROOFING (physical_keycode & keycode song song)
# ==============================================================================

const MainWorldScene = preload("res://scenes/core/main_world.tscn")

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	print("\n================================================================================")
	print("🪞 KIỂM THỬ E2E: TỦ TRANG PHỤC THỊ TRƯỞNG (WARDROBE OUTFIT CHANGER)")
	print("================================================================================")

	var main_world := MainWorldScene.instantiate() as Node3D
	root.add_child(main_world)
	current_scene = main_world
	await process_frame
	await physics_frame

	var player := main_world.get_node("Player") as PlayerController
	var hud := main_world.get_node("HUDOverlay") as HUDOverlay
	var office := main_world.find_child("MayorPrivateOffice", true, false) as Node3D
	var bedroom := office.find_child("MasterBedroom", true, false) if office else null
	var wardrobe := main_world.find_child("WardrobeOutfitChanger", true, false) as Node3D

	if not _check(player != null and hud != null, "MainWorld phải khởi tạo Player và HUD."):
		return
	if not _check(office != null and bedroom != null and wardrobe != null, "Phòng ngủ Master và Tủ trang phục phải tồn tại trong thế giới."):
		return
	if not _check(office.get_parent().name == "Floor_13", "Dinh thự Thị trưởng phải nằm ở Floor_13."):
		return
	if not _check(wardrobe.get_parent() == bedroom, "Tủ trang phục phải nằm bên trong MasterBedroom."):
		return

	# Kiểm tra Quy tắc 7: Dual-Layer Safety & Bán kính tương tác >= 6.0m
	var radius := float(wardrobe.get("interaction_radius"))
	if not _check(radius >= 6.0, "Tủ trang phục phải có bán kính tương tác >= 6.0m (hiện tại: %.1fm)." % radius):
		return

	var area := wardrobe.get("interaction_area") as Area3D
	var prompt := wardrobe.get("prompt_label") as Label3D
	if not _check(area != null and area.collision_layer == (1 | 2 | 4) and area.collision_mask == (1 | 2 | 4), "Cảm biến Area3D phải dùng collision layer/mask = 1|2|4."):
		return

	# Kiểm tra Quy tắc 8: Diegetic UI Label3D
	if not _check(prompt != null and prompt.billboard == BaseMaterial3D.BILLBOARD_ENABLED and prompt.no_depth_test, "Prompt 3D phải bật billboard và no_depth_test xuyên thấu."):
		return

	# 1. Đứng ngoài cự ly tương tác (> 6.0m)
	player.global_position = wardrobe.global_position + Vector3(0.0, 0.0, 10.0)
	for _frame in range(3):
		await physics_frame
	if not _check(not prompt.visible, "Prompt không được hiển thị khi người chơi ở ngoài bán kính tương tác."):
		return

	# 2. Tiến vào cự ly tương tác (< 6.0m)
	player.global_position = wardrobe.global_position + Vector3(0.0, 0.0, 3.0)
	for _frame in range(4):
		await physics_frame
	await create_timer(0.2).timeout

	if not _check(area.overlaps_body(player), "Area3D phải nhận diện Player khi bước vào phạm vi."):
		return
	if not _check(prompt.visible, "Prompt 3D phải tự động bật sáng khi bước vào cự ly."):
		return
	if not _check(player.has_meta("nearby_interactive") and player.get_meta("nearby_interactive") == wardrobe, "Fallback khoảng cách phải đăng ký wardrobe là nearby_interactive."):
		return

	# 3. Mô phỏng phím vật lý [E] mở Wardrobe Modal
	var key_e := InputEventKey.new()
	key_e.keycode = KEY_E
	key_e.physical_keycode = KEY_E
	key_e.pressed = true
	player._input(key_e)
	await process_frame

	var wardrobe_modal := hud.get("wardrobe_modal") as PanelContainer
	if not _check(wardrobe_modal != null and wardrobe_modal.visible, "Nhấn phím vật lý [E] phải mở Modal Tủ Trang Phục."):
		return

	# 4. Đổi sang Đồ Dã Ngoại & Thị Sát Núi Rừng (outdoor)
	var btn_outdoor := hud.find_child("Select_outfit_outdoor", true, false) as Button
	if not _check(btn_outdoor != null, "Giao diện tủ phải có nút Select_outfit_outdoor."):
		return
	btn_outdoor.pressed.emit()
	await process_frame

	if not _check(player.current_outfit == "outdoor", "Trang phục người chơi phải đổi sang 'outdoor'."):
		return
	if not _check(not wardrobe_modal.visible, "Modal tủ trang phục phải tự đóng sau khi chọn đồ."):
		return

	# 5. Mô phỏng phím vật lý [F] tương tác lại để mở Modal và đổi sang Đồ Ngủ Lụa (sleepwear)
	var key_f := InputEventKey.new()
	key_f.keycode = KEY_F
	key_f.physical_keycode = KEY_F
	key_f.pressed = true
	player._input(key_f)
	await process_frame

	if not _check(wardrobe_modal.visible, "Nhấn phím vật lý [F] cũng phải mở Modal Tủ Trang Phục (hỗ trợ đa phím)."):
		return

	var btn_sleepwear := hud.find_child("Select_outfit_sleepwear", true, false) as Button
	if not _check(btn_sleepwear != null, "Giao diện tủ phải có nút Select_outfit_sleepwear."):
		return
	btn_sleepwear.pressed.emit()
	await process_frame

	if not _check(player.current_outfit == "sleepwear", "Trang phục người chơi phải đổi sang 'sleepwear'."):
		return

	# 6. Đổi về Âu Phục Lễ Tân Ngoại Giao (formal)
	wardrobe.interact(player)
	await process_frame
	var btn_formal := hud.find_child("Select_outfit_formal", true, false) as Button
	if not _check(btn_formal != null, "Giao diện tủ phải có nút Select_outfit_formal."):
		return
	btn_formal.pressed.emit()
	await process_frame

	if not _check(player.current_outfit == "formal", "Trang phục người chơi phải đổi về 'formal'."):
		return

	# 7. Kiểm thử tính bền vững Save/Load
	var save_state: Dictionary = player.get_save_state()
	if not _check(save_state.get("current_outfit") == "formal", "Save state phải lưu trữ current_outfit = formal."):
		return

	save_state["current_outfit"] = "outdoor"
	if not _check(player.apply_saved_state(save_state), "Áp dụng saved state có outfit 'outdoor' phải thành công."):
		return
	if not _check(player.current_outfit == "outdoor", "PlayerController phải cập nhật outfit từ file lưu game."):
		return

	# Khôi phục trạng thái chuẩn
	player.set_outfit("formal")

	print("\n🎉 TẤT CẢ CÁC BƯỚC KIỂM THỬ TỦ TRANG PHỤC THỊ TRƯỞNG ĐỀU ĐẠT CHUẨN 100%!")
	quit(0)

func _check(condition: bool, failure_message: String) -> bool:
	if not condition:
		push_error("❌ KIỂM THỬ THẤT BẠI: %s" % failure_message)
		printerr("❌ KIỂM THỬ THẤT BẠI: %s" % failure_message)
		quit(1)
		return false
	return true
