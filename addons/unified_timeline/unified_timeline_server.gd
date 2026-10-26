extends Node

# ==============================================================================
# UNIFIED TIMELINE SERVER (DÒNG THỜI GIAN THỐNG NHẤT LUÔN CHẢY VỀ PHÍA TRƯỚC)
# TÂN THẾ GIỚI - GODOT 4.6.2
# ==============================================================================
# Nguyên lý hoạt động:
# 1. ĐƠN ĐIỆU (Strict Monotonicity): Dòng thời gian không bao giờ quay ngược.
#    Nếu có lệnh đặt giờ lùi (ví dụ từ 23:00 về 06:00), hệ thống tự động cộng +1 ngày.
# 2. LƯU THƯỜNG TRỰC SQLITE: Lưu trạng thái đồng hồ và Unix Epoch vào bảng `world_timeline`.
# 3. TRÔI THỜI GIAN THỰC NGOẠI TUYẾN (Uncapped Real-Time Offline Catch-Up):
#    Khi mở game, tự động tính số giây thực tế vắng mặt (Time.get_unix_time_from_system() - last_unix)
#    Quy đổi theo tỷ lệ vàng 1:20 (3.0s thực = 1 phút game) và cập nhật kinh tế/công trình.
# ==============================================================================

signal timeline_advanced(elapsed_game_minutes: int, total_game_minutes: int)
signal offline_catchup_completed(offline_real_seconds: float, game_minutes_added: int, economic_yield: Dictionary)
signal timeline_saved(total_game_minutes: int)

const TABLE_NAME: String = "world_timeline"
const REAL_SECONDS_PER_GAME_MINUTE: float = 3.0

var total_game_minutes: int = 0
var last_real_unix_timestamp: int = 0
var total_sessions: int = 1
var is_initialized: bool = false
var auto_save_timer: float = 0.0
const AUTO_SAVE_INTERVAL: float = 15.0 # Tự động ghi vào SQLite mỗi 15 giây thực

var cached_db: Node = null
var cached_wm: Node = null

func _ready() -> void:
	if not Engine.has_singleton("UnifiedTimelineServer"):
		Engine.register_singleton("UnifiedTimelineServer", self)
	call_deferred("_setup_timeline")

func _exit_tree() -> void:
	save_timeline()
	if Engine.has_singleton("UnifiedTimelineServer"):
		Engine.unregister_singleton("UnifiedTimelineServer")

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		save_timeline()

func _process(delta: float) -> void:
	if not is_initialized:
		return
	auto_save_timer += delta
	if auto_save_timer >= AUTO_SAVE_INTERVAL:
		auto_save_timer = 0.0
		save_timeline()

func _setup_timeline(override_db: Node = null, override_wm: Node = null) -> void:
	cached_db = override_db if override_db != null else _get_database_manager()
	cached_wm = override_wm if override_wm != null else _get_world_manager()
	if cached_db == null or cached_wm == null:
		return

	cached_wm.set("timeline_server_ref", self)
	_ensure_schema(cached_db)
	_load_or_create_timeline(cached_db, cached_wm)
	is_initialized = true

func _ensure_schema(db: Node) -> void:
	if not db.get("is_db_open"):
		return
	var raw_db = db.get("db")
	if raw_db == null:
		return

	var sql = """
	CREATE TABLE IF NOT EXISTS %s (
		id INTEGER PRIMARY KEY CHECK (id = 1),
		total_game_minutes INTEGER NOT NULL DEFAULT 0,
		current_day_index INTEGER NOT NULL DEFAULT 2,
		current_hour INTEGER NOT NULL DEFAULT 11,
		current_minute INTEGER NOT NULL DEFAULT 30,
		second_accumulator REAL NOT NULL DEFAULT 0.0,
		last_real_unix_timestamp INTEGER NOT NULL DEFAULT 0,
		last_updated_iso TEXT DEFAULT CURRENT_TIMESTAMP,
		total_sessions INTEGER NOT NULL DEFAULT 1,
		total_offline_catchup_seconds REAL NOT NULL DEFAULT 0.0
	);
	""" % TABLE_NAME
	raw_db.query(sql)

func _load_or_create_timeline(db: Node, wm: Node) -> void:
	var raw_db = db.get("db")
	if raw_db == null:
		return

	var current_unix: int = int(Time.get_unix_time_from_system())
	raw_db.query("SELECT * FROM %s WHERE id = 1 LIMIT 1;" % TABLE_NAME)
	var records = raw_db.query_result

	if records == null or records.is_empty():
		# Lần đầu tiên khởi tạo thế giới Tân Thế Giới
		total_game_minutes = (wm.current_day_index * 24 * 60) + (wm.current_hour * 60) + wm.current_minute
		last_real_unix_timestamp = current_unix
		total_sessions = 1

		var insert_sql = """
		INSERT INTO %s (
			id, total_game_minutes, current_day_index, current_hour,
			current_minute, second_accumulator, last_real_unix_timestamp, total_sessions
		) VALUES (
			1, %d, %d, %d, %d, %.2f, %d, %d
		);
		""" % [
			TABLE_NAME, total_game_minutes, wm.current_day_index,
			wm.current_hour, wm.current_minute, wm.second_accumulator,
			current_unix, total_sessions
		]
		raw_db.query(insert_sql)
		print("[UnifiedTimelineServer] 🌟 Khởi tạo Dòng Thời Gian Mới: %s %02d:%02d (Tổng %d phút game)." % [
			wm.DAY_NAMES[wm.current_day_index], wm.current_hour, wm.current_minute, total_game_minutes
		])
	else:
		# Đã có dữ liệu từ các phiên chơi hoặc bài test trước
		var row = records[0]
		total_game_minutes = int(row.get("total_game_minutes", 0))
		var saved_day_idx = int(row.get("current_day_index", 2))
		var saved_hour = int(row.get("current_hour", 11))
		var saved_min = int(row.get("current_minute", 30))
		var saved_sec = float(row.get("second_accumulator", 0.0))
		var prev_unix = int(row.get("last_real_unix_timestamp", current_unix))
		total_sessions = int(row.get("total_sessions", 1)) + 1

		# Thiết lập lại trạng thái đồng hồ trong WorldManager
		wm.current_day_index = saved_day_idx
		wm.current_hour = saved_hour
		wm.current_minute = saved_min
		wm.second_accumulator = saved_sec

		# Tính toán khoảng cách thời gian ngoại tuyến (Offline Catch-Up)
		var elapsed_real_sec: int = maxi(0, current_unix - prev_unix)
		last_real_unix_timestamp = current_unix

		if elapsed_real_sec > 0:
			var added_game_minutes: int = int(float(elapsed_real_sec) / REAL_SECONDS_PER_GAME_MINUTE)
			if added_game_minutes > 0:
				var economic_yield = _apply_offline_catchup(wm, db, added_game_minutes, elapsed_real_sec)
				offline_catchup_completed.emit(float(elapsed_real_sec), added_game_minutes, economic_yield)
				print("[UnifiedTimelineServer] ⏩ ĐÃ TRÔI QUA NGOẠI TUYẾN: %d giây thực -> +%d phút game (Kinh tế: +%.2fĐ thuế)!" % [
					elapsed_real_sec, added_game_minutes, economic_yield.get("city_tax_collected", 0.0)
				])
		
		# Cập nhật số phiên và mốc hiện tại vào SQLite
		save_timeline()
		print("[UnifiedTimelineServer] ⏳ Dòng thời gian nối tiếp: %s %02d:%02d (Phiên thứ #%d | Tổng %d phút game)." % [
			wm.DAY_NAMES[wm.current_day_index], wm.current_hour, wm.current_minute, total_sessions, total_game_minutes
		])

## Áp dụng tiến trình mô phỏng ngoại tuyến (Offline Catch-Up Simulation)
func _apply_offline_catchup(wm: Node, db: Node, added_minutes: int, real_seconds: int) -> Dictionary:
	total_game_minutes += added_minutes

	# Tính toán lại ngày, giờ, phút mới
	var current_total_day_minutes = (wm.current_hour * 60) + wm.current_minute + added_minutes
	var days_passed: int = current_total_day_minutes / (24 * 60)
	var remainder_minutes: int = current_total_day_minutes % (24 * 60)

	wm.current_day_index = (wm.current_day_index + days_passed) % 7
	wm.current_hour = remainder_minutes / 60
	wm.current_minute = remainder_minutes % 60
	wm.second_accumulator = 0.0

	# Kích hoạt cập nhật khung giờ sinh hoạt & phụng vụ mới
	var day_name = wm.DAY_NAMES[wm.current_day_index]
	wm.time_ticked.emit(wm.current_day_index, wm.current_hour, wm.current_minute, day_name)
	wm._check_time_slot_change()
	wm._check_liturgy_schedule(day_name)
	wm._check_fellowship_schedule()

	# Tính toán sản lượng kinh tế tự động tích lũy trong thời gian offline
	var tax_yield: float = 0.0
	var tithe_yield: float = 0.0
	var raw_db = db.get("db")
	if raw_db != null:
		# Tính thuế từ các doanh nghiệp phồn vinh (mỗi ngày game ~ 150Đ thuế/doanh nghiệp)
		raw_db.query("SELECT COUNT(*) as enterprise_count FROM enterprises WHERE status = 'PROSPEROUS';")
		var ent_res = raw_db.query_result
		var enterprise_count: int = 1
		if ent_res != null and not ent_res.is_empty():
			enterprise_count = maxi(1, int(ent_res[0].get("enterprise_count", 1)))
		
		var effective_days = float(added_minutes) / (24.0 * 60.0)
		tax_yield = effective_days * float(enterprise_count) * 150.0
		tithe_yield = tax_yield * 0.10 # 10% trích lập Quỹ 1/10 Bác ái

		wm.deposit_city_tax(tax_yield)
		wm.deposit_church_tithe(tithe_yield)

		db.log_transaction(
			wm.current_day_index, wm.current_hour, wm.current_minute,
			"THUẾ_TÍCH_LŨY_NGOẠI_TUYẾN", tax_yield, "CITY_TREASURY",
			"Tự động thu thuế %d phút game trôi qua khi người chơi offline" % added_minutes
		)

	# Đồng bộ tiến trình Nghiên cứu & Phát triển HAS (Offline R&D Progress Catch-Up)
	var research_kbu_yield: int = 0
	var research_mgr = get_node_or_null("/root/ResearchManager")
	if research_mgr != null and research_mgr.has_method("apply_offline_research_progress"):
		research_mgr.apply_offline_research_progress(added_minutes)
		research_kbu_yield = added_minutes * 10

	return {
		"days_passed": days_passed,
		"added_game_minutes": added_minutes,
		"city_tax_collected": tax_yield,
		"church_tithe_collected": tithe_yield,
		"research_kbu_yield": research_kbu_yield
	}

## Tiến tới một mốc thời gian đảm bảo tính ĐƠN ĐIỆU (Strict Monotonic Advance)
func advance_monotonically(target_hour: int, target_minute: int = 0) -> Dictionary:
	var wm = cached_wm if cached_wm != null else _get_world_manager()
	if wm == null:
		return {}

	target_hour = clampi(target_hour, 0, 23)
	target_minute = clampi(target_minute, 0, 59)

	var current_tod_min: int = (wm.current_hour * 60) + wm.current_minute
	var target_tod_min: int = (target_hour * 60) + target_minute

	var minutes_to_add: int = 0
	var days_to_add: int = 0

	if target_tod_min > current_tod_min:
		# Đích đến ở sau trong cùng một ngày
		minutes_to_add = target_tod_min - current_tod_min
	else:
		# Đích đến nhỏ hơn hoặc bằng giờ hiện tại -> BẮT BUỘC nhảy sang ngày hôm sau (+1 ngày)
		days_to_add = 1
		minutes_to_add = (24 * 60 - current_tod_min) + target_tod_min

	wm.current_day_index = (wm.current_day_index + days_to_add) % 7
	wm.current_hour = target_hour
	wm.current_minute = target_minute
	wm.second_accumulator = 0.0

	total_game_minutes += minutes_to_add
	timeline_advanced.emit(minutes_to_add, total_game_minutes)

	var day_name = wm.DAY_NAMES[wm.current_day_index]
	wm.time_ticked.emit(wm.current_day_index, wm.current_hour, wm.current_minute, day_name)
	wm._check_time_slot_change()
	wm._check_liturgy_schedule(day_name)
	wm._check_fellowship_schedule()

	save_timeline()

	return {
		"minutes_added": minutes_to_add,
		"days_added": days_to_add,
		"new_day_name": day_name,
		"new_hour": target_hour,
		"new_minute": target_minute,
		"total_game_minutes": total_game_minutes
	}

## Lưu trạng thái dòng thời gian vào SQLite
func save_timeline() -> void:
	var db = cached_db if cached_db != null else _get_database_manager()
	var wm = cached_wm if cached_wm != null else _get_world_manager()
	if db == null or wm == null:
		return
	var raw_db = db.get("db")
	if raw_db == null or not db.get("is_db_open"):
		return

	var current_unix: int = int(Time.get_unix_time_from_system())
	last_real_unix_timestamp = current_unix

	var update_sql = """
	UPDATE %s SET
		total_game_minutes = %d,
		current_day_index = %d,
		current_hour = %d,
		current_minute = %d,
		second_accumulator = %.2f,
		last_real_unix_timestamp = %d,
		last_updated_iso = CURRENT_TIMESTAMP,
		total_sessions = %d
	WHERE id = 1;
	""" % [
		TABLE_NAME, total_game_minutes, wm.current_day_index,
		wm.current_hour, wm.current_minute, wm.second_accumulator,
		current_unix, total_sessions
	]
	raw_db.query(update_sql)
	timeline_saved.emit(total_game_minutes)

## Tăng 1 phút game (được gọi từ WorldManager._advance_one_minute)
func on_game_minute_advanced() -> void:
	total_game_minutes += 1

func get_total_game_days() -> int:
	return total_game_minutes / (24 * 60)

func get_timeline_stats() -> Dictionary:
	var wm = cached_wm if cached_wm != null else _get_world_manager()
	return {
		"total_game_minutes": total_game_minutes,
		"total_game_days": get_total_game_days(),
		"total_sessions": total_sessions,
		"last_real_unix_timestamp": last_real_unix_timestamp,
		"formatted_time": wm.get_formatted_time() if wm else "N/A"
	}

func _get_world_manager() -> Node:
	if Engine.has_singleton("WorldManager"):
		return Engine.get_singleton("WorldManager")
	if is_inside_tree():
		var tree = get_tree()
		if tree and tree.root and tree.root.has_node("WorldManager"):
			return tree.root.get_node("WorldManager")
	return null

func _get_database_manager() -> Node:
	if Engine.has_singleton("DatabaseManager"):
		return Engine.get_singleton("DatabaseManager")
	if is_inside_tree():
		var tree = get_tree()
		if tree and tree.root and tree.root.has_node("DatabaseManager"):
			return tree.root.get_node("DatabaseManager")
	return null
