class_name EnterpriseData
extends Resource

signal enterprise_status_changed(message: String)
signal bankruptcy_declared(enterprise_id: String)
signal prosperity_achieved(enterprise_id: String)

enum DivisionType {
	INTERNAL_AFFAIRS,     # Ban Nội Vụ & Nhân Sự (CERT_CIVIC_ADMIN)
	FINANCE_ACCOUNTING,   # Ban Tài Chính & Kế Toán (CERT_FINANCE_BANKING)
	TRAINING_MENTORSHIP,  # Ban Đào Tạo & Kèm Cặp (CERT_EDU_*)
	PLANNING_STRATEGY,    # Ban Kế Hoạch & Chiến Lược (CERT_CIVIC_ADMIN, CERT_LOGISTICS_SUPPLY)
	MAINTENANCE_TECH,     # Ban Kỹ Thuật & Bảo Trì (CERT_POWER_GRID, CERT_AUTO_MECHANIC)
	QUALITY_ENVIRONMENT,  # Ban Kiểm Chuẩn & Môi Trường (CERT_ENVIRONMENTAL_HEALTH)
	MEDIA_EVENTS,         # Ban Truyền Thông & Sự Kiện (CERT_JOURNALISM_MEDIA, CERT_CINEMA_VIDEOGRAPHY)
	PASTORAL_CARE_PEACE   # Ban Mục Vụ, Tâm Lý & Hòa Bình (CERT_DIVINE_SHEPHERD, CERT_MEDICINE_GENERAL)
}

@export var enterprise_id: String = ""
@export var enterprise_name: String = "Cơ Sở Kinh Doanh"
@export var sector_code: String = "COMMERCE" # COMMERCE, AGRI, INDUSTRY, TECH, HEALTH, etc.
@export var bank_account: float = 3000.0
@export var base_operating_cost: float = 200.0

@export var staff_members: Array[String] = [] # List of citizen IDs
@export var max_capacity_slots: int = 4
@export var consecutive_loss_days: int = 0
@export var is_bankrupt: bool = false

# 8 Bộ Ban Chuyên Ngành (Key: DivisionType int, Value: Head Citizen ID or "")
@export var department_heads: Dictionary = {}

# Hệ số năng suất & phồn vinh
@export var productivity_multiplier: float = 1.0
@export var is_prosperous: bool = false
@export var has_bottleneck: bool = false

func _init(p_id: String = "", p_name: String = "Doanh Nghiệp") -> void:
	enterprise_id = p_id if not p_id.is_empty() else str(randi() % 90000 + 10000)
	enterprise_name = p_name
	_init_departments()

func _init_departments() -> void:
	for div in [
		DivisionType.INTERNAL_AFFAIRS,
		DivisionType.FINANCE_ACCOUNTING,
		DivisionType.TRAINING_MENTORSHIP,
		DivisionType.PLANNING_STRATEGY,
		DivisionType.MAINTENANCE_TECH,
		DivisionType.QUALITY_ENVIRONMENT,
		DivisionType.MEDIA_EVENTS,
		DivisionType.PASTORAL_CARE_PEACE
	]:
		if not department_heads.has(div):
			department_heads[div] = ""

func appoint_department_head(div: DivisionType, citizen_id: String) -> void:
	department_heads[div] = citizen_id
	evaluate_organizational_health()

func evaluate_organizational_health() -> void:
	var total_headcount: int = staff_members.size()
	
	# Quy chuẩn: Tổ chức quy mô >= 16 người bắt buộc phải có đủ 8 Trưởng Ban
	if total_headcount >= 16:
		var missing_count: int = 0
		for div in department_heads.keys():
			if str(department_heads[div]).is_empty():
				missing_count += 1
		
		if missing_count > 0:
			# Nghẽn Quản Trị: Giảm -30% năng suất
			has_bottleneck = true
			is_prosperous = false
			productivity_multiplier = 0.70
			enterprise_status_changed.emit("CẢNH BÁO NGHẼN QUẢN TRỊ: Thiếu %d Trưởng Ban chức năng (-30%% năng suất)" % missing_count)
		else:
			# Tổ chức Phồn Vinh: Tăng vọt +50% năng suất!
			has_bottleneck = false
			is_prosperous = true
			productivity_multiplier = 1.50
			prosperity_achieved.emit(enterprise_id)
			enterprise_status_changed.emit("TỔ CHỨC PHỒN VINH: Đã kiện toàn 8 Ban chuyên ngành (+50%% năng suất)!")
	else:
		has_bottleneck = false
		is_prosperous = false
		productivity_multiplier = 1.0

func calculate_daily_finances(gross_sales: float, total_wages: float) -> Dictionary:
	if is_bankrupt:
		return { "profit": 0.0, "tax": 0.0, "tithe": 0.0 }
		
	var effective_revenue: float = gross_sales * productivity_multiplier
	var total_expenses: float = base_operating_cost + total_wages
	var gross_profit: float = effective_revenue - total_expenses
	
	var tax_paid: float = 0.0
	var tithe_paid: float = 0.0
	var net_profit: float = 0.0
	
	if gross_profit > 0.0:
		tax_paid = gross_profit * 0.05    # 5% thuế thu nhập doanh nghiệp nộp Kho Bạc
		tithe_paid = gross_profit * 0.10  # 1/10 trích nộp Quỹ Chúa
		net_profit = gross_profit - tax_paid - tithe_paid
		consecutive_loss_days = 0
		bank_account += net_profit
		
		# Kinh doanh có lãi liên tục -> Mở rộng quy mô & thêm slot tuyển dụng
		if bank_account > (max_capacity_slots * 1200.0):
			max_capacity_slots += 2
			enterprise_status_changed.emit("Mở rộng quy mô: Nâng chỉ tiêu lên %d nhân sự" % max_capacity_slots)
	else:
		net_profit = gross_profit
		bank_account += net_profit
		consecutive_loss_days += 1
		
		# Thua lỗ -> Cắt giảm chi phí, nếu cạn vốn -> Tuyên bố phá sản trong hòa bình
		if bank_account <= 0.0:
			bank_account = 0.0
			is_bankrupt = true
			bankruptcy_declared.emit(enterprise_id)
			enterprise_status_changed.emit("PHÁ SẢN TỰ NHIÊN: Cơ sở thanh lý giải thể hòa bình, không tranh chấp.")
			
	return {
		"revenue": effective_revenue,
		"expenses": total_expenses,
		"gross_profit": gross_profit,
		"net_profit": net_profit,
		"tax_paid": tax_paid,
		"tithe_paid": tithe_paid
	}
