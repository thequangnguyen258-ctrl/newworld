extends SceneTree

# ==============================================================================
# TEST SUITE: GODOT-VRM, MTOON SHADER, PHANTOM CAMERA & CINEMATIC RIGS
# Kiểm thử toàn diện:
# 1. Addons godot-vrm, Godot-MToon-Shader & phantom_camera nạp chuẩn xác.
# 2. VRMCharacterManager: Blendshapes biểu cảm, Tự động chớp mắt, Lip-sync khẩu hình.
# 3. VRMCharacterManager: Spring Bone dao động tóc và vạt áo theo gia tốc di chuyển.
# 4. PhantomCamera3D & PhantomCameraHost: Tích hợp trên Camera3D.
# 5. CinematicCameraController: 4 Rigs chuyển đổi linh hoạt (Player, Vehicle, Dialogue, Vista).
# ==============================================================================

const VRMCharacterManagerScript = preload("res://scripts/characters/vrm_character_manager.gd")
const CinematicCameraControllerScript = preload("res://scripts/camera/cinematic_camera_controller.gd")
const PhantomCamera3DScript = preload("res://addons/phantom_camera/scripts/phantom_camera/phantom_camera_3d.gd")
const PhantomCameraHostScript = preload("res://addons/phantom_camera/scripts/phantom_camera_host/phantom_camera_host.gd")

func _init() -> void:
	print("==================================================================")
	print("🧪 BẮT ĐẦU TEST: GODOT-VRM, MTOON SHADER & PHANTOM CAMERA")
	print("==================================================================")

	var root_node = Node3D.new()
	root.add_child(root_node)

	var pcam_mgr_script = load("res://addons/phantom_camera/scripts/managers/phantom_camera_manager.gd")
	if not Engine.has_singleton("PhantomCameraManager"):
		var pcam_mgr = pcam_mgr_script.new()
		Engine.register_singleton("PhantomCameraManager", pcam_mgr)
		root.add_child(pcam_mgr)

	# --------------------------------------------------------------------------
	# 1. KIỂM THỬ NẠP CÁC ADDONS CỐT LÕI
	# --------------------------------------------------------------------------
	print("\n--- 1. KIỂM THỬ ADDONS (VRM, MTOON, PHANTOM CAMERA) ---")
	var vrm_top = load("res://addons/vrm/vrm_toplevel.gd")
	assert(vrm_top != null, "Addon godot-vrm vrm_toplevel.gd phải nạp thành công")

	var vrm_spring = load("res://addons/vrm/vrm_spring_bone.gd")
	assert(vrm_spring != null, "Addon godot-vrm vrm_spring_bone.gd phải nạp thành công")

	var mtoon_shader = load("res://addons/Godot-MToon-Shader/mtoon_outline.gdshader")
	assert(mtoon_shader != null, "Addon Godot-MToon-Shader mtoon_outline.gdshader phải nạp thành công")

	var pcam_class = load("res://addons/phantom_camera/scripts/phantom_camera/phantom_camera_3d.gd")
	assert(pcam_class != null, "Addon phantom_camera PhantomCamera3D phải nạp thành công")

	var host_class = load("res://addons/phantom_camera/scripts/phantom_camera_host/phantom_camera_host.gd")
	assert(host_class != null, "Addon phantom_camera PhantomCameraHost phải nạp thành công")
	print(" [PASS] Toàn bộ 3 addons godot-vrm, MToon, phantom_camera đã nạp và biên dịch không lỗi.")

	# --------------------------------------------------------------------------
	# 2. KIỂM THỬ VRM CHARACTER MANAGER (BLENDSHAPES & BIỂU CẢM)
	# --------------------------------------------------------------------------
	print("\n--- 2. KIỂM THỬ VRM CHARACTER MANAGER ---")
	var vrm_char = VRMCharacterManagerScript.new()
	vrm_char.name = "VRMCharacter"
	root_node.add_child(vrm_char)
	if not vrm_char.is_node_ready():
		vrm_char._ready()

	assert(vrm_char.character_root != null, "VRMCharacterManager phải tạo được character root")
	assert(vrm_char.left_eye_mesh != null and vrm_char.right_eye_mesh != null, "Phải có mắt anime L và R")
	assert(vrm_char.mouth_mesh != null, "Phải có AnimeMouth mesh phục vụ khẩu hình lip-sync")
	assert(vrm_char.coat_tail_mesh != null, "Phải có vạt áo CoatTail cho spring bone")

	# Kiểm tra biểu cảm Joy
	vrm_char.set_expression(VRMCharacterManagerScript.ExpressionPreset.JOY, 1.0)
	assert(vrm_char.current_expression == VRMCharacterManagerScript.ExpressionPreset.JOY, "Biểu cảm phải là JOY")
	assert(vrm_char.left_eye_mesh.scale.y < 0.6, "Mắt phải híp lại khi cười (JOY)")

	# Kiểm tra biểu cảm Surprised
	vrm_char.set_expression(VRMCharacterManagerScript.ExpressionPreset.SURPRISED, 1.0)
	assert(vrm_char.left_eye_mesh.scale.y > 1.2, "Mắt phải mở to khi ngạc nhiên (SURPRISED)")
	assert(vrm_char.mouth_mesh.scale.y > 2.0, "Miệng phải há to khi ngạc nhiên (SURPRISED)")

	# Trở về Neutral
	vrm_char.set_expression(VRMCharacterManagerScript.ExpressionPreset.NEUTRAL, 1.0)
	assert(vrm_char.left_eye_mesh.scale == Vector3.ONE, "Mắt phải trở lại bình thường khi NEUTRAL")

	# Kiểm tra Chớp mắt tự nhiên (Auto-Blinking)
	vrm_char.is_blinking = true
	vrm_char.blink_progress = 0.5
	vrm_char._process(0.01)
	assert(vrm_char.left_eye_mesh.scale.y < 0.5, "Mắt phải nhắm lại khi đang trong chu trình chớp mắt")
	print(" [PASS] Blendshapes, biểu cảm khuôn mặt và chớp mắt tự nhiên hoạt động hoàn hảo.")

	# --------------------------------------------------------------------------
	# 3. KIỂM THỬ LIP-SYNC KHẨU HÌNH & SPRING BONE VẬT LÝ
	# --------------------------------------------------------------------------
	print("\n--- 3. KIỂM THỬ LIP-SYNC & SPRING BONES ---")
	vrm_char.start_speaking(3.0)
	assert(vrm_char.is_speaking, "Trạng thái speaking phải bật")
	assert(vrm_char.speaking_timer > 0.0, "Timer đối thoại phải đếm")

	vrm_char._process(0.1)
	assert(vrm_char.mouth_open_amount > 0.0, "Khẩu hình miệng phải mở nhấp nhô theo âm vị")

	vrm_char.stop_speaking()
	assert(not vrm_char.is_speaking, "Dừng nói chuyện phải tắt is_speaking")

	# Kiểm tra Spring Bone khi di chuyển
	vrm_char.global_position = Vector3(10.0, 0.0, 0.0)
	vrm_char._process(0.05)
	assert(vrm_char.hair_sway_offset != Vector3.ZERO or vrm_char.coat_tail_mesh.rotation != Vector3.ZERO, "Gia tốc di chuyển phải làm rung động tóc và vạt áo")
	print(" [PASS] Lip-sync khẩu hình miệng và Spring Bone vật lý đung đưa mượt mà.")

	# --------------------------------------------------------------------------
	# 4. KIỂM THỬ PHANTOM CAMERA 3D & HOST INTEGRATION
	# --------------------------------------------------------------------------
	print("\n--- 4. KIỂM THỬ PHANTOM CAMERA 3D & HOST ---")
	var cam = Camera3D.new()
	cam.name = "MainGameCamera"
	root_node.add_child(cam)

	var pcam_host = PhantomCameraHostScript.new()
	pcam_host.name = "PhantomCameraHost"
	cam.add_child(pcam_host)
	assert(cam.has_node("PhantomCameraHost"), "Camera3D phải gắn được PhantomCameraHost")

	var test_pcam = PhantomCamera3DScript.new()
	test_pcam.name = "TestPcam"
	test_pcam.priority = 15
	root_node.add_child(test_pcam)
	assert(test_pcam.priority == 15, "PhantomCamera3D priority phải là 15")
	print(" [PASS] Khởi tạo PhantomCamera3D và PhantomCameraHost thành công.")

	# --------------------------------------------------------------------------
	# 5. KIỂM THỬ CINEMATIC CAMERA CONTROLLER & 4 RIGS
	# --------------------------------------------------------------------------
	print("\n--- 5. KIỂM THỬ CINEMATIC CAMERA CONTROLLER ---")
	var cam_ctrl = CinematicCameraControllerScript.new()
	root_node.add_child(cam_ctrl)
	if not cam_ctrl.is_node_ready():
		cam_ctrl._ready()
	cam_ctrl.setup_camera_host(cam)

	assert(cam_ctrl.pcam_player != null, "Phải có pcam_player")
	assert(cam_ctrl.pcam_vehicle != null, "Phải có pcam_vehicle")
	assert(cam_ctrl.pcam_dialogue != null, "Phải có pcam_dialogue")
	assert(cam_ctrl.pcam_vista != null, "Phải có pcam_vista")
	assert(cam_ctrl.pcam_player.priority == 10, "pcam_player mặc định priority phải là 10")

	# Tạo Mock Player và NPC
	var mock_player = CharacterBody3D.new()
	mock_player.position = Vector3(0, 0, 0)
	root_node.add_child(mock_player)

	var mock_npc = Node3D.new()
	mock_npc.position = Vector3(0, 0, 3.0)
	root_node.add_child(mock_npc)

	cam_ctrl.set_player_target(mock_player)

	# Kích hoạt Camera đối thoại Anime (Over-the-shoulder)
	cam_ctrl.activate_dialogue_camera(mock_npc, mock_player)
	assert(cam_ctrl.current_state == CinematicCameraControllerScript.CameraState.NPC_DIALOGUE, "Phải chuyển sang NPC_DIALOGUE")
	assert(cam_ctrl.pcam_dialogue.priority == 30, "pcam_dialogue priority phải nâng lên 30")

	# Tắt đối thoại, trở về Player
	cam_ctrl.deactivate_dialogue_camera()
	assert(cam_ctrl.current_state == CinematicCameraControllerScript.CameraState.PLAYER_EXPLORATION, "Phải trở lại PLAYER_EXPLORATION")
	assert(cam_ctrl.pcam_dialogue.priority == 0, "pcam_dialogue priority phải về 0")

	# Kích hoạt Camera Phương tiện
	var mock_vehicle = Node3D.new()
	mock_vehicle.add_to_group("buggies")
	mock_vehicle.position = Vector3(20, 0, 20)
	root_node.add_child(mock_vehicle)

	cam_ctrl.activate_vehicle_camera(mock_vehicle)
	assert(cam_ctrl.current_state == CinematicCameraControllerScript.CameraState.VEHICLE_CRUISE, "Phải chuyển sang VEHICLE_CRUISE")
	assert(cam_ctrl.pcam_vehicle.priority == 20, "pcam_vehicle priority phải nâng lên 20")

	cam_ctrl.deactivate_vehicle_camera()
	assert(cam_ctrl.current_state == CinematicCameraControllerScript.CameraState.PLAYER_EXPLORATION, "Phải trở về PLAYER_EXPLORATION")

	# Kích hoạt Camera ngắm toàn cảnh Civic Vista
	cam_ctrl.trigger_civic_vista(Vector3(0, 150, 200), Vector3(0, 50, 0), 5.0)
	assert(cam_ctrl.current_state == CinematicCameraControllerScript.CameraState.CIVIC_VISTA, "Phải chuyển sang CIVIC_VISTA")
	assert(cam_ctrl.pcam_vista.priority == 40, "pcam_vista priority phải nâng lên 40")

	print(" [PASS] CinematicCameraController 4 rigs chuyển đổi trạng thái và priority chính xác tuyệt đối.")

	# Dọn dẹp an toàn các node PhantomCamera và VRM trước khi quit
	cam_ctrl.queue_free()
	mock_player.queue_free()
	mock_npc.queue_free()
	mock_vehicle.queue_free()
	vrm_char.queue_free()
	cam.queue_free()

	print("\n==================================================================")
	print("🎉 TẤT CẢ CÁC BÀI TEST VRM, MTOON & PHANTOM CAMERA ĐÃ THÀNH CÔNG RỰC RỠ!")
	print("==================================================================")
	quit(0)
