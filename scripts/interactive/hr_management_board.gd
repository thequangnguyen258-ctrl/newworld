class_name HRManagementBoard
extends Node3D

signal hr_board_opened(enterprise: EnterpriseData)
signal hr_board_closed()

@export var enterprise: EnterpriseData
@export var prompt_message: String = "Nhấn [E] để mở Bảng Quản Trị Nhân Sự & 9 Bộ Ban"
@export var interaction_radius: float = 6.0

@onready var interaction_area: Area3D = $InteractionArea

var player_in_range: bool = false
var is_ui_open: bool = false
var prompt_label: Label3D = null

func _ready() -> void:
	add_to_group("interactive_stations")
	if not enterprise:
		enterprise = EnterpriseData.new("ENT_SAMPLE", "Doanh Nghiệp Đô Thị")
	if interaction_area:
		interaction_area.collision_layer = 1 | 2 | 4
		interaction_area.collision_mask = 1 | 2 | 4
		interaction_area.body_entered.connect(_on_player_entered)
		interaction_area.body_exited.connect(_on_player_exited)
	
	_create_prompt_label()

func _create_prompt_label() -> void:
	prompt_label = Label3D.new()
	prompt_label.text = "📋 [E] QUẢN TRỊ NHÂN SỰ & 9 BỘ BAN"
	prompt_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	prompt_label.no_depth_test = true
	prompt_label.font_size = 28
	prompt_label.position = Vector3(0, 2.2, 0)
	prompt_label.modulate = Color(0.3, 0.8, 1.0)
	prompt_label.visible = false
	add_child(prompt_label)

func _process(_delta: float) -> void:
	var player = get_tree().get_first_node_in_group("player") if get_tree() else null
	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		var in_range = (dist <= interaction_radius)
		if in_range != player_in_range:
			player_in_range = in_range
			if prompt_label:
				prompt_label.visible = player_in_range
			if in_range:
				player.set_meta("nearby_interactive", self)
			else:
				if player.has_meta("nearby_interactive") and player.get_meta("nearby_interactive") == self:
					player.remove_meta("nearby_interactive")

func _unhandled_input(event: InputEvent) -> void:
	if not player_in_range:
		return
	var is_interact_key = false
	if event is InputEventKey and event.pressed and not event.echo:
		var key = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		if key == KEY_E or key == KEY_F:
			is_interact_key = true
	if event.is_action_pressed("interact") or is_interact_key:
		toggle_board()
		get_viewport().set_input_as_handled()

func interact(_player: Node) -> void:
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
		if prompt_label:
			prompt_label.visible = true
		body.set_meta("nearby_interactive", self)

func _on_player_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		if prompt_label:
			prompt_label.visible = false
		if body.has_meta("nearby_interactive") and body.get_meta("nearby_interactive") == self:
			body.remove_meta("nearby_interactive")
		if is_ui_open:
			is_ui_open = false
			hr_board_closed.emit()
