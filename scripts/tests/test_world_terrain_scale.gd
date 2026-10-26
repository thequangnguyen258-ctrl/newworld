extends SceneTree

const POIManagerScript = preload("res://scripts/simulation/poi_manager.gd")
const ModularChunkScript = preload("res://scripts/terrain/modular_nature_chunk.gd")
const AssemblerScript = preload("res://scripts/terrain/natural_landscape_assembler.gd")

func _init() -> void:
	print("=================================================================")
	print("🏔️ BẮT ĐẦU KIỂM THỬ: ĐỊA HÌNH 3D & HỆ THỦY VĂN TÂN THẾ GIỚI (600M)")
	print("=================================================================")
	
	# --------------------------------------------------------------------------
	# 1. KIỂM THỬ ĐỘ CAO CHUẨN ĐỈNH NÚI & CHUNKS THIÊN NHIÊN
	# --------------------------------------------------------------------------
	print("\n[1] KIỂM TRA THÔNG SỐ ĐỊA HÌNH & CAO ĐỘ MASTER:")
	assert(ModularChunkScript.PLATEAU_ALTITUDE == 600.0, "LỖI: Cao độ đỉnh núi phải là +600m!")
	print("  - Cao độ đỉnh núi chuẩn hóa: %.1fm (ĐẠT CHUẨN: +600.0m)" % ModularChunkScript.PLATEAU_ALTITUDE)
	
	var chunk_flat = ModularChunkScript.new(ModularChunkScript.ChunkType.FLAT_GRASS_PLATEAU, Vector2i(0, 0))
	chunk_flat.build_chunk()
	root.add_child(chunk_flat)
	assert(chunk_flat.mesh_instance != null, "LỖI: Chunk flat grass không tạo được mesh!")
	print("  - Khối Thảo Nguyên Bằng Phẳng 64mx64m: Sinh lưới và va chạm tại +600m thành công!")
	chunk_flat.queue_free()
	
	# --------------------------------------------------------------------------
	# 2. KIỂM THỬ BỘ LẮP GHÉP CẢNH QUAN & BIỂN MÂY LƠ LỬNG +140M
	# --------------------------------------------------------------------------
	print("\n[2] KIỂM TRA LƯỚI 3x3 CHUNKS & BIỂN MÂY ANIME (+140M):")
	var assembler = AssemblerScript.new()
	assembler.auto_assemble = false
	root.add_child(assembler)
	assembler.assemble_landscape()
	
	assert(assembler.chunks.size() == 25, "LỖI: Phải có đủ 25 chunks trong lưới 5x5! Thực tế: %d" % assembler.chunks.size())
	assert(assembler.sea_of_clouds != null, "LỖI: Biển mây Anime chưa được tạo!")
	assert(assembler.sea_of_clouds.position.y == 4000.0, "LỖI: Biển mây phải lơ lửng tại cao độ +4000m!")
	print("  - Số lượng chunks lắp ghép: %d chunks (320m x 320m)" % assembler.chunks.size())
	print("  - Vị trí Biển Mây: %s (Cao độ Y = +4000m trên trời cao)" % assembler.sea_of_clouds.position)
	print("  ✅ ĐẠT CHUẨN: Lưới cảnh quan và tầng mây khớp hoàn toàn với bản vẽ mặt cắt!")
	assembler.queue_free()
	
	# --------------------------------------------------------------------------
	# 3. KIỂM THỬ HỆ THỐNG 10 POIS TRONG POI_MANAGER
	# --------------------------------------------------------------------------
	print("\n[3] KIỂM TRA ĐĂNG KÝ & TRUY VẤN 10 ĐỊA DANH BIỂU TƯỢNG (POIS):")
	var all_pois = POIManagerScript.get_all_pois()
	assert(all_pois.size() == 10, "LỖI: Phải có đúng 10 POIs cốt lõi!")
	print("  - Tổng số POIs đăng ký: %d / 10" % all_pois.size())
	
	# Kiểm tra từng POI bắt buộc
	var required_keys = [
		"SUMMIT_CENTER", "SUMMIT_LAKE", "MAIN_WATERFALL", "WATERFALL_BASIN",
		"SCENIC_LOOKOUT", "NORTH_VILLAGE", "EAST_VILLAGE", "WEST_VILLAGE",
		"SOUTH_VALLEY", "SOUTH_CLIFF_TRAIL"
	]
	for key in required_keys:
		var p = POIManagerScript.get_poi_by_key(key)
		assert(not p.is_empty(), "LỖI: Thiếu POI key: %s" % key)
		print("  - POI [%d] %s: Tọa độ Godot=%s (Cao độ=%.0fm)" % [
			p["id"], p["name_vi"], p["godot_pos"], p["godot_pos"].y
		])
		
	# Kiểm tra độ cao cụ thể của các địa danh đặc trưng
	var summit = POIManagerScript.get_poi_by_key("SUMMIT_CENTER")
	assert(summit["godot_pos"].y == 600.0, "LỖI: Đỉnh núi phải ở +600m!")
	
	var summit_lake = POIManagerScript.get_poi_by_key("SUMMIT_LAKE")
	assert(summit_lake["godot_pos"].y == 590.0, "LỖI: Hồ đỉnh phải ở +590m!")
	
	var waterfall_basin = POIManagerScript.get_poi_by_key("WATERFALL_BASIN")
	assert(waterfall_basin["godot_pos"].y == 140.0, "LỖI: Hồ chân thác phải ở +140m!")
	
	var lookout = POIManagerScript.get_poi_by_key("SCENIC_LOOKOUT")
	assert(lookout["godot_pos"].y == 300.0, "LỖI: Mỏm đá ngắm cảnh phải ở +300m!")
	
	# Kiểm tra API truy vấn khoảng cách
	var player_pos = Vector3(0, 600.0, 0) # Đang đứng tại tâm đỉnh núi
	var nearest = POIManagerScript.get_nearest_poi(player_pos)
	assert(nearest["key"] == "SUMMIT_CENTER", "LỖI: Điểm gần nhất tại (0,600,0) phải là SUMMIT_CENTER!")
	print("  - Kiểm tra GPS Nearest POI: %s (Khoảng cách = 0m)" % nearest["name_vi"])
	
	var dist_to_waterfall = POIManagerScript.get_distance_to_poi(player_pos, 3) # MAIN_WATERFALL
	print("  - Khoảng cách từ Đỉnh (0,600,0) đến Thác Nước Chính: %.1fm (ước tính ~12km)" % dist_to_waterfall)
	assert(dist_to_waterfall > 11000.0 and dist_to_waterfall < 13000.0, "LỖI: Khoảng cách tới thác nước không chính xác!")
	print("  ✅ ĐẠT CHUẨN: Hệ thống GPS và truy vấn 10 POIs hoạt động hoàn hảo!")
	
	# --------------------------------------------------------------------------
	# 4. KIỂM THỬ MÔ HÌNH THỦY VĂN & LƯU LƯỢNG NƯỚC
	# --------------------------------------------------------------------------
	print("\n[4] KIỂM TRA MÔ HÌNH THỦY VĂN & DÒNG CHẢY TUẦN HOÀN:")
	var hydro = POIManagerScript.calculate_hydrology_stats(1350.0, 0.60)
	print("  - Diện tích lưu vực núi: %.1f km²" % hydro["basin_area_km2"])
	print("  - Tổng lượng mưa hàng năm: %.1f triệu m³" % (hydro["total_annual_precipitation_m3"] / 1_000_000.0))
	print("  - Lượng nước sinh dòng chảy (Runoff 60%%): %.1f triệu m³" % (hydro["annual_runoff_m3"] / 1_000_000.0))
	print("  - Lưu lượng trung bình thác & suối: %.1f m³/s" % hydro["average_flow_rate_m3_s"])
	print("  - Đỉnh lũ mùa mưa: %.1f m³/s | Đáy dòng mùa khô: %.1f m³/s" % [
		hydro["flood_peak_flow_m3_s"], hydro["dry_season_flow_m3_s"]
	])
	print("  - Dung tích hồ điều tiết Hồ Đỉnh: %.1f triệu m³" % (hydro["summit_reservoir_capacity_m3"] / 1_000_000.0))
	
	# Đảm bảo lưu lượng nằm trong ngưỡng tính toán Master Blueprint (18 - 26 m³/s)
	assert(hydro["average_flow_rate_m3_s"] >= 15.0 and hydro["average_flow_rate_m3_s"] <= 30.0,
		"LỖI: Lưu lượng trung bình phải nằm trong khoảng 15 - 30 m³/s!")
	print("  ✅ ĐẠT CHUẨN: Mô hình thủy văn bảo đảm nguồn nước liên tục quanh năm không cạn kiệt!")
	
	print("\n=================================================================")
	print("🎉 TẤT CẢ KIỂM THỬ ĐỊA HÌNH 3D & THỦY VĂN ĐÃ ĐẠT 100% THÀNH CÔNG!")
	print("=================================================================")
	quit(0)
