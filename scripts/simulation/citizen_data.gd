class_name CitizenData
extends Resource

signal status_updated()
signal durability_warning(item_name: String)

const LIFE_STAGE_THIEU_NIEN: String = "THIEU_NIEN"
const LIFE_STAGE_THANH_NIEN: String = "THANH_NIEN"
const LIFE_STAGE_TRANG_NIEN: String = "TRANG_NIEN"

@export var citizen_id: String = ""
@export var citizen_name: String = "Cư Dân"
@export var age: int = 22
@export var gender: String = "Nam"
@export var life_stage: String = LIFE_STAGE_THANH_NIEN
@export var is_married: bool = false
@export var needs_community_support: bool = false
@export var household_id: String = ""
@export var spouse_id: String = ""
@export var social_connections: Array[String] = []
@export var certificates: Array[String] = []

# 3 trạng thái hoạt động chính theo quy chuẩn mới: thiếu niên, thanh niên, tráng niên
@export var fellowship_group: String = LIFE_STAGE_THANH_NIEN

# Nghề nghiệp & Nơi làm việc
@export var workplace_id: String = ""
@export var job_role: String = "Chưa có việc"
@export var salary: float = 350.0 # Lương cơ bản dồi dào
@export var wallet: float = 500.0

# Địa Bàn Cư Trú (5 Huyện) & Phương Tiện Giao Thông Mạng Nhện
# Cư dân sống ở ĐỈNH VÁT là chủ yếu (DISTRICT_PLATEAU_CORE)
@export var home_district_id: String = "DISTRICT_PLATEAU_CORE"
@export var workplace_district_id: String = "DISTRICT_PLATEAU_CORE"
@export var home_coord_km: Vector2 = Vector2.ZERO
@export var preferred_transit_mode: int = 3 # 0: Đi bộ, 1: Xe đạp, 2: Bus, 3: Xe máy/Ô tô, 4: Metro
@export var commute_duration_minutes: float = 0.0

# Người Hầu Việc Chúa (NHVC) & Mục vụ
@export var is_church_servant: bool = false
@export var servant_type: String = "NONE" # "NONE", "FULL_TIME", "PART_TIME"
@export var sabbatical_days_remaining: int = 0
@export var suit_outfit_active: bool = false # Trang phục Vest thanh lịch

# Thuế & Tiền dâng
@export var tithe_rate: float = 0.10 # 1/10 dâng Quỹ Chúa (chăm lo bác ái, NHVC, quà tặng)
@export var tax_rate: float = 0.05   # 5% thuế thu nhập Kho Bạc Đô Thị

# Trạng thái tinh thần & thể chất
@export var energy: float = 100.0
@export var happiness: float = 100.0

# Độ bền vật chất & Tiêu dùng nâng cấp (Durability & Upgrades)
@export var durability_clothing: float = 100.0 # Trang phục, vest
@export var durability_tools: float = 100.0    # Dụng cụ làm việc, lò nướng, máy tính
@export var durability_vehicle: float = 100.0  # Xe đạp, xe điện, scooter

func _init(p_id: String = "", p_name: String = "Cư Dân", p_age: int = 22) -> void:
	citizen_id = p_id if not p_id.is_empty() else str(randi() % 90000 + 10000)
	citizen_name = p_name
	age = p_age
	update_life_stage()

func update_life_stage() -> void:
	if age < 18:
		life_stage = LIFE_STAGE_THIEU_NIEN
		fellowship_group = "AU_NHI"
	elif is_married:
		life_stage = LIFE_STAGE_TRANG_NIEN
		fellowship_group = "PHU_NU" if (gender == "Nữ" or gender == "FEMALE") else "TRANG_NIEN"
	else:
		life_stage = LIFE_STAGE_THANH_NIEN
		fellowship_group = "THANH_NIEN"

	if is_church_servant:
		suit_outfit_active = true

func auto_assign_fellowship() -> void:
	update_life_stage()

func advance_age_by_years(years: float) -> void:
	if years <= 0.0:
		return
	age += int(floor(years))
	update_life_stage()

func process_salary_payment(gross_salary: float) -> Dictionary:
	var tithe_amount: float = gross_salary * tithe_rate
	var tax_amount: float = gross_salary * tax_rate
	var net_salary: float = gross_salary - tithe_amount - tax_amount
	
	wallet += net_salary
	status_updated.emit()
	
	return {
		"net_salary": net_salary,
		"tithe": tithe_amount,
		"tax": tax_amount
	}

func tick_durability_and_wear(decay_amount: float) -> void:
	durability_clothing = maxf(0.0, durability_clothing - decay_amount)
	durability_tools = maxf(0.0, durability_tools - (decay_amount * 1.2))
	durability_vehicle = maxf(0.0, durability_vehicle - (decay_amount * 0.8))
	
	# Nếu đồ vật hao mòn < 25%, cư dân dùng tiền tiết kiệm nâng cấp/sửa chữa (kích cầu kinh tế)
	if durability_clothing < 25.0 and wallet >= 80.0:
		wallet -= 80.0
		durability_clothing = 100.0 # Mua vest mới hoặc may đồ mới
	elif durability_clothing < 15.0:
		durability_warning.emit("Trang phục bị mòn rách")
		
	if durability_tools < 25.0 and wallet >= 120.0:
		wallet -= 120.0
		durability_tools = 100.0 # Mua máy móc / công cụ mới
		
	if durability_vehicle < 25.0 and wallet >= 150.0:
		wallet -= 150.0
		durability_vehicle = 100.0 # Nâng cấp xe mới

func receive_pastoral_care() -> void:
	# Được Người Chăn Chiên & NHVC tư vấn tâm lý, cầu nguyện, an ủi
	energy = 100.0
	happiness = 100.0
	status_updated.emit()

func request_sabbatical_rest() -> void:
	if is_church_servant and servant_type == "FULL_TIME":
		sabbatical_days_remaining = 7
		happiness = 100.0
		status_updated.emit()

func switch_to_part_time() -> void:
	if is_church_servant:
		servant_type = "PART_TIME"
		# Rule #4: NHVC Part-Time tình nguyện 100%, không nhận lương giáo vụ
		status_updated.emit()
