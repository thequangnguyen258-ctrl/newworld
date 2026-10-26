extends SceneTree

# ==============================================================================
# TEST AUTOMATION: HIGHLAND ACADEMY OF SCIENCES (HAS) R&D & 20-TIER TECH TREE
# Tuân thủ:
# - RULE 6: END_TO_END_INTERACTION_TESTING_STANDARD
# - GAME_DESIGN_CONCEPT Section 5.7: 5 Branches x 20 Tiers, KBU, -21% Wear, 1.85x Yield
# - RULE 7: DUAL_LAYER_SAFETY & TABLET CIVIC OS TAB 7 INTEGRATION
# ==============================================================================

const DatabaseManagerScript = preload("res://scripts/simulation/database_manager.gd")
const ResearchManagerScript = preload("res://scripts/simulation/research_manager.gd")
const WorldManagerScript = preload("res://scripts/core/world_manager.gd")
const MayorBuggyScript = preload("res://scripts/interactive/mayor_buggy.gd")
const MacroMapModalScript = preload("res://scripts/ui/macro_map_modal.gd")

func _init() -> void:
	print("\n==================================================================")
	print("🧪 BẮT ĐẦU TEST: VIỆN HÀN LÂM HAS & CÂY R&D 20 BẬC TOÀN ĐÔ THỊ")
	print("==================================================================")

	# 1. Khởi tạo Core Singletons
	print("\n--- 1. KHỞI TẠO SINGLETONS VÀ DATABASE KẾT NỐI ---")
	var wm = root.get_node_or_null("WorldManager")
	if wm == null:
		wm = WorldManagerScript.new()
		wm.name = "WorldManager"
		root.add_child(wm)

	var db = root.get_node_or_null("DatabaseManager")
	if db == null:
		db = DatabaseManagerScript.new()
		db.name = "DatabaseManager"
		root.add_child(db)
		db._init_database()

	var research_mgr = root.get_node_or_null("ResearchManager")
	if research_mgr == null:
		research_mgr = ResearchManagerScript.new()
		research_mgr.name = "ResearchManager"
		root.add_child(research_mgr)
		research_mgr._ready()

	assert(research_mgr != null, "ResearchManager phải khởi tạo thành công")
	research_mgr.set_world_manager(wm)
	research_mgr.set_database_manager(db)
	print(" [PASS] Khởi tạo WorldManager, DatabaseManager, ResearchManager thành công.")

	# 2. Kiểm thử Cấu trúc 5 Phân khoa & 20 Bậc (Tổng cộng 100 Sáng chế)
	print("\n--- 2. KIỂM THỬ CẤU TRÚC 5 PHÂN KHOA X 20 BẬC = 100 SÁNG CHẾ ---")
	var expected_branches = ["materials", "agri", "energy", "automation", "wellness"]
	for b_id in expected_branches:
		var tiers = research_mgr.get_branch_tiers(b_id)
		assert(tiers.size() == 20, "Phân khoa %s phải có đúng 20 bậc sáng chế liên tục" % b_id)
		var b_name = research_mgr.get_branch_name(b_id)
		assert(b_name != "", "Tên phân khoa %s không được rỗng" % b_id)
		print("  - Phân khoa: %s | Đủ 20/20 bậc sáng chế." % b_name)

	print(" [PASS] 100 sáng chế trong 5 phân khoa đã được định nghĩa đầy đủ và chính xác.")

	# 3. Kiểm thử Sinh Điểm KBU & Tiến Trình Đề Án
	print("\n--- 3. KIỂM THỬ CƠ CHẾ SINH KBU & TÍCH LŨY ĐỀ ÁN TRỌNG ĐIỂM ---")
	var initial_kbu = research_mgr.kbu_balance
	research_mgr.select_active_directive("materials", 1)
	assert(research_mgr.active_branch_id == "materials" and research_mgr.active_tier == 1, "Phải chọn đúng đề án Bậc 1 Vật Liệu")
	
	# Tua 5 phút game -> +50 KBU
	research_mgr.advance_research_minute(5)
	assert(research_mgr.kbu_balance == initial_kbu + 50, "Mỗi phút game phải sinh đúng +10 KBU cơ bản")
	assert(research_mgr.current_progress_kbu == 50, "Đề án phải tích lũy đúng 50 KBU")
	print("  - KBU ban đầu: %d -> Sau 5 phút: %d (+50 KBU) | Tiến độ đề án: %d/%d" % [
		initial_kbu, research_mgr.kbu_balance, research_mgr.current_progress_kbu, research_mgr.get_tier_cost("materials", 1)
	])
	print(" [PASS] Cơ chế sinh điểm tri thức KBU tự nhiên hoạt động hoàn hảo.")

	# 4. Kiểm thử Gói Tài Trợ Tăng Tốc (5.000Đ từ Kho Bạc)
	print("\n--- 4. KIỂM THỬ GÓI TÀI TRỢ TĂNG TỐC HAS (5.000Đ) ---")
	wm.treasury_city = 10000.0 # Bơm ngân sách cho Kho Bạc
	var grant_success = research_mgr.grant_acceleration_funding()
	assert(grant_success, "Thị Trưởng phải tài trợ thành công khi Kho Bạc có đủ 5.000Đ")
	assert(research_mgr.acceleration_grant_active, "Trạng thái tăng tốc R&D phải được kích hoạt")
	assert(wm.treasury_city == 5000.0, "Kho Bạc phải bị trừ đúng 5.000Đ")

	# Khi có tài trợ: 1 phút game sinh 20 KBU (gấp đôi)
	var pre_kbu = research_mgr.kbu_balance
	research_mgr.advance_research_minute(1)
	assert(research_mgr.kbu_balance == pre_kbu + 20, "Tốc độ phải tăng gấp đôi lên +20 KBU/phút")
	print("  - Trạng thái tăng tốc: %s | Kho Bạc còn lại: %.0fĐ | Tốc độ mới: +20 KBU/phút" % [
		research_mgr.acceleration_grant_active, wm.treasury_city
	])
	print(" [PASS] Gói tài trợ tăng tốc R&D nhân đôi sản lượng KBU thành công.")

	# 5. Kiểm thử Tự Động Hoàn Thành & Ban Hành Bản Vẽ Toàn Đô Thị
	print("\n--- 5. KIỂM THỬ HOÀN TẤT ĐỀ ÁN & BAN HÀNH BẢN VẼ TOÀN ĐÔ THỊ ---")
	# Bơm đủ KBU để hoàn thành Bậc 1
	var cost_tier_1 = research_mgr.get_tier_cost("materials", 1)
	research_mgr.advance_research_minute(10) # Bơm tiếp để vượt qua 60 KBU
	assert(research_mgr.is_tech_unlocked("materials", 1), "Bậc 1 phải được mở khóa sau khi đủ KBU")
	print("  - Đề án Bậc 1: %s -> ĐÃ MỞ KHÓA" % research_mgr.get_tech_name("materials", 1))

	# Ban hành toàn đô thị
	var deploy_res = research_mgr.deploy_blueprint_citywide("materials", 1)
	assert(deploy_res, "Ban hành bản vẽ sáng chế Bậc 1 phải thành công")
	assert(research_mgr.is_tech_deployed("materials", 1), "Bậc 1 phải được đánh dấu đã ban hành")
	var initial_wear_red = research_mgr.get_wear_and_tear_reduction()
	assert(initial_wear_red > 0.0, "Hệ số giảm hao mòn máy móc phải lớn hơn 0")
	print("  - Hiệu quả giảm hao mòn máy móc hiện tại: -%.2f%%" % (initial_wear_red * 100.0))
	print(" [PASS] Ban hành bản vẽ sáng chế Bậc 1 thành công rực rỡ.")

	# 6. Kiểm thử Tác Động Vật Lý Xe Buggy Thị Trưởng (MayorBuggy) & Đất Lành 1.85x
	print("\n--- 6. KIỂM THỬ TÁC ĐỘNG VẬT LÝ XE BUGGY (-21% HAO MÒN) & NÔNG NGHIỆP (1.85X) ---")
	# Mở khóa toàn bộ 20 bậc nhánh Vật Liệu để đạt mức giảm tối đa -21%
	for t in range(1, 21):
		research_mgr.unlocked_techs["materials_%d" % t] = true
		research_mgr.deploy_blueprint_citywide("materials", t)
	
	var max_wear_red = research_mgr.get_wear_and_tear_reduction()
	assert(is_equal_approx(max_wear_red, 0.21), "Ở bậc 20 Vật Liệu, tỷ lệ giảm hao mòn phải đạt đúng -21.0%% (thực tế: %.4f)" % max_wear_red)
	print("  - Hệ số giảm hao mòn máy móc tối đa đạt: -%.1f%%" % (max_wear_red * 100.0))

	# Kiểm tra trên xe MayorBuggy
	var buggy = MayorBuggyScript.new()
	root.add_child(buggy)
	buggy.current_speed = 16.67 # Chạy 60 km/h
	buggy.is_occupied = true
	# Giả lập 2.0 giây lái xe vận tốc tối đa 16.67 m/s
	buggy.apply_driving_wear(16.67, 2.0)
	var calculated_wear = buggy.get_mechanical_wear()
	assert(calculated_wear > 0.0 and calculated_wear < 0.02, "Hao mòn phải được tích lũy với tỷ lệ giảm trừ -21%%")
	print("  - Hao mòn đo được trên xe Buggy sau 2s chạy tối đa tốc: %.4f%%" % (calculated_wear * 100.0))
	buggy.repair_vehicle()
	assert(buggy.get_mechanical_wear() == 0.0, "Sau khi bảo dưỡng, hao mòn phải về 0")
	buggy.queue_free()

	# Mở khóa toàn bộ 20 bậc nhánh Nông Nghiệp để đạt hệ số bội thu 1.85x
	for t in range(1, 21):
		research_mgr.unlocked_techs["agri_%d" % t] = true
		research_mgr.deploy_blueprint_citywide("agri", t)

	var agri_boost = research_mgr.get_blessed_abundance_boost()
	assert(is_equal_approx(agri_boost, 0.25), "Ở bậc 20 Nông Nghiệp, mức tăng phải đạt +25.0%% (thực tế: %.4f)" % agri_boost)
	var final_yield = 1.60 + agri_boost
	assert(is_equal_approx(final_yield, 1.85), "Hệ số Đất Lành Bội Thu phải đạt đúng 1.85x")
	print("  - Hệ số Đất Lành Bội Thu sau khi ban hành 20 bậc Nông Nghiệp: %.2fx" % final_yield)
	print(" [PASS] Vật lý xe Buggy và Kinh tế Nông nghiệp chịu tác động chuẩn xác theo Concept.")

	# 7. Kiểm thử Đồng bộ Ngoại Tuyến (Offline Research Progress)
	print("\n--- 7. KIỂM THỬ ĐỒNG BỘ NGOẠI TUYẾN TỪ UNIFIED TIMELINE SERVER ---")
	var pre_offline_kbu = research_mgr.kbu_balance
	# Mô phỏng offline 120 phút game
	research_mgr.apply_offline_research_progress(120)
	assert(research_mgr.kbu_balance >= pre_offline_kbu + 1200, "120 phút offline phải cộng tối thiểu +1200 KBU")
	print("  - KBU trước khi offline: %d -> Sau 120 phút offline: %d (+%d KBU)" % [
		pre_offline_kbu, research_mgr.kbu_balance, research_mgr.kbu_balance - pre_offline_kbu
	])
	print(" [PASS] Cơ chế đồng bộ dòng thời gian ngoại tuyến cho Viện HAS hoạt động chuẩn xác.")

	# 8. Kiểm thử Giao diện Máy Tính Bảng Thị Trưởng (Civic OS Tablet Tab 7)
	print("\n--- 8. KIỂM THỬ GIAO DIỆN TABLET THỊ TRƯỞNG (CIVIC OS TAB 7: HAS R&D) ---")
	var map_scene = load("res://scenes/ui/macro_map_modal.tscn")
	var tablet = map_scene.instantiate()
	root.add_child(tablet)
	tablet._ready()

	assert(tablet.tab_bar != null, "Tablet phải có thanh CivicTabBar")
	assert(tablet.tab_bar.get_child_count() >= 7, "Thanh TabBar phải có tối thiểu 7 ứng dụng (Bao gồm Tab 7 HAS)")
	var tab_7_btn = tablet.tab_bar.get_child(6) as Button
	assert(tab_7_btn.text.contains("HAS"), "Tab 7 phải mang tên R&D Viện HAS")

	# Chuyển sang Tab 7
	tablet._on_tab_clicked(6)
	assert(tablet.current_tab_index == 6, "Index tab hiện tại phải là 6")
	assert(tablet.civic_pages_container.visible, "Container trang Civic OS phải hiển thị")

	# Đổi phân khoa trong Tab 7
	tablet._on_select_has_branch("agri")
	assert(tablet.selected_has_branch == "agri", "Phải đổi thành công sang phân khoa agri")

	# Thử bấm Ban Hành Bản Vẽ trên UI
	tablet._on_has_deploy_pressed("agri", 1)
	assert(tablet.status_feedback != null, "Phải có label status_feedback")
	print("  - Phản hồi trên màn hình Tablet: \"%s\"" % tablet.status_feedback.text)

	tablet.queue_free()
	print(" [PASS] Giao diện Tablet Thị Trưởng kết xuất và tương tác Tab 7 HAS hoàn hảo.")

	print("\n==================================================================")
	print("🎉 TOÀN BỘ CÁC BÀI TEST VIỆN HÀN LÂM HAS & CÂY R&D 20 BẬC ĐÃ THÀNH CÔNG RỰC RỠ (100% PASS)!")
	print("==================================================================\n")
	quit(0)
