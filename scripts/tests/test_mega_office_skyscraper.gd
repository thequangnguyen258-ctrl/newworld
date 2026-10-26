extends SceneTree

# ==============================================================================
# TEST AUTOMATION: MEGA OFFICE FOOTPRINT 20X & THÁNH ĐƯỜNG 15 TẦNG
# Tuân thủ nghiêm ngặt:
# - RULE 6: END_TO_END_INTERACTION_TESTING_STANDARD (cảm biến, 3D label, mô phỏng phím vật lý InputEventKey)
# - RULE 7: DUAL_LAYER_SAFETY (Layer 1|2|4, fallback khoảng cách)
# - RULE 8: DIEGETIC_UI_PROMPT_VISIBILITY_STANDARD (Billboard, no_depth_test, outline)
# - RULE 1: VIETNAMESE_IME_INPUT_BULLETPROOFING (physical_keycode & keycode)
# ==============================================================================

const SkyscraperElevatorScript = preload("res://scripts/elevator/elevator.gd")

const TEST_SCENE_PATH := "res://scenes/core/main_world.tscn"

var test_frames: int = 0
var test_step: int = 0
var tram_test_elapsed: float = 0.0

var main_world: Node3D = null
var player: CharacterBody3D = null
var hud: CanvasLayer = null
var skyscraper: Node3D = null
var tram_car: Node3D = null
var tram_stop: InteractiveStation = null
var tram_passenger_initial_position: Vector3 = Vector3.ZERO
var elevator: Node3D = null
var stairwell: Node3D = null
var elevator_travel_position_changed: bool = false
var stair_walk_start_y: float = 0.0
var elevator_travel_started_ms: int = 0
var elevator_queue_test_requested: bool = false
var elevator_queue_test_return_started: bool = false
var elevator_queue_test_intermediate_arrival: bool = false

var ground_y_recorded: float = 0.0

func _init() -> void:
	print("\n================================================================================")
	print("🏛️ KIỂM THỬ TOÀN DIỆN: MEGA OFFICE 15 TẦNG, FOOTPRINT GẤP 20 LẦN")
	print("================================================================================")

func _simulate_key(key_code: Key) -> void:
	var ev_down = InputEventKey.new()
	ev_down.physical_keycode = key_code
	ev_down.keycode = key_code
	ev_down.pressed = true
	if player and is_instance_valid(player):
		player._input(ev_down)
	else:
		Input.parse_input_event(ev_down)

func _set_physical_key(key_code: Key, pressed: bool) -> void:
	var event = InputEventKey.new()
	event.keycode = key_code
	event.physical_keycode = key_code
	event.pressed = pressed
	Input.parse_input_event(event)
	if key_code == KEY_W:
		if pressed:
			Input.action_press("move_forward")
		else:
			Input.action_release("move_forward")

func _process(delta: float) -> bool:
	test_frames += 1
	if test_step == 16:
		tram_test_elapsed += delta

	match test_step:
		0:
			# Nạp main_world
			var scene = load(TEST_SCENE_PATH)
			assert(scene != null, "Không thể nạp main_world.tscn!")
			main_world = scene.instantiate()
			root.add_child(main_world)
			current_scene = main_world

			player = main_world.get_node_or_null("Player") as CharacterBody3D
			hud = main_world.get_node_or_null("HUDOverlay") as CanvasLayer
			skyscraper = main_world.find_child("MegaOfficeSkyscraper", true, false) as Node3D
			var helicopter = main_world.get_node_or_null("Helicopter") as Node3D
			var helipad = main_world.get_node_or_null("CentralCapital/Helipad") as Node3D
			var tram_line = main_world.find_child("TramTrackLine", true, false) as Node3D
			var tram_station = main_world.find_child("CentralTramStation", true, false) as Node3D
			tram_car = main_world.find_child("VintageTram01", true, false) as Node3D
			tram_stop = main_world.find_child("CentralTramStop", true, false) as InteractiveStation

			assert(player != null, "LỖI: Player không tồn tại!")
			assert(hud != null, "LỖI: HUDOverlay không tồn tại!")
			assert(skyscraper != null, "LỖI: MegaOfficeSkyscraper không tồn tại!")
			assert(helicopter != null and helipad != null, "LỖI: Thiếu sân đáp hoặc trực thăng!")
			assert(tram_line != null and tram_station != null and tram_car != null and tram_stop != null, "LỖI: Thiếu tuyến tram trung tâm!")

			print("\n[Bước 0.0] KIỂM TRA BỐ CỤC LỐI VÀO & GIAO THÔNG TRUNG TÂM:")
			var entrance = skyscraper.find_child("MainEntrance", true, false) as Node3D
			var welcome_sign = skyscraper.find_child("MegaOfficeWelcomeSign", true, false) as Label3D
			assert(entrance != null, "Tầng 1 phải có lối cửa chính thông ra quảng trường!")
			assert(welcome_sign != null and "MEGA OFFICE" in welcome_sign.text, "Biển tên tòa nhà phải hiển thị Mega Office!")
			assert(main_world.find_child("TramTrackRing", true, false) == null, "Tuyến tram không được chạy vòng quanh quảng trường!")
			assert(tram_station.global_position.distance_to(skyscraper.global_position) > 250.0, "Ga tram phải nằm ngoài tòa nhà và quảng trường!")
			var plaza = main_world.find_child("PeacePlaza", true, false) as MeshInstance3D
			assert(plaza != null and plaza.mesh is CylinderMesh and is_equal_approx((plaza.mesh as CylinderMesh).top_radius, 250.0), "Quảng trường phải được mở rộng lên bán kính 250m!")
			for amenity_name in ["CentralFountain", "BakeryBooth", "ClinicBooth", "PeaceBellTower", "MayorDeskOffice", "MayorBedSuite", "PetitionsBoard"]:
				var amenity = main_world.find_child(amenity_name, true, false) as Node3D
				assert(amenity != null, "Thiếu tiện ích trung tâm %s!" % amenity_name)
				assert(maxf(absf(amenity.global_position.x), absf(amenity.global_position.z)) > 161.0, "%s bị che bên trong footprint Mega Office!" % amenity_name)
			assert(absf(helicopter.global_position.x - helipad.global_position.x) < 1.0, "Trực thăng phải đỗ trên sân đáp!")
			assert(absf(helicopter.global_position.z - helipad.global_position.z) < 1.0, "Trực thăng phải đỗ trên sân đáp!")
			assert(helipad.get_parent() == main_world.get_node("CentralCapital"), "Sân đáp phải được đặt trong cụm Mega Office!")
			assert(not bool(helipad.get("follow_terrain")), "Sân đáp trên mái không được tự hạ xuống mặt đất!")
			assert(helipad.global_position.x > 100.0 and helipad.global_position.z > 100.0, "Sân đáp phải chiếm riêng một góc Skydeck!")
			assert(absf(helipad.global_position.y - skyscraper.global_position.y - 194.4) < 0.5, "Sân đáp phải nằm trên mái mở tầng 15!")
			var buggy = main_world.get_node_or_null("MayorBuggy") as Node3D
			assert(buggy != null and maxf(absf(buggy.global_position.x), absf(buggy.global_position.z)) > 161.0, "Buggy phải được chuyển ra ngoài footprint Mega Office!")
			assert(absf(helicopter.global_position.y - helipad.global_position.y) < 1.0, "Trực thăng phải đỗ ở cao độ sân thượng!")
			assert(float(tram_car.get("track_end_x")) > float(tram_car.get("track_start_x")), "Tuyến tram phải có lộ trình thẳng hai chiều!")
			assert(tram_stop.station_type == InteractiveStation.StationType.TRAM_STOP, "Ga tram phải có tương tác lên tàu!")
			assert(tram_car.is_in_group("trams"), "Tàu tram phải được đăng ký trong group trams!")
			var flora = main_world.find_child("NatureFlora", true, false) as Node3D
			assert(flora != null, "Thiếu hệ thống thực vật tự nhiên!")
			for scatter_name in ["PineForestMultiMesh", "DeciduousGroveMultiMesh", "WildflowersMultiMesh", "RiverBouldersMultiMesh"]:
				var scatter = flora.find_child(scatter_name, true, false) as MultiMeshInstance3D
				assert(scatter != null and scatter.multimesh != null, "Thiếu cụm thực vật %s!" % scatter_name)
				for instance_index in range(scatter.multimesh.instance_count):
					var instance_position = scatter.multimesh.get_instance_transform(instance_index).origin
					assert(Vector2(instance_position.x - helipad.global_position.x, instance_position.z - helipad.global_position.z).length() > 16.0, "Thực vật mọc trong vùng an toàn sân đáp!")
			print("  ✅ Có cửa chính ra quảng trường, ga tram nằm ngoài quảng trường và sân đáp riêng ngoài tòa nhà.")

			print("\n[Bước 0] KIỂM TRA FOOTPRINT MEGA OFFICE GẤP 80 LẦN VÀ TĂNG CHIỀU CAO:")
			print("  - Vị trí Tòa Nhà: %s" % str(skyscraper.global_position))
			print("  - Tỉ lệ (Scale): %s" % str(skyscraper.scale))
			assert(is_equal_approx(skyscraper.scale.x * skyscraper.scale.z, 80.0), "Diện tích footprint Mega Office phải gấp 80 lần diện tích ban đầu!")
			assert(is_equal_approx(skyscraper.scale.y, 1.0), "Chiều cao tòa nhà phải được nâng bằng cao độ các tầng, không scale Y!")
			var scaled_floor = skyscraper.find_child("Floor_01", true, false) as Node3D
			assert(scaled_floor != null and is_equal_approx(scaled_floor.global_basis.get_scale().x, 8.94427191), "Kích thước sàn phải tăng theo hệ số căn bậc hai của 80!")
			assert(skyscraper.get_meta("occupancy_capacity") == 10000, "Mega Office phải khai báo công suất thiết kế 10.000 người!")
			var holomap_station = skyscraper.find_child("Station_holomap", true, false) as InteractiveStation
			assert(holomap_station != null and holomap_station.global_basis.get_scale().is_equal_approx(Vector3.ONE), "Cảm biến tương tác phải giữ nguyên bán kính sau khi mở rộng tòa nhà!")
			var entrances = skyscraper.find_children("Entrance_*", "Node3D", true, false)
			assert(entrances.size() == 11 and skyscraper.find_child("MainEntrance", true, false) != null, "Tầng 1 phải có ba lối cửa ở mỗi mặt, tổng cộng 12.")
			var stairwells = skyscraper.find_children("ContinuousStairwell*", "Node3D", true, false)
			assert(stairwells.size() == 2, "Phải có hai cầu thang bộ bố trí ở hai góc phía Nam.")
			for stairwell_node in stairwells:
				var stair_flights_for_well = stairwell_node.find_children("Stairs_From_*", "Node3D", true, false)
				assert(stair_flights_for_well.size() == 18, "Mỗi cầu thang phải nối liên tục từ B4 đến tầng 15.")
				assert((stairwell_node as Node3D).global_position.z > 100.0, "Cả hai cầu thang phải nằm ở phía Nam.")
			var privacy_walls = skyscraper.find_children("StairwellPrivacyPartition_*", "StaticBody3D", true, false)
			assert(privacy_walls.size() == 2, "Mỗi cầu thang phía Nam phải có một vách ngăn riêng tư.")
			var glass_corridors = skyscraper.find_children("GlassOfficeCorridor_*", "Node3D", true, false)
			assert(glass_corridors.size() == 2, "Mỗi khu cầu thang phải có một hành lang kính văn phòng.")
			for corridor in glass_corridors:
				assert(corridor.get_meta("floor_count") == 14, "Hành lang kính phải nối các tầng 2 đến 15.")
				assert(corridor.find_child("CorridorFloor_Floor_02", true, false) != null, "Hành lang phải có sàn đi lại riêng.")
				assert(corridor.find_child("CorridorOuterGlassWall", true, false) != null, "Hành lang phải có vách kính ngoài.")
				assert(not corridor.find_children("CorridorOuterMullion", "MeshInstance3D", true, false).is_empty(), "Vách kính phải có khung kim loại.")
			for privacy_wall in privacy_walls:
				var privacy_wall_body := privacy_wall as StaticBody3D
				var side_panel_collision := privacy_wall_body.find_child("PrivacyWallSideCollision", true, false) as CollisionShape3D
				var side_panel := privacy_wall_body.find_child("PrivacyWallSide", true, false) as MeshInstance3D
				assert(privacy_wall_body.get_meta("from_floor") == 2 and privacy_wall_body.get_meta("to_floor") == 15, "Vách ngăn phải chạy từ tầng 2 đến tầng 15.")
				assert(side_panel_collision != null and (side_panel_collision.shape as BoxShape3D).size.y > 177.0, "Vách ngăn phải chạy liên tục dọc các tầng.")
				assert(side_panel != null and side_panel.material_override is StandardMaterial3D and (side_panel.material_override as StandardMaterial3D).transparency == BaseMaterial3D.TRANSPARENCY_ALPHA, "Vách ngăn hành lang phải dùng kính trong.")
				assert(privacy_wall_body.get_meta("door_count") == 14, "Mỗi vách phải có cửa ở từng tầng từ tầng 2 đến tầng 15.")
			var stair_doors = skyscraper.find_children("StairwellDoor_Floor_*", "Node3D", true, false)
			assert(stair_doors.size() == 28, "Hai cầu thang phải có tổng cộng 28 cửa, mỗi tầng từ 2 đến 15.")
			for stair_door_node in stair_doors:
				var stair_door := stair_door_node as DoorController
				assert(stair_door != null and stair_door.auto_open_on_proximity, "Cửa cầu thang phải tự mở khi người chơi đến gần.")
				var stair_door_leaf := stair_door.get_node_or_null("DoorHingePivot/DoorLeaf") as MeshInstance3D
				assert(stair_door_leaf != null and stair_door_leaf.material_override is StandardMaterial3D and (stair_door_leaf.material_override as StandardMaterial3D).transparency == BaseMaterial3D.TRANSPARENCY_ALPHA, "Cửa hành lang phải là cửa kính.")
				var door_trigger := stair_door.get_node("InteractionTrigger") as Area3D
				assert(door_trigger.collision_layer == (1 | 2 | 4) and door_trigger.collision_mask == (1 | 2 | 4), "Cảm biến cửa phải nhận diện đúng các lớp vật lý.")

			var all_elevators = skyscraper.find_children("GlassPanoramaElevator*", "Node3D", true, false)
			assert(all_elevators.size() == 4, "Mega Office phải có bốn thang máy.")
			var elevator_x_positions: Array[float] = []
			for elevator_node in all_elevators:
				var elevator_position := (elevator_node as Node3D).global_position
				elevator_x_positions.append(elevator_position.x)
				assert(elevator_position.z > 100.0, "Cả bốn thang máy phải ở phía Nam, sau cửa chính.")
			elevator_x_positions.sort()
			for elevator_index in range(1, elevator_x_positions.size()):
				assert(elevator_x_positions[elevator_index] - elevator_x_positions[elevator_index - 1] < 8.0, "Bốn thang máy phải đứng cạnh nhau thành một cụm.")
			
			# Kiểm tra toàn bộ 15 tầng, cao độ mới và tầng mái mở.
			print("\n[Bước 0.1] KIỂM TRA 15 TẦNG VÀ CAO ĐỘ ĐƯỢC TĂNG:")
			for f in range(1, 16):
				var floor_name = "Floor_%02d" % f
				var f_node = skyscraper.find_child(floor_name, true, false)
				assert(f_node != null, "Tầng %s phải tồn tại trong SceneTree!" % floor_name)
				var stop_index = SkyscraperElevatorScript.STOP_FLOOR_NUMBERS.find(f)
				assert(is_equal_approx(f_node.position.y, SkyscraperElevatorScript.FLOOR_HEIGHTS[stop_index]), "Cao độ %s không khớp với lịch tầng!" % floor_name)
				print("  ✅ %s: %s (Y = +%.1fm)" % [floor_name, SkyscraperElevatorScript.FLOOR_NAMES[stop_index], f_node.position.y])
			var skydeck = skyscraper.find_child("Floor_15", true, false) as Node3D
			assert(skydeck != null and skydeck.get_meta("open_to_sky", false), "Tầng 15 phải là sân thượng mở nóc!")
			assert(is_equal_approx(skydeck.position.y, 194.0), "Tầng 15 phải cao hơn trước sau khi mỗi tầng được tăng chiều cao!")
			assert(skyscraper.find_child("Basement_B1", true, false) != null and skyscraper.find_child("Basement_B4", true, false) != null, "Mega Office phải có đủ tầng hầm B1–B4!")

			# Kiểm tra Cầu thang bộ thông tầng
			stairwell = skyscraper.find_child("ContinuousStairwell", true, false) as Node3D
			assert(stairwell != null, "Hệ thống Cầu Thang Bộ Thông Tầng (ContinuousStairwell) phải tồn tại!")
			var stair_flights = stairwell.find_children("Stairs_From_*", "Node3D", true, false)
			print("  ✅ Mỗi cầu thang bộ có %d chặng nối từ B4 lên Tầng 15." % stair_flights.size())
			assert(stair_flights.size() == 18, "Cầu thang phải nối liên tục 4 tầng hầm và 15 tầng nổi!")
			assert(stairwell.find_child("Stairs_From_-40_To_-30", true, false) != null, "Cầu thang bộ phải nối được từ B4 lên B3!")
			for section_index in range(stair_flights.size() - 1):
				var current_section = stair_flights[section_index] as Node3D
				var next_section = stair_flights[section_index + 1] as Node3D
				var current_landings = current_section.find_children("StairLanding_*", "MeshInstance3D", true, false)
				var next_ramps = next_section.find_children("StairRampCollider*", "StaticBody3D", true, false)
				assert(not current_landings.is_empty() and not next_ramps.is_empty(), "Mỗi tầng phải có chiếu nghỉ nối với nhịp thang kế tiếp!")
				var landing = current_landings.back() as MeshInstance3D
				var next_ramp_shape = (next_ramps[0] as StaticBody3D).get_child(0) as CollisionShape3D
				var next_ramp_box = next_ramp_shape.shape as BoxShape3D
				var ramp_half_length = next_ramp_box.size.z * 0.5
				var ramp_axis = next_ramp_shape.global_basis.z.normalized()
				var ramp_endpoint_a = next_ramp_shape.global_position + ramp_axis * ramp_half_length
				var ramp_endpoint_b = next_ramp_shape.global_position - ramp_axis * ramp_half_length
				var lower_ramp_endpoint = ramp_endpoint_a if ramp_endpoint_a.y < ramp_endpoint_b.y else ramp_endpoint_b
				var landing_top_y = landing.global_position.y + (landing.mesh as BoxMesh).size.y * 0.5
				assert(absf(landing.global_position.z - lower_ramp_endpoint.z) < 0.35, "Chiếu nghỉ tầng %d phải gặp đầu dưới của nhịp thang kế tiếp!" % section_index)
				assert(absf(landing.global_position.x - lower_ramp_endpoint.x) <= (landing.mesh as BoxMesh).size.x * 0.5 + 0.35, "Chiếu nghỉ phải phủ kín lối nối giữa hai nhịp cầu thang!")
				assert(absf(landing_top_y - lower_ramp_endpoint.y) < 0.35, "Cao độ chiếu nghỉ phải khớp với nhịp cầu thang kế tiếp!")

			# Kiểm tra Thang máy kính Panorama
			elevator = skyscraper.find_child("GlassPanoramaElevator", true, false) as Node3D
			assert(elevator != null, "Thang Máy Kính Panorama (GlassPanoramaElevator) phải tồn tại!")
			assert(elevator is AnimatableBody3D, "Node gốc của thang máy phải là AnimatableBody3D.")
			assert(elevator.FLOOR_HEIGHTS.size() == 19 and elevator.STOP_FLOOR_NUMBERS.size() == 19, "Thang máy phải phục vụ từ B4 đến Tầng 15!")
			assert(is_equal_approx(elevator.TRAVEL_SPEED, 8.0), "Thang máy phải chạy chậm hơn gấp 3 lần, ở tốc độ 8m/s!")
			assert(elevator.elevator_car == elevator, "Cabin chuyển động phải chính là node gốc AnimatableBody3D.")
			print("  ✅ Bốn thang máy liền kề ở phía Nam phục vụ đủ B4–B1 và Tầng 1–15.")

			# Đếm số lượng NPC làm việc trong tòa nhà
			var npc_count: int = 0
			for child in skyscraper.find_children("NPC_*", "Node3D", true, false):
				npc_count += 1
			print("  ✅ Tổng số NPC Anime đại diện các Ban ngành đang làm việc: %d NPC (Yêu cầu >= 30)" % npc_count)
			assert(npc_count >= 30, "Phải có từ 30 NPC làm việc trở lên trong đại cao ốc!")

			test_step = 20
			test_frames = 0

		20:
			if test_frames < 10:
				return false
			var stair_door := skyscraper.find_child("StairwellDoor_Floor_02", true, false) as DoorController
			assert(stair_door != null, "Cửa cầu thang tầng 2 phải tồn tại.")
			player.global_position = stair_door.global_position + Vector3(0.8, 0.0, 0.0)
			player.velocity = Vector3.ZERO
			test_step = 21
			test_frames = 0

		21:
			if test_frames < 8:
				return false
			var stair_door := skyscraper.find_child("StairwellDoor_Floor_02", true, false) as DoorController
			assert(stair_door.is_open, "Cảm biến Area3D phải tự mở cửa khi Player thực sự bước vào cự ly.")
			print("  ✅ Cửa cầu thang tầng 2 tự mở khi Player tiếp cận qua cảm biến.")
			test_step = 1
			test_frames = 0

		1:
			if test_frames < 10:
				return false
			var entrance = skyscraper.find_child("MainEntrance", true, false) as Node3D
			var center_entrances: Array[Node3D] = [
				entrance,
				skyscraper.find_child("Entrance_North_2", true, false) as Node3D,
				skyscraper.find_child("Entrance_East_2", true, false) as Node3D,
				skyscraper.find_child("Entrance_West_2", true, false) as Node3D
			]
			var outward_directions: Array[Vector3] = [
				Vector3(0.0, 0.0, 1.0),
				Vector3(0.0, 0.0, -1.0),
				Vector3(1.0, 0.0, 0.0),
				Vector3(-1.0, 0.0, 0.0)
			]
			for entrance_index in range(center_entrances.size()):
				assert(center_entrances[entrance_index] != null, "Mỗi mặt tòa nhà phải có một cửa giữa.")
				var ray_start = center_entrances[entrance_index].global_position + outward_directions[entrance_index] * 6.0 + Vector3.UP * 2.0
				var ray_end = center_entrances[entrance_index].global_position - outward_directions[entrance_index] * 8.0 + Vector3.UP * 2.0
				var ray_query = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
				ray_query.collision_mask = 1
				var entrance_hit = main_world.get_world_3d().direct_space_state.intersect_ray(ray_query)
				assert(entrance_hit.is_empty(), "Cửa giữa ở mỗi mặt phải thông thoáng để người chơi đi ra/vào!")
			assert(tram_car.position.x >= float(tram_car.get("track_start_x")) and tram_car.position.x <= float(tram_car.get("track_end_x")), "Xe tram phải nằm trên tuyến thẳng!")
			assert(absf(tram_car.position.z - float(tram_car.get("track_z"))) < 0.1, "Xe tram phải giữ đúng tim tuyến!")
			print("  ✅ Kiểm tra vật lý xác nhận cửa giữa ở cả bốn mặt đều thông thoáng.")
			print("\n[Bước 1] NGƯỜI CHƠI TIẾP CẬN ĐẠI SẢNH TẦNG 1 & QUẦY DỊCH VỤ CÔNG 1 CỬA:")
			var f1 = skyscraper.find_child("Floor_01", true, false)
			var counter = f1.find_child("Station_desk_civic_counter", true, false) as InteractiveStation
			assert(counter != null, "Quầy Một Cửa (Station_desk_civic_counter) phải tồn tại!")
			
			player.global_position = counter.global_position + Vector3(0.0, 0.2, 1.6)
			ground_y_recorded = player.global_position.y
			print("  - Vị trí Player tại Tầng 1: %s (Cao độ: %.1fm)" % [str(player.global_position), ground_y_recorded])
			test_step = 2
			test_frames = 0

		2:
			if test_frames < 10:
				return false
			var f1 = skyscraper.find_child("Floor_01", true, false)
			var counter = f1.find_child("Station_desk_civic_counter", true, false) as InteractiveStation
			var dist = player.global_position.distance_to(counter.global_position)
			print("  - Cự ly tới Quầy Một Cửa: %.2fm (Bán kính: %.1fm)" % [dist, counter.interaction_radius])
			assert(dist <= counter.interaction_radius, "Người chơi phải ở trong cự ly tương tác Quầy Một Cửa!")
			assert(counter.prompt_label.visible == true, "Nhãn tương tác 3D Billboard của Quầy Một Cửa phải hiển thị!")

			hud.last_toast_message = ""
			_simulate_key(KEY_E)
			print("  ✅ Tương tác Quầy Một Cửa thành công! Toast: '%s'" % hud.last_toast_message)
			assert("quầy dịch vụ công một cửa" in hud.last_toast_message.to_lower() or "hồ sơ" in hud.last_toast_message.to_lower(), "Toast Quầy Một Cửa phải kích hoạt!")

			test_step = 3
			test_frames = 0

		3:
			if test_frames < 10:
				return false
			print("\n[Bước 2] DI CHUYỂN TỚI THANG MÁY KÍNH PANORAMA & MỞ BẢNG ĐIỀU KHIỂN:")
			player.global_position = elevator.global_position + Vector3(0.0, 0.4, 2.0)
			test_step = 4
			test_frames = 0

		4:
			if test_frames < 10:
				return false
			var dist_ele = Vector2(player.global_position.x - elevator.global_position.x, player.global_position.z - elevator.global_position.z).length()
			print("  - Cự ly tới Thang Máy Kính: %.2fm (Bán kính: %.1fm)" % [dist_ele, elevator.interaction_radius])
			assert(dist_ele <= elevator.interaction_radius, "Player phải ở trong cự ly thang máy kính!")
			assert(elevator.prompt_label.visible == true, "Nhãn nhắc 3D Thang Máy Kính phải hiển thị!")

			# Kiểm tra mở UI Modal bảng điều khiển thang máy bằng phím [E]
			_simulate_key(KEY_E)
			assert(elevator.ui_modal != null and elevator.ui_modal.visible == true, "Bảng điều khiển Thang Máy 15 Tầng phải mở lên!")
			print("  ✅ Bảng điều khiển Thang Máy Kính (ElevatorModal) đã mở lên với 15 nút chọn tầng!")

			test_step = 5
			test_frames = 0

		5:
			if test_frames < 10:
				return false
			print("\n[Bước 3] THANG MÁY DI CHUYỂN DẦN LÊN TẦNG 11:")
			elevator_travel_position_changed = false
			elevator_queue_test_requested = false
			elevator_queue_test_return_started = false
			elevator_queue_test_intermediate_arrival = false
			elevator_travel_started_ms = Time.get_ticks_msec()
			elevator.request_floor(player, 11)
			test_step = 6
			test_frames = 0

		6:
			if elevator.is_travelling and not elevator_queue_test_requested and not is_zero_approx(elevator.position.y):
				elevator.request_floor(player, 2)
				elevator_queue_test_requested = true
			if elevator_queue_test_requested and elevator.current_floor_number == 11:
				elevator_queue_test_intermediate_arrival = true
			if not elevator.is_travelling and elevator_queue_test_requested and not elevator_queue_test_return_started and elevator.current_floor_number == 2:
				assert(elevator_queue_test_intermediate_arrival, "Thang máy phải hoàn tất điểm đến ban đầu trước khi phục vụ tầng đã xếp hàng.")
				elevator.request_floor(player, 11)
				elevator_queue_test_return_started = true
				elevator_travel_started_ms = Time.get_ticks_msec()
				return false
			if elevator.is_travelling:
				elevator_travel_position_changed = elevator_travel_position_changed or not is_zero_approx(elevator.elevator_car.position.y)
				var cabin_position = elevator.elevator_car.to_local(player.global_position)
				assert(absf(cabin_position.x) < 1.0 and absf(cabin_position.z) < 1.0, "Player phải luôn nằm bên trong cabin trong lúc thang máy chạy!")
				assert(player.get_parent() == elevator.elevator_car, "Player phải được gắn với cabin trong suốt hành trình!")
				var cabin_floor_collision = elevator.elevator_car.get_node("CabinFloorCollider") as CollisionShape3D
				var cabin_floor_box = cabin_floor_collision.shape as BoxShape3D
				var cabin_floor_top = cabin_floor_collision.position.y + cabin_floor_box.size.y * 0.5
				assert(absf(elevator.PLAYER_CABIN_FLOOR_OFFSET - cabin_floor_top - 0.02) < 0.001, "Offset player phải giữ khe hở 2cm trên mặt sàn cabin!")
				assert(absf(cabin_position.y - elevator.PLAYER_CABIN_FLOOR_OFFSET) < 0.08, "Player phải đứng đúng offset sàn trong lúc cabin di chuyển!")
				assert(Time.get_ticks_msec() - elevator_travel_started_ms < 120000, "Thang máy không hoàn tất hành trình lên Tầng 11!")
				return false
			assert(elevator_travel_position_changed, "Thang máy phải di chuyển dần qua trục, không dịch chuyển tức thời!")
			if test_frames < 10:
				return false
			assert(elevator.current_floor_number == 11, "Thang máy phải quay lại tầng 11 sau khi phục vụ yêu cầu tầng 2 được xếp hàng.")
			assert(elevator.floor_request_queue.is_empty(), "Hàng đợi tầng phải được xóa sau khi phục vụ xong.")
			assert(elevator.are_doors_open, "Cửa thang máy phải mở khi đã đến tầng.")
			assert(player.get_parent() != elevator.elevator_car, "Player phải được trả về node cha ban đầu sau khi đến tầng!")
			var cabin_position = elevator.elevator_car.to_local(player.global_position)
			assert(absf(cabin_position.x) < 1.0 and absf(cabin_position.z) < 1.0, "Player phải đứng bên trong cabin sau khi đến Tầng 11!")
			assert(absf(cabin_position.y - 0.32) < 0.08, "Player phải đứng trên sàn cabin ở Tầng 11, không bị lơ lửng!")
			var y_f11 = player.global_position.y
			var floor_11_index = SkyscraperElevatorScript.STOP_FLOOR_NUMBERS.find(11)
			var expected_y_f11 = ground_y_recorded + SkyscraperElevatorScript.FLOOR_HEIGHTS[floor_11_index] + 0.32
			print("  - Cao độ tại Tầng 11: %.2fm (Kỳ vọng: ~%.1fm)" % [y_f11, expected_y_f11])
			assert(abs(y_f11 - expected_y_f11) < 3.0, "Người chơi phải có mặt tại Tầng 11 Thánh Đường Hội Lễ!")

			# Khảo sát Bàn Thờ & Bục Giảng Thánh Đường
			var f11 = skyscraper.find_child("Floor_11", true, false)
			var altar = f11.find_child("Station_desk_sanctuary_liturgy", true, false) as InteractiveStation
			assert(altar != null, "Bàn Thờ & Bục Giảng Thánh Đường (Station_desk_sanctuary_liturgy) phải tồn tại!")
			
			player.global_position = altar.global_position + Vector3(0.0, 0.2, 1.6)
			test_step = 7
			test_frames = 0

		7:
			if test_frames < 10:
				return false
			var f11 = skyscraper.find_child("Floor_11", true, false)
			var altar = f11.find_child("Station_desk_sanctuary_liturgy", true, false) as InteractiveStation
			var dist_altar = player.global_position.distance_to(altar.global_position)
			print("  - Cự ly tới Bàn Thờ Thánh Đường: %.2fm" % dist_altar)
			assert(dist_altar <= altar.interaction_radius, "Player phải ở gần Bàn Thờ Thánh Đường!")
			
			hud.last_toast_message = ""
			_simulate_key(KEY_E)
			print("  ✅ Tương tác Bàn Thờ Thánh Đường thành công! Toast: '%s'" % hud.last_toast_message)
			assert("thánh lễ" in hud.last_toast_message.to_lower() or "phụng vụ" in hud.last_toast_message.to_lower() or "thánh đường" in hud.last_toast_message.to_lower(), "Toast Thánh Lễ phải kích hoạt!")

			test_step = 8
			test_frames = 0

		8:
			if test_frames < 10:
				return false
			print("\n[Bước 4] THANG MÁY DI CHUYỂN LÊN SKYDECK MỞ TRỜI:")
			elevator_travel_position_changed = false
			elevator_travel_started_ms = Time.get_ticks_msec()
			elevator.request_floor(player, 15)
			test_step = 9
			test_frames = 0

		9:
			if elevator.is_travelling:
				elevator_travel_position_changed = elevator_travel_position_changed or not is_equal_approx(elevator.elevator_car.position.y, 134.0)
				assert(Time.get_ticks_msec() - elevator_travel_started_ms < 120000, "Thang máy không hoàn tất hành trình lên Skydeck!")
				return false
			assert(elevator_travel_position_changed, "Thang máy phải tiếp tục di chuyển liên tục tới Tầng 15!")
			if test_frames < 10:
				return false
			var cabin_position = elevator.elevator_car.to_local(player.global_position)
			assert(absf(cabin_position.x) < 1.0 and absf(cabin_position.z) < 1.0, "Player phải đứng trong cabin trên Skydeck!")
			assert(absf(cabin_position.y - 0.32) < 0.08, "Player phải đứng trên sàn cabin khi đến Skydeck!")
			var y_f15 = player.global_position.y
			var floor_15_index = SkyscraperElevatorScript.STOP_FLOOR_NUMBERS.find(15)
			var expected_y_f15 = ground_y_recorded + SkyscraperElevatorScript.FLOOR_HEIGHTS[floor_15_index] + 0.32
			print("  - Cao độ tại Tầng 15 Skydeck: %.2fm (Kỳ vọng: ~%.1fm)" % [y_f15, expected_y_f15])
			assert(abs(y_f15 - expected_y_f15) < 3.0, "Người chơi phải có mặt tại Tầng 15 Skydeck!")

			# Tương tác quầy Cloud Cafe
			var f15 = skyscraper.find_child("Floor_15", true, false)
			var cafe = f15.find_child("Station_station_cloud_cafe", true, false) as InteractiveStation
			assert(cafe != null, "Quán Cà Phê Mây Trời (Station_station_cloud_cafe) phải tồn tại trên Skydeck!")

			player.global_position = cafe.global_position + Vector3(0.0, 0.2, 1.6)
			test_step = 10
			test_frames = 0

		10:
			if test_frames < 10:
				return false
			var f15 = skyscraper.find_child("Floor_15", true, false)
			var cafe = f15.find_child("Station_station_cloud_cafe", true, false) as InteractiveStation
			var dist_cafe = player.global_position.distance_to(cafe.global_position)
			print("  - Cự ly tới Cloud Cafe Skydeck: %.2fm" % dist_cafe)
			assert(dist_cafe <= cafe.interaction_radius, "Player phải ở gần Cloud Cafe Skydeck!")

			hud.last_toast_message = ""
			_simulate_key(KEY_E)
			print("  ✅ Thưởng thức Cà phê ngắm mây thành công! Toast: '%s'" % hud.last_toast_message)
			assert("cloud cafe" in hud.last_toast_message.to_lower() or "cà phê" in hud.last_toast_message.to_lower(), "Toast Cà Phê Mây Trời phải kích hoạt!")

			test_step = 11
			test_frames = 0

		11:
			if test_frames < 10:
				return false
			print("\n[Bước 5] HẠ THANG MÁY LIÊN TỤC VỀ TẦNG 1:")
			elevator_travel_position_changed = false
			elevator_travel_started_ms = Time.get_ticks_msec()
			elevator.request_floor(player, 1)
			test_step = 12
			test_frames = 0

		12:
			if elevator.is_travelling:
				elevator_travel_position_changed = elevator_travel_position_changed or not is_equal_approx(elevator.elevator_car.position.y, 194.0)
				assert(Time.get_ticks_msec() - elevator_travel_started_ms < 120000, "Thang máy không hoàn tất hành trình về Tầng 1!")
				return false
			assert(elevator_travel_position_changed, "Thang máy phải chuyển động khi đi xuống Tầng 1!")
			if test_frames < 10:
				return false
			var return_y = player.global_position.y
			print("  - Cao độ sau khi hạ thang máy về sảnh: %.2fm" % return_y)
			assert(abs(return_y - ground_y_recorded - 0.32) < 3.0, "Người chơi phải trở về Đại Sảnh Tầng 1 an toàn!")
			print("  ✅ Thang máy hạ xuống Sảnh Tầng 1; tiếp tục kiểm tra B4.")
			elevator_travel_position_changed = false
			elevator_travel_started_ms = Time.get_ticks_msec()
			elevator.request_floor(player, -4)
			test_step = 18
			test_frames = 0

		13:
			if test_frames < 10:
				return false
			print("\n[Bước 6] KIỂM TRA ĐI BỘ TRÊN CẦU THANG BỘ THÔNG TẦNG (CONTINUOUS STAIRS):")
			var flight_1 = stairwell.find_child("Stairs_From_0_To_17", true, false) as Node3D
			assert(flight_1 != null, "Nhịp thang Tầng 1 lên Tầng 2 phải tồn tại!")
			var ramp_body = flight_1.find_child("StairRampCollider", true, false) as StaticBody3D
			assert(ramp_body != null, "Cầu thang phải có mặt dốc liên tục bên dưới các bậc!")
			var ramp_shape = ramp_body.get_child(0) as CollisionShape3D
			assert(ramp_shape != null and absf(ramp_shape.rotation.x) <= deg_to_rad(60.0), "Độ dốc cầu thang phải nằm trong giới hạn đi bộ của CharacterBody3D!")
			assert(is_equal_approx((ramp_shape.shape as BoxShape3D).size.x, 5.6), "Mỗi nhịp cầu thang phải rộng gấp đôi, đạt 5.6m!")
			var guardrails = flight_1.find_children("StairGuardrail_*", "MeshInstance3D", true, false)
			assert(guardrails.size() >= 2, "Mỗi nhịp cầu thang phải có lan can hai bên!")
			var landings = flight_1.find_children("StairLanding_*", "MeshInstance3D", true, false)
			assert(landings.size() > 0, "Cầu thang phải có chiếu nghỉ giữa các nhịp!")
			for landing_node in landings:
				var landing_mesh = (landing_node as MeshInstance3D).mesh as BoxMesh
				assert(is_equal_approx(landing_mesh.size.x, 11.4), "Chiếu nghỉ phải bắc kín cả hai nhịp thang rộng gấp đôi!")
				assert(is_equal_approx(landing_mesh.size.z, 4.0), "Chiếu nghỉ phải sâu tối thiểu 4m để có lối chuyển hướng an toàn!")
			var landing_guardrails = flight_1.find_children("StairLandingGuardrail_*", "MeshInstance3D", true, false)
			assert(landing_guardrails.size() == landings.size() * 2, "Mỗi chiếu nghỉ phải có lan can hai bên!")
			var landing_rail_colliders = flight_1.find_children("StairLandingGuardrailCollision_*", "StaticBody3D", true, false)
			assert(landing_rail_colliders.size() == landing_guardrails.size(), "Lan can chiếu nghỉ phải có collider an toàn!")
			var treads = flight_1.find_children("Tread_*", "MeshInstance3D", true, false)
			assert(treads.size() >= 10, "Cầu thang phải có các bậc thật, không chỉ là một mặt dốc.")
			assert(ramp_body.collision_layer & 1 == 1, "Mặt dốc cầu thang phải nằm trên collision layer của người chơi!")

			var ramp = ramp_shape.shape as BoxShape3D
			var uphill_direction = ramp_shape.global_basis.z.normalized()
			if uphill_direction.y < 0.0:
				uphill_direction = -uphill_direction
			player.global_rotation.y = PI if uphill_direction.z > 0.0 else 0.0
			player.global_position = ramp_shape.global_position - uphill_direction * (ramp.size.z * 0.5 - 0.8) + Vector3.UP * 0.1
			player.velocity = Vector3.ZERO
			test_step = 14
			test_frames = 0

		14:
			if test_frames < 10:
				return false
			if test_frames == 10:
				stair_walk_start_y = player.global_position.y
				_set_physical_key(KEY_W, true)
			if test_frames < 55:
				return false
			_set_physical_key(KEY_W, false)
			var stair_p_y = player.global_position.y
			print("  - Vị trí Player trên cầu thang bộ: %s (Cao độ: %.1fm)" % [str(player.global_position), stair_p_y])
			var last_stair_collision = player.get_last_slide_collision()
			if stair_p_y <= stair_walk_start_y + 0.5:
				push_error("Player không thể đi bộ lên cầu thang bằng phím vật lý [W]. Bắt đầu: %.2fm, kết thúc: %.2fm." % [stair_walk_start_y, stair_p_y])
				quit(1)
				return true
			assert(player.is_on_floor(), "Player phải vẫn được cầu thang đỡ sau khi đi bộ lên!")
			assert(last_stair_collision != null, "Player phải có va chạm sàn khi đi bộ trên cầu thang!")
			print("  ✅ Player đi bộ thật trên bậc thang bằng phím [W], tăng cao độ %.1fm." % (stair_p_y - stair_walk_start_y))

			tram_car.position.x = 0.0
			tram_car.set("dwell_remaining", 0.5)
			tram_car.set("direction", 1.0)
			player.global_position = tram_stop.global_position
			test_step = 15
			test_frames = 0

		15:
			if test_frames < 10:
				return false
			assert(tram_stop.player_in_range, "Cảm biến ga tram phải nhận diện người chơi!")
			assert(tram_stop.prompt_label.visible, "Ga tram phải hiện bảng nhắc tương tác!")
			assert(tram_car.global_position.distance_to(tram_stop.global_position) <= 8.0, "Tàu phải đang ở ga khi người chơi lên tàu!")
			tram_passenger_initial_position = player.global_position
			print("\n[Bước 7] NGƯỜI CHƠI LÊN TRAM TỪ GA BẰNG PHÍM [E]:")
			_simulate_key(KEY_E)
			tram_test_elapsed = 0.0
			test_step = 16
			test_frames = 0

		16:
			if tram_test_elapsed < 1.5:
				return false
			assert(tram_car.get("passenger_ref") == player, "Tram phải nhận người chơi sau tương tác từ ga!")
			assert(not player.visible, "Người chơi phải vào trong tram!")
			assert(tram_car.position.x > 1.0, "Tram phải chạy dọc tuyến sau khi đón khách!")
			assert(player.global_position.distance_to(tram_passenger_initial_position) > 1.0, "Người chơi phải được chở đi cùng tram!")
			assert(player.global_position.distance_to(tram_car.global_position) < 2.0, "Vị trí người chơi phải bám theo tram đang chạy!")
			print("  ✅ Người chơi đã lên tàu từ cảm biến ga và được chở theo tuyến.")
			_simulate_key(KEY_F)
			test_step = 17
			test_frames = 0

		17:
			assert(tram_car.get("passenger_ref") == null, "Tram phải thả người chơi sau khi nhấn [F]!")
			assert(player.visible, "Người chơi phải hiện lại khi xuống tram!")
			assert(player.is_physics_processing(), "Điều khiển người chơi phải được khôi phục sau khi xuống tram!")
			assert(not player.has_meta("occupied_tram"), "Trạng thái đang ngồi tram phải được xóa!")
			print("  ✅ Người chơi xuống tram bằng phím [F] và nhận lại điều khiển.")

			print("\n================================================================================")
			print("🎉 KIỂM THỬ MEGA OFFICE, 4 THANG MÁY, TẦNG HẦM, CẦU THANG, TRAM VÀ SÂN ĐÁP PASS!")
			print("================================================================================")
			quit(0)
			return true

		18:
			if elevator.is_travelling:
				assert(Time.get_ticks_msec() - elevator_travel_started_ms < 120000, "Thang máy không xuống tầng hầm B4!")
				return false
			var floor_b4_index = SkyscraperElevatorScript.STOP_FLOOR_NUMBERS.find(-4)
			var cabin_position = elevator.elevator_car.to_local(player.global_position)
			assert(absf(cabin_position.x) < 1.0 and absf(cabin_position.z) < 1.0, "Player phải còn trong cabin tại B4!")
			assert(absf(cabin_position.y - 0.32) < 0.08, "Player phải đứng trên sàn cabin tại B4!")
			assert(absf(player.global_position.y - (ground_y_recorded + SkyscraperElevatorScript.FLOOR_HEIGHTS[floor_b4_index] + 0.32)) < 2.0, "Thang máy phải đưa người chơi xuống đúng cao độ B4!")
			assert(not player.has_meta("occupied_elevator") and player.is_physics_processing(), "Điều khiển Player phải được khôi phục sau khi đến tầng hầm.")
			print("  ✅ Thang máy chạy tới B4, dừng đúng tầng và trả lại quyền điều khiển.")
			elevator_travel_started_ms = Time.get_ticks_msec()
			elevator.request_floor(player, 1)
			test_step = 19
			test_frames = 0

		19:
			if elevator.is_travelling:
				assert(Time.get_ticks_msec() - elevator_travel_started_ms < 120000, "Thang máy không trở lại tầng 1 sau khi rời B4!")
				return false
			assert(absf(player.global_position.y - ground_y_recorded - 0.32) < 2.0, "Người chơi phải về đúng cao độ Tầng 1 sau B4.")
			test_step = 13
			test_frames = 0

	return false
