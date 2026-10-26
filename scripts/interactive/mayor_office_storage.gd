extends Node3D

@export var interaction_radius: float = 6.0

var interaction_area: Area3D
var prompt_label: Label3D
var player_ref: Node3D

func _ready() -> void:
	add_to_group("interactive_stations")
	_setup_cabinet()
	_setup_interaction_area()
	_setup_prompt_label()

func _setup_cabinet() -> void:
	var cabinet_material := StandardMaterial3D.new()
	cabinet_material.albedo_color = Color(0.28, 0.16, 0.09)
	cabinet_material.roughness = 0.75
	var brass_material := StandardMaterial3D.new()
	brass_material.albedo_color = Color(0.83, 0.64, 0.24)
	brass_material.metallic = 0.7

	var cabinet := MeshInstance3D.new()
	cabinet.name = "MayorOfficeStorageCabinet"
	var cabinet_mesh := BoxMesh.new()
	cabinet_mesh.size = Vector3(1.8, 1.8, 0.8)
	cabinet.mesh = cabinet_mesh
	cabinet.position.y = 1.3
	cabinet.material_override = cabinet_material
	add_child(cabinet)

	var cabinet_body := StaticBody3D.new()
	cabinet_body.name = "CabinetCollision"
	cabinet_body.collision_layer = 1
	cabinet_body.collision_mask = 1 | 2
	var cabinet_collision := CollisionShape3D.new()
	var cabinet_shape := BoxShape3D.new()
	cabinet_shape.size = cabinet_mesh.size
	cabinet_collision.shape = cabinet_shape
	cabinet_collision.position = cabinet.position
	cabinet_body.add_child(cabinet_collision)
	add_child(cabinet_body)

	for drawer_index in range(3):
		var drawer := MeshInstance3D.new()
		drawer.name = "CabinetDrawer_%d" % (drawer_index + 1)
		var drawer_mesh := BoxMesh.new()
		drawer_mesh.size = Vector3(1.35, 0.04, 0.04)
		drawer.mesh = drawer_mesh
		drawer.position = Vector3(0.0, 0.85 + float(drawer_index) * 0.38, 0.42)
		drawer.material_override = brass_material
		add_child(drawer)

func _setup_interaction_area() -> void:
	interaction_area = Area3D.new()
	interaction_area.name = "OfficeStorageArea"
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
	prompt_label.name = "OfficeStoragePrompt"
	prompt_label.text = "🗄️ [E/F] Mở kho riêng trong Văn phòng Thị trưởng"
	prompt_label.font_size = 24
	prompt_label.outline_size = 8
	prompt_label.outline_modulate = Color(0.05, 0.07, 0.1, 0.95)
	prompt_label.modulate = Color(1.0, 0.88, 0.3)
	prompt_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	prompt_label.no_depth_test = true
	prompt_label.position = Vector3(0.0, 2.2, 0.0)
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
	if hud != null and hud.has_method("open_mayor_office_storage_modal"):
		hud.open_mayor_office_storage_modal(self)
	else:
		push_error("[MayorOfficeStorage] HUD không cung cấp giao diện kho văn phòng.")

func get_storage_summary() -> String:
	var inventory_script := load("res://scripts/economy/inventory_manager.gd")
	var stored: Dictionary = inventory_script.get_office_storage_items()
	if stored.is_empty():
		return "KHO RIÊNG ĐANG TRỐNG"
	var count := 0
	for quantity in stored.values():
		count += int(quantity)
	return "ĐANG LƯU %d MÓN • %.1f / %.0f KG" % [
		count,
		inventory_script.get_office_storage_weight_kg(),
		inventory_script.OFFICE_STORAGE_CAPACITY_KG
	]
