extends SceneTree

func _init() -> void:
	print("=================================================================")
	print("📊 BẮT ĐẦU KIỂM THỬ TÍCH HỢP TAUPLOT CHARTS VÀO CIVIC OS")
	print("=================================================================")

	var TauPlotClass = preload("res://addons/tau-plot/plot/plot.gd")
	var plot = TauPlotClass.new()
	assert(plot != null, "LỖI: Không thể khởi tạo đối tượng TauPlot!")

	# Tạo dữ liệu mẫu 5 Huyện:
	# 1. Huyện Đông (Lúa Mì & Lương Thực): 48.500 kg
	# 2. Huyện Tây (Điện Gió & Kỹ Nghệ): 48.000 đơn vị năng lượng
	# 3. Huyện Bắc (Dược Liệu & Gỗ Rừng): 35.000 đơn vị
	# 4. Huyện Nam (Thủy Sản & Cảng Biển): 30.000 tấn
	# 5. Thủ Phủ Đỉnh Vát (Bánh Mì & Dịch Vụ): 40.000 đơn vị
	var y_data: Array[PackedFloat64Array] = [
		PackedFloat64Array([48.5, 48.0, 35.0, 30.0, 40.0]),
		PackedFloat64Array([40.0, 42.0, 30.0, 28.0, 35.0]),
	]
	var dataset = TauPlotClass.Dataset.make_shared_x_categorical(
		PackedStringArray(["Sản Lượng Thực Tế (Actual)", "Chỉ Tiêu Đô Thị (Target)"]),
		PackedStringArray(["Đông (Lúa)", "Tây (Điện)", "Bắc (Rừng)", "Nam (Cảng)", "Thủ Phủ (Dịch Vụ)"]),
		y_data
	)
	assert(dataset != null, "LỖI: Không thể khởi tạo Dataset TauPlot!")

	var x_axis = TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CATEGORICAL

	var y_axis = TauAxisConfig.new()
	y_axis.title = "Nghìn Đơn Vị (k Units)"

	var bar_overlay_config = TauBarConfig.new()

	var overlays_arr: Array[TauPaneOverlayConfig] = [bar_overlay_config]
	var pane = TauPaneConfig.new()
	pane.y_left_axis = y_axis
	pane.overlays = overlays_arr

	var panes_arr: Array[TauPaneConfig] = [pane]
	var config = TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = panes_arr

	var b0 = TauXYSeriesBinding.new()
	b0.series_id = dataset.get_series_id_by_index(0)
	b0.pane_index = 0
	b0.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	b0.y_axis_id = TauPlotClass.AxisId.LEFT

	var b1 = TauXYSeriesBinding.new()
	b1.series_id = dataset.get_series_id_by_index(1)
	b1.pane_index = 0
	b1.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	b1.y_axis_id = TauPlotClass.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [b0, b1]

	plot.title = "Biểu Đồ Sản Lượng Kinh Tế 5 Huyện"
	plot.custom_minimum_size = Vector2(580, 260)
	plot.plot_xy(dataset, config, bindings)

	root.add_child(plot)
	print("  ✅ Khởi tạo và thiết lập biểu đồ cột TauPlot thành công 100%!")

	# 2. KIỂM THỬ BIỂU ĐỒ ĐƯỜNG DÒNG TIỀN KINH TẾ (LINE CHART)
	var line_plot = TauPlotClass.new()
	var line_y_data: Array[PackedFloat64Array] = [
		PackedFloat64Array([42000.0, 44500.0, 47000.0, 52000.0, 50000.0, 51000.0, 55000.0]),
		PackedFloat64Array([21000.0, 22000.0, 23000.0, 28000.0, 25000.0, 26000.0, 30000.0]),
	]
	var line_dataset = TauPlotClass.Dataset.make_shared_x_categorical(
		PackedStringArray(["Kho Bạc Đô Thị", "Quỹ 1/10 Dâng Chúa"]),
		PackedStringArray(["Thứ 2", "Thứ 3", "Thứ 4", "Thứ 5", "Thứ 6", "Thứ 7", "Chủ Nhật"]),
		line_y_data
	)
	var line_x_axis = TauAxisConfig.new()
	line_x_axis.type = TauAxisConfig.Type.CATEGORICAL

	var line_y_axis = TauAxisConfig.new()
	line_y_axis.title = "Đồng Đô (Đ)"

	var line_overlay_config = TauLineConfig.new()
	var line_overlays_arr: Array[TauPaneOverlayConfig] = [line_overlay_config]
	var line_pane = TauPaneConfig.new()
	line_pane.y_left_axis = line_y_axis
	line_pane.overlays = line_overlays_arr

	var line_panes_arr: Array[TauPaneConfig] = [line_pane]
	var line_config = TauXYConfig.new()
	line_config.x_axis = line_x_axis
	line_config.panes = line_panes_arr

	var lb0 = TauXYSeriesBinding.new()
	lb0.series_id = line_dataset.get_series_id_by_index(0)
	lb0.pane_index = 0
	lb0.overlay_type = TauXYSeriesBinding.PaneOverlayType.LINE
	lb0.y_axis_id = TauPlotClass.AxisId.LEFT

	var lb1 = TauXYSeriesBinding.new()
	lb1.series_id = line_dataset.get_series_id_by_index(1)
	lb1.pane_index = 0
	lb1.overlay_type = TauXYSeriesBinding.PaneOverlayType.LINE
	lb1.y_axis_id = TauPlotClass.AxisId.LEFT

	var line_bindings: Array[TauXYSeriesBinding] = [lb0, lb1]
	line_plot.title = "Biểu Đồ Dòng Tiền Kinh Tế & Tăng Trưởng Ngân Khố"
	line_plot.custom_minimum_size = Vector2(580, 240)
	line_plot.plot_xy(line_dataset, line_config, line_bindings)
	root.add_child(line_plot)
	print("  ✅ Khởi tạo và thiết lập biểu đồ đường TauPlot thành công 100%!")

	print("=================================================================")
	print("🎉 KIỂM THỬ TAUPLOT CHARTS HOÀN TẤT XUẤT SẮC!")
	print("=================================================================")
	plot.free()
	line_plot.free()
	quit(0)
