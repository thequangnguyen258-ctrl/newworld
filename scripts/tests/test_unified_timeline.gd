extends SceneTree

# ==============================================================================
# TEST AUTOMATION: DÒNG THỜI GIAN THỐNG NHẤT LUÔN CHẢY VỀ PHÍA TRƯỚC (GODOT 4.6.2)
# Tuân thủ:
# - RULE 6: END_TO_END_INTERACTION_TESTING_STANDARD
# - RULE 12: PERSISTENT_UNIFIED_MONOTONIC_TIMELINE
# ==============================================================================

const DatabaseManagerScript = preload("res://scripts/simulation/database_manager.gd")
const WorldManagerScript = preload("res://scripts/core/world_manager.gd")
var UnifiedTimelineServerScript = load("res://addons/unified_timeline/unified_timeline_server.gd")

func _init() -> void:
	print("\n==================================================================")
	print("🧪 BẮT ĐẦU TEST: UNIFIED TIMELINE (DÒNG THỜI GIAN THỐNG NHẤT)")
	print("==================================================================")

	# --------------------------------------------------------------------------
	# 1. KHỞI TẠO HỆ THỐNG WORLD & DATABASE
	# --------------------------------------------------------------------------
	print("\n--- 1. KHỞI TẠO DATABASE & WORLD MANAGER ---")
	var db = root.get_node_or_null("DatabaseManager")
	if db == null:
		db = DatabaseManagerScript.new()
		root.add_child(db)
		db._init_database()

	var wm = root.get_node_or_null("WorldManager")
	if wm == null:
		wm = WorldManagerScript.new()
		root.add_child(wm)
		wm._ready()

	var timeline_server = root.get_node_or_null("UnifiedTimelineServer")
	if timeline_server == null:
		timeline_server = UnifiedTimelineServerScript.new()
		root.add_child(timeline_server)

	timeline_server._setup_timeline(db, wm)
	wm.timeline_server_ref = timeline_server

	assert(db.is_db_open, "Database SQLite phải mở thành công")
	assert(timeline_server.is_initialized, "UnifiedTimelineServer phải khởi tạo thành công")
	print(" [PASS] Khởi tạo DatabaseManager, WorldManager và UnifiedTimelineServer thành công.")

	# --------------------------------------------------------------------------
	# 2. KIỂM THỬ LƯU TRỮ VĨNH VIỄN VÀ BẢNG world_timeline
	# --------------------------------------------------------------------------
	print("\n--- 2. KIỂM THỬ BẢNG world_timeline TRONG SQLITE ---")
	timeline_server.save_timeline()
	var raw_db = db.get("db")
	assert(raw_db != null, "Raw DB phải tồn tại")
	raw_db.query("SELECT * FROM world_timeline WHERE id = 1;")
	var res = raw_db.query_result
	assert(res != null and not res.is_empty(), "Bảng world_timeline phải có bản ghi id=1")
	var row = res[0]
	print("  - Bản ghi timeline: Day=%d, %02d:%02d, TotalMin=%d, Sessions=%d" % [
		row["current_day_index"], row["current_hour"], row["current_minute"],
		row["total_game_minutes"], row["total_sessions"]
	])
	assert(int(row["current_hour"]) == wm.current_hour, "Giờ lưu phải khớp với WorldManager")
	assert(int(row["current_minute"]) == wm.current_minute, "Phút lưu phải khớp với WorldManager")
	print(" [PASS] Bảng world_timeline đã ghi nhận trạng thái đồng hồ thế giới chính xác.")

	# --------------------------------------------------------------------------
	# 3. KIỂM THỬ TÍNH ĐƠN ĐIỆU (STRICT MONOTONICITY INVARIANT)
	# --------------------------------------------------------------------------
	print("\n--- 3. KIỂM THỬ TÍNH ĐƠN ĐIỆU: KHÔNG BAO GIỜ LÙI GIỜ ---")
	# Đưa mốc giờ về buổi chiều (16:00) để bảo đảm thử thách lùi giờ luôn khách quan
	wm.set_time_of_day(16, 0)
	var prev_day = wm.current_day_index
	var prev_hour = wm.current_hour
	var prev_min = wm.current_minute
	var prev_total = timeline_server.total_game_minutes

	# Thử đặt giờ lùi: Đang 16:00 -> Thử đặt về 08:00 sáng
	print("  - Thử đặt giờ lùi: Hiện tại %s %02d:%02d -> Thử đặt về 08:00..." % [
		wm.DAY_NAMES[prev_day], prev_hour, prev_min
	])
	wm.set_time_of_day(8, 0)

	# Xác nhận: Ngày phải tự động tăng +1 (nhảy sang ngày tiếp theo, không quay về quá khứ)
	var expected_day = (prev_day + 1) % 7
	assert(wm.current_day_index == expected_day, "Lùi giờ phải tự động chuyển sang ngày tiếp theo (+1 ngày)")
	assert(wm.current_hour == 8 and wm.current_minute == 0, "Giờ mới phải là 08:00")
	assert(timeline_server.total_game_minutes > prev_total, "Tổng phút game luôn luôn phải tăng đơn điệu")
	print("  - Sau khi can thiệp: %s %02d:%02d (Tổng phút game: %d -> %d, +%d phút)" % [
		wm.DAY_NAMES[wm.current_day_index], wm.current_hour, wm.current_minute,
		prev_total, timeline_server.total_game_minutes, timeline_server.total_game_minutes - prev_total
	])
	print(" [PASS] Tính đơn điệu được bảo vệ 100%: Dòng thời gian tự động tiến sang ngày hôm sau.")

	# --------------------------------------------------------------------------
	# 4. KIỂM THỬ TIẾN TRÌNH NGOẠI TUYẾN (UNCAPPED OFFLINE CATCH-UP SIMULATION)
	# --------------------------------------------------------------------------
	print("\n--- 4. KIỂM THỬ TRÔI THỜI GIAN NGOẠI TUYẾN & TÍCH LŨY KINH TẾ ---")
	var initial_city_treasury = wm.treasury_city
	var initial_total_min = timeline_server.total_game_minutes

	# Giả lập người chơi tắt game trong 300 giây thực (5 phút thực = 100 phút game)
	var simulated_real_offline_sec: int = 300
	var expected_game_min: int = int(float(simulated_real_offline_sec) / timeline_server.REAL_SECONDS_PER_GAME_MINUTE)

	var yield_data = timeline_server._apply_offline_catchup(wm, db, expected_game_min, simulated_real_offline_sec)

	assert(timeline_server.total_game_minutes == initial_total_min + expected_game_min, "Tổng phút game phải cộng thêm 100 phút")
	assert(wm.treasury_city > initial_city_treasury, "Ngân khố đô thị phải nhận tiền thuế tích lũy ngoại tuyến")
	print("  - Tiến trình offline: +%d phút game, Thuế thu được: +%.2fĐ, Quỹ Bác ái: +%.2fĐ" % [
		expected_game_min, yield_data["city_tax_collected"], yield_data["church_tithe_collected"]
	])
	print(" [PASS] Cơ chế Offline Catch-Up mô phỏng trôi thời gian và thu hoạch kinh tế thành công.")

	# --------------------------------------------------------------------------
	# 5. KIỂM THỬ TUA NHANH QUA ĐÊM (NIGHT SKIP TO MORNING)
	# --------------------------------------------------------------------------
	print("\n--- 5. KIỂM THỬ TUA NHANH QUA ĐÊM (NIGHT SKIP) ---")
	wm.set_time_of_day(23, 15) # Chuyển sang 23:15 đêm
	var night_day = wm.current_day_index
	wm.skip_night_to_morning(6) # Đón bình minh 06:00

	assert(wm.current_hour == 6 and wm.current_minute == 0, "Sau khi skip phải là 06:00 sáng")
	assert(wm.current_day_index == (night_day + 1) % 7, "Qua đêm phải chuyển sang ngày tiếp theo")
	print("  - Đón bình minh thành công: %s 06:00 sáng!" % wm.DAY_NAMES[wm.current_day_index])
	print(" [PASS] Tua nhanh qua đêm tuân thủ 100% dòng thời gian thống nhất.")

	# --------------------------------------------------------------------------
	# 6. KIỂM THỬ THỐNG KÊ TIMELINE STATS & DỌN DẸP
	# --------------------------------------------------------------------------
	print("\n--- 6. KIỂM THỬ THỐNG KÊ TIMELINE VĨ MÔ ---")
	var stats = timeline_server.get_timeline_stats()
	assert(stats.has("total_game_minutes"), "Phải có trường total_game_minutes")
	assert(stats.has("total_sessions"), "Phải có trường total_sessions")
	print("  - Thống kê vĩ mô: %s" % str(stats))
	print(" [PASS] Thống kê dòng thời gian chính xác.")

	print("\n==================================================================")
	print("🎉 TOÀN BỘ CÁC BÀI TEST UNIFIED TIMELINE ĐÃ THÀNH CÔNG RỰC RỠ (100% PASS)!")
	print("==================================================================")
	if is_instance_valid(timeline_server):
		timeline_server.free()
	if is_instance_valid(wm):
		wm.free()
	if is_instance_valid(db):
		db.free()
	quit(0)
