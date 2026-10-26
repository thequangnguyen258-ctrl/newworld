extends Node

signal shipment_created(shipment_id: String)
signal shipment_dispatched(shipment_id: String, truck_id: String, driver_id: String)
signal shipment_delivered(shipment_id: String, destination_id: String)

const InventoryManagerScript = preload("res://scripts/economy/inventory_manager.gd")
const FreightTruckVisualScript = preload("res://scripts/vehicles/freight_truck_visual.gd")
const ModularNatureChunkScript = preload("res://scripts/terrain/modular_nature_chunk.gd")

const TRUCK_CLASS_ORDER: Array[String] = ["LIGHT", "MEDIUM", "CONTAINER", "HEAVY"]
const TRUCK_SPECS: Dictionary = {
	"LIGHT": {"name": "Xe tải nhẹ", "capacity_kg": 3500.0, "speed_kmh": 50.0, "driver_role": "Tài xế xe tải nhẹ"},
	"MEDIUM": {"name": "Xe tải trung", "capacity_kg": 10000.0, "speed_kmh": 45.0, "driver_role": "Tài xế xe tải trung"},
	"CONTAINER": {"name": "Xe đầu kéo container", "capacity_kg": 28000.0, "speed_kmh": 38.0, "driver_role": "Tài xế xe container"},
	"HEAVY": {"name": "Xe tải hạng nặng", "capacity_kg": 40000.0, "speed_kmh": 30.0, "driver_role": "Tài xế xe siêu trường"}
}

var companies: Dictionary = {}
var locations: Dictionary = {}
var trucks: Dictionary = {}
var shipments: Dictionary = {}
var next_shipment_number: int = 1
var truck_visuals: Dictionary = {}
var visual_container: Node3D
var visual_minute_fraction: float = 0.0

func _ready() -> void:
	var world_manager := get_node_or_null("/root/WorldManager")
	if world_manager != null and world_manager.has_signal("time_ticked"):
		world_manager.time_ticked.connect(_on_world_time_ticked)

func attach_visuals(world_parent: Node3D) -> void:
	if not is_instance_valid(world_parent):
		push_error("[LogisticsManager] Không thể tạo đội xe 3D khi thiếu node thế giới.")
		return
	if is_instance_valid(visual_container):
		return
	visual_container = Node3D.new()
	visual_container.name = "FreightFleet"
	world_parent.add_child(visual_container)
	_build_logistics_yard()
	var slot_index := 0
	for truck_id in trucks:
		var truck: Dictionary = trucks[truck_id]
		var truck_visual: Node3D = FreightTruckVisualScript.new()
		truck_visual.call("configure", {
			"truck_id": truck_id,
			"truck_class": truck["truck_class"],
			"display_name": TRUCK_SPECS[truck["truck_class"]]["name"]
		}, slot_index)
		visual_container.add_child(truck_visual)
		truck_visuals[truck_id] = truck_visual
		slot_index += 1
		if truck["status"] == "in_transit":
			_begin_visual_shipment(str(truck["shipment_id"]))

func _build_logistics_yard() -> void:
	var yard := MeshInstance3D.new()
	yard.name = "FreightDepotYard"
	var yard_mesh := BoxMesh.new()
	yard_mesh.size = Vector3(30.0, 0.2, 28.0)
	yard.mesh = yard_mesh
	var yard_material := StandardMaterial3D.new()
	yard_material.albedo_color = Color(0.24, 0.27, 0.29)
	yard_material.roughness = 0.9
	yard.material_override = yard_material
	yard.position = Vector3(
		150.0,
		ModularNatureChunkScript.get_world_height(150.0, 300.0) + 0.1,
		300.0
	)
	visual_container.add_child(yard)
	var sign := Label3D.new()
	sign.name = "FreightCompanySign"
	sign.text = "CÔNG TY VẬN TẢI TÂN THẾ GIỚI\nĐỘI XE HÀNG HÓA"
	sign.position = Vector3(150.0, yard.position.y + 6.0, 284.0)
	sign.font_size = 40
	sign.outline_size = 10
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.no_depth_test = true
	sign.modulate = Color(1.0, 0.84, 0.35)
	visual_container.add_child(sign)

func _process(delta: float) -> void:
	visual_minute_fraction = fmod(visual_minute_fraction + delta / 3.0, 1.0)
	if not is_instance_valid(visual_container):
		return
	for shipment_id in shipments:
		var shipment: Dictionary = shipments[shipment_id]
		if shipment["status"] != "in_transit":
			continue
		var truck_visual: Node3D = truck_visuals.get(shipment["truck_id"]) as Node3D
		if truck_visual == null:
			continue
		var travel_minutes := float(shipment["travel_game_minutes"])
		var elapsed_minutes := float(shipment["duration_game_minutes"]) - float(shipment["remaining_game_minutes"])
		var progress := clampf((elapsed_minutes + visual_minute_fraction - 10.0) / maxf(travel_minutes, 0.001), 0.0, 1.0)
		truck_visual.call("set_route_progress", progress)

func initialize_capital_industry(citizen_registry: Dictionary) -> void:
	if companies.has("COMPANY_CAPITAL_FREIGHT"):
		return

	register_location("EAST_FARM", "Nông trại Huyện Đông", Vector2(10.0, 0.0), {
		"item_wheat_sack": 20000
	})
	register_location("NORTH_HERB_GARDEN", "Vườn dược liệu Huyện Bắc", Vector2(0.0, -10.0), {
		"item_onsen_herb": 1000
	})
	register_location("WEST_ENERGY_DEPOT", "Kho năng lượng Huyện Tây", Vector2(-10.0, 0.0), {
		"item_solar_battery": 1000
	})
	register_location("SOUTH_HARBOR", "Kho cảng Huyện Nam", Vector2(0.0, 20.0), {
		"item_fresh_fish": 1000
	})
	register_location("CAPITAL_LOGISTICS_DEPOT", "Bãi xe Công ty Vận tải Thủ Phủ", Vector2(0.15, 0.3))
	register_location("CAPITAL_BAKERY", "Tiệm bánh Thủ Phủ", Vector2(0.0, 0.0))
	register_location("CAPITAL_CLINIC", "Trạm xá Thủ Phủ", Vector2(0.0, 0.0))
	register_location("CAPITAL_POWER_GRID", "Lưới điện Thủ Phủ", Vector2(0.0, 0.0))
	register_location("CAPITAL_AGAPE_HALL", "Đại sảnh sinh hoạt Thủ Phủ", Vector2(0.0, 0.0))

	var company := {
		"company_id": "COMPANY_CAPITAL_FREIGHT",
		"name": "Công ty Vận tải Tân Thế Giới",
		"ownership_type": "company",
		"manager_id": "",
		"dispatcher_id": "",
		"mechanic_id": "",
		"employee_ids": [],
		"truck_ids": []
	}
	for citizen_value in citizen_registry.values():
		var citizen := citizen_value as CitizenData
		if citizen.job_role == "Quản lý đội xe":
			company["manager_id"] = citizen.citizen_id
			company["employee_ids"].append(citizen.citizen_id)
		elif citizen.job_role == "Điều phối viên logistics":
			company["dispatcher_id"] = citizen.citizen_id
			company["employee_ids"].append(citizen.citizen_id)
		elif citizen.job_role == "Thợ máy xe tải":
			company["mechanic_id"] = citizen.citizen_id
			company["employee_ids"].append(citizen.citizen_id)

	companies[company["company_id"]] = company
	for truck_class in TRUCK_CLASS_ORDER:
		var driver_role: String = TRUCK_SPECS[truck_class]["driver_role"]
		var driver_id := ""
		for citizen_value in citizen_registry.values():
			var citizen := citizen_value as CitizenData
			if citizen.job_role == driver_role:
				driver_id = citizen.citizen_id
				company["employee_ids"].append(driver_id)
				break
		if driver_id.is_empty():
			push_error("[LogisticsManager] Không tìm thấy tài xế chuyên môn cho hạng xe %s." % truck_class)
			continue
		register_truck(
			company["company_id"],
			"CAPITAL_TRUCK_%s_01" % truck_class,
			truck_class,
			driver_id
		)
	var starter_shipment := request_shipment(
		"COMPANY_CAPITAL_FREIGHT",
		"EAST_FARM",
		"CAPITAL_BAKERY",
		"item_wheat_sack",
		100
	)
	if starter_shipment.is_empty():
		push_error("[LogisticsManager] Không thể khởi tạo chuyến tiếp tế lúa mì cho Tiệm bánh Thủ Phủ.")

func register_location(location_id: String, display_name: String, position_km: Vector2, initial_stock: Dictionary = {}) -> bool:
	if location_id.is_empty() or locations.has(location_id):
		push_warning("[LogisticsManager] Mã địa điểm trống hoặc đã được đăng ký: %s." % location_id)
		return false
	for item_id in initial_stock:
		if not InventoryManagerScript.ITEM_DEFINITIONS.has(item_id):
			push_error("[LogisticsManager] Không thể tạo tồn kho cho vật phẩm chưa định nghĩa: %s." % item_id)
			return false
		if int(initial_stock[item_id]) < 0:
			push_error("[LogisticsManager] Tồn kho ban đầu không thể âm tại %s." % location_id)
			return false
	locations[location_id] = {
		"name": display_name,
		"position_km": position_km,
		"inventory": initial_stock.duplicate(true)
	}
	return true

func register_truck(company_id: String, truck_id: String, truck_class: String, driver_id: String) -> bool:
	if not companies.has(company_id):
		push_warning("[LogisticsManager] Không thể đăng ký xe cho công ty chưa tồn tại: %s." % company_id)
		return false
	if trucks.has(truck_id) or not TRUCK_SPECS.has(truck_class):
		push_warning("[LogisticsManager] Mã xe đã tồn tại hoặc hạng xe không hợp lệ: %s." % truck_id)
		return false
	if driver_id.is_empty():
		push_warning("[LogisticsManager] Xe %s cần có tài xế được phân công." % truck_id)
		return false
	var spec: Dictionary = TRUCK_SPECS[truck_class]
	trucks[truck_id] = {
		"truck_id": truck_id,
		"company_id": company_id,
		"truck_class": truck_class,
		"capacity_kg": float(spec["capacity_kg"]),
		"speed_kmh": float(spec["speed_kmh"]),
		"driver_id": driver_id,
		"status": "idle",
		"current_location_id": "CAPITAL_LOGISTICS_DEPOT",
		"shipment_id": ""
	}
	companies[company_id]["truck_ids"].append(truck_id)
	return true

func request_shipment(
	company_id: String,
	origin_id: String,
	destination_id: String,
	item_id: String,
	quantity: int
) -> String:
	if not companies.has(company_id) or not locations.has(origin_id) or not locations.has(destination_id):
		push_warning("[LogisticsManager] Không thể tạo chuyến: thiếu công ty hoặc địa điểm hợp lệ.")
		return ""
	if origin_id == destination_id or quantity <= 0:
		push_warning("[LogisticsManager] Chuyến hàng cần điểm đi/đến khác nhau và số lượng dương.")
		return ""
	if not InventoryManagerScript.ITEM_DEFINITIONS.has(item_id):
		push_warning("[LogisticsManager] Vật phẩm chưa được định nghĩa: %s." % item_id)
		return ""
	var item_definition: Dictionary = InventoryManagerScript.ITEM_DEFINITIONS[item_id]
	if item_definition.get("type", "") != "cargo":
		push_warning("[LogisticsManager] Chỉ hàng hóa vận tải mới được tạo thành chuyến: %s." % item_id)
		return ""
	var available_quantity := int(locations[origin_id]["inventory"].get(item_id, 0))
	available_quantity -= _get_pending_reserved_quantity(origin_id, item_id)
	if available_quantity < quantity:
		push_warning("[LogisticsManager] Kho %s không đủ %s x%d." % [origin_id, item_id, quantity])
		return ""

	var cargo_weight := float(item_definition["weight_kg"]) * quantity
	if get_suitable_truck_class(cargo_weight).is_empty():
		push_warning("[LogisticsManager] Khối lượng %.1f kg vượt sức chở tối đa của đội xe." % cargo_weight)
		return ""
	var shipment_id := "SHIPMENT_%06d" % next_shipment_number
	next_shipment_number += 1
	shipments[shipment_id] = {
		"shipment_id": shipment_id,
		"company_id": company_id,
		"origin_id": origin_id,
		"destination_id": destination_id,
		"item_id": item_id,
		"quantity": quantity,
		"weight_kg": cargo_weight,
		"status": "pending",
		"truck_id": "",
		"driver_id": "",
		"remaining_game_minutes": 0.0
	}
	shipment_created.emit(shipment_id)
	_dispatch_pending_shipments()
	return shipment_id

func get_location_inventory(location_id: String) -> Dictionary:
	if not locations.has(location_id):
		return {}
	return locations[location_id]["inventory"].duplicate(true)

func get_shipment(shipment_id: String) -> Dictionary:
	return shipments.get(shipment_id, {}).duplicate(true)

func get_save_state() -> Dictionary:
	var location_inventories: Dictionary = {}
	for location_id in locations:
		location_inventories[location_id] = locations[location_id]["inventory"].duplicate(true)
	var truck_states: Dictionary = {}
	for truck_id in trucks:
		var truck: Dictionary = trucks[truck_id]
		truck_states[truck_id] = {
			"status": truck["status"],
			"current_location_id": truck["current_location_id"],
			"shipment_id": truck["shipment_id"]
		}
	return {
		"next_shipment_number": next_shipment_number,
		"location_inventories": location_inventories,
		"truck_states": truck_states,
		"shipments": shipments.duplicate(true)
	}

func validate_saved_state(state: Dictionary) -> bool:
	if (
		not state.get("location_inventories") is Dictionary
		or not state.get("truck_states") is Dictionary
		or not state.get("shipments") is Dictionary
	):
		return false
	var saved_inventories: Dictionary = state["location_inventories"]
	var saved_trucks: Dictionary = state["truck_states"]
	var saved_shipments: Dictionary = state["shipments"]
	if saved_inventories.size() != locations.size() or saved_trucks.size() != trucks.size():
		return false
	if int(state.get("next_shipment_number", 0)) < 1:
		return false
	for location_id in locations:
		if not saved_inventories.has(location_id) or not saved_inventories[location_id] is Dictionary:
			return false
		for item_id in saved_inventories[location_id]:
			var quantity: Variant = saved_inventories[location_id][item_id]
			if (
				not InventoryManagerScript.ITEM_DEFINITIONS.has(item_id)
				or InventoryManagerScript.ITEM_DEFINITIONS[item_id].get("type", "") != "cargo"
				or not (quantity is int or quantity is float)
				or is_nan(float(quantity))
				or is_inf(float(quantity))
				or int(quantity) < 0
				or float(quantity) != float(int(quantity))
			):
				return false
	for truck_id in trucks:
		if not saved_trucks.has(truck_id) or not saved_trucks[truck_id] is Dictionary:
			return false
		var truck_state: Dictionary = saved_trucks[truck_id]
		var assigned_shipment_id := str(truck_state.get("shipment_id", ""))
		var truck_status := str(truck_state.get("status", ""))
		if (
			not ["idle", "in_transit"].has(truck_status)
			or not locations.has(str(truck_state.get("current_location_id", "")))
			or (truck_status == "idle" and not assigned_shipment_id.is_empty())
			or (truck_status == "in_transit" and (
				assigned_shipment_id.is_empty() or not saved_shipments.has(assigned_shipment_id)
			))
		):
			return false
	var reserved_cargo: Dictionary = {}
	for shipment_id in saved_shipments:
		if not saved_shipments[shipment_id] is Dictionary:
			return false
		var shipment: Dictionary = saved_shipments[shipment_id]
		var item_id := str(shipment.get("item_id", ""))
		var item_definition: Dictionary = InventoryManagerScript.ITEM_DEFINITIONS.get(item_id, {})
		var quantity := int(shipment.get("quantity", 0))
		var cargo_weight := float(shipment.get("weight_kg", -1.0))
		var remaining_minutes := float(shipment.get("remaining_game_minutes", -1.0))
		var status := str(shipment.get("status", ""))
		var truck_id := str(shipment.get("truck_id", ""))
		if (
			str(shipment.get("shipment_id", "")) != str(shipment_id)
			or not companies.has(str(shipment.get("company_id", "")))
			or not locations.has(str(shipment.get("origin_id", "")))
			or not locations.has(str(shipment.get("destination_id", "")))
			or item_definition.get("type", "") != "cargo"
			or quantity <= 0
			or not is_equal_approx(cargo_weight, float(item_definition.get("weight_kg", 0.0)) * quantity)
			or not ["pending", "in_transit", "delivered"].has(status)
			or is_nan(remaining_minutes)
			or is_inf(remaining_minutes)
			or remaining_minutes < 0.0
			or (status == "pending" and (not truck_id.is_empty() or remaining_minutes != 0.0))
			or (status != "pending" and not trucks.has(truck_id))
		):
			return false
		if status == "pending":
			var reservation_key := "%s|%s" % [shipment["origin_id"], item_id]
			reserved_cargo[reservation_key] = int(reserved_cargo.get(reservation_key, 0)) + quantity
		elif status == "in_transit":
			var saved_truck: Dictionary = saved_trucks[truck_id]
			if saved_truck["status"] != "in_transit" or saved_truck["shipment_id"] != shipment_id:
				return false
		if status == "delivered" and remaining_minutes != 0.0:
			return false
	for reservation_key in reserved_cargo:
		var key_parts: PackedStringArray = str(reservation_key).split("|")
		var origin_id: String = key_parts[0]
		var item_id: String = key_parts[1]
		if int(reserved_cargo[reservation_key]) > int(saved_inventories[origin_id].get(item_id, 0)):
			return false
	return true

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

func get_suitable_truck_class(weight_kg: float) -> String:
	if weight_kg <= 0.0:
		return ""
	for truck_class in TRUCK_CLASS_ORDER:
		if weight_kg <= float(TRUCK_SPECS[truck_class]["capacity_kg"]):
			return truck_class
	return ""

func _dispatch_pending_shipments() -> void:
	for shipment_id in shipments:
		var shipment: Dictionary = shipments[shipment_id]
		if shipment["status"] != "pending":
			continue
		var truck_id := _find_available_truck(
			str(shipment["company_id"]),
			float(shipment["weight_kg"])
		)
		if truck_id.is_empty():
			continue
		var truck: Dictionary = trucks[truck_id]
		var origin_id: String = shipment["origin_id"]
		var item_id: String = shipment["item_id"]
		var quantity: int = shipment["quantity"]
		var origin_inventory: Dictionary = locations[origin_id]["inventory"]
		origin_inventory[item_id] = int(origin_inventory[item_id]) - quantity
		if int(origin_inventory[item_id]) == 0:
			origin_inventory.erase(item_id)
		var truck_location_id: String = truck["current_location_id"]
		var truck_position: Vector2 = locations[truck_location_id]["position_km"]
		var origin_position: Vector2 = locations[origin_id]["position_km"]
		var destination_position: Vector2 = locations[shipment["destination_id"]]["position_km"]
		var distance_km := (
			truck_position.distance_to(origin_position)
			+ origin_position.distance_to(destination_position)
		) * 1.2
		var travel_game_minutes := distance_km / float(truck["speed_kmh"]) * 60.0
		var total_game_minutes := travel_game_minutes + 20.0
		shipment["status"] = "in_transit"
		shipment["truck_id"] = truck_id
		shipment["driver_id"] = truck["driver_id"]
		shipment["travel_game_minutes"] = travel_game_minutes
		shipment["duration_game_minutes"] = total_game_minutes
		shipment["remaining_game_minutes"] = total_game_minutes
		truck["status"] = "in_transit"
		truck["shipment_id"] = shipment_id
		shipment_dispatched.emit(shipment_id, truck_id, truck["driver_id"])
		_begin_visual_shipment(shipment_id)

func _begin_visual_shipment(shipment_id: String) -> void:
		if not shipments.has(shipment_id):
			return
		var shipment: Dictionary = shipments[shipment_id]
		var truck_id: String = shipment["truck_id"]
		var truck_visual: Node3D = truck_visuals.get(truck_id) as Node3D
		if truck_visual == null:
			return
		var truck: Dictionary = trucks[truck_id]
		var start_location: String = truck["current_location_id"]
		var start_km: Vector2 = locations[start_location]["position_km"]
		var origin_km: Vector2 = locations[shipment["origin_id"]]["position_km"]
		var destination_km: Vector2 = locations[shipment["destination_id"]]["position_km"]
		truck_visual.call("begin_route", start_km * 1000.0, origin_km * 1000.0, destination_km * 1000.0)

func _find_available_truck(company_id: String, cargo_weight_kg: float) -> String:
	for truck_class in TRUCK_CLASS_ORDER:
		if cargo_weight_kg > float(TRUCK_SPECS[truck_class]["capacity_kg"]):
			continue
		for truck_id in companies[company_id]["truck_ids"]:
			var truck: Dictionary = trucks[truck_id]
			if truck["truck_class"] == truck_class and truck["status"] == "idle":
				return truck_id
	return ""

func _get_pending_reserved_quantity(origin_id: String, item_id: String) -> int:
	var reserved_quantity := 0
	for shipment in shipments.values():
		if (
			shipment["status"] == "pending"
			and shipment["origin_id"] == origin_id
			and shipment["item_id"] == item_id
		):
			reserved_quantity += int(shipment["quantity"])
	return reserved_quantity

func _on_world_time_ticked(_day: int, _hour: int, _minute: int, _day_name: String) -> void:
	visual_minute_fraction = 0.0
	advance_game_minutes(1.0)

func advance_game_minutes(game_minutes: float) -> void:
	if game_minutes <= 0.0:
		return
	for shipment_id in shipments:
		var shipment: Dictionary = shipments[shipment_id]
		if shipment["status"] != "in_transit":
			continue
		shipment["remaining_game_minutes"] = maxf(
			0.0,
			float(shipment["remaining_game_minutes"]) - game_minutes
		)
		if shipment["remaining_game_minutes"] > 0.0:
			continue
		var destination_id: String = shipment["destination_id"]
		var item_id: String = shipment["item_id"]
		var destination_inventory: Dictionary = locations[destination_id]["inventory"]
		destination_inventory[item_id] = int(destination_inventory.get(item_id, 0)) + int(shipment["quantity"])
		shipment["status"] = "delivered"
		var truck: Dictionary = trucks[shipment["truck_id"]]
		truck["status"] = "idle"
		truck["current_location_id"] = destination_id
		truck["shipment_id"] = ""
		var truck_visual: Node3D = truck_visuals.get(shipment["truck_id"]) as Node3D
		if truck_visual != null:
			var destination_position: Vector2 = locations[destination_id]["position_km"] * 1000.0
			truck_visual.call("finish_route", destination_position)
		shipment_delivered.emit(shipment_id, destination_id)
	_dispatch_pending_shipments()
