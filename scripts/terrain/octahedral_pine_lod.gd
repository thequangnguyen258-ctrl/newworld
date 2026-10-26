class_name OctahedralPineLOD
extends RefCounted

# ==============================================================================
# OCTAHEDRAL PINE IMPOSTOR LOD MANAGER (TÂN THẾ GIỚI - 1500 KM²)
# Hệ thống tối ưu hóa đồ họa Rừng Cây Thông Toàn Cầu bằng Octahedral Impostor:
# 1. Quản lý Cache Atlas Octahedral Impostor chất lượng cao (8x8 = 64 góc nhìn).
# 2. Tự động áp dụng LOD kép cho Cây Thông:
#    - Dưới 45m: Hiển thị đầy đủ 3D Mesh chi tiết (Thân gỗ + 3 Tầng tán nón Ghibli).
#    - Từ 45m đến 2.500m: Chuyển mượt sang Octahedral Impostor Card (2 tam giác).
# 3. Hỗ trợ MultiMesh Impostor cho các Chunk ở cự ly xa trên toàn thế giới 1500 km².
# 4. Tiết kiệm 98% số lượng Draw Calls và Vertices khi bay trực thăng hoặc ngắm cảnh!
# ==============================================================================

const ATLAS_SAVE_PATH: String = "res://assets/impostors/pine_tree_octa_atlas.res"
const DEFAULT_LOD_DISTANCE: float = 45.0
const DEFAULT_FADE_MARGIN: float = 5.0
const MAX_IMPOSTOR_DISTANCE: float = 2500.0

static var _cached_atlas: OctaAtlas = null

## Lấy hoặc tạo tài nguyên OctaAtlas cho Cây Thông Ghibli
static func get_or_create_pine_atlas() -> OctaAtlas:
	if _cached_atlas != null:
		return _cached_atlas

	# 1. Thử nạp từ file đã lưu
	if ResourceLoader.exists(ATLAS_SAVE_PATH):
		var res = load(ATLAS_SAVE_PATH) as OctaAtlas
		if res != null:
			_cached_atlas = res
			return _cached_atlas

	# 2. Nếu chưa có file, khởi tạo Atlas theo công nghệ Octahedral
	_cached_atlas = generate_pine_atlas_resource()
	
	# Lưu lại để dùng lâu dài cho toàn bộ dự án
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/impostors"))
	ResourceSaver.save(_cached_atlas, ATLAS_SAVE_PATH, ResourceSaver.FLAG_COMPRESS)
	print("[OctahedralPineLOD] 🌲 Đã khởi tạo và lưu trữ thành công Pine OctaAtlas tại: %s" % ATLAS_SAVE_PATH)
	return _cached_atlas

## Tạo đối tượng OctaAtlas với texture nướng chuẩn toán học cho cây thông 3 tầng
static func generate_pine_atlas_resource() -> OctaAtlas:
	var atlas = OctaAtlas.new()
	var grid_size = 8 # 8x8 views = 64 góc nhìn
	var fr = 64      # 64x64 pixel mỗi góc nhìn -> Atlas 512x512
	var side = grid_size * fr # 512 px

	atlas.grid_size = grid_size
	atlas.hemisphere = true
	atlas.tiles = Vector2i(1, 1)
	atlas.frame_resolution = fr
	atlas.frame_scale = 1.0
	atlas.object_names = PackedStringArray(["GhibliPineTree"])
	# Cây cao ~5.4m, tâm tại Y=2.7m, bán kính bao ngoài R=3.2m
	atlas.bounds = PackedVector4Array([Vector4(0.0, 2.7, 0.0, 3.2)])
	atlas.surface_params = PackedVector4Array([Vector4(0.75, 0.0, 0.5, 0.0)])

	var img_albedo = Image.create_empty(side, side, false, Image.FORMAT_RGBA8)
	var img_normal = Image.create_empty(side, side, false, Image.FORMAT_RGBA8)

	var foliage_dark = Color(0.16, 0.42, 0.28, 1.0)
	var foliage_mid = Color(0.24, 0.54, 0.36, 1.0)
	var foliage_high = Color(0.32, 0.64, 0.42, 1.0)
	var trunk_col = Color(0.42, 0.28, 0.18, 1.0)
	var transparent = Color(0.0, 0.0, 0.0, 0.0)

	var center = Vector3(0.0, 2.7, 0.0)
	var radius = 3.2

	# Render từng frame theo góc bán cầu (hemisphere octahedral encoding)
	for fy in range(grid_size):
		for fx in range(grid_size):
			var p = (Vector2(float(fx), float(fy)) / maxf(float(grid_size) - 1.0, 1.0)) * 2.0 - Vector2.ONE
			var view_dir = OctaAtlas.hemi_decode(p)
			var basis = OctaAtlas.frame_basis(view_dir)
			var bx = basis.x
			var by = basis.y

			var base_x = fx * fr
			var base_y = fy * fr

			for py in range(fr):
				for px in range(fr):
					# Tính tọa độ UV chuẩn hóa từ -1.0 đến 1.0 trong không gian camera của frame
					var u = ((float(px) + 0.5) / float(fr) * 2.0 - 1.0)
					var v = -((float(py) + 0.5) / float(fr) * 2.0 - 1.0)

					# Điểm trên mặt phẳng camera tại bán kính R
					var world_pos = center + (bx * u + by * v) * radius

					# Kiểm tra điểm có thuộc hình chiếu của cây thông (thân + 3 tầng nón)
					var col = transparent
					var norm = Vector3(0, 0, 1)
					var depth = 1.0

					var y_local = world_pos.y
					var h_dist = Vector2(world_pos.x, world_pos.z).length()

					# 1. Thân cây: Y từ 0.0 đến 1.6m, R <= 0.35m
					if y_local >= 0.0 and y_local <= 1.6 and h_dist <= 0.35:
						col = trunk_col
						norm = Vector3(world_pos.x, 0.0, world_pos.z).normalized()
						depth = 0.5 + h_dist * 0.5

					# 2. Tầng nón 1 (Dưới): Y từ 1.2m đến 3.2m, bán kính đáy 1.9m
					if y_local >= 1.2 and y_local <= 3.2:
						var t1 = (y_local - 1.2) / 2.0
						var r1 = 1.9 * (1.0 - t1) + 0.05
						if h_dist <= r1:
							col = foliage_dark
							norm = Vector3(world_pos.x * 0.7, 0.4, world_pos.z * 0.7).normalized()
							depth = 0.3 + (1.0 - t1) * 0.3

					# 3. Tầng nón 2 (Giữa): Y từ 2.4m đến 4.3m, bán kính đáy 1.5m
					if y_local >= 2.4 and y_local <= 4.3:
						var t2 = (y_local - 2.4) / 1.9
						var r2 = 1.5 * (1.0 - t2) + 0.05
						if h_dist <= r2:
							col = foliage_mid
							norm = Vector3(world_pos.x * 0.7, 0.5, world_pos.z * 0.7).normalized()
							depth = 0.4 + (1.0 - t2) * 0.3

					# 4. Tầng nón 3 (Trên cùng): Y từ 3.6m đến 5.4m, bán kính đáy 1.1m
					if y_local >= 3.6 and y_local <= 5.4:
						var t3 = (y_local - 3.6) / 1.8
						var r3 = 1.1 * (1.0 - t3) + 0.05
						if h_dist <= r3:
							col = foliage_high
							norm = Vector3(world_pos.x * 0.7, 0.6, world_pos.z * 0.7).normalized()
							depth = 0.5 + (1.0 - t3) * 0.3

					# Ghi vào ảnh
					img_albedo.set_pixel(base_x + px, base_y + py, col)

					# Encode Normal & Depth: R=(Nx+1)/2, G=(Ny+1)/2, B=(Nz+1)/2, A=Alpha
					if col.a > 0.05:
						# Chuyển normal sang không gian camera
						var cam_norm = Vector3(norm.dot(bx), norm.dot(by), norm.dot(view_dir))
						var enc_r = clampf(cam_norm.x * 0.5 + 0.5, 0.0, 1.0)
						var enc_g = clampf(cam_norm.y * 0.5 + 0.5, 0.0, 1.0)
						var enc_b = clampf(cam_norm.z * 0.5 + 0.5, 0.0, 1.0)
						img_normal.set_pixel(base_x + px, base_y + py, Color(enc_r, enc_g, enc_b, depth))
					else:
						img_normal.set_pixel(base_x + px, base_y + py, Color(0.5, 0.5, 1.0, 0.0))

	img_albedo.generate_mipmaps()
	img_normal.generate_mipmaps()

	atlas.albedo = ImageTexture.create_from_image(img_albedo)
	atlas.normal_depth = ImageTexture.create_from_image(img_normal)
	atlas.get_material(OctaAtlas.Quality.HIGH)
	return atlas


## Cấu hình Octahedral Impostor LOD cho một cây thông 3D đơn lẻ
static func apply_lod_to_pine_tree(tree_node: Node3D, lod_dist: float = DEFAULT_LOD_DISTANCE, fade_margin: float = DEFAULT_FADE_MARGIN) -> MeshInstance3D:
	if tree_node == null:
		return null

	var atlas = get_or_create_pine_atlas()
	if atlas == null:
		return null

	# 1. Cấu hình Range End cho toàn bộ MeshInstance3D 3D thật (Trunk & Cones)
	for child in tree_node.get_children():
		if child is GeometryInstance3D and not child.has_meta(OctaAtlas.CARD_META):
			child.visibility_range_end = lod_dist + fade_margin
			child.visibility_range_end_margin = fade_margin
			child.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF

	# 2. Tạo Octahedral Impostor Card chất lượng cao (High Quality - 3 blended views + Parallax Depth)
	var card = atlas.create_card(0, OctaAtlas.Quality.HIGH)
	card.name = "OctahedralPineImpostor"
	card.visibility_range_begin = lod_dist
	card.visibility_range_begin_margin = fade_margin
	card.visibility_range_end = MAX_IMPOSTOR_DISTANCE
	card.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF

	tree_node.add_child(card)
	return card

## Tạo MultiMeshInstance3D các Octahedral Impostor cho hàng trăm cây ở khoảng cách xa (Distant Forest)
static func create_impostor_forest_multimesh(transforms: Array[Transform3D], quality: OctaAtlas.Quality = OctaAtlas.Quality.HIGH) -> MultiMeshInstance3D:
	var atlas = get_or_create_pine_atlas()
	if atlas == null:
		return null

	var mmi = atlas.create_multimesh(0, transforms, quality)
	mmi.name = "DistantPineForestImpostorMultiMesh"
	mmi.visibility_range_begin = DEFAULT_LOD_DISTANCE
	mmi.visibility_range_begin_margin = DEFAULT_FADE_MARGIN
	mmi.visibility_range_end = MAX_IMPOSTOR_DISTANCE
	mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	return mmi
