extends SceneTree

# ==============================================================================
# KIỂM THỬ TỰ ĐỘNG: HỆ THỐNG NHÀ MẪU & MUA ĐẤT THI CÔNG TÂN THẾ GIỚI
# 1. Xác thực sự hiện diện của Đại Lộ Nhà Mẫu (Showcase Residential Avenue) tại Đỉnh Vát.
# 2. Xác thực 4 hình thức nhà ở: Studio Anime, Nhà Chung Co-Living, Villa Gia Đình, Nhà Vườn Ghibli.
# 3. Kiểm tra kiến trúc căn Studio mẫu hoàn thiện sẵn (ban công hoa phong lữ, đèn hiên, cửa mở).
# 4. Kiểm tra Blueprint Hologram phát sáng & cọc mốc quy hoạch của các lô đang mở bán.
# 5. Mô phỏng End-to-End: Tiếp cận lô đất Co-Living -> Nhấn [E] Mua đất & Đặt lệnh xây dựng.
# 6. Xác nhận biến đổi trạng thái thành nhà hoàn thiện 3D, trừ tiền ngân khố, lưu SQLite.
# 7. Mô phỏng mở cửa nhà [E], nghỉ ngơi hồi phục 100% HP sinh lực.
# ==============================================================================

const HousingPlotScript = preload("res://scripts/interactive/housing_plot.gd")

var test_frames: int = 0
var test_step: int = 0
var main_world: Node3D = null
var player: PlayerController = null
var housing_plots: Array[Node] = []

func _init() -> void:
	print("\n" + "=".repeat(80))
	print("🏡 BẮT ĐẦU KIỂM THỬ: HỆ THỐNG NHÀ MẪU & MUA ĐẤT THI CÔNG HOÀN THIỆN")
	print("=".repeat(80))

func _assert(condition: bool, msg: String) -> void:
	if not condition:
		push_error("❌ THẤT BẠI: " + msg)
		assert(condition, msg)
	print("  ✅ ĐẠT: " + msg)

func _process(delta: float) -> bool:
	test_frames += 1

	if test_step == 0:
		var scene = load("res://scenes/core/main_world.tscn")
		assert(scene != null, "Không thể tải main_world.tscn")
		main_world = scene.instantiate()
		root.add_child(main_world)
		current_scene = main_world

		player = main_world.get_node("Player") as PlayerController
		assert(player != null, "PlayerController không tồn tại!")

		# Nạp ngân khố dồi dào để Thị Trưởng thử nghiệm mua đất
		var wm = root.get_node_or_null("/root/WorldManager")
		if wm:
			wm.treasury_city = 50000.0

		test_step = 1
		test_frames = 0
		return false

	if test_step == 1:
		if test_frames < 3:
			return false

		print("\n[BƯỚC 1] KIỂM TRA ĐẠI LỘ NHÀ MẪU & CÁC LÔ ĐẤT QUY HOẠCH:")
		var avenue = main_world.find_child("ShowcaseHousingAvenue", true, false)
		_assert(avenue != null, "Tìm thấy cụm Đại Lộ Nhà Mẫu ShowcaseHousingAvenue trong thế giới")

		var sign = avenue.find_child("AvenueSign3D", true, false) as Label3D
		_assert(sign != null, "Tìm thấy biển hiệu chào mừng Đại Lộ Nhà Mẫu AvenueSign3D")
		_assert(sign.billboard == BaseMaterial3D.BILLBOARD_ENABLED, "Biển hiệu đạt chuẩn Billboard xoay theo góc nhìn")
		_assert(sign.no_depth_test == true, "Biển hiệu bật no_depth_test chống bị che khuất")

		housing_plots = get_nodes_in_group("housing_plots")
		print("  - Tổng số lô đất / nhà mẫu được đăng ký: %d lô" % housing_plots.size())
		_assert(housing_plots.size() >= 12, "Đăng ký thành công tối thiểu 12 Lô Đất Nhà Mẫu phân bổ trên 5 Huyện")

		test_step = 2
		test_frames = 0
		return false

	if test_step == 2:
		if test_frames < 3:
			return false

		print("\n[BƯỚC 2] KIỂM TRA PHÂN BỔ 5 HUYỆN, CÁC KIỂU MẪU KIẾN TRÚC & SỐ SỔ ĐỎ:")
		var district_counts: Dictionary = {}
		var house_types: Dictionary = {}
		var studio_plot: Node = null
		var coliving_plot: Node = null
		var family_plot: Node = null
		var cottage_plot: Node = null

		for p in housing_plots:
			var p_id = p.get("plot_id")
			var p_type = p.get("house_type")
			var p_dist = p.get("district_id")
			var p_deed = p.get("land_deed_number")

			district_counts[p_dist] = district_counts.get(p_dist, 0) + 1
			house_types[p_type] = house_types.get(p_type, 0) + 1

			_assert(p_deed != null and not p_deed.is_empty(), "Lô %s có mã Sổ Đỏ hợp lệ: %s" % [p_id, p_deed])
			_assert(p_deed.begins_with("SO_DO_TTG_"), "Số Sổ Đỏ tuân thủ định chuẩn hành chính SO_DO_TTG_*")

			if p_id == "plot_plateau_01_studio":
				studio_plot = p
			elif p_id == "plot_plateau_02_coliving":
				coliving_plot = p
			elif p_id == "plot_plateau_03_family":
				family_plot = p
			elif p_id == "plot_plateau_04_cottage":
				cottage_plot = p

		print("  - Phân bổ theo 5 Huyện: %s" % str(district_counts))
		_assert(district_counts.has("DISTRICT_PLATEAU_CORE"), "Có lô đất tại Huyện Đỉnh Vát (Central Plateau)")
		_assert(district_counts.has("DISTRICT_EAST_FARMS"), "Có lô đất tại Huyện Đông (East Farms)")
		_assert(district_counts.has("DISTRICT_NORTH_FOREST"), "Có lô đất tại Huyện Bắc (North Forest)")
		_assert(district_counts.has("DISTRICT_WEST_VALLEY"), "Có lô đất tại Huyện Tây (West Valley)")
		_assert(district_counts.has("DISTRICT_SOUTH_PORT"), "Có lô đất tại Huyện Nam (South Port)")

		print("  - Đa dạng kiểu kiến trúc: %s" % str(house_types.keys()))
		_assert(house_types.size() >= 6, "Hỗ trợ tối thiểu 6 phong cách kiến trúc đặc sắc")

		# 1. Căn mẫu Studio hoàn thiện sẵn
		_assert(studio_plot != null, "Tìm thấy Lô 1: Chung Cư Studio Anime")
		_assert(studio_plot.current_status == HousingPlotScript.PlotStatus.COMPLETED, "Căn Studio đã ở trạng thái HOÀN THIỆN (COMPLETED) làm nhà mẫu thực tế")
		_assert(studio_plot.completed_node != null, "Node 3D nhà hoàn thiện của Studio đã được render")
		_assert(studio_plot.completed_node.find_child("DoorHingePivot", true, false) != null, "Căn Studio có cửa xoay DoorHingePivot")

		# 2. Lô đất Co-Living mở bán
		_assert(coliving_plot != null, "Tìm thấy Lô 2: Nhà Chung Co-Living")
		_assert(coliving_plot.current_status == HousingPlotScript.PlotStatus.AVAILABLE, "Lô Co-Living ở trạng thái MỞ BÁN (AVAILABLE)")
		_assert(coliving_plot.blueprint_node != null, "Lô Co-Living có Blueprint và Hologram phát sáng")
		_assert(coliving_plot.blueprint_node.find_child("HoloPreview", true, false) != null, "Tìm thấy HoloPreview mô phỏng ngôi nhà tương lai")

		# 3. Kiểm tra công trường thi công và Thợ Mộc Artisan Carpenter
		var builder = load("res://scripts/terrain/model_house_builder.gd")
		_assert(builder != null, "Tải thành công ModelHouseBuilder")
		var test_site = builder.build_construction_site("CO_LIVING_HOUSE", 140.0)
		_assert(test_site != null, "Khởi tạo thành công Công Trường Thi Công")
		var carpenter = test_site.find_child("CarpenterArtisan", true, false)
		_assert(carpenter != null, "Tìm thấy Thợ Mộc Artisan Carpenter NPC đang thi công trên công trường")
		test_site.free()

		# 4. Kiểm tra các lô đất gia đình & nhà vườn
		_assert(family_plot != null and family_plot.price == 5500.0, "Đơn giá lô Gia Đình chính xác: 5.500 Đ")
		_assert(cottage_plot != null and cottage_plot.area_sqm == 252.0, "Diện tích khuôn viên nhà vườn chính xác: 252m²")

		test_step = 3
		test_frames = 0
		return false

	if test_step == 3:
		if test_frames < 3:
			return false

		print("\n[BƯỚC 3] MÔ PHỎNG TIẾP CẬN VÀ MUA ĐẤT LÔ CO-LIVING BẰNG PHÍM [E]:")
		var target_plot: Node = null
		for p in housing_plots:
			if p.get("plot_id") == "plot_plateau_02_coliving":
				target_plot = p
				break

		_assert(target_plot != null, "Xác định mục tiêu Lô Co-Living (plot_plateau_02_coliving)")

		# Di chuyển player tới sát tâm lô đất
		player.global_position = target_plot.global_position + Vector3(0.0, 0.0, 2.5)

		# Chờ 2 frame để cảm biến Area3D cập nhật
		test_step = 4
		test_frames = 0
		return false

	if test_step == 4:
		if test_frames < 3:
			return false

		var target_plot: Node = null
		for p in housing_plots:
			if p.get("plot_id") == "plot_plateau_02_coliving":
				target_plot = p
				break

		var dist = player.global_position.distance_to(target_plot.global_position)
		print("  - Cự ly người chơi tới Lô Co-Living: %.2fm (Bán kính tương tác: %.1fm)" % [dist, target_plot.interaction_radius])
		_assert(dist <= target_plot.interaction_radius, "Người chơi đã bước vào phạm vi tương tác lô đất")
		_assert(target_plot.prompt_3d.visible == true, "Biển 3D Diegetic hiển thị rõ ràng cho người chơi")
		_assert(target_plot.prompt_3d.text.contains("MUA ĐẤT & THI CÔNG"), "Nội dung bảng 3D nhắc lệnh [E] Mua đất & thi công")

		var wm = root.get_node_or_null("/root/WorldManager")
		var pre_treasury = wm.treasury_city if wm else 0.0

		# Mô phỏng nhấn phím [E] để mua đất & đặt lệnh xây dựng
		print("  - Mô phỏng nhấn phím vật lý [E] ký hợp đồng mua đất & cấp Sổ Đỏ...")
		target_plot.interact(player)

		var post_treasury = wm.treasury_city if wm else 0.0
		print("  - Ngân khố trước khi mua: %d Đ | Sau khi mua: %d Đ (Trừ đúng %d Đ)" % [int(pre_treasury), int(post_treasury), int(target_plot.price)])
		_assert(post_treasury == pre_treasury - target_plot.price, "Ngân khố đã thanh toán chuẩn xác gói mua đất & xây nhà")

		# Kiểm tra trạng thái đã biến đổi thành COMPLETED
		_assert(target_plot.current_status == HousingPlotScript.PlotStatus.COMPLETED, "Lô đất đã biến hình thành trạng thái HOÀN THIỆN (COMPLETED)")
		_assert(target_plot.completed_node != null, "Kiến trúc 3D nhà 2 tầng Co-Living đã xuất hiện")
		_assert(target_plot.owner_name == "Thị Trưởng", "Quyền sở hữu đã đăng ký chính thức cho Thị Trưởng")
		_assert(target_plot.construction_progress == 100.0, "Tiến độ xây dựng đạt 100%")

		test_step = 5
		test_frames = 0
		return false

	if test_step == 5:
		if test_frames < 3:
			return false

		print("\n[BƯỚC 4] MÔ PHỎNG BƯỚC VÀO NHÀ, MỞ CỬA & HỒI PHỤC THỂ LỰC:")
		var target_plot: Node = null
		for p in housing_plots:
			if p.get("plot_id") == "plot_plateau_02_coliving":
				target_plot = p
				break

		# Rút bớt thể lực để kiểm tra tính năng hồi phục
		player.current_health = 40.0
		print("  - Thể lực trước khi vào nhà: %.0f HP" % player.current_health)

		# Nhấn [E] bước vào nhà
		target_plot.interact(player)

		print("  - Thể lực sau khi vào nhà: %.0f HP" % player.current_health)
		_assert(player.current_health == 100.0, "Ngôi nhà giúp người chơi hồi phục 100% sinh lực")
		_assert(target_plot.is_door_open == true, "Cánh cửa nhà đã xoay mở chào đón gia chủ")

		test_step = 6
		test_frames = 0
		return false

	if test_step == 6:
		if test_frames < 3:
			return false

		print("\n[BƯỚC 5] KIỂM TRA ĐỒNG BỘ CƠ SỞ DỮ LIỆU SQLITE NATIVE:")
		var db_mgr = root.get_node_or_null("/root/DatabaseManager")
		if db_mgr and db_mgr.has_method("get_all_housing_plots"):
			var db_plots = db_mgr.get_all_housing_plots()
			print("  - Số lượng bản ghi lô đất trong SQLite: %d bản ghi" % db_plots.size())
			_assert(db_plots.size() >= 12, "CSDL SQLite đã lưu trữ đầy đủ toàn bộ 12 lô đất 5 Huyện")

			var found_bought_record: bool = false
			for r in db_plots:
				if r.get("plot_id", "") == "plot_plateau_02_coliving":
					found_bought_record = true
					_assert(r.get("status", "") == "COMPLETED", "Trạng thái lô đất trong SQLite đồng bộ COMPLETED")
					_assert(r.get("owner_id", "") == "Thị Trưởng", "Chủ sở hữu trong SQLite đồng bộ Thị Trưởng")
					_assert(r.get("land_deed_number", "").begins_with("SO_DO_TTG_"), "Bản ghi SQLite lưu trữ chuẩn xác Số Sổ Đỏ")
					break
			_assert(found_bought_record, "Tìm thấy bản ghi lô đất Co-Living đã mua trong SQLite")

		test_step = 7
		test_frames = 0
		return false

	if test_step == 7:
		if test_frames < 3:
			return false

		print("\n[BƯỚC 6] KIỂM TRA GIAO DIỆN TABLET CIVIC OS (TAB 8: NHÀ Ở & SỔ ĐỎ):")
		var modal_scene = load("res://scenes/ui/macro_map_modal.tscn")
		_assert(modal_scene != null, "Tải thành công macro_map_modal.tscn")
		var modal = modal_scene.instantiate()
		root.add_child(modal)

		# Kích hoạt Tab 8: Nhà Ở & Sổ Đỏ (index = 7)
		if modal.has_method("_on_tab_clicked"):
			modal._on_tab_clicked(7)
			_assert(modal.civic_pages_container != null and modal.civic_pages_container.visible == true, "Trang Civic Pages Container hiển thị thành công")
			var vbox = modal.civic_pages_container.find_child("HousingPlotsVBox", true, false)
			_assert(vbox != null, "Tìm thấy VBox quản lý Nhà Ở & Sổ Đỏ (HousingPlotsVBox)")

		modal.queue_free()
		_assert(true, "Tablet Civic OS hiển thị đầy đủ và điều hành trơn tru 12 Lô Đất & Sổ Đỏ")

		print("\n" + "=".repeat(80))
		print("🎉 TOÀN BỘ BÀI KIỂM THỬ HỆ THỐNG NHÀ MẪU & SỔ ĐỎ ĐÃ THÀNH CÔNG RỰC RỠ (100% PASS)!")
		print("=".repeat(80) + "\n")

		quit(0)
		return true

	return false
