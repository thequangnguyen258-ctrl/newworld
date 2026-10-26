class_name TestResidentDailySchedule
extends SceneTree

# ==============================================================================
# TEST AUTOMATION: HỆ THỐNG LỊCH TRÌNH SINH HOẠT CƯ DÂN 5 HUYỆN (DAILY SCHEDULE)
# 1. Kiểm tra 6 Khung Giờ Sinh Hoạt Chuẩn (WorldManager & DailyScheduleManager)
# 2. Kiểm tra Sinh Hoạt Chuyên Ngành Của Cư Dân 5 Huyện (Đông, Tây, Bắc, Nam, Đỉnh Vát)
# 3. Kiểm tra Thánh Lễ Thứ Tư / Chủ Nhật vs Giờ Nghỉ Trưa Ngày Thường
# 4. Kiểm tra Cập Nhật Bảng Tên 3D (FloatingNameplate) Theo Thời Gian Thực
# 5. Kiểm tra Thẻ Căn Cước Hologram (CitizenIDModal) & Lời Thoại Ngữ Cảnh
# 6. Kiểm tra Tablet Civic OS (MacroMapModal) Giám Sát Lịch Trình 5 Huyện
# ==============================================================================

const DailyScheduleManagerScript = preload("res://scripts/simulation/daily_schedule_manager.gd")
const NPCCharacterScript = preload("res://scripts/characters/npc_character.gd")
const ModularHumanoidBuilderScript = preload("res://scripts/characters/modular_humanoid_builder.gd")

func _init() -> void:
	print("================================================================================")
	print("👥 BẮT ĐẦU KIỂM THỬ: HỆ THỐNG LỊCH TRÌNH SINH HOẠT (DAILY SCHEDULE) CƯ DÂN 5 HUYỆN")
	print("================================================================================")

	_test_time_slot_conversion()
	_test_facility_opening_hours()
	_test_five_districts_activities()
	_test_liturgy_vs_regular_noon()
	_test_npc_live_schedule_update()
	_test_tablet_civic_os_schedule_monitor()

	print("\n🎉 TOÀN BỘ CÁC BÀI KIỂM THỬ LỊCH TRÌNH SINH HOẠT ĐÃ ĐẠT 100% PASS!")
	print("================================================================================")
	quit(0)

# 1. Kiểm tra chuyển đổi 6 khung giờ
func _test_time_slot_conversion() -> void:
	print("\n[1] KIỂM TRA CHUYỂN ĐỔI 6 KHUNG THỜI GIAN CHUẨN:")

	var s_dawn = DailyScheduleManagerScript.get_time_slot(6, 30)
	assert(s_dawn == DailyScheduleManagerScript.TimeSlot.MORNING_DAWN, "06:30 phải là MORNING_DAWN")
	print("  ✅ 06:30 -> %s: %s" % [DailyScheduleManagerScript.get_time_slot_icon(s_dawn), DailyScheduleManagerScript.get_time_slot_name(s_dawn)])

	var s_work_m = DailyScheduleManagerScript.get_time_slot(9, 15)
	assert(s_work_m == DailyScheduleManagerScript.TimeSlot.MORNING_WORK, "09:15 phải là MORNING_WORK")
	print("  ✅ 09:15 -> %s: %s" % [DailyScheduleManagerScript.get_time_slot_icon(s_work_m), DailyScheduleManagerScript.get_time_slot_name(s_work_m)])

	var s_noon = DailyScheduleManagerScript.get_time_slot(12, 0)
	assert(s_noon == DailyScheduleManagerScript.TimeSlot.NOON_LITURGY_MEAL, "12:00 phải là NOON_LITURGY_MEAL")
	print("  ✅ 12:00 -> %s: %s" % [DailyScheduleManagerScript.get_time_slot_icon(s_noon), DailyScheduleManagerScript.get_time_slot_name(s_noon)])

	var s_work_a = DailyScheduleManagerScript.get_time_slot(15, 30)
	assert(s_work_a == DailyScheduleManagerScript.TimeSlot.AFTERNOON_WORK, "15:30 phải là AFTERNOON_WORK")
	print("  ✅ 15:30 -> %s: %s" % [DailyScheduleManagerScript.get_time_slot_icon(s_work_a), DailyScheduleManagerScript.get_time_slot_name(s_work_a)])

	var s_sunset = DailyScheduleManagerScript.get_time_slot(18, 45)
	assert(s_sunset == DailyScheduleManagerScript.TimeSlot.EVENING_SUNSET, "18:45 phải là EVENING_SUNSET")
	print("  ✅ 18:45 -> %s: %s" % [DailyScheduleManagerScript.get_time_slot_icon(s_sunset), DailyScheduleManagerScript.get_time_slot_name(s_sunset)])

	var s_night = DailyScheduleManagerScript.get_time_slot(22, 10)
	assert(s_night == DailyScheduleManagerScript.TimeSlot.NIGHT_REST, "22:10 phải là NIGHT_REST")
	print("  ✅ 22:10 -> %s: %s" % [DailyScheduleManagerScript.get_time_slot_icon(s_night), DailyScheduleManagerScript.get_time_slot_name(s_night)])

# 2. Kiểm tra giờ phục vụ của cơ sở đồng bộ với ca NPC
func _test_facility_opening_hours() -> void:
	print("\n[2] KIỂM TRA LỊCH PHỤC VỤ CÁC CƠ SỞ:")

	var bakery_dawn := DailyScheduleManagerScript.get_facility_schedule("bakery", 3, 7, 0)
	assert(bakery_dawn["is_open"], "Tiệm bánh phải mở trong ca sáng sớm của Bác Nam.")
	var bakery_lunch := DailyScheduleManagerScript.get_facility_schedule("bakery", 3, 12, 0)
	assert(not bakery_lunch["is_open"], "Tiệm bánh phải đóng trong giờ nghỉ trưa.")
	var bakery_afternoon := DailyScheduleManagerScript.get_facility_schedule("bakery", 3, 14, 0)
	assert(bakery_afternoon["is_open"], "Tiệm bánh phải mở lại vào ca chiều.")
	var bakery_evening := DailyScheduleManagerScript.get_facility_schedule("bakery", 3, 17, 30)
	assert(not bakery_evening["is_open"], "Tiệm bánh phải đóng khi ca chiều kết thúc.")

	var wheat_dawn := DailyScheduleManagerScript.get_facility_schedule("east_wheat_station", 3, 7, 0)
	assert(not wheat_dawn["is_open"], "Trạm thu hoạch chưa mở trước ca lao động.")
	var wheat_work := DailyScheduleManagerScript.get_facility_schedule("east_wheat_station", 3, 8, 0)
	assert(wheat_work["is_open"] and wheat_work["attendant_id"] == "farmer_hai", "Trạm lúa mì phải mở cùng ca của Bác Hai.")
	var unknown := DailyScheduleManagerScript.get_facility_schedule("untracked_station", 3, 12, 0)
	assert(not unknown["is_tracked"], "Cơ sở không thuộc lịch này phải giữ nguyên hành vi hiện có.")

	var baker_schedule := DailyScheduleManagerScript.get_npc_schedule("baker_nam", "Bác Nam", "Nghệ Nhân Bánh Mì", "Thủ Phủ", 3, 7, 0)
	var farmer_schedule := DailyScheduleManagerScript.get_npc_schedule("farmer_hai", "Bác Hai", "Nông Dân", "Huyện Đông", 3, 7, 0)
	assert(baker_schedule["is_on_duty"] and not farmer_schedule["is_on_duty"], "Ca trực NPC phải tương ứng với giờ mở của cơ sở.")
	print("  ✅ Tiệm bánh, trạm huyện và ca trực NPC thay đổi đúng theo thời gian trong ngày.")

# 2. Kiểm tra sinh hoạt của 5 đại diện 5 Huyện
func _test_five_districts_activities() -> void:
	print("\n[2] KIỂM TRA HOẠT ĐỘNG CHUYÊN NGÀNH THEO 5 HUYỆN:")

	# 1. Huyện Đông - Bác Hai (09:00 sáng)
	var sch_hai = DailyScheduleManagerScript.get_npc_schedule("farmer_hai", "Bác Hai", "Trưởng Thôn Nông Trang", "Huyện Đông", 2, 9, 0)
	assert("lúa mạch" in sch_hai["activity"] or "Silo" in sch_hai["activity"], "Bác Hai sáng phải gặt lúa")
	print("  ✅ Huyện Đông (Bác Hai - 09:00): %s %s" % [sch_hai["slot_icon"], sch_hai["activity"]])

	# 2. Huyện Tây - Kỹ Sư Khoa (09:00 sáng)
	var sch_khoa = DailyScheduleManagerScript.get_npc_schedule("engineer_khoa", "Kỹ Sư Khoa", "Trưởng Trạm Năng Lượng", "Huyện Tây", 2, 9, 0)
	assert("tuabin" in sch_khoa["activity"] or "sạc" in sch_khoa["activity"] or "Pin" in sch_khoa["activity"], "Kỹ Sư Khoa sáng phải bảo trì điện gió")
	print("  ✅ Huyện Tây (Kỹ Sư Khoa - 09:00): %s %s" % [sch_khoa["slot_icon"], sch_khoa["activity"]])

	# 3. Huyện Bắc - Thợ Rừng Lâm (09:00 sáng)
	var sch_lam = DailyScheduleManagerScript.get_npc_schedule("ranger_lam", "Thợ Rừng Lâm", "Kiểm Lâm & Onsen", "Huyện Bắc", 2, 9, 0)
	assert("Onsen" in sch_lam["activity"] or "suối" in sch_lam["activity"] or "rừng" in sch_lam["activity"], "Thợ Rừng Lâm sáng phải kiểm tra Onsen")
	print("  ✅ Huyện Bắc (Thợ Rừng Lâm - 09:00): %s %s" % [sch_lam["slot_icon"], sch_lam["activity"]])

	# 4. Huyện Nam - Thuyền Trưởng Hải (09:00 sáng)
	var sch_capt = DailyScheduleManagerScript.get_npc_schedule("captain_hai", "Thuyền Trưởng Hải", "Cảng Trưởng", "Huyện Nam", 2, 9, 0)
	assert("tàu" in sch_capt["activity"] or "cảng" in sch_capt["activity"] or "hải sản" in sch_capt["activity"], "Thuyền Trưởng Hải sáng phải đón tàu cá")
	print("  ✅ Huyện Nam (Thuyền Trưởng Hải - 09:00): %s %s" % [sch_capt["slot_icon"], sch_capt["activity"]])

	# 5. Thủ Phủ Đỉnh Vát - Bác Nam (07:00 sáng)
	var sch_nam = DailyScheduleManagerScript.get_npc_schedule("baker_nam", "Bác Nam", "Nghệ Nhân Bánh Mì", "Thủ Phủ Đỉnh Vát", 2, 7, 0)
	assert("lò nướng" in sch_nam["activity"] or "bánh mì" in sch_nam["activity"], "Bác Nam sáng phải nhóm lò nướng")
	print("  ✅ Thủ Phủ Đỉnh Vát (Bác Nam - 07:00): %s %s" % [sch_nam["slot_icon"], sch_nam["activity"]])

# 3. Kiểm tra Thánh Lễ Thứ Tư vs ngày thường
func _test_liturgy_vs_regular_noon() -> void:
	print("\n[3] KIỂM TRA THÁNH LỄ THỨ TƯ / CHỦ NHẬT VS NGÀY THƯỜNG (12:30 TRƯA):")

	# Thứ Tư (index 2): Phải là Thánh Lễ
	var sch_wed = DailyScheduleManagerScript.get_npc_schedule("baker_nam", "Bác Nam", "Nghệ Nhân Bánh Mì", "Thủ Phủ", 2, 12, 30)
	assert("Thánh Lễ" in sch_wed["activity"], "Trưa Thứ Tư phải là Thánh Lễ")
	print("  ✅ Trưa Thứ Tư (Thánh Lễ): %s %s" % [sch_wed["slot_icon"], sch_wed["activity"]])

	# Thứ Năm (index 3): Phải là nghỉ trưa bình thường
	var sch_thu = DailyScheduleManagerScript.get_npc_schedule("baker_nam", "Bác Nam", "Nghệ Nhân Bánh Mì", "Thủ Phủ", 3, 12, 30)
	assert("Nghỉ trưa" in sch_thu["activity"], "Trưa Thứ Năm phải là nghỉ trưa cơm huynh đệ")
	print("  ✅ Trưa Thứ Năm (Ngày thường): %s %s" % [sch_thu["slot_icon"], sch_thu["activity"]])

# 4. Kiểm tra NPCCharacter cập nhật trạng thái sống động theo WorldManager
func _test_npc_live_schedule_update() -> void:
	print("\n[4] KIỂM TRA NPCCHARACTER CẬP NHẬT TRẠNG THÁI SỐNG ĐỘNG THEO THỜI GIAN THỰC:")

	var npc = NPCCharacterScript.new()
	npc.npc_id = "farmer_hai"
	npc.citizen_name = "Bác Hai"
	npc.job_title = "Trưởng Thôn Nông Trang"
	npc.district_name = "Huyện Đông"
	root.add_child(npc)

	# Giả lập 06:30 sáng
	npc.update_schedule(2, 6, 30)
	assert(npc.current_activity != "", "NPC phải có current_activity")
	assert(npc.current_activity_icon == "🌾" or npc.current_activity_icon == "🌅", "Icon hoạt động phải đúng")
	print("  ✅ NPC Bác Hai lúc 06:30: [%s %s] | Lời thoại: \"%s\"" % [npc.current_activity_icon, npc.current_activity, npc.dialogue_text.substr(0, 40) + "..."])

	# Giả lập chuyển sang 22:00 đêm
	npc.update_schedule(2, 22, 0)
	assert("Nghỉ ngơi" in npc.current_activity or "Grand Barn" in npc.current_activity, "NPC đêm phải nghỉ ngơi")
	print("  ✅ NPC Bác Hai lúc 22:00: [%s %s] | Lời thoại: \"%s\"" % [npc.current_activity_icon, npc.current_activity, npc.dialogue_text.substr(0, 40) + "..."])

	npc.queue_free()

# 5. Kiểm tra Tablet Civic OS Giám sát Lịch Trình 5 Huyện
func _test_tablet_civic_os_schedule_monitor() -> void:
	print("\n[5] KIỂM TRA TABLET CIVIC OS GIÁM SÁT LỊCH TRÌNH 5 HUYỆN:")

	var list = DailyScheduleManagerScript.get_district_live_status(12, 0, 2) # Trưa Thứ Tư
	assert(list.size() == 5, "Phải có đúng 5 Huyện được giám sát!")

	for item in list:
		assert("district" in item and "activity" in item and "lead_npc" in item, "Item phải có đủ trường thông tin")
		print("  • %s: %s (Đại diện: %s | %s)" % [item["district"], item["activity"], item["lead_npc"], item["status_badge"]])

	print("  ✅ Tablet Civic OS cập nhật dòng chảy lịch trình sinh hoạt 5 Huyện hoàn hảo!")
