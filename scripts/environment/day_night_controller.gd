@tool
class_name DayNightController
extends Node3D

# ==============================================================================
# DAY NIGHT CONTROLLER (CHU KỲ NGÀY - ĐÊM & ÁNH SÁNG TOON) - TÂN THẾ GIỚI
# Quản lý góc chiếu mặt trời, trăng và bảng màu bầu trời Anime:
# - Bình minh vàng mật (Dawn): 05:00 - 07:30 (Ánh sáng ấm, quầng chân trời đào)
# - Ban ngày nắng rực Toon (Noon): 07:30 - 16:30 (Trời xanh ngắt, bóng đổ sắc nét)
# - Hoàng hôn tím hồng (Sunset): 16:30 - 19:15 (Makoto Shinkai tím hồng & cam rực)
# - Ban đêm sao lung linh (Night): 19:15 - 05:00 (Trăng bạc, ngàn sao nhấp nháy)
# Hỗ trợ phím tắt trải nghiệm: F1 (Sáng), F2 (Trưa), F3 (Chiều), F4 (Tối), F5/T (Tua sáng)
# ==============================================================================

@export var world_environment: WorldEnvironment
@export var directional_light: DirectionalLight3D
@export var auto_sync_world_manager: bool = true
@export var is_time_paused: bool = false
@export var time_speed_multiplier: float = 1.0

# Ghi đè thời gian thủ công (-1 là dùng thời gian thực của WorldManager)
@export_range(-1.0, 24.0) var manual_hour: float = -1.0

var sky_material: ShaderMaterial
var current_time_hours: float = 11.5 # 11:30 mặc định

func _ready() -> void:
	_resolve_node_references()
	_apply_time_of_day(get_current_time_hours())
	print("[DayNightController] ☀️ Khởi tạo Hệ Thống Chu Kỳ Ngày - Đêm Anime Toon thành công!")

func _resolve_node_references() -> void:
	if directional_light == null:
		directional_light = get_node_or_null("../DirectionalLight3D")
		if directional_light == null:
			directional_light = get_tree().root.find_child("DirectionalLight3D", true, false)
			
	if world_environment == null:
		world_environment = get_node_or_null("../WorldEnvironment")
		if world_environment == null:
			world_environment = get_tree().root.find_child("WorldEnvironment", true, false)

	if world_environment != null and world_environment.environment != null:
		if world_environment.environment.sky != null:
			sky_material = world_environment.environment.sky.sky_material as ShaderMaterial

func _process(delta: float) -> void:
	if not is_time_paused:
		if auto_sync_world_manager and Engine.has_singleton("WorldManager"):
			var wm = Engine.get_singleton("WorldManager")
			if wm != null and wm.has_method("get_time_of_day_hours"):
				current_time_hours = wm.get_time_of_day_hours()
		elif manual_hour >= 0.0:
			current_time_hours = manual_hour
		else:
			# Tự động tiến thời gian nội bộ nếu không có WorldManager
			current_time_hours += (delta / (WorldManager.REAL_SECONDS_PER_GAME_MINUTE * 60.0)) * time_speed_multiplier
			if current_time_hours >= 24.0:
				current_time_hours -= 24.0

	_apply_time_of_day(current_time_hours)

func get_current_time_hours() -> float:
	if manual_hour >= 0.0:
		return manual_hour
	if auto_sync_world_manager and Engine.has_singleton("WorldManager"):
		var wm = Engine.get_singleton("WorldManager")
		if wm != null and wm.has_method("get_time_of_day_hours"):
			return wm.get_time_of_day_hours()
	return current_time_hours

func set_hour(hour_val: float) -> void:
	current_time_hours = fmod(hour_val, 24.0)
	if current_time_hours < 0.0:
		current_time_hours += 24.0
	manual_hour = current_time_hours
	
	if Engine.has_singleton("WorldManager"):
		var wm = Engine.get_singleton("WorldManager")
		var h = int(current_time_hours)
		var m = int((current_time_hours - float(h)) * 60.0)
		wm.set_time_of_day(h, m)
		
	_apply_time_of_day(current_time_hours)

func skip_to_morning() -> void:
	print("[DayNightController] 🌅 Kích hoạt tua nhanh qua đêm tới 06:00 sáng!")
	set_hour(6.0)

# ------------------------------------------------------------------------------
# TÍNH TOÁN & ÁP ĐẶT ÁNH SÁNG THEO THỜI GIAN TRONG NGÀY
# ------------------------------------------------------------------------------
func _apply_time_of_day(hours: float) -> void:
	var atmosphere = evaluate_atmosphere(hours)
	
	# 1. Cập nhật góc quay của Mặt Trời / Mặt Trăng
	_update_sun_rotation(hours, atmosphere)
	
	# 2. Cập nhật DirectionalLight3D
	if directional_light != null:
		directional_light.light_color = atmosphere["light_color"]
		directional_light.light_energy = atmosphere["light_energy"]
		
	# 3. Cập nhật Shader Bầu Trời Anime
	if sky_material != null:
		sky_material.set_shader_parameter("top_color", atmosphere["top_color"])
		sky_material.set_shader_parameter("horizon_color", atmosphere["horizon_color"])
		sky_material.set_shader_parameter("bottom_color", atmosphere["bottom_color"])
		sky_material.set_shader_parameter("sun_color", atmosphere["sun_color"])
		sky_material.set_shader_parameter("horizon_glow_color", atmosphere["horizon_glow_color"])
		sky_material.set_shader_parameter("horizon_glow_intensity", atmosphere["horizon_glow_intensity"])
		sky_material.set_shader_parameter("stars_intensity", atmosphere["stars_intensity"])
		
	# 4. Cập nhật Environment (Sương mù & Ánh sáng môi trường)
	if world_environment != null and world_environment.environment != null:
		var env = world_environment.environment
		env.fog_light_color = atmosphere["fog_color"]
		env.fog_density = atmosphere["fog_density"]
		env.ambient_light_sky_contribution = atmosphere["ambient_sky_contrib"]

func _update_sun_rotation(hours: float, atmosphere: Dictionary) -> void:
	if directional_light == null:
		return
		
	# Góc ngày 0 -> 2PI (0 = 06:00 sáng, PI/2 = 12:00 trưa, PI = 18:00 chiều, 3PI/2 = 24:00 đêm)
	var sun_phase = (hours - 6.0) / 24.0 * TAU
	
	# Quỹ đạo nghiêng tự nhiên của mặt trời
	# X: Đông (+) sang Tây (-)
	# Y: Cao độ (Elevation)
	# Z: Độ lệch Nam/Bắc tạo bóng đổ Toon ấn tượng
	var sun_dir: Vector3
	var is_daytime = (hours >= 5.5 and hours <= 18.5)
	
	if is_daytime:
		var elevation = sin((hours - 6.0) / 12.0 * PI)
		var azimuth = -cos((hours - 6.0) / 12.0 * PI)
		sun_dir = Vector3(azimuth, -elevation, 0.40).normalized()
	else:
		# Ban đêm: Ánh trăng dịu êm từ hướng ngược lại
		var night_prog = fmod(hours + 6.0, 24.0) / 12.0 * PI
		var moon_elev = sin(night_prog)
		var moon_azim = -cos(night_prog)
		sun_dir = Vector3(moon_azim, -maxf(moon_elev, 0.25), -0.35).normalized()
		
	directional_light.look_at_from_position(Vector3(0, 5000, 0), Vector3(0, 5000, 0) + sun_dir, Vector3.UP)

# ------------------------------------------------------------------------------
# HÀM NỘI SUY BẦU TRỜI ANIME & ÁNH SÁNG THEO GIỜ (INTERPOLATION LOGIC)
# ------------------------------------------------------------------------------
static func evaluate_atmosphere(hours: float) -> Dictionary:
	# Chuẩn hóa giờ về [0, 24)
	var t = fmod(hours, 24.0)
	if t < 0.0:
		t += 24.0
		
	# Định nghĩa các mốc thời khắc đặc trưng:
	# - 02:00: Ban Đêm Sâu (Deep Night - Ngàn sao lung linh)
	# - 05:00: Chớm Rạng (Pre-Dawn - Bầu trời chuyển chàm)
	# - 06:15: Bình Minh Vàng Mật (Golden Dawn - Rực rỡ ánh mật, quầng sáng đào)
	# - 08:00: Sáng Sớm Thanh Khiết (Early Morning)
	# - 12:00: Giữa Trưa Nắng Toon (High Noon - Xanh ngắt Ghibli)
	# - 16:30: Xế Chiều Vàng Ấm (Late Afternoon)
	# - 17:45: Hoàng Hôn Tím Hồng (Sunset Shinkai - Magenta hồng & cam cháy)
	# - 19:15: Chập Tối (Dusk / Twilight)
	# - 22:00: Ban Đêm Thân Thiện (Night - Trăng thanh sao biếc)
	
	if t >= 5.0 and t < 6.25:
		# 05:00 -> 06:15: Chuyển từ Đêm sang Bình Minh Vàng Mật
		var factor = (t - 5.0) / 1.25
		return _lerp_atmosphere(_get_night_preset(), _get_dawn_preset(), factor)
	elif t >= 6.25 and t < 8.0:
		# 06:15 -> 08:00: Chuyển từ Bình Minh Vàng Mật sang Ban Ngày
		var factor = (t - 6.25) / 1.75
		return _lerp_atmosphere(_get_dawn_preset(), _get_day_preset(), factor)
	elif t >= 8.0 and t < 16.5:
		# 08:00 -> 16:30: Ban Ngày Toon Rực Rỡ
		return _get_day_preset()
	elif t >= 16.5 and t < 17.75:
		# 16:30 -> 17:45: Chuyển từ Ban Ngày sang Hoàng Hôn Tím Hồng
		var factor = (t - 16.5) / 1.25
		return _lerp_atmosphere(_get_day_preset(), _get_dusk_preset(), factor)
	elif t >= 17.75 and t < 19.25:
		# 17:45 -> 19:15: Chuyển từ Hoàng Hôn Tím Hồng sang Đêm
		var factor = (t - 17.75) / 1.5
		return _lerp_atmosphere(_get_dusk_preset(), _get_night_preset(), factor)
	else:
		# 19:15 -> 05:00: Ban Đêm Sao Lung Linh
		return _get_night_preset()

static func _get_dawn_preset() -> Dictionary:
	return {
		"light_color": Color(1.0, 0.85, 0.62),              # Ánh nắng vàng mật
		"light_energy": 1.10,
		"top_color": Color(0.26, 0.52, 0.82),               # Lam pastel sớm mai
		"horizon_color": Color(1.0, 0.70, 0.46),           # Chân trời ửng hồng cam đào
		"bottom_color": Color(0.68, 0.58, 0.52),
		"sun_color": Color(1.0, 0.88, 0.65),
		"horizon_glow_color": Color(1.0, 0.72, 0.40),      # Quầng sáng rực vàng mật
		"horizon_glow_intensity": 1.35,
		"stars_intensity": 0.05,
		"fog_color": Color(0.95, 0.82, 0.70),               # Sương mai ấm áp
		"fog_density": 0.00035,
		"ambient_sky_contrib": 0.60
	}

static func _get_day_preset() -> Dictionary:
	return {
		"light_color": Color(1.0, 0.97, 0.90),              # Ánh nắng Toon trong trẻo
		"light_energy": 1.35,
		"top_color": Color(0.20, 0.48, 0.88),               # Bầu trời xanh biếc Ghibli
		"horizon_color": Color(0.84, 0.92, 0.98),           # Trắng xanh dịu êm
		"bottom_color": Color(0.70, 0.82, 0.88),
		"sun_color": Color(1.0, 0.96, 0.82),
		"horizon_glow_color": Color(0.85, 0.92, 0.98),
		"horizon_glow_intensity": 0.0,
		"stars_intensity": 0.0,
		"fog_color": Color(0.78, 0.88, 0.96),               # Sương mù thanh khiết
		"fog_density": 0.00025,
		"ambient_sky_contrib": 0.65
	}

static func _get_dusk_preset() -> Dictionary:
	return {
		"light_color": Color(1.0, 0.55, 0.38),              # Ánh chiều tà hổ phách rực rỡ
		"light_energy": 1.15,
		"top_color": Color(0.32, 0.20, 0.55),               # Tím lam hoàng hôn sâu thẳm
		"horizon_color": Color(0.94, 0.40, 0.54),           # Sắc tím hồng Makoto Shinkai
		"bottom_color": Color(0.45, 0.24, 0.42),
		"sun_color": Color(1.0, 0.65, 0.45),
		"horizon_glow_color": Color(1.0, 0.45, 0.50),      # Quầng sáng rực tím hồng
		"horizon_glow_intensity": 1.60,
		"stars_intensity": 0.25,
		"fog_color": Color(0.70, 0.46, 0.62),               # Sương chiều tím mộng mơ
		"fog_density": 0.00035,
		"ambient_sky_contrib": 0.55
	}

static func _get_night_preset() -> Dictionary:
	return {
		"light_color": Color(0.55, 0.68, 0.92),              # Ánh trăng bạc dịu mát
		"light_energy": 0.38,                               # Đủ sáng rõ địa hình, không tối đen
		"top_color": Color(0.06, 0.10, 0.22),               # Lam chàm thẫm huyền bí
		"horizon_color": Color(0.12, 0.20, 0.36),           # Chân trời xanh sapphire
		"bottom_color": Color(0.04, 0.06, 0.14),
		"sun_color": Color(0.75, 0.85, 1.0),
		"horizon_glow_color": Color(0.10, 0.15, 0.28),
		"horizon_glow_intensity": 0.0,
		"stars_intensity": 1.0,                             # Ngàn sao anime lấp lánh rực rỡ
		"fog_color": Color(0.12, 0.18, 0.30),               # Màn đêm tĩnh lặng an lành
		"fog_density": 0.00030,
		"ambient_sky_contrib": 0.45
	}

static func _lerp_atmosphere(a: Dictionary, b: Dictionary, f: float) -> Dictionary:
	f = clampf(f, 0.0, 1.0)
	# Dùng smoothstep để chuyển giao mượt mà không bị gãy khấc
	var s = f * f * (3.0 - 2.0 * f)
	return {
		"light_color": a["light_color"].lerp(b["light_color"], s),
		"light_energy": lerpf(a["light_energy"], b["light_energy"], s),
		"top_color": a["top_color"].lerp(b["top_color"], s),
		"horizon_color": a["horizon_color"].lerp(b["horizon_color"], s),
		"bottom_color": a["bottom_color"].lerp(b["bottom_color"], s),
		"sun_color": a["sun_color"].lerp(b["sun_color"], s),
		"horizon_glow_color": a["horizon_glow_color"].lerp(b["horizon_glow_color"], s),
		"horizon_glow_intensity": lerpf(a["horizon_glow_intensity"], b["horizon_glow_intensity"], s),
		"stars_intensity": lerpf(a["stars_intensity"], b["stars_intensity"], s),
		"fog_color": a["fog_color"].lerp(b["fog_color"], s),
		"fog_density": lerpf(a["fog_density"], b["fog_density"], s),
		"ambient_sky_contrib": lerpf(a["ambient_sky_contrib"], b["ambient_sky_contrib"], s)
	}

# ------------------------------------------------------------------------------
# PHÍM TẮT TRẢI NGHIỆM TƯƠNG TÁC (DEBUG & DEMO HOTKEYS)
# ------------------------------------------------------------------------------
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
		
	var key_event = event as InputEventKey
	var code = key_event.physical_keycode if key_event.physical_keycode != 0 else key_event.keycode
	match code:
		KEY_F1:
			print("[DayNightController] ⌨️ [F1] Chuyển ngay sang BÌNH MINH VÀNG MẬT (06:15)!")
			set_hour(6.25)
		KEY_F2:
			print("[DayNightController] ⌨️ [F2] Chuyển ngay sang GIỮA TRƯA NẮNG TOON (12:00)!")
			set_hour(12.0)
		KEY_F3:
			print("[DayNightController] ⌨️ [F3] Chuyển ngay sang HOÀNG HÔN TÍM HỒNG (17:45)!")
			set_hour(17.75)
		KEY_F4:
			print("[DayNightController] ⌨️ [F4] Chuyển ngay sang BAN ĐÊM SAO LUNG LINH (22:30)!")
			set_hour(22.5)
		KEY_F5, KEY_T:
			print("[DayNightController] ⌨️ [F5/T] TUA NHANH QUA ĐÊM -> Đón bình minh 06:00!")
			skip_to_morning()
		KEY_F6:
			is_time_paused = not is_time_paused
			print("[DayNightController] ⌨️ [F6] Dừng/Tiếp tục thời gian: %s" % ("ĐÃ DỪNG" if is_time_paused else "ĐANG CHẠY"))
