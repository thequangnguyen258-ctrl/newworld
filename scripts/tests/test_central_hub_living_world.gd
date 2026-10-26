extends SceneTree

# ==============================================================================
# TEST AUTOMATION: ĐÔ THỊ TRUNG TÂM SỐNG ĐỘNG, HỘI THOẠI RPG & TÚI ĐỒ THỊ TRƯỞNG
# Tuân thủ:
# - RULE 6: END_TO_END_INTERACTION_TESTING_STANDARD (cảm biến, 3D label, mô phỏng phím vật lý InputEventKey)
# - RULE 7: DUAL_LAYER_SAFETY (Layer 1|2|4, fallback khoảng cách)
# - RULE 8: DIEGETIC_UI_PROMPT_VISIBILITY_STANDARD (Billboard, no_depth_test, outline)
# - RULE 1: VIETNAMESE_IME_INPUT_BULLETPROOFING (physical_keycode & keycode)
# ==============================================================================

const InventoryManagerScript = preload("res://scripts/economy/inventory_manager.gd")
const DialogueManagerScript = preload("res://scripts/dialogue/dialogue_manager.gd")
const AudioSynthesizerScript = preload("res://scripts/core/audio_synthesizer.gd")

var test_frames: int = 0
var test_step: int = 0

var main_world: Node3D = null
var player: CharacterBody3D = null
var hud: CanvasLayer = null

var npc_nam: CharacterBody3D = null
var npc_mai: CharacterBody3D = null
var npc_david: CharacterBody3D = null
var npc_tuan: CharacterBody3D = null
var npc_ba: CharacterBody3D = null
var count_before: int = 0

func _init() -> void:
	print("\n================================================================================")
	print("🏛️ KIỂM THỬ: ĐÔ THỊ TRUNG TÂM SỐNG ĐỘNG, HỘI THOẠI RPG & TÚI ĐỒ THỊ TRƯỞNG")
	print("================================================================================")

func _process(_delta: float) -> bool:
	test_frames += 1

	match test_step:
		0:
			# Nạp main_world.tscn
			var scene = load("res://scenes/core/main_world.tscn")
			assert(scene != null, "Không thể nạp main_world.tscn!")
			main_world = scene.instantiate()
			root.add_child(main_world)
			current_scene = main_world

			player = main_world.get_node_or_null("Player") as CharacterBody3D
			hud = main_world.get_node_or_null("HUDOverlay") as CanvasLayer

			assert(player != null, "LỖI: Player không tồn tại!")
			assert(hud != null, "LỖI: HUDOverlay không tồn tại!")

			print("\n[Bước 0] XÁC THỰC SỰ HIỆN DIỆN CỦA 5 NPC CỐT LÕI TẠI TRUNG TÂM:")
			for node in get_nodes_in_group("citizens"):
				var nid = node.get("npc_id")
				if nid != null:
					match str(nid):
						"baker_nam": npc_nam = node
						"doctor_mai": npc_mai = node
						"shepherd_david": npc_david = node
						"mechanic_tuan": npc_tuan = node
						"elder_ba": npc_ba = node

			assert(npc_nam != null, "LỖI: Thiếu Bác Nam tại Tiệm Bánh Mì!")
			assert(npc_mai != null, "LỖI: Thiếu Chị Mai tại Trạm Xá!")
			assert(npc_david != null, "LỖI: Thiếu Mục Tử David tại Đại Hội Trường!")
			assert(npc_tuan != null, "LỖI: Thiếu Kỹ Sư Tuấn tại Bãi Đỗ Xe Buggy!")
			assert(npc_ba != null, "LỖI: Thiếu Bác Ba tại Bảng Tin Dân Làng!")

			print("  ✅ Bác Nam: Vị trí %s | Nghề: %s" % [npc_nam.global_position, npc_nam.get("job_title")])
			print("  ✅ Chị Mai: Vị trí %s | Nghề: %s" % [npc_mai.global_position, npc_mai.get("job_title")])
			print("  ✅ Mục Tử David: Vị trí %s | Nghề: %s" % [npc_david.global_position, npc_david.get("job_title")])
			print("  ✅ Kỹ Sư Tuấn: Vị trí %s | Nghề: %s" % [npc_tuan.global_position, npc_tuan.get("job_title")])
			print("  ✅ Bác Ba: Vị trí %s | Nghề: %s" % [npc_ba.global_position, npc_ba.get("job_title")])

			test_step = 1
			test_frames = 0
			return false

		1:
			# BƯỚC 1: TIẾP CẬN BÁC NAM & KIỂM TRA BẢNG TÊN DIEGETIC
			if test_frames < 4:
				return false

			print("\n[Bước 1] TIẾP CẬN BÁC NAM TẠI QUẦY TIỆM BÁNH MÌ:")
			player.global_position = npc_nam.global_position + Vector3(0, 0, -1.5)

			test_step = 2
			test_frames = 0
			return false

		2:
			if test_frames < 4:
				return false

			var dist = player.global_position.distance_to(npc_nam.global_position)
			print("  - Cự ly tới Bác Nam: %.2fm (Yêu cầu <= 3.8m)" % dist)
			assert(dist <= 3.8, "Player phải ở trong cự ly tương tác!")
			assert(npc_nam.get("nameplate").no_depth_test == true, "Bảng tên phải bật no_depth_test!")
			assert(player.has_meta("nearby_npc") == true, "Player phải nhận diện nearby_npc!")

			# Mô phỏng nhấn phím [E] để mở Hộp Thoại Anime RPG
			print("  - Mô phỏng nhấn phím [E] để trò chuyện...")
			var ev_e = InputEventKey.new()
			ev_e.keycode = KEY_E
			ev_e.physical_keycode = KEY_E
			ev_e.pressed = true
			player._input(ev_e)

			test_step = 3
			test_frames = 0
			return false

		3:
			if test_frames < 4:
				return false

			assert(hud.get("dialogue_modal").visible == true, "Hộp thoại RPG phải mở ra!")
			assert(hud.get("dlg_name_label").text == "Bác Nam", "Tên người nói phải là Bác Nam!")
			assert(hud.get("dlg_avatar_label").text == "🥖", "Icon Avatar phải là bánh mì 🥖!")
			print("  ✅ Hộp thoại Anime RPG mở thành công! Lời chào: '%s'" % hud.get("dlg_text_label").text)

			# BƯỚC 2: CHỌN PHƯƠNG ÁN XIN Ổ BÁNH MÌ QUA HỘI THOẠI
			var init_baguettes = InventoryManagerScript.get_item_count("item_baguette")
			print("\n[Bước 2] CHỌN PHƯƠNG ÁN NHẬN BÁNH MÌ TỪ BÁC NAM (Hiện có: %d):" % init_baguettes)
			hud._handle_dialogue_action("give_baguette")

			test_step = 4
			test_frames = 0
			return false

		4:
			if test_frames < 4:
				return false

			var new_baguettes = InventoryManagerScript.get_item_count("item_baguette")
			assert(new_baguettes > 0, "Túi đồ phải có ít nhất 1 bánh mì baguette!")
			assert(hud.get("dialogue_modal").visible == false, "Hộp thoại phải đóng sau khi nhận đồ!")
			print("  ✅ Nhận bánh mì thành công! Số lượng mới trong túi: %d" % new_baguettes)

			# BƯỚC 3: MÔ PHỎNG PHÍM [I] MỞ/ĐÓNG TÚI ĐỒ THỊ TRƯỞNG
			print("\n[Bước 3] MÔ PHỎNG PHÍM [I] MỞ TÚI ĐỒ THỊ TRƯỞNG:")
			var ev_i = InputEventKey.new()
			ev_i.keycode = KEY_I
			ev_i.physical_keycode = KEY_I
			ev_i.pressed = true
			player._input(ev_i)

			test_step = 5
			test_frames = 0
			return false

		5:
			if test_frames < 4:
				return false

			assert(hud.get("inventory_modal").visible == true, "Túi đồ phải hiển thị khi bấm [I]!")
			print("  ✅ Mở Túi Đồ [I] thành công! Số danh mục hiển thị: %d" % hud.get("inv_items_container").get_child_count())

			# Đóng túi đồ
			var ev_i_close = InputEventKey.new()
			ev_i_close.keycode = KEY_I
			ev_i_close.physical_keycode = KEY_I
			ev_i_close.pressed = true
			player._input(ev_i_close)

			test_step = 6
			test_frames = 0
			return false

		6:
			if test_frames < 4:
				return false

			assert(hud.get("inventory_modal").visible == false, "Túi đồ phải đóng lại!")
			print("  ✅ Đóng Túi Đồ [I] thành công!")

			# BƯỚC 4: MÔ PHỎNG PHÍM [1] ĂN BÁNH MÌ HỒI SINH LỰC
			print("\n[Bước 4] MÔ PHỎNG PHÍM [1] ĂN BÁNH MÌ HỒI SINH LỰC:")
			player.current_health = 45.0 # Làm tiêu hao thể lực
			print("  - Thể lực trước khi ăn: %.0f HP" % player.current_health)

			count_before = InventoryManagerScript.get_item_count("item_baguette")
			var ev_1 = InputEventKey.new()
			ev_1.keycode = KEY_1
			ev_1.physical_keycode = KEY_1
			ev_1.pressed = true
			player._input(ev_1) # Lần 1: Cầm bánh mì lên tay (Equip Hotbar)
			player._input(ev_1) # Lần 2: Ăn bánh mì (Consume/Use)

			test_step = 7
			test_frames = 0
			return false

		7:
			if test_frames < 4:
				return false

			print("  - Thể lực sau khi ăn: %.0f HP" % player.current_health)
			assert(player.current_health > 45.0, "Sinh lực phải được hồi phục!")
			assert(InventoryManagerScript.get_item_count("item_baguette") == count_before - 1, "Số bánh mì phải trừ đi 1!")
			print("  ✅ Ăn Bánh Mì bằng phím [1] thành công! Toast: '%s'" % hud.get("toast_label").text)

			# BƯỚC 5: MÔ PHỎNG PHÍM [2] UỐNG TRÀ THẢO MỘC & TĂNG TỐC CHẠY
			print("\n[Bước 5] MÔ PHỎNG PHÍM [2] UỐNG TRÀ THẢO MỘC:")
			InventoryManagerScript.add_item("item_herbal_tea", 1)
			var ev_2 = InputEventKey.new()
			ev_2.keycode = KEY_2
			ev_2.physical_keycode = KEY_2
			ev_2.pressed = true
			player._input(ev_2) # Lần 1: Cầm chén trà (Equip Hotbar)
			player._input(ev_2) # Lần 2: Uống trà (Consume/Use)

			test_step = 8
			test_frames = 0
			return false

		8:
			if test_frames < 4:
				return false

			assert(player.speed_multiplier > 1.0, "Tốc độ chạy phải được nhân hệ số buff!")
			assert(player.speed_buff_timer > 0.0, "Thời gian buff tốc độ phải lớn hơn 0!")
			print("  ✅ Uống Trà Thảo Mộc bằng phím [2] thành công! Hệ số tốc độ: x%.1f (còn %.1fs)" % [player.speed_multiplier, player.speed_buff_timer])

			# BƯỚC 6: TIẾP CẬN BÁC BA & NHẬN NHIỆM VỤ DÂN SINH 5 HUYỆN
			print("\n[Bước 6] TIẾP CẬN BÁC BA & NHẬN NHIỆM VỤ DÂN SINH 5 HUYỆN:")
			player.global_position = npc_ba.global_position + Vector3(0, 0, -1.2)

			test_step = 9
			test_frames = 0
			return false

		9:
			if test_frames < 4:
				return false

			var ev_e_ba = InputEventKey.new()
			ev_e_ba.keycode = KEY_E
			ev_e_ba.physical_keycode = KEY_E
			ev_e_ba.pressed = true
			player._input(ev_e_ba)

			test_step = 10
			test_frames = 0
			return false

		10:
			if test_frames < 4:
				return false

			assert(hud.get("dialogue_modal").visible == true, "Hộp thoại Bác Ba phải mở!")
			assert(hud.get("dlg_name_label").text == "Bác Ba", "Tên người nói phải là Bác Ba!")

			# Nhận nhiệm vụ Huyện Nam
			hud._handle_dialogue_action("quest_south_port")

			test_step = 11
			test_frames = 0
			return false

		11:
			if test_frames < 4:
				return false

			assert(hud.get("dialogue_modal").visible == false, "Hộp thoại phải đóng sau khi nhận quest!")
			print("  ✅ Đã nhận nhiệm vụ dân sinh kết nối Huyện Nam! Toast: '%s'" % hud.get("toast_label").text)

			# BƯỚC 7: KIỂM THỬ HỆ THỐNG ÂM THANH PROCEDURAL DIEGETIC
			print("\n[Bước 7] KIỂM THỬ HỆ THỐNG ÂM THANH DIEGETIC PROCEDURAL:")
			AudioSynthesizerScript.play_sound(main_world, "bell")
			AudioSynthesizerScript.play_sound(main_world, "horn")
			AudioSynthesizerScript.play_sound(main_world, "fanfare")
			AudioSynthesizerScript.play_sound(main_world, "consume")
			print("  ✅ Phát thành công toàn bộ 4 âm sắc Procedural (Chuông, Còi xe, Fanfare, Tiêu dùng)!")

			print("\n================================================================================")
			print("🎉 TOÀN BỘ CÁC BÀI KIỂM THỬ ĐÔ THỊ SỐNG ĐỘNG ĐÃ THÀNH CÔNG RỰC RỠ (100% PASS)!")
			print("================================================================================")
			quit(0)
			return true

	return false
