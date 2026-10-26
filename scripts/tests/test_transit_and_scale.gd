extends SceneTree

const TransitNetworkManagerScript = preload("res://scripts/simulation/transit_network_manager.gd")

func _init() -> void:
	print("=================================================================")
	print("🧪 BẮT ĐẦU KIỂM THỬ: QUY MÔ 5 HUYỆN & GIAO THÔNG MẠNG NHỆN")
	print("=================================================================")
	
	var transit = TransitNetworkManagerScript.new()
	
	# 1. Kiểm tra vận tốc và thời gian di chuyển từ rìa ngoài (30km)
	var distance_km: float = 30.0
	
	var t_metro: float = transit.calculate_travel_time_minutes(distance_km, TransitNetworkManagerScript.TransitMode.METRO_EXPRESS, false)
	var t_car: float = transit.calculate_travel_time_minutes(distance_km, TransitNetworkManagerScript.TransitMode.CAR_MOTORBIKE, false)
	var t_bus: float = transit.calculate_travel_time_minutes(distance_km, TransitNetworkManagerScript.TransitMode.BUS, false)
	
	print("[1] KIỂM TRA THỜI GIAN DI CHUYỂN CỰ LY 30 KM:")
	print("  - Tàu ngầm Metro: %.2f phút (Kỳ vọng: 15-20 phút)" % t_metro)
	print("  - Ô tô / Xe máy:  %.2f phút (Kỳ vọng: đúng 30 phút)" % t_car)
	print("  - Xe bus BRT:     %.2f phút (Kỳ vọng: đúng 40 phút)" % t_bus)
	
	assert(t_metro >= 15.0 and t_metro <= 20.0, "LỖI: Thời gian Metro không nằm trong 15-20 phút!")
	assert(is_equal_approx(t_car, 30.0), "LỖI: Thời gian ô tô không đúng 30 phút!")
	assert(is_equal_approx(t_bus, 40.0), "LỖI: Thời gian xe bus không đúng 40 phút!")
	print("  ✅ ĐẠT CHUẨN: Metro 15-20p, Ô tô 30p, Bus 40p hoàn toàn chính xác!")
	
	# Kiểm tra xe đạp & đi bộ cho quy mô toàn tuyến (52km xe đạp, 50km đi bộ)
	var t_bike_hours: float = (52.0 / TransitNetworkManagerScript.SPEED_KMH[TransitNetworkManagerScript.TransitMode.BICYCLE])
	var t_walk_hours: float = (50.0 / TransitNetworkManagerScript.SPEED_KMH[TransitNetworkManagerScript.TransitMode.WALKING])
	print("  - Xe đạp xuyên vùng 52km: %.2f tiếng (Kỳ vọng: 4 tiếng)" % t_bike_hours)
	print("  - Đi bộ xuyên vùng 50km:  %.2f tiếng (Kỳ vọng: cả ngày / >= 12 tiếng)" % t_walk_hours)
	assert(is_equal_approx(t_bike_hours, 4.0), "LỖI: Thời gian xe đạp không đạt 4 tiếng!")
	assert(t_walk_hours >= 12.0, "LỖI: Đi bộ không đủ cả ngày!")
	print("  ✅ ĐẠT CHUẨN: Xe đạp đúng 4 tiếng, Đi bộ cả ngày (12.5 tiếng)!")

	# 2. Kiểm tra xác định 5 Huyện theo tọa độ
	print("\n[2] KIỂM TRA XÁC ĐỊNH ĐỊA BÀN 5 HUYỆN:")
	var core_district = transit.get_district_by_coord(Vector2(2.0, -3.0)) # R = 3.6km <= 7.5km
	var east_district = transit.get_district_by_coord(Vector2(25.0, 0.0)) # Đông
	var south_district = transit.get_district_by_coord(Vector2(0.0, 25.0)) # Nam
	var west_district = transit.get_district_by_coord(Vector2(-25.0, 0.0)) # Tây
	var north_district = transit.get_district_by_coord(Vector2(0.0, -25.0)) # Bắc
	
	print("  - Tọa độ (2, -3)km   -> %s (Kỳ vọng: DISTRICT_PLATEAU_CORE)" % core_district)
	print("  - Tọa độ (25, 0)km   -> %s (Kỳ vọng: DISTRICT_EAST_FARMS)" % east_district)
	print("  - Tọa độ (0, 25)km   -> %s (Kỳ vọng: DISTRICT_SOUTH_COAST)" % south_district)
	print("  - Tọa độ (-25, 0)km  -> %s (Kỳ vọng: DISTRICT_WEST_INDUSTRY)" % west_district)
	print("  - Tọa độ (0, -25)km  -> %s (Kỳ vọng: DISTRICT_NORTH_FOREST)" % north_district)
	
	assert(core_district == TransitNetworkManagerScript.DISTRICT_PLATEAU_CORE)
	assert(east_district == TransitNetworkManagerScript.DISTRICT_EAST_FARMS)
	assert(south_district == TransitNetworkManagerScript.DISTRICT_SOUTH_COAST)
	assert(west_district == TransitNetworkManagerScript.DISTRICT_WEST_INDUSTRY)
	assert(north_district == TransitNetworkManagerScript.DISTRICT_NORTH_FOREST)
	print("  ✅ ĐẠT CHUẨN: Cả 5 Huyện (1 Đỉnh Vát + 4 Chân Núi Ôm 4 Hướng) phân bổ chính xác!")

	# 3. Kiểm tra tính lộ trình Mạng Nhện đổ về Ga Lõi Trung Tâm
	print("\n[3] KIỂM TRA LỘ TRÌNH MẠNG NHỆN ĐỔ VỀ TÒA MEGA-OFFICE TRUNG TÂM:")
	var route_foothill = transit.calculate_route_to_central_hub(
		Vector2(25.0, 0.0), 
		TransitNetworkManagerScript.TransitMode.METRO_EXPRESS
	)
	print("  - Từ Chân núi Đông đi Metro: Quãng đường = %.1f km, Thời gian = %.1f phút in-game (%.1f giây thực)" % [
		route_foothill["distance_km"],
		route_foothill["travel_time_game_minutes"],
		route_foothill["travel_time_real_seconds"]
	])
	
	print("\n[4] KIỂM TRA MẠNG LƯỚI TÌNH NGUYỆN VIÊN HỖ TRỢ CHÚA (NHVC PART-TIME):")
	var JobRegistryScript = preload("res://scripts/simulation/building_job_registry.gd")
	var registry = JobRegistryScript.new()
	
	# Kiểm tra các vai trò tình nguyện viên không nhận lương
	assert(registry.is_volunteer_role("VOLUNTEER_DISTRICT_HEAD") == true, "LỖI: VOLUNTEER_DISTRICT_HEAD phải là vai trò tình nguyện!")
	assert(registry.is_volunteer_role("VOLUNTEER_TEAM_LEADER") == true, "LỖI: VOLUNTEER_TEAM_LEADER phải là vai trò tình nguyện!")
	assert(registry.is_volunteer_role("VOLUNTEER_CELL_LEADER") == true, "LỖI: VOLUNTEER_CELL_LEADER phải là vai trò tình nguyện!")
	assert(registry.is_volunteer_role("CHURCH_SHEPHERD") == false, "LỖI: CHURCH_SHEPHERD là vai trò Full-time, không phải tình nguyện!")
	
	# Kiểm tra chứng chỉ yêu cầu cho mạng lưới 4 cấp
	assert(registry.get_required_certificate("VOLUNTEER_DISTRICT_HEAD") == "CERT_DIVINE_SHEPHERD")
	assert(registry.get_required_certificate("VOLUNTEER_TEAM_LEADER") == "CERT_PASTORAL_COUNSELING")
	assert(registry.get_required_certificate("VOLUNTEER_CELL_LEADER") == "CERT_PASTORAL_COUNSELING")
	
	print("  - Hội Trưởng (Trưởng khu vực): Yêu cầu CERT_DIVINE_SHEPHERD")
	print("  - Nhóm Trưởng: Yêu cầu CERT_PASTORAL_COUNSELING")
	print("  - Tổ Trưởng: Yêu cầu CERT_PASTORAL_COUNSELING")
	print("  ✅ ĐẠT CHUẨN: Mạng lưới chăm sóc 4 cấp Tình Nguyện Viên (Hội trưởng -> Nhóm trưởng -> Tổ trưởng -> Thành viên) hoạt động chuẩn xác!")
	
	print("\n=================================================================")
	print("🎉 TẤT CẢ CÁC BÀI KIỂM THỬ ĐÃ VƯỢT QUA 100% THÀNH CÔNG!")
	print("=================================================================")
	
	registry.free()
	transit.free()
	quit(0)

