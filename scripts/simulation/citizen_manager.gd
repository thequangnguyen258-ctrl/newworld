class_name CitizenManager
extends Node

signal citizen_population_updated(total: int)
signal weekly_driver_changed(job_role: String, citizen_id: String, citizen_name: String, week_number: int)
signal monthly_community_meetup_started(supported_citizens: int)

# Giai đoạn 1: 300 cư dân đầu tiên tập trung ở Thủ Phủ; chưa mở rộng ngoại ô.
const POPULATION_CAP_PHASE_1: int = 300
const POPULATION_CAP_PHASE_2: int = 300
const CAPITAL_DISTRICT_ID: String = "DISTRICT_PLATEAU_CORE"

const VIETNAMESE_SURNAMES: Array[String] = [
	"Nguyễn", "Trần", "Lê", "Phạm", "Hoàng", "Huỳnh", "Vũ", "Đặng", "Bùi", "Đỗ", "Hồ",
	"Ngô", "Dương", "Lý", "Mai", "Tạ", "Phan", "Võ", "Quách", "Tô", "Cao", "Lâm",
	"Đinh", "Trịnh", "Mạc", "Nông", "Đoàn", "Tăng", "La", "Khương", "Thạch", "Bành",
	"Chu", "Lương", "Triệu", "Tống", "Cung", "Hà", "Hứa", "Ngụy", "Âu", "Thân", "Châu",
	"Phùng", "Đào", "Kim", "Khuất", "Mã", "Sinh", "Nhiêu", "Nhữ", "Đậu", "Lữ", "Văn"
]

const VIETNAMESE_GIVEN_NAMES: Array[String] = [
	"An", "Ánh", "Bảo", "Bình", "Chi", "Chinh", "Dân", "Diễm", "Dũng", "Giang", "Hà",
	"Hải", "Hạnh", "Hiếu", "Hoài", "Hồng", "Huy", "Khang", "Khánh", "Lan", "Linh",
	"Long", "Mạnh", "Mai", "Minh", "Nam", "Nhi", "Nhân", "Ninh", "Phúc", "Phương",
	"Quân", "Quỳnh", "Sang", "Tài", "Thảo", "Thiện", "Thu", "Thư", "Tiến", "Tuấn",
	"Tú", "Uyên", "Vân", "Việt", "Vinh", "Yến", "Yên", "Anh", "Tâm", "Hòa"
]

const VIETNAMESE_SECOND_NAMES: Array[String] = [
	"Hương", "Lệ", "Mai", "Nhi", "Phúc", "Quang", "Thảo", "Thịnh", "Trâm", "Uyên",
	"Vân", "Xuân", "Yến", "An", "Bình", "Duy", "Hà", "Lan", "Linh", "Nhu", "Phi",
	"Tâm", "Tùng", "Việt", "Vinh", "Hòa", "Khang", "Ngọc", "Thanh", "Diệu", "Tân"
]

@export var is_phase_2_unlocked: bool = false
@export var current_population_cap: int = POPULATION_CAP_PHASE_1
@export var is_reproduction_halted: bool = false
var is_monthly_meetup_active: bool = false
var current_driver_week: int = -1

var citizen_registry: Dictionary = {} # citizen_id -> CitizenData

var fellowship_registry: Dictionary = {
	"AU_NHI": [],
	"THANH_NIEN": [],
	"PHU_NU": [],
	"TRANG_NIEN": []
}

func _ready() -> void:
	add_to_group("citizen_manager")
	_generate_initial_citizens()
	_connect_world_signals()

func _connect_world_signals() -> void:
	var wm = get_node_or_null("/root/WorldManager")
	if wm:
		wm.liturgy_started.connect(_on_liturgy_started)
		wm.liturgy_ended.connect(_on_liturgy_ended)
		if wm.has_signal("time_ticked"):
			wm.time_ticked.connect(_on_world_time_ticked)
		if wm.has_signal("monthly_community_meetup_started"):
			wm.monthly_community_meetup_started.connect(_on_monthly_community_meetup_started)

func _generate_initial_citizens() -> void:
	citizen_registry.clear()
	for key in fellowship_registry.keys():
		fellowship_registry[key].clear()

	var total_people: int = POPULATION_CAP_PHASE_1
	for index in range(total_people):
		var name_text = _build_vietnamese_name(index)
		var age_value = _build_age_for_index(index)
		var married_flag = false
		var c = CitizenData.new(str(1000 + index), name_text, age_value)
		c.is_married = married_flag
		c.needs_community_support = index % 17 == 0
		c.home_district_id = CAPITAL_DISTRICT_ID
		c.workplace_district_id = CAPITAL_DISTRICT_ID
		c.preferred_transit_mode = 0 if age_value < 18 else 3
		c.home_coord_km = Vector2(
			(float(index % 18) - 8.5) * 0.8,
			((float(index) / 18.0) - 8.0) * 0.8
		)
		c.job_role = _build_job_for_index(index)
		c.workplace_id = _build_workplace_id(c.job_role)
		c.salary = 350.0 + (float(index % 8) * 25.0)
		c.wallet = 600.0 + (float(index % 5) * 120.0)
		c.is_church_servant = (
			age_value >= 18
			and index >= 8
			and index % 13 == 0
			and c.job_role != "Thợ máy xe tải"
		)
		if c.is_church_servant:
			if index % 39 == 0:
				c.servant_type = "FULL_TIME"
				c.job_role = "NHVC toàn thời gian"
				c.workplace_id = "CAPITAL_MEGA_OFFICE"
				c.salary = 600.0
				c.wallet = 1100.0
			else:
				c.servant_type = "PART_TIME"
				# Rule #4: Tình nguyện viên Bán thời gian nhận lương từ nghề nghiệp thế tục, không ghi đè salary = 320.0
				c.wallet = 700.0
		else:
			c.servant_type = "NONE"
		c.certificates = _build_certificates_for_index(index)
		c.update_life_stage()
		register_citizen(c)

	_assign_households_and_relationships()
	_rebuild_fellowship_registry()
	citizen_population_updated.emit(citizen_registry.size())
	print("[CitizenManager] Khởi tạo %d cư dân Thủ Phủ với danh sách họ tên Việt Nam và quy chuẩn tuổi mới." % citizen_registry.size())
	if is_inside_tree():
		var logistics_manager := get_node_or_null("/root/LogisticsManager")
		if logistics_manager != null and logistics_manager.has_method("initialize_capital_industry"):
			logistics_manager.call("initialize_capital_industry", citizen_registry)

	_sync_citizens_to_database()

func _sync_citizens_to_database() -> void:
	if not is_inside_tree():
		return
	var db_mgr = get_node_or_null("/root/DatabaseManager")
	if db_mgr:
		db_mgr.sync_citizens_batch(citizen_registry)

func _rebuild_fellowship_registry() -> void:
	for k in fellowship_registry.keys():
		fellowship_registry[k].clear()
	for cid in citizen_registry.keys():
		var c: CitizenData = citizen_registry[cid]
		c.update_life_stage()
		var fg: String = c.fellowship_group
		if fellowship_registry.has(fg):
			fellowship_registry[fg].append(cid)

func _build_vietnamese_name(index: int) -> String:
	var surname = VIETNAMESE_SURNAMES[index % VIETNAMESE_SURNAMES.size()]
	var given_name = VIETNAMESE_GIVEN_NAMES[(index * 3 + 7) % VIETNAMESE_GIVEN_NAMES.size()]
	var second_name = VIETNAMESE_SECOND_NAMES[(index * 5 + 11) % VIETNAMESE_SECOND_NAMES.size()]
	if index % 4 == 0:
		return "%s %s %s" % [surname, given_name, second_name]
	return "%s %s" % [surname, given_name]

func _build_age_for_index(index: int) -> int:
	var representative_ages: Array[int] = [46, 27, 24, 25, 46, 33, 17, 9]
	if index < representative_ages.size():
		return representative_ages[index]
	if index % 6 == 0:
		return 8 + (index % 10)
	if index % 3 == 0:
		return 18 + ((index * 7) % 12)
	return 24 + ((index * 3) % 23)

func _build_job_for_index(index: int) -> String:
	var representative_jobs: Array[String] = [
		"Nông dân", "Thợ mộc", "Kỹ sư", "Bác sĩ", "Thợ gốm", "Giáo viên", "Sinh viên", "Học sinh"
	]
	if index < representative_jobs.size():
		return representative_jobs[index]
	if _build_age_for_index(index) < 18:
		return "Học sinh"
	match index:
		20:
			return "Tài xế xe tải nhẹ"
		21:
			return "Tài xế xe tải trung"
		22:
			return "Tài xế xe container"
		23:
			return "Tài xế xe siêu trường"
		25:
			return "Quản lý đội xe"
		26:
			return "Thợ máy xe tải"
		27:
			return "Điều phối viên logistics"
	if index % 29 == 0:
		return "Lái xe bus"
	if index % 31 == 0:
		return "Lái tàu điện"
	var jobs: Array[String] = [
		"Nông dân", "Công nhân", "Nhân viên văn phòng", "Bác sĩ", "Nhà bếp", "Giáo viên",
		"Kỹ sư", "Nhân sự", "Thủ kho", "Bảo vệ", "Lái xe bus", "Dược sĩ", "Chủ cửa hàng"
	]
	return jobs[index % jobs.size()]

func _build_certificates_for_index(index: int) -> Array[String]:
	var certs: Array[String] = []
	if index % 5 == 0:
		certs.append("CERT_FINANCE_BANKING")
	if index % 7 == 0:
		certs.append("CERT_MEDICINE_GENERAL")
	if index % 11 == 0:
		certs.append("CERT_CIVIC_ADMIN")
	match index:
		20:
			certs.append("CERT_LIGHT_TRUCK")
		21:
			certs.append("CERT_MEDIUM_TRUCK")
		22:
			certs.append("CERT_CONTAINER_TRUCK")
		23:
			certs.append("CERT_HEAVY_HAUL")
		25, 27:
			certs.append("CERT_LOGISTICS_SUPPLY")
		26:
			certs.append("CERT_AUTO_MECHANIC")
	return certs

func _build_workplace_id(job_role: String) -> String:
	match job_role:
		"Nông dân":
			return "CAPITAL_FARM_PLOTS"
		"Lái xe bus":
			return "CAPITAL_BUS_DEPOT"
		"Lái tàu điện":
			return "CAPITAL_TRAM_DEPOT"
		"Học sinh", "Sinh viên":
			return "CAPITAL_SCHOOL"
		"Nhân viên văn phòng", "Kỹ sư", "Nhân sự", "Thủ kho":
			return "CAPITAL_MEGA_OFFICE"
		"Tài xế xe tải nhẹ":
			return "CAPITAL_LOGISTICS_DEPOT"
		"Tài xế xe tải trung":
			return "CAPITAL_LOGISTICS_DEPOT"
		"Tài xế xe container":
			return "CAPITAL_LOGISTICS_DEPOT"
		"Tài xế xe siêu trường":
			return "CAPITAL_LOGISTICS_DEPOT"
		"Điều phối viên logistics":
			return "CAPITAL_LOGISTICS_DEPOT"
		"Quản lý đội xe":
			return "CAPITAL_LOGISTICS_DEPOT"
		"Thợ máy xe tải":
			return "CAPITAL_LOGISTICS_DEPOT"
		"NHVC toàn thời gian":
			return "CAPITAL_MEGA_OFFICE"
		_:
			return "CAPITAL_CIVIC_CENTER"

func _assign_households_and_relationships() -> void:
	for household_start in range(0, citizen_registry.size(), 4):
		var household_members: Array[CitizenData] = []
		var household_id := "HOUSEHOLD_%03d" % int(household_start / 4 + 1)
		for offset in range(4):
			var citizen := get_citizen(str(1000 + household_start + offset))
			if citizen == null:
				continue
			citizen.household_id = household_id
			household_members.append(citizen)
		var adults: Array[CitizenData] = []
		for citizen in household_members:
			if citizen.age >= 18:
				adults.append(citizen)
		if adults.size() >= 2:
			var first_adult := adults[0]
			var second_adult := adults[1]
			first_adult.is_married = true
			second_adult.is_married = true
			first_adult.spouse_id = second_adult.citizen_id
			second_adult.spouse_id = first_adult.citizen_id
			first_adult.social_connections.append(second_adult.citizen_id)
			second_adult.social_connections.append(first_adult.citizen_id)
			first_adult.update_life_stage()
			second_adult.update_life_stage()
		for citizen in household_members:
			for relative in household_members:
				if relative.citizen_id != citizen.citizen_id and not citizen.social_connections.has(relative.citizen_id):
					citizen.social_connections.append(relative.citizen_id)

func register_citizen(citizen: CitizenData) -> void:
	citizen_registry[citizen.citizen_id] = citizen
	if fellowship_registry.has(citizen.fellowship_group):
		fellowship_registry[citizen.fellowship_group].append(citizen.citizen_id)

func get_citizen(citizen_id: String) -> CitizenData:
	return citizen_registry.get(citizen_id) as CitizenData

func get_home_position_for(citizen_id: String) -> Vector3:
	var citizen := get_citizen(citizen_id)
	if citizen == null:
		return Vector3.ZERO
	var wx := citizen.home_coord_km.x * 4.0
	var wz := citizen.home_coord_km.y * 4.0
	if citizen.home_district_id == "DISTRICT_PLATEAU_CORE":
		wx = clamp(wx, -120.0, 120.0)
		wz = clamp(wz, -120.0, 120.0)
	elif citizen.home_district_id == "DISTRICT_EAST_FARMS":
		wx = 10000.0 + clamp(wx, -260.0, 260.0)
		wz = clamp(wz, -220.0, 220.0)
	elif citizen.home_district_id == "DISTRICT_NORTH_FOREST":
		wx = clamp(wx, -240.0, 240.0)
		wz = -10000.0 + clamp(wz, -260.0, 260.0)
	elif citizen.home_district_id == "DISTRICT_WEST_VALLEY" or citizen.home_district_id == "DISTRICT_WEST_INDUSTRY":
		wx = -10000.0 + clamp(wx, -260.0, 260.0)
		wz = clamp(wz, -220.0, 220.0)
	elif citizen.home_district_id == "DISTRICT_SOUTH_PORT" or citizen.home_district_id == "DISTRICT_SOUTH_COAST":
		wx = clamp(wx, -240.0, 240.0)
		wz = 20000.0 + clamp(wz, -260.0, 260.0)
	return Vector3(wx, ModularNatureChunk.get_world_height(wx, wz), wz)

func get_workplace_position_for(citizen_id: String) -> Vector3:
	var citizen := get_citizen(citizen_id)
	if citizen == null:
		return Vector3.ZERO
	var workplace_id := citizen.workplace_id
	match workplace_id:
		"CAPITAL_FARM_PLOTS":
			return Vector3(48.0, ModularNatureChunk.get_world_height(48.0, 42.0), 42.0)
		"CAPITAL_BUS_DEPOT":
			return Vector3(120.0, ModularNatureChunk.get_world_height(120.0, 210.0), 210.0)
		"CAPITAL_TRAM_DEPOT":
			return Vector3(0.0, ModularNatureChunk.get_world_height(0.0, 275.0), 275.0)
		"CAPITAL_SCHOOL":
			return Vector3(-48.0, ModularNatureChunk.get_world_height(-48.0, -52.0), -52.0)
		"CAPITAL_LOGISTICS_DEPOT":
			return Vector3(150.0, ModularNatureChunk.get_world_height(150.0, 300.0), 300.0)
		"CAPITAL_MEGA_OFFICE", "CAPITAL_CIVIC_CENTER":
			return Vector3(0.0, ModularNatureChunk.get_world_height(0.0, 0.0), 0.0)
		_:
			var home_pos := get_home_position_for(citizen_id)
			return Vector3(home_pos.x + 18.0, home_pos.y, home_pos.z - 20.0)

func is_monthly_meetup_active_for(citizen_id: String) -> bool:
	var citizen := get_citizen(citizen_id)
	return is_monthly_meetup_active and citizen != null and citizen.needs_community_support

func is_weekly_driver(citizen_id: String, job_role: String) -> bool:
	if job_role != "Lái xe bus" and job_role != "Lái tàu điện":
		return false
	var week_number := _get_game_week_number()
	var drivers := _get_drivers_for_role(job_role)
	if drivers.is_empty():
		return false
	var driver_index := week_number % drivers.size()
	return str(drivers[driver_index].citizen_id) == citizen_id

func _get_drivers_for_role(job_role: String) -> Array[CitizenData]:
	var drivers: Array[CitizenData] = []
	for citizen_value in citizen_registry.values():
		var citizen := citizen_value as CitizenData
		if citizen.job_role == job_role:
			drivers.append(citizen)
	return drivers

func _get_game_week_number() -> int:
	var server := get_node_or_null("/root/UnifiedTimelineServer")
	if server != null:
		return int(server.get("total_game_minutes")) / (7 * 24 * 60)
	return 0

func _on_world_time_ticked(_day: int, hour: int, _minute: int, _day_name: String) -> void:
	if is_monthly_meetup_active and hour >= 18:
		is_monthly_meetup_active = false
	var week_number := _get_game_week_number()
	if week_number == current_driver_week:
		return
	current_driver_week = week_number
	for job_role in ["Lái xe bus", "Lái tàu điện"]:
		var drivers := _get_drivers_for_role(job_role)
		if not drivers.is_empty():
			var driver := drivers[week_number % drivers.size()]
			weekly_driver_changed.emit(job_role, driver.citizen_id, driver.citizen_name, week_number)

func _on_monthly_community_meetup_started(_day_name: String) -> void:
	is_monthly_meetup_active = true
	var supported_count := 0
	for citizen_value in citizen_registry.values():
		var citizen := citizen_value as CitizenData
		if citizen.needs_community_support:
			supported_count += 1
	monthly_community_meetup_started.emit(supported_count)

func _on_liturgy_started(day_name: String) -> void:
	print("[CitizenManager] 🔔 CHUÔNG VANG: Toàn thể cư dân (%s) di chuyển theo Mạng Nhện về Mega Office dự Thánh Lễ!" % day_name)
	for c_id in citizen_registry.keys():
		var citizen: CitizenData = citizen_registry[c_id]
		citizen.happiness = 100.0
		var transit_mgr = get_node_or_null("/root/TransitNetworkManager")
		if transit_mgr:
			var route_info = transit_mgr.calculate_route_to_central_hub(
				citizen.home_coord_km,
				citizen.preferred_transit_mode,
				false
			)
			citizen.commute_duration_minutes = route_info["travel_time_game_minutes"]

func _on_liturgy_ended(_day_name: String) -> void:
	print("[CitizenManager] 🕊️ Thánh Lễ kết thúc, cư dân dùng tiệc Bác Ái và trở lại vị trí làm việc theo Mạng Nhện.")

func tick_macro_simulation(delta_day: float) -> void:
	for c_id in citizen_registry.keys():
		var citizen: CitizenData = citizen_registry[c_id]
		var wear_reduction: float = 0.0
		var rm = get_node_or_null("/root/ResearchManager")
		if rm != null and rm.has_method("get_wear_and_tear_reduction"):
			wear_reduction = rm.get_wear_and_tear_reduction()
		citizen.tick_durability_and_wear(1.5 * delta_day * (1.0 - wear_reduction))
		if citizen.age >= 18 and not citizen.job_role.is_empty() and citizen.job_role != "Chưa có việc":
			var fin = citizen.process_salary_payment(citizen.salary)
			var wm = get_node_or_null("/root/WorldManager")
			if wm:
				wm.deposit_city_tax(fin["tax"])
				wm.deposit_church_tithe(fin["tithe"])

func can_birth_or_immigrate() -> bool:
	if is_reproduction_halted:
		return false
	return citizen_registry.size() < current_population_cap

func try_birth_or_immigrate_citizen(new_citizen: CitizenData) -> bool:
	if not can_birth_or_immigrate():
		if not is_reproduction_halted:
			is_reproduction_halted = true
			print("[CitizenManager] 🛑 ĐẠT TRẦN DÂN SỐ %d NGƯỜI: Thủ phủ chỉ nhận cư dân tối đa theo quy mô hiện tại." % current_population_cap)
		return false
	register_citizen(new_citizen)
	citizen_population_updated.emit(citizen_registry.size())
	if citizen_registry.size() >= current_population_cap:
		is_reproduction_halted = true
		print("[CitizenManager] 🛑 ĐẠT TRẦN DÂN SỐ %d NGƯỜI: Toàn thành phố dừng sinh sản và nhập cư tạm thời." % current_population_cap)
	return true

## Tổng số cư dân hiện tại trong RAM
func get_total_population() -> int:
	return citizen_registry.size()

## Số cư dân theo huyện
func get_count_by_district(district_id: String) -> int:
	var count := 0
	for c_value in citizen_registry.values():
		var c := c_value as CitizenData
		if c.home_district_id == district_id:
			count += 1
	return count

## Số cư dân theo nhóm hội (AU_NHI, THANH_NIEN, PHU_NU, TRANG_NIEN)
func get_fellowship_stats() -> Dictionary:
	var stats: Dictionary = {
		"AU_NHI": 0,
		"THANH_NIEN": 0,
		"PHU_NU": 0,
		"TRANG_NIEN": 0
	}
	for c_value in citizen_registry.values():
		var c := c_value as CitizenData
		if stats.has(c.fellowship_group):
			stats[c.fellowship_group] += 1
	return stats

## Chỉ số hòa hợp xã hội (trung bình happiness 0-100 → 0-100%)
func get_harmony_index() -> float:
	if citizen_registry.is_empty():
		return 100.0
	var total_happiness := 0.0
	for c_value in citizen_registry.values():
		var c := c_value as CitizenData
		total_happiness += c.happiness
	return clampf(total_happiness / float(citizen_registry.size()), 0.0, 100.0)

## Số cư dân cần hỗ trợ cộng đồng
func get_community_support_count() -> int:
	var count := 0
	for c_value in citizen_registry.values():
		var c := c_value as CitizenData
		if c.needs_community_support:
			count += 1
	return count

## Số NHVC (Người Hầu Việc Chúa) toàn thời gian và bán thời gian
func get_nhvc_counts() -> Dictionary:
	var full_time := 0
	var part_time := 0
	for c_value in citizen_registry.values():
		var c := c_value as CitizenData
		if c.servant_type == "FULL_TIME":
			full_time += 1
		elif c.servant_type == "PART_TIME":
			part_time += 1
	return {"full_time": full_time, "part_time": part_time}

## Số cư dân đã có nhà (workplace_id = CAPITAL_MEGA_OFFICE hoặc có household_id)
func get_available_housing_slots() -> int:
	# Trả về số căn nhà còn trống (tổng trần - số đã có hộ khẩu)
	var housed := 0
	var seen_households: Dictionary = {}
	for c_value in citizen_registry.values():
		var c := c_value as CitizenData
		if not c.household_id.is_empty() and not seen_households.has(c.household_id):
			seen_households[c.household_id] = true
			housed += 1
	# Ước tính: mỗi hộ 4 người, trần 300 người = 75 hộ. Slot còn trống:
	var total_capacity := current_population_cap / 4
	return maxi(0, total_capacity - housed)
