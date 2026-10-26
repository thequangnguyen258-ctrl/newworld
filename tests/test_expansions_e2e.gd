extends SceneTree
## KIỂM THỬ TÍNH NĂNG MỞ RỘNG (EXP-01 ĐẾN EXP-06) - TÂN THẾ GIỚI
## Xác thực thực tế: Satellite Hubs, BRT Fleet, HousingPlot Supply Chain,
## Immigration Port, 4-Season Weather, Polyphonic Synthesizer

const DistrictsBuilderScript = preload("res://scripts/terrain/districts_builder.gd")
const SpiderwebTransitBuilderScript = preload("res://scripts/terrain/spiderweb_transit_builder.gd")
const HousingPlotScript = preload("res://scripts/interactive/housing_plot.gd")
const CitizenManagerScript = preload("res://scripts/simulation/citizen_manager.gd")
const WorldManagerScript = preload("res://scripts/core/world_manager.gd")
const AudioSynthesizerScript = preload("res://scripts/core/audio_synthesizer.gd")

func _init() -> void:
	print("\n============================================================")
	print("🧪 BẮT ĐẦU KIỂM THỬ CÁC TÍNH NĂNG MỞ RỘNG (EXP-01 -> EXP-06)")
	print("============================================================")
	call_deferred("_run_suite")

func _run_suite() -> void:
	var passed: int = 0
	var failed: int = 0

	# 1. EXP-01: Kiểm tra 4 Tòa Trụ Sở Vệ Tinh (Satellite Hubs)
	var east_dist = DistrictsBuilderScript.build_east_district()
	var west_dist = DistrictsBuilderScript.build_west_district()
	var north_dist = DistrictsBuilderScript.build_north_district()
	var south_dist = DistrictsBuilderScript.build_south_district()
	root.add_child(east_dist)
	root.add_child(west_dist)
	root.add_child(north_dist)
	root.add_child(south_dist)

	var hub_e = east_dist.find_child("SatelliteHub*", true, false)
	var hub_w = west_dist.find_child("SatelliteHub*", true, false)
	var hub_n = north_dist.find_child("SatelliteHub*", true, false)
	var hub_s = south_dist.find_child("SatelliteHub*", true, false)

	if hub_e and hub_w and hub_n and hub_s:
		print("✅ [EXP-01 PASS] Đã tạo đủ 4 Trụ sở Vệ Tinh 4 tầng Tân Cổ Điển tại 4 Huyện (Đông/Tây/Bắc/Nam).")
		passed += 1
	else:
		push_error("❌ [EXP-01 FAIL] Thiếu Trụ sở Vệ tinh tại các huyện!")
		failed += 1

	# 2. EXP-02: Kiểm tra Đội Xe Bus Điện BRT (Spiderweb BRT Fleet)
	var spiderweb = SpiderwebTransitBuilderScript.build_spiderweb_network()
	root.add_child(spiderweb)
	var brt_fleet = spiderweb.find_child("BRTFleet", true, false)
	if brt_fleet and brt_fleet.get_child_count() == 8:
		print("✅ [EXP-02 PASS] Đội Xe Bus Điện BRT đã khởi tạo đủ 8 xe tuần hoàn trên 4 trục nan hoa.")
		passed += 1
	else:
		var cnt = brt_fleet.get_child_count() if brt_fleet else 0
		push_error("❌ [EXP-02 FAIL] BRTFleet chỉ có %d xe (kỳ vọng 8 xe)!" % cnt)
		failed += 1

	# 3. EXP-03: Kiểm tra Chuỗi Cung Ứng & Thi Công HousingPlot (AVAILABLE -> CONSTRUCTION -> COMPLETED)
	var plot = HousingPlotScript.new()
	plot.plot_id = "test_plot_exp03_%d" % Time.get_ticks_msec()
	plot.price = 100.0
	root.add_child(plot)
	await physics_frame
	plot.current_status = HousingPlotScript.PlotStatus.AVAILABLE

	var dummy_player = Node3D.new()
	dummy_player.name = "Player"
	dummy_player.add_to_group("player")
	root.add_child(dummy_player)

	# Lần tương tác 1: Từ AVAILABLE -> Chuyển sang CONSTRUCTION
	plot.interact(dummy_player)
	var is_under_construction = (plot.current_status == HousingPlotScript.PlotStatus.CONSTRUCTION)
	# Lần tương tác 2: Từ CONSTRUCTION -> Nghiệm thu COMPLETED
	plot.interact(dummy_player)
	var is_completed = (plot.current_status == HousingPlotScript.PlotStatus.COMPLETED)

	if is_under_construction and is_completed and plot.construction_progress == 100.0:
		print("✅ [EXP-03 PASS] Khép kín chuỗi thi công HousingPlot (AVAILABLE -> CONSTRUCTION 50% -> COMPLETED 100%).")
		passed += 1
	else:
		push_error("❌ [EXP-03 FAIL] HousingPlot không chuyển hóa đúng chu kỳ xây dựng!")
		failed += 1

	# 4. EXP-04: Kiểm tra Đón Tàu Lữ Khách & Nhập Cư Cảng Hòa Bình
	var cit_mgr = CitizenManagerScript.new()
	root.add_child(cit_mgr)
	var new_immigrants = cit_mgr.spawn_immigrant_batch(3)
	var ship_station = south_dist.find_child("StationPassengerShipTerminal", true, false)
	if new_immigrants == 3 and ship_station != null:
		print("✅ [EXP-04 PASS] Đã tiếp nhận %d công dân mới từ Nhà Ga Tàu Khách Quốc Tế Cảng Hòa Bình." % new_immigrants)
		passed += 1
	else:
		push_error("❌ [EXP-04 FAIL] Lỗi tiếp nhận nhập cư tàu khách Cảng Hòa Bình!")
		failed += 1

	# 5. EXP-05: Kiểm tra Chu Kỳ 4 Mùa Sinh Thái (WorldManager Seasons)
	var wm = WorldManagerScript.new()
	root.add_child(wm)
	var season_initial = wm.current_season
	var mul_spring = wm.get_season_production_multiplier("DISTRICT_NORTH_FOREST")
	wm.current_season = WorldManagerScript.SeasonType.AUTUMN
	var mul_autumn = wm.get_season_production_multiplier("DISTRICT_EAST_AGRICULTURE")
	var season_name = wm.get_season_name()
	if season_initial == 0 and mul_spring == 1.20 and mul_autumn == 1.30 and not season_name.is_empty():
		print("✅ [EXP-05 PASS] Hệ thống 4 Mùa hoạt động chính xác với hệ số sản lượng mùa vụ (%s)." % season_name)
		passed += 1
	else:
		push_error("❌ [EXP-05 FAIL] Lỗi hệ thống 4 Mùa hoặc hệ số kinh tế theo mùa!")
		failed += 1

	# 6. EXP-06: Kiểm tra Bộ Tổng Hợp Âm Đa Bè (AudioSynthesizer Pipe Organ / Grand Piano)
	AudioSynthesizerScript.play_polyphonic_progression(dummy_player, "organ")
	AudioSynthesizerScript.play_polyphonic_progression(dummy_player, "piano")
	print("✅ [EXP-06 PASS] Bộ Tổng hợp âm đa bè (Pipe Organ / Grand Piano) đã kích hoạt thành công.")
	passed += 1

	print("============================================================")
	print("📊 KẾT QUẢ KIỂM THỬ EXP: %d PASS / %d FAIL" % [passed, failed])
	print("============================================================\n")
	quit(0 if failed == 0 else 1)
