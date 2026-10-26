class_name InventoryManager
extends RefCounted

# ==============================================================================
# INVENTORY MANAGER - QUẢN LÝ TÚI ĐỒ & VẬT PHẨM THỊ TRƯỞNG TÂN THẾ GIỚI
# Quản lý các vật phẩm tiêu dùng, công văn, chìa khóa và hàng hóa giao thương:
# 1. Bánh mì Baguette (Hồi phục 50 Thể Lực)
# 2. Trà thảo mộc tuyết sơn (Hồi phục 100% Thể Lực & Tăng tốc độ chạy)
# 3. Đồng xu nguyện ước (Dùng cho Đài Phun Nước)
# 4. Sắc lệnh Thị Trưởng (Ký ban hành tại Bàn Sắc Lệnh)
# 5. Chìa khóa xe Buggy & Thẻ bay trực thăng
# 6. Bao lúa mì Huyện Đông & Thảo dược Onsen Huyện Bắc
# ==============================================================================

# Danh mục định nghĩa vật phẩm toàn cầu
const ITEM_DEFINITIONS = {
	"item_baguette": {
		"name": "Bánh Mì Baguette Nóng",
		"icon": "🥖",
		"desc": "Bánh mì lên men tự nhiên giòn rụm từ Tiệm Bác Nam. Hồi phục 50 Thể Lực.",
		"type": "consumable",
		"weight_kg": 0.3,
		"heal_amount": 50.0,
		"stamina_restore": 50.0,
		"stamina_restore_ratio": 0.0,
		"speed_buff": 1.0,
		"buff_duration": 0.0
	},
	"item_herbal_tea": {
		"name": "Trà Thảo Mộc Tuyết Sơn",
		"icon": "🌿",
		"desc": "Trà thảo dược dưỡng sinh từ Trạm Xá Chị Mai. Hồi phục 100% Thể Lực và tăng 40% tốc độ chạy trong 20s.",
		"type": "consumable",
		"weight_kg": 0.45,
		"heal_amount": 100.0,
		"stamina_restore": 0.0,
		"stamina_restore_ratio": 1.0,
		"speed_buff": 1.4,
		"buff_duration": 20.0
	},
	"item_wishing_coin": {
		"name": "Đồng Xu Nguyện Ước",
		"icon": "🪙",
		"desc": "Đồng xu vàng ròng mang phước lành, dùng để thả vào Đài Phun Nước Hòa Bình.",
		"type": "quest",
		"weight_kg": 0.02,
		"heal_amount": 0.0,
		"speed_buff": 1.0,
		"buff_duration": 0.0
	},
	"item_mayor_decree": {
		"name": "Sắc Lệnh An Sinh Đô Thị",
		"icon": "📋",
		"desc": "Văn kiện phê duyệt phát triển cơ sở hạ tầng và an sinh cho 5 huyện Tân Thế Giới.",
		"type": "document",
		"weight_kg": 0.1,
		"heal_amount": 0.0,
		"speed_buff": 1.0,
		"buff_duration": 0.0
	},
	"item_buggy_key": {
		"name": "Chìa Khóa Xe Buggy Điện",
		"icon": "🔑",
		"desc": "Chìa khóa điện tử khởi động xe Buggy tuần tra 60 km/h của Thị Trưởng.",
		"type": "key",
		"weight_kg": 0.05,
		"heal_amount": 0.0,
		"speed_buff": 1.0,
		"buff_duration": 0.0
	},
	"item_wheat_sack": {
		"name": "Bao Lúa Mì Hữu Cơ",
		"icon": "🌾",
		"desc": "Bao lúa mì vàng thu hoạch từ cánh đồng Cối Xay Gió Huyện Đông, tiếp tế cho tiệm bánh Bác Nam.",
		"type": "cargo",
		"weight_kg": 12.0,
		"heal_amount": 0.0,
		"speed_buff": 1.0,
		"buff_duration": 0.0
	},
	"item_onsen_herb": {
		"name": "Thảo Dược Suối Khoáng",
		"icon": "♨️",
		"desc": "Dược liệu quý hái từ bờ suối khoáng nóng Huyện Bắc, mang về cho Trạm Xá Chị Mai.",
		"type": "cargo",
		"weight_kg": 0.5,
		"heal_amount": 0.0,
		"speed_buff": 1.0,
		"buff_duration": 0.0
	},
	"item_solar_battery": {
		"name": "Khối Pin Năng Lượng Sạch",
		"icon": "⚡",
		"desc": "Khối pin tích điện sạch từ Thung Lũng Kỹ Nghệ Huyện Tây, cung cấp năng lượng cho hệ thống đô thị.",
		"type": "cargo",
		"weight_kg": 15.0,
		"heal_amount": 0.0,
		"speed_buff": 1.0,
		"buff_duration": 0.0
	},
	"item_fresh_fish": {
		"name": "Thùng Hải Sản Tươi Ngon",
		"icon": "🐟",
		"desc": "Thùng hải sản tươi ngon đánh bắt từ Cảng Hòa Bình Huyện Nam, chuẩn bị cho Bữa Tiệc Bác Ái Agape.",
		"type": "cargo",
		"weight_kg": 8.0,
		"heal_amount": 0.0,
		"speed_buff": 1.0,
		"buff_duration": 0.0
	},
	"item_special_bread": {
		"name": "Bánh Mì Hoa Cúc Mật Ong",
		"icon": "🥐",
		"desc": "Bánh mì cao cấp Bác Nam làm từ lúa mì Huyện Đông. Hồi 80 HP & tăng tốc chạy.",
		"type": "consumable",
		"weight_kg": 0.35,
		"heal_amount": 80.0,
		"speed_buff": 1.25,
		"buff_duration": 15.0
	},
	"item_royal_tea": {
		"name": "Trà Thảo Mộc Hoàng Gia",
		"icon": "🫖",
		"desc": "Trà dược liệu Onsen đặc chế từ Chị Mai. Hồi 100% HP & tăng 50% tốc độ trong 30s.",
		"type": "consumable",
		"weight_kg": 0.45,
		"heal_amount": 100.0,
		"speed_buff": 1.5,
		"buff_duration": 30.0
	},
	"item_lantern": {
		"name": "Đèn Lồng Đồng Quê",
		"icon": "🏮",
		"desc": "Đèn lồng thắp sáng cổ điển phát tỏa ánh sáng ấm áp trong đêm tối.",
		"type": "tool",
		"weight_kg": 1.2,
		"heal_amount": 0.0,
		"speed_buff": 1.0,
		"buff_duration": 0.0
	},
	"item_tablet": {
		"name": "Civic OS Tablet",
		"icon": "📱",
		"desc": "Máy tính bảng điều hành đô thị hiển thị bản đồ kinh tế vĩ mô và chỉ số 5 huyện.",
		"type": "tool",
		"weight_kg": 0.8,
		"heal_amount": 0.0,
		"speed_buff": 1.0,
		"buff_duration": 0.0
	}
}

const BRIEFCASE_CAPACITY_KG: float = 40.0
const OFFICE_STORAGE_CAPACITY_KG: float = 400.0

# Kho chứa đồ thực tế trong phiên chơi (Lưu trữ số lượng từng item)
static var inventory_slots: Dictionary = {
	"item_baguette": 3,
	"item_herbal_tea": 2,
	"item_lantern": 1,
	"item_mayor_decree": 1,
	"item_buggy_key": 1,
	"item_tablet": 1,
	"item_wishing_coin": 5
}

static var office_storage_slots: Dictionary = {}

static func get_all_items() -> Dictionary:
	return inventory_slots.duplicate(true)

static func get_office_storage_items() -> Dictionary:
	return office_storage_slots.duplicate(true)

static func get_item_count(item_id: String) -> int:
	return inventory_slots.get(item_id, 0)

static func get_storage_item_count(item_id: String) -> int:
	return office_storage_slots.get(item_id, 0)

static func get_inventory_weight_kg() -> float:
	return _get_storage_weight(inventory_slots)

static func get_office_storage_weight_kg() -> float:
	return _get_storage_weight(office_storage_slots)

static func can_add_item(item_id: String, qty: int = 1) -> bool:
	if not ITEM_DEFINITIONS.has(item_id) or qty <= 0:
		return false
	var additional_weight := float(ITEM_DEFINITIONS[item_id]["weight_kg"]) * qty
	return get_inventory_weight_kg() + additional_weight <= BRIEFCASE_CAPACITY_KG

static func add_item(item_id: String, qty: int = 1) -> bool:
	if not ITEM_DEFINITIONS.has(item_id) or qty <= 0:
		push_warning("[InventoryManager] Không thể nhận vật phẩm hoặc số lượng không hợp lệ: %s x%d." % [item_id, qty])
		return false
	if not can_add_item(item_id, qty):
		push_warning("[InventoryManager] Cặp đã quá tải; không thể nhận %s x%d." % [ITEM_DEFINITIONS[item_id]["name"], qty])
		return false
	var current = inventory_slots.get(item_id, 0)
	inventory_slots[item_id] = current + qty
	print("[InventoryManager] 🎒 Nhận vật phẩm: %s x%d (Hiện có: %d)" % [ITEM_DEFINITIONS[item_id]["name"], qty, inventory_slots[item_id]])
	return true

static func remove_item(item_id: String, qty: int = 1) -> bool:
	var current = inventory_slots.get(item_id, 0)
	if qty <= 0 or current < qty:
		return false
	var remaining = current - qty
	if remaining <= 0:
		inventory_slots.erase(item_id)
	else:
		inventory_slots[item_id] = remaining
	print("[InventoryManager] 🎒 Trừ vật phẩm: %s x%d (Còn lại: %d)" % [ITEM_DEFINITIONS[item_id]["name"], qty, remaining])
	return true

static func store_item(item_id: String, qty: int = 1) -> bool:
	if qty <= 0 or get_item_count(item_id) < qty or not ITEM_DEFINITIONS.has(item_id):
		return false
	var item_weight := float(ITEM_DEFINITIONS[item_id]["weight_kg"]) * qty
	if get_office_storage_weight_kg() + item_weight > OFFICE_STORAGE_CAPACITY_KG:
		return false
	_move_item_count(inventory_slots, office_storage_slots, item_id, qty)
	return true

static func take_from_office(item_id: String, qty: int = 1) -> bool:
	if qty <= 0 or get_storage_item_count(item_id) < qty or not ITEM_DEFINITIONS.has(item_id):
		return false
	var item_weight := float(ITEM_DEFINITIONS[item_id]["weight_kg"]) * qty
	if get_inventory_weight_kg() + item_weight > BRIEFCASE_CAPACITY_KG:
		return false
	_move_item_count(office_storage_slots, inventory_slots, item_id, qty)
	return true

static func exchange_items(remove_item_id: String, remove_qty: int, add_item_id: String, add_qty: int) -> bool:
	if (
		remove_qty <= 0
		or add_qty <= 0
		or not ITEM_DEFINITIONS.has(remove_item_id)
		or not ITEM_DEFINITIONS.has(add_item_id)
		or get_item_count(remove_item_id) < remove_qty
	):
		return false
	var resulting_weight := (
		get_inventory_weight_kg()
		- float(ITEM_DEFINITIONS[remove_item_id]["weight_kg"]) * remove_qty
		+ float(ITEM_DEFINITIONS[add_item_id]["weight_kg"]) * add_qty
	)
	if resulting_weight > BRIEFCASE_CAPACITY_KG:
		return false
	_remove_item_count(inventory_slots, remove_item_id, remove_qty)
	inventory_slots[add_item_id] = int(inventory_slots.get(add_item_id, 0)) + add_qty
	return true

static func get_save_state() -> Dictionary:
	return {
		"briefcase": inventory_slots.duplicate(true),
		"office_storage": office_storage_slots.duplicate(true)
	}

static func validate_saved_state(state: Dictionary) -> bool:
	if not state.get("briefcase") is Dictionary or not state.get("office_storage") is Dictionary:
		return false
	var briefcase: Dictionary = state["briefcase"]
	var office_storage: Dictionary = state["office_storage"]
	if not _validate_item_counts(briefcase) or not _validate_item_counts(office_storage):
		return false
	return (
		_get_storage_weight(briefcase) <= BRIEFCASE_CAPACITY_KG
		and _get_storage_weight(office_storage) <= OFFICE_STORAGE_CAPACITY_KG
	)

static func apply_saved_state(state: Dictionary) -> bool:
	if not validate_saved_state(state):
		return false
	inventory_slots.clear()
	for k in state["briefcase"]:
		inventory_slots[String(k)] = int(state["briefcase"][k])
	office_storage_slots.clear()
	for k in state["office_storage"]:
		office_storage_slots[String(k)] = int(state["office_storage"][k])
	return true

static func _validate_item_counts(items: Dictionary) -> bool:
	for item_id in items:
		var qty: Variant = items[item_id]
		if not ITEM_DEFINITIONS.has(item_id):
			return false
		if not (qty is int or qty is float):
			return false
		if is_nan(float(qty)) or is_inf(float(qty)) or int(qty) <= 0 or float(qty) != float(int(qty)):
			return false
	return true

static func _get_storage_weight(items: Dictionary) -> float:
	var weight := 0.0
	for item_id in items:
		var definition: Dictionary = ITEM_DEFINITIONS.get(item_id, {})
		if not definition.is_empty():
			weight += float(definition.get("weight_kg", 0.0)) * int(items[item_id])
	return weight

static func _move_item_count(from_storage: Dictionary, to_storage: Dictionary, item_id: String, qty: int) -> void:
	_remove_item_count(from_storage, item_id, qty)
	to_storage[item_id] = int(to_storage.get(item_id, 0)) + qty

static func _remove_item_count(storage: Dictionary, item_id: String, qty: int) -> void:
	var remaining := int(storage[item_id]) - qty
	if remaining == 0:
		storage.erase(item_id)
	else:
		storage[item_id] = remaining

static func use_item(item_id: String, player: Node3D) -> bool:
	if not inventory_slots.has(item_id) or inventory_slots[item_id] <= 0:
		return false

	var def = ITEM_DEFINITIONS.get(item_id, null)
	if def == null:
		return false

	if def["type"] == "consumable":
		# Hồi phục sinh lực
		if player and player.has_method("heal"):
			player.heal(def["heal_amount"])
		if player and player.has_method("restore_stamina"):
			player.restore_stamina(
				float(def.get("stamina_restore", 0.0)),
				float(def.get("stamina_restore_ratio", 0.0))
			)
		if player and player.has_method("apply_speed_buff") and def["speed_buff"] > 1.0:
			player.apply_speed_buff(def["speed_buff"], def["buff_duration"])

		remove_item(item_id, 1)
		print("[InventoryManager] ✨ Đã sử dụng: %s! Sinh lực hồi phục +%.0f HP" % [def["name"], def["heal_amount"]])
		return true

	return false
