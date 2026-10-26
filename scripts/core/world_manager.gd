extends Node

# Autoload Singleton: WorldManager
signal time_ticked(day_index: int, hour: int, minute: int, day_name: String)
signal time_slot_changed(slot_id: int, slot_name: String, icon: String)
signal liturgy_started(day_name: String)
signal liturgy_ended(day_name: String)
signal treasury_updated(city_balance: float, church_balance: float)
signal fellowship_gathering_started(fellowship_name: String)
signal monthly_community_meetup_started(day_name: String)

const DailyScheduleManagerScript = preload("res://scripts/simulation/daily_schedule_manager.gd")

# Tỉ lệ thời gian vàng 1:20
# 1 ngày trong game = 72 phút thực (4320s)
# 1 giờ trong game = 3 phút thực (180s)
# 1 phút trong game = 3 giây thực
const REAL_SECONDS_PER_GAME_MINUTE: float = 3.0

const DAY_NAMES: Array[String] = [
	"Thứ Hai",
	"Thứ Ba",
	"Thứ Tư",     # Thánh Lễ 11:40 - 14:00
	"Thứ Năm",
	"Thứ Sáu",
	"Thứ Bảy",
	"Chủ Nhật"    # Thánh Lễ 11:40 - 14:00
]

# Trạng thái đồng hồ thế giới
var current_day_index: int = 2 # Khởi đầu vào Thứ Tư để dễ quan sát thánh lễ
var current_hour: int = 11
var current_minute: int = 30
var second_accumulator: float = 0.0

var is_liturgy_active: bool = false
var current_time_slot: int = -1

# Hai nguồn tài chính độc lập
var treasury_city: float = 50000.0     # Kho Bạc Đô Thị (Thuế thu nhập 5%, Thuế DN 5%)
var fund_tithe_church: float = 25000.0 # Quỹ 1/10 Dâng Chúa (Bác ái, cứu trợ, tiệc cộng đồng, NHVC)

func _ready() -> void:
	print("[WorldManager] Hệ thống Đồng Hồ Thế Giới & Quản Trị Đô Thị khởi tạo thành công.")
	treasury_updated.emit(treasury_city, fund_tithe_church)
	_check_time_slot_change()

func _process(delta: float) -> void:
	second_accumulator += delta
	if second_accumulator >= REAL_SECONDS_PER_GAME_MINUTE:
		second_accumulator -= REAL_SECONDS_PER_GAME_MINUTE
		_advance_one_minute()

func _advance_one_minute() -> void:
	current_minute += 1
	if current_minute >= 60:
		current_minute = 0
		current_hour += 1
		if current_hour >= 24:
			current_hour = 0
			current_day_index = (current_day_index + 1) % 7
			
	var server = _get_timeline_server()
	if server and server.has_method("on_game_minute_advanced"):
		server.on_game_minute_advanced()

	var day_name: String = DAY_NAMES[current_day_index]
	time_ticked.emit(current_day_index, current_hour, current_minute, day_name)
	
	_check_time_slot_change()
	_check_liturgy_schedule(day_name)
	_check_fellowship_schedule()

func _check_time_slot_change() -> void:
	var slot = DailyScheduleManagerScript.get_time_slot(current_hour, current_minute)
	if slot != current_time_slot:
		current_time_slot = slot
		var slot_name = DailyScheduleManagerScript.get_time_slot_name(slot)
		var slot_icon = DailyScheduleManagerScript.get_time_slot_icon(slot)
		time_slot_changed.emit(slot, slot_name, slot_icon)
		print("[WorldManager] %s CHUYỂN KHUNG GIỜ SINH HOẠT: %s (%02d:%02d)!" % [slot_icon, slot_name, current_hour, current_minute])


func _check_liturgy_schedule(day_name: String) -> void:
	# Thánh Lễ cố định: Thứ Tư (index 2) và Chủ Nhật (index 6) từ 11:40 đến 14:00
	var is_liturgy_day: bool = (current_day_index == 2 or current_day_index == 6)
	var time_in_minutes: int = (current_hour * 60) + current_minute
	var liturgy_start_min: int = (11 * 60) + 40 # 11:40
	var liturgy_end_min: int = (14 * 60) + 0    # 14:00
	
	if is_liturgy_day and time_in_minutes >= liturgy_start_min and time_in_minutes < liturgy_end_min:
		if not is_liturgy_active:
			is_liturgy_active = true
			liturgy_started.emit(day_name)
			print("[WorldManager] 🔔 CHUÔNG THÁNH ĐƯỜNG VANG VỌNG: Bắt đầu Thánh Lễ (%s %02d:%02d)!" % [day_name, current_hour, current_minute])
	else:
		if is_liturgy_active:
			is_liturgy_active = false
			liturgy_ended.emit(day_name)
			print("[WorldManager] 🕊️ KẾT THÚC THÁNH LỄ: Cư dân cùng dự Bữa tiệc Bác ái & trở lại công việc.")

func _check_fellowship_schedule() -> void:
	# Sinh hoạt 4 Hội Đoàn vào chiều Thứ Bảy (15:00 - 18:00)
	if current_day_index == 5 and current_hour == 15 and current_minute == 0:
		fellowship_gathering_started.emit("HỘI ĐOÀN ĐỒNG LOẠT SINH HOẠT")
		_check_monthly_community_meetup()

func _check_monthly_community_meetup() -> void:
	var server := _get_timeline_server()
	if server == null:
		return
	var week_number := int(server.get("total_game_minutes")) / (7 * 24 * 60)
	if week_number % 4 == 3:
		monthly_community_meetup_started.emit(DAY_NAMES[current_day_index])

func deposit_city_tax(amount: float) -> void:
	treasury_city = maxf(0.0, treasury_city + amount)
	treasury_updated.emit(treasury_city, fund_tithe_church)

func withdraw_city_budget(amount: float) -> bool:
	if amount < 0.0 or treasury_city < amount:
		return false
	treasury_city -= amount
	treasury_updated.emit(treasury_city, fund_tithe_church)
	return true

func withdraw_city_tax(amount: float) -> bool:
	return withdraw_city_budget(amount)

func deposit_church_tithe(amount: float) -> void:
	# QUY TẮC TỐI THƯỢNG: Quỹ Dâng Hiến hoàn toàn tự nguyện, không bao giờ ép buộc
	fund_tithe_church = maxf(0.0, fund_tithe_church + amount)
	treasury_updated.emit(treasury_city, fund_tithe_church)

func withdraw_church_tithe(amount: float) -> bool:
	if amount < 0.0 or fund_tithe_church < amount:
		return false
	fund_tithe_church -= amount
	treasury_updated.emit(treasury_city, fund_tithe_church)
	return true

func get_save_state() -> Dictionary:
	var server := _get_timeline_server()
	var total_game_minutes := int(server.get("total_game_minutes")) if server != null else -1
	return {
		"day_index": current_day_index,
		"hour": current_hour,
		"minute": current_minute,
		"second_accumulator": second_accumulator,
		"treasury_city": treasury_city,
		"fund_tithe_church": fund_tithe_church,
		"total_game_minutes": total_game_minutes
	}

func validate_saved_state(state: Dictionary) -> bool:
	var values: Array[String] = [
		"day_index", "hour", "minute", "second_accumulator",
		"treasury_city", "fund_tithe_church", "total_game_minutes"
	]
	for key in values:
		var value: Variant = state.get(key)
		if not (value is int or value is float) or not is_finite(float(value)):
			return false
	return (
		int(state["day_index"]) >= 0 and int(state["day_index"]) < DAY_NAMES.size()
		and int(state["hour"]) >= 0 and int(state["hour"]) < 24
		and int(state["minute"]) >= 0 and int(state["minute"]) < 60
		and float(state["second_accumulator"]) >= 0.0
		and float(state["second_accumulator"]) < REAL_SECONDS_PER_GAME_MINUTE
		and float(state["treasury_city"]) >= 0.0
		and float(state["fund_tithe_church"]) >= 0.0
		and int(state["total_game_minutes"]) >= -1
	)

func apply_saved_state(state: Dictionary) -> bool:
	if not validate_saved_state(state):
		return false
	current_day_index = int(state["day_index"])
	current_hour = int(state["hour"])
	current_minute = int(state["minute"])
	second_accumulator = float(state["second_accumulator"])
	treasury_city = float(state["treasury_city"])
	fund_tithe_church = float(state["fund_tithe_church"])
	var server := _get_timeline_server()
	if server != null and int(state["total_game_minutes"]) >= 0:
		server.set("total_game_minutes", int(state["total_game_minutes"]))
	is_liturgy_active = false
	current_time_slot = -1

	if server != null and server.has_method("save_timeline"):
		server.save_timeline()
	treasury_updated.emit(treasury_city, fund_tithe_church)
	time_ticked.emit(current_day_index, current_hour, current_minute, DAY_NAMES[current_day_index])
	_check_time_slot_change()
	_check_liturgy_schedule(DAY_NAMES[current_day_index])
	return true

func get_formatted_time() -> String:
	return "%s - %02d:%02d" % [DAY_NAMES[current_day_index], current_hour, current_minute]

func get_time_of_day_hours() -> float:
	return float(current_hour) + (float(current_minute) / 60.0) + (second_accumulator / REAL_SECONDS_PER_GAME_MINUTE) / 60.0

func set_time_of_day(hour: int, minute: int = 0) -> void:
	var target_h = clampi(hour, 0, 23)
	var target_m = clampi(minute, 0, 59)
	
	# Kiểm tra tính ĐƠN ĐIỆU (Monotonicity Invariant): Không bao giờ lùi giờ
	var cur_tod_min = (current_hour * 60) + current_minute
	var tgt_tod_min = (target_h * 60) + target_m
	var minutes_to_add: int = 0

	if tgt_tod_min > cur_tod_min:
		minutes_to_add = tgt_tod_min - cur_tod_min
	else:
		# Đích đến nhỏ hơn hoặc bằng mốc hiện tại -> tự động sang ngày hôm sau (+1 ngày)
		current_day_index = (current_day_index + 1) % 7
		minutes_to_add = (24 * 60 - cur_tod_min) + tgt_tod_min

	current_hour = target_h
	current_minute = target_m
	second_accumulator = 0.0

	var server = _get_timeline_server()
	if server:
		server.total_game_minutes += minutes_to_add
		if server.has_method("save_timeline"):
			server.save_timeline()

	var day_name: String = DAY_NAMES[current_day_index]
	time_ticked.emit(current_day_index, current_hour, current_minute, day_name)
	_check_time_slot_change()
	_check_liturgy_schedule(day_name)
	_check_fellowship_schedule()

func skip_night_to_morning(target_hour: int = 6) -> void:
	# Đón bình minh luôn đảm bảo dòng thời gian chảy về phía trước
	var cur_tod_min = (current_hour * 60) + current_minute
	var tgt_tod_min = (target_hour * 60)
	var minutes_to_add: int = 0

	if tgt_tod_min > cur_tod_min:
		minutes_to_add = tgt_tod_min - cur_tod_min
	else:
		current_day_index = (current_day_index + 1) % 7
		minutes_to_add = (24 * 60 - cur_tod_min) + tgt_tod_min

	current_hour = target_hour
	current_minute = 0
	second_accumulator = 0.0

	var server = _get_timeline_server()
	if server:
		server.total_game_minutes += minutes_to_add
		if server.has_method("save_timeline"):
			server.save_timeline()

	var day_name: String = DAY_NAMES[current_day_index]
	print("[WorldManager] 🌅 TUA NHANH QUA ĐÊM: Đã đón bình minh lúc %02d:00 (%s)!" % [target_hour, day_name])
	time_ticked.emit(current_day_index, current_hour, current_minute, day_name)
	_check_time_slot_change()
	_check_liturgy_schedule(day_name)
	_check_fellowship_schedule()

var timeline_server_ref: Node = null

func set_timeline_server(server: Node) -> void:
	timeline_server_ref = server

func _get_timeline_server() -> Node:
	# Tầng 1: Biến tham chiếu trực tiếp đã cache
	if timeline_server_ref != null and is_instance_valid(timeline_server_ref):
		return timeline_server_ref
	# Tầng 2: Engine Singleton
	if Engine.has_singleton("UnifiedTimelineServer"):
		timeline_server_ref = Engine.get_singleton("UnifiedTimelineServer")
		return timeline_server_ref
	# Tầng 3: SceneTree Root Autoload (/root/UnifiedTimelineServer)
	var tree = Engine.get_main_loop() as SceneTree
	if tree and tree.root:
		var node = tree.root.get_node_or_null("UnifiedTimelineServer")
		if node != null:
			timeline_server_ref = node
			return timeline_server_ref
	# Tầng 4: Node anh em trong cùng Parent (phục vụ Headless Test Runner)
	if is_inside_tree() and get_parent() != null:
		var sibling = get_parent().get_node_or_null("UnifiedTimelineServer")
		if sibling != null:
			timeline_server_ref = sibling
			return timeline_server_ref
	return null

func get_current_time_slot() -> int:
	return current_time_slot

func get_current_time_slot_name() -> String:
	return DailyScheduleManagerScript.get_time_slot_name(current_time_slot)

func get_current_time_slot_icon() -> String:
	return DailyScheduleManagerScript.get_time_slot_icon(current_time_slot)

func trigger_bell_ringing() -> void:
	var day_name: String = DAY_NAMES[current_day_index]
	is_liturgy_active = true
	liturgy_started.emit(day_name)
	print("[WorldManager] 🔔 CHUÔNG HÒA BÌNH ĐƯỢC RUNG BỞI THỊ TRƯỞNG (%s)!" % day_name)
