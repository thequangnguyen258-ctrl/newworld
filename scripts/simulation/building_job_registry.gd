extends Node

# Autoload Singleton: BuildingJobRegistry
signal job_assigned(building_id: String, role: String, citizen_id: String)
signal job_vacated(building_id: String, role: String)
signal abundance_harvested(sector: String, bonus_amount: float)

# ==============================================================================
# HỆ THỐNG ĐÀO TẠO ĐẠI HỌC BÁCH KHOA & DANH MỤC CHỨNG CHỈ (ACADEMY CURRICULUM)
# ==============================================================================

# 10 Khoa Đào Tạo & Các Môn Học Tại Học Viện Bách Khoa Đa Ngành Đỉnh Vát
const FACULTIES: Dictionary = {
	"FAC_AGRI_MARITIME": {
		"name": "Khoa Nông Nghiệp Sinh Thái & Thủy Sản",
		"district": "DISTRICT_EAST_FARMS",
		"courses": [
			"Canh tác Lúa mì & Lương thực Hữu cơ",
			"Kỹ thuật Nhà kính & Nông nghiệp Thủy canh",
			"Chăn nuôi Gia súc Trang trại & Thú y Dự phòng",
			"Khai thác & Nuôi trồng Thủy hải sản Bền vững",
			"Lâm nghiệp Sinh thái & Quản lý Rừng Nguyên sinh"
		],
		"certificates": [
			"CERT_AGRI_CROPS",
			"CERT_AGRI_HORTICULTURE",
			"CERT_AGRI_LIVESTOCK",
			"CERT_MARITIME_FISHING",
			"CERT_FORESTRY_EXTRACTION"
		]
	},
	"FAC_MECHANICAL_MFG": {
		"name": "Khoa Cơ Khí Chế Tạo & Chẩn Đoán Hao Mòn",
		"district": "DISTRICT_WEST_INDUSTRY",
		"courses": [
			"Nguyên lý Máy & Thiết kế Chi tiết Cơ khí",
			"Gia công Phay, Tiện CNC & Hàn Kết cấu",
			"Kỹ thuật Bảo trì Công nghiệp & Chẩn đoán Hao mòn Máy",
			"Động lực học Ô tô & Hệ thống Truyền động Xe điện",
			"Kỹ thuật Đóng tàu & Động cơ Thủy hải"
		],
		"certificates": [
			"CERT_AUTO_MECHANIC",
			"CERT_CNC_MACHINIST",
			"CERT_INDUSTRIAL_MAINTENANCE",
			"CERT_NAVAL_ENGINEERING"
		]
	},
	"FAC_ENERGY_AUTOMATION": {
		"name": "Khoa Năng Lượng Tái Tạo & Tự Động Hóa",
		"district": "DISTRICT_WEST_INDUSTRY",
		"courses": [
			"Lưới điện Thông minh & Trạm Biến áp Đỉnh Vát",
			"Kỹ thuật Tuabin Gió & Thủy điện Dòng chảy",
			"Lập trình PLC & Hệ thống Điều khiển SCADA",
			"Vận hành Robot Công nghiệp & Cảm biến Đo lường"
		],
		"certificates": [
			"CERT_POWER_GRID",
			"CERT_AUTOMATION_ROBOTICS"
		]
	},
	"FAC_CIVIC_ARCH": {
		"name": "Khoa Kiến Trúc, Quy Hoạch & Hạ Tầng Đô Thị",
		"district": "DISTRICT_PLATEAU_CORE",
		"courses": [
			"Thiết kế Kiến trúc Công trình Cel-shaded & Nhà ở Xanh",
			"Quy hoạch Cảnh quan Anime & Không gian Đi bộ",
			"Kỹ thuật Kết cấu Cầu đường & Hầm Metro Ngầm Xuyên Núi",
			"Hệ thống Mạng lưới Cấp thoát nước & Thủy lợi Vách đá",
			"Mô hình hóa Thông tin Công trình BIM & Trắc địa",
			"Vận hành Thiết bị Cơ giới & Cần cẩu Xây dựng"
		],
		"certificates": [
			"CERT_CIVIC_ARCH",
			"CERT_CIVIC_CONSTRUCTION",
			"CERT_HEAVY_MACHINERY",
			"CERT_CARPENTRY"
		]
	},
	"FAC_SOFTWARE_DATA": {
		"name": "Khoa Công Nghệ Thông Tin & Dữ Liệu Thông Minh",
		"district": "DISTRICT_PLATEAU_CORE",
		"courses": [
			"Cấu trúc Dữ liệu, Thuật toán & Kỹ thuật Phần mềm",
			"Phát triển Ứng dụng Toàn diện (Full-stack & Mobile)",
			"Quản trị Hệ thống Đám mây & Kiến trúc DevOps",
			"Phân tích Dữ liệu Kinh doanh (BI & Analytics)",
			"An toàn Thông tin Đô thị & Phòng thủ Mạng"
		],
		"certificates": [
			"CERT_SOFTWARE_ENG",
			"CERT_CLOUD_DEVOPS",
			"CERT_DATA_ANALYTICS",
			"CERT_CYBER_SECURITY",
			"CERT_INFO_TECH"
		]
	},
	"FAC_PUBLIC_ADMIN_BANKING": {
		"name": "Khoa Quản Trị Công, Kinh Tế & Ngân Hàng Nhà Nước",
		"district": "DISTRICT_PLATEAU_CORE",
		"courses": [
			"Khoa học Hành chính Công & Dịch vụ Một Cửa 5 Bước",
			"Quản trị Nhân sự Vĩ mô & Điều phối Thị trường Lao động",
			"Tài chính Công, Kế toán Doanh nghiệp & Kiểm toán Nội bộ",
			"Kinh tế học Tiền tệ Thuật toán & Ngân hàng Nhà nước",
			"Quản trị Chuỗi Cung ứng Đô thị (SCM) & Kho vận Logistics",
			"Điều vận Đội xe, Ghép tải & An toàn Giao nhận",
			"Vận hành Xe tải nhẹ đến 3,5 tấn",
			"Vận hành Xe tải trung đến 10 tấn",
			"Vận hành Đầu kéo Container đến 28 tấn",
			"Vận hành Xe tải hạng nặng đến 40 tấn"
		],
		"certificates": [
			"CERT_CIVIC_ADMIN",
			"CERT_FINANCE_BANKING",
			"CERT_LOGISTICS_SUPPLY",
			"CERT_LIGHT_TRUCK",
			"CERT_MEDIUM_TRUCK",
			"CERT_CONTAINER_TRUCK",
			"CERT_HEAVY_HAUL"
		]
	},
	"FAC_CULINARY_CRAFTS": {
		"name": "Khoa Ẩm Thực, Mỹ Nghệ & Thời Trang Anime",
		"district": "DISTRICT_PLATEAU_CORE",
		"courses": [
			"Nghệ thuật Bánh mì Thủ công & Lên men Bánh ngọt",
			"Kỹ thuật Pha chế Trà Thảo mộc Onsen & Cà phê Đặc sản",
			"Thiết kế Thời trang Cel-shaded & May đo VEST Cao cấp",
			"Mỹ thuật Gốm Sứ Mỹ nghệ & Điêu khắc Gỗ Gia dụng"
		],
		"certificates": [
			"CERT_FOOD_PROCESSING",
			"CERT_BEVERAGE_BREWING",
			"CERT_TEXTILE_FASHION",
			"CERT_CERAMIC_CRAFT"
		]
	},
	"FAC_HEALTH_ENVIRONMENT": {
		"name": "Khoa Sức Khỏe Phục Hồi & Khoa Học Môi Trường",
		"district": "DISTRICT_NORTH_FOREST",
		"courses": [
			"Y học Phục hồi Thể lực & Trị liệu Suối khoáng Onsen",
			"Dinh dưỡng Thanh xuân & Vệ sinh Dịch tễ Dự phòng",
			"Khoa học Môi trường & Xử lý Tuần hoàn Sinh thái 100%",
			"Huấn luyện Thể thao Phong trào & Vận động Thể chất"
		],
		"certificates": [
			"CERT_MEDICINE_GENERAL",
			"CERT_ENVIRONMENTAL_HEALTH",
			"CERT_SPORTS_FITNESS"
		]
	},
	"FAC_MEDIA_ARTS": {
		"name": "Khoa Nghệ Thuật, Âm Nhạc Đời Sống & Truyền Thông",
		"district": "DISTRICT_PLATEAU_CORE",
		"courses": [
			"Sáng tác Ca khúc Đời sống & Giai điệu Thanh xuân (Acoustic, Ballad, Ghibli Lo-fi)",
			"Kỹ thuật Biểu diễn Nhạc cụ (Piano, Guitar, Violin) & Hòa nhạc Đường phố (Busking)",
			"Nghệ thuật Hát Đơn ca, Ca kịch Sân khấu & Hợp xướng Phụng vụ",
			"Mỹ thuật Hội họa, Tranh tường Anime & Triển lãm Đời sống",
			"Biên kịch, Quay phim Điện ảnh Anime & Sân khấu Nghệ thuật",
			"Báo chí Phát thanh, Sản xuất Podcast & Đạo diễn Sự kiện"
		],
		"certificates": [
			"CERT_MUSIC_PERFORMANCE",
			"CERT_MUSIC_COMPOSITION",
			"CERT_FINE_ARTS_VISUAL",
			"CERT_CINEMA_VIDEOGRAPHY",
			"CERT_JOURNALISM_MEDIA"
		]
	},
	"FAC_PASTORAL_PEACE": {
		"name": "Khoa Thần Học Mục Vụ, Đạo Đức & Sứ Mạng Hòa Bình",
		"district": "DISTRICT_PLATEAU_CORE",
		"courses": [
			"Thần học Giao ước Mới, Lời Chúa & Đời sống Thánh khiết",
			"Tâm lý học Tham vấn, Lắng nghe & Đồng hành Mục vụ",
			"Nghi thức Phụng vụ: Đại Lễ Hiệp Thông & Lễ Cưới Vĩnh Cửu",
			"Sứ mạng Hòa bình: Tiếp đón Lữ khách & Viện trợ Nhân đạo"
		],
		"certificates": [
			"CERT_DIVINE_SHEPHERD",
			"CERT_PASTORAL_COUNSELING"
		]
	},
	"FAC_NATURAL_SCI_RND": {
		"name": "Khoa Khoa Học Tự Nhiên, Vật Liệu & Viện R&D",
		"district": "DISTRICT_PLATEAU_CORE",
		"courses": [
			"Phương pháp Luận Nghiên cứu Khoa học & Kỹ thuật Phòng Lab",
			"Khoa học Vật liệu Tiên tiến & Công nghệ Lớp phủ Nano Chống Hao mòn",
			"Kỹ thuật Di truyền Thực vật, Sinh học Đất & Men Vi sinh Hữu cơ",
			"Khí động học Ứng dụng & Năng lượng Tái tạo Không Thoái hóa",
			"Điều khiển học Tự động & Robot Hỗ trợ Nhân đạo"
		],
		"certificates": [
			"CERT_RESEARCH_METHODOLOGY",
			"CERT_APPLIED_RND",
			"CERT_NANO_MATERIALS",
			"CERT_BIO_GENETICS"
		]
	}
}

# Bảng tra cứu yêu cầu Chứng chỉ chuẩn cho từng chức danh nghề nghiệp (Curated Job Directory)
const CERT_REQUIREMENTS: Dictionary = {
	# 1. Hành chính, Quản trị & Hộ tịch
	"CIVIC_ADMIN": "CERT_CIVIC_ADMIN",
	"HR_OFFICER": "CERT_CIVIC_ADMIN",
	"PLANNER": "CERT_CIVIC_ADMIN",
	"COMMUNITY_COORDINATOR": "CERT_CIVIC_ADMIN",
	
	# 2. Tài chính, Ngân hàng Nhà nước & Kế toán
	"BANK_TELLER": "CERT_FINANCE_BANKING",
	"BANK_DIRECTOR": "CERT_FINANCE_BANKING",
	"ACCOUNTANT": "CERT_FINANCE_BANKING",
	"FINANCIAL_ANALYST": "CERT_FINANCE_BANKING",
	"CHIEF_FINANCIAL_OFFICER": "CERT_FINANCE_BANKING",
	
	# 3. Nông nghiệp, Chăn nuôi & Thủy sản
	"FARMER_CROPS": "CERT_AGRI_CROPS",
	"HORTICULTURIST": "CERT_AGRI_HORTICULTURE",
	"HYDRO_SPECIALIST": "CERT_AGRI_HORTICULTURE",
	"DAIRY_FARMER": "CERT_AGRI_LIVESTOCK",
	"VETERINARIAN": "CERT_AGRI_LIVESTOCK",
	"FISHERMAN": "CERT_MARITIME_FISHING",
	"AQUACULTURE_ENGINEER": "CERT_MARITIME_FISHING",
	"FORESTER": "CERT_FORESTRY_EXTRACTION",
	"FOREST_RANGER": "CERT_FORESTRY_EXTRACTION",
	
	# 4. Cơ khí, Chế tạo & Chẩn đoán Hao mòn Máy móc
	"MECHANIC": "CERT_AUTO_MECHANIC",
	"AUTO_DIAGNOSTIC_TECH": "CERT_AUTO_MECHANIC",
	"EV_TECH": "CERT_AUTO_MECHANIC",
	"CNC_OPERATOR": "CERT_CNC_MACHINIST",
	"WELDER": "CERT_CNC_MACHINIST",
	"LOCKSMITH": "CERT_CNC_MACHINIST",
	"MAINTENANCE_ENGINEER": "CERT_INDUSTRIAL_MAINTENANCE",
	"SHIPWRIGHT": "CERT_NAVAL_ENGINEERING",
	"MARINE_ENGINEER": "CERT_NAVAL_ENGINEERING",
	
	# 5. Năng lượng tái tạo, Lưới điện & Tự động hóa
	"GRID_ENGINEER": "CERT_POWER_GRID",
	"ELECTRICIAN": "CERT_POWER_GRID",
	"WIND_TURBINE_TECH": "CERT_POWER_GRID",
	"AUTOMATION_ENGINEER": "CERT_AUTOMATION_ROBOTICS",
	"PLC_ENGINEER": "CERT_AUTOMATION_ROBOTICS",
	"ROBOTICS_TECH": "CERT_AUTOMATION_ROBOTICS",
	
	# 6. Kiến trúc, Xây dựng hạ tầng & Giao thông
	"ARCHITECT": "CERT_CIVIC_ARCH",
	"URBAN_DESIGNER": "CERT_CIVIC_ARCH",
	"CIVIL_ENGINEER": "CERT_CIVIC_CONSTRUCTION",
	"BRIDGE_TUNNEL_ENGINEER": "CERT_CIVIC_CONSTRUCTION",
	"METRO_TRANSIT_ENGINEER": "CERT_CIVIC_CONSTRUCTION",
	"BIM_ENGINEER": "CERT_CIVIC_CONSTRUCTION",
	"CRANE_OPERATOR": "CERT_HEAVY_MACHINERY",
	"EXCAVATOR_OPERATOR": "CERT_HEAVY_MACHINERY",
	"CARPENTER": "CERT_CARPENTRY",
	"MASON": "CERT_CARPENTRY",
	
	# 7. Công nghệ thông tin, Phần mềm & Dữ liệu
	"SOFTWARE_ENGINEER": "CERT_SOFTWARE_ENG",
	"FRONTEND_DEV": "CERT_SOFTWARE_ENG",
	"BACKEND_DEV": "CERT_SOFTWARE_ENG",
	"FULLSTACK_DEV": "CERT_SOFTWARE_ENG",
	"MOBILE_DEV": "CERT_SOFTWARE_ENG",
	"CLOUD_ENGINEER": "CERT_CLOUD_DEVOPS",
	"DEVOPS_ENGINEER": "CERT_CLOUD_DEVOPS",
	"SYSTEM_ADMIN": "CERT_CLOUD_DEVOPS",
	"DATA_ANALYST": "CERT_DATA_ANALYTICS",
	"BI_DEVELOPER": "CERT_DATA_ANALYTICS",
	"DATABASE_ADMIN": "CERT_DATA_ANALYTICS",
	"CYBER_SECURITY_SPECIALIST": "CERT_CYBER_SECURITY",
	
	# 8. Chuỗi cung ứng, Logistics & Kho vận
	"SCM_MANAGER": "CERT_LOGISTICS_SUPPLY",
	"WAREHOUSE_SUPERVISOR": "CERT_LOGISTICS_SUPPLY",
	"INVENTORY_DISPATCHER": "CERT_LOGISTICS_SUPPLY",
	"Điều phối viên logistics": "CERT_LOGISTICS_SUPPLY",
	"Quản lý đội xe": "CERT_LOGISTICS_SUPPLY",
	"Tài xế xe tải nhẹ": "CERT_LIGHT_TRUCK",
	"Tài xế xe tải trung": "CERT_MEDIUM_TRUCK",
	"Tài xế xe container": "CERT_CONTAINER_TRUCK",
	"Tài xế xe siêu trường": "CERT_HEAVY_HAUL",
	"Thợ máy xe tải": "CERT_AUTO_MECHANIC",
	
	# 9. Ẩm thực, Dệt may thời trang & Thủ công mỹ nghệ
	"BAKER": "CERT_FOOD_PROCESSING",
	"FOOD_TECH": "CERT_FOOD_PROCESSING",
	"TEA_MASTER": "CERT_BEVERAGE_BREWING",
	"BARISTA": "CERT_BEVERAGE_BREWING",
	"TAILOR": "CERT_TEXTILE_FASHION",
	"FASHION_DESIGNER": "CERT_TEXTILE_FASHION",
	"CERAMIST": "CERT_CERAMIC_CRAFT",
	"WOOD_ARTISAN": "CERT_CARPENTRY",
	
	# 10. Y tế phục hồi, Môi trường & Thể thao
	"DOCTOR": "CERT_MEDICINE_GENERAL",
	"ONSEN_ATTENDANT": "CERT_MEDICINE_GENERAL",
	"THERAPIST_PHYSICAL": "CERT_MEDICINE_GENERAL",
	"ENVIRONMENT_INSPECTOR": "CERT_ENVIRONMENTAL_HEALTH",
	"FITNESS_COACH": "CERT_SPORTS_FITNESS",
	
	# 11. Giáo dục, Học viện & Nghiên cứu Khoa học (R&D)
	"TEACHER": "CERT_EDU_PRIMARY",
	"PROFESSOR": "CERT_EDU_POLYTECHNIC",
	"CHIEF_SCIENTIST": "CERT_APPLIED_RND",
	"RESEARCH_SCIENTIST": "CERT_APPLIED_RND",
	"RND_ENGINEER": "CERT_APPLIED_RND",
	"MATERIALS_SCIENTIST": "CERT_NANO_MATERIALS",
	"BIO_RESEARCHER": "CERT_BIO_GENETICS",
	"LAB_TECHNICIAN": "CERT_RESEARCH_METHODOLOGY",
	
	# 12. Nghệ thuật, Âm nhạc Đời sống & Truyền thông
	"JOURNALIST": "CERT_JOURNALISM_MEDIA",
	"CAMERAMAN": "CERT_CINEMA_VIDEOGRAPHY",
	"PIANIST": "CERT_MUSIC_PERFORMANCE",
	"CHOIR_DIRECTOR": "CERT_MUSIC_PERFORMANCE",
	"MUSICIAN_BUSKER": "CERT_MUSIC_PERFORMANCE",
	"SINGER_PERFORMER": "CERT_MUSIC_PERFORMANCE",
	"COMPOSER": "CERT_MUSIC_COMPOSITION",
	"PAINTER_ARTIST": "CERT_FINE_ARTS_VISUAL",
	"ACTOR_PERFORMER": "CERT_CINEMA_VIDEOGRAPHY",
	
	# 13. Người Hầu Việc Chúa (NHVC Full-Time: NCC, Đảm nhiệm, Thư ký & 9 Trưởng ban)
	"CHURCH_SHEPHERD": "CERT_DIVINE_SHEPHERD",
	"DISTRICT_CHURCH_OVERSEER": "CERT_DIVINE_SHEPHERD",
	"OVERSEER_SECRETARY": "CERT_CIVIC_ADMIN",
	"HEAD_CIVIC_INTERNAL": "CERT_CIVIC_ADMIN",
	"HEAD_FINANCE_BANKING": "CERT_FINANCE_BANKING",
	"HEAD_TRAINING_ACADEMY": "CERT_EDU_POLYTECHNIC",
	"HEAD_PLANNING_SCM": "CERT_LOGISTICS_SUPPLY",
	"HEAD_MAINTENANCE_TECH": "CERT_AUTO_MECHANIC",
	"HEAD_QUALITY_ECO": "CERT_ENVIRONMENTAL_HEALTH",
	"HEAD_MEDIA_CINEMA": "CERT_JOURNALISM_MEDIA",
	"HEAD_WORSHIP_PRAISE": "CERT_MUSIC_PERFORMANCE",
	"HEAD_PASTORAL_PEACE": "CERT_DIVINE_SHEPHERD",
	"MINISTRY_SECRETARY": "CERT_CIVIC_ADMIN",
	
	# 14. Tình Nguyện Viên Hỗ Trợ Chúa (NHVC Part-Time: Tình nguyện viên KHÔNG NHẬN LƯƠNG, mạng lưới 4 cấp & phụng vụ)
	"VOLUNTEER_DISTRICT_HEAD": "CERT_DIVINE_SHEPHERD", # 1 Hội Trưởng (Trưởng khu vực) quản lý các Nhóm Trưởng
	"VOLUNTEER_TEAM_LEADER": "CERT_PASTORAL_COUNSELING", # 1 Nhóm Trưởng quản lý các Tổ Trưởng
	"VOLUNTEER_CELL_LEADER": "CERT_PASTORAL_COUNSELING", # 1 Tổ Trưởng quản lý các Thành viên tổ
	"VOLUNTEER_COUNSELOR": "CERT_PASTORAL_COUNSELING", # Tư vấn tâm lý mục vụ cơ sở
	"VOLUNTEER_WORSHIPPER": "CERT_MUSIC_PERFORMANCE", # Ca viên & Nhạc công ca đoàn
	"VOLUNTEER_HOSPITALITY": "CERT_CIVIC_ADMIN", # Tiếp đón Cảng Hòa Bình & Tiệc Agape
	"VOLUNTEER_MENTOR": "CERT_DIVINE_SHEPHERD", # Đồng hành thiếu nhi & thanh thiếu niên
	"PARTTIME_COUNSELOR": "CERT_PASTORAL_COUNSELING",
	"PARTTIME_WORSHIPPER": "CERT_MUSIC_PERFORMANCE",
	"PARTTIME_HOSPITALITY": "CERT_CIVIC_ADMIN",
	"PARTTIME_MENTOR": "CERT_DIVINE_SHEPHERD",
	"PASTORAL_COUNSELOR": "CERT_PASTORAL_COUNSELING",
	"PEACE_AMBASSADOR": "CERT_DIVINE_SHEPHERD"
}

# Đất lành được chúc phước: Hệ số bội thu sản vật
var blessed_abundance_multiplier: float = 1.60

# Hệ thống 20 Bậc Công Nghệ Kiến Tạo (20-Tier Tech Tree Progress: Level 0 đến 20)
var tech_tiers: Dictionary = {
	"ANTI_WEAR_MATERIALS": 0,    # Mỗi bậc giảm 0.5% - 1.5% hao mòn (Tối đa giảm 21.0%)
	"AGRI_BIO_ABUNDANCE": 0,     # Mỗi bậc tăng 0.5% - 1.5% sản lượng hữu cơ
	"CLEAN_ENERGY_GRID": 0,      # Mỗi bậc tăng 0.5% - 1.5% hiệu suất năng lượng
	"HUMAN_AUTOMATION": 0,       # Mỗi bậc tăng 0.5% - 1.5% lưu lượng kho RAM
	"WELLNESS_ECO_SCIENCES": 0   # Mỗi bậc tăng 0.5% - 1.5% hồi phục sinh lực
}

# Tỷ lệ giảm hao mòn máy móc toàn đô thị tích lũy từ công nghệ (0.0 đến 0.21)
var tech_wear_reduction_ratio: float = 0.0

# Danh bạ các tòa nhà & vị trí làm việc đang đăng ký
var registered_buildings: Dictionary = {} # building_id -> Dictionary of job slots
var registered_enterprises: Dictionary = {} # enterprise_id -> EnterpriseData

func _ready() -> void:
	print("[BuildingJobRegistry] Khởi tạo Hệ thống Danh mục Nghề & Đất Lành Chúc Phước thành công.")

func register_building(building_id: String, slots_info: Dictionary) -> void:
	registered_buildings[building_id] = slots_info

func register_enterprise(enterprise: EnterpriseData) -> void:
	registered_enterprises[enterprise.enterprise_id] = enterprise

func get_required_certificate(role: String) -> String:
	return CERT_REQUIREMENTS.get(role, "")

func can_citizen_apply(citizen: CitizenData, role: String) -> bool:
	var required_cert: String = get_required_certificate(role)
	if required_cert.is_empty():
		return true # Vị trí lao động phổ thông không đòi hỏi chứng chỉ
	return citizen.certificates.has(required_cert)

func assign_citizen_to_slot(building_id: String, role: String, citizen: CitizenData) -> bool:
	if not can_citizen_apply(citizen, role):
		print("[JobRegistry] Từ chối tuyển dụng: Cư dân %s thiếu chứng chỉ %s" % [citizen.citizen_name, get_required_certificate(role)])
		return false
		
	if registered_buildings.has(building_id):
		var building: Dictionary = registered_buildings[building_id]
		building[role] = citizen.citizen_id
		citizen.workplace_id = building_id
		citizen.job_role = role
		job_assigned.emit(building_id, role, citizen.citizen_id)
		print("[JobRegistry] Tuyển dụng thành công: %s vào vị trí %s tại %s" % [citizen.citizen_name, role, building_id])
		return true
	return false

func vacate_citizen_from_slot(building_id: String, role: String, citizen: CitizenData = null) -> bool:
	if registered_buildings.has(building_id):
		var building: Dictionary = registered_buildings[building_id]
		if building.has(role):
			building[role] = ""
			if citizen != null:
				citizen.workplace_id = ""
				citizen.job_role = "Chưa có việc"
			job_vacated.emit(building_id, role)
			print("[JobRegistry] Vị trí việc làm %s tại %s đã được bỏ trống (vacated)." % [role, building_id])
			return true
	return false

func calculate_harvest_with_blessing(base_yield: float, sector: String) -> float:
	# Áp dụng nhân hệ số đất lành cho nông sản, thủy sản, chế biến thực phẩm
	if sector in ["AGRI_CROPS", "HORTICULTURE", "LIVESTOCK", "FISHING", "FOOD_PROCESSING"]:
		var final_yield: float = base_yield * blessed_abundance_multiplier
		abundance_harvested.emit(sector, final_yield - base_yield)
		return final_yield
	return base_yield

# ==============================================================================
# HÀM TIỆN ÍCH TRUY VẤN HỌC VIỆN & CHỨNG CHỈ NGHỀ (ACADEMY API)
# ==============================================================================

func get_all_faculties() -> Dictionary:
	return FACULTIES

func get_faculty(faculty_id: String) -> Dictionary:
	return FACULTIES.get(faculty_id, {})

func get_faculty_for_cert(cert_id: String) -> String:
	for fac_id in FACULTIES.keys():
		var fac: Dictionary = FACULTIES[fac_id]
		var certs: Array = fac.get("certificates", [])
		if cert_id in certs:
			return fac_id
	return ""

func get_courses_for_cert(cert_id: String) -> Array:
	var fac_id: String = get_faculty_for_cert(cert_id)
	if not fac_id.is_empty():
		var fac: Dictionary = FACULTIES[fac_id]
		return fac.get("courses", [])
	return []

# ==============================================================================
# HỆ THỐNG CÔNG NGHỆ 20 BẬC KIẾN TẠO (20-TIER TECH TREE API)
# ==============================================================================

func get_tech_tier(branch: String) -> int:
	return tech_tiers.get(branch, 0)

func upgrade_tech_tier(branch: String) -> int:
	if tech_tiers.has(branch):
		var current_lvl: int = tech_tiers[branch]
		if current_lvl < 20:
			tech_tiers[branch] = current_lvl + 1
			_recalculate_tech_effects()
			print("[TechTree] Nhánh %s đã nâng cấp lên Bậc %d/20" % [branch, tech_tiers[branch]])
			return tech_tiers[branch]
	return -1

func get_tech_wear_reduction() -> float:
	return tech_wear_reduction_ratio

func _recalculate_tech_effects() -> void:
	# Nhánh 1: Giảm hao mòn máy móc tích lũy 0.5% - 1.5%/bậc, tối đa -21.0% ở bậc 20
	var anti_wear_lvl: int = tech_tiers.get("ANTI_WEAR_MATERIALS", 0)
	tech_wear_reduction_ratio = minf(anti_wear_lvl * 0.0105, 0.210)
	
	# Nhánh 2: Tăng hệ số đất lành từ 1.60 -> 1.85 ở bậc 20
	var agri_lvl: int = tech_tiers.get("AGRI_BIO_ABUNDANCE", 0)
	blessed_abundance_multiplier = 1.60 + (agri_lvl * 0.0125)

func is_volunteer_role(role: String) -> bool:
	return role.begins_with("VOLUNTEER_") or role.begins_with("PARTTIME_")

