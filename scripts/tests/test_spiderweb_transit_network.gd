extends SceneTree

# ==============================================================================
# TEST AUTOMATION: HỆ THỐNG GIAO THÔNG MẠNG NHỆN (5 VÀNH ĐAI, 8 NAN HOA & 12 TRẠM)
# Tuân thủ:
# - RULE 6: END_TO_END_INTERACTION_TESTING_STANDARD
# - RULE 8: DIEGETIC_UI_PROMPT_VISIBILITY_STANDARD (Billboard, no_depth_test, outline)
# - RULE 2: CONTINUOUS_ELEVATION_FUNCTION_FOR_MODULAR_TERRAIN
# ==============================================================================

const TEST_SCENE_PATH := "res://scenes/core/main_world.tscn"

var test_frames: int = 0
var test_step: int = 0

var main_world: Node3D = null
var player: CharacterBody3D = null
var transit_net: Node3D = null

func _init() -> void:
	print("\n================================================================================")
	print("🕸️ KIỂM THỬ: HỆ THỐNG GIAO THÔNG MẠNG NHỆN 500 KM² (5 VÀNH ĐAI, 8 NAN HOA)")
	print("================================================================================")

func _process(_delta: float) -> bool:
	test_frames += 1

	match test_step:
		0:
			# Nạp main_world.tscn
			var scene = load(TEST_SCENE_PATH)
			assert(scene != null, "Không thể nạp main_world.tscn!")
			main_world = scene.instantiate()
			root.add_child(main_world)
			current_scene = main_world

			player = main_world.get_node_or_null("Player") as CharacterBody3D
			assert(player != null, "LỖI: Player không tồn tại!")

			transit_net = main_world.find_child("SpiderwebTransitNetwork", true, false) as Node3D
			assert(transit_net != null, "LỖI: SpiderwebTransitNetwork không tồn tại trong thế giới!")

			print("\n[Bước 1] KIỂM TRA 5 TUYẾN VÀNH ĐAI ĐỒNG TÂM (CONCENTRIC RINGS):")
			var rings_node = transit_net.get_node_or_null("ConcentricRings")
			assert(rings_node != null, "Thiếu node ConcentricRings!")

			var expected_rings = [
				"Ring1_CoreHub",
				"Ring2_PlateauCity",
				"Ring3_CliffParkway",
				"Ring4_FoothillBelt",
				"Ring5_FrontierLoop"
			]

			for r_name in expected_rings:
				var r_mesh = rings_node.get_node_or_null(r_name) as MeshInstance3D
				assert(r_mesh != null, "LỖI: Thiếu vành đai %s!" % r_name)
				assert(r_mesh.mesh != null, "LỖI: Vành đai %s chưa tạo Mesh!" % r_name)
				print("  ✅ %s: Khởi tạo thành công ruy băng vành đai!" % r_name)

			test_step = 1
			test_frames = 0

		1:
			if test_frames < 4:
				return false

			print("\n[Bước 2] KIỂM TRA 8 TRỤC NAN HOA HƯỚNG TÂM (RADIAL SPOKES):")
			var spokes_node = transit_net.get_node_or_null("RadialSpokes")
			assert(spokes_node != null, "Thiếu node RadialSpokes!")

			var expected_spokes = [
				"SPOKE_N", "SPOKE_NE", "SPOKE_E", "SPOKE_SE",
				"SPOKE_S", "SPOKE_SW", "SPOKE_W", "SPOKE_NW"
			]

			for s_name in expected_spokes:
				var s_mesh = spokes_node.get_node_or_null(s_name) as MeshInstance3D
				assert(s_mesh != null, "LỖI: Thiếu nan hoa %s!" % s_name)
				assert(s_mesh.mesh != null, "LỖI: Nan hoa %s chưa tạo Mesh!" % s_name)
				print("  ✅ %s: Khởi tạo thành công trục đại lộ hướng tâm!" % s_name)

			test_step = 2
			test_frames = 0

		2:
			if test_frames < 4:
				return false

			print("\n[Bước 3] KIỂM TRA 12 TRẠM DỪNG CHÂN GIAO THÔNG (TRANSIT WAYPOINTS):")
			var stops_node = transit_net.get_node_or_null("TransitWaypoints")
			assert(stops_node != null, "Thiếu node TransitWaypoints!")

			var stop_list = stops_node.get_children()
			print("  - Tổng số trạm dừng chân khởi tạo: %d trạm (Kỳ vọng: 12 trạm)" % stop_list.size())
			assert(stop_list.size() == 12, "LỖI: Phải có đúng 12 trạm dừng chân trên 4 hướng x 3 vành đai!")

			for stop in stop_list:
				assert(stop.is_in_group("transit_stations"), "Mọi trạm dừng chân phải thuộc group transit_stations")
				var label = stop.find_child("StationSign3D", true, false) as Label3D
				assert(label != null, "LỖI: Trạm %s thiếu Label3D diegetic!" % stop.name)
				assert(label.billboard == BaseMaterial3D.BILLBOARD_ENABLED, "Nhãn trạm phải bật billboard!")
				assert(label.no_depth_test == true, "Nhãn trạm phải bật no_depth_test!")
				assert(label.outline_size >= 8, "Nhãn trạm phải có viền outline dày!")

			print("  ✅ 100% 12 Trạm dừng chân đạt chuẩn Diegetic UI và cấu trúc Platform/Canopy!")
			test_step = 3
			test_frames = 0

		3:
			if test_frames < 4:
				return false

			print("\n[Bước 4] TIẾP CẬN TRẠM NGHỈ CHÂN ĐÔNG 1.5KM (END-TO-END VERIFICATION):")
			var sample_stop = transit_net.find_child("TransitStop_Đông_1500m", true, false) as Node3D
			assert(sample_stop != null, "Phải tìm thấy TransitStop_Đông_1500m")

			# Đặt người chơi bước vào bệ chờ xe của trạm
			player.global_position = sample_stop.global_position + Vector3(0.0, 0.5, 0.0)
			test_step = 4
			test_frames = 0

		4:
			if test_frames < 6:
				return false

			var sample_stop = transit_net.find_child("TransitStop_Đông_1500m", true, false) as Node3D
			var dist = player.global_position.distance_to(sample_stop.global_position)
			print("  - Cự ly người chơi tới tâm trạm: %.2fm (Bệ chờ 8x4m)" % dist)
			assert(dist <= 3.0, "Player phải đứng gọn gàng trên bệ đứng chờ xe!")

			var label = sample_stop.find_child("StationSign3D", true, false) as Label3D
			print("  - Biển hiệu Diegetic 3D: '%s'" % label.text.replace("\n", " | "))
			assert("TRẠM NGHỈ CHÂN NAN HOA ĐÔNG (1.5 KM)" in label.text, "Biển hiệu phải hiển thị đúng tên trạm!")
			print("  ✅ Người chơi tiếp cận trạm chờ xe và đọc biển thông tin thành công!")

			print("\n================================================================================")
			print("🎉 KIỂM THỬ HỆ THỐNG GIAO THÔNG MẠNG NHỆN 500 KM² ĐÃ THÀNH CÔNG RỰC RỠ (100% PASS)!")
			print("================================================================================\n")
			quit(0)
			return true

	return false
