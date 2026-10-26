extends SceneTree

func _init() -> void:
	print("=================================================================")
	print("🧪 BẮT ĐẦU KIỂM THỬ: GIO THỨC SQLITE NATIVE TRONG GODOT 4.6")
	print("=================================================================")
	
	# Kiểm tra class SQLite có tồn tại không
	if not ClassDB.class_exists("SQLite"):
		print("❌ LỖI: Class SQLite không tồn tại trong ClassDB!")
		quit(1)
		return
		
	print("✅ Class SQLite đã đăng ký thành công vào Engine ClassDB!")
	
	var db = ClassDB.instantiate("SQLite")
	db.path = "res://data_test_temp.db"
	db.open_db()
	
	# Tạo bảng kiểm thử
	var query_drop = "DROP TABLE IF EXISTS test_citizens;"
	db.query(query_drop)
	
	var query_create = """
	CREATE TABLE test_citizens (
		id TEXT PRIMARY KEY,
		name TEXT,
		age INTEGER,
		district TEXT,
		wallet REAL
	);
	"""
	var success_create = db.query(query_create)
	print("  - Tạo bảng test_citizens: %s" % ("Thành công" if success_create else "Thất bại"))
	
	# Chèn dữ liệu mẫu
	db.query("INSERT INTO test_citizens (id, name, age, district, wallet) VALUES ('C01', 'Gioan Văn An', 24, 'DISTRICT_PLATEAU_CORE', 1500.5);")
	db.query("INSERT INTO test_citizens (id, name, age, district, wallet) VALUES ('C02', 'Maria Kim Ngân', 23, 'DISTRICT_PLATEAU_CORE', 2000.0);")
	db.query("INSERT INTO test_citizens (id, name, age, district, wallet) VALUES ('C03', 'Giuse Hữu Phúc', 25, 'DISTRICT_EAST_FARMS', 850.0);")
	
	# Truy vấn dữ liệu
	db.query("SELECT * FROM test_citizens WHERE district = 'DISTRICT_PLATEAU_CORE' ORDER BY wallet DESC;")
	var results = db.query_result
	
	print("  - Kết quả truy vấn cư dân Đỉnh Vát (Sắp xếp theo ví tiền giảm dần):")
	for row in results:
		print("    + [%s] %s (%d tuổi) - Ví tiền: %.1f Đ" % [row["id"], row["name"], row["age"], row["wallet"]])
		
	assert(results.size() == 2, "LỖI: Số lượng cư dân trả về không đúng!")
	assert(results[0]["name"] == "Maria Kim Ngân", "LỖI: Thứ tự sắp xếp ví tiền sai!")
	
	db.close_db()
	
	# Xóa file tạm
	var dir = DirAccess.open("res://")
	if dir and dir.file_exists("data_test_temp.db"):
		dir.remove("data_test_temp.db")
		
	print("=================================================================")
	print("🎉 NATIVE SQLITE HOẠT ĐỘNG HOÀN HẢO 100% TRÊN WINDOWS X64!")
	print("=================================================================")
	quit(0)
