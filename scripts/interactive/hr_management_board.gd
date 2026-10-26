class_name HRManagementBoard
extends Node3D

signal hr_board_opened(enterprise: EnterpriseData)
signal hr_board_closed()

@export var enterprise: EnterpriseData
@export var prompt_message: String = "Nhấn [E] để mở Bảng Quản Trị Nhân Sự & 8 Bộ Ban"

@onready var interaction_area: Area3D = $InteractionArea

var player_in_range: bool = false
var is_ui_open: bool = false

func _ready() -> void:
	if not enterprise:
		enterprise = EnterpriseData.new("ENT_SAMPLE", "Doanh Nghiệp Đô Thị")
	if interaction_area:
		interaction_area.body_entered.connect(_on_player_entered)
		interaction_area.body_exited.connect(_on_player_exited)

func _unhandled_input(event: InputEvent) -> void:
	if player_in_range and event.is_action_pressed("interact"):
		toggle_board()

func toggle_board() -> void:
	is_ui_open = not is_ui_open
	if is_ui_open:
		hr_board_opened.emit(enterprise)
	else:
		hr_board_closed.emit()

func _on_player_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_in_range = true

func _on_player_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		if is_ui_open:
			is_ui_open = false
			hr_board_closed.emit()
