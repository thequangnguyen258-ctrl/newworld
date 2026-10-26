extends SceneTree

const TEST_SCENE_PATH := "res://scenes/core/main_world.tscn"
const ACCESS_SEQUENCE: Array[String] = [
	"MetroAccessGroundDown",
	"MetroAccessB1Down",
	"MetroAccessB2Down",
	"MetroAccessB3Down",
	"MetroAccessB4Up",
	"MetroAccessB3Up",
	"MetroAccessB2Up",
	"MetroAccessB1Up",
	"MetroAccessGroundDown"
]
const DESTINATION_SEQUENCE: Array[String] = [
	"MetroAccessB1Up",
	"MetroAccessB2Up",
	"MetroAccessB3Up",
	"MetroAccessB4Up",
	"MetroAccessB3Down",
	"MetroAccessB2Down",
	"MetroAccessB1Down",
	"MetroAccessGroundDown",
	"MetroAccessB1Up"
]

var world: Node3D
var player: CharacterBody3D
var step_index: int = 0
var frames_waited: int = 0
var player_positioned_for_station: bool = false
var metro_platform_station: InteractiveStation
var metro_boarded_train: Node3D
var metro_boarding_start_position: Vector3
var metro_boarding_frames: int = 0
var metro_boarding_phase: int = 0
var layout_checked: bool = false
var route_access_phase: int = 0
var route_access_frames: int = 0
var route_surface_station: InteractiveStation
var route_underground_station: InteractiveStation

func _initialize() -> void:
	print("🚇 KIỂM THỬ GA METRO TRUNG TÂM 4 TẦNG, 8 HƯỚNG & TÀU CAO TỐC")
	var scene = load(TEST_SCENE_PATH)
	assert(scene != null, "Không thể nạp MainWorld!")
	world = scene.instantiate()
	root.add_child(world)
	player = world.get_node_or_null("Player") as CharacterBody3D
	assert(player != null, "Không tìm thấy Player!")

func _process(_delta: float) -> bool:
	frames_waited += 1
	if frames_waited < 3:
		return false

	if not layout_checked:
		_assert_metro_layout()
		layout_checked = true

	if step_index < ACCESS_SEQUENCE.size():
		if not player_positioned_for_station:
			var source = world.find_child(ACCESS_SEQUENCE[step_index], true, false) as InteractiveStation
			assert(source != null, "Thiếu ga %s!" % ACCESS_SEQUENCE[step_index])
			player.global_position = source.global_position + Vector3.UP
			player.velocity = Vector3.ZERO
			player_positioned_for_station = true
			frames_waited = 0
			return false
		if frames_waited < 3:
			return false
		_test_access_station(step_index)
		step_index += 1
		player_positioned_for_station = false
		frames_waited = 0
		return false

	if route_access_phase < 3 and not _test_route_station_access():
		return false
	return _test_metro_boarding()

func _assert_metro_layout() -> void:
	var hub = world.find_child("CentralMetroHub", true, false) as Node3D
	assert(hub != null, "Thiếu CentralMetroHub!")
	assert(world.find_child("CentralTramStop", true, false) != null, "Tuyến tram hiện hữu phải được giữ lại!")

	var avenue = hub.find_child("SurfaceCentralBoulevard", true, false) as Node3D
	assert(avenue != null and avenue.get_meta("lane_count") == 4, "Mặt đất phải có đại lộ 4 làn!")
	assert(hub.find_child("CentralMetroEntrance", true, false) != null, "Thiếu lối vào ga Metro trên mặt đất!")

	var expected_axis_angles := [0.0, 45.0, 90.0, 135.0]
	for floor_number in range(1, 5):
		var floor = hub.find_child("MetroLevel_%02d" % floor_number, true, false) as Node3D
		assert(floor != null, "Thiếu tầng hầm Metro B%d!" % floor_number)
		assert(is_equal_approx(floor.position.y, -[12.0, 22.0, 32.0, 42.0][floor_number - 1]), "Sai cao độ tầng B%d!" % floor_number)
		assert(is_equal_approx(floor.get_meta("axis_angle_degrees"), expected_axis_angles[floor_number - 1]), "Trục Metro B%d không khớp hướng chéo dự kiến!" % floor_number)
		assert(floor.get_meta("tracks_per_axis") == 4, "Mỗi trục phải có 4 đường ray!")
		assert(floor.get_meta("inbound_tracks") == 2 and floor.get_meta("outbound_tracks") == 2, "Mỗi trục cần 2 ray mỗi chiều!")
		for track_number in range(1, 5):
			var track = floor.find_child("MetroTrack_%02d" % track_number, true, false) as Node3D
			assert(track != null, "Thiếu ray %d trên tầng B%d!" % [track_number, floor_number])
			assert(track.get_meta("direction") == ("outbound" if track_number <= 2 else "inbound"), "Hướng ray phân bổ sai!")

		var expected_station_positions := [-18000.0, -10000.0, 10000.0, 18000.0]
		for station_index in range(1, 5):
			var route_station = floor.find_child("MetroRouteStation_B%d_%02d" % [floor_number, station_index], true, false) as Node3D
			assert(route_station != null, "Thiếu ga tuyến Metro B%d số %d!" % [floor_number, station_index])
			assert(is_equal_approx(route_station.get_meta("route_position"), expected_station_positions[station_index - 1]), "Ga Metro tuyến B%d sai vị trí dọc ray!" % floor_number)
			for platform_side in ["A", "B"]:
				var platform_station = route_station.find_child("MetroRouteBoard_B%d_%02d_%s" % [floor_number, station_index, platform_side], true, false) as InteractiveStation
				assert(platform_station != null and platform_station.station_type == InteractiveStation.StationType.METRO_PLATFORM, "Ga tuyến phải có sân lên/xuống tàu cho cả hai phía!")
			var surface_entrance = hub.find_child("MetroSurfaceEntrance_B%d_%02d" % [floor_number, station_index], true, false) as Node3D
			var surface_access = hub.find_child("MetroRouteAccessSurface_B%d_%02d" % [floor_number, station_index], true, false) as InteractiveStation
			var underground_access = route_station.find_child("MetroRouteAccessUnderground_B%d_%02d" % [floor_number, station_index], true, false) as InteractiveStation
			assert(surface_entrance != null and surface_access != null and underground_access != null, "Ga tuyến cần lối vào mặt đất và kết nối xuống sân ga!")
			assert(surface_access.get_meta("metro_target_station") == underground_access and underground_access.get_meta("metro_target_station") == surface_access, "Lối vào mặt đất và sân ga phải kết nối hai chiều!")
			for access_station in [surface_access, underground_access]:
				assert(access_station.area.collision_layer == (1 | 2 | 4) and access_station.area.collision_mask == (1 | 2 | 4), "Lối ga tuyến mới phải dùng collision layer/mask 1|2|4.")
				assert(access_station.interaction_radius >= 6.0 and access_station.prompt_label.billboard == BaseMaterial3D.BILLBOARD_ENABLED and access_station.prompt_label.no_depth_test, "Lối ga tuyến mới phải có bán kính và bảng nhắc 3D đạt chuẩn.")

	var trains = get_nodes_in_group("metro_trains")
	assert(trains.size() == 8, "Mỗi tầng phải có hai tàu metro cao tốc!")
	for train in trains:
		assert(is_equal_approx(train.speed, 40.0), "Tàu metro phải đạt 40 m/s (144 km/h)!")

	print("  ✅ Đại lộ 4 làn, tram được giữ, 4 tầng tương ứng 4 trục chéo/8 hướng và 16 đường ray.")
	print("  ✅ 16 ga tuyến mới có sân ga hai phía và lối vào mặt đất kết nối xuống tầng Metro.")
	print("  ✅ 8 tàu cao tốc vận hành trên 4 tầng ngầm B1–B4.")

func _test_route_station_access() -> bool:
	if route_access_phase == 0:
		route_surface_station = world.find_child("MetroRouteAccessSurface_B1_03", true, false) as InteractiveStation
		route_underground_station = world.find_child("MetroRouteAccessUnderground_B1_03", true, false) as InteractiveStation
		assert(route_surface_station != null and route_underground_station != null, "Ga Metro tuyến mới phải có lối vào mặt đất và lối ra sân ga!")
		player.global_position = route_surface_station.global_position + Vector3.UP
		player.velocity = Vector3.ZERO
		route_access_phase = 1
		route_access_frames = 0
		return false

	route_access_frames += 1
	if route_access_frames < 3:
		return false

	if route_access_phase == 1:
		assert(route_surface_station.player_in_range and route_surface_station.prompt_label.visible, "Cảm biến và bảng nhắc 3D phải hiện tại cửa ga tuyến mặt đất!")
		_simulate_key(KEY_E)
		assert(player.global_position.distance_to(route_underground_station.global_position + Vector3.UP) < 0.2, "Phím E phải đưa Player từ cửa mặt đất xuống đúng sân ga tuyến!")
		route_access_phase = 2
		route_access_frames = 0
		return false

	if route_access_phase == 2:
		assert(route_underground_station.player_in_range and route_underground_station.prompt_label.visible, "Cảm biến và bảng nhắc 3D phải hiện tại lối ra sân ga!")
		_simulate_key(KEY_E)
		assert(player.global_position.distance_to(route_surface_station.global_position + Vector3.UP) < 0.2, "Phím E phải đưa Player từ sân ga về cửa mặt đất!")
		print("  ✅ Cửa ga tuyến mới dùng cảm biến, prompt và phím [E] để đi hai chiều giữa mặt đất với sân ga.")
		route_access_phase = 3
		return true
	return false

func _test_access_station(sequence_index: int) -> void:
	var source_name = ACCESS_SEQUENCE[sequence_index]
	var destination_name = DESTINATION_SEQUENCE[sequence_index]
	var source = world.find_child(source_name, true, false) as InteractiveStation
	var destination = world.find_child(destination_name, true, false) as InteractiveStation
	assert(source != null and destination != null, "Thiếu lối chuyển tầng %s hoặc %s!" % [source_name, destination_name])
	assert(source.area.collision_layer == (1 | 2 | 4) and source.area.collision_mask == (1 | 2 | 4), "Metro access phải có collision layer/mask 1|2|4.")
	assert(source.interaction_radius >= 6.0, "Bán kính tương tác Metro phải tối thiểu 6m.")

	assert(source.player_in_range, "Cảm biến khoảng cách chưa nhận Player tại %s!" % source_name)
	assert(source.prompt_label.visible, "Bảng nhắc 3D phải hiện tại %s!" % source_name)

	var event = InputEventKey.new()
	event.keycode = KEY_E
	event.physical_keycode = KEY_E
	event.pressed = true
	player._input(event)

	assert(source.interaction_count >= 1, "Phím vật lý E chưa kích hoạt %s!" % source_name)
	assert(player.global_position.distance_to(destination.global_position + Vector3.UP) < 0.2, "Player không được chuyển tới %s!" % destination_name)
	print("  ✅ %s → %s bằng cảm biến, prompt 3D và phím [E]." % [source_name, destination_name])

func _test_metro_boarding() -> bool:
	if metro_boarding_phase == 0:
		metro_platform_station = world.find_child("MetroPlatformBoard_B1_A", true, false) as InteractiveStation
		assert(metro_platform_station != null, "Thiếu sân ga lên tàu Metro B1!")
		assert(metro_platform_station.station_type == InteractiveStation.StationType.METRO_PLATFORM, "Sân ga lên tàu phải xử lý đúng loại tương tác Metro Platform!")
		player.global_position = metro_platform_station.global_position + Vector3.UP
		player.velocity = Vector3.ZERO
		metro_boarding_phase = 1
		metro_boarding_frames = 0
		return false

	metro_boarding_frames += 1
	if metro_boarding_phase == 1:
		if metro_boarding_frames < 3:
			return false
		assert(metro_platform_station.player_in_range and metro_platform_station.prompt_label.visible, "Cảm biến sân ga và bảng nhắc phải hiện trước khi lên tàu!")
		var trains = get_nodes_in_group("metro_trains_b1")
		for train in trains:
			if train.dwell_remaining > 0.0 and train.global_position.distance_to(metro_platform_station.global_position) <= 12.0:
				metro_boarded_train = train
				break
		if metro_boarded_train == null:
			assert(metro_boarding_frames < 1200, "Không có tàu cao tốc nào dừng tại sân ga trong thời gian chờ!")
			return false

		metro_boarding_start_position = player.global_position
		_simulate_key(KEY_E)
		assert(metro_boarded_train.get("passenger_ref") == player, "Tàu Metro phải nhận Player từ sân ga bằng phím E!")
		assert(not player.visible and not player.is_physics_processing(), "Player phải ở trên tàu và tạm dừng điều khiển vật lý.")
		metro_boarded_train.speed = 600000.0
		metro_boarding_phase = 2
		metro_boarding_frames = 0
		print("  ✅ Player lên tàu Metro cao tốc từ sân ga bằng phím vật lý [E].")
		return false

	if metro_boarding_phase == 2:
		if metro_boarded_train.dwell_remaining <= 0.0 or not is_equal_approx(metro_boarded_train.position.x, 10000.0):
			assert(metro_boarding_frames < 900, "Tàu Metro không dừng tại ga trung tuyến kế tiếp!")
			return false
		assert(player.global_position.distance_to(metro_boarded_train.global_position) < 3.0, "Player phải được chở cùng toa Metro.")
		var next_station = world.find_child("MetroRouteStation_B1_03", true, false) as Node3D
		assert(next_station != null and player.global_position.distance_to(next_station.global_position) < 10.0, "Player phải được đưa tới sân ga trung tuyến B1.")
		_simulate_key(KEY_F)
		assert(metro_boarded_train.get("passenger_ref") == null, "Tàu phải thả Player khi nhấn F!")
		assert(player.visible and player.is_physics_processing(), "Điều khiển Player phải được khôi phục sau khi xuống Metro.")
		assert(not player.has_meta("occupied_metro"), "Phải xóa trạng thái đang ngồi Metro sau khi xuống!")
		print("  ✅ Tàu chở Player đến ga trung tuyến và dừng đón/trả; phím [F] xuống đúng sân ga.")
		print("✅ PASS: Bốn tầng, 16 ray, 8 hướng, 16 ga tuyến mới, tàu cao tốc và lối chuyển tầng hai chiều.")
		quit(0)
		return true
	return false

func _simulate_key(key_code: Key) -> void:
	var event = InputEventKey.new()
	event.keycode = key_code
	event.physical_keycode = key_code
	event.pressed = true
	player._input(event)
