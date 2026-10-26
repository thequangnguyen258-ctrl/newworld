class_name CinematicCameraController
extends Node3D

# ==============================================================================
# CINEMATIC CAMERA CONTROLLER (TÂN THẾ GIỚI - PHANTOM CAMERA 3D PIPELINE)
# Điều khiển camera điện ảnh mượt mà dựa trên PhantomCamera3D & PhantomCameraHost:
# 1. Pcam 1: Camera góc nhìn thứ 3 theo người chơi (Player Follow & Spring Damping).
# 2. Pcam 2: Camera xe cộ (Vehicle Follow: Buggy 7.5m, Trực thăng 15m, Dynamic FOV).
# 3. Pcam 3: Camera đối thoại Anime (Over-The-Shoulder Dialogue Framing khi gặp NPC).
# 4. Pcam 4: Camera toàn cảnh đô thị (Civic Vista Panoramas khi rung chuông / xem bản đồ).
# ==============================================================================

const PhantomCamera3DScript = preload("res://addons/phantom_camera/scripts/phantom_camera/phantom_camera_3d.gd")
const PhantomCameraHostScript = preload("res://addons/phantom_camera/scripts/phantom_camera_host/phantom_camera_host.gd")

enum CameraState {
	PLAYER_EXPLORATION,
	VEHICLE_CRUISE,
	NPC_DIALOGUE,
	CIVIC_VISTA
}

@export var player_follow_distance: float = 3.6
@export var player_follow_height: float = 1.4
@export var buggy_follow_distance: float = 7.5
@export var heli_follow_distance: float = 16.0

var host_camera: Camera3D = null
var pcam_host: PhantomCameraHost = null

var pcam_player: PhantomCamera3D = null
var pcam_vehicle: PhantomCamera3D = null
var pcam_dialogue: PhantomCamera3D = null
var pcam_vista: PhantomCamera3D = null

var current_state: CameraState = CameraState.PLAYER_EXPLORATION
var target_player: CharacterBody3D = null
var target_vehicle: Node3D = null
var vista_timer: float = 0.0

func _ready() -> void:
	add_to_group("cinematic_cameras")
	_build_phantom_camera_rigs()

## Khởi tạo và thiết lập các dàn PhantomCamera3D
func _build_phantom_camera_rigs() -> void:
	# 1. PCAM PLAYER FOLLOW (Mặc định Priority = 10)
	pcam_player = PhantomCamera3D.new()
	pcam_player.name = "PcamPlayerFollow"
	pcam_player.priority = 10
	pcam_player.follow_mode = PhantomCamera3D.FollowMode.SIMPLE
	add_child(pcam_player)

	# 2. PCAM VEHICLE (Priority = 0, chuyển thành 20 khi lên xe)
	pcam_vehicle = PhantomCamera3D.new()
	pcam_vehicle.name = "PcamVehicleCruise"
	pcam_vehicle.priority = 0
	pcam_vehicle.follow_mode = PhantomCamera3D.FollowMode.SIMPLE
	add_child(pcam_vehicle)

	# 3. PCAM DIALOGUE ANIME (Priority = 0, chuyển thành 30 khi nói chuyện)
	pcam_dialogue = PhantomCamera3D.new()
	pcam_dialogue.name = "PcamDialogueFraming"
	pcam_dialogue.priority = 0
	pcam_dialogue.follow_mode = PhantomCamera3D.FollowMode.NONE
	add_child(pcam_dialogue)

	# 4. PCAM CIVIC VISTA (Priority = 0, chuyển thành 40 khi xem toàn cảnh)
	pcam_vista = PhantomCamera3D.new()
	pcam_vista.name = "PcamCivicVista"
	pcam_vista.priority = 0
	pcam_vista.follow_mode = PhantomCamera3D.FollowMode.NONE
	add_child(pcam_vista)

	print("[CinematicCamera] 🎥 Đã cấu hình xong 4 rigs PhantomCamera3D (Player, Vehicle, Dialogue, Vista).")

## Gắn kết Camera3D với PhantomCameraHost
func setup_camera_host(cam: Camera3D) -> void:
	if cam == null:
		return
	host_camera = cam

	# Kiểm tra nếu Camera3D đã có PhantomCameraHost
	pcam_host = cam.get_node_or_null("PhantomCameraHost") as PhantomCameraHost
	if pcam_host == null:
		pcam_host = PhantomCameraHostScript.new()
		pcam_host.name = "PhantomCameraHost"
		cam.add_child(pcam_host)
		print("[CinematicCamera] 🎬 Đã khởi tạo PhantomCameraHost trên Camera3D chính.")

## Thiết lập mục tiêu Player
func set_player_target(player: CharacterBody3D) -> void:
	target_player = player
	if pcam_player and player:
		pcam_player.follow_target = player
		pcam_player.look_at_target = player

func _process(delta: float) -> void:
	# Cập nhật vị trí camera theo trạng thái hiện hành
	match current_state:
		CameraState.PLAYER_EXPLORATION:
			if target_player and is_instance_valid(target_player):
				var p_pos = target_player.global_position
				var yaw = target_player.rotation.y
				if target_player.has_node("Head"):
					yaw = target_player.get_node("Head").global_rotation.y
				var offset = Vector3(sin(yaw), 0, cos(yaw)) * player_follow_distance
				var target_cam_pos = p_pos + offset + Vector3(0, player_follow_height, 0)
				pcam_player.global_position = pcam_player.global_position.lerp(target_cam_pos, delta * 12.0)
				var look_tgt = p_pos + Vector3(0, 1.2, 0)
				if pcam_player.global_position.distance_squared_to(look_tgt) > 0.01:
					pcam_player.look_at(look_tgt, Vector3.UP)

		CameraState.VEHICLE_CRUISE:
			if target_vehicle and is_instance_valid(target_vehicle):
				var v_pos = target_vehicle.global_position
				var v_basis = target_vehicle.global_transform.basis
				var is_heli = target_vehicle.is_in_group("helicopters")
				var dist = heli_follow_distance if is_heli else buggy_follow_distance
				var h_offset = 6.0 if is_heli else 2.5
				var target_pos = v_pos - v_basis.z * dist + Vector3(0, h_offset, 0)
				pcam_vehicle.global_position = pcam_vehicle.global_position.lerp(target_pos, delta * 8.0)
				var v_look_tgt = v_pos + Vector3(0, 1.0, 0)
				if pcam_vehicle.global_position.distance_squared_to(v_look_tgt) > 0.01:
					pcam_vehicle.look_at(v_look_tgt, Vector3.UP)

		CameraState.CIVIC_VISTA:
			if vista_timer > 0.0:
				vista_timer -= delta
				if vista_timer <= 0.0:
					deactivate_civic_vista()

## Kích hoạt Camera đối thoại Anime góc nhìn vai (Over-the-Shoulder)
func activate_dialogue_camera(npc: Node3D, player: Node3D) -> void:
	if npc == null or player == null:
		return
	current_state = CameraState.NPC_DIALOGUE

	var npc_pos = npc.global_position + Vector3(0, 1.4, 0)
	var p_pos = player.global_position + Vector3(0, 1.4, 0)
	var dir_to_npc = (npc_pos - p_pos).normalized()
	var right_vec = dir_to_npc.cross(Vector3.UP).normalized()

	# Đặt camera chếch phía sau vai người chơi nhìn sang NPC
	var cam_pos = p_pos - dir_to_npc * 0.85 + right_vec * 0.55 + Vector3(0, 0.15, 0)
	pcam_dialogue.global_position = cam_pos
	pcam_dialogue.look_at(npc_pos, Vector3.UP)
	pcam_dialogue.priority = 30
	print("[CinematicCamera] 💬 Kích hoạt Camera đối thoại Anime Over-the-shoulder (Priority = 30).")

## Tắt Camera đối thoại, trở về Player
func deactivate_dialogue_camera() -> void:
	pcam_dialogue.priority = 0
	current_state = CameraState.PLAYER_EXPLORATION
	print("[CinematicCamera] 🎥 Quay trở lại Camera Player chuẩn.")

## Kích hoạt Camera Xe Cộ / Trực Thăng
func activate_vehicle_camera(vehicle: Node3D) -> void:
	target_vehicle = vehicle
	current_state = CameraState.VEHICLE_CRUISE
	pcam_vehicle.priority = 20
	print("[CinematicCamera] 🚗 Kích hoạt Camera theo đuôi phương tiện (Priority = 20).")

## Tắt Camera Phương Tiện
func deactivate_vehicle_camera() -> void:
	pcam_vehicle.priority = 0
	target_vehicle = null
	current_state = CameraState.PLAYER_EXPLORATION
	print("[CinematicCamera] 🎥 Người chơi rời phương tiện, kích hoạt lại Camera bộ hành.")

## Kích hoạt Camera ngắm toàn cảnh Vista (Quảng Trường / Tháp Chuông)
func trigger_civic_vista(vista_pos: Vector3, look_at_pos: Vector3, duration: float = 6.0) -> void:
	current_state = CameraState.CIVIC_VISTA
	vista_timer = duration
	pcam_vista.global_position = vista_pos
	pcam_vista.look_at(look_at_pos, Vector3.UP)
	pcam_vista.priority = 40
	print("[CinematicCamera] 🏛️ Kích hoạt Camera toàn cảnh Civic Vista trong %.1fs (Priority = 40)." % duration)

## Tắt Camera toàn cảnh
func deactivate_civic_vista() -> void:
	pcam_vista.priority = 0
	current_state = CameraState.PLAYER_EXPLORATION
