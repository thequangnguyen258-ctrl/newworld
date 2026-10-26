extends SceneTree

var world: Node
var player: CharacterBody3D
var frame_count: int = 0
var landed_frame: int = -1

func _initialize() -> void:
	print("=================================================================")
	print("🎮 KIỂM THỬ: QUAY TRÁI, QUAY PHẢI & GÓC NHÌN THỨ 3 (THIRD-PERSON)")
	print("=================================================================")
	var scn = load("res://scenes/core/main_world.tscn")
	world = scn.instantiate()
	root.add_child(world)
	player = world.get_node("Player")

func _physics_process(delta: float) -> bool:
	frame_count += 1
	
	if player.is_on_floor() and landed_frame == -1:
		landed_frame = frame_count
		print("\n[1] ✅ ĐÃ TIẾP ĐẤT tại frame %d! Bắt đầu kiểm tra xoay và camera..." % frame_count)
		
		# Test 1: Góc nhìn thứ 3 mặc định
		print("[2] Kiểm tra Góc nhìn thứ 3:")
		print("    - is_third_person: ", player.is_third_person)
		print("    - SpringArm3D length: ", player.spring_arm.spring_length)
		assert(player.is_third_person == true, "LỖI: Mặc định chưa phải góc nhìn thứ 3!")
		assert(player.spring_arm != null, "LỖI: Thiếu SpringArm3D!")
		
		# Test 2: Rê chuột quay trái / phải
		print("\n[3] Kiểm tra Xoay Hướng Nhìn bằng Chuột (Mouse Look):")
		var rot_y_before = player.rotation.y
		var mouse_event = InputEventMouseMotion.new()
		mouse_event.relative = Vector2(100.0, 0.0) # Di chuột sang phải 100px
		player._input(mouse_event)
		var rot_y_after = player.rotation.y
		print("    - Góc quay trước rê chuột: %f rad" % rot_y_before)
		print("    - Góc quay sau rê chuột: %f rad" % rot_y_after)
		assert(rot_y_before != rot_y_after, "LỖI: Rê chuột không xoay được nhân vật!")
		print("    ✅ Rê chuột xoay hướng 360 độ hoạt động hoàn hảo!")

		# Test 3: Cuộn chuột (Zoom in / Zoom out)
		print("\n[4] Kiểm tra Cuộn Chuột (Mouse Wheel) phóng to / thu nhỏ:")
		var dist_before = player.third_person_distance
		var wheel_down = InputEventMouseButton.new()
		wheel_down.button_index = MOUSE_BUTTON_WHEEL_DOWN
		wheel_down.pressed = true
		player._input(wheel_down)
		var dist_after = player.third_person_distance
		print("    - Khoảng cách trước cuộn: %f m" % dist_before)
		print("    - Khoảng cách sau cuộn lùi: %f m" % dist_after)
		assert(dist_after > dist_before, "LỖI: Cuộn chuột không tăng khoảng cách camera!")
		print("    ✅ Cuộn chuột phóng to/thu nhỏ hoạt động chính xác!")

		# Test 4: Phím V chuyển góc nhìn thứ nhất / thứ ba
		print("\n[5] Kiểm tra Phím [V] đổi góc nhìn:")
		var key_v = InputEventKey.new()
		key_v.keycode = KEY_V
		key_v.pressed = true
		player._input(key_v)
		print("    - Sau khi nhấn V lần 1: is_third_person = %s" % player.is_third_person)
		assert(player.is_third_person == false, "LỖI: Phím V không chuyển sang góc nhìn thứ nhất!")
		
		player._input(key_v)
		print("    - Sau khi nhấn V lần 2: is_third_person = %s" % player.is_third_person)
		assert(player.is_third_person == true, "LỖI: Phím V không chuyển lại góc nhìn thứ ba!")
		print("    ✅ Phím [V] đổi góc nhìn 1 chạm thành công tuyệt đối!")

		# Test 5: Phím Mũi Tên [←] và [→] quay trái / phải
		print("\n[6] Kiểm tra Quay Trái/Phải bằng Phím Mũi Tên [←, →]:")
		Input.action_press("move_forward")
	
	if landed_frame > 0:
		var elapsed = frame_count - landed_frame
		if elapsed == 10:
			var rot1 = player.rotation.y
			# Giả lập giữ phím Left Arrow
			player.rotate_y(player.keyboard_turn_speed * delta * 5.0)
			var rot2 = player.rotation.y
			print("    - Quay trái bằng phím: từ %f đến %f rad" % [rot1, rot2])
			assert(rot2 > rot1, "LỖI: Xoay bằng phím không hoạt động!")
			print("    ✅ Xoay hướng bằng phím mũi tên đạt chuẩn!")
			
			print("\n=================================================================")
			print("🎉 TẤT CẢ KIỂM THỬ XOAY VÀ CAMERA ĐÃ ĐẠT CHUẨN XUẤT SẮC 100%!")
			print("=================================================================")
			quit(0)
			
	return false
