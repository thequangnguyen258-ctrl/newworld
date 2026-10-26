extends Node

# Autoload Singleton: DatabaseManager
# Quản lý Toàn Bộ Cơ Sở Dữ Liệu Quan Hệ SQLite (Local Embedded Database)
# Lưu trữ thường trực tại user://tan_the_gioi.db

signal database_synced(record_count: int)
signal transaction_logged(category: String, amount: float, fund_type: String)

const DB_PATH: String = "user://tan_the_gioi.db"

var db: Object = null
var is_db_open: bool = false

func _ready() -> void:
	_init_database()

func _init_database() -> void:
	if not ClassDB.class_exists("SQLite"):
		push_warning("[DatabaseManager] GDExtension SQLite không khả dụng, chuyển sang chế độ dự phòng RAM.")
		return
		
	db = ClassDB.instantiate("SQLite")
	db.path = DB_PATH
	if not db.open_db():
		push_error("[DatabaseManager] Không thể mở database tại: %s" % DB_PATH)
		return
		
	is_db_open = true
	db.query("PRAGMA journal_mode=WAL;")
	db.query("PRAGMA synchronous=NORMAL;")
	db.query("PRAGMA foreign_keys=ON;")
	print("[DatabaseManager] 🗄️ Mở thành công cơ sở dữ liệu SQLite (WAL Mode) tại: %s" % DB_PATH)
	_create_schema()

func _create_schema() -> void:
	if not is_db_open:
		return
		
	# Bảng Cư Dân (mô hình mới: 300 cư dân thủ phủ, không mở rộng dân số giai đoạn đầu)
	var sql_citizens = """
	CREATE TABLE IF NOT EXISTS citizens (
		citizen_id TEXT PRIMARY KEY,
		citizen_name TEXT NOT NULL,
		age INTEGER NOT NULL,
		life_stage TEXT NOT NULL DEFAULT 'THANH_NIEN',
		is_married INTEGER DEFAULT 0,
		household_id TEXT DEFAULT '',
		spouse_id TEXT DEFAULT '',
		needs_community_support INTEGER DEFAULT 0,
		fellowship_group TEXT NOT NULL,
		home_district_id TEXT NOT NULL,
		home_coord_x REAL DEFAULT 0.0,
		home_coord_z REAL DEFAULT 0.0,
		workplace_id TEXT DEFAULT '',
		job_role TEXT DEFAULT 'Chưa có việc',
		salary REAL DEFAULT 350.0,
		wallet REAL DEFAULT 500.0,
		is_church_servant INTEGER DEFAULT 0,
		servant_type TEXT DEFAULT 'NONE',
		preferred_transit_mode INTEGER DEFAULT 3,
		commute_duration_minutes REAL DEFAULT 0.0,
		energy REAL DEFAULT 100.0,
		happiness REAL DEFAULT 100.0,
		durability_clothing REAL DEFAULT 100.0,
		durability_tools REAL DEFAULT 100.0,
		durability_vehicle REAL DEFAULT 100.0,
		updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	);
	"""
	db.query(sql_citizens)
	db.query("PRAGMA table_info(citizens);")
	var citizen_columns := {}
	for field in db.query_result:
		var field_name = String(field.get("name", ""))
		citizen_columns[field_name] = true
	for column_name in ["life_stage", "is_married", "household_id", "spouse_id", "needs_community_support"]:
		if not citizen_columns.has(column_name):
			var column_definition := "TEXT DEFAULT ''"
			if column_name == "life_stage":
				column_definition = "TEXT DEFAULT 'THANH_NIEN'"
			elif column_name == "is_married" or column_name == "needs_community_support":
				column_definition = "INTEGER DEFAULT 0"
			db.query("ALTER TABLE citizens ADD COLUMN %s %s;" % [column_name, column_definition])
	
	# Bảng Chứng Chỉ Của Cư Dân (Quan hệ nhiều - nhiều)
	var sql_certs = """
	CREATE TABLE IF NOT EXISTS citizen_certificates (
		citizen_id TEXT NOT NULL,
		cert_id TEXT NOT NULL,
		PRIMARY KEY (citizen_id, cert_id),
		FOREIGN KEY (citizen_id) REFERENCES citizens(citizen_id) ON DELETE CASCADE
	);
	"""
	db.query(sql_certs)
	db.query("""
	CREATE TABLE IF NOT EXISTS citizen_relationships (
		citizen_id TEXT NOT NULL,
		related_citizen_id TEXT NOT NULL,
		relationship_type TEXT NOT NULL,
		PRIMARY KEY (citizen_id, related_citizen_id, relationship_type),
		FOREIGN KEY (citizen_id) REFERENCES citizens(citizen_id) ON DELETE CASCADE,
		FOREIGN KEY (related_citizen_id) REFERENCES citizens(citizen_id) ON DELETE CASCADE
	);
	""")
	
	# Bảng Doanh Nghiệp & Tổ Chức
	var sql_enterprises = """
	CREATE TABLE IF NOT EXISTS enterprises (
		enterprise_id TEXT PRIMARY KEY,
		enterprise_name TEXT NOT NULL,
		sector TEXT NOT NULL,
		district_id TEXT NOT NULL,
		cash_reserve REAL DEFAULT 5000.0,
		monthly_revenue REAL DEFAULT 0.0,
		monthly_expense REAL DEFAULT 0.0,
		status TEXT DEFAULT 'PROSPEROUS'
	);
	"""
	db.query(sql_enterprises)
	
	# Bảng Sổ Cái Minh Bạch Kho Bạc & Quỹ 1/10
	var sql_ledger = """
	CREATE TABLE IF NOT EXISTS treasury_ledger (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		day_index INTEGER,
		hour INTEGER,
		minute INTEGER,
		category TEXT NOT NULL,
		amount REAL NOT NULL,
		fund_type TEXT NOT NULL, -- 'CITY_TREASURY' hoặc 'CHURCH_TITHE'
		description TEXT,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	);
	"""
	db.query(sql_ledger)
	
	# Bảng Lô Đất Nhà Ở & Dự Án Nhà Mẫu (Housing Plots & Blueprints)
	var sql_housing_plots = """
	CREATE TABLE IF NOT EXISTS housing_plots (
		plot_id TEXT PRIMARY KEY,
		district_id TEXT NOT NULL,
		house_type TEXT NOT NULL,
		title TEXT NOT NULL,
		status TEXT NOT NULL, -- 'AVAILABLE', 'UNDER_CONSTRUCTION', 'COMPLETED', 'OCCUPIED'
		owner_id TEXT DEFAULT '',
		price REAL NOT NULL,
		area_sqm REAL NOT NULL,
		pos_x REAL NOT NULL,
		pos_y REAL NOT NULL,
		pos_z REAL NOT NULL,
		land_deed_number TEXT DEFAULT '',
		construction_progress REAL DEFAULT 0.0,
		built_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	);
	"""
	db.query(sql_housing_plots)
	var has_district_col = db.query("SELECT district_id FROM housing_plots LIMIT 1;")
	if not has_district_col:
		db.query("DROP TABLE IF EXISTS housing_plots;")
		db.query(sql_housing_plots)
	var has_deed_col = db.query("SELECT land_deed_number FROM housing_plots LIMIT 1;")
	if not has_deed_col:
		db.query("ALTER TABLE housing_plots ADD COLUMN land_deed_number TEXT DEFAULT '';")
		db.query("ALTER TABLE housing_plots ADD COLUMN construction_progress REAL DEFAULT 0.0;")
	
	# Bảng Dòng Thời Gian Thống Nhất (Persistent Unified Timeline)
	var sql_timeline = """
	CREATE TABLE IF NOT EXISTS world_timeline (
		id INTEGER PRIMARY KEY CHECK (id = 1),
		total_game_minutes INTEGER NOT NULL DEFAULT 0,
		current_day_index INTEGER NOT NULL DEFAULT 2,
		current_hour INTEGER NOT NULL DEFAULT 11,
		current_minute INTEGER NOT NULL DEFAULT 30,
		second_accumulator REAL NOT NULL DEFAULT 0.0,
		last_real_unix_timestamp INTEGER NOT NULL DEFAULT 0,
		last_updated_iso TEXT DEFAULT CURRENT_TIMESTAMP,
		total_sessions INTEGER NOT NULL DEFAULT 1,
		total_offline_catchup_seconds REAL NOT NULL DEFAULT 0.0
	);
	"""
	db.query(sql_timeline)

	# Bảng Cây Công Nghệ R&D Viện Hàn Lâm HAS (20 Bậc x 5 Nhánh)
	var sql_tech = """
	CREATE TABLE IF NOT EXISTS research_tech_tree (
		branch_id TEXT NOT NULL,
		tier_level INTEGER NOT NULL,
		tech_name TEXT NOT NULL,
		kbu_cost INTEGER NOT NULL,
		benefit_desc TEXT NOT NULL,
		is_unlocked INTEGER DEFAULT 0,
		is_deployed INTEGER DEFAULT 0,
		unlocked_at TIMESTAMP,
		PRIMARY KEY (branch_id, tier_level)
	);
	"""
	db.query(sql_tech)

	# Bảng Trạng Thái R&D & Điểm Tri Thức (KBU State)
	var sql_rstate = """
	CREATE TABLE IF NOT EXISTS research_state (
		id INTEGER PRIMARY KEY CHECK (id = 1),
		kbu_balance INTEGER DEFAULT 120,
		active_branch_id TEXT DEFAULT 'materials',
		active_tier INTEGER DEFAULT 1,
		current_progress_kbu INTEGER DEFAULT 0,
		acceleration_grant_active INTEGER DEFAULT 0,
		acceleration_grant_expiry_unix INTEGER DEFAULT 0,
		last_kbu_update_unix INTEGER DEFAULT 0
	);
	"""
	db.query(sql_rstate)
	db.query("INSERT OR IGNORE INTO research_state (id, kbu_balance, active_branch_id, active_tier, current_progress_kbu) VALUES (1, 120, 'materials', 1, 0);")

	# Tạo các B-Tree Indexes để tối ưu tra cứu siêu tốc khi quy mô lên 144.000 người
	db.query("CREATE INDEX IF NOT EXISTS idx_citizens_district ON citizens(home_district_id);")
	db.query("CREATE INDEX IF NOT EXISTS idx_citizens_role ON citizens(job_role);")
	db.query("CREATE INDEX IF NOT EXISTS idx_citizens_workplace ON citizens(workplace_id);")
	db.query("CREATE INDEX IF NOT EXISTS idx_certs_cert_id ON citizen_certificates(cert_id);")
	db.query("CREATE INDEX IF NOT EXISTS idx_ledger_fund ON treasury_ledger(fund_type);")
	db.query("CREATE INDEX IF NOT EXISTS idx_housing_status ON housing_plots(status);")
	db.query("CREATE INDEX IF NOT EXISTS idx_tech_branch ON research_tech_tree(branch_id);")
	db.query("CREATE INDEX IF NOT EXISTS idx_tech_unlocked ON research_tech_tree(is_unlocked);")
	
	print("[DatabaseManager] ✅ Đã thiết lập hoàn chỉnh Schema DDL & B-Tree Indexes cho Tân Thế Giới (kèm Housing Plots, World Timeline & R&D Tech Tree).")

## Đồng bộ hàng loạt toàn bộ cư dân từ RAM vào SQLite bằng Transaction an toàn
func sync_citizens_batch(citizens_dict: Dictionary) -> bool:
	if not is_db_open:
		return false
		
	db.query("BEGIN TRANSACTION;")
	for c_id in citizens_dict.keys():
		var c = citizens_dict[c_id]
		var query_upsert = """
		INSERT INTO citizens (
			citizen_id, citizen_name, age, life_stage, is_married, household_id, spouse_id, needs_community_support,
			fellowship_group, home_district_id,
			home_coord_x, home_coord_z, workplace_id, job_role, salary,
			wallet, is_church_servant, servant_type, preferred_transit_mode,
			commute_duration_minutes, energy, happiness, durability_clothing,
			durability_tools, durability_vehicle
		) VALUES (
			'%s', '%s', %d, '%s', %d, '%s', '%s', %d,
			'%s', '%s',
			%.2f, %.2f, '%s', '%s', %.2f,
			%.2f, %d, '%s', %d,
			%.2f, %.2f, %.2f, %.2f,
			%.2f, %.2f
		)
		ON CONFLICT(citizen_id) DO UPDATE SET
			life_stage=excluded.life_stage,
			is_married=excluded.is_married,
			household_id=excluded.household_id,
			spouse_id=excluded.spouse_id,
			needs_community_support=excluded.needs_community_support,
			salary=excluded.salary,
			wallet=excluded.wallet,
			workplace_id=excluded.workplace_id,
			job_role=excluded.job_role,
			energy=excluded.energy,
			happiness=excluded.happiness,
			durability_clothing=excluded.durability_clothing,
			durability_tools=excluded.durability_tools,
			durability_vehicle=excluded.durability_vehicle,
			updated_at=CURRENT_TIMESTAMP;
		""" % [
			c.citizen_id, c.citizen_name.replace("'", "''"), c.age, c.life_stage, 1 if c.is_married else 0,
			c.household_id, c.spouse_id, 1 if c.needs_community_support else 0, c.fellowship_group, c.home_district_id,
			c.home_coord_km.x, c.home_coord_km.y, c.workplace_id, c.job_role.replace("'", "''"), c.salary,
			c.wallet, 1 if c.is_church_servant else 0, c.servant_type, c.preferred_transit_mode,
			c.commute_duration_minutes, c.energy, c.happiness, c.durability_clothing,
			c.durability_tools, c.durability_vehicle
		]
		db.query(query_upsert)
		
		# Đồng bộ chứng chỉ
		for cert in c.certificates:
			db.query("INSERT OR IGNORE INTO citizen_certificates (citizen_id, cert_id) VALUES ('%s', '%s');" % [c.citizen_id, cert])

	for c_id in citizens_dict.keys():
		var c = citizens_dict[c_id]
		for related_id in c.social_connections:
			var relationship_type := "SPOUSE" if related_id == c.spouse_id else "HOUSEHOLD"
			db.query(
				"INSERT OR IGNORE INTO citizen_relationships (citizen_id, related_citizen_id, relationship_type) VALUES ('%s', '%s', '%s');"
				% [c.citizen_id, related_id, relationship_type]
			)
			
	db.query("COMMIT;")
	database_synced.emit(citizens_dict.size())
	print("[DatabaseManager] 💾 Đồng bộ thành công %d cư dân vào SQLite!" % citizens_dict.size())
	return true

## Ghi nhận một giao dịch tài chính vào Sổ Cái SQLite
func log_transaction(day_idx: int, hour: int, minute: int, category: String, amount: float, fund_type: String, desc: String) -> void:
	if not is_db_open:
		return
	var sql = """
	INSERT INTO treasury_ledger (day_index, hour, minute, category, amount, fund_type, description)
	VALUES (%d, %d, %d, '%s', %.2f, '%s', '%s');
	""" % [day_idx, hour, minute, category, amount, fund_type, desc.replace("'", "''")]
	db.query(sql)
	transaction_logged.emit(category, amount, fund_type)

## Truy vấn danh sách ứng viên có chứng chỉ chuyên môn phù hợp cho HR Board
func query_candidates_with_cert(required_cert: String) -> Array[Dictionary]:
	if not is_db_open:
		return []
		
	var sql: String = ""
	if required_cert.is_empty():
		sql = "SELECT * FROM citizens WHERE job_role = 'Chưa có việc' LIMIT 20;"
	else:
		sql = """
		SELECT c.* FROM citizens c
		JOIN citizen_certificates cc ON c.citizen_id = cc.citizen_id
		WHERE cc.cert_id = '%s' AND c.job_role = 'Chưa có việc'
		LIMIT 20;
		""" % required_cert
		
	db.query(sql)
	var arr: Array[Dictionary] = []
	for r in db.query_result:
		arr.append(r)
	return arr

## Báo cáo thống kê dân số theo từng Huyện
func query_district_census() -> Array[Dictionary]:
	if not is_db_open:
		return []
	var sql = """
	SELECT home_district_id, COUNT(*) AS population, AVG(wallet) AS avg_wallet
	FROM citizens
	GROUP BY home_district_id;
	"""
	db.query(sql)
	var arr: Array[Dictionary] = []
	for r in db.query_result:
		arr.append(r)
	return arr

## Lưu trữ / Cập nhật Lô Đất Nhà Ở & Nhà Mẫu
func save_housing_plot(plot: Dictionary) -> bool:
	if not is_db_open:
		return false
	var deed = plot.get("land_deed_number", "")
	if deed.is_empty():
		deed = "SO_DO_TTG_" + plot.get("plot_id", "PL01").to_upper().replace("PLOT_", "") + "_2026"
	var progress = float(plot.get("construction_progress", 0.0))
	var stat = plot.get("status", "AVAILABLE")
	if stat == "COMPLETED" or stat == "OCCUPIED":
		progress = 100.0
	elif stat == "UNDER_CONSTRUCTION" and progress <= 0.0:
		progress = 50.0

	var sql = """
	INSERT INTO housing_plots (
		plot_id, district_id, house_type, title, status, owner_id,
		price, area_sqm, pos_x, pos_y, pos_z, land_deed_number, construction_progress
	) VALUES (
		'%s', '%s', '%s', '%s', '%s', '%s',
		%.2f, %.2f, %.2f, %.2f, %.2f, '%s', %.1f
	)
	ON CONFLICT(plot_id) DO UPDATE SET
		status=excluded.status,
		owner_id=excluded.owner_id,
		price=excluded.price,
		land_deed_number=excluded.land_deed_number,
		construction_progress=excluded.construction_progress;
	""" % [
		str(plot.get("plot_id", "")).replace("'", "''"),
		str(plot.get("district_id", "DISTRICT_PLATEAU_CORE")).replace("'", "''"),
		str(plot.get("house_type", "STUDIO_APARTMENT")).replace("'", "''"),
		str(plot.get("title", "")).replace("'", "''"),
		stat.replace("'", "''"),
		str(plot.get("owner_id", "")).replace("'", "''"),
		plot.get("price", 1500.0),
		plot.get("area_sqm", 80.0),
		plot.get("pos_x", 0.0),
		plot.get("pos_y", 600.0),
		plot.get("pos_z", 0.0),
		str(deed).replace("'", "''"),
		progress
	]
	return db.query(sql)

## Cập nhật trạng thái lô đất (AVAILABLE -> UNDER_CONSTRUCTION -> COMPLETED)
func update_plot_status(plot_id: String, new_status: String, owner_id: String = "", deed_no: String = "") -> bool:
	if not is_db_open:
		return false
	var progress = 0.0
	if new_status == "UNDER_CONSTRUCTION":
		progress = 50.0
	elif new_status == "COMPLETED" or new_status == "OCCUPIED":
		progress = 100.0

	var sql = ""
	var safe_status = new_status.replace("'", "''")
	var safe_owner = owner_id.replace("'", "''")
	var safe_deed = deed_no.replace("'", "''")
	var safe_plot_id = plot_id.replace("'", "''")
	if deed_no.is_empty():
		sql = "UPDATE housing_plots SET status = '%s', owner_id = '%s', construction_progress = %.1f WHERE plot_id = '%s';" % [safe_status, safe_owner, progress, safe_plot_id]
	else:
		sql = "UPDATE housing_plots SET status = '%s', owner_id = '%s', land_deed_number = '%s', construction_progress = %.1f WHERE plot_id = '%s';" % [safe_status, safe_owner, safe_deed, progress, safe_plot_id]
	return db.query(sql)

## Truy vấn tất cả các lô đất nhà ở
func get_all_housing_plots() -> Array[Dictionary]:
	if not is_db_open:
		return []
	db.query("SELECT * FROM housing_plots ORDER BY plot_id ASC;")
	var arr: Array[Dictionary] = []
	for r in db.query_result:
		arr.append(r)
	return arr

func get_housing_plot(plot_id: String) -> Dictionary:
	if not is_db_open:
		return {}
	var escaped_plot_id := plot_id.replace("'", "''")
	if not db.query("SELECT * FROM housing_plots WHERE plot_id = '%s' LIMIT 1;" % escaped_plot_id):
		push_error("[DatabaseManager] Không thể đọc trạng thái lô đất %s." % plot_id)
		return {}
	if db.query_result.is_empty():
		return {}
	return db.query_result[0]

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		close_database()

func close_database() -> void:
	if is_db_open and db:
		db.close_db()
		is_db_open = false
		db = null
		print("[DatabaseManager] Đã đóng kết nối SQLite an toàn.")
