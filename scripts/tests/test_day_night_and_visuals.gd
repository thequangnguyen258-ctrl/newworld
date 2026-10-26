extends SceneTree

const DayNightControllerScript = preload("res://scripts/environment/day_night_controller.gd")

func _init() -> void:
	print("=================================================================")
	print("☀️ BẮT ĐẦU KIỂM THỬ: CHU KỲ NGÀY - ĐÊM & ÁNH SÁNG ANIME TOON")
	print("=================================================================")
	
	# --------------------------------------------------------------------------
	# 1. KIỂM THỬ 4 PHA BẦU TRỜI & ÁNH SÁNG TOON
	# --------------------------------------------------------------------------
	print("\n[1] KIỂM TRA ĐẶC TÍNH MÀU SẮC & ÁNH SÁNG 4 THỜI KHẮC ANIME:")
	
	# Pha 1: Bình minh vàng mật (06:15)
	var dawn = DayNightControllerScript.evaluate_atmosphere(6.25)
	print("  [Bình Minh 06:15]:")
	print("    - Ánh nắng: %s (Năng lượng = %.2f)" % [dawn["light_color"], dawn["light_energy"]])
	print("    - Chân trời ửng hồng cam: %s (Quầng sáng = %.2f)" % [dawn["horizon_color"], dawn["horizon_glow_intensity"]])
	assert(dawn["light_color"].r > 0.95 and dawn["light_color"].b < 0.70, "LỖI: Bình minh phải có sắc vàng mật ấm áp!")
	assert(dawn["horizon_glow_intensity"] > 1.0, "LỖI: Chân trời bình minh phải có quầng sáng rực rỡ!")
	print("    ✅ ĐẠT CHUẨN: Bình minh vàng mật ấm áp rực rỡ!")
	
	# Pha 2: Giữa trưa nắng Toon (12:00)
	var day = DayNightControllerScript.evaluate_atmosphere(12.0)
	print("  [Giữa Trưa 12:00]:")
	print("    - Ánh nắng Toon: %s (Năng lượng = %.2f)" % [day["light_color"], day["light_energy"]])
	print("    - Bầu trời xanh biếc Ghibli: %s" % day["top_color"])
	print("    - Sao ban ngày: %.1f (Kỳ vọng: 0.0)" % day["stars_intensity"])
	assert(day["light_energy"] >= 1.3, "LỖI: Ban ngày nắng phải rực rỡ (energy >= 1.3)!")
	assert(day["stars_intensity"] == 0.0, "LỖI: Ban ngày không được có sao!")
	print("    ✅ ĐẠT CHUẨN: Ban ngày trong vắt, nắng vàng rực Toon rõ nét!")
	
	# Pha 3: Hoàng hôn tím hồng Shinkai (17:45)
	var dusk = DayNightControllerScript.evaluate_atmosphere(17.75)
	print("  [Hoàng Hôn 17:45]:")
	print("    - Ánh chiều tà: %s (Năng lượng = %.2f)" % [dusk["light_color"], dusk["light_energy"]])
	print("    - Chân trời tím hồng: %s (Quầng sáng tím = %.2f)" % [dusk["horizon_color"], dusk["horizon_glow_intensity"]])
	print("    - Bầu trời tím sâu: %s" % dusk["top_color"])
	assert(dusk["horizon_color"].r > 0.85 and dusk["horizon_color"].b > 0.45, "LỖI: Hoàng hôn phải mang sắc tím hồng Makoto Shinkai!")
	assert(dusk["horizon_glow_intensity"] > 1.2, "LỖI: Quầng sáng hoàng hôn phải rực rỡ!")
	print("    ✅ ĐẠT CHUẨN: Hoàng hôn tím hồng huyền ảo lãng mạn!")
	
	# Pha 4: Ban đêm sao lung linh (22:30)
	var night = DayNightControllerScript.evaluate_atmosphere(22.5)
	print("  [Ban Đêm 22:30]:")
	print("    - Ánh trăng bạc dịu mát: %s (Năng lượng = %.2f)" % [night["light_color"], night["light_energy"]])
	print("    - Bầu trời đêm chàm thẫm: %s" % night["top_color"])
	print("    - Ngàn sao lung linh: %.2f (Kỳ vọng: 1.0)" % night["stars_intensity"])
	assert(night["light_color"].b > night["light_color"].r, "LỖI: Ánh trăng đêm phải có tông bạc/xanh dịu mát!")
	assert(night["light_energy"] > 0.25 and night["light_energy"] < 0.50, "LỖI: Ban đêm phải đủ sáng để thấy đường, không tối đen!")
	assert(night["stars_intensity"] >= 0.95, "LỖI: Ban đêm phải có bầu trời sao anime lung linh!")
	print("    ✅ ĐẠT CHUẨN: Ban đêm trăng thanh dịu mắt, ngàn sao lấp lánh!")
	
	# --------------------------------------------------------------------------
	# 2. KIỂM THỬ ĐIỀU KHIỂN THỜI GIAN & TUA NHANH QUA ĐÊM (NIGHT SKIP)
	# --------------------------------------------------------------------------
	print("\n[2] KIỂM TRA ĐIỀU KHIỂN & CƠ CHẾ TUA QUA ĐÊM (NIGHT SKIP):")
	var controller = DayNightControllerScript.new()
	root.add_child(controller)
	
	# Đặt giờ đêm 23:00
	controller.set_hour(23.0)
	assert(abs(controller.get_current_time_hours() - 23.0) < 0.01, "LỖI: Không đặt được 23:00!")
	print("  - Đã chuyển sang ban đêm: %.1fh" % controller.get_current_time_hours())
	
	# Kích hoạt tua nhanh qua đêm tới 06:00
	controller.skip_to_morning()
	assert(abs(controller.get_current_time_hours() - 6.0) < 0.01, "LỖI: Tua qua đêm phải đưa về 06:00 sáng!")
	print("  - Sau khi skip_to_morning: %.1fh (Đón bình minh thành công!)" % controller.get_current_time_hours())
	print("  ✅ ĐẠT CHUẨN: Cơ chế tua nhanh qua đêm (F5/T) hoạt động tức thì!")
	controller.queue_free()
	
	# --------------------------------------------------------------------------
	# 3. KIỂM THỬ TẢI MAIN_WORLD & KHÔNG GIAN BẢN ĐỒ 100% THIÊN NHIÊN
	# --------------------------------------------------------------------------
	print("\n[3] KIỂM TRA BẢN ĐỒ MAIN_WORLD CHỨA ĐẦY ĐỦ CẢNH QUAN 3D THIÊN NHIÊN:")
	var world_scene = load("res://scenes/core/main_world.tscn")
	var world = world_scene.instantiate()
	root.add_child(world)
	
	assert(world.has_node("DayNightController"), "LỖI: main_world thiếu DayNightController!")
	assert(world.has_node("NaturalLandscape"), "LỖI: main_world thiếu NaturalLandscape!")
	assert(world.has_node("WorldEnvironment"), "LỖI: main_world thiếu WorldEnvironment!")
	assert(world.has_node("DirectionalLight3D"), "LỖI: main_world thiếu DirectionalLight3D!")
	assert(world.has_node("Player"), "LỖI: main_world thiếu Player!")
	assert(not world.has_node("GrandBoulevard"), "LỖI: Không được có GrandBoulevard trong bản đồ thiên nhiên!")
	assert(not world.has_node("Structures"), "LỖI: Không được có Structures/tòa nhà trong bản đồ thiên nhiên!")
	assert(not world.has_node("ColossalMountain"), "LỖI: Không được có ColossalMountain cũ!")
	assert(not world.has_node("PlateauGround"), "LỖI: Không được có khối trụ tròn PlateauGround cũ!")
	
	var landscape = world.get_node("NaturalLandscape")
	print("  - Cụm Non Nước Tự Nhiên NaturalLandscape: Đã lắp ghép hoàn chỉnh (%d node con)" % landscape.get_child_count())
	print("  ✅ ĐẠT CHUẨN: Bản đồ 100% Thiên Nhiên Thuần Khiết (Không đĩa bay, không trụ nón, không nhà cửa, không đại lộ)!")
	
	world.queue_free()
	
	print("\n=================================================================")
	print("🎉 TẤT CẢ KIỂM THỬ CHU KỲ NGÀY - ĐÊM & BẢN ĐỒ ĐÃ ĐẠT 100% THÀNH CÔNG!")
	print("=================================================================")
	quit(0)
