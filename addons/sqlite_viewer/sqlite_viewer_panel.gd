@tool
extends Control

# ==============================================================================
# SQLITE VIEWER PANEL (BẢNG DUYỆT & TRỰC QUAN HÓA CƠ SỞ DỮ LIỆU TÂN THẾ GIỚI)
# ==============================================================================

const DB_PATH: String = "user://tan_the_gioi.db"

var db_instance: Object = null
var current_table_name: String = "world_timeline"
var table_list: ItemList
var data_tree: Tree
var search_input: LineEdit
var sql_input: LineEdit
var status_label: Label
var limit_selector: OptionButton
var table_count_cache: Dictionary = {}

func _ready() -> void:
	custom_minimum_size = Vector2(800, 500)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	_build_ui()
	_connect_database()
	_refresh_tables_and_view()

func _build_ui() -> void:
	# Dọn dẹp con cũ nếu có
	for child in get_children():
		child.queue_free()

	var root_vbox = VBoxContainer.new()
	root_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_vbox.anchor_right = 1.0
	root_vbox.anchor_bottom = 1.0
	root_vbox.add_theme_constant_override("separation", 6)
	add_child(root_vbox)

	# --- 1. THANH TIÊU ĐỀ TRÊN CÙNG ---
	var top_panel = PanelContainer.new()
	var top_style = StyleBoxFlat.new()
	top_style.bg_color = Color(0.12, 0.16, 0.22, 1.0)
	top_style.content_margin_left = 12
	top_style.content_margin_right = 12
	top_style.content_margin_top = 8
	top_style.content_margin_bottom = 8
	top_panel.add_theme_stylebox_override("panel", top_style)
	root_vbox.add_child(top_panel)

	var top_hbox = HBoxContainer.new()
	top_hbox.add_theme_constant_override("separation", 12)
	top_panel.add_child(top_hbox)

	var title_lbl = Label.new()
	title_lbl.text = "🗄️ TÂN THẾ GIỚI - SQLITE DATABASE VIEWER"
	title_lbl.add_theme_font_size_override("font_size", 14)
	title_lbl.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0))
	top_hbox.add_child(title_lbl)

	var path_lbl = Label.new()
	path_lbl.text = "(%s)" % DB_PATH
	path_lbl.add_theme_font_size_override("font_size", 11)
	path_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	path_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(path_lbl)

	var refresh_btn = Button.new()
	refresh_btn.text = "🔄 Làm Mới (Refresh)"
	refresh_btn.pressed.connect(_on_refresh_pressed)
	top_hbox.add_child(refresh_btn)

	# --- 2. THANH TRUY VẤN SQL NHANH ---
	var sql_hbox = HBoxContainer.new()
	sql_hbox.add_theme_constant_override("separation", 8)
	root_vbox.add_child(sql_hbox)

	var sql_label = Label.new()
	sql_label.text = "  ⚡ SQL Query:"
	sql_label.add_theme_font_size_override("font_size", 12)
	sql_hbox.add_child(sql_label)

	sql_input = LineEdit.new()
	sql_input.placeholder_text = "Nhập câu lệnh SQL tuỳ chọn (ví dụ: SELECT * FROM citizens WHERE salary > 400;)"
	sql_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sql_input.text_submitted.connect(func(_t): _execute_custom_sql())
	sql_hbox.add_child(sql_input)

	var exec_btn = Button.new()
	exec_btn.text = "▶ Thực Thi (Run)"
	exec_btn.pressed.connect(_execute_custom_sql)
	sql_hbox.add_child(exec_btn)

	# --- 3. BẢNG PHÂN CHIA (HSPLIT CONTAINER: TABLES + DATA GRID) ---
	var hsplit = HSplitContainer.new()
	hsplit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hsplit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hsplit.split_offset = 220
	root_vbox.add_child(hsplit)

	# KHỐI TRÁI: DANH SÁCH BẢNG
	var left_vbox = VBoxContainer.new()
	left_vbox.custom_minimum_size = Vector2(200, 0)
	hsplit.add_child(left_vbox)

	var tables_header = Label.new()
	tables_header.text = "📊 CÁC BẢNG DỮ LIỆU"
	tables_header.add_theme_font_size_override("font_size", 12)
	tables_header.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	left_vbox.add_child(tables_header)

	table_list = ItemList.new()
	table_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	table_list.item_selected.connect(_on_table_selected)
	left_vbox.add_child(table_list)

	# KHỐI PHẢI: THANH TÌM KIẾM & BẢNG LƯỚI DATA
	var right_vbox = VBoxContainer.new()
	right_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hsplit.add_child(right_vbox)

	var filter_hbox = HBoxContainer.new()
	filter_hbox.add_theme_constant_override("separation", 8)
	right_vbox.add_child(filter_hbox)

	search_input = LineEdit.new()
	search_input.placeholder_text = "🔍 Lọc nhanh theo từ khóa..."
	search_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search_input.text_changed.connect(func(_t): _load_table_data(current_table_name))
	filter_hbox.add_child(search_input)

	var limit_label = Label.new()
	limit_label.text = "Giới hạn:"
	filter_hbox.add_child(limit_label)

	limit_selector = OptionButton.new()
	limit_selector.add_item("50 dòng", 50)
	limit_selector.add_item("100 dòng", 100)
	limit_selector.add_item("250 dòng", 250)
	limit_selector.add_item("500 dòng", 500)
	limit_selector.select(1) # 100 dòng mặc định
	limit_selector.item_selected.connect(func(_i): _load_table_data(current_table_name))
	filter_hbox.add_child(limit_selector)

	data_tree = Tree.new()
	data_tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	data_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	data_tree.column_titles_visible = true
	data_tree.hide_root = true
	data_tree.select_mode = Tree.SELECT_ROW
	right_vbox.add_child(data_tree)

	# --- 4. THANH TRẠNG THÁI ĐÁY ---
	status_label = Label.new()
	status_label.text = " Sẵn sàng."
	status_label.add_theme_font_size_override("font_size", 11)
	status_label.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8))
	root_vbox.add_child(status_label)

func _connect_database() -> void:
	if not ClassDB.class_exists("SQLite"):
		status_label.text = " ⚠️ Lỗi: GDExtension SQLite không khả dụng!"
		return

	if db_instance == null:
		db_instance = ClassDB.instantiate("SQLite")
		db_instance.path = DB_PATH
		if not db_instance.open_db():
			status_label.text = " ⚠️ Không thể mở database tại: %s" % DB_PATH
			db_instance = null
			return

func _refresh_tables_and_view() -> void:
	if db_instance == null:
		_connect_database()
	if db_instance == null:
		return

	table_list.clear()

	# Lấy danh sách bảng trong SQLite
	var query = "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name;"
	db_instance.query(query)
	var tables = db_instance.query_result

	if tables == null or tables.is_empty():
		status_label.text = " ⚠️ Không tìm thấy bảng nào trong database."
		return

	var select_idx: int = 0
	for i in range(tables.size()):
		var t_name = str(tables[i].get("name", ""))
		# Đếm số dòng
		db_instance.query("SELECT COUNT(*) as cnt FROM %s;" % t_name)
		var cnt_res = db_instance.query_result
		var count: int = 0
		if cnt_res != null and not cnt_res.is_empty():
			count = int(cnt_res[0].get("cnt", 0))
		table_count_cache[t_name] = count

		var icon = _get_icon_for_table(t_name)
		table_list.add_item("%s %s (%d)" % [icon, t_name, count])
		table_list.set_item_metadata(i, t_name)

		if t_name == current_table_name:
			select_idx = i

	table_list.select(select_idx)
	_load_table_data(current_table_name)

func _get_icon_for_table(table_name: String) -> String:
	match table_name:
		"world_timeline": return "⏳"
		"citizens": return "👥"
		"enterprises": return "🏢"
		"treasury_ledger": return "💰"
		"housing_plots": return "🏡"
		"citizen_certificates": return "📜"
		_: return "📄"

func _on_table_selected(index: int) -> void:
	var t_name = table_list.get_item_metadata(index)
	if t_name != null:
		current_table_name = str(t_name)
		search_input.clear()
		sql_input.text = "SELECT * FROM %s LIMIT 100;" % current_table_name
		_load_table_data(current_table_name)

func _on_refresh_pressed() -> void:
	_refresh_tables_and_view()

func _load_table_data(table_name: String) -> void:
	if db_instance == null:
		return

	var limit_val: int = limit_selector.get_selected_id()
	if limit_val <= 0:
		limit_val = 100

	var filter_text = search_input.text.strip_edges()
	var sql: String = ""

	if filter_text.is_empty():
		sql = "SELECT * FROM %s LIMIT %d;" % [table_name, limit_val]
	else:
		# Lấy các cột để tạo WHERE LIKE
		db_instance.query("PRAGMA table_info(%s);" % table_name)
		var columns = db_instance.query_result
		var like_conditions: Array[String] = []
		if columns != null:
			for col in columns:
				var col_name = str(col.get("name", ""))
				like_conditions.append("%s LIKE '%%%s%%'" % [col_name, filter_text.replace("'", "''")])
		
		if like_conditions.is_empty():
			sql = "SELECT * FROM %s LIMIT %d;" % [table_name, limit_val]
		else:
			sql = "SELECT * FROM %s WHERE %s LIMIT %d;" % [table_name, " OR ".join(like_conditions), limit_val]

	_execute_and_render_query(sql, table_name)

func _execute_custom_sql() -> void:
	var sql = sql_input.text.strip_edges()
	if sql.is_empty():
		return
	_execute_and_render_query(sql, "Custom Query")

func _execute_and_render_query(sql: String, source_label: String) -> void:
	if db_instance == null:
		return

	var start_time = Time.get_ticks_msec()
	db_instance.query(sql)
	var elapsed = Time.get_ticks_msec() - start_time
	var rows = db_instance.query_result

	data_tree.clear()

	if rows == null or rows.is_empty():
		data_tree.columns = 1
		data_tree.set_column_title(0, "Kết quả")
		var empty_root = data_tree.create_item()
		var empty_item = data_tree.create_item(empty_root)
		empty_item.set_text(0, "(Không có bản ghi nào khớp với truy vấn)")
		status_label.text = " [%s] 0 kết quả tìm thấy (thời gian: %dms)" % [source_label, elapsed]
		return

	# Lấy danh sách cột từ hàng đầu tiên
	var first_row = rows[0]
	var col_names: Array = first_row.keys()
	data_tree.columns = col_names.size()

	for i in range(col_names.size()):
		data_tree.set_column_title(i, str(col_names[i]))
		data_tree.set_column_expand(i, true)

	var tree_root = data_tree.create_item()

	for r_idx in range(rows.size()):
		var r = rows[r_idx]
		var item = data_tree.create_item(tree_root)
		for c_idx in range(col_names.size()):
			var key = col_names[c_idx]
			var val = r.get(key, "")
			item.set_text(c_idx, str(val))
			# Đổi màu nhẹ giữa các hàng (Zebra striping)
			if r_idx % 2 == 1:
				item.set_custom_bg_color(c_idx, Color(0.15, 0.18, 0.22, 0.4))

	var total_cached = table_count_cache.get(current_table_name, rows.size())
	status_label.text = " [%s] Hiển thị %d / %d bản ghi | Thời gian truy vấn: %dms | SQLite: user://tan_the_gioi.db" % [
		source_label, rows.size(), total_cached, elapsed
	]
