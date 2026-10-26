class_name ModularHumanoidBuilder
extends RefCounted

# ==============================================================================
# MODULAR HUMANOID BUILDER (TÂN THẾ GIỚI - GHIBLI ANIME 3D SYSTEM)
# Kiến tạo nhân vật 3D Anime đa độ tuổi & trang phục nghề nghiệp:
# 1. 4 Độ Tuổi: Thiếu Nhi (Chibi), Thanh Thiếu Niên, Người Trưởng Thành, Trưởng Lão
# 2. Trang Phục Ngành Nghề Đặc Thù: Thị Trưởng, Thợ Mộc, Cơ Khí, Nông Dân,
#    Bác Sĩ, Thợ Bánh Mì, Giáo Viên, Học Sinh, Thiếu Nhi.
# 3. Phụ Kiện Đặc Trưng: Nón rơm, Mũ bảo hộ, Mũ đầu bếp, Ba lô, Bản vẽ, Gùi tre...
# Tối ưu hóa tuyệt đối cho GPU Intel Iris Xe / UHD (Toon Shading, Low-Drawcall).
# ==============================================================================

enum AgeGroup {
	CHILD,       # 6 - 14 tuổi (Cao ~1.15m, Chibi đầu to, năng động)
	YOUTH,       # 15 - 19 tuổi (Cao ~1.58m, Học viên thanh thiếu niên)
	ADULT,       # 20 - 39 tuổi (Cao ~1.76m, Cân đối, trang phục nghề chuyên sâu)
	ELDER        # 40 - 65+ tuổi (Cao ~1.70m, Râu tóc bạc, trang phục nghệ nhân)
}

enum ProfessionType {
	MAYOR,            # Thị Trưởng (Người chơi) - Áo măng tô xanh hoàng gia viền vàng
	CARPENTER,        # Thợ Mộc Mỹ Nghệ - Áo sơ mi caro, tạp dề da bò, đai búa
	ENGINEER,         # Kỹ Sư Xây Dựng & Cầu - Áo gilê phản quang, mũ bảo hộ vàng
	FARMER,           # Nông Dân Sinh Thái - Áo bà ba, nón rơm rộng vành, gùi tre
	DOCTOR,           # Bác Sĩ Nghỉ Dưỡng - Áo blouse trắng viền xanh ngọc, ống nghe
	BAKER,            # Thợ Bánh Mì Thơm Lừng - Mũ đầu bếp xếp ly, tạp dề trắng
	TEACHER,          # Thầy Giáo Học Viện - Áo sơ mi thanh lịch, cà vạt, kính mắt
	STUDENT,          # Học Viên Mỹ Thuật - Đồng phục học sinh anime, ba lô, giá vẽ
	CITIZEN_KID       # Thiếu Nhi Hồn Nhiên - Áo phông vàng, quần yếm xanh denim
}

# ------------------------------------------------------------------------------
# HÀM CHÍNH: XÂY DỰNG MÔ HÌNH NHÂN VẬT HOÀN CHỈNH
# ------------------------------------------------------------------------------
static func build_character_model(p_prof: ProfessionType, p_age: AgeGroup = AgeGroup.ADULT, p_gender: String = "Nam") -> Node3D:
	var root_node = Node3D.new()
	root_node.name = "CharacterVisualModel"
	
	# Hệ số tỷ lệ kích thước theo độ tuổi
	var age_scale: float = 1.0
	var head_scale: float = 1.0
	match p_age:
		AgeGroup.CHILD:
			age_scale = 0.65
			head_scale = 1.25 # Chibi anime đầu to dễ thương
		AgeGroup.YOUTH:
			age_scale = 0.88
			head_scale = 1.08
		AgeGroup.ADULT:
			age_scale = 1.0
			head_scale = 1.0
		AgeGroup.ELDER:
			age_scale = 0.96
			head_scale = 1.0
			
	# Vật liệu Toon chung
	var skin_color = Color(1.0, 0.88, 0.78) if p_age != AgeGroup.ELDER else Color(0.95, 0.84, 0.74)
	var skin_mat = _create_toon_mat(skin_color)
	
	# 1. THÂN NGƯỜI (TORSO) & TRANG PHỤC CHÍNH
	var torso_mesh = MeshInstance3D.new()
	torso_mesh.name = "Torso"
	var torso_box = BoxMesh.new()
	var torso_w = 0.42 * age_scale
	var torso_h = 0.55 * age_scale
	var torso_d = 0.25 * age_scale
	torso_box.size = Vector3(torso_w, torso_h, torso_d)
	torso_mesh.mesh = torso_box
	torso_mesh.material_override = _get_outfit_material(p_prof)
	torso_mesh.position = Vector3(0, 0.95 * age_scale, 0)
	root_node.add_child(torso_mesh)
	
	# 2. ĐẦU NHÂN VẬT (HEAD)
	var head_node = Node3D.new()
	head_node.name = "HeadGroup"
	head_node.position = Vector3(0, (0.95 + 0.32) * age_scale, 0)
	root_node.add_child(head_node)
	
	var head_mesh = MeshInstance3D.new()
	head_mesh.name = "HeadMesh"
	var head_sphere = SphereMesh.new()
	var head_r = 0.20 * age_scale * head_scale
	head_sphere.radius = head_r
	head_sphere.height = head_r * 2.05
	head_mesh.mesh = head_sphere
	head_mesh.material_override = skin_mat
	head_node.add_child(head_mesh)
	
	# Đôi mắt anime
	_add_anime_eyes(head_node, head_r)
	
	# Tóc anime theo nghề & độ tuổi
	_add_hair(head_node, p_prof, p_age, p_gender, head_r)
	
	# Mũ nón theo nghề
	_add_hat_accessory(head_node, p_prof, head_r)
	
	# 3. ĐÔI TAY (ARMS)
	var left_arm = _build_arm(p_prof, skin_mat, age_scale, -1.0)
	var right_arm = _build_arm(p_prof, skin_mat, age_scale, 1.0)
	root_node.add_child(left_arm)
	root_node.add_child(right_arm)
	
	# 4. ĐÔI CHÂN & QUẦN (LEGS)
	var left_leg = _build_leg(p_prof, age_scale, -1.0)
	var right_leg = _build_leg(p_prof, age_scale, 1.0)
	root_node.add_child(left_leg)
	root_node.add_child(right_leg)
	
	# 5. DỤNG CỤ CẦM TAY & ĐEO LƯNG (OCCUPATIONAL PROPS)
	_add_held_prop(right_arm, p_prof, age_scale)
	_add_back_accessory(torso_mesh, p_prof, age_scale)
	
	return root_node

# ------------------------------------------------------------------------------
# HÀM PHỤ TRỢ: TẠO MẮT ANIME
# ------------------------------------------------------------------------------
static func _add_anime_eyes(head_node: Node3D, head_r: float) -> void:
	var eye_mat = _create_toon_mat(Color(0.12, 0.15, 0.22)) # Mắt đen thẫm anime
	var eye_size = Vector3(0.045, 0.065, 0.02)
	
	for side in [-1.0, 1.0]:
		var eye = MeshInstance3D.new()
		eye.name = "Eye_%s" % ["L" if side < 0 else "R"]
		var box = BoxMesh.new()
		box.size = eye_size
		eye.mesh = box
		eye.material_override = eye_mat
		eye.position = Vector3(side * 0.075, 0.02, -head_r * 0.92)
		head_node.add_child(eye)
		
		# Điểm sáng trong mắt (Anime catchlight)
		var sparkle = MeshInstance3D.new()
		var sp_box = BoxMesh.new()
		sp_box.size = Vector3(0.015, 0.02, 0.01)
		sparkle.mesh = sp_box
		sparkle.material_override = _create_toon_mat(Color.WHITE)
		sparkle.position = Vector3(side * 0.075 + 0.01, 0.035, -head_r * 0.95)
		head_node.add_child(sparkle)

# ------------------------------------------------------------------------------
# HÀM PHỤ TRỢ: TÓC ANIME THEO NGHỀ & ĐỘ TUỔI
# ------------------------------------------------------------------------------
static func _add_hair(head_node: Node3D, prof: ProfessionType, age: AgeGroup, gender: String, r: float) -> void:
	var hair_color = Color(0.18, 0.16, 0.15) # Tóc đen nâu tự nhiên
	if age == AgeGroup.ELDER:
		hair_color = Color(0.85, 0.86, 0.88) # Tóc bạc trắng trưởng lão
	elif prof == ProfessionType.MAYOR:
		hair_color = Color(0.32, 0.22, 0.14) # Tóc nâu lãng tử
	elif prof == ProfessionType.CITIZEN_KID:
		hair_color = Color(0.65, 0.45, 0.22) # Tóc nâu hạt dẻ
	elif prof == ProfessionType.STUDENT:
		hair_color = Color(0.22, 0.32, 0.45) # Tóc xanh đen anime
		
	var hair_mat = _create_toon_mat(hair_color)
	
	# Khối tóc chính bao bọc phía trên và sau đầu
	var hair_top = MeshInstance3D.new()
	hair_top.name = "HairTop"
	var sphere = SphereMesh.new()
	sphere.radius = r * 1.08
	sphere.height = r * 1.5
	hair_top.mesh = sphere
	hair_top.material_override = hair_mat
	hair_top.position = Vector3(0, r * 0.35, 0.02)
	head_node.add_child(hair_top)
	
	# Râu bạc cho Trưởng lão
	if age == AgeGroup.ELDER:
		var beard = MeshInstance3D.new()
		beard.name = "ElderBeard"
		var b_box = BoxMesh.new()
		b_box.size = Vector3(r * 0.8, r * 0.7, r * 0.4)
		beard.mesh = b_box
		beard.material_override = hair_mat
		beard.position = Vector3(0, -r * 0.7, -r * 0.6)
		head_node.add_child(beard)

# ------------------------------------------------------------------------------
# HÀM PHỤ TRỢ: MŨ NÓN THEO NGÀNH NGHỀ
# ------------------------------------------------------------------------------
static func _add_hat_accessory(head_node: Node3D, prof: ProfessionType, r: float) -> void:
	match prof:
		ProfessionType.ENGINEER:
			# Mũ bảo hộ vàng cứng công trường
			var helmet = MeshInstance3D.new()
			helmet.name = "HardHat"
			var cyl = CylinderMesh.new()
			cyl.top_radius = r * 1.15
			cyl.bottom_radius = r * 1.25
			cyl.height = r * 0.65
			helmet.mesh = cyl
			helmet.material_override = _create_toon_mat(Color(0.98, 0.80, 0.12))
			helmet.position = Vector3(0, r * 0.75, 0)
			head_node.add_child(helmet)
			
		ProfessionType.FARMER:
			# Nón rơm rộng vành che nắng
			var hat = MeshInstance3D.new()
			hat.name = "StrawHat"
			var cone = CylinderMesh.new()
			cone.top_radius = 0.05
			cone.bottom_radius = r * 2.3
			cone.height = r * 0.6
			hat.mesh = cone
			hat.material_override = _create_toon_mat(Color(0.86, 0.78, 0.52))
			hat.position = Vector3(0, r * 0.75, 0)
			head_node.add_child(hat)
			
		ProfessionType.BAKER:
			# Mũ đầu bếp vải trắng xếp nếp cao
			var toque = MeshInstance3D.new()
			toque.name = "ChefToque"
			var cyl = CylinderMesh.new()
			cyl.top_radius = r * 1.35
			cyl.bottom_radius = r * 1.05
			cyl.height = r * 1.35
			toque.mesh = cyl
			toque.material_override = _create_toon_mat(Color(0.96, 0.96, 0.98))
			toque.position = Vector3(0, r * 1.1, 0)
			head_node.add_child(toque)
			
		ProfessionType.CITIZEN_KID:
			# Mũ lưỡi trai thể thao
			var cap = MeshInstance3D.new()
			cap.name = "BaseballCap"
			var cyl = CylinderMesh.new()
			cyl.top_radius = r * 1.05
			cyl.bottom_radius = r * 1.12
			cyl.height = r * 0.4
			cap.mesh = cyl
			cap.material_override = _create_toon_mat(Color(0.85, 0.25, 0.22))
			cap.position = Vector3(0, r * 0.6, 0)
			head_node.add_child(cap)

# ------------------------------------------------------------------------------
# HÀM PHỤ TRỢ: TAY ÁO & TAY
# ------------------------------------------------------------------------------
static func _build_arm(prof: ProfessionType, skin_mat: Material, scale_f: float, side: float) -> Node3D:
	var arm_node = Node3D.new()
	arm_node.name = "Arm_%s" % ["L" if side < 0 else "R"]
	arm_node.position = Vector3(side * 0.28 * scale_f, 1.12 * scale_f, 0)
	
	# Tay áo
	var sleeve = MeshInstance3D.new()
	sleeve.name = "Sleeve"
	var box = BoxMesh.new()
	box.size = Vector3(0.12 * scale_f, 0.42 * scale_f, 0.12 * scale_f)
	sleeve.mesh = box
	sleeve.material_override = _get_outfit_material(prof)
	sleeve.position = Vector3(0, -0.21 * scale_f, 0)
	arm_node.add_child(sleeve)
	
	# Bàn tay da Toon
	var hand = MeshInstance3D.new()
	hand.name = "Hand"
	var h_box = BoxMesh.new()
	h_box.size = Vector3(0.09 * scale_f, 0.11 * scale_f, 0.09 * scale_f)
	hand.mesh = h_box
	hand.material_override = skin_mat
	hand.position = Vector3(0, -0.46 * scale_f, 0)
	arm_node.add_child(hand)
	
	return arm_node

# ------------------------------------------------------------------------------
# HÀM PHỤ TRỢ: CHÂN & QUẦN
# ------------------------------------------------------------------------------
static func _build_leg(prof: ProfessionType, scale_f: float, side: float) -> Node3D:
	var leg_node = Node3D.new()
	leg_node.name = "Leg_%s" % ["L" if side < 0 else "R"]
	leg_node.position = Vector3(side * 0.12 * scale_f, 0.65 * scale_f, 0)
	
	# Ống quần
	var pants = MeshInstance3D.new()
	pants.name = "Pants"
	var box = BoxMesh.new()
	box.size = Vector3(0.15 * scale_f, 0.55 * scale_f, 0.16 * scale_f)
	pants.mesh = box
	pants.material_override = _get_pants_material(prof)
	pants.position = Vector3(0, -0.27 * scale_f, 0)
	leg_node.add_child(pants)
	
	# Giày
	var shoe = MeshInstance3D.new()
	shoe.name = "Shoe"
	var s_box = BoxMesh.new()
	s_box.size = Vector3(0.16 * scale_f, 0.11 * scale_f, 0.22 * scale_f)
	shoe.mesh = s_box
	shoe.material_override = _create_toon_mat(Color(0.22, 0.18, 0.15))
	shoe.position = Vector3(0, -0.58 * scale_f, -0.03 * scale_f)
	leg_node.add_child(shoe)
	
	return leg_node

# ------------------------------------------------------------------------------
# HÀM PHỤ TRỢ: VẬT DỤNG CẦM TAY
# ------------------------------------------------------------------------------
static func _add_held_prop(hand_node: Node3D, prof: ProfessionType, scale_f: float) -> void:
	match prof:
		ProfessionType.ENGINEER:
			# Ống đựng bản vẽ công trình
			var roll = MeshInstance3D.new()
			roll.name = "BlueprintRoll"
			var cyl = CylinderMesh.new()
			cyl.top_radius = 0.05 * scale_f
			cyl.bottom_radius = 0.05 * scale_f
			cyl.height = 0.55 * scale_f
			roll.mesh = cyl
			roll.material_override = _create_toon_mat(Color(0.25, 0.55, 0.85))
			roll.position = Vector3(0, -0.48 * scale_f, 0.15 * scale_f)
			roll.rotation_degrees = Vector3(70, 0, 0)
			hand_node.add_child(roll)
			
		ProfessionType.CARPENTER:
			# Búa mộc mỹ nghệ
			var hammer = MeshInstance3D.new()
			hammer.name = "CarpenterHammer"
			var h_mesh = BoxMesh.new()
			h_mesh.size = Vector3(0.06 * scale_f, 0.35 * scale_f, 0.15 * scale_f)
			hammer.mesh = h_mesh
			hammer.material_override = _create_toon_mat(Color(0.55, 0.45, 0.35))
			hammer.position = Vector3(0, -0.48 * scale_f, 0.1 * scale_f)
			hand_node.add_child(hammer)
			
		ProfessionType.TEACHER:
			# Sổ tay bài giảng
			var book = MeshInstance3D.new()
			book.name = "LessonBook"
			var b_mesh = BoxMesh.new()
			b_mesh.size = Vector3(0.05 * scale_f, 0.30 * scale_f, 0.22 * scale_f)
			book.mesh = b_mesh
			book.material_override = _create_toon_mat(Color(0.65, 0.15, 0.15))
			book.position = Vector3(0, -0.48 * scale_f, 0.1 * scale_f)
			hand_node.add_child(book)
			
		ProfessionType.BAKER:
			# Bánh mì Baguette thơm giòn
			var bread = MeshInstance3D.new()
			bread.name = "BaguetteBread"
			var cyl = CylinderMesh.new()
			cyl.top_radius = 0.04 * scale_f
			cyl.bottom_radius = 0.04 * scale_f
			cyl.height = 0.42 * scale_f
			bread.mesh = cyl
			bread.material_override = _create_toon_mat(Color(0.88, 0.62, 0.28))
			bread.position = Vector3(0, -0.48 * scale_f, 0.15 * scale_f)
			bread.rotation_degrees = Vector3(80, 0, 0)
			hand_node.add_child(bread)

# ------------------------------------------------------------------------------
# HÀM PHỤ TRỢ: PHỤ KIỆN ĐEO LƯNG
# ------------------------------------------------------------------------------
static func _add_back_accessory(torso: MeshInstance3D, prof: ProfessionType, scale_f: float) -> void:
	match prof:
		ProfessionType.FARMER:
			# Gùi tre thảo mộc đeo sau lưng
			var basket = MeshInstance3D.new()
			basket.name = "HerbBasket"
			var cyl = CylinderMesh.new()
			cyl.top_radius = 0.24 * scale_f
			cyl.bottom_radius = 0.16 * scale_f
			cyl.height = 0.45 * scale_f
			basket.mesh = cyl
			basket.material_override = _create_toon_mat(Color(0.72, 0.62, 0.42))
			basket.position = Vector3(0, 0, 0.22 * scale_f)
			torso.add_child(basket)
			
		ProfessionType.STUDENT:
			# Ba lô học sinh đeo sau lưng
			var bag = MeshInstance3D.new()
			bag.name = "SchoolBackpack"
			var box = BoxMesh.new()
			box.size = Vector3(0.28 * scale_f, 0.35 * scale_f, 0.16 * scale_f)
			bag.mesh = box
			bag.material_override = _create_toon_mat(Color(0.78, 0.28, 0.28))
			bag.position = Vector3(0, 0, 0.18 * scale_f)
			torso.add_child(bag)

# ------------------------------------------------------------------------------
# BẢNG VẬT LIỆU MÀU TRANG PHỤC (TOON MATERIALS)
# ------------------------------------------------------------------------------
static func _get_outfit_material(prof: ProfessionType) -> StandardMaterial3D:
	var color: Color
	match prof:
		ProfessionType.MAYOR:
			color = Color(0.18, 0.38, 0.72) # Xanh hoàng gia Thị Trưởng
		ProfessionType.CARPENTER:
			color = Color(0.68, 0.35, 0.22) # Áo kẻ thợ mộc
		ProfessionType.ENGINEER:
			color = Color(0.98, 0.48, 0.12) # Cam phản quang kỹ sư
		ProfessionType.FARMER:
			color = Color(0.35, 0.52, 0.32) # Xanh lá mộc mạc nông dân
		ProfessionType.DOCTOR:
			color = Color(0.96, 0.96, 0.98) # Blouse trắng bác sĩ
		ProfessionType.BAKER:
			color = Color(0.92, 0.92, 0.94) # Áo bếp trắng
		ProfessionType.TEACHER:
			color = Color(0.28, 0.52, 0.68) # Xanh thanh lịch giáo viên
		ProfessionType.STUDENT:
			color = Color(0.22, 0.28, 0.42) # Đồng phục navy học sinh
		ProfessionType.CITIZEN_KID:
			color = Color(0.95, 0.82, 0.22) # Vàng tươi thiếu nhi
		_:
			color = Color(0.5, 0.5, 0.5)
	return _create_toon_mat(color)

static func _get_pants_material(prof: ProfessionType) -> StandardMaterial3D:
	var color: Color
	match prof:
		ProfessionType.MAYOR:
			color = Color(0.92, 0.94, 0.96) # Quần âu trắng sáng
		ProfessionType.CARPENTER:
			color = Color(0.32, 0.28, 0.24) # Quần bò nâu đất
		ProfessionType.ENGINEER:
			color = Color(0.25, 0.28, 0.32) # Quần thợ xám chì
		ProfessionType.FARMER:
			color = Color(0.42, 0.36, 0.28) # Quần vải thô
		ProfessionType.DOCTOR:
			color = Color(0.85, 0.92, 0.95) # Quần y tế xanh nhạt
		ProfessionType.BAKER:
			color = Color(0.28, 0.28, 0.28) # Quần bếp đen
		ProfessionType.TEACHER:
			color = Color(0.22, 0.24, 0.28) # Quần tây đen
		ProfessionType.STUDENT:
			color = Color(0.18, 0.22, 0.32) # Quần đồng phục
		ProfessionType.CITIZEN_KID:
			color = Color(0.22, 0.42, 0.72) # Quần yếm denim xanh
		_:
			color = Color(0.3, 0.3, 0.3)
	return _create_toon_mat(color)

static func _create_toon_mat(col: Color) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 0.8
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat.specular_mode = BaseMaterial3D.SPECULAR_TOON
	return mat
