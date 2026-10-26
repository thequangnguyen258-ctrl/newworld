extends SceneTree

const LogisticsManagerScript = preload("res://scripts/simulation/logistics_manager.gd")
const CitizenManagerScript = preload("res://scripts/simulation/citizen_manager.gd")
const DailyScheduleManagerScript = preload("res://scripts/simulation/daily_schedule_manager.gd")
const BuildingJobRegistryScript = preload("res://scripts/simulation/building_job_registry.gd")

func _init() -> void:
	var citizens := CitizenManagerScript.new()
	citizens._generate_initial_citizens()
	var logistics: LogisticsManagerScript = LogisticsManagerScript.new()
	logistics.name = "TestLogisticsManager"
	root.add_child(logistics)
	logistics.initialize_capital_industry(citizens.citizen_registry)
	var visual_world := Node3D.new()
	visual_world.name = "TestVisualWorld"
	root.add_child(visual_world)
	logistics.attach_visuals(visual_world)
	assert(logistics.truck_visuals.size() == 4, "Cả bốn xe đội công ty phải có biểu diễn 3D.")
	for truck_visual_value in logistics.truck_visuals.values():
		var truck_visual := truck_visual_value as Node3D
		var status_label := truck_visual.get_node_or_null("FleetStatus") as Label3D
		assert(truck_visual != null and truck_visual.get_node_or_null("CargoBody") != null)
		assert(status_label != null and status_label.no_depth_test)

	var company: Dictionary = logistics.companies["COMPANY_CAPITAL_FREIGHT"]
	assert(company["name"] == "Công ty Vận tải Tân Thế Giới")
	assert(company["truck_ids"].size() == 4, "Công ty khởi đầu cần có đủ bốn hạng xe tải.")
	assert(company["employee_ids"].size() == 7, "Công ty cần người quản lý, điều phối, bảo dưỡng và bốn tài xế.")
	for truck_id in company["truck_ids"]:
		assert(logistics.trucks[truck_id]["current_location_id"] == "CAPITAL_LOGISTICS_DEPOT")
	assert(citizens.get_citizen(company["manager_id"]).age >= 18)
	assert(citizens.get_citizen(company["dispatcher_id"]).age >= 18)
	assert(not citizens.get_citizen(company["mechanic_id"]).is_church_servant,
		"Thợ máy vận tải giữ công việc đời sống chính, không bị gán nhầm làm NHVC Part-Time.")
	var starter_shipment: Dictionary = logistics.get_shipment("SHIPMENT_000001")
	assert(starter_shipment["status"] == "in_transit",
		"Công ty phải bắt đầu bằng một chuyến tiếp tế thực sự đang chạy.")
	var starter_visual := logistics.truck_visuals[starter_shipment["truck_id"]] as Node3D
	assert(bool(starter_visual.get("has_active_route")), "Xe nhận chuyến phải chuyển sang trạng thái chạy tuyến.")
	var initial_truck_position := starter_visual.position
	starter_visual.call("set_route_progress", 0.6)
	assert(starter_visual.position.distance_to(initial_truck_position) > 1.0,
		"Tiến độ chuyến phải làm xe 3D di chuyển theo tuyến.")
	assert(
		is_equal_approx(
			starter_visual.position.y,
			ModularNatureChunk.get_world_height(starter_visual.position.x, starter_visual.position.z)
		),
		"Xe hàng 3D phải bám hàm cao độ địa hình liên tục."
	)
	logistics.advance_game_minutes(float(starter_shipment["remaining_game_minutes"]))
	assert(logistics.get_shipment("SHIPMENT_000001")["status"] == "delivered")
	assert(not bool(starter_visual.get("has_active_route")))

	var expected_capacity := {
		"LIGHT": 3500.0,
		"MEDIUM": 10000.0,
		"CONTAINER": 28000.0,
		"HEAVY": 40000.0
	}
	for truck_class in expected_capacity:
		assert(
			is_equal_approx(float(logistics.TRUCK_SPECS[truck_class]["capacity_kg"]), expected_capacity[truck_class]),
			"Sức chở hạng xe %s phải khớp cấu hình." % truck_class
		)

	var job_registry := BuildingJobRegistryScript.new()
	for truck_class in logistics.TRUCK_CLASS_ORDER:
		var driver_role: String = logistics.TRUCK_SPECS[truck_class]["driver_role"]
		var driver_found := false
		for citizen_value in citizens.citizen_registry.values():
			var citizen := citizen_value as CitizenData
			if citizen.job_role != driver_role:
				continue
			driver_found = true
			assert(job_registry.can_citizen_apply(citizen, driver_role), "Tài xế cần chứng chỉ phù hợp với hạng xe.")
			var license_certificate := job_registry.get_required_certificate(driver_role)
			assert(not job_registry.get_courses_for_cert(license_certificate).is_empty(),
				"Mỗi hạng xe phải có khóa đào tạo và chứng chỉ chuyên môn.")
			break
		assert(driver_found, "Thiếu nghề tài xế cho hạng xe %s." % truck_class)

	var dispatcher_schedule: Dictionary = DailyScheduleManagerScript.get_citizen_schedule(
		"Điều phối viên logistics", false, 0, 9, 0, true, false, false, "CAPITAL_LOGISTICS_DEPOT"
	)
	assert(dispatcher_schedule["destination"] == "logistics_depot")
	assert(dispatcher_schedule["pose"] == "work")
	var truck_driver_schedule: Dictionary = DailyScheduleManagerScript.get_citizen_schedule(
		"Tài xế xe container", false, 0, 9, 0, true, false, false, "CAPITAL_LOGISTICS_DEPOT"
	)
	assert(truck_driver_schedule["destination"] == "logistics_depot")
	assert(truck_driver_schedule["pose"] == "drive")

	var light_shipment: String = logistics.request_shipment(
		"COMPANY_CAPITAL_FREIGHT", "EAST_FARM", "CAPITAL_BAKERY", "item_wheat_sack", 100
	)
	assert(not light_shipment.is_empty())
	var light_record: Dictionary = logistics.get_shipment(light_shipment)
	assert(light_record["status"] == "in_transit")
	assert(logistics.trucks[light_record["truck_id"]]["truck_class"] == "LIGHT",
		"Đơn 1,2 tấn phải chọn xe tải nhẹ.")
	assert(logistics.get_location_inventory("EAST_FARM")["item_wheat_sack"] == 19800,
		"Kho nguồn phải trừ hàng khi xe xuất bến.")
	logistics.advance_game_minutes(float(light_record["remaining_game_minutes"]))
	assert(logistics.get_shipment(light_shipment)["status"] == "delivered")
	assert(logistics.get_location_inventory("CAPITAL_BAKERY")["item_wheat_sack"] == 200,
		"Kho đích phải nhận đủ hàng sau khi hoàn tất chuyến.")

	var medium_shipment: String = logistics.request_shipment(
		"COMPANY_CAPITAL_FREIGHT", "EAST_FARM", "CAPITAL_BAKERY", "item_wheat_sack", 300
	)
	assert(not medium_shipment.is_empty())
	var medium_record: Dictionary = logistics.get_shipment(medium_shipment)
	assert(logistics.trucks[medium_record["truck_id"]]["truck_class"] == "MEDIUM",
		"Đơn 3,6 tấn phải chọn xe tải trung.")

	var container_shipment: String = logistics.request_shipment(
		"COMPANY_CAPITAL_FREIGHT", "EAST_FARM", "CAPITAL_BAKERY", "item_wheat_sack", 2000
	)
	assert(not container_shipment.is_empty())
	var container_record: Dictionary = logistics.get_shipment(container_shipment)
	assert(logistics.trucks[container_record["truck_id"]]["truck_class"] == "CONTAINER",
		"Đơn 24 tấn phải chọn xe đầu kéo container.")

	var heavy_shipment: String = logistics.request_shipment(
		"COMPANY_CAPITAL_FREIGHT", "EAST_FARM", "CAPITAL_BAKERY", "item_wheat_sack", 3000
	)
	assert(not heavy_shipment.is_empty())
	var heavy_record: Dictionary = logistics.get_shipment(heavy_shipment)
	assert(logistics.trucks[heavy_record["truck_id"]]["truck_class"] == "HEAVY",
		"Đơn 36 tấn phải chọn xe tải hạng nặng.")
	var additional_light_shipment: String = logistics.request_shipment(
		"COMPANY_CAPITAL_FREIGHT", "EAST_FARM", "CAPITAL_BAKERY", "item_wheat_sack", 100
	)
	var queued_small_shipment: String = logistics.request_shipment(
		"COMPANY_CAPITAL_FREIGHT", "EAST_FARM", "CAPITAL_BAKERY", "item_wheat_sack", 100
	)
	var queued_large_shipment: String = logistics.request_shipment(
		"COMPANY_CAPITAL_FREIGHT", "EAST_FARM", "CAPITAL_BAKERY", "item_wheat_sack", 1400
	)
	assert(logistics.get_shipment(additional_light_shipment)["status"] == "in_transit")
	assert(logistics.get_shipment(queued_small_shipment)["status"] == "pending")
	assert(logistics.get_shipment(queued_large_shipment)["status"] == "pending")
	assert(
		logistics.request_shipment(
			"COMPANY_CAPITAL_FREIGHT", "EAST_FARM", "CAPITAL_BAKERY", "item_wheat_sack", 13001
		).is_empty(),
		"Không được nhận đơn vượt lượng hàng còn lại đã trừ cả đơn đang chờ."
	)
	var oversized_shipment: String = logistics.request_shipment(
		"COMPANY_CAPITAL_FREIGHT", "EAST_FARM", "CAPITAL_BAKERY", "item_wheat_sack", 4000
	)
	assert(oversized_shipment.is_empty(), "Đơn vượt 40 tấn phải bị từ chối rõ ràng.")
	var logistics_state: Dictionary = logistics.get_save_state()
	assert(logistics.validate_saved_state(logistics_state), "Trạng thái đội xe, đơn hàng và tồn kho phải lưu được.")
	logistics.advance_game_minutes(10000.0)
	assert(logistics.get_shipment(medium_shipment)["status"] == "delivered")
	assert(logistics.apply_saved_state(logistics_state), "Phải khôi phục được chuyến hàng đang vận chuyển.")
	assert(logistics.get_shipment(medium_shipment)["status"] == "in_transit")
	var invalid_logistics_state := logistics_state.duplicate(true)
	invalid_logistics_state["location_inventories"]["EAST_FARM"]["item_wheat_sack"] = -1
	assert(not logistics.validate_saved_state(invalid_logistics_state), "Không nhận tồn kho âm khi nạp.")

	print("[LogisticsTest] PASS: công ty, nhân sự chuyên môn, đội xe, ghép tải và giao nhận kho.")
	visual_world.free()
	logistics.free()
	citizens.free()
	job_registry.free()
	quit(0)
