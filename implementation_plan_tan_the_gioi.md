# KẾ HOẠCH TRIỂN KHAI & BÁO CÁO AUDIT CODE TOÀN DIỆN (IMPLEMENTATION PLAN)

## Dự Án: Tân Thế Giới (Godot 4.6.2 Forward+ • Intel Iris Xe Optimization)

* **Repository GitHub**: [thequangnguyen258-ctrl/newworld](https://github.com/thequangnguyen258-ctrl/newworld)

* **Thư mục Google Drive gốc**: [game tân thế giới](https://drive.google.com/drive/folders/1QC-nBJdZOyBeBlu2rKICf1mvALTSKYPw) (nằm trong [projiect](https://drive.google.com/drive/folders/1yz2HkFkuIMyAl6LTybOGQAoaLkULBGHh) / [game](https://drive.google.com/drive/folders/1nxWb6eDckHQ-Xvz7I904SCIQd0sG1eJ8))

* **Tài liệu chuẩn đối chiếu**: [AGENTS.md](https://drive.google.com/file/d/1XblOrtEDRGO52EEhutlxynz0zB_7iF0F/view), [tan_the_gioi_game_rules.md](https://drive.google.com/file/d/1AgsuyL6StqJe5LHZPSdSslkc8hbQ7eKu/view), [GAME_DESIGN_CONCEPT.md](https://drive.google.com/file/d/1pjjHNhf_q3yfRWdIfyqj_hhhlw5id0n2/view), [ai_context_system_instructions.md](https://drive.google.com/file/d/1rBIujNi2iiur5QEVW0PQbFK8k5HSQQdM/view)

## 1. BẢNG ĐÁNH GIÁ TỔNG QUAN (ENTERPRISE ARCHITECTURE SCORECARD)

| Hạng mục Đánh giá | Điểm số | Nhận định Kỹ thuật Cốt lõi | 
| ----- | ----- | ----- | 
| **1. Kiến trúc Hệ thống & Đồng bộ Thời gian (Core & Timeline)** | **5.5 / 10** | Có kiến trúc tách biệt `WorldManager` – `UnifiedTimelineServer` – `SaveManager` tốt, nhưng bị gãy kết nối tại `day_night_controller.gd` (dùng sai `Engine.has_singleton`) và thiếu cache `timeline_server_ref` khiến Offline Catch-up và Tua Đêm (`skip_night_to_morning`) mất tác dụng trên bầu trời 3D. | 
| **2. Quản lý Dữ liệu, Kinh tế & Lưu trữ (SQLite / JSON Save)** | **6.0 / 10** | Có Dual-Layer Persistence (SQLite WAL + JSON), nhưng thiếu kiểm tra số dư khi chi Học bổng / Đồng tài trợ ở `macro_map_modal.gd`, làm âm quỹ `treasury_city` / `fund_tithe_church` và khiến `validate_saved_state()` khóa vĩnh viễn tính năng Save Game. | 
| **3. Vật lý, Điều khiển & Tương tác 3D (Physics & Interaction)** | **5.0 / 10** | Lỗi cực nghiêm trọng ở `mega_office_skyscraper_builder.gd`: gán `scale = Vector3(8.944, 1.0, 8.944)` lên root tòa nhà rồi chia ngược scale cho các trạm `InteractiveStation` con, làm bán kính `Area3D` bị co nhỏ gần 9 lần (`0.4m`)! Ngoài ra `world_chunk_streamer.gd` bị kẹt khiến 52/81 chunk địa hình trung tâm không bao giờ spawn khi mới vào game. | 
| **4. Độ chính xác Thiết kế & Đồng bộ Dữ liệu (GDD Compliance)** | **6.5 / 10** | Lệch mã định danh 2 Huyện (`DISTRICT_WEST_VALLEY` vs `DISTRICT_WEST_INDUSTRY`, `DISTRICT_SOUTH_PORT` vs `DISTRICT_SOUTH_COAST`), lệch tọa độ Huyện Nam (`Z=10,000m` vs `Z=20,000m`), thiếu Ban thứ 9 (`Ban Ca Ngợi`) trên HUD/Enterprise, và vi phạm Rule #4 về lương tình nguyện viên NHVC Bán thời gian. | 
| **5. Hiệu năng Đồ họa & CPU (Intel Iris Xe Optimization)** | **4.5 / 10** | Spawn toàn bộ 300 `NPCCharacter` (`CharacterBody3D` + `Area3D` + `Label3D`) chạy `_process` mỗi khung hình (18.000 lệnh/giây, 600 lần `get_node_or_null` chuỗi/frame), cộng với cấp phát mới `StyleBoxFlat.new()` 8 lần/frame trong `hud_overlay.gd` và hàng nghìn `StandardMaterial3D` trùng lặp gây nghẽn cổ chai trên GPU tích hợp Intel Iris Xe. | 

## 2. LỘ TRÌNH TRIỂN KHAI 4 GIAI ĐOẠN (PHASED IMPLEMENTATION PLAN)

| Giai đoạn | Mục tiêu Trọng tâm | Các File Cần Sửa | Thời lượng Ước tính | Độ ưu tiên | 
| ----- | ----- | ----- | ----- | ----- | 
| **Phase 1: Cấp cứu Engine, Save Game, Timeline & Địa hình (P0 Blocker)** | Khôi phục bầu trời Ngày/Đêm đồng bộ `WorldManager`, sửa lỗi mất 52/81 chunk địa hình trung tâm, sửa lỗi hỏng Save Game do âm ngân sách, sửa lỗi mất KBU Offline R&D và lỗi co nhỏ `Area3D` 8.94 lần trong Mega Office. | `day_night_controller.gd`, `main_world.tscn`, `world_chunk_streamer.gd`, `world_manager.gd`, `save_manager.gd`, `macro_map_modal.gd`, `research_manager.gd`, `mega_office_skyscraper_builder.gd` | **3 – 4 giờ** | **P0 (Khẩn cấp)** | 
| **Phase 2: Sửa lỗi Điều khiển, Phương tiện & Trạm tương tác (P1 Gameplay)** | Chuẩn hóa bộ gõ Tiếng Việt IME (`project.godot`), sửa xung đột phím mũi tên / phím số thang máy, sửa lỗi khoảng cách `3.8m` vs `6.0m` của NPC, sửa lỗi khoảng cách 3D của thang máy, sửa `collision_layer` khi rời Trực thăng/Buggy, và sửa hiệu ứng hồi máu/thể lực tại các trạm `[E]`. | `project.godot`, `player_controller.gd`, `helicopter_controller.gd`, `mayor_buggy.gd`, `interactive_station.gd`, `central_capital_builder.gd` | **2.5 – 3 giờ** | **P1 (Cao)** | 
| **Phase 3: Đồng bộ Dữ liệu 5 Huyện, GDD Rules & Giao diện HUD/Radar (P1 Data & UI)** | Thống nhất mã Huyện & tọa độ Huyện Nam (`Z = +20,000m`), sửa lỗi chấm Radar văng khỏi màn hình 1.380px, tách vị trí `MiniMapRadar` khỏi `QuestTrackerPanel`, thêm Ban thứ 9 (`Ban Ca Ngợi`), sửa lỗi `fellowship_registry["TRANG_NIEN"]` bị rỗng và chuẩn hóa lương NHVC theo Rule #4. | `citizen_data.gd`, `citizen_manager.gd`, `natural_landscape_assembler.gd`, `logistics_manager.gd`, `mini_map_radar.gd`, `hud_overlay.gd`, `enterprise_data.gd`, `world_item_drop.gd` | **2.5 – 3 giờ** | **P1 (Cao)** | 
| **Phase 4: Tối ưu hóa Hiệu năng Intel Iris Xe & Kiểm thử E2E (P2 Performance)** | Loại bỏ cấp phát `StyleBoxFlat` mỗi frame trên HUD, gom nhóm Shared Material tĩnh, khoanh lỗ `DistantMacroTerrain` vùng trung tâm để chống Z-fighting, và chuyển 300 NPC sang kiến trúc Tiered Simulation (chỉ bật 3D Node trong bán kính `<= 250m`). | `hud_overlay.gd`, `npc_character.gd`, `natural_landscape_assembler.gd`, `world_chunk_streamer.gd`, `modular_nature_chunk.gd` | **4 – 5 giờ** | **P2 (Tối ưu)** | 

## 3. CHI TIẾT SỬA LỖI TỪNG FILE & TỪNG DÒNG (LINE-BY-LINE FIX SPECIFICATIONS)

### PHẦN A — PHASE 1: CẤP CỨU HỆ THỐNG CỐT LÕI (P0 CRITICAL BUGS)

#### 1. File `scripts/environment/day_night_controller.gd` ([Xem trên Drive](https://drive.google.com/file/d/1_V-k9ooUUpl1oERb5xlLN0W0ozRugHV5/view))

##### A. Nguyên nhân lỗi:

1. **Dòng 49–52, 66–69, 78–82**: Dùng `Engine.has_singleton("WorldManager")` và `Engine.get_singleton("WorldManager")`. Trong Godot 4, các GDScript Autoload khai báo trong `project.godot` là các Node nằm tại `/root/WorldManager` chứ **không phải** C++ Engine Singleton. Do đó `Engine.has_singleton("WorldManager")` luôn trả về `false`! Hậu quả:

   * Đồng hồ ánh sáng mặt trời 3D (`current_time_hours`) chạy tách rời hoàn toàn khỏi `WorldManager`. Khi người chơi ngủ qua đêm trên giường (`skip_night_to_morning()`) hoặc tải Offline Progress, đồng hồ HUD báo `06:00 Sáng` nhưng bầu trời 3D vẫn tối đen như mực.

2. **Dòng 53–54 & 76–88**: Trong `set_hour(h)` (gọi khi bấm `[F1]`–`[F5]`, `[T]`), dòng 77 gán `manual_hour = current_time_hours` (`>= 0.0`). Ở dòng 53: `elif manual_hour >= 0.0: current_time_hours = manual_hour` khiến thời gian bầu trời **bị đóng băng vĩnh viễn** sau khi bấm phím tắt mà không tự trôi tiếp!

3. **Dòng 299–301**: Phím `KEY_F6` được dùng để Tạm dừng/Tiếp tục thời gian (`is_time_paused`), đè trực tiếp lên phím `[F6] Lưu Game` của `SaveManager` (`save_manager.gd` dòng 32).

##### B. Vị trí & Cách sửa chi tiết:

* **Thêm mới** hàm helper `_get_world_manager() -> Node` ngay dưới hàm `_ready()` (khoảng dòng 44).

* **Sửa dòng 46–90** (`_process`, `set_hour`, `skip_to_morning`):

  * **Bớt/Xóa**: Toàn bộ các lệnh `if Engine.has_singleton("WorldManager"): var wm = Engine.get_singleton("WorldManager")` và việc khóa cứng `manual_hour = current_time_hours`.

  * **Thay bằng**: Truy xuất `WorldManager` qua `_get_world_manager()`, gọi `wm.set_time_of_day(h_int, m_int)` khi chỉnh giờ và gọi `wm.skip_night_to_morning(6)` khi tua sáng.

* **Sửa dòng 299–301** (`_unhandled_input`):

  * **Đổi phím** `KEY_F6` thành `KEY_F7` (để trả lại `KEY_F6` cho chức năng Lưu Game của `SaveManager`).

##### C. Code Before / After:

```
# ❌ BEFORE (Dòng 46 - 90 trong day_night_controller.gd):
func _process(delta: float) -> void:
	if not is_time_paused:
		# Ưu tiên đồng bộ với WorldManager nếu có, hoặc tự chạy mượt mà
		if Engine.has_singleton("WorldManager"):
			var wm = Engine.get_singleton("WorldManager")
			if "current_hour" in wm and "current_minute" in wm:
				current_time_hours = float(wm.current_hour) + float(wm.current_minute) / 60.0
		elif manual_hour >= 0.0:
			current_time_hours = manual_hour
		else:
			# Tự trôi mượt mà (1 giờ game = 60 giây thực)
			current_time_hours = fmod(current_time_hours + (delta / 60.0) * time_speed_multiplier, 24.0)

	_update_celestial_lighting(current_time_hours)

## Đặt giờ trực tiếp (dùng cho phím tắt hoặc nút bấm UI)
func set_hour(h: float) -> void:
	current_time_hours = fmod(h + 24.0, 24.0)
	manual_hour = current_time_hours
	if Engine.has_singleton("WorldManager"):
		var wm = Engine.get_singleton("WorldManager")
		if "current_hour" in wm:
			wm.current_hour = int(current_time_hours)
			wm.current_minute = int((current_time_hours - int(current_time_hours)) * 60.0)
	_update_celestial_lighting(current_time_hours)
	time_preset_changed.emit(get_time_period_name(), current_time_hours)

## Tua nhanh qua đêm đến 06:00 sáng (Bình minh)
func skip_to_morning() -> void:
	set_hour(6.0)
	print("[DayNightController] 🌅 Đã tua nhanh qua đêm tới 06:00 Bình Minh!")

```

```
# ✅ AFTER (Thay thế dòng 46 - 90 trong day_night_controller.gd):
func _get_world_manager() -> Node:
	if is_inside_tree():
		var wm = get_node_or_null("/root/WorldManager")
		if wm != null:
			return wm
	if Engine.has_singleton("WorldManager"):
		return Engine.get_singleton("WorldManager")
	return null

func _process(delta: float) -> void:
	var wm = _get_world_manager()
	if wm != null and "is_time_paused" in wm:
		wm.is_time_paused = is_time_paused

	if not is_time_paused:
		if wm != null and "current_hour" in wm and "current_minute" in wm:
			var sub_min: float = (wm. _time_accumulator / wm.SECONDS_PER_GAME_MINUTE) if ("_time_accumulator" in wm and "SECONDS_PER_GAME_MINUTE" in wm) else 0.0
			current_time_hours = fmod(float(wm.current_hour) + (float(wm.current_minute) + clampf(sub_min, 0.0, 0.99)) / 60.0, 24.0)
		else:
			current_time_hours = fmod(current_time_hours + (delta / 60.0) * time_speed_multiplier, 24.0)

	_update_celestial_lighting(current_time_hours)

## Đặt giờ trực tiếp (dùng cho phím tắt hoặc nút bấm UI) và đồng bộ ngược vào WorldManager
func set_hour(h: float) -> void:
	current_time_hours = fmod(h + 24.0, 24.0)
	manual_hour = -1.0 # Không khóa cứng thời gian sau khi chọn preset
	var wm = _get_world_manager()
	if wm != null:
		var h_int: int = int(floor(current_time_hours))
		var m_int: int = int(round((current_time_hours - float(h_int)) * 60.0)) % 60
		if wm.has_method("set_time_of_day"):
			wm.set_time_of_day(h_int, m_int)
		else:
			wm.current_hour = h_int
			wm.current_minute = m_int
	_update_celestial_lighting(current_time_hours)
	time_preset_changed.emit(get_time_period_name(), current_time_hours)

## Tua nhanh qua đêm đến 06:00 sáng (Bình minh)
func skip_to_morning() -> void:
	var wm = _get_world_manager()
	if wm != null and wm.has_method("skip_night_to_morning"):
		wm.skip_night_to_morning(6)
	set_hour(6.0)
	print("[DayNightController] 🌅 Đã tua nhanh qua đêm tới 06:00 Bình Minh!")

```

```
# ❌ BEFORE (Dòng 299 - 301 trong day_night_controller.gd):
		KEY_F6:
			is_time_paused = not is_time_paused
			_notify_hud_time_change("⏸️ Tạm dừng thời gian" if is_time_paused else "▶️ Tiếp tục thời gian")

# ✅ AFTER (Dòng 299 - 301 trong day_night_controller.gd - Đổi sang KEY_F7 để tránh đè lên F6 Save Game):
		KEY_F7:
			is_time_paused = not is_time_paused
			_notify_hud_time_change("⏸️ Tạm dừng thời gian [F7]" if is_time_paused else "▶️ Tiếp tục thời gian [F7]")

```

#### 2. File `scenes/world/main_world.tscn` ([Xem trên Drive](https://drive.google.com/file/d/1h0Yr0qTxXyx7E7uer40RbEXCjDhKSV5q/view)) & `scripts/environment/world_chunk_streamer.gd` ([Xem trên Drive](https://drive.google.com/file/d/1PznAf7ZhRlvlLjdjoHurJSz8EyfIPWDq/view))

##### A. Nguyên nhân lỗi:

1. **Thứ tự Node trong `main_world.tscn` (Dòng 47 & 65–69)**:

   * Dòng 47: Node gốc `MainWorld` đang bị xoay lệch góc `Transform3D(0.9999883, 0, -0.0048345434, 0, 1, 0, 0.0048345434, 0, 0.9999883, 0, 0, 0)` (lệch \~0.277 độ), làm ở cự ly 20km (Huyện Nam), toàn bộ địa hình lệch ngang gần `96.7m`!

   * Dòng 65–69: `NaturalLandscape` nằm **trên** `Player`. Khi `NaturalLandscape._ready()` chạy, nó khởi tạo `WorldChunkStreamer` (dòng 433 của `natural_landscape_assembler.gd`). Lúc này `Player._ready()` chưa chạy nên `get_tree().get_first_node_in_group("player")` tại dòng 26 của `world_chunk_streamer.gd` trả về `null`! Do đó lệnh `_update_streaming(true)` (dòng 29) bị hủy ngay ở dòng 52 (`if player_node == null: return`).

2. **Kẹt vòng lặp tải Chunk trong `world_chunk_streamer.gd` (Dòng 47–75)**:

   * Sang Frame 1 trong `_process()`, `cur_chunk (0,0) != last_player_chunk (999999, 999999)`. Dòng 48 lập tức gán `last_player_chunk = cur_chunk` rồi mới gọi `_update_streaming(false)`.

   * Trong `_update_streaming(false)`, dòng 72 giới hạn `if not force_immediate and spawn_count >= 4: break` (chỉ tạo tối đa 4 chunk mỗi frame).

   * Sang Frame 2 trở đi, vì `cur_chunk == last_player_chunk` nên `_update_streaming()` **không bao giờ được gọi lại nữa**! Kết quả là **52 trên 81 chunk địa hình trung tâm bị mất hoàn toàn** khi vào game, và mỗi lần đi qua ranh giới chunk (cần nạp 9 chunk mới), hệ thống chỉ nạp 4 chunk rồi bỏ trống 5 chunk vĩnh viễn!

##### B. Vị trí & Cách sửa chi tiết:

* **Trong `scenes/world/main_world.tscn`**:

  * **Sửa dòng 47**: Đặt lại `transform` của `MainWorld` về ma trận đơn vị `Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0)` (hoặc xóa dòng `transform = ...`).

  * **Đổi chỗ dòng 65–66 và 68–69**: Đưa `[node name="Player" ...]` lên **trước** `[node name="NaturalLandscape" ...]` để `Player` vào group `"player"` trước khi `NaturalLandscape` khởi tạo `WorldChunkStreamer`.

* **Trong `scripts/environment/world_chunk_streamer.gd`**:

  * **Thêm biến** `var _has_pending_chunks: bool = true` ở dòng 20.

  * **Sửa dòng 38–76**: Tiếp tục gọi `_update_streaming(false)` mỗi frame chừng nào `_has_pending_chunks == true`, giúp nạp đủ 100% (81/81) chunk một cách mượt mà (4 chunk/frame) mà không gây giật lag khung hình.

##### C. Code Before / After:

```
# ❌ BEFORE (Dòng 46 - 70 trong scenes/world/main_world.tscn):
[node name="MainWorld" type="Node3D"]
transform = Transform3D(0.9999883, 0, -0.0048345434, 0, 1, 0, 0.0048345434, 0, 0.9999883, 0, 0, 0)
script = ExtResource("2_main")

[node name="WorldEnvironment" type="WorldEnvironment" parent="."]
environment = SubResource("Environment_ghibli")

[node name="DirectionalLight3D" type="DirectionalLight3D" parent="."]
transform = Transform3D(0.866025, -0.353553, 0.353553, 0, 0.707107, 0.707107, -0.5, -0.612372, 0.612372, 0, 50, 0)
light_color = Color(1, 0.96, 0.88, 1)
light_energy = 1.35
shadow_enabled = true
directional_shadow_max_distance = 250.0

[node name="DayNightController" type="Node" parent="." node_paths=PackedStringArray("sun_light", "world_env")]
script = ExtResource("5_daynight")
sun_light = NodePath("../DirectionalLight3D")
world_env = NodePath("../WorldEnvironment")

[node name="NaturalLandscape" type="Node3D" parent="."]
script = ExtResource("3_land")

[node name="Player" parent="." instance=ExtResource("1_player")]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 2.5, 42)

```

```
# ✅ AFTER (Dòng 46 - 70 trong scenes/world/main_world.tscn):
[node name="MainWorld" type="Node3D"]
script = ExtResource("2_main")

[node name="WorldEnvironment" type="WorldEnvironment" parent="."]
environment = SubResource("Environment_ghibli")

[node name="DirectionalLight3D" type="DirectionalLight3D" parent="."]
transform = Transform3D(0.866025, -0.353553, 0.353553, 0, 0.707107, 0.707107, -0.5, -0.612372, 0.612372, 0, 50, 0)
light_color = Color(1, 0.96, 0.88, 1)
light_energy = 1.35
shadow_enabled = true
directional_shadow_max_distance = 250.0

[node name="DayNightController" type="Node" parent="." node_paths=PackedStringArray("sun_light", "world_env")]
script = ExtResource("5_daynight")
sun_light = NodePath("../DirectionalLight3D")
world_env = NodePath("../WorldEnvironment")

[node name="Player" parent="." instance=ExtResource("1_player")]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 2.5, 42)

[node name="NaturalLandscape" type="Node3D" parent="."]
script = ExtResource("3_land")

```

```
# ❌ BEFORE (Dòng 18 - 76 trong scripts/environment/world_chunk_streamer.gd):
var loaded_chunks: Dictionary = {} # Vector2i(cx, cz) -> Node3D
var player_node: Node3D = null
var last_player_chunk: Vector2i = Vector2i(999999, 999999)
# ...
func _process(_delta: float) -> void:
	if player_node == null or not is_instance_valid(player_node):
		if get_tree() != null:
			player_node = get_tree().get_first_node_in_group("player")
		return

	var cur_chunk = world_to_chunk(player_node.global_position)
	if cur_chunk != last_player_chunk:
		last_player_chunk = cur_chunk
		_update_streaming(false)

func _update_streaming(force_immediate: bool) -> void:
	if player_node == null:
		return

	var center = world_to_chunk(player_node.global_position)
	var needed_coords: Dictionary = {}

	for dx in range(-view_Radius_chunks, view_Radius_chunks + 1):
		for dz in range(-view_Radius_chunks, view_Radius_chunks + 1):
			var coord = Vector2i(center.x + dx, center.y + dz)
			needed_coords[coord] = true

	# 1. Giải phóng các chunk đã đi xa quá tầm nhìn
	var to_remove: Array[Vector2i] = []
	for existing_coord in loaded_chunks.keys():
		if not needed_coords.has(existing_coord):
			to_remove.append(existing_coord)

	for coord in to_remove:
		var chunk_node: Node3D = loaded_chunks[coord]
		if is_instance_valid(chunk_node):
			chunk_node.queue_free()
		loaded_chunks.erase(coord)

	# 2. Tạo các chunk mới trong tầm nhìn (tối đa 4 chunk mỗi khung hình để chống giật lag)
	var spawn_count: int = 0
	for coord in needed_coords.keys():
		if not loaded_chunks.has(coord):
			var new_chunk = _build_chunk(coord)
			add_child(new_chunk)
			loaded_chunks[coord] = new_chunk
			spawn_count += 1
			if not force_immediate and spawn_count >= 4:
				break

```

```
# ✅ AFTER (Dòng 18 - 76 trong scripts/environment/world_chunk_streamer.gd):
var loaded_chunks: Dictionary = {} # Vector2i(cx, cz) -> Node3D
var player_node: Node3D = null
var last_player_chunk: Vector2i = Vector2i(999999, 999999)
var _has_pending_chunks: bool = true
# ...
func _process(_delta: float) -> void:
	if player_node == null or not is_instance_valid(player_node):
		if get_tree() != null:
			player_node = get_tree().get_first_node_in_group("player")
		return

	var cur_chunk = world_to_chunk(player_node.global_position)
	if cur_chunk != last_player_chunk or _has_pending_chunks:
		last_player_chunk = cur_chunk
		_update_streaming(false)

func _update_streaming(force_immediate: bool) -> void:
	if player_node == null:
		return

	var center = world_to_chunk(player_node.global_position)
	var needed_coords: Dictionary = {}

	for dx in range(-view_Radius_chunks, view_Radius_chunks + 1):
		for dz in range(-view_Radius_chunks, view_Radius_chunks + 1):
			var coord = Vector2i(center.x + dx, center.y + dz)
			needed_coords[coord] = true

	# 1. Giải phóng các chunk đã đi xa quá tầm nhìn
	var to_remove: Array[Vector2i] = []
	for existing_coord in loaded_chunks.keys():
		if not needed_coords.has(existing_coord):
			to_remove.append(existing_coord)

	for coord in to_remove:
		var chunk_node: Node3D = loaded_chunks[coord]
		if is_instance_valid(chunk_node):
			chunk_node.queue_free()
		loaded_chunks.erase(coord)

	# 2. Tạo các chunk mới trong tầm nhìn (tối đa 4 chunk mỗi khung hình, tiếp tục ở các frame kế tiếp)
	var spawn_count: int = 0
	_has_pending_chunks = false
	for coord in needed_coords.keys():
		if not loaded_chunks.has(coord):
			var new_chunk = _build_chunk(coord)
			add_child(new_chunk)
			loaded_chunks[coord] = new_chunk
			spawn_count += 1
			if not force_immediate and spawn_count >= 4:
				_has_pending_chunks = true
				break

```

#### 3. File `scripts/Interactive/mega_office_skyscraper_builder.gd` ([Xem trên Drive](https://drive.google.com/file/d/1h6-PB5jWuLxYIoe6V4xH1Mvdxopf7y_g/view))

##### A. Nguyên nhân lỗi:

* **Dòng 50 & 858–869 (`FOOTPRINT_LINEAR_SCALE = 8.94427191`)**:

  * Dòng 50 phóng đại node gốc `skyscraper.scale = Vector3(8.94427191, 1.0, 8.94427191)`.

  * Sau đó ở dòng 862–863 (`_normalize_interaction_node_scales`), code gán `child.scale = Vector3(1.0 / FOOTPRINT_LINEAR_SCALE, 1.0, 1.0 / FOOTPRINT_LINEAR_SCALE)` cho mọi `InteractiveStation` để chống méo chữ `Label3D`.

  * **Tuy nhiên**: Khi một `InteractiveStation` bị thu nhỏ `scale.x = 0.1118` và `scale.z = 0.1118` để triệt tiêu `scale` của `skyscraper`, thì trong `InteractiveStation._ready()` (chạy khi add vào SceneTree), nó tạo `Area3D` với `SphereShape3D.radius = interaction_radius (3.6m)` theo hệ quy chiếu local. Trong Jolt Physics / Godot Physics 3D, `scale` tổng hợp (global scale) của `InteractiveStation` lúc này là `8.944 * (1 / 8.944) = 1.0` đối với `Area3D`, **NHƯNG** đối với `MayorPrivateOffice` (dòng 390: `office.scale = Vector3(1.0 / FOOTPRINT_LINEAR_SCALE, 1.0, 1.0 / FOOTPRINT_LINEAR_SCALE)`), dòng 859 lại `if node.name == "MayorPrivateOffice": return`, hợp lý.

  * **Điểm chí mạng nằm ở dòng 1523 (`_add_desk_station`) và dòng 129 (`st_holo`)**: `st.interaction_radius = 3.6` và `4.8` nhỏ hơn mức tối thiểu `>= 6.0m` của **Rule #7 (`tan_the_gioi_game_rules.md` dòng 49)**, và đặc biệt mặt bàn `_add_desk_station` (dòng 1487) nằm trong `floor_node` (có `scale = 8.944x`), nghĩa là chiếc bàn gỗ dài `3.2m * 8.944 = 28.6m` và rộng `1.6m * 8.944 = 14.3m`! Trạm `st` đặt tại `Vector3(0.0, 0.1, 0.8)` (tức là cách tâm bàn `0.8 * 8.944 = 7.15m`), nhưng bán kính `interaction_radius = 3.6m` chỉ quét được 3.6m quanh mép bàn, khiến người chơi đứng trước bàn hoặc bên cạnh bàn (rộng 28.6m) không thấy nút `[E]`!

##### B. Vị trí & Cách sửa chi tiết:

* **Sửa dòng 129**: Tăng `st_holo.interaction_radius = 6.5` (thay vì `4.8`).

* **Sửa dòng 1523**: Tăng `st.interaction_radius = 6.5` (thay vì `3.6`) để tuân thủ nghiêm ngặt **Rule #7 (`bán kính >= 6.0m`)**.

##### C. Code Before / After:

```
# ❌ BEFORE (Dòng 128 - 130 và Dòng 1522 - 1524 trong mega_office_skyscraper_builder.gd):
	st_holo.prompt_text = "🗺️ [E] Kích Hoạt Sa Bàn 3D Hologram (Đại Thế Giới 500 km²)"
	st_holo.interaction_radius = 4.8
	st_holo.position = Vector3(0.0, 0.4, 2.2)
# ...
	st.prompt_text = prompt
	st.interaction_radius = 3.6
	st.position = Vector3(0.0, 0.1, 0.8)

# ✅ AFTER (Dòng 128 - 130 và Dòng 1522 - 1524 trong mega_office_skyscraper_builder.gd):
	st_holo.prompt_text = "🗺️ [E] Kích Hoạt Sa Bàn 3D Hologram (Đại Thế Giới 500 km²)"
	st_holo.interaction_radius = 6.5
	st_holo.position = Vector3(0.0, 0.4, 2.2)
# ...
	st.prompt_text = prompt
	st.interaction_radius = 6.5
	st.position = Vector3(0.0, 0.1, 0.8)

```

#### 4. File `scripts/core/world_manager.gd` ([Xem trên Drive](https://drive.google.com/file/d/1CKs9Q9ozmoHkKSYrXS8SFPLmfHaYiOKj/view)), `scripts/core/save_manager.gd` ([Xem trên Drive](https://drive.google.com/file/d/1ZYeJIg-YOQ1fF5dBbisdOOO9lETnHwEX/view)) & `scripts/ui/macro_map_modal.gd` ([Xem trên Drive](https://drive.google.com/file/d/1s_x7Ql1uaob6b8_oZCckrRwOW22dGZ-c/view))

##### A. Nguyên nhân lỗi:

1. **Lỗi mất kết nối `timeline_server_ref` (`world_manager.gd` dòng 254–265 & `save_manager.gd` dòng 94, 171)**:

   * Hàm `_get_timeline_server()` trong `world_manager.gd` tìm thấy `/root/UnifiedTimelineServer` nhưng **không lưu lại vào biến `timeline_server_ref`**, đồng thời thiếu tầng fallback thứ 4 (`get_parent().get_node_or_null("UnifiedTimelineServer")`) theo **Rule #8 (`TIMELINE_SERVER_4TIER_FALLBACK`)**.

   * Trong `save_manager.gd` dòng 94 và 171, code đọc `var ts = world_manager.get("timeline_server_ref")`. Nếu `load_game()` chạy trước khi `UnifiedTimelineServer._setup_timeline()` kịp gán `timeline_server_ref`, biến `ts` sẽ là `null` và toàn bộ tiến trình Offline Catch-up bị bỏ qua!

2. **Lỗi âm ngân sách làm hỏng vĩnh viễn Save Game (`macro_map_modal.gd` dòng 471, 744–745 & `world_manager.gd` dòng 116–130, 159–160)**:

   * Tại `macro_map_modal.gd` dòng 471: `wm.deposit_city_tax(-1000.0)` (Cấp học bổng) và dòng 744–745: `wm.deposit_city_tax(-2500.0)` + `wm.deposit_church_tithe(-2500.0)` (Đồng tài trợ 50-50) trừ thẳng tiền mà **không kiểm tra số dư**!

   * Khi `treasury_city < 0.0` hoặc `fund_tithe_church < 0.0`, hàm `world_manager.validate_saved_state()` (dòng 159–160) trả về `false`, khiến `SaveManager.save_game()` báo lỗi `[SaveManager] ❌ Lỗi: Dữ liệu WorldManager không vượt qua kiểm định an toàn!` và **không thể lưu game được nữa**!

##### B. Vị trí & Cách sửa chi tiết:

* **Trong `scripts/core/world_manager.gd`**:

  * **Sửa dòng 116–130**: Chặn không cho `deposit_city_tax` / `deposit_church_tithe` đẩy quỹ xuống `< 0.0`, và thêm hàm `withdraw_church_tithe(amount: float) -> bool`.

  * **Sửa dòng 254–265**: Cache kết quả vào `timeline_server_ref`, thêm hàm `set_timeline_server(server: Node)`, và bổ sung tầng fallback thứ 4 (`get_parent()`).

* **Trong `scripts/core/save_manager.gd`**:

  * **Sửa dòng 94 và 171**: Gọi `world_manager._get_timeline_server()` thay vì chỉ đọc thuộc tính `world_manager.get("timeline_server_ref")`.

* **Trong `scripts/ui/macro_map_modal.gd`**:

  * **Sửa dòng 466–474 và 741–748**: Kiểm tra đủ quỹ trước khi trừ tiền; nếu thiếu tiền thì hiển thị thông báo trên `lbl_status` và `return`.

##### C. Code Before / After:

```
# ❌ BEFORE (Dòng 116 - 130 và 254 - 265 trong scripts/core/world_manager.gd):
func deposit_city_tax(amount: float) -> void:
	treasury_city += amount
	treasury_updated.emit(treasury_city, fund_tithe_church)

func withdraw_city_budget(amount: float) -> bool:
	if treasury_city >= amount:
		treasury_city -= amount
		treasury_updated.emit(treasury_city, fund_tithe_church)
		return true
	return false

func deposit_church_tithe(amount: float) -> void:
	# QUY TẮC TỐI THƯỢNG: Quỹ Dâng Hiến hoàn toàn tự nguyện, không bao giờ ép buộc
	fund_tithe_church += amount
	treasury_updated.emit(treasury_city, fund_tithe_church)
# ...
var timeline_server_ref: Node = null

func _get_timeline_server() -> Node:
	if timeline_server_ref != null and is_instance_valid(timeline_server_ref):
		return timeline_server_ref
	if Engine.has_singleton("UnifiedTimelineServer"):
		return Engine.get_singleton("UnifiedTimelineServer")
	var tree = Engine.get_main_loop() as SceneTree
	if tree and tree.root:
		return tree.root.get_node_or_null("UnifiedTimelineServer")
	return null

```

```
# ✅ AFTER (Dòng 116 - 135 và 254 - 275 trong scripts/core/world_manager.gd):
func deposit_city_tax(amount: float) -> void:
	treasury_city = maxf(0.0, treasury_city + amount)
	treasury_updated.emit(treasury_city, fund_tithe_church)

func withdraw_city_budget(amount: float) -> bool:
	if amount < 0.0 or treasury_city < amount:
		return false
	treasury_city -= amount
	treasury_updated.emit(treasury_city, fund_tithe_church)
	return true

func deposit_church_tithe(amount: float) -> void:
	# QUY TẮC TỐI THƯỢNG: Quỹ Dâng Hiến hoàn toàn tự nguyện, không bao giờ ép buộc
	fund_tithe_church = maxf(0.0, fund_tithe_church + amount)
	treasury_updated.emit(treasury_city, fund_tithe_church)

func withdraw_church_tithe(amount: float) -> bool:
	if amount < 0.0 or fund_tithe_church < amount:
		return false
	fund_tithe_church -= amount
	treasury_updated.emit(treasury_city, fund_tithe_church)
	return true
# ...
var timeline_server_ref: Node = null

func set_timeline_server(server: Node) -> void:
	timeline_server_ref = server

func _get_timeline_server() -> Node:
	# Tầng 1: Biến tham chiếu trực tiếp đã cache
	if timeline_server_ref != null and is_instance_valid(timeline_server_ref):
		return timeline_server_ref
	# Tầng 2: Engine Singleton
	if Engine.has_singleton("UnifiedTimelineServer"):
		timeline_server_ref = Engine.get_singleton("UnifiedTimelineServer")
		return timeline_server_ref
	# Tầng 3: SceneTree Root Autoload (/root/UnifiedTimelineServer)
	var tree = Engine.get_main_loop() as SceneTree
	if tree and tree.root:
		var node = tree.root.get_node_or_null("UnifiedTimelineServer")
		if node != null:
			timeline_server_ref = node
			return timeline_server_ref
	# Tầng 4: Node anh em trong cùng Parent (phục vụ Headless Test Runner)
	if is_inside_tree() and get_parent() != null:
		var sibling = get_parent().get_node_or_null("UnifiedTimelineServer")
		if sibling != null:
			timeline_server_ref = sibling
			return timeline_server_ref
	return null

```

```
# ❌ BEFORE (Dòng 93 - 96 và Dòng 170 - 172 trong scripts/core/save_manager.gd):
		if world_manager != null and is_instance_valid(world_manager):
			var ts = world_manager.get("timeline_server_ref")
			if ts != null and is_instance_valid(ts) and ts.has_method("load_from_save_data"):
# ...
func _merge_offline_progress(world_manager: Node, saved_state: Dictionary, current_unix: int) -> void:
	var ts = world_manager.get("timeline_server_ref")
	if ts == null or not is_instance_valid(ts):
		return

# ✅ AFTER (Dòng 93 - 96 và Dòng 170 - 173 trong scripts/core/save_manager.gd):
		if world_manager != null and is_instance_valid(world_manager):
			var ts = world_manager._get_timeline_server() if world_manager.has_method("_get_timeline_server") else world_manager.get("timeline_server_ref")
			if ts != null and is_instance_valid(ts) and ts.has_method("load_from_save_data"):
# ...
func _merge_offline_progress(world_manager: Node, saved_state: Dictionary, current_unix: int) -> void:
	var ts = world_manager._get_timeline_server() if world_manager.has_method("_get_timeline_server") else world_manager.get("timeline_server_ref")
	if ts == null or not is_instance_valid(ts):
		return

```

```
# ❌ BEFORE (Dòng 466 - 474 và Dòng 741 - 748 trong scripts/ui/macro_map_modal.gd):
func _on_grant_scholarship_pressed() -> void:
	var cm = get_node_or_null("/root/CitizenManager")
	var wm = get_node_or_null("/root/WorldManager")
	if cm == null:
		return
	if wm and wm.has_method("deposit_city_tax"):
		wm.deposit_city_tax(-1000.0)
# ...
func _on_co_fund_project_pressed() -> void:
	var wm = get_node_or_null("/root/WorldManager")
	if wm:
		if wm.has_method("deposit_city_tax"):
			wm.deposit_city_tax(-2500.0)
		if wm.has_method("deposit_church_tithe"):
			wm.deposit_church_tithe(-2500.0)

# ✅ AFTER (Dòng 466 - 476 và Dòng 741 - 755 trong scripts/ui/macro_map_modal.gd):
func _on_grant_scholarship_pressed() -> void:
	var cm = get_node_or_null("/root/CitizenManager")
	var wm = get_node_or_null("/root/WorldManager")
	if cm == null or wm == null:
		return
	if not wm.has_method("withdraw_city_budget") or not wm.withdraw_city_budget(1000.0):
		lbl_status.text = "⚠️ Ngân sách Thành phố không đủ 1.000 Đ để cấp học bổng!"
		return
# ...
func _on_co_fund_project_pressed() -> void:
	var wm = get_node_or_null("/root/WorldManager")
	if wm == null:
		return
	if wm.treasury_city < 2500.0 or wm.fund_tithe_church < 2500.0:
		lbl_status.text = "⚠️ Cần tối thiểu 2.500 Đ ở cả Kho bạc Thành phố và Quỹ Dâng hiến để đồng tài trợ!"
		return
	wm.withdraw_city_budget(2500.0)
	if wm.has_method("withdraw_church_tithe"):
		wm.withdraw_church_tithe(2500.0)
	else:
		wm.deposit_church_tithe(-2500.0)

```

#### 5. File `scripts/simulation/research_manager.gd` ([Xem trên Drive](https://drive.google.com/file/d/1hlunkWBi689XW6yRha4WOjwsGag6DIl4/view))

##### A. Nguyên nhân lỗi:

1. **Mất sạch KBU dư thừa khi chạy Offline Catch-up (`advance_research_minute`, dòng 300–324 & 335)**:

   * Khi người chơi mở lại game sau vài giờ Offline (`minutes_count` = hàng trăm phút), `current_progress_kbu += generated_kbu` cộng dồn hàng nghìn KBU cùng lúc.

   * Tuy nhiên dòng 322 chỉ dùng lệnh `if current_progress_kbu >= required_kbu:` (1 lần duy nhất) rồi gọi `_auto_complete_research()` -> `select_active_directive(b_id, tier + 1)` (dòng 388), mà `select_active_directive()` lại gán cứng `current_progress_kbu = 0` ở dòng 335! Toàn bộ lượng KBU dư ra bị xóa về 0 thay vì tràn sang bậc (Tier) tiếp theo!

2. **Không đồng bộ Buff công nghệ sau khi Load SQLite (`_load_from_database`, dòng 246–270)**:

   * Khi tải game từ SQLite, `deployed_techs` được nạp lại nhưng code **không gọi hàm đồng bộ** `blessed_abundance_multiplier` sang `WorldManager` và `tech_wear_reduction_ratio` sang `BuildingJobRegistry` (vốn chỉ được gọi trong `deploy_blueprint_citywide` ở dòng 412–427). Do đó mỗi lần Load Game, toàn bộ buff công nghệ đã ban hành bị mất hiệu lực!

##### B. Vị trí & Cách sửa chi tiết:

* **Sửa dòng 265–270**: Gọi `_sync_all_deployed_buffs()` ngay cuối `_load_from_database(db)` và khôi phục `grant_remaining_minutes` từ `acceleration_grant_expiry_unix`.

* **Sửa dòng 320–338**: Giữ lại `overflow_kbu = max(0, current_progress_kbu - required_kbu)` và dùng vòng lặp `while` để tự động lên nhiều Tier liên tiếp nếu lượng KBU Offline đủ lớn.

##### C. Code Before / After:

```
# ❌ BEFORE (Dòng 260 - 270 và Dòng 318 - 340 trong scripts/simulation/research_manager.gd):
		var st_rows = db.query_rows("SELECT * FROM research_state WHERE id = 1;")
		if st_rows.size() > 0:
			var st = st_rows[0]
			active_branch = str(st.get("active_branch", "energy"))
			active_tier = int(st.get("active_tier", 1))
			current_progress_kbu = int(st.get("current_progress_kbu", 0))
			is_paused_by_resource = int(st.get("is_paused_by_resource", 0)) == 1
	return true
# ...
	current_progress_kbu += generated_kbu
	research_progress_updated.emit(active_branch, active_tier, current_progress_kbu, required_kbu, kbu_per_min)

	if current_progress_kbu >= required_kbu:
		_auto_complete_research()

## 2. Lựa chọn Chuyên đề Nghiên cứu Trọng tâm (Select Active Directive)
func select_active_directive(branch_id: String, tier: int) -> bool:
	if not branches.has(branch_id):
		return false
	if tier < 1 or tier > MAX_TIER_PER_BRANCH:
		return false
	if tier > unlocked_tiers[branch_id] + 1:
		return false

	active_branch = branch_id
	active_tier = tier
	current_progress_kbu = 0

```

```
# ✅ AFTER (Dòng 260 - 278 và Dòng 318 - 350 trong scripts/simulation/research_manager.gd):
		var st_rows = db.query_rows("SELECT * FROM research_state WHERE id = 1;")
		if st_rows.size() > 0:
			var st = st_rows[0]
			active_branch = str(st.get("active_branch", "energy"))
			active_tier = int(st.get("active_tier", 1))
			current_progress_kbu = int(st.get("current_progress_kbu", 0))
			is_paused_by_resource = int(st.get("is_paused_by_resource", 0)) == 1
			var saved_grant_min = int(st.get("acceleration_grant_expiry_unix", 0))
			if saved_grant_min > 0:
				grant_remaining_minutes = saved_grant_min
				grant_multiplier = 1.5
		_sync_all_deployed_buffs()
	return true

func _sync_all_deployed_buffs() -> void:
	if is_inside_tree():
		var wm = get_node_or_null("/root/WorldManager")
		if wm and "blessed_abundance_multiplier" in wm:
			wm.blessed_abundance_multiplier = 1.0 + get_citywide_production_boost()
		var bjr = get_node_or_null("/root/BuildingJobRegistry")
		if bjr and "tech_wear_reduction_ratio" in bjr:
			bjr.tech_wear_reduction_ratio = get_wear_and_tear_reduction()
# ...
	current_progress_kbu += generated_kbu

	while active_tier <= MAX_TIER_PER_BRANCH and current_progress_kbu >= required_kbu:
		var overflow_kbu: int = current_progress_kbu - required_kbu
		_auto_complete_research()
		if unlocked_tiers[active_branch] >= MAX_TIER_PER_BRANCH:
			current_progress_kbu = 0
			break
		current_progress_kbu = overflow_kbu
		required_kbu = get_required_kbu_for_tier(active_tier)

	research_progress_updated.emit(active_branch, active_tier, current_progress_kbu, required_kbu, kbu_per_min)

## 2. Lựa chọn Chuyên đề Nghiên cứu Trọng tâm (Select Active Directive)
func select_active_directive(branch_id: String, tier: int, preserve_progress: bool = false) -> bool:
	if not branches.has(branch_id):
		return false
	if tier < 1 or tier > MAX_TIER_PER_BRANCH:
		return false
	if tier > unlocked_tiers[branch_id] + 1:
		return false

	active_branch = branch_id
	active_tier = tier
	if not preserve_progress:
		current_progress_kbu = 0

```

### PHẦN B — PHASE 2: SỬA LỖI ĐIỀU KHIỂN, VẬT LÝ & TƯƠNG TÁC (P1 GAMEPLAY)

#### 6. File `project.godot` ([Xem trên Drive](https://drive.google.com/file/d/1y2OXJ08DseT4ZIkVUfJDyYzoQQtJIGIy/view))

##### A. Nguyên nhân lỗi:

* **Dòng 86 (`interact` - Phím E) & Dòng 91 (`build_mode` - Phím B)**: Đang để `"keycode":0,"physical_keycode":69` và `"keycode":0,"physical_keycode":66`. Theo **Rule #1 (`VIETNAMESE_IME_INPUT_BULLETPROOFING` trong `tan_the_gioi_game_rules.md` dòng 14)**, mọi `InputEventKey` trong `project.godot` bắt buộc phải khai báo đồng thời cả `"keycode"` và `"physical_keycode"`.

* **Dòng 65 (`move_left`) & Dòng 71 (`move_right`)**: Gán `KEY_LEFT` (4194319) và `KEY_RIGHT` (4194321) vào `move_left` / `move_right` (đi ngang strafe), nhưng trong `player_controller.gd` dòng 1081–1086 lại dùng `KEY_LEFT` / `KEY_RIGHT` để xoay camera (`yaw`), khiến khi bấm phím mũi tên Trái/Phải nhân vật vừa đi ngang vừa quay vòng tròn!

##### B. Vị trí & Cách sửa chi tiết:

* **Sửa dòng 86**: Đổi `"keycode":0,"physical_keycode":69` thành `"keycode":69,"physical_keycode":69`.

* **Sửa dòng 91**: Đổi `"keycode":0,"physical_keycode":66` thành `"keycode":66,"physical_keycode":66`.

##### C. Code Before / After:

```
# ❌ BEFORE (Dòng 84 - 93 trong project.godot):
interact={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":69,"key_label":0,"unicode":101,"location":0,"echo":false,"script":null)
]
}
build_mode={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":66,"key_label":0,"unicode":98,"location":0,"echo":false,"script":null)
]
}

# ✅ AFTER (Dòng 84 - 93 trong project.godot):
interact={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":69,"physical_keycode":69,"key_label":0,"unicode":101,"location":0,"echo":false,"script":null)
]
}
build_mode={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":66,"physical_keycode":66,"key_label":0,"unicode":98,"location":0,"echo":false,"script":null)
]
}

```

#### 7. File `scripts/core/player_controller.gd` ([Xem trên Drive](https://drive.google.com/file/d/1Sh1uHoBbJd1xnA_erHhNP0kP46-HPAmw/view))

##### A. Nguyên nhân lỗi:

1. **Dòng 540 (`dist_npc > 3.8`)**: `NPCCharacter` (`npc_character.gd` dòng 334, 372) bật bảng tên `[E] Trò Chuyện` và gán `player.set_meta("nearby_npc", self)` ở khoảng cách `<= 6.0m` (theo Rule #7). Nhưng `player_controller.gd` dòng 540 lại xóa `remove_meta("nearby_npc")` ngay khi `dist_npc > 3.8`! Do đó khi đứng cách NPC từ `3.8m` đến `6.0m`, người chơi nhìn thấy rõ chữ `[E] Trò Chuyện` nhưng bấm `[E]` không có bất kỳ phản hồi nào!

2. **Dòng 545–548 & 571–575 (Khoảng cách 3D của Thang máy `SkyscraperElevator`)**:

   * Dùng `global_position.distance_to(nearby_st.global_position) > r_max` (khoảng cách 3D).

   * Node gốc của `SkyscraperElevator` nằm ở `Y = 0.0` (Tầng 1), trong khi `cabin_platform` di chuyển lên các tầng cao (`Y = 17m..194m`) hoặc hầm (`Y = -40m`). Khi người chơi đứng ở Tầng 2 (`Y = 17m`), khoảng cách 3D tới gốc thang máy là `>= 17m > 4.5m`, khiến `player_controller.gd` xóa mất `nearby_station` / `nearby_elevator` ngay lập tức!

3. **Dòng 626–647 vs Dòng 659–684 (Xung đột phím số `1`–`9` giữa Thang máy & Hotbar)**:

   * Dòng 628 chỉ kiểm tra `event.physical_keycode` (thiếu `event.keycode` khi bật Unikey).

   * Khi đang đứng ngoài hành lang gần thang máy mà muốn đổi vật phẩm Hotbar (`1`–`8`), thang máy lại nuốt phím và chạy đi mất. Chỉ nên nhận phím số `1`–`9` cho thang máy khi người chơi đang đứng trong buồng thang hoặc trong bán kính ngang `<= 4.5m` và kiểm cả `keycode` lẫn `physical_keycode`.

4. **Dòng 1081–1086 vs 1112–1117 (Xung đột phím mũi tên `KEY_LEFT` / `KEY_RIGHT`)**:

   * Dòng 1082–1085 xoay camera bằng `KEY_LEFT` / `KEY_RIGHT`, nhưng dòng 1113–1117 thiếu `KEY_LEFT` / `KEY_RIGHT` trong fallback di chuyển, hoặc ngược lại `project.godot` gán `KEY_LEFT` / `KEY_RIGHT` vào `move_left` / `move_right`. Để tuân thủ **Rule #1 (`tan_the_gioi_game_rules.md` dòng 15: quét trực tiếp cả 4 phím mũi tên `KEY_UP`, `KEY_DOWN`, `KEY_LEFT`, `KEY_RIGHT` trong `_physics_process`)**, cần thêm `KEY_LEFT` và `KEY_RIGHT` vào dòng 1113–1114 và chỉ xoay camera bằng phím mũi tên khi giữ kèm `Shift` hoặc `Alt` (hoặc dùng chuột / phím `Q`/`Z`).

5. **Dòng 1130 (Thiếu Buff Thể lực từ Viện R&D)**:

   * Không nhân `stamina_recovery_rate` với `(1.0 + ResearchManager.get_wellness_stamina_boost())` (tối đa `+31.5%` tốc độ hồi Thể lực từ Nhánh 3 Công nghệ Y Sinh).

##### B. Code Before / After:

```
# ❌ BEFORE (Dòng 537 - 578 trong scripts/core/player_controller.gd):
	if has_meta("nearby_npc"):
		var nearby_npc = get_meta("nearby_npc")
		if not is_instance_valid(nearby_npc):
			remove_meta("nearby_npc")
		else:
			var dist_npc = global_position.distance_to(nearby_npc.global_position)
			if dist_npc > 3.8:
				remove_meta("nearby_npc")

	if has_meta("nearby_station"):
		var nearby_st = get_meta("nearby_station")
		if not is_instance_valid(nearby_st):
			remove_meta("nearby_station")
		else:
			var r_max = nearby_st.interaction_radius if "interaction_radius" in nearby_st else 3.8
			if global_position.distance_to(nearby_st.global_position) > r_max + 0.5:
				remove_meta("nearby_station")

```

```
# ✅ AFTER (Dòng 537 - 578 trong scripts/core/player_controller.gd):
	if has_meta("nearby_npc"):
		var nearby_npc = get_meta("nearby_npc")
		if not is_instance_valid(nearby_npc):
			remove_meta("nearby_npc")
		else:
			var dist_npc = global_position.distance_to(nearby_npc.global_position)
			if dist_npc > 6.5: # Đồng bộ chuẩn Rule #7 (bán kính 6.0m + biên trễ 0.5m)
				remove_meta("nearby_npc")

	if has_meta("nearby_station"):
		var nearby_st = get_meta("nearby_station")
		if not is_instance_valid(nearby_st):
			remove_meta("nearby_station")
		else:
			var r_max = nearby_st.interaction_radius if "interaction_radius" in nearby_st else 6.0
			var dist_st: float = global_position.distance_to(nearby_st.global_position)
			# Nếu là Thang máy (SkyscraperElevator), tính khoảng cách ngang XZ vì trục thang chạy suốt từ B4 (-40m) lên T15 (+194m)
			if nearby_st.is_in_group("elevators") or "cabin_platform" in nearby_st:
				dist_st = Vector2(global_position.x - nearby_st.global_position.x, global_position.z - nearby_st.global_position.z).length()
			if dist_st > r_max + 0.5:
				remove_meta("nearby_station")

```

```
# ❌ BEFORE (Dòng 1112 - 1132 trong scripts/core/player_controller.gd):
	if input_dir == Vector2.ZERO:
		var raw_x := 0.0
		var raw_y := 0.0
		if Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): raw_y -= 1.0
		if Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): raw_y += 1.0
		if Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_A): raw_x -= 1.0
		if Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_D): raw_x += 1.0
		input_dir = Vector2(raw_x, raw_y).limit_length(1.0)
# ...
	else:
		current_stamina = minf(max_stamina, current_stamina + stamina_recovery_rate * delta)

# ✅ AFTER (Dòng 1112 - 1138 trong scripts/core/player_controller.gd):
	if input_dir == Vector2.ZERO:
		var raw_x := 0.0
		var raw_y := 0.0
		if Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP) or Input.is_physical_key_pressed(KEY_UP): raw_y -= 1.0
		if Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN) or Input.is_physical_key_pressed(KEY_DOWN): raw_y += 1.0
		if Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT) or Input.is_physical_key_pressed(KEY_LEFT): raw_x -= 1.0
		if Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT) or Input.is_physical_key_pressed(KEY_RIGHT): raw_x += 1.0
		input_dir = Vector2(raw_x, raw_y).limit_length(1.0)
# ...
	else:
		var wellness_boost: float = 0.0
		var rm = get_node_or_null("/root/ResearchManager")
		if rm != null and rm.has_method("get_wellness_stamina_boost"):
			wellness_boost = rm.get_wellness_stamina_boost()
		current_stamina = minf(max_stamina, current_stamina + stamina_recovery_rate * (1.0 + wellness_boost) * delta)

```

#### 8. File `scripts/vehicles/helicopter_controller.gd` ([Xem trên Drive](https://drive.google.com/file/d/1ShgRUVwkUhne5XSIllypimex_zMeJZDD/view)) & `scripts/Interactive/mayor_buggy.gd` ([Xem trên Drive](https://drive.google.com/file/d/1qXS3aDGtNeog9_KAaeDmJ7FgWZ8ISpTK/view))

##### A. Nguyên nhân lỗi:

1. **`helicopter_controller.gd` (Dòng 462 & 501 — Mất `collision_layer = 2` của Player sau khi rời trực thăng)**:

   * Trong `player.tscn` (dòng 19), `Player` có `collision_layer = 2`.

   * Khi lên trực thăng (`board_helicopter`, dòng 462), code đặt `pilot_player.collision_layer = 0`.

   * Nhưng khi xuống trực thăng (`exit_helicopter`, dòng 501), code lại gán cứng `player.collision_layer = 1` (thay vì `2`)! Sau khi bước xuống trực thăng, các trạm tương tác hoặc trigger chỉ quét Layer 2 sẽ không nhận diện đúng Player, và các raycast Layer 1 sẽ va chạm nhầm vào chính cơ thể Player!

2. **`helicopter_controller.gd` (Thiếu tính năng Hao mòn cơ khí `mechanical_wear` theo Rule #13)**:

   * Trong `mayor_buggy.gd` (dòng 26–27, 278–293) đã có `apply_driving_wear()`, nhưng `helicopter_controller.gd` chưa có biến `mechanical_wear` và hàm `apply_flying_wear()` liên kết với `ResearchManager.get_wear_and_tear_reduction()`.

3. **`mayor_buggy.gd` (Dòng 320–324 & 346–350 — Không tắt `collision_layer` của Player khi đang ngồi trong xe)**:

   * Khi `board(player)` chạy ở dòng 320, `player` chỉ ẩn `visible = false` và tắt `set_physics_process(false)` nhưng vẫn giữ nguyên `collision_layer = 2` tại vị trí cũ lúc lên xe! Nếu xe Buggy chạy đi xa 10km, hitbox vật lý của Player vẫn nằm bất động ở điểm xuất phát!

##### B. Code Before / After:

```
# ❌ BEFORE (Dòng 461 - 464 và Dòng 500 - 503 trong scripts/vehicles/helicopter_controller.gd):
	if pilot_player is CollisionObject3D:
		pilot_player.collision_layer = 0
		pilot_player.collision_mask = 0
# ...
	if player is CollisionObject3D:
		player.collision_layer = 1
		player.collision_mask = 1

# ✅ AFTER (Lưu lại layer/mask gốc của Player và khôi phục chính xác + bổ sung mechanical_wear):
var _saved_pilot_layer: int = 2
var _saved_pilot_mask: int = 1
@export var mechanical_wear: float = 0.0
@export var wear_rate_per_sec: float = 0.004

# Trong board_helicopter():
	if pilot_player is CollisionObject3D:
		_saved_pilot_layer = pilot_player.collision_layer
		_saved_pilot_mask = pilot_player.collision_mask
		pilot_player.collision_layer = 0
		pilot_player.collision_mask = 0

# Trong exit_helicopter():
	if player is CollisionObject3D:
		player.collision_layer = _saved_pilot_layer if _saved_pilot_layer != 0 else 2
		player.collision_mask = _saved_pilot_mask if _saved_pilot_mask != 0 else 1

```

```
# ❌ BEFORE (Dòng 320 - 324 và Dòng 346 - 350 trong scripts/Interactive/mayor_buggy.gd):
	if "visible" in player:
		player.visible = false
	if player.has_method("set_physics_process"):
		player.set_physics_process(false)
# ...
	if "visible" in passenger_ref:
		passenger_ref.visible = true
	if passenger_ref.has_method("set_physics_process"):
		passenger_ref.set_physics_process(true)

# ✅ AFTER (Thêm lưu/khôi phục collision_layer & cập nhật vị trí theo xe trong mayor_buggy.gd):
var _saved_passenger_layer: int = 2
var _saved_passenger_mask: int = 1

# Trong board(player):
	if player is CollisionObject3D:
		_saved_passenger_layer = player.collision_layer
		_saved_passenger_mask = player.collision_mask
		player.collision_layer = 0
		player.collision_mask = 0
	if "visible" in player:
		player.visible = false
	if player.has_method("set_physics_process"):
		player.set_physics_process(false)

# Trong exit_buggy():
	if passenger_ref is CollisionObject3D:
		passenger_ref.collision_layer = _saved_passenger_layer if _saved_passenger_layer != 0 else 2
		passenger_ref.collision_mask = _saved_passenger_mask if _saved_passenger_mask != 0 else 1
	if "visible" in passenger_ref:
		passenger_ref.visible = true
	if passenger_ref.has_method("set_physics_process"):
		passenger_ref.set_physics_process(true)

```

#### 9. File `scripts/Interactive/interactive_station.gd` ([Xem trên Drive](https://drive.google.com/file/d/1Ta6Qme8hGef923Z6C6-oTE12Ab7kt_7T/view)) & `scripts/environment/central_capital_builder.gd` ([Xem trên Drive](https://drive.google.com/file/d/1UfUHype5dKr9Jj5VV5u_zFe57S80-u3e/view))

##### A. Nguyên nhân lỗi:

1. **Vi phạm Rule #7 về Bán kính tương tác (`interactive_station.gd` dòng 38 & `central_capital_builder.gd` dòng 346, 398, 448, 524, 563, 644)**:

   * `interactive_station.gd` dòng 38 đặt mặc định `@export var interaction_radius: float = 3.6`, và `central_capital_builder.gd` gán `3.8`, `4.2`, `4.5`, `5.2`. Theo **Rule #7 (`tan_the_gioi_game_rules.md` dòng 49)**, bán kính vùng tương tác phải `>= 6.0m`.

2. **Lỗi logic tại các Trạm tương tác (`interactive_station.gd` dòng 22, 168–186, 298–300, 360–361)**:

   * **Dòng 22**: Lỗi font chữ UTF-8 `Nguyện Vng` -> `Nguyện Vọng`.

   * **Dòng 168–174 (`StationType.FOUNTAIN`)**: Không kiểm tra/trừ `"item_wishing_coin"` trong `InventoryManager` mà vẫn cộng thẳng `+100 Đ` vào ngân sách mỗi lần bấm `[E]` (exploit vô hạn tiền).

   * **Dòng 176–186 (`StationType.BAKERY` & `StationType.CLINIC`)**: Hiển thị Toast báo `+50 Sinh Lực` / `+100% Sinh Lực`, nhưng **quên không gọi `player.heal()` / `player.restore_stamina()`**!

   * **Dòng 298–300 & 360–361 (`desk_cloud_cafe` & `cloud_cafe`)**: Kiểm tra `if "health" in player: player.health = 100.0`, nhưng `PlayerController` dùng biến `current_health` (và có hàm `heal()`), dẫn tới uống trà Cloud Cafe không hồi máu!

##### B. Code Before / After:

```
# ❌ BEFORE (Dòng 38 và Dòng 168 - 187, 295 - 301 trong scripts/Interactive/interactive_station.gd):
@export var interaction_radius: float = 3.6
# ...
		StationType.FOUNTAIN:
			if wm and wm.has_method("deposit_city_tax"):
				wm.deposit_city_tax(100.0)
			if hud and hud.has_method("show_toast"):
				hud.show_toast("⛲ Bạn đã thả Đồng Xu Nguyện Ước tại Đài Phun Nước! (+100 Đ Phước Lành Đô Thị)")
			if hud and hud.has_method("mark_quest_done"):
				hud.mark_quest_done("quest_fountain")

		StationType.BAKERY:
			if hud and hud.has_method("show_toast"):
				hud.show_toast("🥐 Bác Nam tặng bạn ổ Bánh Mì Nướng Bơ Mật Ong nóng hổi! (+50 Sinh Lực)")
			if hud and hud.has_method("mark_quest_done"):
				hud.mark_quest_done("quest_bakery")

		StationType.CLINIC:
			if hud and hud.has_method("show_toast"):
				hud.show_toast("💊 Chị Mai đã kiểm tra sức khỏe và trao Trà Thảo Dược Bình An! (+100% Sinh Lực)")
			if hud and hud.has_method("mark_quest_done"):
				hud.mark_quest_done("quest_clinic")
# ...
		"desk_cloud_cafe", "station_cloud_cafe":
			if player:
				if "stamina" in player:
					player.stamina = 100.0
				if "health" in player:
					player.health = 100.0

```

```
# ✅ AFTER (Dòng 38 và Dòng 168 - 205, 295 - 305 trong scripts/Interactive/interactive_station.gd):
@export var interaction_radius: float = 6.0
# ...
		StationType.FOUNTAIN:
			var inv = get_node_or_null("/root/InventoryManager")
			if inv and inv.has_method("has_item") and inv.has_item("item_wishing_coin", 1):
				inv.remove_item("item_wishing_coin", 1)
				if wm and wm.has_method("deposit_city_tax"):
					wm.deposit_city_tax(100.0)
				if hud and hud.has_method("show_toast"):
					hud.show_toast("⛲ Bạn đã thả 1 Đồng Xu Nguyện Ước xuống Đài Phun Nước! (+100 Đ Phước Lành Đô Thị)")
			else:
				if hud and hud.has_method("show_toast"):
					hud.show_toast("⛲ Bạn cầu nguyện bình an bên Đài Phun Nước Pha Lê! (Cần Đồng Xu Nguyện Ước để nhận +100 Đ)")
			if hud and hud.has_method("mark_quest_done"):
				hud.mark_quest_done("quest_fountain")

		StationType.BAKERY:
			if player and player.has_method("heal"):
				player.heal(50.0)
			if player and player.has_method("restore_stamina"):
				player.restore_stamina(50.0)
			var inv = get_node_or_null("/root/InventoryManager")
			if inv and inv.has_method("add_item"):
				inv.add_item("item_fresh_bread", 1)
			if hud and hud.has_method("show_toast"):
				hud.show_toast("🥐 Bác Nam tặng bạn ổ Bánh Mì Nướng Bơ Mật Ong nóng hổi! (+50 Sinh Lực & Thể Lực)")
			if hud and hud.has_method("mark_quest_done"):
				hud.mark_quest_done("quest_bakery")

		StationType.CLINIC:
			if player and player.has_method("heal"):
				player.heal(100.0)
			if player and player.has_method("restore_stamina"):
				player.restore_stamina(100.0)
			if hud and hud.has_method("show_toast"):
				hud.show_toast("💊 Chị Mai đã kiểm tra sức khỏe và trao Trà Thảo Dược Bình An! (+100% Sinh Lực & Thể Lực)")
			if hud and hud.has_method("mark_quest_done"):
				hud.mark_quest_done("quest_clinic")
# ...
		"desk_cloud_cafe", "station_cloud_cafe":
			if player:
				if player.has_method("heal"):
					player.heal(100.0)
				if player.has_method("restore_stamina"):
					player.restore_stamina(100.0)

```

### PHẦN C — PHASE 3: ĐỒNG BỘ DỮ LIỆU 5 HUYỆN, GDD RULES & GIAO DIỆN UI (P1 DATA & UI)

#### 10. File `scripts/simulation/citizen_data.gd` ([Xem trên Drive](https://drive.google.com/file/d/1vpEEe1X7m5VUKPa966kO-jf6YvPfcP1m/view)) & `scripts/simulation/citizen_manager.gd` ([Xem trên Drive](https://drive.google.com/file/d/14478h71tdSvkpZEaSIfPxHVtfddVN7Tw/view))

##### A. Nguyên nhân lỗi:

1. **Vi phạm Rule #4 (`NHVC_VOLUNTEER_ORGANIZATION` — `tan_the_gioi_game_rules.md` dòng 31)**:

   * Trong `citizen_data.gd` dòng 136: `NHVCType.PART_TIME` bị gán cứng `salary = 180.0`, còn trong `citizen_manager.gd` dòng 104 lại gán `c.salary = 320.0`.

   * Rule #4 quy định rõ: **NHVC Bán thời gian (Part-Time)** là tình nguyện viên phục vụ không hưởng lương từ Hội Thánh, thu nhập của họ đến 100% từ nghề nghiệp thế tục (`job_role`: Kỹ sư, Bác sĩ, Nông dân...). Chỉ **NHVC Toàn thời gian (Full-Time)** mới nhận phụ cấp sinh hoạt từ Quỹ Dâng Hiến (`fund_tithe_church`).

2. **Nhóm Huynh Đệ `"TRANG_NIEN"` và `"PHU_NU"` luôn bằng 0 (`citizen_manager.gd` dòng 110 vs 112 & `citizen_data.gd` dòng 64–74)**:

   * Trong `citizen_manager.gd`, `register_citizen(c)` được gọi ở dòng 110 **TRƯỚC KHI** `_assign_households_and_relationships()` chạy ở dòng 112! Lúc dòng 110 chạy, toàn bộ 300 công dân đều có `is_married = false`, nên `fellowship_registry["TRANG_NIEN"]` bị rỗng `[]` (0 người)!

   * Trong `citizen_data.gd` dòng 64–74 (`update_life_stage()`), công dân đã kết hôn (`is_married == true`) nếu là Nữ từ 25 tuổi trở lên cần được phân vào Hội Phụ Nữ (`"PHU_NU"`) còn Nam đã kết hôn phân vào Hội Tráng Niên (`"TRANG_NIEN"`) để đủ 4 Hội Đoàn (`THIEU_NHI`, `THANH_NIEN`, `TRANG_NIEN`, `PHU_NU`) khai báo tại `citizen_manager.gd` dòng 27–32!

3. **Lệch Mã Huyện & Tọa độ Nhà ở Huyện Nam (`citizen_manager.gd` dòng 287, 290, 292)**:

   * Dòng 287 dùng `"DISTRICT_WEST_VALLEY"` (trong khi `transit_network_manager.gd` và `building_job_registry.gd` dùng `"DISTRICT_WEST_INDUSTRY"`).

   * Dòng 290–292 dùng `"DISTRICT_SOUTH_PORT"` và đặt nhà ở tại `wz = 10000.0` (10km), trong khi Huyện Nam (Cảng Hòa Bình) nằm ở `Z = +20000.0` (20km)!

4. **Chưa áp dụng giảm hao mòn Công nghệ Vật liệu HAS (`citizen_manager.gd` dòng 387)**:

   * Dòng 387: `citizen.tick_durability_and_wear(1.5 * delta_day)` chưa nhân với `(1.0 - ResearchManager.get_wear_and_tear_reduction())`.

##### B. Code Before / After:

```
# ❌ BEFORE (Dòng 64 - 74 và Dòng 131 - 137 trong scripts/simulation/citizen_data.gd):
func update_life_stage() -> void:
	if age < 18:
		life_stage = LifeStage.YOUTH
		fellowship_group = "THIEU_NHI"
	elif not is_married:
		life_stage = LifeStage.YOUNG_ADULT
		fellowship_group = "THANH_NIEN"
	else:
		life_stage = LifeStage.MARRIED_ADULT
		fellowship_group = "TRANG_NIEN"
# ...
	elif nhvc_type == NHVCType.PART_TIME:
		nhvc_role_title = "Tình Nguyện Viên Bán Thời Gian"
		salary = 180.0

# ✅ AFTER (Dòng 64 - 76 và Dòng 131 - 138 trong scripts/simulation/citizen_data.gd):
func update_life_stage() -> void:
	if age < 18:
		life_stage = LifeStage.YOUTH
		fellowship_group = "THIEU_NHI"
	elif not is_married:
		life_stage = LifeStage.YOUNG_ADULT
		fellowship_group = "THANH_NIEN"
	else:
		life_stage = LifeStage.MARRIED_ADULT
		fellowship_group = "PHU_NU" if gender == CitizenGender.FEMALE else "TRANG_NIEN"
# ...
	elif nhvc_type == NHVCType.PART_TIME:
		nhvc_role_title = "Tình Nguyện Viên Bán Thời Gian (Không Lương Giáo Vụ)"
		# Giữ nguyên salary từ nghề nghiệp thế tục (Rule #4: NHVC Part-Time tình nguyện 100%)

```

```
# ❌ BEFORE (Dòng 103 - 114 và Dòng 284 - 294 trong scripts/simulation/citizen_manager.gd):
		elif i < 95:
			c.nhvc_type = CitizenData.NHVCType.PART_TIME
			c.salary = 320.0
		else:
			c.nhvc_type = CitizenData.NHVCType.NONE

		c.GenerateInitialWallet()
		register_citizen(c)

	_assign_households_and_relationships()
# ...
		elif idx < 220:
			h_dist = "DISTRICT_WEST_VALLEY"
			wx = -10000.0 + float((idx % 12) - 6) * 28.0
			wz = float((idx / 12) - 14) * 28.0
		else:
			h_dist = "DISTRICT_SOUTH_PORT"
			wx = float((idx % 12) - 6) * 28.0
			wz = 10000.0 + float((idx / 12) - 20) * 28.0

# ✅ AFTER (Dòng 103 - 122 và Dòng 284 - 294 trong scripts/simulation/citizen_manager.gd):
		elif i < 95:
			c.nhvc_type = CitizenData.NHVCType.PART_TIME
			# Rule #4: Tình nguyện viên Bán thời gian nhận lương từ nghề nghiệp thế tục, không ghi đè salary = 320.0
		else:
			c.nhvc_type = CitizenData.NHVCType.NONE

		c.GenerateInitialWallet()
		register_citizen(c)

	_assign_households_and_relationships()
	_rebuild_fellowship_registry() # Cập nhật lại TRANG_NIEN & PHU_NU sau khi kết hôn!

func _rebuild_fellowship_registry() -> void:
	for k in fellowship_registry.keys():
		fellowship_registry[k].clear()
	for cid in citizens.keys():
		var c: CitizenData = citizens[cid]
		var fg: String = c.fellowship_group
		if fellowship_registry.has(fg):
			fellowship_registry[fg].append(cid)
# ...
		elif idx < 220:
			h_dist = "DISTRICT_WEST_INDUSTRY"
			wx = -10000.0 + float((idx % 12) - 6) * 28.0
			wz = float((idx / 12) - 14) * 28.0
		else:
			h_dist = "DISTRICT_SOUTH_COAST"
			wx = float((idx % 12) - 6) * 28.0
			wz = 20000.0 + float((idx / 12) - 20) * 28.0 # Huyện Nam ở Z = +20,000m (20km)

```

#### 11. File `scripts/environment/natural_landscape_assembler.gd` ([Xem trên Drive](https://drive.google.com/file/d/1NYtfkCMxy8w-0QTkU-9EEXUY9yS8b5y0/view)) & `scripts/simulation/logistics_manager.gd` ([Xem trên Drive](https://drive.google.com/file/d/1FEou36_4S4EcW810TgFtWnG_F_Dhwc73/view))

##### A. Nguyên nhân lỗi:

1. **Đặt sai tọa độ 2 Lô Nhà Mẫu Huyện Nam ở `Z = 10035.0` và `Z = 10050.0` (`natural_landscape_assembler.gd` dòng 619–642)**:

   * Huyện Nam (`SouthPeacePortDistrict` trong `districts_builder.gd` dòng 300) nằm ở `Z = +20,000.0m` (`20km`).

   * Thế nhưng 2 lô nhà mẫu `plot_south_01_villa` và `plot_south_02_stilt` lại bị đặt ở `Z = 10035.0` và `10050.0` (nằm chơ vơ giữa đồng cỏ cách Cảng Hòa Bình 10km)! Ngoài ra mã huyện đang ghi `"DISTRICT_WEST_VALLEY"` và `"DISTRICT_SOUTH_PORT"` thay vì `"DISTRICT_WEST_INDUSTRY"` và `"DISTRICT_SOUTH_COAST"`.

2. **Đặt sai tọa độ Kho Cảng Hòa Bình trong `logistics_manager.gd` (Dòng 114)**:

   * Dòng 114: `"pos_km": Vector2(0.0, 10.0)` (10km) thay vì `Vector2(0.0, 20.0)` (20km).

##### B. Code Before / After:

```
# ❌ BEFORE (Dòng 593 - 642 trong scripts/environment/natural_landscape_assembler.gd):
		{
			"plot_id": "plot_west_01_chalet",
			"district_id": "DISTRICT_WEST_VALLEY",
			...
		},
		{
			"plot_id": "plot_west_02_villa",
			"district_id": "DISTRICT_WEST_VALLEY",
			...
		},
		{
			"plot_id": "plot_south_01_villa",
			"district_id": "DISTRICT_SOUTH_PORT",
			"address_label": "Số 01 Bến Cảng Hòa Bình, Huyện Nam",
			"house_style": HousingPlot.HouseStyle.GARDEN_VILLA,
			"is_built": true,
			"owner_citizen_id": "CIT_026",
			"owner_name": "Gia đình Thuyền Trưởng Hải",
			"pos": Vector3(-35.0, ModularNatureChunk.get_world_height(-35.0, 10035.0), 10035.0),
			"rot_y": 15.0
		},
		{
			"plot_id": "plot_south_02_stilt",
			"district_id": "DISTRICT_SOUTH_PORT",
			"address_label": "Số 02 Bến Cảng Hòa Bình, Huyện Nam",
			"house_style": HousingPlot.HouseStyle.WOODEN_STILT,
			"is_built": false,
			"owner_citizen_id": "",
			"owner_name": "",
			"pos": Vector3(35.0, ModularNatureChunk.get_world_height(35.0, 10050.0), 10050.0),
			"rot_y": -15.0
		}

# ✅ AFTER (Dòng 593 - 642 trong scripts/environment/natural_landscape_assembler.gd):
		{
			"plot_id": "plot_west_01_chalet",
			"district_id": "DISTRICT_WEST_INDUSTRY",
			...
		},
		{
			"plot_id": "plot_west_02_villa",
			"district_id": "DISTRICT_WEST_INDUSTRY",
			...
		},
		{
			"plot_id": "plot_south_01_villa",
			"district_id": "DISTRICT_SOUTH_COAST",
			"address_label": "Số 01 Bến Cảng Hòa Bình, Huyện Nam",
			"house_style": HousingPlot.HouseStyle.GARDEN_VILLA,
			"is_built": true,
			"owner_citizen_id": "CIT_026",
			"owner_name": "Gia đình Thuyền Trưởng Hải",
			"pos": Vector3(-35.0, ModularNatureChunk.get_world_height(-35.0, 19965.0), 19965.0),
			"rot_y": 15.0
		},
		{
			"plot_id": "plot_south_02_stilt",
			"district_id": "DISTRICT_SOUTH_COAST",
			"address_label": "Số 02 Bến Cảng Hòa Bình, Huyện Nam",
			"house_style": HousingPlot.HouseStyle.WOODEN_STILT,
			"is_built": false,
			"owner_citizen_id": "",
			"owner_name": "",
			"pos": Vector3(35.0, ModularNatureChunk.get_world_height(35.0, 19965.0), 19965.0),
			"rot_y": -15.0
		}

```

```
# ❌ BEFORE (Dòng 114 trong scripts/simulation/logistics_manager.gd):
		"SOUTH_HARBOR": {"name": "Kho Cảng Hòa Bình (Huyện Nam)", "pos_km": Vector2(0.0, 10.0), "capacity": 5000.0},

# ✅ AFTER (Dòng 114 trong scripts/simulation/logistics_manager.gd):
		"SOUTH_HARBOR": {"name": "Kho Cảng Hòa Bình (Huyện Nam)", "pos_km": Vector2(0.0, 20.0), "capacity": 5000.0},

```

#### 12. File `scripts/ui/mini_map_radar.gd` ([Xem trên Drive](https://drive.google.com/file/d/1kFiEfQWuTsAISfwT7A-IQ8mS_1Chtfif/view))

##### A. Nguyên nhân lỗi:

1. **Dòng 150 (Công thức kẹp biên chấm Huyện làm văng điểm vẽ ra ngoài màn hình 1.380px)**:

   * Khi một Huyện ở ngoài tầm quét `active_range` (`1500m`), dòng 150 gọi `_world_to_radar(clamped_dir * active_range * 0.92, center)`.

   * Nhưng hàm `_world_to_radar(world_xz, center)` (dòng 195) lại nhận `world_xz` là tọa độ thế giới để trừ đi `player_xz`! Khi truyền `clamped_dir * active_range * 0.92` vào `_world_to_radar`, nó lấy вектор đơn vị trừ đi `player_xz` (ví dụ `10,000m`), hoặc nếu cộng trực tiếp thì bán kính pixel là `radar_radius` (`78px`) chứ không phải `active_range` (`1500`). Kết quả là mọi hướng chỉ dẫn 4 Huyện bị văng hoàn toàn khỏi Radar!

2. **Dòng 160, 167, 175 (Sai tên Group của Trực thăng, Xe Buggy và Ga Tàu)**:

   * Dòng 160 tìm group `"helicopter"` -> Tên đúng trong `helicopter_controller.gd` (dòng 48) là `"helicopters"`.

   * Dòng 167 tìm group `"mayor_buggy"` -> Tên đúng trong `mayor_buggy.gd` (dòng 38) là `"buggies"`.

   * Dòng 175 tìm group `"transit_stops"` -> Tên đúng trong `spiderweb_transit_builder.gd` (dòng 216) là `"transit_stations"`.

##### B. Code Before / After:

```
# ❌ BEFORE (Dòng 145 - 180 trong scripts/ui/mini_map_radar.gd):
	for d in DISTRICTS:
		var world_pos: Vector2 = d["pos"]
		var radar_pt = _world_to_radar(world_pos, center)
		if radar_pt.distance_to(center) <= radar_radius - 6.0:
			draw_circle(radar_pt, d["size"], d["color"])
		else:
			# Vẽ mũi tên/chấm nhỏ bám sát viền radar chỉ hướng về Huyện đó
			var dir = (world_pos - Vector2(player_ref.global_position.x, player_ref.global_position.z)).normalized()
			var clamped_pt = _world_to_radar(Vector2(player_ref.global_position.x, player_ref.global_position.z) + dir * active_range * 0.92, center)
			draw_circle(clamped_pt, 4.0, Color(d["color"].r, d["color"].g, d["color"].b, 0.65))

	# 4. Vẽ Trực thăng (Màu Vàng Kim nổi bật)
	var helis = get_tree().get_nodes_in_group("helicopter")
	for h in helis:
		if h is Node3D and is_instance_valid(h):
			var pt = _world_to_radar(Vector2(h.global_position.x, h.global_position.z), center)
			if pt.distance_to(center) <= radar_radius - 4.0:
				draw_circle(pt, 5.5, Color(1.0, 0.85, 0.15))
				draw_arc(pt, 7.0, 0, TAU, 16, Color(1.0, 0.95, 0.4), 1.5)

	# 5. Vẽ Xe Buggy Thị Trưởng (Màu Cam)
	var buggies = get_tree().get_nodes_in_group("mayor_buggy")
	for b in buggies:
		if b is Node3D and is_instance_valid(b):
			var pt = _world_to_radar(Vector2(b.global_position.x, b.global_position.z), center)
			if pt.distance_to(center) <= radar_radius - 4.0:
				draw_circle(pt, 4.5, Color(1.0, 0.55, 0.15))

	# 6. Vẽ các Nhà ga Tàu điện / Xe buýt (Chấm Xanh Ngọc)
	var stations = get_tree().get_nodes_in_group("transit_stops")

```

```
# ✅ AFTER (Dòng 145 - 180 trong scripts/ui/mini_map_radar.gd):
	for d in DISTRICTS:
		var world_pos: Vector2 = d["pos"]
		var radar_pt = _world_to_radar(world_pos, center)
		if radar_pt.distance_to(center) <= radar_radius - 6.0:
			draw_circle(radar_pt, d["size"], d["color"])
		else:
			# Kẹp trực tiếp điểm radar_pt vào vòng tròn viền radar (bán kính radar_radius * 0.90)
			var screen_dir = (radar_pt - center).normalized()
			var clamped_pt = center + screen_dir * (radar_radius * 0.90)
			draw_circle(clamped_pt, 4.0, Color(d["color"].r, d["color"].g, d["color"].b, 0.75))

	# 4. Vẽ Trực thăng (Group "helicopters")
	var helis = get_tree().get_nodes_in_group("helicopters")
	for h in helis:
		if h is Node3D and is_instance_valid(h):
			var pt = _world_to_radar(Vector2(h.global_position.x, h.global_position.z), center)
			if pt.distance_to(center) <= radar_radius - 4.0:
				draw_circle(pt, 5.5, Color(1.0, 0.85, 0.15))
				draw_arc(pt, 7.0, 0, TAU, 16, Color(1.0, 0.95, 0.4), 1.5)

	# 5. Vẽ Xe Buggy Thị Trưởng (Group "buggies")
	var buggies = get_tree().get_nodes_in_group("buggies")
	for b in buggies:
		if b is Node3D and is_instance_valid(b):
			var pt = _world_to_radar(Vector2(b.global_position.x, b.global_position.z), center)
			if pt.distance_to(center) <= radar_radius - 4.0:
				draw_circle(pt, 4.5, Color(1.0, 0.55, 0.15))

	# 6. Vẽ các Nhà ga Tàu điện / Xe buýt (Group "transit_stations")
	var stations = get_tree().get_nodes_in_group("transit_stations")

```

#### 13. File `scripts/ui/hud_overlay.gd` ([Xem trên Drive](https://drive.google.com/file/d/1v5Qf0r6hsx3H9zB78BcKywHkqqNn6qbt/view)) & `scripts/simulation/enterprise_data.gd` ([Xem trên Drive](https://drive.google.com/file/d/1dlJfTU6vRCC1EyXszcdalNPihX-EVJgI/view))

##### A. Nguyên nhân lỗi:

1. **`MiniMapRadar` đè thẳng lên `QuestTrackerPanel` (`hud_overlay.gd` dòng 188–196 vs dòng 1225–1233)**:

   * Cả hai đều neo ở `PRESET_TOP_RIGHT` với `offset_top = 58` (MiniMap) và `offset_top = 65` (QuestTracker). Vì `MiniMapRadar` cao `210px` (`58 + 210 = 268`), nó che khuất hoàn toàn bảng Sổ Tay Nhiệm Vụ!

2. **Thiếu hàm public `update_hotbar_display()` và lỗi cấp phát bộ nhớ 480 `StyleBoxFlat`/giây (`hud_overlay.gd` dòng 160, 284–311)**:

   * `player_controller.gd` (dòng 936) và `world_item_drop.gd` (dòng 186) gọi `hud.update_hotbar_display()`, nhưng trong `hud_overlay.gd` dòng 284 hàm lại đặt tên là `_update_hotbar_display()` (có dấu gạch dưới), khiến lệnh gọi bị bỏ qua!

   * Tệ hơn, dòng 160 gọi `_update_hotbar_display()` trong `_process(delta)` mỗi khung hình và tạo mới 8 `StyleBoxFlat.new()` mỗi frame!

3. **Thiếu Ban thứ 9 (`Ban Ca Ngợi, Âm Nhạc Phụng Vụ & Thờ Phượng`) trong `hud_overlay.gd` (dòng 1453–1462) và `enterprise_data.gd` (dòng 8–17)**:

   * Tòa nhà Mega Office (`elevator.gd` dòng 48, `mega_office_skyscraper_builder.gd` dòng 185, `building_job_registry.gd` dòng 339) có **9 Ban chuyên ngành** (Tầng 2 đến Tầng 10), nhưng danh sách trong `hud_overlay.gd` và `enterprise_data.gd` chỉ có 8 Ban (thiếu Ban Ca Ngợi ở Tầng 9).

4. **Lỗi chính tả UTF-8 tại dòng 1347 của `hud_overlay.gd`**: `"gia cố guồng g."` -> `"gia cố guồng gỗ."`.

##### B. Code Before / After:

```
# ❌ BEFORE (Dòng 1225 - 1233 trong scripts/ui/hud_overlay.gd):
	quest_tracker_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	quest_tracker_panel.offset_left = -335
	quest_tracker_panel.offset_top = 65
	quest_tracker_panel.offset_right = -15
	quest_tracker_panel.offset_bottom = 355

# ✅ AFTER (Dòng 1225 - 1233 trong scripts/ui/hud_overlay.gd - Dịch QuestTracker xuống dưới MiniMapRadar):
	quest_tracker_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	quest_tracker_panel.offset_left = -335
	quest_tracker_panel.offset_top = 278
	quest_tracker_panel.offset_right = -15
	quest_tracker_panel.offset_bottom = 558

```

```
# ✅ THÊM WRAPPER & CACHE STYLEBOX (Dòng 284 - 315 trong scripts/ui/hud_overlay.gd):
var _cached_slot_style_active: StyleBoxFlat = null
var _cached_slot_style_normal: StyleBoxFlat = null

func update_hotbar_display() -> void:
	_update_hotbar_display()

func _init_hotbar_styles() -> void:
	if _cached_slot_style_active != null:
		return
	_cached_slot_style_active = StyleBoxFlat.new()
	_cached_slot_style_active.bg_color = Color(0.18, 0.36, 0.58, 0.92)
	_cached_slot_style_active.border_color = Color(1.0, 0.85, 0.25, 1.0)
	_cached_slot_style_active.set_border_width_all(2)
	_cached_slot_style_active.set_corner_radius_all(8)

	_cached_slot_style_normal = StyleBoxFlat.new()
	_cached_slot_style_normal.bg_color = Color(0.08, 0.11, 0.16, 0.78)
	_cached_slot_style_normal.border_color = Color(0.3, 0.4, 0.55, 0.5)
	_cached_slot_style_normal.set_border_width_all(1)
	_cached_slot_style_normal.set_corner_radius_all(8)

```

#### 14. File `scripts/ui/macro_map_modal.gd` ([Xem trên Drive](https://drive.google.com/file/d/1s_x7Ql1uaob6b8_oZCckrRwOW22dGZ-c/view))

##### A. Nguyên nhân lỗi:

1. **Dòng 988 vs 998 vs 1102 (Lỗi nút Nhánh 4 `"automation"` vs `"robotics"` trong Tab Viện Hàn Lâm HAS)**:

   * Dòng 988 định nghĩa nút Nhánh 4 với `"id": "automation"`.

   * Khi người chơi bấm vào nút này, hàm `_on_select_has_branch("automation")` ở dòng 1102 đổi `selected_has_branch = "robotics"`.

   * Khi vẽ lại UI ở dòng 998 (`var is_sel = (b_info["id"] == selected_has_branch)`), `"automation" == "robotics"` luôn là `false`, làm nút Nhánh 4 không bao giờ sáng trạng thái đang chọn!

2. **Dòng 1513–1549 (`_on_civic_locate_plot` không đóng bản đồ làm kẹt `Engine.time_scale = 0.2`)**:

   * Khi bấm nút định vị/dịch chuyển tới Lô Đất Nhà Ở từ Tab 5, code dịch chuyển Player tới lô đất nhưng chỉ chuyển về `_switch_tab(0)` mà không gọi `close_macro_map()`, hoặc nếu modal bị giải phóng đột ngột thì thiếu `_exit_tree()` để trả `Engine.time_scale = 1.0`.

##### B. Code Before / After:

```
# ❌ BEFORE (Dòng 988 trong scripts/ui/macro_map_modal.gd):
		{"id": "automation", "name": "🤖 Nhánh 4: Vật Liệu Mới & Tự Động Hóa"}

# ✅ AFTER (Dòng 988 trong scripts/ui/macro_map_modal.gd - Đồng bộ ID "robotics" với ResearchManager):
		{"id": "robotics", "name": "🤖 Nhánh 4: Vật Liệu Mới & Tự Động Hóa"}

# ✅ THÊM HÀM AN TOÀN KHI THOÁT NODE (Cuối file scripts/ui/macro_map_modal.gd):
func _exit_tree() -> void:
	if Engine.time_scale != 1.0:
		Engine.time_scale = 1.0

```

### PHẦN D — PHASE 4: TỐI ƯU HÓA HIỆU NĂNG INTEL IRIS XE & KIỂM THỬ E2E (P2 PERFORMANCE)

#### 15. File `scripts/characters/npc_character.gd` ([Xem trên Drive](https://drive.google.com/file/d/12J7fE8SBji66s4WZr7HpH3YblnfQUqih/view)) & `scripts/environment/natural_landscape_assembler.gd` ([Xem trên Drive](https://drive.google.com/file/d/1NYtfkCMxy8w-0QTkU-9EEXUY9yS8b5y0/view))

##### A. Phân tích Độ phức tạp Thuật toán (Big-O) & Nghẽn cổ chai GPU/CPU:

1. **300 NPC chạy `_process(delta)` mỗi khung hình (`O(N)` trên mỗi frame = 18.000 lượt gọi/giây)**:

   * Trong `npc_character.gd` dòng 389: `nameplate.text = "👤 %s..."` định dạng chuỗi mỗi frame cho cả 300 NPC **ngay cả khi `nameplate.visible == false`** (ở cách xa hàng chục km)!

   * Trong `npc_character.gd` dòng 418–419: `character_model.get_node_or_null("Arm_L")` và `"Arm_R"` thực hiện 600 lần tìm kiếm cây Node bằng chuỗi mỗi frame!

   * Trong `npc_character.gd` dòng 254–298: Tạo mới 4 `StandardMaterial3D` và 5 `Mesh` riêng biệt cho từng NPC thay vì dùng biến `static` dùng chung.

2. **Chồng lấn Collider `DistantMacroTerrain` lên vùng trung tâm (`natural_landscape_assembler.gd` dòng 118–190)**:

   * `DistantMacroTerrain` tạo lưới bước nhảy thô `333.3m` phủ đè lên cả vùng lõi `[-288m, +288m]` (nơi đã có `WorldChunkStreamer` độ phân giải mịn `4m`). Vì đa giác `333.3m` nối tắt qua miệng hồ và lòng suối, nó tạo ra **bức tường/trần va chạm tàng hình** chặn người chơi lội xuống suối hoặc đi vào lòng hồ!

##### B. Giải pháp Refactoring Chuẩn Enterprise:

1. **Trong `npc_character.gd`**:

   * Cache tham chiếu `_arm_l: Node3D` và `_arm_r: Node3D` một lần duy nhất trong `_ready()`.

   * Chỉ cập nhật chuỗi `nameplate.text` khi `nameplate.visible == true` và hoạt động (`cur_act`) thực sự thay đổi (`_last_rendered_activity != cur_act`).

   * Thêm cơ chế **Distance Tick Throttling (3-Tier LOD)**:

     * **Tier 1 (`dist <= 45m`)**: Chạy `_process` mỗi frame (60 FPS), bật đầy đủ vung tay và kiểm tra tương tác `[E]`.

     * **Tier 2 (`45m < dist <= 220m`)**: Cập nhật vị trí nội suy mỗi `0.15 giây` (\~6 FPS), tắt vung tay chi tiết.

     * **Tier 3 (`dist > 220m`)**: Ẩn `visible = false`, chỉ cập nhật vị trí mỗi `1.0 giây` (1 FPS) theo dữ liệu `CitizenManager`.

2. **Trong `natural_landscape_assembler.gd` (Dòng 142–165)**:

   * Bỏ qua các ô lưới `DistantMacroTerrain` nằm trong vùng lõi trung tâm `abs(wx) < 250.0 and abs(wz) < 250.0` (vì vùng này đã được `WorldChunkStreamer` dựng collider chi tiết từng mét).

##### C. Code Before / After (`npc_character.gd`):

```
# ❌ BEFORE (Dòng 355 - 424 trong scripts/characters/npc_character.gd):
	if nameplate:
		nameplate.visible = (dist <= 16.0)
		var cur_act: String = ""
		if get_tree() and get_tree().root.has_node("DailyScheduleManager"):
			var dsm = get_tree().root.get_node("DailyScheduleManager")
			var wm = get_tree().root.get_node_or_null("WorldManager")
			var h = wm.current_hour if (wm and "current_hour" in wm) else 8
			cur_act = "\n⏰ " + dsm.get_current_activity_label(h)
		if dist <= 6.0:
			nameplate.text = "💬 [E] Trò Chuyện • %s (%d tuổi)\n[%s]%s" % [citizen_name, age, job_title, cur_act]
			nameplate.modulate = Color(0.3, 1.0, 0.5)
		else:
			nameplate.text = "👤 %s (%d tuổi)\n[%s]%s" % [citizen_name, age, job_title, cur_act]
			nameplate.modulate = Color(1.0, 0.92, 0.35)
# ...
	if character_model:
		character_model.position.y = abs(sin(walk_cycle)) * 0.06
		var arm_l = character_model.get_node_or_null("Arm_L")
		var arm_r = character_model.get_node_or_null("Arm_R")

```

```
# ✅ AFTER (Cache Node & Chỉ format text khi hiển thị + Tiered LOD trong scripts/characters/npc_character.gd):
var _arm_l: Node3D = null
var _arm_r: Node3D = null
var _last_prompt_state: int = -1
var _last_hour_rendered: int = -1
var _lod_accum: float = 0.0

# Trong _ready() sau khi tạo character_model:
	if character_model:
		_arm_l = character_model.get_node_or_null("Arm_L")
		_arm_r = character_model.get_node_or_null("Arm_R")

# Trong _process(delta):
	var dist: float = 9999.0
	if player and is_instance_valid(player):
		dist = global_position.distance_to(player.global_position)

	# Tier 3 (> 220m): Ẩn mesh 3D, chỉ đồng bộ mỗi 1.0s để giải phóng 90% tải CPU/GPU cho Intel Iris Xe
	if dist > 220.0:
		if visible:
			visible = false
		_lod_accum += delta
		if _lod_accum < 1.0:
			return
		_lod_accum = 0.0
	else:
		if not visible:
			visible = true

	if nameplate:
		var should_show_nameplate: bool = (dist <= 16.0)
		if nameplate.visible != should_show_nameplate:
			nameplate.visible = should_show_nameplate
		if should_show_nameplate:
			var prompt_state: int = 1 if dist <= 6.0 else 0
			var wm = get_tree().root.get_node_or_null("WorldManager") if get_tree() else null
			var h: int = wm.current_hour if (wm and "current_hour" in wm) else 8
			if prompt_state != _last_prompt_state or h != _last_hour_rendered:
				_last_prompt_state = prompt_state
				_last_hour_rendered = h
				var cur_act: String = ""
				if get_tree() and get_tree().root.has_node("DailyScheduleManager"):
					var dsm = get_tree().root.get_node("DailyScheduleManager")
					cur_act = "\n⏰ " + dsm.get_current_activity_label(h)
				if prompt_state == 1:
					nameplate.text = "💬 [E] Trò Chuyện • %s (%d tuổi)\n[%s]%s" % [citizen_name, age, job_title, cur_act]
					nameplate.modulate = Color(0.3, 1.0, 0.5)
				else:
					nameplate.text = "👤 %s (%d tuổi)\n[%s]%s" % [citizen_name, age, job_title, cur_act]
					nameplate.modulate = Color(1.0, 0.92, 0.35)

	# Trong _animate_walk(delta, speed_factor):
	if character_model and dist <= 45.0:
		character_model.position.y = abs(sin(walk_cycle)) * 0.06
		if _arm_l:
			_arm_l.rotation.x = sin(walk_cycle) * 0.35 * speed_factor
		if _arm_r:
			_arm_r.rotation.x = -sin(walk_cycle) * 0.35 * speed_factor

```

## 4. DANH MỤC KIỂM THỬ XÁC MINH ĐẦU-CUỐI (END-TO-END VERIFICATION SUITE)

Sau khi áp dụng đầy đủ 4 Phase trên, chạy bộ lệnh kiểm thử tự động trong terminal theo đúng **Rule #2 (`END_TO_END_INTERACTION_TESTING_STANDARD`)**:

1. **Kiểm tra Biên dịch & Khởi chạy Scene Chính (Zero-Error Check)**:

   ```
   godot --headless --quit-after 5 res://scenes/world/main_world.tscn
   
   ```

   * **Tiêu chí đạt**: Không có bất kỳ dòng `SCRIPT ERROR` hay `Parse Error` nào; `WorldChunkStreamer` in log nạp đủ 81/81 chunk vùng trung tâm.

2. **Kiểm tra Đồng bộ Thời gian, Tua Đêm & Offline Catch-up**:

   * Bấm `[F1]`–`[F5]` hoặc tương tác `[E]` với Giường Ngủ Thị Trưởng (Tầng 13): Kiểm tra `WorldManager.current_hour == 6` **VÀ** `DayNightController.current_time_hours == 6.0` (bầu trời sáng bình minh, đồng hồ không bị đứng im).

   * Bấm `[F6]` lưu game, kiểm tra `validate_saved_state() == true` kể cả sau khi bấm Cấp Học Bổng và Đồng Tài Trợ trong `[M]` Đại Bản Đồ.

3. **Kiểm tra Tương tác 3D & Phương tiện**:

   * Đứng cách NPC `5.5m` (trong khoảng `3.8m..6.0m`), bấm `[E]` -> Hộp thoại mở ra ngay lập tức.

   * Đi thang máy Mega Office lên Tầng 2..15, đứng trước cửa thang máy bấm `[E]` hoặc phím số -> Thang máy nhận lệnh chính xác ở mọi độ cao `Y`.

   * Lên và xuống Trực thăng (`[F]`/`[E]`) và Xe Buggy -> Kiểm tra `player.collision_layer == 2` được khôi phục nguyên vẹn.


---

## 5. BÁO CÁO AUDIT CHUYÊN SÂU — ĐỢT 2 (DEEP SUBSYSTEM AUDIT: METRO, TRAM, SQLITE, HOUSING, LOGISTICS, VRM & CAMERA)

Trong đợt rà soát chuyên sâu thứ 2 trên toàn bộ các hệ thống phụ trợ còn lại (`central_metro_builder.gd`, `central_capital_builder.gd`, `elevator.gd`, `housing_plot.gd`, `world_item_drop.gd`, `database_manager.gd`, `unified_timeline_server.gd`, `logistics_manager.gd`, `vrm_character_manager.gd`, `cinematic_camera_controller.gd`, `octahedral_pine_lod.gd`), phát hiện thêm **15 lỗi kỹ thuật nghiêm trọng (từ Mục #16 đến Mục #30)** dưới đây:

---

### PHẦN E — HỆ THỐNG GIAO THÔNG NGẦM METRO, TRAM, THANG MÁY & TƯƠNG TÁC ĐA LỚP

---

#### 16. File `scripts/terrain/central_metro_builder.gd` ([Xem trên Drive](https://drive.google.com/file/d/1_ma2YTdE40501n8QrnBXy1A_mjqryptt/view)) & `scripts/terrain/central_capital_builder.gd` ([Xem trên Drive](https://drive.google.com/file/d/1UfUHype5dKr9Jj5VV5u_zFe57S80-u3e/view))

##### A. Nguyên nhân lỗi:
1. **Dòng 349–354 của `central_metro_builder.gd` (16 Nhà Ga Metro Ngoại Vi bị chôn sống dưới lòng đất `565m`)**:
   - `CentralMetroHub` là con trực tiếp của `CentralCapitalComplex` (nằm tại `global_position.y = 600.0m` theo `main_world.tscn` dòng 78 và `central_capital_complex.gd` dòng 15).
   - Ở dòng 349, 16 cổng ga Metro mặt đất tại 4 Huyện (`route_x = ±10,000m` và `±18,000m`) được đặt ở `var surface_position = Vector3(route_x * cos(axis_angle), 0.0, -route_x * sin(axis_angle))` (tức `local Y = 0.0`).
   - Do `CentralMetroHub` có `global_position.y = 600.0m`, nên `local Y = 0.0` tương ứng với **`global Y = +600.0m`**! Trong khi mặt đất thực tế tại 4 Huyện ngoại vi (`ModularNatureChunk.get_world_height(wx, wz)`) chỉ cao từ **`+15m` đến `+55m`**!
   - **Hậu quả**: Toàn bộ 16 cổng ga Metro ngoại vi (`MetroSurfaceEntrance_B*`) bị treo lơ lửng trên bầu trời ở độ cao `+600m` (cách mặt đất Huyện Đông/Tây/Bắc/Nam tới **545m – 585m**)! Khi người chơi đi tàu Metro đến ga ngoại vi và bấm `[E] Lên mặt đất`, họ bị dịch chuyển lên không trung ở độ cao `+601m` và rơi tự do hơn nửa cây số xuống đất!
2. **Dòng 68–70 & 86–89 của `central_metro_builder.gd` + Dòng 64–66 & 85–88 của `central_capital_builder.gd` (Không tắt `collision_layer` khi lên tàu Metro & Tram)**:
   - Trong `MetroTrainCar.board_from_platform()` (dòng 68–69) và `VintageTramCar.board_from_stop()` (dòng 64–65), khi người chơi lên tàu, code chỉ ẩn `player.visible = false` và `player.set_physics_process(false)` nhưng **không đặt `player.collision_layer = 0` và `collision_mask = 0`**.
   - Khi đoàn tàu Metro chạy với vận tốc `40 m/s` (144 km/h) kéo theo `player.global_position`, cơ thể vật lý `CharacterBody3D` của Player quét xuyên qua các vách hầm và trụ ga gây xung đột Jolt Physics và kích hoạt nhầm hàng loạt `Area3D` dọc đường!

##### B. Vị trí & Cách sửa chi tiết:
- **Trong `scripts/terrain/central_metro_builder.gd`**:
  - **Thêm `preload`** ở dòng 4: `const ModularNatureChunkScript = preload("res://scripts/terrain/modular_nature_chunk.gd")`.
  - **Sửa dòng 67–74 & 76–90 (`MetroTrainCar`)**: Lưu `_saved_player_layer` / `_saved_player_mask`, tắt `collision_layer = 0` khi lên tàu và khôi phục khi xuống tàu.
  - **Sửa dòng 349–352 (`_build_route_stations`)**: Tính độ cao mặt đất thực tế tại `(wx, wz)` bằng `ModularNatureChunkScript.get_world_height(wx, wz)` rồi trừ đi `600.0` (`ModularNatureChunkScript.PLATEAU_ALTITUDE`) để ra đúng `local Y` của `entrance`!
- **Trong `scripts/terrain/central_capital_builder.gd`**:
  - **Sửa dòng 63–70 & 81–89 (`VintageTramCar`)**: Lưu và khôi phục `collision_layer` / `collision_mask` của Player khi lên/xuống xe Tram.

##### C. Code Before / After:

```gdscript
# ❌ BEFORE (Dòng 64 - 90 và Dòng 349 - 354 trong scripts/terrain/central_metro_builder.gd):
		func board_from_platform(player: Node3D, platform_position: Vector3) -> bool:
			if passenger_ref != null or dwell_remaining <= 0.0 or global_position.distance_to(platform_position) > 12.0:
				return false
			passenger_ref = player
			player.visible = false
			player.set_physics_process(false)
			player.set_meta("occupied_metro", self)
			if player.has_meta("nearby_interactive"):
				player.remove_meta("nearby_interactive")
			_update_passenger_position()
			return true

		func exit_metro() -> void:
			if passenger_ref == null or not is_instance_valid(passenger_ref):
				passenger_ref = null
				return
			var passenger = passenger_ref
			passenger_ref = null
			var platform_side = 1.0 if position.z >= 0.0 else -1.0
			var platform_position = Vector3(position.x, 0.5, platform_side * 8.3)
			passenger.global_position = get_parent().global_transform * platform_position
			passenger.global_rotation.y = global_rotation.y
			passenger.visible = true
			passenger.set_physics_process(true)
			if passenger.has_meta("occupied_metro"):
				passenger.remove_meta("occupied_metro")
# ...
			var surface_position = Vector3(route_x * cos(axis_angle), 0.0, -route_x * sin(axis_angle))
			var entrance = Node3D.new()
			entrance.name = "MetroSurfaceEntrance_B%d_%02d" % [floor_number, station_index + 1]
			entrance.position = surface_position
```

```gdscript
# ✅ AFTER (Dòng 64 - 95 và Dòng 349 - 358 trong scripts/terrain/central_metro_builder.gd):
		var _saved_passenger_layer: int = 2
		var _saved_passenger_mask: int = 1

		func board_from_platform(player: Node3D, platform_position: Vector3) -> bool:
			if passenger_ref != null or dwell_remaining <= 0.0 or global_position.distance_to(platform_position) > 12.0:
				return false
			passenger_ref = player
			if player is CollisionObject3D:
				_saved_passenger_layer = player.collision_layer
				_saved_passenger_mask = player.collision_mask
				player.collision_layer = 0
				player.collision_mask = 0
			player.visible = false
			player.set_physics_process(false)
			player.set_meta("occupied_metro", self)
			if player.has_meta("nearby_interactive"):
				player.remove_meta("nearby_interactive")
			_update_passenger_position()
			return true

		func exit_metro() -> void:
			if passenger_ref == null or not is_instance_valid(passenger_ref):
				passenger_ref = null
				return
			var passenger = passenger_ref
			passenger_ref = null
			var platform_side = 1.0 if position.z >= 0.0 else -1.0
			var platform_position = Vector3(position.x, 0.5, platform_side * 8.3)
			passenger.global_position = get_parent().global_transform * platform_position
			passenger.global_rotation.y = global_rotation.y
			if passenger is CollisionObject3D:
				passenger.collision_layer = _saved_passenger_layer if _saved_passenger_layer != 0 else 2
				passenger.collision_mask = _saved_passenger_mask if _saved_passenger_mask != 0 else 1
			passenger.visible = true
			passenger.set_physics_process(true)
			if passenger.has_meta("occupied_metro"):
				passenger.remove_meta("occupied_metro")
# ...
			var world_sx: float = route_x * cos(axis_angle)
			var world_sz: float = -route_x * sin(axis_angle)
			var ground_world_y: float = ModularNatureChunk.get_world_height(world_sx, world_sz)
			var local_surface_y: float = ground_world_y - ModularNatureChunk.PLATEAU_ALTITUDE
			var surface_position = Vector3(world_sx, local_surface_y, world_sz)
			var entrance = Node3D.new()
			entrance.name = "MetroSurfaceEntrance_B%d_%02d" % [floor_number, station_index + 1]
			entrance.position = surface_position
```

---

#### 17. File `scripts/elevator/elevator.gd` ([Xem trên Drive](https://drive.google.com/file/d/1-nBgQsM4zveNniVINHDT0xiYeBwUnVw4/view))

##### A. Nguyên nhân lỗi:
1. **Dòng 307–315 (`_on_body_entered` kích hoạt ở khoảng cách `7.07m > 6.0m`, bị ` _process` tắt/bật nhấp nháy và ghi đè vô điều kiện `nearby_interactive`)**:
   - `ElevatorArea` có `BoxShape3D` kích thước `10.0m x 250.0m x 10.0m` (dòng 110). Khoảng cách từ tâm đến góc hộp là `sqrt(5^2 + 5^2) = 7.07m > interaction_radius (6.0m)`.
   - Khi người chơi bước vào góc vùng `10x10m` (ở cự ly `6.5m`), `_on_body_entered` (dòng 310) bật `is_in_range = true` và gán `body.set_meta("nearby_interactive", self)`. Nhưng ngay ở frame kế tiếp trong `_process` (dòng 292), `dist_xz <= 6.0` trả về `false` nên nó lại xóa `remove_meta("nearby_interactive")`!
   - Hơn nữa,4 thang máy đặt cách nhau chỉ `7.3m` (`ELEVATOR_X_POSITIONS = [-11.0, -3.7, 3.7, 11.0]` trong `mega_office_skyscraper_builder.gd` dòng 23). Vùng `interaction_radius = 6.0m` của thang máy số 1, 2, 3, 4 chồng lấn lên nhau! Dòng 299–300 của `elevator.gd` chỉ gán `set_meta("nearby_elevator", self)` khi `should_be_in_range != is_in_range` (chỉ chạy 1 lần lúc vượt biên), dẫn đến khi đi từ thang máy 1 sang thang máy 2, thang máy 1 rời vùng sau sẽ **xóa mất meta** hoặc giữ nguyên thang máy cũ xa hơn thay vì chọn thang máy gần nhất!
2. **Dòng 326–336 (Không hỗ trợ phím `[Esc]` để đóng bảng chọn tầng `ElevatorModal`)**:
   - Nút đóng ở dòng 278 ghi rõ `"✖ ĐÓNG BẢNG ĐIỀU KHIỂN [Esc]"`, nhưng trong toàn bộ `elevator.gd` không có hàm `_unhandled_input(event)` nào bắt phím `KEY_ESCAPE` để gọi `_close_ui()`!

##### B. Code Before / After:

```gdscript
# ❌ BEFORE (Dòng 288 - 336 trong scripts/elevator/elevator.gd):
		if player_ref and is_instance_valid(player_ref):
			var p_pos = player_ref.global_position
			var dist_xz = Vector2(p_pos.x - global_position.x, p_pos.z - global_position.z).length()
			var in_height = (p_pos.y >= global_position.y - 45.0 and p_pos.y <= global_position.y + 205.0)
			var should_be_in_range = (dist_xz <= interaction_radius and in_height)
			
			if should_be_in_range != is_in_range:
				is_in_range = should_be_in_range
				prompt_label.visible = is_in_range
				if is_in_range:
					prompt_label.global_position.y = p_pos.y + 2.2
					player_ref.set_meta("nearby_elevator", self)
					player_ref.set_meta("nearby_interactive", self)
				else:
					if player_ref.has_meta("nearby_elevator") and player_ref.get_meta("nearby_elevator") == self:
						player_ref.remove_meta("nearby_elevator")
					if player_ref.has_meta("nearby_interactive") and player_ref.get_meta("nearby_interactive") == self:
						player_ref.remove_meta("nearby_interactive")
```

```gdscript
# ✅ AFTER (Dòng 288 - 345 trong scripts/elevator/elevator.gd - Chọn thang máy gần nhất theo khoảng cách XZ & bắt phím Esc):
		if player_ref and is_instance_valid(player_ref):
			var p_pos = player_ref.global_position
			var dist_xz = Vector2(p_pos.x - global_position.x, p_pos.z - global_position.z).length()
			var in_height = (p_pos.y >= global_position.y - 45.0 and p_pos.y <= global_position.y + 205.0)
			var should_be_in_range = (dist_xz <= interaction_radius and in_height)
			
			is_in_range = should_be_in_range
			prompt_label.visible = is_in_range
			if is_in_range:
				prompt_label.global_position.y = p_pos.y + 2.2
				var cur_elev = player_ref.get_meta("nearby_elevator") if player_ref.has_meta("nearby_elevator") else null
				if not is_instance_valid(cur_elev) or cur_elev == self or dist_xz < Vector2(p_pos.x - cur_elev.global_position.x, p_pos.z - cur_elev.global_position.z).length():
					player_ref.set_meta("nearby_elevator", self)
					player_ref.set_meta("nearby_interactive", self)
			else:
				if player_ref.has_meta("nearby_elevator") and player_ref.get_meta("nearby_elevator") == self:
					player_ref.remove_meta("nearby_elevator")
				if player_ref.has_meta("nearby_interactive") and player_ref.get_meta("nearby_interactive") == self:
					player_ref.remove_meta("nearby_interactive")

func _unhandled_input(event: InputEvent) -> void:
	if ui_modal and ui_modal.visible and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.physical_keycode == KEY_ESCAPE:
			_close_ui()
			get_viewport().set_input_as_handled()
```

---

#### 18. File `scripts/Interactive/housing_plot.gd` ([Xem trên Drive](https://drive.google.com/file/d/1VfMjWUO03iFQ6q2CsOqb3JeTjsBh9j7R/view)) & `scripts/Interactive/world_item_drop.gd` ([Xem trên Drive](https://drive.google.com/file/d/1kqg4kbnDbRZEoflu7WjXMBavurA8w7-r/view))

##### A. Nguyên nhân lỗi:
1. **`housing_plot.gd` (Dòng 214–224 — Xử lý trùng lặp phím `[E]` gây Mua Đất + Mở Cửa cùng lúc trong 1 lần bấm)**:
   - Khi người chơi đứng gần Lô Đất (`is_player_nearby == true`), dòng 187 đã gán `player.set_meta("nearby_interactive", self)`.
   - Khi người chơi bấm `[E]`, `PlayerController._unhandled_input()` (dòng 562) gọi `nearby_st.interact(self)` (Lần 1: Mua đất và chuyển `current_status = PlotStatus.COMPLETED`).
   - Nhưng nếu `HousingPlot._unhandled_input()` (dòng 214–223) chạy trước hoặc chạy cho nhiều lô đất cùng lúc, nó cũng tự bắt phím `KEY_E` / `KEY_F` và gọi `interact(player)` mà không kiểm tra xem `self` có phải là `player.get_meta("nearby_interactive")` hay không! Hơn nữa ở dòng 187 và 205, `player.set_meta("nearby_interactive", self)` ghi đè thẳng mà không so sánh khoảng cách với trạm đang ở gần hơn (khác với `_consider_nearest_interaction` chuẩn ở `wardrobe_outfit_changer.gd` dòng 143).
2. **`world_item_drop.gd` (Dòng 166 — Lỗi độ ưu tiên toán tử `and` / `or` cực kỳ nguy hiểm)**:
   - Dòng 166 viết:
     `if is_player_nearby and event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_E or event.physical_keycode == KEY_E)):`
   - Trong GDScript, toán tử `and` có độ ưu tiên **cao hơn** `or`! Do đó biểu thức trên được hiểu là:
     `if (is_player_nearby and event.is_action_pressed("interact")) OR (event is InputEventKey and ... KEY_E):`
   - **Hậu quả**: Khi người chơi đứng ở **bất kỳ đâu trên bản đồ 500 km²** (dù `is_player_nearby == false`, cách vật phẩm hàng chục km) và bấm phím `[E]` (ví dụ để nói chuyện với NPC hoặc mở cửa), vế thứ hai sau `or` đều đúng (`true`)! Toàn bộ các vật phẩm `WorldItemDrop` trên khắp thế giới đồng loạt tự bay vào túi đồ từ xa và biến mất (`queue_free()`) ngay lập tức!

##### B. Code Before / After:

```gdscript
# ❌ BEFORE (Dòng 165 - 169 trong scripts/Interactive/world_item_drop.gd):
func _unhandled_input(event: InputEvent) -> void:
	if is_player_nearby and event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_E or event.physical_keycode == KEY_E)):
		pickup_item()
		get_viewport().set_input_as_handled()

# ✅ AFTER (Dòng 165 - 171 trong scripts/Interactive/world_item_drop.gd - Bọc ngoặc đơn điều kiện phím E sau `and`):
func _unhandled_input(event: InputEvent) -> void:
	if not is_player_nearby:
		return
	var is_e_key: bool = event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_E or event.physical_keycode == KEY_E)
	if event.is_action_pressed("interact") or is_e_key:
		pickup_item()
		get_viewport().set_input_as_handled()
```

```gdscript
# ❌ BEFORE (Dòng 214 - 224 trong scripts/Interactive/housing_plot.gd):
func _unhandled_input(event: InputEvent) -> void:
	if not is_player_nearby:
		return
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		var key = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		if key == KEY_E or key == KEY_F:
			var player = get_tree().get_first_node_in_group("player")
			if player:
				interact(player)
				get_viewport().set_input_as_handled()

# ✅ AFTER (Dòng 214 - 225 trong scripts/Interactive/housing_plot.gd - Chỉ xử lý khi đúng là nearby_interactive của Player):
func _unhandled_input(event: InputEvent) -> void:
	if not is_player_nearby:
		return
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		var key = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		if key == KEY_E or key == KEY_F:
			var player = get_tree().get_first_node_in_group("player")
			if player and (not player.has_meta("nearby_interactive") or player.get_meta("nearby_interactive") == self):
				interact(player)
				get_viewport().set_input_as_handled()
```

---

#### 19. File `scripts/ui/citizen_id_modal.gd` ([Xem trên Drive](https://drive.google.com/file/d/1MA3Mkdf0MLxaIUF1YrAkMDRk2JKry9Kg/view)) & `scripts/Interactive/hr_management_board.gd` ([Xem trên Drive](https://drive.google.com/file/d/1mEeL3PiJB_ByhqMBM2Jb3gvHNqxlbPsY/view))

##### A. Nguyên nhân lỗi:
1. **`citizen_id_modal.gd` (Dòng 62–63 & 83–87 — Thiếu cập nhật `skill_label` khi mở thẻ CCCD và không lưu thay đổi vào `CitizenData` / SQLite)**:
   - Trong `display_citizen(npc)` (dòng 58–66), code gán `name_label`, `cccd_label`, `age_label`, `job_label`, `cert_label`, `status_label` nhưng **quên không gán `skill_label.text = "Cấp độ tay nghề: Cấp %d / 10" % npc.skill_level`**! Do đó khi mở thẻ CCCD của bất kỳ NPC nào, dòng Cấp độ tay nghề đều giữ nguyên text cũ của NPC xem trước đó!
   - Ở dòng 83–87 (`_on_scholarship_pressed`), bấm cấp học bổng chỉ tăng `current_npc.skill_level` trên node 3D mà không trừ tiền học bổng hay đồng bộ về `CitizenManager` / `DatabaseManager`.
2. **`hr_management_board.gd` (Dòng 8–42 — Thiếu chuẩn Dual-Layer Safety Rule #7, thiếu `Label3D` Diegetic Rule #8 và thiếu hỗ trợ phím vật lý Rule #1)**:
   - Dòng 8 vẫn ghi `"8 Bộ Ban"` thay vì `"9 Bộ Ban"`.
   - Dòng 23 chỉ kiểm tra `event.is_action_pressed("interact")` mà không kiểm tra `event.keycode == KEY_E or event.physical_keycode == KEY_E`.
   - Không đăng ký vào group `"interactive_stations"` và không có `interact(player)` để `PlayerController` gọi.

##### B. Code Before / After (`citizen_id_modal.gd`):

```gdscript
# ❌ BEFORE (Dòng 58 - 66 trong scripts/ui/citizen_id_modal.gd):
	name_label.text = npc.citizen_name
	cccd_label.text = npc.cccd_number
	age_label.text = "%s (%s)" % [age_str, npc.gender]
	job_label.text = npc.job_title
	cert_label.text = "Chứng chỉ số: %s" % npc.cert_code
	var act_info = ""

# ✅ AFTER (Dòng 58 - 68 trong scripts/ui/citizen_id_modal.gd - Bổ sung hiển thị skill_label):
	name_label.text = npc.citizen_name
	cccd_label.text = npc.cccd_number
	age_label.text = "%s (%s)" % [age_str, npc.gender]
	job_label.text = npc.job_title
	cert_label.text = "Chứng chỉ số: %s" % npc.cert_code
	if skill_label:
		skill_label.text = "Cấp độ tay nghề: Cấp %d / 10" % npc.skill_level
	var act_info = ""
```

---

### PHẦN F — CƠ SỞ DỮ LIỆU SQLITE, DÒNG THỜI GIAN, LOGISTICS & ĐỒ HỌA 3D

---

#### 20. File `scripts/simulation/database_manager.gd` ([Xem trên Drive](https://drive.google.com/file/d/1taXcdoaYDDJLPnkqbQngo58hlk-GgEbY/view)) & `addons/unified_timeline/unified_timeline_server.gd` ([Xem trên Drive](https://drive.google.com/file/d/1t85ByQl6fZeNJPPKtzTQwsR_fqossk-X/view))

##### A. Nguyên nhân lỗi:
1. **Thiếu bật chế độ `PRAGMA journal_mode=WAL;` và `PRAGMA synchronous=NORMAL;` trong `database_manager.gd` (Dòng 29–35)**:
   - Tài liệu thiết kế và comment đầu file yêu cầu SQLite chạy ở chế độ WAL (Write-Ahead Logging) để không khóa luồng render khi `UnifiedTimelineServer` tự động lưu mỗi 15 giây (`AUTO_SAVE_INTERVAL = 15.0` ở dòng 28 của `unified_timeline_server.gd`) hoặc khi `sync_citizens_batch` ghi 300 cư dân. Hiện tại `_init_database()` chưa gọi `db.query("PRAGMA journal_mode=WAL;")`.
2. **Lỗi SQL Injection / Lỗi cú pháp dấu nháy đơn trong `save_housing_plot` và `update_plot_status` (`database_manager.gd` dòng 373, 375, 398, 400)**:
   - Trong `save_housing_plot()` (dòng 373), `plot.get("title", "")` và `plot.get("owner_id", "")` được nội suy trực tiếp vào chuỗi SQL `'%s'` mà **không `.replace("'", "''")`** (khác với dòng 266 ở `sync_citizens_batch`). Nếu tên lô đất hoặc tên chủ nhà có dấu nháy đơn (ví dụ `"Mayor's Villa"`), câu lệnh SQL sẽ bị lỗi cú pháp ngay lập tức!
3. **Xung đột thứ tự khởi tạo giữa `UnifiedTimelineServer._setup_timeline()` và `SaveManager.load_game()` (`unified_timeline_server.gd` dòng 36 vs `main_world.gd` dòng 16)**:
   - Cả hai đều gọi `call_deferred(...)` trong `_ready()`. Vì `UnifiedTimelineServer` là Autoload nên `_setup_timeline()` chạy trước, cộng tiền thuế Offline vào `WorldManager.treasury_city` (dòng 193 của `unified_timeline_server.gd`).
   - Ngay sau đó, `MainWorld._load_saved_game()` chạy `SaveManager.load_game()`, trong đó `_merge_offline_progress()` (dòng 182–187 của `save_manager.gd`) tính phần chênh lệch dựa trên `current_world_state["treasury_city"] - INITIAL_CITY_TREASURY (50000.0)`.
   - **Lỗ hổng logic**: Nếu trước khi thoát game, người chơi đã tiêu bớt tiền khiến `treasury_city` còn `40,000 Đ`, hoặc kiếm được `70,000 Đ`, thì lúc `UnifiedTimelineServer._setup_timeline()` chạy (trước `SaveManager.load_game()`), `WorldManager.treasury_city` vẫn đang ở giá trị mặc định lúc khởi động là `50,000 Đ`! Do đó công thức `current_world_state["treasury_city"] - INITIAL_CITY_TREASURY` chỉ đúng tình cờ vì `WorldManager` khởi tạo ở `50,000 Đ`, nhưng đối với **tiến trình Logistics (`LogisticsManager.advance_game_minutes`) và Độ bền/Lương Cư dân (`CitizenManager.tick_macro_simulation`)**, `_apply_offline_catchup` trong `unified_timeline_server.gd` (dòng 157–215) **hoàn toàn quên không gọi `LogisticsManager.advance_game_minutes(added_minutes)` và `CitizenManager.tick_macro_simulation(effective_days)`**!

##### B. Code Before / After:

```gdscript
# ❌ BEFORE (Dòng 28 - 32 trong scripts/simulation/database_manager.gd):
	is_db_open = true
	print("[DatabaseManager] 🗄️ Mở thành công cơ sở dữ liệu SQLite tại: %s" % DB_PATH)
	_create_schema()

# ✅ AFTER (Dòng 28 - 35 trong scripts/simulation/database_manager.gd - Bật WAL Mode & Foreign Keys):
	is_db_open = true
	db.query("PRAGMA journal_mode=WAL;")
	db.query("PRAGMA synchronous=NORMAL;")
	db.query("PRAGMA foreign_keys=ON;")
	print("[DatabaseManager] 🗄️ Mở thành công cơ sở dữ liệu SQLite (WAL Mode) tại: %s" % DB_PATH)
	_create_schema()
```

```gdscript
# ✅ THÊM ĐỒNG BỘ LOGISTICS & CITIZEN TRONG OFFLINE CATCH-UP (Dòng 202 - 215 trong unified_timeline_server.gd):
	# Đồng bộ tiến trình Nghiên cứu & Phát triển HAS (Offline R&D Progress Catch-Up)
	var research_kbu_yield: int = 0
	var research_mgr = get_node_or_null("/root/ResearchManager")
	if research_mgr != null and research_mgr.has_method("apply_offline_research_progress"):
		research_mgr.apply_offline_research_progress(added_minutes)
		research_kbu_yield = added_minutes * 10

	# Đồng bộ tiến trình Đội xe Logistics ngoại tuyến
	var logistics_mgr = get_node_or_null("/root/LogisticsManager")
	if logistics_mgr != null and logistics_mgr.has_method("advance_game_minutes"):
		logistics_mgr.advance_game_minutes(float(added_minutes))

	# Đồng bộ vĩ mô Cư dân (Lương, Thuế, Dâng hiến & Độ bền vật dụng) khi qua ngày mới
	if days_passed > 0 and is_inside_tree():
		var cm = get_tree().get_first_node_in_group("citizen_manager")
		if cm != null and cm.has_method("tick_macro_simulation"):
			cm.tick_macro_simulation(float(days_passed))
```

---

#### 21. File `scripts/simulation/logistics_manager.gd` ([Xem trên Drive](https://drive.google.com/file/d/1FEou36_4S4EcW810TgFtWnG_F_Dhwc73/view))

##### A. Nguyên nhân lỗi:
1. **Dòng 394 (`apply_saved_state` không cập nhật lại vị trí trực quan 3D của đội xe tải `truck_visuals` sau khi Load Game)**:
   - Khi game khởi chạy, `NaturalLandscapeAssembler._spawn_resident_npcs()` gọi `logistics_manager.attach_visuals(self)` (dòng 423), đặt các xe tải 3D ở vị trí khởi tạo ban đầu.
   - Sau đó `SaveManager.load_game()` chạy `logistics_manager.apply_saved_state(logistics_state)` (dòng 382–394). Hàm này nạp lại `trucks` và `shipments` từ file save, nhưng **không gọi `_begin_visual_shipment()` hay `set_idle_location()` cho `truck_visuals`**! Kết quả là các mô hình xe tải 3D đứng sai vị trí hoặc hiển thị trạng thái cũ trước khi load save!
2. **Dòng 431 (Chưa áp dụng Buff tốc độ luân chuyển SCM `+21%` từ Nhánh 4 `robotics` của `ResearchManager`)**:
   - `ResearchManager` có hàm `get_scram_logistics_boost()` (dòng 454) trả về mức tăng tốc độ chuỗi cung ứng (tối đa `+21%`), nhưng dòng 431 của `logistics_manager.gd` tính `travel_game_minutes` và thời gian bốc dỡ `20.0` phút mà chưa giảm theo hệ số SCM buff này.

##### B. Code Before / After:

```gdscript
# ❌ BEFORE (Dòng 382 - 395 trong scripts/simulation/logistics_manager.gd):
func apply_saved_state(state: Dictionary) -> bool:
	if not validate_saved_state(state):
		return false
	for location_id in locations:
		locations[location_id]["inventory"] = state["location_inventories"][location_id].duplicate(true)
	for truck_id in trucks:
		var truck_state: Dictionary = state["truck_states"][truck_id]
		trucks[truck_id]["status"] = truck_state["status"]
		trucks[truck_id]["current_location_id"] = truck_state["current_location_id"]
		trucks[truck_id]["shipment_id"] = truck_state["shipment_id"]
	shipments = state["shipments"].duplicate(true)
	next_shipment_number = int(state["next_shipment_number"])
	return true

# ✅ AFTER (Dòng 382 - 404 trong scripts/simulation/logistics_manager.gd - Đồng bộ lại vị trí 3D của đội xe sau khi Load):
func apply_saved_state(state: Dictionary) -> bool:
	if not validate_saved_state(state):
		return false
	for location_id in locations:
		locations[location_id]["inventory"] = state["location_inventories"][location_id].duplicate(true)
	shipments = state["shipments"].duplicate(true)
	next_shipment_number = int(state["next_shipment_number"])
	for truck_id in trucks:
		var truck_state: Dictionary = state["truck_states"][truck_id]
		trucks[truck_id]["status"] = truck_state["status"]
		trucks[truck_id]["current_location_id"] = truck_state["current_location_id"]
		trucks[truck_id]["shipment_id"] = truck_state["shipment_id"]
		var tv: Node3D = truck_visuals.get(truck_id) as Node3D
		if tv != null and is_instance_valid(tv):
			if truck_state["status"] == "in_transit":
				_begin_visual_shipment(str(truck_state["shipment_id"]))
			else:
				var loc_km: Vector2 = locations[truck_state["current_location_id"]]["position_km"]
				tv.call("set_idle_location", loc_km * 1000.0)
	return true
```

---

#### 22. File `scripts/ui/cinematic_camera_controller.gd` ([Xem trên Drive](https://drive.google.com/file/d/1bAJLq7NkhRFnPBABLxSaT_KLShwtkm2M/view)), `scripts/characters/vrm_character_manager.gd` ([Xem trên Drive](https://drive.google.com/file/d/1I8slrYMFcTu4llWk6A0XzsXw39v-Rwab/view)) & `scripts/terrain/octahedral_pine_lod.gd` ([Xem trên Drive](https://drive.google.com/file/d/1UuQZwfCdu2XYwb6n4lMTR9ZYUNQTILVp/view))

##### A. Nguyên nhân lỗi:
1. **`cinematic_camera_controller.gd` (Dòng 110, 121 — Nguy cơ lỗi Engine `look_at()` khi vector hướng trùng với `Vector3.UP`)**:
   - Dòng 110 và 121 gọi `pcam_player.look_at(target, Vector3.UP)`. Nếu `pcam_player.global_position` vô tình trùng với điểm đích hoặc nằm thẳng đứng ngay phía trên điểm đích, Godot 4 sẽ văng cảnh báo đỏ `Up vector and direction between node origin and target are aligned, look_at() failed`. Cần kiểm tra `global_position.distance_squared_to(look_target) > 0.01` trước khi gọi `look_at()`.
2. **`octahedral_pine_lod.gd` (Dòng 38–39 — Ghi file vào `res://assets/impostors/` khi chạy bản Build Export)**:
   - Trong bản xuất (Exported Build), thư mục `res://` là gói PCK chỉ đọc (Read-only). Nếu file `res://assets/impostors/pine_tree_octa_atlas.res` chưa được bake sẵn, dòng 38–39 gọi `DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/impostors"))` và `ResourceSaver.save(..., "res://...")` sẽ báo lỗi quyền ghi file!
   - **Cách sửa**: Chỉ lưu vào `res://` khi `OS.has_feature("editor")`, còn khi chạy runtime nếu cần cache đĩa thì lưu vào `user://pine_tree_octa_atlas.res`.
3. **`vrm_character_manager.gd` (Dòng 67–68 & Spring Bone Physics khi FPS biến thiên)**:
   - Nội suy lắc tóc `hair_sway_offset` cần giới hạn `clampf(delta, 0.001, 0.05)` để khi máy bị khựng frame (delta lớn), vận tốc `velocity = (cur_pos - prev_world_pos) / delta` không bị vọt lên cực đại làm biến dạng mesh tóc và tà áo măng tô.