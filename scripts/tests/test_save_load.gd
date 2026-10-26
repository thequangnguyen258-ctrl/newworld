extends SceneTree

const SaveManagerScript = preload("res://scripts/core/save_manager.gd")
const InventoryManagerScript = preload("res://scripts/economy/inventory_manager.gd")
const PlayerControllerScript = preload("res://scripts/core/player_controller.gd")
const HousingPlotScript = preload("res://scripts/interactive/housing_plot.gd")
const TEST_SAVE_PATH: String = "user://save_load_test.json"

class TestPlayer extends Node3D:
	var saved_state: Dictionary = {
		"position": [25.0, 601.2, -18.0],
		"rotation": [0.0, 1.25, 0.0],
		"head_pitch": -0.2,
		"health": 80.0,
		"stamina": 65.0,
		"is_third_person": true,
		"third_person_distance": 3.6
	}

	func get_save_state() -> Dictionary:
		return saved_state.duplicate(true)

	func validate_saved_state(state: Dictionary) -> bool:
		return state.has("position") and state.has("health")

	func apply_saved_state(state: Dictionary) -> bool:
		if not validate_saved_state(state):
			return false
		saved_state = state.duplicate(true)
		return true

class TestWorldManager extends Node:
	var saved_state: Dictionary = {
		"day_index": 4,
		"hour": 17,
		"minute": 42,
		"second_accumulator": 1.25,
		"treasury_city": 42500.0,
		"fund_tithe_church": 21100.0
	}

	func get_save_state() -> Dictionary:
		return saved_state.duplicate(true)

	func validate_saved_state(state: Dictionary) -> bool:
		return state.has("day_index") and state.has("treasury_city")

	func apply_saved_state(state: Dictionary) -> bool:
		if not validate_saved_state(state):
			return false
		saved_state = state.duplicate(true)
		return true

class TestHousingPlot extends Node3D:
	var plot_id: String = "save_test_plot"
	var saved_state: Dictionary = {
		"plot_id": "save_test_plot",
		"status": "COMPLETED",
		"owner_name": "Thị Trưởng",
		"land_deed_number": "SO_DO_TTG_TEST",
		"construction_progress": 100.0,
		"position": [10.0, 600.0, 15.0]
	}

	func get_save_state() -> Dictionary:
		return saved_state.duplicate(true)

	func validate_saved_state(state: Dictionary) -> bool:
		return state.get("plot_id", "") == plot_id

	func apply_saved_state(state: Dictionary) -> bool:
		if not validate_saved_state(state):
			return false
		saved_state = state.duplicate(true)
		return true

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var initial_inventory: Dictionary = InventoryManagerScript.get_save_state()
	var save_manager = SaveManagerScript.new()
	save_manager.save_path = TEST_SAVE_PATH
	save_manager.autosave_interval_seconds = 0.0
	root.add_child(save_manager)

	var player := TestPlayer.new()
	player.add_to_group("player")
	root.add_child(player)
	var world_manager := TestWorldManager.new()
	root.add_child(world_manager)
	var plot := TestHousingPlot.new()
	plot.add_to_group("housing_plots")
	root.add_child(plot)

	var real_player = PlayerControllerScript.new()
	var real_player_state := {
		"position": [0.0, 601.2, 28.0],
		"rotation": [0.0, 0.0, 0.0],
		"head_pitch": 0.0,
		"health": 100.0,
		"stamina": 100.0,
		"is_third_person": true,
		"third_person_distance": 3.6
	}
	assert(real_player.validate_saved_state(real_player_state), "Trạng thái PlayerController mặc định phải hợp lệ.")
	assert(real_player.validate_saved_state({
		"position": [0.0, 601.2, 28.0],
		"rotation": [0.0, 0.0, 0.0],
		"head_pitch": 0.0,
		"health": 100.0,
		"stamina": 100.0,
		"is_third_person": true,
		"third_person_distance": 3.6
	}), "Save cũ thiếu hotbar/đèn phải được nạp với giá trị mặc định.")
	var real_housing_plot = HousingPlotScript.new()
	var real_plot_state := {
		"plot_id": "plot_01",
		"status": "AVAILABLE",
		"owner_name": "",
		"land_deed_number": "",
		"construction_progress": 0.0,
		"position": [0.0, 0.0, 0.0]
	}
	assert(real_housing_plot.validate_saved_state(real_plot_state), "Trạng thái HousingPlot mặc định phải hợp lệ.")
	var live_world_manager = root.get_node("/root/WorldManager")
	assert(live_world_manager.validate_saved_state(live_world_manager.get_save_state()), "Trạng thái WorldManager hiện tại phải hợp lệ.")
	real_player.free()
	real_housing_plot.free()

	assert(InventoryManagerScript.apply_saved_state({
		"briefcase": {"item_baguette": 7},
		"office_storage": {"item_herbal_tea": 4}
	}), "Trạng thái túi/kho kiểm thử phải hợp lệ.")
	assert(save_manager.save_game(player, world_manager), "Lưu trạng thái kiểm thử phải thành công.")
	assert(save_manager.save_game(player, world_manager), "Thay thế tệp lưu hiện có phải thành công.")

	assert(InventoryManagerScript.apply_saved_state({
		"briefcase": {},
		"office_storage": {}
	}), "Có thể thay đổi túi/kho trước khi nạp lại.")
	player.saved_state["position"] = [0.0, 0.0, 0.0]
	world_manager.saved_state["hour"] = 2
	world_manager.saved_state["treasury_city"] = 1.0
	plot.saved_state["status"] = "AVAILABLE"
	plot.saved_state["construction_progress"] = 0.0

	var database_manager = root.get_node_or_null("/root/DatabaseManager")
	var database_was_open := bool(database_manager.get("is_db_open")) if database_manager != null else false
	if database_manager != null:
		database_manager.set("is_db_open", false)
	assert(save_manager.load_game(player, world_manager), "Nạp trạng thái kiểm thử phải thành công.")
	if database_manager != null:
		database_manager.set("is_db_open", database_was_open)
	assert(player.saved_state["position"] == [25.0, 601.2, -18.0], "Vị trí người chơi phải được khôi phục.")
	assert(world_manager.saved_state["hour"] == 17, "Giờ trong game phải được khôi phục.")
	assert(world_manager.saved_state["treasury_city"] == 42500.0, "Ngân khố phải được khôi phục.")
	assert(plot.saved_state["status"] == "COMPLETED", "Trạng thái xây dựng phải được khôi phục.")
	assert(InventoryManagerScript.get_item_count("item_baguette") == 7, "Số vật phẩm trong cặp phải được khôi phục.")
	assert(InventoryManagerScript.get_storage_item_count("item_herbal_tea") == 4, "Số vật phẩm trong kho văn phòng phải được khôi phục.")

	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE_PATH))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE_PATH + ".tmp"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE_PATH + ".bak"))
	plot.free()
	world_manager.free()
	player.free()
	save_manager.free()
	InventoryManagerScript.apply_saved_state(initial_inventory)
	await process_frame
	print("[PASS] Save/load khôi phục người chơi, thế giới, công trình, cặp và kho văn phòng.")
	quit()
