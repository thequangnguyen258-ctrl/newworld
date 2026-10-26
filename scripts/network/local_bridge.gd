extends Node

# Autoload Singleton: LocalBridge
# Quản lý giao tiếp IPC cục bộ hoặc Mock Mode hỗ trợ gỡ lỗi và dashboard ngoài
signal command_received(command_name: String, payload: Dictionary)
signal state_dispatched(state_data: Dictionary)

@export var mock_mode_enabled: bool = true
var is_connected: bool = false

func _ready() -> void:
	if mock_mode_enabled:
		print("[LocalBridge] Đang hoạt động ở chế độ Mock Mode (Nội bộ Engine).")
		is_connected = true

func dispatch_game_event(event_type: String, data: Dictionary) -> void:
	if not is_connected:
		return
	var packet: Dictionary = {
		"timestamp": Time.get_unix_time_from_system(),
		"event": event_type,
		"data": data
	}
	state_dispatched.emit(packet)

func execute_local_command(command: String, args: Dictionary = {}) -> void:
	command_received.emit(command, args)
