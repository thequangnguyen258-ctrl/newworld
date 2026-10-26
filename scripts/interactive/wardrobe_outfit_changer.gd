class_name WardrobeOutfitChanger
extends Node3D

# ==============================================================================
# WARDROBE OUTFIT CHANGER - TỦ TRANG PHỤC THỊ TRƯỞNG (PHÒNG NGỦ MASTER)
# Cho phép Thị trưởng thay đổi giữa 3 bộ trang phục đặc trưng:
# 1. Âu Phục Lễ Tân Ngoại Giao (Formal Suit)
# 2. Đồ Dã Ngoại & Thị Sát Thực Địa (Field Outdoor Outfit)
# 3. Đồ Ngủ Lụa Thư Giãn (Silk Nightwear / Pajamas)
# Tuân thủ nghiêm ngặt Quy tắc 7 (Dual-Layer Safety 6.0m) & Quy tắc 8 (Diegetic UI).
# ==============================================================================

@export var interaction_radius: float = 6.0

var interaction_area: Area3D
var prompt_label: Label3D
var player_ref: Node3D = null

func _ready() -> void:
	add_to_group("interactive_stations")
	add_to_group("wardrobes")
	_build_wardrobe_mesh()
	_setup_interaction_area()
	_setup_prompt_label()

func _build_wardrobe_mesh() -> void:
	# Khung tủ gỗ óc chó cao cấp (Dark Walnut)
	var mat_wood := StandardMaterial3D.new()
	mat_wood.albedo_color = Color(0.24, 0.14, 0.08)
	mat_wood.roughness = 0.65

	var mat_mirror := StandardMaterial3D.new()
	mat_mirror.albedo_color = Color(0.85, 0.92, 0.98, 0.92)
	mat_mirror.metallic = 0.9
	mat_mirror.roughness = 0.1

	var mat_gold := StandardMaterial3D.new()
	mat_gold.albedo_color = Color(0.92, 0.78, 0.28)
	mat_gold.metallic = 0.8
	mat_gold.roughness = 0.2

	# Thân tủ lớn
	var closet := MeshInstance3D.new()
	closet.name = "WardrobeCabinet"
	var c_mesh := BoxMesh.new()
	c_mesh.size = Vector3(2.4, 2.7, 0.85)
	closet.mesh = c_mesh
	closet.position.y = 1.35
	closet.material_override = mat_wood
	add_child(closet)

	# Va chạm vật lý tủ
	var col_body := StaticBody3D.new()
	col_body.name = "WardrobeCollision"
	col_body.collision_layer = 1
	col_body.collision_mask = 1 | 2
	var col_shape := CollisionShape3D.new()
	var b_shape := BoxShape3D.new()
	b_shape.size = c_mesh.size
	col_shape.shape = b_shape
	col_shape.position = closet.position
	col_body.add_child(col_shape)
	add_child(col_body)

	# 3 Cánh cửa tủ ốp gương phản chiếu
	for i in range(3):
		var door_x = -0.75 + float(i) * 0.75
		var door := MeshInstance3D.new()
		door.name = "WardrobeDoor_%d" % (i + 1)
		var d_mesh := BoxMesh.new()
		d_mesh.size = Vector3(0.68, 2.35, 0.04)
		door.mesh = d_mesh
		door.position = Vector3(door_x, 1.35, 0.44)
		door.material_override = mat_mirror
		add_child(door)

		# Tay nắm cửa mạ vàng
		var handle := MeshInstance3D.new()
		handle.name = "DoorHandle_%d" % (i + 1)
		var h_mesh := BoxMesh.new()
		h_mesh.size = Vector3(0.04, 0.22, 0.04)
		handle.mesh = h_mesh
		handle.position = Vector3(door_x + 0.25, 1.35, 0.48)
		handle.material_override = mat_gold
		add_child(handle)

	# Nẹp đỉnh tủ mạ vàng Toon
	var crown := MeshInstance3D.new()
	crown.name = "WardrobeCrown"
	var cr_mesh := BoxMesh.new()
	cr_mesh.size = Vector3(2.48, 0.12, 0.92)
	crown.mesh = cr_mesh
	crown.position = Vector3(0.0, 2.72, 0.0)
	crown.material_override = mat_gold
	add_child(crown)

func _setup_interaction_area() -> void:
	interaction_area = Area3D.new()
	interaction_area.name = "WardrobeArea"
	interaction_area.collision_layer = 1 | 2 | 4
	interaction_area.collision_mask = 1 | 2 | 4

	var shape_node := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = interaction_radius
	shape_node.shape = shape
	shape_node.position.y = 1.0
	interaction_area.add_child(shape_node)
	add_child(interaction_area)

	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)

func _setup_prompt_label() -> void:
	prompt_label = Label3D.new()
	prompt_label.name = "WardrobePrompt"
	prompt_label.text = "🪞 [E/F] Tủ Trang Phục Thị Trưởng (Đổi Quần Áo)"
	prompt_label.font_size = 24
	prompt_label.outline_size = 8
	prompt_label.outline_modulate = Color(0.05, 0.07, 0.12, 0.95)
	prompt_label.modulate = Color(1.0, 0.88, 0.3)
	prompt_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	prompt_label.no_depth_test = true
	prompt_label.position = Vector3(0.0, 2.95, 0.0)
	prompt_label.visible = false
	add_child(prompt_label)

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if player_ref == null or not is_instance_valid(player_ref):
		player_ref = get_tree().get_first_node_in_group("player") as Node3D
	if player_ref == null:
		return

	var in_range := global_position.distance_to(player_ref.global_position) <= interaction_radius
	prompt_label.visible = in_range
	if in_range:
		_consider_nearest_interaction(player_ref)
	elif player_ref.has_meta("nearby_interactive") and player_ref.get_meta("nearby_interactive") == self:
		player_ref.remove_meta("nearby_interactive")

func _consider_nearest_interaction(player: Node3D) -> void:
	var nearby = player.get_meta("nearby_interactive") if player.has_meta("nearby_interactive") else null
	if not is_instance_valid(nearby) or not nearby is Node3D or not nearby.has_method("interact"):
		player.set_meta("nearby_interactive", self)
	elif global_position.distance_to(player.global_position) < nearby.global_position.distance_to(player.global_position):
		player.set_meta("nearby_interactive", self)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_ref = body
		prompt_label.visible = true
		_consider_nearest_interaction(body)

func _on_body_exited(body: Node3D) -> void:
	if body == player_ref:
		prompt_label.visible = false
		if body.has_meta("nearby_interactive") and body.get_meta("nearby_interactive") == self:
			body.remove_meta("nearby_interactive")

func interact(player: Node3D) -> void:
	if global_position.distance_to(player.global_position) > interaction_radius:
		return
	var hud := get_tree().get_first_node_in_group("hud")
	if hud != null and hud.has_method("open_wardrobe_modal"):
		hud.open_wardrobe_modal(self)
	else:
		push_error("[WardrobeOutfitChanger] HUD không cung cấp giao diện tủ trang phục.")
