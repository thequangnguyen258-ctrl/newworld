extends Node

const InventoryManagerScript = preload("res://scripts/economy/inventory_manager.gd")
const SAVE_VERSION: int = 1
const DEFAULT_SAVE_PATH: String = "user://tan_the_gioi_save.json"
const TEMP_SUFFIX: String = ".tmp"
const BACKUP_SUFFIX: String = ".bak"
const INITIAL_CITY_TREASURY: float = 50000.0
const INITIAL_CHURCH_FUND: float = 25000.0

@export_range(10.0, 600.0, 1.0) var autosave_interval_seconds: float = 60.0

var save_path: String = DEFAULT_SAVE_PATH
var _autosave_elapsed: float = 0.0

func _process(delta: float) -> void:
	if autosave_interval_seconds <= 0.0:
		return
	if get_tree().get_first_node_in_group("player") == null:
		_autosave_elapsed = 0.0
		return

	_autosave_elapsed += delta
	if _autosave_elapsed >= autosave_interval_seconds:
		_autosave_elapsed = 0.0
		save_game()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key_event := event as InputEventKey
		var physical_key := key_event.physical_keycode if key_event.physical_keycode != 0 else key_event.keycode
		if physical_key == KEY_F6:
			if save_game():
				_show_toast("Đã lưu tiến trình thành công.")
			get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if get_tree().get_first_node_in_group("player") != null:
			save_game()

func save_game(player: Node = null, world_manager: Node = null) -> bool:
	if player == null:
		player = get_tree().get_first_node_in_group("player")
	if world_manager == null:
		world_manager = get_node_or_null("/root/WorldManager")
	if player == null or world_manager == null:
		push_error("[SaveManager] Không thể lưu: thiếu Player hoặc WorldManager.")
		return false
	if not player.has_method("get_save_state") or not player.has_method("validate_saved_state"):
		push_error("[SaveManager] Player thiếu API get/validate_save_state().")
		return false
	if not world_manager.has_method("get_save_state") or not world_manager.has_method("validate_saved_state"):
		push_error("[SaveManager] WorldManager thiếu API get/validate_saved_state().")
		return false

	var player_state: Dictionary = player.get_save_state()
	var world_state: Dictionary = world_manager.get_save_state()
	if not player.validate_saved_state(player_state) or not world_manager.validate_saved_state(world_state):
		push_error("[SaveManager] Không lưu dữ liệu vì trạng thái người chơi hoặc thế giới không hợp lệ.")
		return false
	var inventory_state: Dictionary = InventoryManagerScript.get_save_state()
	if not InventoryManagerScript.validate_saved_state(inventory_state):
		push_error("[SaveManager] Không lưu dữ liệu vì túi/cặp hoặc kho văn phòng không hợp lệ.")
		return false
	var logistics_manager := get_node_or_null("/root/LogisticsManager")
	var logistics_state: Dictionary = {}
	if logistics_manager != null:
		if not logistics_manager.has_method("get_save_state") or not logistics_manager.has_method("validate_saved_state"):
			push_error("[SaveManager] LogisticsManager thiếu API get/validate_saved_state().")
			return false
		logistics_state = logistics_manager.get_save_state()
		if not logistics_manager.validate_saved_state(logistics_state):
			push_error("[SaveManager] Không lưu dữ liệu vì trạng thái logistics không hợp lệ.")
			return false
	var housing_states: Variant = _capture_housing_plots()
	if not housing_states is Array:
		return false
	var payload := {
		"version": SAVE_VERSION,
		"saved_at_unix": int(Time.get_unix_time_from_system()),
		"player": player_state,
		"world": world_state,
		"inventory": inventory_state,
		"housing_plots": housing_states
	}
	if logistics_manager != null:
		payload["logistics"] = logistics_state
	if not _validate_payload(payload):
		push_error("[SaveManager] Không lưu dữ liệu vì trạng thái hiện tại không hợp lệ.")
		return false
	if not _write_payload(payload):
		return false
	var timeline_server: Node = world_manager._get_timeline_server() if world_manager.has_method("_get_timeline_server") else world_manager.get("timeline_server_ref")
	if timeline_server != null and timeline_server.has_method("save_timeline"):
		timeline_server.save_timeline()
	return true

func load_game(player: Node = null, world_manager: Node = null) -> bool:
	if player == null:
		player = get_tree().get_first_node_in_group("player")
	if world_manager == null:
		world_manager = get_node_or_null("/root/WorldManager")
	if player == null or world_manager == null:
		push_error("[SaveManager] Không thể nạp: thiếu Player hoặc WorldManager.")
		return false
	if not player.has_method("validate_saved_state") or not player.has_method("apply_saved_state"):
		push_error("[SaveManager] Player thiếu API validate/apply_saved_state().")
		return false
	if not world_manager.has_method("validate_saved_state") or not world_manager.has_method("apply_saved_state"):
		push_error("[SaveManager] WorldManager thiếu API validate/apply_saved_state().")
		return false

	var payload := _read_payload()
	if payload.is_empty():
		return false
	var player_state: Dictionary = payload["player"]
	var world_state: Dictionary = payload["world"].duplicate(true)
	var inventory_state: Dictionary = payload.get("inventory", InventoryManagerScript.get_save_state())
	var logistics_manager := get_node_or_null("/root/LogisticsManager")
	var logistics_state: Dictionary = payload.get("logistics", {})
	if not player.validate_saved_state(player_state) or not world_manager.validate_saved_state(world_state):
		push_error("[SaveManager] Tệp lưu chứa trạng thái người chơi hoặc thế giới không hợp lệ.")
		return false
	if not InventoryManagerScript.validate_saved_state(inventory_state):
		push_error("[SaveManager] Tệp lưu chứa túi/cặp hoặc kho văn phòng không hợp lệ.")
		return false
	if not logistics_state.is_empty():
		if logistics_manager == null:
			push_error("[SaveManager] Tệp lưu có dữ liệu logistics nhưng LogisticsManager chưa được khởi tạo.")
			return false
		if not logistics_manager.has_method("validate_saved_state") or not logistics_manager.validate_saved_state(logistics_state):
			push_error("[SaveManager] Tệp lưu chứa trạng thái logistics không hợp lệ.")
			return false
	_merge_offline_progress(world_manager, world_state)

	var plot_states: Dictionary = {}
	for plot_state in payload["housing_plots"]:
		plot_states[plot_state["plot_id"]] = plot_state
	var restore_housing_from_json := not _has_persistent_housing_database()
	if restore_housing_from_json:
		for plot in get_tree().get_nodes_in_group("housing_plots"):
			if plot_states.has(plot.plot_id):
				if not plot.has_method("validate_saved_state") or not plot.validate_saved_state(plot_states[plot.plot_id]):
					push_error("[SaveManager] Dữ liệu lưu lô đất không hợp lệ: %s." % plot.plot_id)
					return false

	if not world_manager.apply_saved_state(world_state):
		push_error("[SaveManager] Không thể khôi phục trạng thái thế giới.")
		return false
	if not InventoryManagerScript.apply_saved_state(inventory_state):
		push_error("[SaveManager] Không thể khôi phục túi/cặp và kho văn phòng.")
		return false
	if not logistics_state.is_empty() and not logistics_manager.apply_saved_state(logistics_state):
		push_error("[SaveManager] Không thể khôi phục trạng thái logistics.")
		return false
	if not player.apply_saved_state(player_state):
		push_error("[SaveManager] Không thể khôi phục trạng thái người chơi.")
		return false
	if restore_housing_from_json:
		for plot in get_tree().get_nodes_in_group("housing_plots"):
			if plot_states.has(plot.plot_id) and not plot.apply_saved_state(plot_states[plot.plot_id]):
				push_error("[SaveManager] Không thể khôi phục lô đất: %s." % plot.plot_id)
				return false

	print("[SaveManager] Đã nạp tiến trình từ %s." % save_path)
	_show_toast("Đã nạp tiến trình gần nhất.")
	return true

func _merge_offline_progress(world_manager: Node, saved_world_state: Dictionary) -> void:
	var timeline_server: Node = world_manager._get_timeline_server() if world_manager.has_method("_get_timeline_server") else world_manager.get("timeline_server_ref")
	if timeline_server == null or not bool(timeline_server.get("is_initialized")):
		return
	var saved_total := int(saved_world_state.get("total_game_minutes", -1))
	var current_total := int(timeline_server.get("total_game_minutes"))
	if saved_total < 0 or current_total <= saved_total:
		return

	var current_world_state: Dictionary = world_manager.get_save_state()
	for key in ["day_index", "hour", "minute", "second_accumulator"]:
		saved_world_state[key] = current_world_state[key]
	saved_world_state["treasury_city"] = float(saved_world_state["treasury_city"]) + maxf(
		0.0, float(current_world_state["treasury_city"]) - INITIAL_CITY_TREASURY
	)
	saved_world_state["fund_tithe_church"] = float(saved_world_state["fund_tithe_church"]) + maxf(
		0.0, float(current_world_state["fund_tithe_church"]) - INITIAL_CHURCH_FUND
	)
	saved_world_state["total_game_minutes"] = current_total

func _has_persistent_housing_database() -> bool:
	var database_manager := get_node_or_null("/root/DatabaseManager")
	return database_manager != null and bool(database_manager.get("is_db_open"))

func _capture_housing_plots() -> Variant:
	var saved_plots: Array[Dictionary] = []
	for plot in get_tree().get_nodes_in_group("housing_plots"):
		if not plot.has_method("get_save_state") or not plot.has_method("validate_saved_state"):
			push_error("[SaveManager] Lô đất %s thiếu API lưu/nạp trạng thái." % plot.name)
			return null
		var plot_state: Dictionary = plot.get_save_state()
		if not plot.validate_saved_state(plot_state):
			push_error("[SaveManager] Trạng thái lô đất không hợp lệ: %s." % plot.name)
			return null
		saved_plots.append(plot_state)
	return saved_plots

func _validate_payload(payload: Dictionary) -> bool:
	if not (
		int(payload.get("version", -1)) == SAVE_VERSION
		and payload.get("player") is Dictionary
		and payload.get("world") is Dictionary
		and payload.get("housing_plots") is Array
	):
		return false
	if payload.has("inventory") and not payload["inventory"] is Dictionary:
		return false
	if payload.has("logistics") and not payload["logistics"] is Dictionary:
		return false
	var plot_ids: Dictionary = {}
	for plot_state in payload["housing_plots"]:
		if not plot_state is Dictionary or not plot_state.get("plot_id", "") is String:
			return false
		var plot_id: String = plot_state["plot_id"]
		if plot_id.is_empty() or plot_ids.has(plot_id):
			return false
		plot_ids[plot_id] = true
	return true

func _read_payload() -> Dictionary:
	if not FileAccess.file_exists(save_path):
		return {}
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		push_error("[SaveManager] Không mở được tệp lưu: %s (mã lỗi %d)." % [save_path, FileAccess.get_open_error()])
		return {}

	var json := JSON.new()
	var parse_error := json.parse(file.get_as_text())
	file.close()
	if parse_error != OK:
		push_error("[SaveManager] Tệp lưu bị lỗi tại dòng %d: %s." % [json.get_error_line(), json.get_error_message()])
		return {}
	if not json.data is Dictionary:
		push_error("[SaveManager] Tệp lưu không có cấu trúc JSON object.")
		return {}
	var payload: Dictionary = json.data
	if not _validate_payload(payload):
		push_error("[SaveManager] Phiên bản hoặc cấu trúc tệp lưu không được hỗ trợ.")
		return {}
	return payload

func _write_payload(payload: Dictionary) -> bool:
	var temp_path := save_path + TEMP_SUFFIX
	var backup_path := save_path + BACKUP_SUFFIX
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		push_error("[SaveManager] Không tạo được tệp lưu tạm: %s (mã lỗi %d)." % [temp_path, FileAccess.get_open_error()])
		return false

	file.store_string(JSON.stringify(payload, "\t"))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
		push_error("[SaveManager] Ghi tệp lưu tạm thất bại (mã lỗi %d)." % write_error)
		return false

	var absolute_temp := ProjectSettings.globalize_path(temp_path)
	var absolute_save := ProjectSettings.globalize_path(save_path)
	var absolute_backup := ProjectSettings.globalize_path(backup_path)
	var had_previous_save := FileAccess.file_exists(save_path)
	if had_previous_save:
		var backup_error := DirAccess.rename_absolute(absolute_save, absolute_backup)
		if backup_error != OK:
			DirAccess.remove_absolute(absolute_temp)
			push_error("[SaveManager] Không thể bảo toàn tệp lưu hiện có (mã lỗi %d)." % backup_error)
			return false

	var replace_error := DirAccess.rename_absolute(absolute_temp, absolute_save)
	if replace_error != OK:
		if had_previous_save:
			var restore_error := DirAccess.rename_absolute(absolute_backup, absolute_save)
			if restore_error != OK:
				push_error("[SaveManager] Thay tệp lưu thất bại (%d) và khôi phục bản cũ cũng thất bại (%d)." % [replace_error, restore_error])
				return false
		DirAccess.remove_absolute(absolute_temp)
		push_error("[SaveManager] Không thể thay thế tệp lưu (mã lỗi %d)." % replace_error)
		return false

	if had_previous_save:
		var remove_error := DirAccess.remove_absolute(absolute_backup)
		if remove_error != OK:
			push_warning("[SaveManager] Đã lưu thành công nhưng không xóa được bản sao lưu tạm (mã lỗi %d)." % remove_error)
	return true

func _show_toast(message: String) -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud != null and hud.has_method("show_toast"):
		hud.show_toast(message)
