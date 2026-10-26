extends SceneTree

var world: Node
var player: CharacterBody3D
var test_frames: int = 0

func _initialize() -> void:
	print("=================================================================")
	print("🎭 BẮT ĐẦU KIỂM THỬ: HỆ THỐNG NHÂN VẬT, ĐỘ TUỔI, TRANG PHỤC & NGHỀ")
	print("=================================================================")
	
	# --- PHẦN 1: KIỂM THỬ MODULAR HUMANOID BUILDER ---
	print("\n--- 1. KIỂM THỬ TẠO HÌNH 4 ĐỘ TUỔI & 9 TRANG PHỤC NGHỀ NGHIỆP ---")
	
	var ages = [
		{"group": ModularHumanoidBuilder.AgeGroup.CHILD, "name": "Thiếu Nhi"},
		{"group": ModularHumanoidBuilder.AgeGroup.YOUTH, "name": "Thanh Thiếu Niên"},
		{"group": ModularHumanoidBuilder.AgeGroup.ADULT, "name": "Trưởng Thành"},
		{"group": ModularHumanoidBuilder.AgeGroup.ELDER, "name": "Trưởng Lão"}
	]
	
	for a in ages:
		var model = ModularHumanoidBuilder.build_character_model(ModularHumanoidBuilder.ProfessionType.CITIZEN_KID if a["group"] == ModularHumanoidBuilder.AgeGroup.CHILD else ModularHumanoidBuilder.ProfessionType.FARMER, a["group"])
		assert(model != null, "Mô hình không được null")
		assert(model.get_child_count() > 0, "Mô hình phải có các chi tiết giải phẫu/trang phục")
		print("  ✅ Tạo thành công độ tuổi: %s (Số bộ phận: %d)" % [a["name"], model.get_child_count()])
		model.free()
		
	var professions = [
		{"type": ModularHumanoidBuilder.ProfessionType.MAYOR, "name": "Thị Trưởng"},
		{"type": ModularHumanoidBuilder.ProfessionType.CARPENTER, "name": "Thợ Mộc"},
		{"type": ModularHumanoidBuilder.ProfessionType.ENGINEER, "name": "Kỹ Sư"},
		{"type": ModularHumanoidBuilder.ProfessionType.FARMER, "name": "Nông Dân"},
		{"type": ModularHumanoidBuilder.ProfessionType.DOCTOR, "name": "Bác Sĩ"},
		{"type": ModularHumanoidBuilder.ProfessionType.BAKER, "name": "Thợ Bánh Mì"},
		{"type": ModularHumanoidBuilder.ProfessionType.TEACHER, "name": "Giáo Viên"},
		{"type": ModularHumanoidBuilder.ProfessionType.STUDENT, "name": "Học Sinh"},
		{"type": ModularHumanoidBuilder.ProfessionType.CITIZEN_KID, "name": "Thiếu Nhi"}
	]
	
	for p in professions:
		var p_model = ModularHumanoidBuilder.build_character_model(p["type"])
		assert(p_model != null, "Mô hình nghề nghiệp không được null")
		print("  ✅ Tạo thành công trang phục & phụ kiện nghề: %s" % p["name"])
		p_model.free()

	# --- PHẦN 2: TẢI MAIN WORLD & KIỂM THỬ KHÔNG GIAN THỰC TẾ ---
	print("\n--- 2. KHỞI CHẠY THẾ GIỚI & KIỂM TRA DÂN CƯ THỦ PHỦ (300 NPCS) ---")
	var scn = load("res://scenes/core/main_world.tscn")
	assert(scn != null, "Không load được main_world.tscn")
	world = scn.instantiate()
	root.add_child(world)
	player = world.get_node("Player")
	assert(player != null, "Không tìm thấy Player trong world")

var test_done: bool = false

func _physics_process(delta: float) -> bool:
	if test_done:
		return true
	test_frames += 1
	if test_frames < 5:
		return false # Đợi vài frame cho world khởi tạo hoàn tất
	test_done = true
		
	# Kiểm tra Player có mô hình 3D Thị Trưởng
	var mayor_model = player.get_node_or_null("MayorVisualModel")
	assert(mayor_model != null, "Player phải có MayorVisualModel!")
	print("  ✅ Player (Thị Trưởng) đã nạp mô hình 3D Anime Stylized thành công.")

	# Kiểm tra container ResidentNPCs
	var landscape = world.get_node_or_null("NaturalLandscape")
	assert(landscape != null, "Không tìm thấy NaturalLandscape!")
	var npc_container = landscape.get_node_or_null("ResidentNPCs")
	assert(npc_container != null, "Không tìm thấy container ResidentNPCs!")
	
	var npcs = npc_container.get_children()
	print("  👥 Số lượng NPC cư dân trong thế giới: %d (Kỳ vọng: 300)" % npcs.size())
	assert(npcs.size() == 300, "Phải có đúng 300 NPC cư dân trong giai đoạn Thủ Phủ!")
	var citizen_manager := landscape.get_node_or_null("CitizenManager") as CitizenManager
	assert(citizen_manager != null and citizen_manager.citizen_registry.size() == 300, "Mỗi NPC phải gắn với roster 300 hồ sơ cư dân.")
	var seen_citizen_ids: Dictionary = {}
	for i in range(npcs.size()):
		var npc = npcs[i] as NPCCharacter
		assert(npc != null, "Node phải là instance của NPCCharacter")
		assert(npc.has_daily_schedule and npc.citizen_data != null, "Mỗi NPC phải dùng dữ liệu cư dân và lịch sinh hoạt chung.")
		assert(not seen_citizen_ids.has(npc.citizen_id), "Không được tạo hai NPC cho cùng một cư dân.")
		seen_citizen_ids[npc.citizen_id] = true
		if i < 8:
			print("    • NPC [%s] children: %s" % [npc.citizen_name, str(npc.get_children().map(func(c): return c.name))])
		var visual = npc.get_node_or_null("CharacterVisualModel")
		var nameplate = npc.nameplate if npc.nameplate else npc.get_node_or_null("FloatingNameplate")
		assert(visual != null, "NPC %s phải có CharacterVisualModel" % npc.citizen_name)
		assert(nameplate != null, "NPC %s phải có FloatingNameplate 3D" % npc.citizen_name)
		if i < 8:
			print("    • [%d] %s (%dt - %s) | Nghề: %s | CCCD: %s | Tọa độ: (%.1f, %.1f, %.1f)" % [
				i + 1, npc.citizen_name, npc.age, npc.job_title, npc.cert_code, npc.cccd_number,
				npc.global_position.x, npc.global_position.y, npc.global_position.z
			])
	var farmer: NPCCharacter = npcs[0]
	farmer.update_schedule(0, 9, 0)
	assert(farmer.schedule_destination == "farm" and farmer.is_on_duty, "Nông dân phải được điều phối ra đồng trong giờ làm.")
	for npc_value in npcs:
		var npc := npc_value as NPCCharacter
		npc.update_schedule(2, 12, 0)
	assert((npcs[0] as NPCCharacter).schedule_destination == "gathering", "Ngày lễ, NPC phải di chuyển về khu sinh hoạt chung.")
	farmer.update_schedule(0, 12, 0)
	assert(farmer.schedule_destination == "rest" and farmer.schedule_pose == "sit", "Giữa ngày thường, cư dân phải nghỉ trưa tại nhà.")
	farmer.update_schedule(0, 22, 0)
	assert(farmer.schedule_destination == "home" and farmer.schedule_pose == "sleep", "Ban đêm, cư dân phải về nhà để ngủ.")
	var home_position := farmer.target_position
	farmer.global_position = home_position + Vector3(2.0, 0.0, 0.0)
	farmer.global_position.y = ModularNatureChunk.get_world_height(farmer.global_position.x, farmer.global_position.z)
	farmer._process(0.5)
	assert(
		Vector2(farmer.global_position.x, farmer.global_position.z).distance_to(Vector2(home_position.x, home_position.z)) < 2.0,
		"Cư dân đang ngủ phải tiếp tục đi về nhà trước khi vào tư thế ngủ."
	)
		
	# --- PHẦN 3: KIỂM THỬ TƯƠNG TÁC THẺ CĂN CƯỚC HOLOGRAM (CITIZEN ID MODAL) ---
	print("\n--- 3. KIỂM THỬ TƯƠNG TÁC THẺ CĂN CƯỚC SỐ & MODAL ---")
	var hud = world.get_node_or_null("HUDOverlay") as HUDOverlay
	assert(hud != null, "Không tìm thấy HUDOverlay!")
	var modal = hud.citizen_modal as CitizenIDModal
	assert(modal != null, "Không tìm thấy CitizenIDModal trong HUDOverlay!")
	assert(modal.visible == false, "Modal ban đầu phải ẩn")
	
	# Giả lập tương tác mở thẻ căn cước của Bác Hai (Nông dân)
	var bac_hai = npcs[0] as NPCCharacter
	bac_hai.trigger_interaction()
	if hud.dialogue_modal and hud.dialogue_modal.visible:
		hud._handle_dialogue_action("open_cccd")
	
	assert(modal.visible == true, "Modal phải hiển thị sau khi tương tác")
	assert(modal.name_label.text == "Bác Hai", "Tên trên thẻ phải là Bác Hai")
	assert(modal.cccd_label.text == "TTG-2026-0082", "Mã CCCD phải khớp")
	assert(modal.job_label.text == "Nông Dân Sinh Thái", "Nghề nghiệp phải khớp")
	print("  ✅ Thẻ Căn Cước hiển thị chuẩn xác thông tin sinh trắc & ngành nghề!")
	print("     Hộp thoại: %s" % modal.dialogue_box.text)
	
	# Kiểm tra nút Động viên (Tăng điểm hòa hợp)
	var prev_harmony = bac_hai.harmony_score
	modal._on_encourage_pressed()
	assert(bac_hai.harmony_score >= prev_harmony, "Điểm hòa hợp phải tăng sau khi động viên")
	print("  ✅ Nút Động viên hoạt động: Hòa hợp = %.1f%%" % bac_hai.harmony_score)
	
	# Kiểm tra nút Cấp học bổng (Tăng cấp độ kỹ năng)
	var prev_skill = bac_hai.skill_level
	modal._on_scholarship_pressed()
	assert(bac_hai.skill_level == mini(prev_skill + 1, 10), "Cấp tay nghề phải tăng 1 cấp")
	print("  ✅ Nút Cấp học bổng hoạt động: Cấp tay nghề = %d/10" % bac_hai.skill_level)
	
	# Đóng modal
	modal._on_close_pressed()
	assert(modal.visible == false, "Modal phải đóng thành công")
	print("  ✅ Đóng Thẻ Căn Cước thành công.")

	print("\n=================================================================")
	print("🎉 TẤT CẢ CÁC KIỂM THỬ NHÂN VẬT, ĐỘ TUỔI, TRANG PHỤC & NGHỀ ĐÃ ĐẠT 100%!")
	print("=================================================================")
	quit(0)
	return false
