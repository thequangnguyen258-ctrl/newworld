extends SceneTree

# ==============================================================================
# TEST AUTOMATION: CẤU HÌNH OCTAHEDRAL IMPOSTOR LOD CHO RỪNG CÂY THÔNG 1500 KM²
# 1. Kiểm tra Khởi tạo & Cache OctaAtlas chuẩn Octahedral (8x8 = 64 góc nhìn).
# 2. Kiểm tra Áp dụng Dynamic LOD cho Cây Thông:
#    - Dưới 45m: Hiển thị 3D Mesh (visibility_range_end = 50.0m).
#    - Từ 45m đến 2500m: Hiển thị Octahedral Impostor (visibility_range_begin = 45.0m).
# 3. Kiểm tra MultiMesh Impostor Forest cho Rừng Cây Thông viễn cảnh 1500 km².
# ==============================================================================

func _init() -> void:
	print("================================================================================")
	print("🌲 KIỂM THỬ: CẤU HÌNH OCTAHEDRAL IMPOSTOR LOD CHO RỪNG CÂY THÔNG 1500 KM²")
	print("================================================================================")

	var OctaPineClass = preload("res://scripts/terrain/octahedral_pine_lod.gd")

	# 1. KIỂM TRA KHỞI TẠO ATLAS OCTAHEDRAL CHO CÂY THÔNG
	print("\n[1] KIỂM TRA TẠO & NẠP OCTAHEDRAL PINE ATLAS:")
	var atlas: OctaAtlas = OctaPineClass.get_or_create_pine_atlas()
	assert(atlas != null, "LỖI: Không thể khởi tạo OctaAtlas cho cây thông!")
	assert(atlas.grid_size == 8, "LỖI: grid_size phải là 8 (8x8 = 64 góc nhìn)!")
	assert(atlas.hemisphere == true, "LỖI: Cây cối phải dùng hemisphere = true!")
	assert(atlas.object_count() == 1, "LỖI: Atlas phải chứa đúng 1 định nghĩa Cây Thông!")
	assert(atlas.albedo != null, "LỖI: Atlas phải có Texture Albedo!")
	assert(atlas.normal_depth != null, "LỖI: Atlas phải có Texture Normal/Depth!")
	print("  ✅ Atlas hợp lệ: Grid 8x8 (64 views), Hemisphere=true, Bounds=%s" % str(atlas.bounds[0]))
	print("  ✅ Albedo Atlas (%dx%d) và Normal/Depth Atlas sẵn sàng." % [atlas.albedo.get_width(), atlas.albedo.get_height()])

	# 2. KIỂM TRA ÁP DỤNG DYNAMIC LOD VÀO CÂY THÔNG 3D
	print("\n[2] KIỂM TRA GẮN DYNAMIC LOD CHO CÂY THÔNG 3D ĐƠN LẺ:")
	var tree = Node3D.new()
	tree.name = "TestPineTree"
	root.add_child(tree)

	var trunk = MeshInstance3D.new()
	trunk.name = "Trunk"
	var cyl = CylinderMesh.new()
	trunk.mesh = cyl
	tree.add_child(trunk)

	for t in range(3):
		var foliage = MeshInstance3D.new()
		foliage.name = "Foliage_%d" % t
		foliage.mesh = CylinderMesh.new()
		tree.add_child(foliage)

	# Gắn Octahedral Impostor LOD (ngưỡng 45m, margin 5m)
	var card = OctaPineClass.apply_lod_to_pine_tree(tree, 45.0, 5.0)
	assert(card != null, "LỖI: Không thể gắn card Octahedral Impostor!")
	assert(card.get_parent() == tree, "LỖI: Card phải là node con của tree!")
	assert(card.visibility_range_begin == 45.0, "LỖI: visibility_range_begin của card phải là 45.0m!")
	assert(card.visibility_range_begin_margin == 5.0, "LỖI: visibility_range_begin_margin phải là 5.0m!")
	assert(card.visibility_range_end == 2500.0, "LỖI: visibility_range_end của card phải là 2500m (tầm nhìn thế giới 1500 km²)!")

	# Kiểm tra các Mesh 3D thật có được đặt visibility_range_end tương ứng không
	for child in tree.get_children():
		if child is GeometryInstance3D and child != card:
			assert(child.visibility_range_end == 50.0, "LỖI: Mesh 3D thật phải có visibility_range_end = 50.0m (45 + 5)!")
			assert(child.visibility_range_end_margin == 5.0, "LỖI: Margin fade của 3D mesh phải là 5.0m!")
	print("  ✅ Cây thông 3D chuyển đổi mượt mà: [0m - 50m: 3D Mesh] ⇄ [45m - 2500m: Octahedral Impostor Card].")

	# 3. KIỂM TRA TẠO MULTIMESH IMPOSTOR CHO RỪNG THÔNG ĐẠI NGÀN 1500 KM²
	print("\n[3] KIỂM TRA MULTIMESH IMPOSTOR CHO RỪNG THÔNG ĐẠI NGÀN 1500 KM²:")
	var transforms: Array[Transform3D] = []
	for i in range(120):
		var xform = Transform3D()
		xform.origin = Vector3(float(i * 10), 600.0, float(i * -15))
		transforms.append(xform)

	var forest_mmi = OctaPineClass.create_impostor_forest_multimesh(transforms, OctaAtlas.Quality.HIGH)
	assert(forest_mmi != null, "LỖI: Không thể tạo MultiMeshInstance3D cho rừng thông!")
	assert(forest_mmi.multimesh != null, "LỖI: MultiMeshInstance3D thiếu MultiMesh!")
	assert(forest_mmi.multimesh.instance_count == 120, "LỖI: Số lượng cây trong MultiMesh phải là 120!")
	assert(forest_mmi.visibility_range_begin == 45.0, "LỖI: visibility_range_begin phải là 45.0m!")
	assert(forest_mmi.visibility_range_end == 2500.0, "LỖI: visibility_range_end phải đạt 2500m!")
	root.add_child(forest_mmi)
	print("  ✅ Đã tạo thành công MultiMesh Impostor gồm 120 cây thông viễn cảnh (Tầm hiển thị 45m - 2500m)!")

	# 4. KIỂM TRA NATUREFLORASCATTER TỰ ĐỘNG TÍCH HỢP OCTAHEDRAL IMPOSTOR LOD
	print("\n[4] KIỂM TRA NATUREFLORASCATTER TÍCH HỢP OCTAHEDRAL IMPOSTOR LOD:")
	var flora_scatter = NatureFloraScatter.new()
	flora_scatter.name = "TestFloraScatter"
	root.add_child(flora_scatter)
	flora_scatter.generate_flora()

	var pine_mm = flora_scatter.get_node_or_null("PineForestMultiMesh") as MultiMeshInstance3D
	assert(pine_mm != null, "LỖI: Thiếu PineForestMultiMesh trong NatureFloraScatter!")
	assert(pine_mm.visibility_range_end == 50.0, "LỖI: PineForestMultiMesh phải có visibility_range_end = 50.0m!")

	var impostor_mm = flora_scatter.get_node_or_null("PineForestImpostorMultiMesh") as MultiMeshInstance3D
	assert(impostor_mm != null, "LỖI: Thiếu PineForestImpostorMultiMesh trong NatureFloraScatter!")
	assert(impostor_mm.visibility_range_begin == 45.0, "LỖI: PineForestImpostorMultiMesh phải có visibility_range_begin = 45.0m!")
	print("  ✅ NatureFloraScatter tự động trang bị cặp LOD: PineForestMultiMesh (0-50m) & PineForestImpostorMultiMesh (45-2500m)!")

	# 5. KIỂM TRA WORLDCHUNKSTREAMER SINH CÂY THÔNG KÈM IMPOSTOR CARD
	print("\n[5] KIỂM TRA WORLDCHUNKSTREAMER SINH CÂY THÔNG KÈM IMPOSTOR TRÊN ĐẠI THẾ GIỚI 1500 KM²:")
	var streamer = WorldChunkStreamer.new()
	streamer.name = "TestStreamer"
	root.add_child(streamer)

	# Sinh thử 1 chunk ở Huyện Bắc (Rừng thông đại ngàn)
	var test_coord = Vector2i(0, -90) # Tọa độ Z = -5760m (is_north_forest)
	streamer._spawn_chunk(test_coord)
	var spawned_chunk = streamer.loaded_chunks.get(test_coord)
	assert(spawned_chunk != null, "LỖI: Không sinh được chunk!")

	var flora_container = spawned_chunk.get_node_or_null("ChunkFlora")
	assert(flora_container != null, "LỖI: Chunk thiếu ChunkFlora!")

	var found_pine_with_impostor = false
	for child in flora_container.get_children():
		var imp_card = child.get_node_or_null("OctahedralPineImpostor")
		if imp_card != null:
			found_pine_with_impostor = true
			assert(imp_card.visibility_range_begin == 45.0, "LỖI: Card trong chunk phải có visibility_range_begin = 45.0m!")
			assert(imp_card.visibility_range_end == 2500.0, "LỖI: Card trong chunk phải có visibility_range_end = 2500m!")
			break
	assert(found_pine_with_impostor, "LỖI: Không tìm thấy cây thông nào được trang bị OctahedralPineImpostor trong Chunk!")
	print("  ✅ Cây thông trong Chunk thế giới 1500 km² được cấu hình Octahedral Impostor LOD hoàn hảo!")

	# Dọn dẹp
	tree.free()
	forest_mmi.free()
	flora_scatter.free()
	streamer.free()

	print("\n================================================================================")
	print("🎉 TOÀN BỘ KIỂM THỬ OCTAHEDRAL IMPOSTOR LOD CHO RỪNG THÔNG ĐÃ THÀNH CÔNG RỰC RỠ (100% PASS)!")
	print("================================================================================")
	quit(0)
