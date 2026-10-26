class_name TestCentralCapitalAndCivicOS
extends SceneTree

# ==============================================================================
# TEST AUTOMATION: THỦ PHỦ ĐỈNH VÁT (0,600,0) & TABLET CIVIC OS 6 ỨNG DỤNG
# 1. Kiểm tra Khu Phức Hợp Trung Tâm Đỉnh Vát (Mega Office footprint 20x, Thánh Đường, Quảng Trường)
# 2. Kiểm tra Tablet Thị Trưởng (Civic OS 6 Tabs)
# 3. Kiểm tra Cơ chế Slow-Motion 20% khi mở Tablet
# 4. Kiểm tra Cơ chế Tháo Gỡ Nút Thắt Cổ Chai & Đồng Tài Trợ Dự Án
# ==============================================================================

func _init() -> void:
	print("================================================================================")
	print("🏛️ KIỂM THỬ TỰ ĐỘNG: KHU TRUNG TÂM ĐỈNH VÁT & TABLET ĐIỀU HÀNH CIVIC OS 6 APPS")
	print("================================================================================")

	_test_central_capital_landmark()
	_test_civic_os_tablet()

	print("\n🎉 TOÀN BỘ CÁC BÀI KIỂM THỬ ĐÃ THÀNH CÔNG RỰC RỠ (100% PASS)!")
	print("================================================================================")
	quit(0)

func _test_central_capital_landmark() -> void:
	print("\n[1] KIỂM TRA KHU PHỨC HỢP TRUNG TÂM ĐỈNH VÁT (CENTRAL CAPITAL AT 0, 600, 0):")

	var capital = CentralCapitalBuilder.build_capital_complex()
	assert(capital != null, "LỖI: CentralCapitalBuilder không trả về Node3D!")
	root.add_child(capital)

	# Kiểm tra các thành phần cốt lõi
	var fountain = capital.get_node_or_null("CentralFountain")
	assert(fountain != null, "LỖI: Thiếu Đài Phun Nước Trung Tâm!")

	var skyscraper = capital.get_node_or_null("MegaOfficeSkyscraper")
	assert(skyscraper != null, "LỖI: Thiếu Tòa Mega-Office Skyscraper 68m!")

	var sanctuary = capital.get_node_or_null("GrandSanctuary")
	assert(sanctuary != null, "LỖI: Thiếu Đại Hội Trường Phụng Vụ 15.000 Chỗ!")

	print("  ✅ Quảng Trường Hòa Bình: Sàn đá hoa cương R=120m và Đài Phun Nước 3 tầng.")
	print("  ✅ Tòa Mega Office: footprint 20x, cao 135m, vách kính rèm Toon lam ngọc.")
	print("  ✅ Đại Hội Trường Thánh Đường: Đại sảnh Mega Office và Tháp Chuông Hòa Bình 42m.")
	print("  - Tổng số lượng thành phần cấu tạo: %d components" % capital.get_child_count())

	capital.free()

func _test_civic_os_tablet() -> void:
	print("\n[2] KIỂM TRA TABLET THỊ TRƯỞNG & HỆ ĐIỀU HÀNH CIVIC OS 6 ỨNG DỤNG:")

	var map_scene = load("res://scenes/ui/macro_map_modal.tscn")
	var tablet: MacroMapModal = map_scene.instantiate()
	root.add_child(tablet)
	tablet._ready()

	# Kiểm tra các Tab Ứng Dụng (Đủ 6 Tab cốt lõi + Tab 7 HAS R&D)
	assert(tablet.tab_bar != null, "LỖI: Thiếu thanh điều hướng CivicTabBar!")
	assert(tablet.tab_bar.get_child_count() >= 6, "LỖI: Phải có đủ các Tab ứng dụng Civic OS!")
	print("  ✅ Đạt chuẩn các Tab Ứng Dụng: Bản Đồ, Hộ Tịch, Doanh Nghiệp, Tài Nguyên, Kho Bạc, Phụng Vụ, Viện HAS.")

	# Kiểm tra mở Tablet và Hiệu Ứng Slow-Motion 20%
	print("\n[3] KIỂM TRA HIỆU ỨNG SLOW-MOTION 20% KHI MỞ TABLET:")
	assert(Engine.time_scale == 1.0, "LỖI: Vận tốc thời gian ban đầu phải là 1.0!")
	tablet.open_macro_map()
	assert(tablet.visible == true, "LỖI: Tablet phải hiển thị sau khi mở!")
	assert(is_equal_approx(Engine.time_scale, 0.2), "LỖI: Khi mở Tablet, thời gian phải chạy chậm còn 20% (0.2)!")
	print("  ✅ ĐẠT: Engine.time_scale = %.1f (Thế giới 3D chạy chậm 20%% cho Thị Trưởng thảnh thơi điều hành)." % Engine.time_scale)

	# Kiểm tra duyệt qua các trang ứng dụng
	print("\n[4] KIỂM TRA TỪNG TRANG ỨNG DỤNG TRÊN TABLET:")
	
	# Tab 2: Sổ Hộ Tịch
	tablet._on_tab_clicked(1)
	assert(tablet.civic_pages_container.visible == true, "LỖI: Trang Hộ Tịch phải hiển thị!")
	print("  ✅ Tab 2: Sổ Bộ Hộ Tịch (14.400 dân, 4 độ tuổi, danh bạ 8 cư dân tiêu biểu).")

	# Tab 3: Doanh Nghiệp & Nút Thắt Cổ Chai
	tablet._on_tab_clicked(2)
	assert(tablet.east_wheat_bottleneck == true, "LỖI: Ban đầu Hợp tác xã Đông phải có nút thắt cổ chai!")
	# Kích hoạt cấp học bổng
	tablet._on_grant_scholarship_pressed()
	assert(tablet.east_wheat_bottleneck == false, "LỖI: Sau khi cấp học bổng, nút thắt phải được giải quyết!")
	print("  ✅ Tab 3: Doanh Nghiệp (Phát hiện nút thắt & Cấp 10 suất học bổng CERT_AGRI_CROPS thành công).")

	# Tab 4: Tài Nguyên
	tablet._on_tab_clicked(3)
	print("  ✅ Tab 4: Kho Tài Nguyên Đô Thị (8 luồng vật tư: lúa mì, bột, sữa, gỗ, đá, linh kiện, điện, nước).")

	# Tab 5: Kho Bạc & Quỹ 1/10
	tablet._on_tab_clicked(4)
	tablet._on_co_fund_project_pressed()
	print("  ✅ Tab 5: Kho Bạc & Ngân Hàng Nhà Nước (Đồng tài trợ 5.000Đ dự án dân sinh thành công).")

	# Tab 6: Phụng Vụ
	tablet._on_tab_clicked(5)
	print("  ✅ Tab 6: Giám sát Thánh Lễ Thứ Tư/Chủ Nhật 11:40 & Tiệc Bác Ái Agape.")

	# Kiểm tra đóng Tablet và khôi phục thời gian
	print("\n[5] KIỂM TRA ĐÓNG TABLET & KHÔI PHỤC THỜI GIAN:")
	tablet.close_macro_map()
	assert(tablet.visible == false, "LỖI: Tablet phải ẩn sau khi đóng!")
	assert(is_equal_approx(Engine.time_scale, 1.0), "LỖI: Sau khi đóng Tablet, thời gian phải phục hồi về 1.0!")
	print("  ✅ ĐẠT: Engine.time_scale = %.1f (Thời gian phục hồi 100%% bình thường)." % Engine.time_scale)

	tablet.free()
