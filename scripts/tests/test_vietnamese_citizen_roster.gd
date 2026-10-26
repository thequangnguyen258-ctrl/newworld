class_name TestVietnameseCitizenRoster
extends SceneTree

const CitizenManagerScript = preload("res://scripts/simulation/citizen_manager.gd")
const CitizenDataScript = preload("res://scripts/simulation/citizen_data.gd")
const DailyScheduleManagerScript = preload("res://scripts/simulation/daily_schedule_manager.gd")

func _init() -> void:
	print("================================================================================")
	print("👥 BẮT ĐẦU KIỂM THỬ: DÂN SỐ THỦ PHỦ 300 NGƯỜI & CHUỖI TUỔI VIỆT NAM")
	print("================================================================================")
	_run_roster_validation()
	print("\n🎉 TẤT CẢ KIỂM THỬ DÀN XẾP DÂN SỐ VÀ TUỔI ĐÃ ĐẠT PASS")
	print("================================================================================")
	quit(0)

func _run_roster_validation() -> void:
	var manager = CitizenManagerScript.new()
	assert(manager.current_population_cap == 300, "Dân số bắt đầu phải là 300 người theo quy chuẩn thủ phủ.")
	manager._generate_initial_citizens()
	assert(manager.citizen_registry.size() == 300, "Phải tạo chính xác 300 cư dân trong giai đoạn đầu.")
	assert(manager._get_drivers_for_role("Lái xe bus").size() > 1, "Cần nhiều tài xế xe buýt để luân phiên theo tuần.")
	assert(manager._get_drivers_for_role("Lái tàu điện").size() > 1, "Cần nhiều tài xế tàu điện để luân phiên theo tuần.")

	for citizen_id in manager.citizen_registry.keys():
		var citizen: CitizenDataScript = manager.citizen_registry[citizen_id]
		var has_vietnamese_surname = false
		for surname in manager.VIETNAMESE_SURNAMES:
			if citizen.citizen_name.begins_with(surname + " "):
				has_vietnamese_surname = true
				break
		assert(has_vietnamese_surname, "Tên cư dân phải có họ Việt Nam hợp lệ: %s" % citizen.citizen_name)
		assert(citizen.home_district_id == "DISTRICT_PLATEAU_CORE", "Tất cả cư dân hiện đang tập trung ở Thủ Phủ.")
		assert(not citizen.household_id.is_empty(), "Mỗi cư dân phải thuộc một hộ gia đình.")
		for related_id in citizen.social_connections:
			assert(manager.get_citizen(related_id) != null, "Quan hệ xã hội phải trỏ đến cư dân có thật.")
		if citizen.is_married:
			var spouse := manager.get_citizen(citizen.spouse_id)
			assert(spouse != null and spouse.spouse_id == citizen.citizen_id, "Quan hệ hôn nhân phải có liên kết hai chiều.")
		if citizen.age < 18:
			assert(citizen.life_stage == CitizenDataScript.LIFE_STAGE_THIEU_NIEN, "Tuổi dưới 18 phải là THIEU_NIEN.")
		elif citizen.is_married:
			assert(citizen.life_stage == CitizenDataScript.LIFE_STAGE_TRANG_NIEN, "Đã kết hôn phải là TRANG_NIEN.")
		else:
			assert(citizen.life_stage == CitizenDataScript.LIFE_STAGE_THANH_NIEN, "Thanh niên chưa kết hôn phải là THANH_NIEN.")
		assert(citizen.age >= 0, "Tuổi cư dân phải không âm.")

	var farmer_schedule := manager.get_citizen("1000")
	assert(farmer_schedule.job_role == "Nông dân", "Cư dân mẫu đầu tiên cần thuộc nghề nông.")
	var farming: Dictionary = DailyScheduleManagerScript.get_citizen_schedule(
		farmer_schedule.job_role, false, 0, 9, 0
	)
	assert(farming["destination"] == "farm" and farming["pose"] == "work", "Lịch sáng phải đưa nông dân ra đồng làm việc.")
	var night: Dictionary = DailyScheduleManagerScript.get_citizen_schedule(
		"Nhân viên văn phòng", false, 0, 22, 0
	)
	assert(night["pose"] == "sleep" and night["destination"] == "home",
		"Khung giờ đêm phải đưa cư dân về nhà và chuyển sang trạng thái ngủ.")
	var lunch: Dictionary = DailyScheduleManagerScript.get_citizen_schedule(
		"Nhân viên văn phòng", false, 0, 12, 0
	)
	assert(lunch["pose"] == "sit" and lunch["destination"] == "rest",
		"Giữa ngày thường, cư dân phải có lịch nghỉ trưa tại nhà.")
	var volunteer: Dictionary = DailyScheduleManagerScript.get_citizen_schedule(
		"NHVC toàn thời gian", true, 0, 9, 0, true, false, false, "CAPITAL_MEGA_OFFICE", "FULL_TIME"
	)
	assert(volunteer["destination"] == "mega_office", "NHVC phải được điều phối tới Mega Office trong giờ làm.")
	var monthly_meetup: Dictionary = DailyScheduleManagerScript.get_citizen_schedule(
		"Nhân viên văn phòng", false, 5, 15, 0, true, true, true
	)
	assert(monthly_meetup["destination"] == "gathering" and monthly_meetup["pose"] == "social",
		"Cư dân cần hỗ trợ phải có lịch gặp cộng đồng trực tiếp hằng tháng.")
	var active_driver: Dictionary = DailyScheduleManagerScript.get_citizen_schedule(
		"Lái xe bus", false, 0, 9, 0, true
	)
	var standby_driver: Dictionary = DailyScheduleManagerScript.get_citizen_schedule(
		"Lái xe bus", false, 0, 9, 0, false
	)
	assert(active_driver["pose"] == "drive" and standby_driver["destination"] == "work",
		"Ca lái xe phải phân biệt tài xế trong tuần và người đang luân phiên nghỉ/bảo dưỡng.")

	var home_pos := manager.get_home_position_for("1000")
	var work_pos := manager.get_workplace_position_for("1000")
	assert(home_pos != Vector3.ZERO, "Cư dân phải có vị trí nhà hợp lệ trong thế giới 3D.")
	assert(work_pos != Vector3.ZERO, "Cư dân phải có vị trí nơi làm việc hợp lệ trong thế giới 3D.")
	assert(work_pos.distance_to(Vector3.ZERO) > 0.0, "Nơi làm việc phải có tọa độ thật và không rơi về (0,0,0) vô nghĩa.")
	assert(home_pos.y == manager.get_home_position_for("1000").y, "Tọa độ nhà phải ổn định khi tính lại theo chiều cao địa hình.")

	print("  ✅ 300 cư dân, hộ gia đình/quan hệ, lịch nghề và hoạt động theo giờ hợp lệ.")
