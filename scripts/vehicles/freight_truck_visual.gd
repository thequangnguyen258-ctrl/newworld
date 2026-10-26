class_name FreightTruckVisual
extends Node3D

var truck_id: String = ""
var truck_class: String = ""
var display_name: String = ""
var status_label: Label3D
var cargo_body: MeshInstance3D
var vehicle_length: float = 5.0
var route_start: Vector3 = Vector3.ZERO
var route_origin: Vector3 = Vector3.ZERO
var route_destination: Vector3 = Vector3.ZERO
var has_active_route: bool = false

const ModularNatureChunkScript = preload("res://scripts/terrain/modular_nature_chunk.gd")

func configure(truck_data: Dictionary, slot_index: int) -> void:
	truck_id = str(truck_data["truck_id"])
	truck_class = str(truck_data["truck_class"])
	display_name = str(truck_data["display_name"])
	name = truck_id
	_build_visual()
	_set_status("ĐANG CHỜ ĐIỀU PHỐI")
	var slot := Vector2(float(slot_index % 2) * 9.0, float(slot_index / 2) * 10.0)
	set_idle_location(Vector2(142.0 + slot.x, 292.0 + slot.y))

func _build_visual() -> void:
	var vehicle_material := StandardMaterial3D.new()
	vehicle_material.albedo_color = Color(0.12, 0.38, 0.55)
	vehicle_material.metallic = 0.2
	vehicle_material.roughness = 0.5
	var cargo_material := StandardMaterial3D.new()
	cargo_material.albedo_color = Color(0.78, 0.45, 0.18)
	cargo_material.roughness = 0.7
	var tire_material := StandardMaterial3D.new()
	tire_material.albedo_color = Color(0.08, 0.08, 0.09)
	tire_material.roughness = 0.95

	var cab := MeshInstance3D.new()
	cab.name = "Cab"
	var cab_mesh := BoxMesh.new()
	cab_mesh.size = Vector3(1.9, 1.7, 2.1)
	cab.mesh = cab_mesh
	cab.material_override = vehicle_material
	cab.position = Vector3(0.0, 1.35, -vehicle_length * 0.25)
	add_child(cab)

	cargo_body = MeshInstance3D.new()
	cargo_body.name = "CargoBody"
	var cargo_mesh := BoxMesh.new()
	var cargo_length := 3.8
	match truck_class:
		"LIGHT":
			cargo_length = 3.0
		"MEDIUM":
			cargo_length = 4.2
		"CONTAINER":
			cargo_length = 7.4
		"HEAVY":
			cargo_length = 5.6
	cargo_mesh.size = Vector3(1.9, 2.2, cargo_length)
	cargo_body.mesh = cargo_mesh
	cargo_body.material_override = cargo_material
	cargo_body.position = Vector3(0.0, 1.65, 1.25)
	add_child(cargo_body)
	vehicle_length = cargo_length + 3.2

	for x_side in [-1.0, 1.0]:
		for z_axis in [-1.0, 1.0, 3.0]:
			var wheel := MeshInstance3D.new()
			wheel.name = "Wheel_%s_%s" % [str(x_side), str(z_axis)]
			var wheel_mesh := CylinderMesh.new()
			wheel_mesh.top_radius = 0.48
			wheel_mesh.bottom_radius = 0.48
			wheel_mesh.height = 0.32
			wheel.mesh = wheel_mesh
			wheel.material_override = tire_material
			wheel.position = Vector3(x_side * 1.0, 0.48, z_axis)
			wheel.rotation.z = PI * 0.5
			add_child(wheel)

	status_label = Label3D.new()
	status_label.name = "FleetStatus"
	status_label.text = "%s\n%s" % [display_name, truck_id]
	status_label.position = Vector3(0.0, 3.4, 0.0)
	status_label.font_size = 32
	status_label.outline_size = 8
	status_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	status_label.no_depth_test = true
	status_label.modulate = Color(1.0, 0.94, 0.72)
	add_child(status_label)

func _set_status(status: String) -> void:
	if status_label != null:
		status_label.text = "%s\n%s\n%s" % [display_name, truck_id, status]

func set_idle_location(position_xz: Vector2) -> void:
	has_active_route = false
	var target_position := Vector3(
		position_xz.x,
		ModularNatureChunkScript.get_world_height(position_xz.x, position_xz.y),
		position_xz.y
	)
	_set_world_position(target_position)
	_set_status("ĐANG CHỜ ĐIỀU PHỐI")

func begin_route(start: Vector2, origin: Vector2, destination: Vector2) -> void:
	route_start = Vector3(start.x, 0.0, start.y)
	route_origin = Vector3(origin.x, 0.0, origin.y)
	route_destination = Vector3(destination.x, 0.0, destination.y)
	has_active_route = true
	_set_status("ĐANG VẬN CHUYỂN")
	set_route_progress(0.0)

func set_route_progress(progress: float) -> void:
	if not has_active_route:
		return
	var start_to_origin := Vector2(route_start.x, route_start.z).distance_to(
		Vector2(route_origin.x, route_origin.z)
	)
	var origin_to_destination := Vector2(route_origin.x, route_origin.z).distance_to(
		Vector2(route_destination.x, route_destination.z)
	)
	var route_distance := start_to_origin + origin_to_destination
	var traveled_distance := clampf(progress, 0.0, 1.0) * route_distance
	var point: Vector3
	if route_distance <= 0.001:
		point = route_destination
	elif traveled_distance <= start_to_origin and start_to_origin > 0.001:
		point = route_start.lerp(route_origin, traveled_distance / start_to_origin)
	else:
		var second_leg_distance := maxf(origin_to_destination, 0.001)
		var second_leg_progress := clampf(
			(traveled_distance - start_to_origin) / second_leg_distance,
			0.0,
			1.0
		)
		point = route_origin.lerp(route_destination, second_leg_progress)
	var world_position := Vector3(
		point.x,
		ModularNatureChunkScript.get_world_height(point.x, point.z),
		point.z
	)
	_set_world_position(world_position)
	var target := route_origin if traveled_distance < start_to_origin else route_destination
	target.y = world_position.y
	var direction := target - world_position
	if direction.length_squared() > 0.01:
		rotation.y = atan2(-direction.x, -direction.z)

func finish_route(destination: Vector2) -> void:
	set_idle_location(destination)

func _set_world_position(world_position: Vector3) -> void:
	if is_inside_tree():
		global_position = world_position
	else:
		position = world_position
