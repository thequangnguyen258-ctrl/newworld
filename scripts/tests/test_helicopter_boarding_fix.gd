extends SceneTree

# ==============================================================================
# KIỂM THỬ TỰ ĐỘNG: CƠ CHẾ TIẾP CẬN & LÊN / XUỐNG TRỰC THĂNG (F / E)
# ==============================================================================

var test_frames: int = 0
var test_step: int = 0
var main_world: Node3D = null
var player: PlayerController = null
var helicopter: HelicopterController = null

func _init() -> void:
	print("\n================================================================================")
	print("🚁 KIỂM THỬ: TIẾP CẬN VÀ LÊN / XUỐNG TRỰC THĂNG BẰNG PHÍM [F] HOẶC [E]")
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

		print("\n[1] KIỂM TRA TRẠNG THÁI BAN ĐẦU (KHI Ở XA > 7M):")
		var dist = player.global_position.distance_to(helicopter.global_position)
		print("  - Khoảng cách ban đầu: %.2fm" % dist)
		assert(helicopter.is_occupied == false, "Trực thăng ban đầu chưa có người lái")

		test_step = 1
		test_frames = 0
		return false

	if test_step == 1:
		if test_frames < 5:
			return false

		print("\n[2] TIẾP CẬN TRỰC THĂNG VÀO BÁN KÍNH HELIPAD (~2.5M):")
		# Đặt vị trí player lại sát trực thăng (như trong ảnh screenshot của user)
		player.global_position = helicopter.global_position + Vector3(0.0, 0.0, 2.5)

		test_step = 2
		test_frames = 0
		return false

	if test_step == 2:
		if test_frames < 5:
			return false

		var dist = player.global_position.distance_to(helicopter.global_position)
		print("  - Khoảng cách sau khi tiếp cận: %.2fm (Kỳ vọng <= 7.0m)" % dist)
		assert(dist <= 7.0, "Player phải ở trong bán kính tương tác!")

		print("  - Kiểm tra bảng chữ 3D nhắc lệnh [prompt_3d.visible]: %s" % helicopter.prompt_3d.visible)
		assert(helicopter.prompt_3d.visible == true, "prompt_3d phải hiển thị khi Player ở gần!")
		print("  - Kiểm tra meta nearby_helicopter trên Player: %s" % player.has_meta("nearby_helicopter"))
		assert(player.has_meta("nearby_helicopter") == true, "Player phải có meta nearby_helicopter!")

		print("\n[3] MÔ PHỎNG NHẤN PHÍM [F] ĐỂ LÊN TRỰC THĂNG:")
		var ev_f = InputEventKey.new()
		ev_f.keycode = KEY_F
		ev_f.physical_keycode = KEY_F
		ev_f.pressed = true
		player._input(ev_f)

		test_step = 3
		test_frames = 0
		return false

	if test_step == 3:
		if test_frames < 5:
			return false

		print("  - Trực thăng is_occupied: %s" % helicopter.is_occupied)
		assert(helicopter.is_occupied == true, "Trực thăng phải chuyển sang is_occupied = true!")
		assert(player.visible == false, "Player phải ẩn khi đang lái trực thăng!")
		assert(helicopter.chase_camera.current == true, "Camera phải chuyển sang Camera Trực Thăng!")
		assert(helicopter.hud_layer.visible == true, "HUD Phi hành phải hiển thị!")
		print("  ✅ Thị Trưởng đã lên trực thăng thành công bằng phím [F]!")

		print("\n[4] MÔ PHỎNG NHẤN PHÍM [F] ĐỂ XUỐNG TRỰC THĂNG:")
		var ev_exit = InputEventKey.new()
		ev_exit.keycode = KEY_F
		ev_exit.physical_keycode = KEY_F
		ev_exit.pressed = true
		helicopter._unhandled_input(ev_exit)

		test_step = 4
		test_frames = 0
		return false

	if test_step == 4:
		if test_frames < 5:
			return false

		assert(helicopter.is_occupied == false, "Trực thăng phải chuyển về is_occupied = false!")
		assert(player.visible == true, "Player phải hiện lại sau khi xuống!")
		assert(helicopter.hud_layer.visible == false, "HUD Phi hành phải ẩn đi!")
		print("  ✅ Thị Trưởng đã xuống trực thăng an toàn!")

		print("\n[5] MÔ PHỎNG LÊN TRỰC THĂNG BẰNG PHÍM [E] (DỰ PHÒNG TƯƠNG TÁC):")
		var ev_e = InputEventKey.new()
		ev_e.keycode = KEY_E
		ev_e.physical_keycode = KEY_E
		ev_e.pressed = true
		player._input(ev_e)

		test_step = 5
		test_frames = 0
		return false

	if test_step == 5:
		if test_frames < 5:
			return false

		assert(helicopter.is_occupied == true, "Phím [E] cũng phải cho phép lên trực thăng thành công!")
		print("  ✅ Lên trực thăng bằng phím [E] thành công 100%!")

		print("\n================================================================================")
		print("🎉 TẤT CẢ CÁC BÀI KIỂM THỬ LÊN / XUỐNG TRỰC THĂNG ĐÃ ĐẠT 100% THÀNH CÔNG!")
		print("================================================================================")
		quit(0)
		return true

	return false
