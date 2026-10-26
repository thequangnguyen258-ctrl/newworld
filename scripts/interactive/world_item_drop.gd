class_name WorldItemDrop
extends Area3D

# ==============================================================================
# WORLD ITEM DROP - VẬT PHẨM RƠI NGOÀI THỰC ĐỊA 3D (TÂN THẾ GIỚI)
# 1. Hiển thị vật thể 3D nổi bồng bềnh và xoay tròn phát sáng nhẹ (Hover & Rotate).
# 2. Bảng 3D Diegetic hiển thị nhắc lệnh [E] Nhặt vật phẩm (Billboard, no_depth_test).
# 3. Bảo hiểm 2 lớp (Dual-Layer Safety: Area3D + Fallback cự ly <= 4.0m).
# 4. Tự động thêm vào InventoryManager và hiển thị Toast trên HUD khi nhặt.
# ==============================================================================

const InventoryManagerScript = preload("res://scripts/economy/inventory_manager.gd")

@export var item_id: String = "item_baguette"
@export var item_quantity: int = 1
@export var hover_amplitude: float = 0.12
@export var hover_speed: float = 3.0
@export var rotation_speed: float = 1.8
@export var interaction_radius: float = 4.0

var base_y: float = 0.0
var anim_time: float = 0.0
var prompt_label: Label3D
var mesh_container: Node3D
var is_player_nearby: bool = false
var player_ref: CharacterBody3D = null

func _ready() -> void:
	add_to_group("world_drops")
	base_y = position.y

	# Cấu hình Layer vật lý bảo hiểm 2 lớp (Layer 1|2|4)
	collision_layer = 1 | 2 | 4
	collision_mask = 1 | 2 | 4

	var col = CollisionShape3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = interaction_radius
	col.shape = sphere
	add_child(col)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# Container cho mô hình 3D vật phẩm
	mesh_container = Node3D.new()
	mesh_container.name = "ItemMeshContainer"
	add_child(mesh_container)
	_build_item_visual()

	# Bảng nhắc lệnh 3D Diegetic xuyên thấu
	prompt_label = Label3D.new()
	prompt_label.name = "PromptLabel"
	var def = InventoryManagerScript.ITEM_DEFINITIONS.get(item_id, {})
	var item_name = def.get("name", "Vật phẩm")
	var icon = def.get("icon", "📦")
	prompt_label.text = "[E] Nhặt %s %s" % [icon, item_name]
	prompt_label.font_size = 20
	prompt_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	prompt_label.no_depth_test = true
	prompt_label.modulate = Color(1.0, 0.95, 0.4)
	prompt_label.outline_render_priority = 10
	prompt_label.position = Vector3(0, 0.85, 0)
	prompt_label.visible = false
	add_child(prompt_label)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_ref = body as CharacterBody3D
		is_player_nearby = true
		if prompt_label:
			prompt_label.visible = true

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		is_player_nearby = false
		if prompt_label:
			prompt_label.visible = false

func _build_item_visual() -> void:
	match item_id:
		"item_baguette":
			var mesh_inst = MeshInstance3D.new()
			var cyl = CylinderMesh.new()
			cyl.top_radius = 0.08
			cyl.bottom_radius = 0.09
			cyl.height = 0.48
			mesh_inst.mesh = cyl
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.82, 0.55, 0.22)
			mat.roughness = 0.8
			mesh_inst.material_override = mat
			mesh_inst.rotation_degrees = Vector3(45, 30, 0)
			mesh_container.add_child(mesh_inst)

		"item_herbal_tea":
			var cup = MeshInstance3D.new()
			var cyl = CylinderMesh.new()
			cyl.top_radius = 0.12
			cyl.bottom_radius = 0.08
			cyl.height = 0.22
			cup.mesh = cyl
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.3, 0.65, 0.4)
			cup.material_override = mat
			mesh_container.add_child(cup)

		"item_lantern":
			var lantern = MeshInstance3D.new()
			var box = BoxMesh.new()
			box.size = Vector3(0.2, 0.32, 0.2)
			lantern.mesh = box
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.85, 0.65, 0.2)
			mat.emission_enabled = true
			mat.emission = Color(1.0, 0.8, 0.3)
			mat.emission_energy_multiplier = 2.0
			lantern.material_override = mat
			mesh_container.add_child(lantern)

		"item_wheat_sack":
			var sack = MeshInstance3D.new()
			var sph = SphereMesh.new()
			sph.radius = 0.22
			sph.height = 0.38
			sack.mesh = sph
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.88, 0.78, 0.5)
			sack.material_override = mat
			mesh_container.add_child(sack)

		_:
			# Mặc định: Khối quà phát sáng Toon
			var box = MeshInstance3D.new()
			var b = BoxMesh.new()
			b.size = Vector3(0.28, 0.28, 0.28)
			box.mesh = b
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.25, 0.8, 1.0)
			mat.emission_enabled = true
			mat.emission = Color(0.2, 0.7, 1.0)
			mat.emission_energy_multiplier = 1.2
			box.material_override = mat
			mesh_container.add_child(box)

func _process(delta: float) -> void:
	anim_time += delta
	# Hiệu ứng bồng bềnh & xoay tròn nhẹ
	if mesh_container:
		mesh_container.position.y = sin(anim_time * hover_speed) * hover_amplitude
		mesh_container.rotate_y(rotation_speed * delta)

	# Bảo hiểm 2 lớp (Fallback đo khoảng cách trực tiếp)
	if (player_ref == null or not is_instance_valid(player_ref)) and get_tree():
		player_ref = get_tree().get_first_node_in_group("player") as CharacterBody3D

	if player_ref and is_instance_valid(player_ref):
		var dist = global_position.distance_to(player_ref.global_position)
		var in_range = dist <= interaction_radius
		if in_range != is_player_nearby:
			is_player_nearby = in_range
			if prompt_label:
				prompt_label.visible = is_player_nearby

func _unhandled_input(event: InputEvent) -> void:
	if not is_player_nearby:
		return
	var is_e_key: bool = event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_E or event.physical_keycode == KEY_E)
	if event.is_action_pressed("interact") or is_e_key:
		pickup_item()
		get_viewport().set_input_as_handled()

## Thu nhặt vật phẩm vào túi đồ
func pickup_item() -> void:
	var def = InventoryManagerScript.ITEM_DEFINITIONS.get(item_id, {})
	var item_name = def.get("name", "Vật phẩm")
	var icon = def.get("icon", "📦")

	var tree = get_tree()
	var hud = tree.get_first_node_in_group("hud") if tree else null
	if not InventoryManagerScript.add_item(item_id, item_quantity):
		if hud and hud.has_method("show_toast"):
			hud.show_toast("Cặp mang theo đã đầy; vật phẩm vẫn ở nguyên trên mặt đất.")
		return
	if hud and hud.has_method("show_toast"):
		hud.show_toast("🎉 Đã nhặt +%d %s %s vào túi đồ!" % [item_quantity, icon, item_name])

	# Cập nhật hotbar nếu có
	if hud and hud.has_method("update_hotbar_display"):
		hud.update_hotbar_display()

	queue_free()
