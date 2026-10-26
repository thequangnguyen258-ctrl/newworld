extends SceneTree

# ==============================================================================
# TEST AUTOMATION: SQLITE VIEWER DOCK & WORKBENCH (GODOT 4.6.2)
# Tuân thủ:
# - RULE 6: END_TO_END_INTERACTION_TESTING_STANDARD
# - RULE 11: IN_EDITOR_FIDELITY_STANDARD (@tool compliance)
# ==============================================================================

const SQLiteViewerPanelScript = preload("res://addons/sqlite_viewer/sqlite_viewer_panel.gd")
const DatabaseManagerScript = preload("res://scripts/simulation/database_manager.gd")

func _init() -> void:
	print("\n==================================================================")
	print("🧪 BẮT ĐẦU TEST: SQLITE VIEWER DOCK (BẢNG ĐIỀU KHIỂN DATABASE)")
	print("==================================================================")

	# 1. Khởi tạo Database nếu chưa có
	var db = root.get_node_or_null("DatabaseManager")
	if db == null:
		db = DatabaseManagerScript.new()
		root.add_child(db)
		db._init_database()

	# 2. Khởi tạo SQLite Viewer Panel
	print("\n--- 1. KHỞI TẠO SQLITE VIEWER PANEL ---")
	var panel = SQLiteViewerPanelScript.new()
	root.add_child(panel)
	panel._ready()

	assert(panel.db_instance != null, "SQLiteViewerPanel phải mở được kết nối SQLite")
	print(" [PASS] SQLiteViewerPanel nạp và kết nối database thành công.")

	# 3. Kiểm tra danh sách bảng
	print("\n--- 2. KIỂM THỬ DANH SÁCH BẢNG HIỂN THỊ ---")
	assert(panel.table_list != null, "Panel phải có ItemList danh sách bảng")
	assert(panel.table_list.item_count >= 5, "Database phải có tối thiểu 5 bảng cốt lõi")
	print("  - Số lượng bảng phát hiện được: %d" % panel.table_list.item_count)
	for i in range(panel.table_list.item_count):
		print("    • %s" % panel.table_list.get_item_text(i))
	print(" [PASS] Danh mục bảng hiển thị đầy đủ các bảng dữ liệu của Tân Thế Giới.")

	# 4. Kiểm tra nạp dữ liệu bảng world_timeline
	print("\n--- 3. KIỂM THỬ NẠP DỮ LIỆU BẢNG 'world_timeline' ---")
	panel._load_table_data("world_timeline")
	assert(panel.data_tree.columns >= 5, "Bảng world_timeline phải có nhiều cột")
	assert(panel.data_tree.get_root() != null, "Data Tree phải có root")
	assert(panel.data_tree.get_root().get_child_count() > 0, "Phải có dữ liệu hàng trong bảng")
	print("  - Số cột hiển thị: %d | Số hàng: %d" % [
		panel.data_tree.columns, panel.data_tree.get_root().get_child_count()
	])
	print(" [PASS] Dữ liệu bảng world_timeline kết xuất dạng bảng lưới thành công.")

	# 5. Kiểm tra nạp dữ liệu bảng citizens
	print("\n--- 4. KIỂM THỬ NẠP DỮ LIỆU BẢNG 'citizens' ---")
	panel._load_table_data("citizens")
	assert(panel.data_tree.columns >= 10, "Bảng citizens phải có đầy đủ các cột thuộc tính")
	print("  - Số cột bảng citizens: %d" % panel.data_tree.columns)
	print(" [PASS] Bảng citizens hiển thị trực quan thành công.")

	# 6. Kiểm tra thực thi truy vấn tuỳ chỉnh Custom SQL
	print("\n--- 5. KIỂM THỬ TRUY VẤN SQL TUỲ CHỈNH (CUSTOM SQL) ---")
	panel.sql_input.text = "SELECT COUNT(*) as total_citizens FROM citizens;"
	panel._execute_custom_sql()
	assert(panel.data_tree.columns == 1, "Kết quả COUNT(*) phải có 1 cột")
	assert(panel.data_tree.get_root().get_child_count() == 1, "Phải có 1 hàng kết quả")
	print(" [PASS] Chạy câu lệnh SQL tuỳ chỉnh thành công.")

	print("\n==================================================================")
	print("🎉 TOÀN BỘ CÁC BÀI TEST SQLITE VIEWER DOCK ĐÃ THÀNH CÔNG RỰC RỠ (100% PASS)!")
	print("==================================================================")
	if is_instance_valid(panel):
		panel.free()
	quit(0)
