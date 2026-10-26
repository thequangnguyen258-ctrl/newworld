extends SceneTree

# ==============================================================================
# TEST SUITE: MINI-MAP RADAR 360°, 8-SLOT HOTBAR & 3D HELD PROPS
# Kiểm thử toàn diện:
# 1. MiniMapRadar 360° xoay la bàn B-Đ-N-T, chuyển tầm quét 1.5km ⇄ 25km.
# 2. 8-Slot Hotbar trên HUD với icon, số lượng và viền chọn vàng rực rỡ.
# 3. PlayerController Held Prop Mount & Vật phẩm 3D (Đèn lồng thắp sáng, Tablet, v.v.).
# 4. Kích hoạt vật phẩm: Bánh mì hồi máu, Đèn lồng bật/tắt ánh sáng ban đêm.
# 5. WorldItemDrop rơi thực địa, bồng bềnh 3D, nhắc lệnh diegetic [E] và nhặt đồ.
# ==============================================================================

const MiniMapRadarScript = preload("res://scripts/ui/mini_map_radar.gd")
const HUDOverlayScript = preload("res://scripts/ui/hud_overlay.gd")
const PlayerControllerScript = preload("res://scripts/core/player_controller.gd")
const InventoryManagerScript = preload("res://scripts/economy/inventory_manager.gd")
const WorldItemDropScript = preload("res://scripts/interactive/world_item_drop.gd")

func _init() -> void:
	print("==================================================================")
	print("🧪 BẮT ĐẦU TEST: MINI-MAP RADAR, 8-SLOT HOTBAR & HELD PROPS")
	print("==================================================================")

	var root_node = Node3D.new()
	root.add_child(root_node)

	# --------------------------------------------------------------------------
	# 1. KIỂM THỬ TÚI ĐỒ VÀ CÁC ITEM MỚI (LANTERN, TABLET)
	# --------------------------------------------------------------------------
	print("\n--- 1. KIỂM THỬ ĐỊNH NGHĨA VẬT PHẨM MỚI ---")
	assert(InventoryManagerScript.ITEM_DEFINITIONS.has("item_lantern"), "Phải có định nghĩa item_lantern")
	assert(InventoryManagerScript.ITEM_DEFINITIONS.has("item_tablet"), "Phải có định nghĩa item_tablet")
	assert(InventoryManagerScript.ITEM_DEFINITIONS.has("item_baguette"), "Phải có định nghĩa item_baguette")

	InventoryManagerScript.add_item("item_lantern", 1)
	InventoryManagerScript.add_item("item_tablet", 1)
	InventoryManagerScript.add_item("item_baguette", 2)
	assert(InventoryManagerScript.get_item_count("item_lantern") >= 1, "Túi đồ phải có ít nhất 1 đèn lồng")
	print(" [PASS] Khởi tạo và truy vấn vật phẩm thành công.")

	# --------------------------------------------------------------------------
	# 2. KIỂM THỬ MINI-MAP RADAR 360°
	# --------------------------------------------------------------------------
	print("\n--- 2. KIỂM THỬ MINI-MAP RADAR 360° ---")
	var radar = MiniMapRadarScript.new()
	root_node.add_child(radar)
	if not radar.is_node_ready():
		radar._ready()

	assert(radar.local_range == 1500.0, "Tầm quét cục bộ phải là 1500m (1.5km)")
	assert(radar.macro_range == 25000.0, "Tầm quét vĩ mô phải là 25000m (25km)")
	assert(not radar.is_macro_mode, "Mặc định phải ở chế độ cục bộ (Local)")

	# Chuyển đổi tầm quét
	radar.toggle_range_mode()
	assert(radar.is_macro_mode, "Sau khi toggle phải chuyển sang chế độ Macro 25km")
	radar.toggle_range_mode()
	assert(not radar.is_macro_mode, "Toggle lần 2 phải quay về Local 1.5km")

	# Kiểm tra 5 Huyện trên Radar
	assert(radar.district_markers.size() == 5, "Radar phải theo dõi đủ 5 huyện đô thị")
	print(" [PASS] MiniMapRadar khởi tạo, chuyển đổi tầm quét và nạp 5 huyện thành công.")

	# --------------------------------------------------------------------------
	# 3. KIỂM THỬ GIAO DIỆN HUD 8-SLOT HOTBAR
	# --------------------------------------------------------------------------
	print("\n--- 3. KIỂM THỬ HUD 8-SLOT HOTBAR ---")
	var hud_scene = load("res://scenes/ui/hud_overlay.tscn")
	var hud: CanvasLayer = hud_scene.instantiate()
	root_node.add_child(hud)
	if not hud.is_node_ready():
		hud._ready()

	assert(hud.has_node("HotbarPanel"), "HUD phải có HotbarPanel")
	assert(hud.get("hotbar_slot_buttons") != null, "HUD phải có danh sách nút hotbar")
	var buttons = hud.get("hotbar_slot_buttons") as Array
	assert(buttons.size() == 8, "Hotbar phải có chính xác 8 ô vật phẩm phím [1]-[8]")

	# Kiểm tra MiniMapRadar đã được nhúng vào HUD
	assert(hud.has_node("MiniMapRadar"), "HUD phải chứa MiniMapRadar nhúng sẵn")

	# Kiểm tra chuyển slot highlight trên HUD
	hud.call("set_selected_hotbar_slot", 2) # Chọn slot 3 (Đèn lồng)
	assert(hud.get("hotbar_selected_index") == 2, "Hotbar index phải là 2")
	print(" [PASS] HUD 8-Slot Hotbar & MiniMapRadar nhúng hoàn chỉnh.")

	# --------------------------------------------------------------------------
	# 4. KIỂM THỬ PLAYER CONTROLLER & 3D HELD PROPS
	# --------------------------------------------------------------------------
	print("\n--- 4. KIỂM THỬ PLAYER CONTROLLER & 3D HELD PROPS ---")
	var player = PlayerControllerScript.new()
	player.position = Vector3(0, 10, 0)
	root_node.add_child(player)
	if not player.is_node_ready():
		player._ready()

	assert(player.held_prop_mount != null, "Player phải có giá đỡ HeldPropMount")
	assert(player.has_method("select_hotbar_slot"), "Player phải có hàm select_hotbar_slot")

	# Trang bị slot 0: Bánh mì Baguette
	player.select_hotbar_slot(0)
	assert(player.selected_hotbar_index == 0, "Slot được chọn phải là 0")
	assert(player.current_held_item_id == "item_baguette", "Vật phẩm cầm tay phải là item_baguette")
	assert(player.held_prop_mount.get_child_count() > 0, "Giá đỡ phải có mô hình 3D bánh mì")

	# Trang bị slot 2: Đèn lồng đồng quê (Lantern)
	player.select_hotbar_slot(2)
	assert(player.selected_hotbar_index == 2, "Slot được chọn phải là 2 (Đèn lồng)")
	assert(player.current_held_item_id == "item_lantern", "Vật phẩm cầm tay phải là item_lantern")
	assert(player.equipped_lantern_light != null, "Đèn lồng phải có nguồn sáng OmniLight3D thực tế")
	assert(player.equipped_lantern_light.visible, "Đèn lồng ban đầu phải sáng")

	# Bấm lần 2 vào slot 2 -> Bật/Tắt ánh sáng đèn lồng
	player.select_hotbar_slot(2)
	assert(not player.lantern_is_lit, "Bấm lần 2 phải tắt đèn lồng")
	assert(not player.equipped_lantern_light.visible, "OmniLight3D phải tắt khi đèn lồng tắt")
	player.select_hotbar_slot(2)
	assert(player.lantern_is_lit, "Bấm lần 3 phải bật lại đèn lồng")
	assert(player.equipped_lantern_light.visible, "OmniLight3D phải bật lại")

	# Trang bị slot 7: Civic OS Tablet
	player.select_hotbar_slot(7)
	assert(player.current_held_item_id == "item_tablet", "Vật phẩm cầm tay phải là item_tablet")
	assert(player.held_prop_mount.get_child_count() >= 2, "Mô hình Tablet phải gồm thân máy và màn hình Hologram")

	# Thử sử dụng/tiêu thụ bánh mì (Hồi máu)
	player.current_health = 40.0
	player.current_stamina = 20.0
	player.sprint_exhausted = true
	player.select_hotbar_slot(0) # Trang bị lại bánh mì
	var prev_bread = InventoryManagerScript.get_item_count("item_baguette")
	player.select_hotbar_slot(0) # Bấm lần 2 để ăn bánh mì
	assert(player.current_health == 90.0, "Ăn bánh mì phải hồi +50 HP (40 -> 90)")
	assert(player.current_stamina == 70.0, "Ăn bánh mì phải hồi +50 thể lực (20 -> 70)")
	assert(not player.sprint_exhausted, "Bánh mì hồi đủ ngưỡng phải cho phép chạy lại.")
	assert(InventoryManagerScript.get_item_count("item_baguette") == prev_bread - 1, "Số lượng bánh mì phải trừ 1")

	# Trà thảo mộc phục hồi toàn bộ HP, thể lực và áp dụng buff chạy.
	player.current_health = 35.0
	player.current_stamina = 10.0
	player.select_hotbar_slot(1)
	player.select_hotbar_slot(1)
	assert(player.current_health == player.max_health, "Trà phải hồi đầy HP.")
	assert(player.current_stamina == player.max_stamina, "Trà phải hồi đầy thể lực.")
	assert(player.speed_multiplier == 1.4, "Trà phải tăng tốc chạy 40%.")
	print(" [PASS] Held Props, đèn lồng, bánh mì hồi phục và trà hồi đầy thể lực thành công.")

	# --------------------------------------------------------------------------
	# 5. KIỂM THỬ WORLD ITEM DROP (VẬT PHẨM RƠI THỰC ĐỊA 3D)
	# --------------------------------------------------------------------------
	print("\n--- 5. KIỂM THỬ WORLD ITEM DROP ---")
	var drop = WorldItemDropScript.new()
	drop.item_id = "item_herbal_tea"
	drop.item_quantity = 2
	drop.position = Vector3(2.0, 10.0, 0.0)
	root_node.add_child(drop)
	if not drop.is_node_ready():
		drop._ready()

	assert(drop.prompt_label != null, "Vật phẩm rơi phải có Label3D nhắc lệnh")
	assert(drop.prompt_label.no_depth_test, "Label3D phải bật no_depth_test để chống khuất")
	assert(drop.prompt_label.billboard == BaseMaterial3D.BILLBOARD_ENABLED, "Label3D phải bật Billboard")

	# Kiểm tra hiệu ứng bồng bềnh và xoay
	var old_y = drop.mesh_container.position.y
	drop._process(0.2)
	assert(drop.mesh_container.position.y != old_y or drop.anim_time > 0.0, "Vật phẩm rơi phải bồng bềnh và đếm anim_time")

	# Kiểm tra cơ chế nhặt đồ (Dual-Layer Pickup)
	var initial_tea = InventoryManagerScript.get_item_count("item_herbal_tea")
	drop.pickup_item()
	assert(InventoryManagerScript.get_item_count("item_herbal_tea") == initial_tea + 2, "Nhặt đồ phải cộng 2 trà thảo mộc vào túi")
	print(" [PASS] WorldItemDrop bồng bềnh 3D, diegetic label và nhặt đồ thành công.")

	print("\n==================================================================")
	print("🎉 TẤT CẢ CÁC BÀI TEST RADAR, HOTBAR & HELD PROPS ĐÃ THÀNH CÔNG RỰC RỠ!")
	print("==================================================================")
	quit(0)
