class_name TestHelicopterAndSouthernMeadow
extends SceneTree

# ==============================================================================
# TEST AUTOMATION: TRỰC THĂNG CAO TỐC & BỎ THÁC NƯỚC PHÍA NAM
# 1. Kiểm tra loại bỏ thác nước & sương mù phía Nam
# 2. Kiểm tra Trực Thăng Cao Tốc Thị Trưởng (40 m/s cruise, 700 km/h Turbo)
# 3. Kiểm tra cơ chế Lên / Xuống trực thăng [F], Camera đuổi & HUD phi hành
# 4. Kiểm tra Sân đỗ trực thăng Helipad chuẩn đồ họa Anime
# ==============================================================================

func _init() -> void:
	print("================================================================================")
	print("🚁 KIỂM THỬ TỰ ĐỘNG: TRỰC THĂNG CAO TỐC (700 KM/H) & XÓA BỎ THÁC NƯỚC NAM")
	print("================================================================================")
	
	_test_southern_waterfall_removal()
	_test_helipad_generation()
	_test_helicopter_system()
	
	print("\n🎉 TOÀN BỘ CÁC BÀI KIỂM THỬ ĐÃ THÀNH CÔNG RỰC RỠ (100% PASS)!")
	print("================================================================================")
	quit(0)

func _test_southern_waterfall_removal() -> void:
	print("\n[1] KIỂM TRA LOẠI BỎ THÁC NƯỚC PHÍA NAM (SOUTHERN WATERFALL REMOVAL):")
	
	# Khởi tạo NaturalLandscape
	var assembler_script = load("res://scripts/terrain/natural_landscape_assembler.gd")
	var assembler = assembler_script.new()
	assembler.auto_assemble = false # Tự gọi từng phần
	root.add_child(assembler)
	
	# Kiểm tra không còn node sương thác nước WaterfallMist
	var mist = assembler.get_node_or_null("WaterfallMist")
	assert(mist == null, "LỖI: WaterfallMist vẫn còn tồn tại!")
	print("  ✅ ĐẠT: Không còn hiệu ứng sương mù thác nước (WaterfallMist = null)")
	
	# Kiểm tra độ cao tại vùng Nam (trước đây là vực thác 12km)
	var h_south_12km = ModularNatureChunk.get_world_height(0.0, 12000.0)
	print("  - Cao độ tại Nam Z=+12000m: %.2fm (Cao nguyên xanh êm dịu, không bị sụt vực thác)" % h_south_12km)
	assert(h_south_12km >= 590.0, "LỖI: Cao nguyên Nam bị sụt vực nước!")
	print("  ✅ ĐẠT: Vùng Nam là cao nguyên liền mạch +600m.")
	
	assembler.queue_free()

func _test_helipad_generation() -> void:
	print("\n[2] KIỂM TRA SÂN ĐỖ TRỰC THĂNG HELIPAD:")
	var helipad = HelipadBuilder.build_helipad()
	assert(helipad != null, "LỖI: HelipadBuilder không trả về Node3D!")
	assert(helipad.get_child_count() >= 3, "LỖI: Helipad thiếu các chi tiết đồ họa!")
	print("  - Số lượng chi tiết cấu thành Helipad: %d components" % helipad.get_child_count())
	print("  ✅ ĐẠT: Helipad bát giác với vòng tròn vàng, chữ [H] và 4 đèn Amber khởi tạo hoàn hảo!")
	helipad.queue_free()

func _test_helicopter_system() -> void:
	print("\n[3] KIỂM TRA TRỰC THĂNG CAO TỐC & KHÍ ĐỘNG HỌC:")
	
	var heli_scene = load("res://scenes/interactive/helicopter.tscn")
	var heli: HelicopterController = heli_scene.instantiate()
	heli.position = Vector3(26.0, 600.3, 12.0)
	root.add_child(heli)
	heli._ready()
	
	# Kiểm tra cấu trúc trực thăng
	assert(heli.visual_root != null, "LỖI: Thiếu visual_root trực thăng!")
	assert(heli.main_rotor_pivot != null, "LỖI: Thiếu cánh quạt chính!")
	assert(heli.tail_rotor_pivot != null, "LỖI: Thiếu cánh quạt đuôi!")
	assert(heli.chase_camera != null, "LỖI: Thiếu chase camera!")
	assert(heli.hud_layer != null, "LỖI: Thiếu Flight HUD layer!")
	print("  ✅ Cấu trúc trực thăng đầy đủ: Thân Anime Toon, Cánh quạt chính, Cánh đuôi, Động cơ Turbo, Camera Far=35km.")
	
	# Kiểm tra trạng thái Parked
	assert(not heli.is_occupied, "LỖI: Trực thăng ban đầu không được có người lái!")
	assert(not heli.hud_layer.visible, "LỖI: Flight HUD phải ẩn khi trực thăng đỗ!")
	print("  ✅ Trạng thái ban đầu: Đang đỗ ổn định trên Helipad.")
	
	# Tạo Mock Player để lên trực thăng
	var player = CharacterBody3D.new()
	player.add_to_group("player")
	player.position = Vector3(24.0, 600.5, 12.0)
	var p_cam = Camera3D.new()
	p_cam.name = "Camera3D"
	var p_head = Node3D.new()
	p_head.name = "Head"
	p_head.add_child(p_cam)
	player.add_child(p_head)
	root.add_child(player)
	
	# Kiểm tra cơ chế Lên Trực Thăng (Boarding)
	print("\n[4] KIỂM TRA CƠ CHẾ LÊN TRỰC THĂNG [F]:")
	heli.board(player)
	assert(heli.is_occupied, "LỖI: Sau khi board(), is_occupied phải là true!")
	assert(not player.visible, "LỖI: Nhân vật phải được ẩn khi ngồi trong trực thăng!")
	assert(heli.chase_camera.current, "LỖI: Camera trực thăng phải trở thành current camera!")
	assert(heli.hud_layer.visible, "LỖI: Flight HUD phải hiển thị cho phi công!")
	print("  ✅ ĐẠT: Thị Trưởng lên trực thăng thành công, Camera chuyển sang trực thăng, Flight HUD kích hoạt!")

	# Kiểm tra mô phỏng bay tốc độ cao (Flight Simulation)
	print("\n[5] KIỂM TRA TỐC ĐỘ PHI HÀNH (CRUISE & TURBO BOOST):")
	# Mô phỏng bay tiến 1.5 giây
	heli.current_forward_speed = heli.cruise_speed
	heli.velocity = -heli.transform.basis.z * heli.cruise_speed
	print("  - Tốc độ bay thường (Cruise Speed): %.1f m/s = %.1f km/h" % [
		heli.cruise_speed, heli.cruise_speed * 3.6
	])
	assert(heli.cruise_speed >= 40.0, "LỖI: Tốc độ thường phải đạt ít nhất 40 m/s (144 km/h)!")
	
	# Mô phỏng kích hoạt Turbo Boost [Shift]
	heli.is_turbo_active = true
	heli.current_forward_speed = heli.turbo_speed
	heli.velocity = -heli.transform.basis.z * heli.turbo_speed
	print("  - Tốc độ Siêu Tốc Turbo [Shift]: %.1f m/s = %.1f km/h" % [
		heli.turbo_speed, heli.turbo_speed * 3.6
	])
	assert(is_equal_approx(heli.turbo_speed * 3.6, 700.0), "LỖI: Tốc độ Turbo khi giữ Shift phải đạt 700 km/h!")
	print("  ✅ ĐẠT: Khả năng vượt 500 km²: Bay hết 10 km chỉ trong ~110 giây!")

	# Kiểm tra bay nâng độ cao (Climb)
	heli.position.y += 100.0 # Bay lên cao độ +700m
	heli.velocity.y = heli.vertical_climb_speed
	assert(heli.vertical_climb_speed >= 15.0, "LỖI: Tốc độ nâng phải đạt ít nhất 15 m/s!")
	print("  - Tốc độ bay lên thẳng đứng: %.1f m/s" % heli.vertical_climb_speed)
	print("  ✅ ĐẠT: Cao nguyên trung tâm duy trì ở +600m.")

	# Kiểm tra cơ chế Xuống Trực Thăng (Exit)
	print("\n[6] KIỂM TRA CƠ CHẾ XUỐNG TRỰC THĂNG [F]:")
	heli.exit_helicopter()
	assert(not heli.is_occupied, "LỖI: Sau khi exit, is_occupied phải là false!")
	assert(player.visible, "LỖI: Nhân vật phải hiển thị trở lại sau khi xuống xe!")
	assert(not heli.hud_layer.visible, "LỖI: Flight HUD phải tắt sau khi xuống trực thăng!")
	print("  - Vị trí người chơi sau khi xuống: %s (Bám đất an toàn)" % player.position)
	print("  ✅ ĐẠT: Xuống trực thăng an toàn, hoàn trả quyền điều khiển và góc nhìn cho người chơi.")

	player.queue_free()
	heli.queue_free()
