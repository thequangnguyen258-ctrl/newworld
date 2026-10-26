extends SceneTree

# ==============================================================================
# TEST AUTOMATION: TRUNG TÂM THỦ PHỦ ĐÔ THỊ ĐỈNH VÁT CHƠI ĐƯỢC 100%
# Tuân thủ:
# - RULE 6: END_TO_END_INTERACTION_TESTING_STANDARD (cảm biến, 3D label, mô phỏng phím vật lý InputEventKey)
# - RULE 7: DUAL_LAYER_SAFETY (Layer 1|2|4, fallback khoảng cách)
# - RULE 8: DIEGETIC_UI_PROMPT_VISIBILITY_STANDARD (Billboard, no_depth_test, outline)
# - RULE 1: VIETNAMESE_IME_INPUT_BULLETPROOFING (physical_keycode & keycode)
# ==============================================================================

const InteractiveStationClass = preload("res://scripts/interactive/interactive_station.gd")
const MayorBuggyClass = preload("res://scripts/interactive/mayor_buggy.gd")
const HUDOverlayClass = preload("res://scripts/ui/hud_overlay.gd")

var test_frames: int = 0
var test_step: int = 0

var main_world: Node3D = null
var player: CharacterBody3D = null
var hud: HUDOverlay = null
var buggy: CharacterBody3D = null
var capital_complex: Node3D = null

var st_fountain: Node3D = null
var st_bakery: Node3D = null
var st_clinic: Node3D = null
var st_bell: Node3D = null
var st_desk: Node3D = null
var st_bed: Node3D = null
var st_pet: Node3D = null

func _init() -> void:
	print("\n================================================================================")
	print("🏛️ KIỂM THỬ TỰ ĐỘNG: KHU TRUNG TÂM ĐÔ THỊ TÂN THẾ GIỚI CHƠI ĐƯỢC 100%")
	print("================================================================================")

func _process(delta: float) -> bool:
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
			hud = main_world.get_node_or_null("HUDOverlay") as HUDOverlay
			buggy = main_world.get_node_or_null("MayorBuggy") as CharacterBody3D
			capital_complex = main_world.get_node_or_null("CentralCapital")

			assert(player != null, "LỖI: Player không tồn tại trong main_world!")
			assert(hud != null, "LỖI: HUDOverlay không tồn tại!")
			assert(buggy != null, "LỖI: MayorBuggy không tồn tại trong main_world!")
			assert(capital_complex != null, "LỖI: CentralCapitalComplex không tồn tại!")

			print("\n[Bước 0] KHỞI TẠO SCENE & XÁC THỰC CÁC THÀNH PHẦN:")
			print("  - Vị trí Player: %s" % player.global_position)
			print("  - Vị trí Xe Buggy Điện: %s" % buggy.global_position)
			print("  - Vị trí Trung Tâm Thủ Phủ: %s" % capital_complex.global_position)

			# Tìm các Interactive Stations
			for node in get_nodes_in_group("interactive_stations"):
				if node.get("station_id") != null:
					match node.station_id:
						"fountain": st_fountain = node
						"bakery": st_bakery = node
						"clinic": st_clinic = node
						"bell": st_bell = node
						"desk": st_desk = node
						"bed": st_bed = node
						"petitions": st_pet = node

			assert(st_fountain != null, "LỖI: Thiếu Trạm Đài Phun Nước (fountain)!")
			assert(st_bakery != null, "LỖI: Thiếu Trạm Tiệm Bánh Mì (bakery)!")
			assert(st_clinic != null, "LỖI: Thiếu Trạm Trạm Xá (clinic)!")
			assert(st_bell != null, "LỖI: Thiếu Trạm Dây Chuông (bell)!")
			assert(st_desk != null, "LỖI: Thiếu Trạm Bàn Sắc Lệnh (desk)!")
			assert(st_bed != null, "LỖI: Thiếu Trạm Giường Ngủ (bed)!")
			assert(st_pet != null, "LỖI: Thiếu Trạm Bảng Tin (petitions)!")
			print("  ✅ Đã định vị đủ 7 Trạm Tương Tác Cốt Lõi tại Quảng Trường Trung Tâm!")

			test_step = 1
			test_frames = 0
			return false

		1:
			# BƯỚC 1: TIẾP CẬN & TƯƠNG TÁC ĐÀI PHUN NƯỚC ƯỚC NGUYỆN (FOUNTAIN)
			if test_frames < 4:
				return false

			print("\n[Bước 1] TIẾP CẬN ĐÀI PHUN NƯỚC ƯỚC NGUYỆN (X=0, Z=0):")
			player.global_position = st_fountain.global_position + Vector3(0, 0, 2.5)

			test_step = 2
			test_frames = 0
			return false

		2:
			if test_frames < 4:
				return false

			var dist = player.global_position.distance_to(st_fountain.global_position)
			print("  - Cự ly tới Đài Phun Nước: %.2fm (Bán kính cảm biến: %.2fm)" % [dist, st_fountain.interaction_radius])
			assert(dist <= st_fountain.interaction_radius, "Player phải ở trong cự ly tương tác!")
			assert(st_fountain.prompt_label.visible == true, "Bảng chữ 3D nhắc lệnh [E] phải hiện lên!")
			print("  - Nhãn 3D nhắc lệnh: %s (visible: %s)" % [st_fountain.prompt_label.text, st_fountain.prompt_label.visible])

			# Mô phỏng nhấn phím [E] vật lý
			var ev = InputEventKey.new()
			ev.keycode = KEY_E
			ev.physical_keycode = KEY_E
			ev.pressed = true
			player._input(ev)

			test_step = 3
			test_frames = 0
			return false

		3:
			if test_frames < 4:
				return false

			assert(st_fountain.interaction_count >= 1, "Đài Phun Nước phải được kích hoạt ít nhất 1 lần!")
			assert(hud.quests_data["quest_fountain"]["done"] == true, "Nhiệm vụ Đài Phun Nước phải được đánh dấu hoàn thành!")
			assert(hud.toast_panel.visible == true, "Toast thông báo phải hiện lên!")
			print("  ✅ Kích hoạt thành công Đài Phun Nước! Toast: '%s'" % hud.toast_label.text)

			# BƯỚC 2: TIẾP CẬN TIỆM BÁNH MÌ BÁC NAM (BAKERY)
			print("\n[Bước 2] TIẾP CẬN TIỆM BÁNH MÌ BÁC NAM (-14, 10):")
			var wm = root.get_node_or_null("/root/WorldManager")
			wm.set_time_of_day(9, 0)
			player.global_position = st_bakery.global_position + Vector3(0, 0, 2.0)

			test_step = 4
			test_frames = 0
			return false

		4:
			if test_frames < 4:
				return false

			assert(st_bakery.prompt_label.visible == true, "Nhãn 3D Tiệm Bánh Mì phải hiện lên!")
			var ev = InputEventKey.new()
			ev.keycode = KEY_E
			ev.physical_keycode = KEY_E
			ev.pressed = true
			player._input(ev)

			test_step = 5
			test_frames = 0
			return false

		5:
			if test_frames < 4:
				return false

			assert(st_bakery.interaction_count >= 1, "Tiệm Bánh Mì phải được kích hoạt!")
			assert(hud.quests_data["quest_bakery"]["done"] == true, "Nhiệm vụ Tiệm Bánh Mì phải hoàn thành!")
			print("  ✅ Nhận bánh mì nóng Bác Nam thành công! Toast: '%s'" % hud.toast_label.text)

			var wm = root.get_node_or_null("/root/WorldManager")
			wm.set_time_of_day(12, 0)
			assert("🔴 Đóng cửa theo lịch" in st_bakery.prompt_label.text, "Tiệm bánh phải hiển thị đóng cửa trong giờ nghỉ trưa.")
			var closed_service_event := InputEventKey.new()
			closed_service_event.keycode = KEY_E
			closed_service_event.physical_keycode = KEY_E
			closed_service_event.pressed = true
			player._input(closed_service_event)
			assert(st_bakery.interaction_count == 1, "Tiệm bánh đóng cửa không được tính là giao dịch thành công.")
			assert("đóng cửa theo lịch" in hud.toast_label.text, "Cơ sở đóng cửa phải giải thích lý do từ chối phục vụ.")
			wm.set_time_of_day(14, 0)
			assert("🟢 Đang phục vụ" in st_bakery.prompt_label.text, "Tiệm bánh phải mở lại khi ca chiều bắt đầu.")
			print("  ✅ Tiệm bánh đóng/mở theo lịch và từ chối giao dịch trong giờ nghỉ trưa.")

			# BƯỚC 3: TIẾP CẬN TRẠM XÁ CHỊ MAI (CLINIC)
			print("\n[Bước 3] TIẾP CẬN TRẠM XÁ CHỊ MAI (14, 10):")
			player.global_position = st_clinic.global_position + Vector3(0, 0, 2.0)

			test_step = 6
			test_frames = 0
			return false

		6:
			if test_frames < 4:
				return false

			assert(st_clinic.prompt_label.visible == true, "Nhãn 3D Trạm Xá phải hiện lên!")
			var ev = InputEventKey.new()
			ev.keycode = KEY_E
			ev.physical_keycode = KEY_E
			ev.pressed = true
			player._input(ev)

			test_step = 7
			test_frames = 0
			return false

		7:
			if test_frames < 4:
				return false

			assert(st_clinic.interaction_count >= 1, "Trạm Xá phải được kích hoạt!")
			assert(hud.quests_data["quest_clinic"]["done"] == true, "Nhiệm vụ Trạm Xá phải hoàn thành!")
			print("  ✅ Uống trà thảo mộc Chị Mai thành công! Toast: '%s'" % hud.toast_label.text)

			# BƯỚC 4: TIẾP CẬN DÂY CHUÔNG HÒA BÌNH (BELL TOWER)
			print("\n[Bước 4] TIẾP CẬN DÂY RUNG CHUÔNG HÒA BÌNH (36, -10):")
			player.global_position = st_bell.global_position + Vector3(0, 0, 2.0)

			test_step = 8
			test_frames = 0
			return false

		8:
			if test_frames < 4:
				return false

			assert(st_bell.prompt_label.visible == true, "Nhãn 3D Dây Chuông phải hiện lên!")
			var ev = InputEventKey.new()
			ev.keycode = KEY_E
			ev.physical_keycode = KEY_E
			ev.pressed = true
			player._input(ev)

			test_step = 9
			test_frames = 0
			return false

		9:
			if test_frames < 4:
				return false

			assert(st_bell.interaction_count >= 1, "Dây Chuông phải được kích hoạt!")
			assert(hud.quests_data["quest_bell"]["done"] == true, "Nhiệm vụ Rung Chuông phải hoàn thành!")
			var wm = root.get_node_or_null("/root/WorldManager")
			assert(wm != null and wm.is_liturgy_active == true, "Thánh Lễ và Chuông phải ngân vang!")
			print("  ✅ Chuông Hòa Bình đã ngân vang khắp 500 km²! Toast: '%s'" % hud.toast_label.text)

			# BƯỚC 5: TIẾP CẬN BÀN SẮC LỆNH THỊ TRƯỞNG (DESK)
			print("\n[Bước 5] TIẾP CẬN BÀN SẮC LỆNH THỊ TRƯỞNG (-18, -10):")
			player.global_position = st_desk.global_position + Vector3(0, 0, 1.8)

			test_step = 10
			test_frames = 0
			return false

		10:
			if test_frames < 4:
				return false

			assert(st_desk.prompt_label.visible == true, "Nhãn 3D Bàn Sắc Lệnh phải hiện lên!")
			var ev = InputEventKey.new()
			ev.keycode = KEY_E
			ev.physical_keycode = KEY_E
			ev.pressed = true
			player._input(ev)

			test_step = 11
			test_frames = 0
			return false

		11:
			if test_frames < 4:
				return false

			assert(st_desk.interaction_count >= 1, "Bàn Sắc Lệnh phải được kích hoạt!")
			assert(hud.is_life_activity_options_open(), "Bàn làm việc phải mở lựa chọn ngồi hoặc ký sắc lệnh!")
			assert(hud.life_activity_buttons.has("desk_sit"), "Phải có lựa chọn ngồi làm việc.")
			assert(hud.life_activity_buttons.has("desk_sign"), "Phải có lựa chọn ký sắc lệnh.")
			hud.life_activity_buttons["desk_sign"].pressed.emit()
			assert(hud.quests_data["quest_desk"]["done"] == true, "Nhiệm vụ Bàn Sắc Lệnh phải hoàn thành!")
			print("  ✅ Sắc lệnh Thị Trưởng ban hành thành công! Toast: '%s'" % hud.toast_label.text)

			# BƯỚC 6: TIẾP CẬN BẢNG TIN CƯ DÂN (PETITIONS)
			print("\n[Bước 6] TIẾP CẬN BẢNG TIN NGUYỆN VỌNG CƯ DÂN (0, 16):")
			player.global_position = st_pet.global_position + Vector3(0, 0, 2.0)

			test_step = 12
			test_frames = 0
			return false

		12:
			if test_frames < 4:
				return false

			assert(st_pet.prompt_label.visible == true, "Nhãn 3D Bảng Tin Cư Dân phải hiện lên!")
			var ev = InputEventKey.new()
			ev.keycode = KEY_E
			ev.physical_keycode = KEY_E
			ev.pressed = true
			player._input(ev)

			test_step = 13
			test_frames = 0
			return false

		13:
			if test_frames < 4:
				return false

			assert(st_pet.interaction_count >= 1, "Bảng Tin phải được kích hoạt!")
			assert(hud.petition_modal.visible == true, "Hộp thoại Bảng Tin Cư Dân phải mở ra!")
			assert(hud.quests_data["quest_petitions"]["done"] == true, "Nhiệm vụ Bảng Tin phải hoàn thành!")
			print("  ✅ Đã xem nguyện vọng cư dân 5 huyện thành công!")
			hud.close_petition_modal()
			assert(hud.petition_modal.visible == false, "Hộp thoại Bảng Tin phải đóng lại sau khi đọc!")

			# BƯỚC 7: TIẾP CẬN GIƯỜNG NGHỈ (BED - NIGHT SKIP)
			print("\n[Bước 7] TIẾP CẬN GIƯỜNG NGHỈ THỊ TRƯỞNG & TUA QUA ĐÊM (-22, -10):")
			var wm = root.get_node_or_null("/root/WorldManager")
			if wm:
				wm.set_time_of_day(22, 30) # Đặt lúc 22:30 đêm
			player.global_position = st_bed.global_position + Vector3(0, 0, 1.8)

			test_step = 14
			test_frames = 0
			return false

		14:
			if test_frames < 4:
				return false

			assert(st_bed.prompt_label.visible == true, "Nhãn 3D Giường Ngủ phải hiện lên!")
			var ev = InputEventKey.new()
			ev.keycode = KEY_E
			ev.physical_keycode = KEY_E
			ev.pressed = true
			player._input(ev)
			assert(hud.is_life_activity_options_open(), "Giường phải hiển thị lựa chọn nằm nghỉ hoặc tua đêm.")
			assert(hud.life_activity_buttons.has("bed_sleep"), "Ban đêm phải có lựa chọn ngủ đến sáng.")
			hud.life_activity_buttons["bed_sleep"].pressed.emit()

			test_step = 15
			test_frames = 0
			return false

		15:
			if test_frames < 4:
				return false

			var wm = root.get_node_or_null("/root/WorldManager")
			assert(wm.current_hour == 6, "Giờ phải được tua sang 06:00 sáng!")
			assert(hud.quests_data["quest_bed"]["done"] == true, "Nhiệm vụ Giường Ngủ phải hoàn thành!")
			print("  ✅ Night Skip qua đêm thành công! Đón bình minh lúc %s" % wm.get_formatted_time())

			# BƯỚC 8: TIẾP CẬN & LÁI XE BUGGY ĐIỆN THỊ TRƯỞNG (60 KM/H)
			print("\n[Bước 8] TIẾP CẬN & LÁI XE BUGGY ĐIỆN THỊ TRƯỞNG (10, 14):")
			if player.has_method("end_life_activity"):
				player.end_life_activity()
			player.global_position = buggy.global_position + Vector3(0, 0, 2.5)

			test_step = 16
			test_frames = 0
			return false

		16:
			if test_frames < 4:
				return false

			var dist_buggy = player.global_position.distance_to(buggy.global_position)
			print("  - Cự ly tới Xe Buggy Điện: %.2fm (Player: %s, Buggy: %s)" % [dist_buggy, player.global_position, buggy.global_position])
			assert(dist_buggy <= 6.0, "Player phải ở trong cự ly tương tác xe buggy!")
			assert(buggy.prompt_3d.visible == true, "Bảng chữ 3D xe buggy [F/E] phải hiện lên!")

			# Mô phỏng phím [F] lên xe
			var ev_f = InputEventKey.new()
			ev_f.keycode = KEY_F
			ev_f.physical_keycode = KEY_F
			ev_f.pressed = true
			player._input(ev_f)

			test_step = 17
			test_frames = 0
			return false

		17:
			if test_frames < 4:
				return false

			assert(buggy.is_occupied == true, "Buggy phải chuyển sang is_occupied = true!")
			assert(player.visible == false, "Player phải ẩn khi đang lái buggy!")
			assert(buggy.chase_camera.current == true, "Camera phải chuyển sang Camera Xe Buggy!")
			assert(hud.quests_data["quest_buggy"]["done"] == true, "Nhiệm vụ Lái Xe Buggy phải hoàn thành!")
			print("  ✅ Thị Trưởng đã lên Xe Buggy Điện thành công!")

			# Mô phỏng bóp còi xe [H]
			var ev_h = InputEventKey.new()
			ev_h.keycode = KEY_H
			ev_h.physical_keycode = KEY_H
			ev_h.pressed = true
			buggy._input(ev_h)

			# Mô phỏng phím [F] xuống xe
			var ev_exit = InputEventKey.new()
			ev_exit.keycode = KEY_F
			ev_exit.physical_keycode = KEY_F
			ev_exit.pressed = true
			buggy._input(ev_exit)

			test_step = 18
			test_frames = 0
			return false

		18:
			if test_frames < 4:
				return false

			assert(buggy.is_occupied == false, "Buggy phải ở trạng thái is_occupied = false sau khi xuống!")
			assert(player.visible == true, "Player phải hiện hình lại sau khi xuống xe!")
			print("  ✅ Thị Trưởng đã xuống Xe Buggy Điện an toàn!")

			# BƯỚC 9: TỔNG KẾT MỤC TIÊU ĐÔ THỊ TRUNG TÂM (8/8)
			print("\n[Bước 9] KIỂM TRA TIẾN ĐỘ QUEST TRACKER:")
			var completed = 0
			for qid in hud.quests_data.keys():
				var q = hud.quests_data[qid]
				if q["done"]:
					completed += 1
				print("  - %s: %s [%s]" % [qid, q["title"], "ĐÃ HOÀN THÀNH" if q["done"] else "CHƯA XONG"])

			print("  -> Tổng số nhiệm vụ hoàn thành: %d / %d" % [completed, hud.quests_data.size()])
			assert(completed == 8, "Cả 8 nhiệm vụ khởi đầu Trung Tâm phải hoàn thành 100%!")
			assert(hud.quest_title_label.text.contains("8/"), "Tiêu đề Quest Tracker phải cập nhật (8/...)!")

			print("\n================================================================================")
			print("🎉 TOÀN BỘ CÁC BÀI KIỂM THỬ TRUNG TÂM ĐÔ THỊ ĐÃ THÀNH CÔNG RỰC RỠ (100% PASS)!")
			print("================================================================================")
			quit(0)
			return true

	return false
