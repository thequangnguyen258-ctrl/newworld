class_name CentralMetroBuilder
extends RefCounted

const TRACK_COUNT_PER_AXIS: int = 4
const TRACK_OFFSETS: Array[float] = [-4.5, -1.5, 1.5, 4.5]
const AXIS_ANGLES_DEGREES: Array[float] = [0.0, 45.0, 90.0, 135.0]
const FLOOR_DEPTHS: Array[float] = [12.0, 22.0, 32.0, 42.0]
const ROUTE_HALF_LENGTH: float = 18000.0
const ROUTE_STATION_STOP_POSITIONS: Array[float] = [-18000.0, -10000.0, 0.0, 10000.0, 18000.0]
const TRAIN_SPEED: float = 40.0
const ENTRANCE_POSITION := Vector3(22.0, 0.0, 205.0)

class MetroTrainCar extends Node3D:
	var speed: float = TRAIN_SPEED
	var direction: float = 1.0
	var outbound_track_index: int = 0
	var current_track_index: int = 0
	var dwell_remaining: float = 0.0
	var passenger_ref: Node3D
	var stop_positions: Array[float] = ROUTE_STATION_STOP_POSITIONS.duplicate()

	func _ready() -> void:
		add_to_group("metro_trains_b%d" % get_parent().get_parent().get_meta("floor_number"))

	func _process(delta: float) -> void:
		if dwell_remaining > 0.0:
			dwell_remaining = maxf(0.0, dwell_remaining - delta)
			_update_passenger_position()
			return

		var previous_x = position.x
		position.x += speed * direction * delta
		var next_station_position = _get_crossed_station(previous_x, position.x)
		if next_station_position != null:
			position.x = next_station_position
			dwell_remaining = 5.0
			_update_passenger_position()
			return

		if direction > 0.0 and position.x >= ROUTE_HALF_LENGTH:
			position.x = ROUTE_HALF_LENGTH
			direction = -1.0
			current_track_index = outbound_track_index + 2
			position.z = TRACK_OFFSETS[current_track_index]
		elif direction < 0.0 and position.x <= -ROUTE_HALF_LENGTH:
			position.x = -ROUTE_HALF_LENGTH
			direction = 1.0
			current_track_index = outbound_track_index
			position.z = TRACK_OFFSETS[current_track_index]
		rotation.y = 0.0 if direction > 0.0 else PI
		_update_passenger_position()

	func _get_crossed_station(previous_x: float, next_x: float) -> Variant:
		var next_station: Variant = null
		for station_x in stop_positions:
			if direction > 0.0 and previous_x < station_x and station_x <= next_x:
				if next_station == null or station_x < next_station:
					next_station = station_x
			elif direction < 0.0 and previous_x > station_x and station_x >= next_x:
				if next_station == null or station_x > next_station:
					next_station = station_x
		return next_station

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

		var hud = get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("show_toast"):
			hud.show_toast("🚇 Bạn đã xuống tàu Metro cao tốc an toàn.")

	func _update_passenger_position() -> void:
		if passenger_ref != null and is_instance_valid(passenger_ref):
			passenger_ref.global_position = global_position + Vector3.UP * 2.5
			passenger_ref.global_rotation.y = global_rotation.y

static func build_central_metro(
	mat_platform: Material,
	mat_rail: Material,
	mat_train: Material,
	mat_accent: Material
) -> Node3D:
	var hub = Node3D.new()
	hub.name = "CentralMetroHub"
	hub.add_to_group("metro_hubs")
	_build_surface_boulevard(hub, mat_platform, mat_accent)
	_build_surface_entrance(hub, mat_platform, mat_accent)

	var floors: Array[Node3D] = []
	for floor_index in range(FLOOR_DEPTHS.size()):
		var metro_floor = _build_underground_floor(floor_index, mat_platform, mat_rail, mat_train, mat_accent)
		hub.add_child(metro_floor)
		floors.append(metro_floor)
		var axis = metro_floor.get_node("DiagonalTrackAxis") as Node3D
		_build_route_stations(hub, metro_floor, axis, floor_index + 1, mat_platform, mat_accent)

	_connect_access_stations(hub, floors)
	return hub

static func _build_surface_boulevard(parent: Node3D, mat_road: Material, mat_accent: Material) -> void:
	var avenue = Node3D.new()
	avenue.name = "SurfaceCentralBoulevard"
	avenue.set_meta("lane_count", 4)
	avenue.set_meta("road_type", "pedestrian_first_urban_avenue")
	parent.add_child(avenue)

	var road = MeshInstance3D.new()
	road.name = "AvenueRoadSurface"
	var road_mesh = BoxMesh.new()
	road_mesh.size = Vector3(700.0, 0.18, 18.0)
	road.mesh = road_mesh
	road.material_override = mat_road
	road.position = Vector3(0.0, 0.1, 230.0)
	avenue.add_child(road)

	var sidewalk_mesh = BoxMesh.new()
	sidewalk_mesh.size = Vector3(700.0, 0.22, 5.0)
	for side in [-1.0, 1.0]:
		var sidewalk = MeshInstance3D.new()
		sidewalk.name = "AvenueSidewalk"
		sidewalk.mesh = sidewalk_mesh
		sidewalk.material_override = mat_accent
		sidewalk.position = Vector3(0.0, 0.2, 230.0 + side * 11.5)
		avenue.add_child(sidewalk)

	var divider_mesh = BoxMesh.new()
	divider_mesh.size = Vector3(700.0, 0.06, 0.18)
	var divider = MeshInstance3D.new()
	divider.name = "AvenueCenterLine"
	divider.mesh = divider_mesh
	divider.material_override = mat_accent
	divider.position = Vector3(0.0, 0.2, 230.0)
	avenue.add_child(divider)

static func _build_surface_entrance(parent: Node3D, mat_wall: Material, mat_sign: Material) -> void:
	var entrance = Node3D.new()
	entrance.name = "CentralMetroEntrance"
	entrance.position = ENTRANCE_POSITION
	entrance.set_meta("below_grade_station", true)
	parent.add_child(entrance)

	var base = MeshInstance3D.new()
	base.name = "MetroEntranceForecourt"
	var base_mesh = BoxMesh.new()
	base_mesh.size = Vector3(16.0, 0.24, 12.0)
	base.mesh = base_mesh
	base.material_override = mat_wall
	base.position.y = 0.12
	entrance.add_child(base)

	for side in [-1.0, 1.0]:
		var pier = MeshInstance3D.new()
		pier.name = "MetroEntrancePier"
		var pier_mesh = BoxMesh.new()
		pier_mesh.size = Vector3(0.8, 4.0, 0.8)
		pier.mesh = pier_mesh
		pier.material_override = mat_sign
		pier.position = Vector3(side * 6.8, 2.0, -4.6)
		entrance.add_child(pier)

	var roof = MeshInstance3D.new()
	roof.name = "MetroEntranceCanopy"
	var roof_mesh = BoxMesh.new()
	roof_mesh.size = Vector3(15.0, 0.45, 4.0)
	roof.mesh = roof_mesh
	roof.material_override = mat_sign
	roof.position = Vector3(0.0, 4.0, -4.6)
	entrance.add_child(roof)

	var sign = _make_label("GA METRO TRUNG TÂM\n4 TẦNG NGẦM • 8 HƯỚNG • TÀU CAO TỐC", Color(0.55, 0.9, 1.0), 24)
	sign.position = Vector3(0.0, 4.8, -4.6)
	entrance.add_child(sign)

	var access = _make_access_station(
		"MetroAccessGroundDown",
		"metro_access_ground",
		"Ga Metro Trung Tâm",
		"🚇 [E] Xuống ga Metro tầng B1",
		Vector3(0.0, 0.0, 1.0)
	)
	entrance.add_child(access)

static func _build_underground_floor(
	floor_index: int,
	mat_platform: Material,
	mat_rail: Material,
	mat_train: Material,
	mat_accent: Material
) -> Node3D:
	var floor_number = floor_index + 1
	var floor = Node3D.new()
	floor.name = "MetroLevel_%02d" % floor_number
	floor.position = Vector3(0.0, -FLOOR_DEPTHS[floor_index], 0.0)
	floor.set_meta("floor_number", floor_number)
	floor.set_meta("axis_angle_degrees", AXIS_ANGLES_DEGREES[floor_index])
	floor.set_meta("tracks_per_axis", TRACK_COUNT_PER_AXIS)
	floor.set_meta("inbound_tracks", 2)
	floor.set_meta("outbound_tracks", 2)

	var axis = Node3D.new()
	axis.name = "DiagonalTrackAxis"
	axis.rotation.y = deg_to_rad(AXIS_ANGLES_DEGREES[floor_index])
	floor.add_child(axis)
	_build_track_axis(axis, floor_number, mat_rail, mat_platform)
	_build_platforms(axis, floor_number, mat_platform, mat_accent)
	_build_access_concourse(floor, floor_number, mat_platform, mat_accent)
	_build_high_speed_trains(axis, floor_number, mat_train, mat_accent)
	return floor

static func _build_track_axis(floor: Node3D, floor_number: int, mat_rail: Material, mat_ballast: Material) -> void:
	var rail_mesh = BoxMesh.new()
	rail_mesh.size = Vector3(ROUTE_HALF_LENGTH * 2.0, 0.16, 0.14)
	var ballast_mesh = BoxMesh.new()
	ballast_mesh.size = Vector3(ROUTE_HALF_LENGTH * 2.0, 0.22, 1.35)

	for track_index in range(TRACK_COUNT_PER_AXIS):
		var track = Node3D.new()
		track.name = "MetroTrack_%02d" % (track_index + 1)
		track.position = Vector3(0.0, -0.48, TRACK_OFFSETS[track_index])
		track.set_meta("direction", "outbound" if track_index < 2 else "inbound")
		floor.add_child(track)

		var ballast = MeshInstance3D.new()
		ballast.name = "TrackBed"
		ballast.mesh = ballast_mesh
		ballast.material_override = mat_ballast
		track.add_child(ballast)

		for rail_side in [-0.78, 0.78]:
			var rail = MeshInstance3D.new()
			rail.name = "RunningRail"
			rail.mesh = rail_mesh
			rail.material_override = mat_rail
			rail.position.z = rail_side
			track.add_child(rail)

static func _build_platforms(floor: Node3D, floor_number: int, mat_platform: Material, mat_accent: Material) -> void:
	var platform_mesh = BoxMesh.new()
	platform_mesh.size = Vector3(72.0, 0.42, 3.4)
	for side in [-1.0, 1.0]:
		var platform = MeshInstance3D.new()
		platform.name = "MetroPlatform"
		platform.mesh = platform_mesh
		platform.material_override = mat_platform
		platform.position = Vector3(0.0, -0.28, side * 8.3)
		floor.add_child(platform)
		_add_box_collision(floor, platform_mesh.size, platform.position)

		var edge = MeshInstance3D.new()
		edge.name = "PlatformSafetyEdge"
		var edge_mesh = BoxMesh.new()
		edge_mesh.size = Vector3(72.0, 0.06, 0.28)
		edge.mesh = edge_mesh
		edge.material_override = mat_accent
		edge.position = Vector3(0.0, -0.04, side * 6.65)
		floor.add_child(edge)

		var axis_names := ["TÂY ⇄ ĐÔNG", "TÂY NAM ⇄ ĐÔNG BẮC", "NAM ⇄ BẮC", "ĐÔNG NAM ⇄ TÂY BẮC"]
		var label = _make_label("B%d • %s • 2 ray mỗi chiều" % [floor_number, axis_names[floor_number - 1]], Color(0.6, 0.92, 1.0), 18)
		label.position = Vector3(side * 25.0, 1.2, side * 10.0)
		floor.add_child(label)

static func _build_route_stations(
	hub: Node3D,
	floor: Node3D,
	axis: Node3D,
	floor_number: int,
	mat_platform: Material,
	mat_accent: Material
) -> void:
	var route_positions: Array[float] = [-18000.0, -10000.0, 10000.0, 18000.0]
	var route_directions := [
		["Tây", "Đông"],
		["Tây Nam", "Đông Bắc"],
		["Nam", "Bắc"],
		["Đông Nam", "Tây Bắc"]
	]
	var platform_mesh = BoxMesh.new()
	platform_mesh.size = Vector3(72.0, 0.42, 3.4)
	var axis_angle = deg_to_rad(AXIS_ANGLES_DEGREES[floor_number - 1])

	for station_index in range(route_positions.size()):
		var route_x = route_positions[station_index]
		var direction_index = 0 if route_x < 0.0 else 1
		var stop_kind = "Ga trung tuyến" if absf(route_x) < ROUTE_HALF_LENGTH else "Ga cuối tuyến"
		var station_title = "%s %s" % [stop_kind, route_directions[floor_number - 1][direction_index]]
		var station_id = "metro_route_b%d_%02d" % [floor_number, station_index + 1]
		var station_site = Node3D.new()
		station_site.name = "MetroRouteStation_B%d_%02d" % [floor_number, station_index + 1]
		station_site.position.x = route_x
		station_site.set_meta("route_position", route_x)
		station_site.set_meta("station_title", station_title)
		axis.add_child(station_site)

		for side in [-1.0, 1.0]:
			var platform = MeshInstance3D.new()
			platform.name = "MetroRoutePlatform"
			platform.mesh = platform_mesh
			platform.material_override = mat_platform
			platform.position = Vector3(0.0, -0.28, side * 8.3)
			station_site.add_child(platform)
			_add_box_collision(station_site, platform_mesh.size, platform.position)

			var board_station = _make_access_station(
				"BoardingPlatform_%s" % ("A" if side < 0.0 else "B"),
				"%s_%s" % [station_id, "a" if side < 0.0 else "b"],
				"Metro B%d • %s" % [floor_number, station_title],
				"🚄 [E] Lên/xuống tàu Metro • %s" % station_title,
				Vector3(0.0, 0.0, side * 8.3)
			)
			board_station.name = "MetroRouteBoard_B%d_%02d_%s" % [floor_number, station_index + 1, "A" if side < 0.0 else "B"]
			board_station.station_type = InteractiveStation.StationType.METRO_PLATFORM
			board_station.set_meta("metro_floor_number", floor_number)
			board_station.set_meta("route_position", route_x)
			station_site.add_child(board_station)

		var underground_access = _make_access_station(
			"MetroRouteAccessUnderground_B%d_%02d" % [floor_number, station_index + 1],
			"%s_underground" % station_id,
			"Metro B%d • Lối lên mặt đất" % floor_number,
			"🚇 [E] Lên mặt đất • %s" % station_title,
			Vector3(-22.0, 0.0, -8.3)
		)
		station_site.add_child(underground_access)

		var world_sx: float = route_x * cos(axis_angle)
		var world_sz: float = -route_x * sin(axis_angle)
		var ground_world_y: float = ModularNatureChunk.get_world_height(world_sx, world_sz)
		var local_surface_y: float = ground_world_y - ModularNatureChunk.PLATEAU_ALTITUDE
		var surface_position = Vector3(world_sx, local_surface_y, world_sz)
		var entrance = Node3D.new()
		entrance.name = "MetroSurfaceEntrance_B%d_%02d" % [floor_number, station_index + 1]
		entrance.position = surface_position
		entrance.set_meta("metro_station_id", station_id)
		hub.add_child(entrance)

		var forecourt = MeshInstance3D.new()
		forecourt.name = "MetroStationForecourt"
		var forecourt_mesh = BoxMesh.new()
		forecourt_mesh.size = Vector3(16.0, 0.24, 12.0)
		forecourt.mesh = forecourt_mesh
		forecourt.material_override = mat_platform
		forecourt.position.y = 0.12
		entrance.add_child(forecourt)

		for side in [-1.0, 1.0]:
			var pillar = MeshInstance3D.new()
			pillar.name = "MetroEntrancePillar"
			var pillar_mesh = BoxMesh.new()
			pillar_mesh.size = Vector3(0.7, 3.5, 0.7)
			pillar.mesh = pillar_mesh
			pillar.material_override = mat_accent
			pillar.position = Vector3(side * 6.5, 1.75, -3.5)
			entrance.add_child(pillar)

		var sign = _make_label("METRO B%d\n%s" % [floor_number, station_title.to_upper()], Color(0.55, 0.9, 1.0), 20)
		sign.position = Vector3(0.0, 4.0, -3.5)
		entrance.add_child(sign)

		var surface_access = _make_access_station(
			"MetroRouteAccessSurface_B%d_%02d" % [floor_number, station_index + 1],
			"%s_surface" % station_id,
			"Ga Metro • %s" % station_title,
			"🚇 [E] Xuống sân ga Metro B%d" % floor_number,
			Vector3.ZERO
		)
		entrance.add_child(surface_access)
		surface_access.set_meta("metro_target_station", underground_access)
		underground_access.set_meta("metro_target_station", surface_access)

static func _build_access_concourse(floor: Node3D, floor_number: int, mat_floor: Material, mat_wall: Material) -> void:
	var concourse = Node3D.new()
	concourse.name = "MetroAccessConcourse"
	concourse.position = Vector3(11.0, -0.5, 70.0)
	concourse.rotation.y = deg_to_rad(9.6)
	floor.add_child(concourse)

	var floor_mesh = BoxMesh.new()
	floor_mesh.size = Vector3(24.0, 0.3, 140.0)
	var concourse_floor = MeshInstance3D.new()
	concourse_floor.name = "ConcourseFloor"
	concourse_floor.mesh = floor_mesh
	concourse_floor.material_override = mat_floor
	concourse.add_child(concourse_floor)
	_add_box_collision(concourse, floor_mesh.size, Vector3.ZERO)

	for side in [-1.0, 1.0]:
		var wall_mesh = BoxMesh.new()
		wall_mesh.size = Vector3(0.35, 3.4, 140.0)
		var wall = MeshInstance3D.new()
		wall.name = "ConcourseWall"
		wall.mesh = wall_mesh
		wall.material_override = mat_wall
		wall.position = Vector3(side * 12.0, 1.7, 0.0)
		concourse.add_child(wall)

	var roof = MeshInstance3D.new()
	roof.name = "ConcourseRoof"
	var roof_mesh = BoxMesh.new()
	roof_mesh.size = Vector3(9.0, 0.28, 140.0)
	roof.mesh = roof_mesh
	roof.material_override = mat_wall
	roof.position.y = 3.4
	concourse.add_child(roof)

	var up_station = _make_access_station(
		"MetroAccessB%dUp" % floor_number,
		"metro_access_b%d_up" % floor_number,
		"Metro B%d • Lối lên" % floor_number,
		"🚇 [E] Đi lên một tầng Metro",
		Vector3(ENTRANCE_POSITION.x - 7.0, 0.0, 136.0)
	)
	floor.add_child(up_station)

	if floor_number < FLOOR_DEPTHS.size():
		var down_station = _make_access_station(
			"MetroAccessB%dDown" % floor_number,
			"metro_access_b%d_down" % floor_number,
			"Metro B%d • Lối xuống" % floor_number,
			"🚇 [E] Đi xuống tầng Metro B%d" % (floor_number + 1),
			Vector3(ENTRANCE_POSITION.x + 7.0, 0.0, 136.0)
		)
		floor.add_child(down_station)

static func _build_high_speed_trains(floor: Node3D, floor_number: int, mat_body: Material, mat_accent: Material) -> void:
	for outbound_track in range(2):
		var train = MetroTrainCar.new()
		train.name = "HighSpeedMetro_B%d_Express_%d" % [floor_number, outbound_track + 1]
		train.add_to_group("metro_trains")
		train.speed = TRAIN_SPEED
		train.outbound_track_index = outbound_track
		train.current_track_index = outbound_track
		train.position = Vector3(-120.0 - float(outbound_track) * 90.0, 0.0, TRACK_OFFSETS[outbound_track])
		floor.add_child(train)

		var body = MeshInstance3D.new()
		body.name = "ExpressTrainBody"
		var body_mesh = BoxMesh.new()
		body_mesh.size = Vector3(18.0, 3.2, 2.3)
		body.mesh = body_mesh
		body.material_override = mat_body
		body.position.y = 1.75
		train.add_child(body)

		var window = MeshInstance3D.new()
		window.name = "PanoramicWindowBand"
		var window_mesh = BoxMesh.new()
		window_mesh.size = Vector3(14.0, 0.8, 2.36)
		window.mesh = window_mesh
		window.material_override = mat_accent
		window.position.y = 2.15
		train.add_child(window)

		var nose = MeshInstance3D.new()
		nose.name = "StreamlinedNose"
		var nose_mesh = BoxMesh.new()
		nose_mesh.size = Vector3(1.2, 2.8, 2.25)
		nose.mesh = nose_mesh
		nose.material_override = mat_body
		nose.position.x = 9.0
		nose.position.y = 1.7
		train.add_child(nose)

		var headlight = OmniLight3D.new()
		headlight.name = "ExpressHeadlight"
		headlight.light_color = Color(0.4, 0.85, 1.0)
		headlight.light_energy = 1.4
		headlight.omni_range = 12.0
		headlight.position = Vector3(9.5, 1.6, 0.0)
		train.add_child(headlight)

	for side in [-1.0, 1.0]:
		var board_station = _make_access_station(
			"MetroPlatformBoard_B%d_%s" % [floor_number, "A" if side < 0.0 else "B"],
			"metro_platform_b%d_%s" % [floor_number, "a" if side < 0.0 else "b"],
			"Ga tàu cao tốc Metro B%d" % floor_number,
			"🚄 [E] Lên tàu cao tốc Metro (144 km/h)",
			Vector3(0.0, 0.0, side * 8.3)
		)
		board_station.station_type = InteractiveStation.StationType.METRO_PLATFORM
		board_station.set_meta("metro_floor_number", floor_number)
		floor.add_child(board_station)

static func _connect_access_stations(hub: Node3D, floors: Array[Node3D]) -> void:
	var ground_station = hub.find_child("MetroAccessGroundDown", true, false) as InteractiveStation
	var first_up = hub.find_child("MetroAccessB1Up", true, false) as InteractiveStation
	if ground_station == null or first_up == null:
		push_error("CentralMetroBuilder: Missing ground or B1 access station.")
		return
	ground_station.set_meta("metro_target_station", first_up)
	first_up.set_meta("metro_target_station", ground_station)

	for floor_index in range(floors.size()):
		var floor_number = floor_index + 1
		var up_station = hub.find_child("MetroAccessB%dUp" % floor_number, true, false) as InteractiveStation
		if up_station == null:
			push_error("CentralMetroBuilder: Missing upward access for B%d." % floor_number)
			continue
		if floor_number > 1:
			var previous_down = hub.find_child("MetroAccessB%dDown" % (floor_number - 1), true, false) as InteractiveStation
			if previous_down != null:
				previous_down.set_meta("metro_target_station", up_station)
				up_station.set_meta("metro_target_station", previous_down)

		if floor_number < floors.size():
			var down_station = hub.find_child("MetroAccessB%dDown" % floor_number, true, false) as InteractiveStation
			var next_up = hub.find_child("MetroAccessB%dUp" % (floor_number + 1), true, false) as InteractiveStation
			if down_station != null and next_up != null:
				down_station.set_meta("metro_target_station", next_up)
				next_up.set_meta("metro_target_station", down_station)

static func _make_access_station(node_name: String, station_id: String, title: String, prompt: String, station_position: Vector3) -> InteractiveStation:
	var station = InteractiveStation.new()
	station.name = node_name
	station.station_type = InteractiveStation.StationType.METRO_ACCESS
	station.station_id = station_id
	station.title_name = title
	station.prompt_text = prompt
	station.interaction_radius = 6.5
	station.position = station_position
	return station

static func _make_label(text: String, color: Color, size: int) -> Label3D:
	var label = Label3D.new()
	label.text = text
	label.font_size = size
	label.modulate = color
	label.outline_size = 7
	label.outline_modulate = Color(0.04, 0.08, 0.12, 0.95)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	return label

static func _add_box_collision(parent: Node3D, size: Vector3, box_position: Vector3) -> void:
	var body = StaticBody3D.new()
	body.name = "MetroWalkableSurface"
	body.collision_layer = 1
	body.collision_mask = 1 | 2
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	collision.position = box_position
	body.add_child(collision)
	parent.add_child(body)
