class_name DoorController
extends Node3D

signal door_opened()
signal door_closed()

@export var is_open: bool = false
@export var open_angle_deg: float = 90.0
@export var swing_duration: float = 0.55
@export var auto_open_on_proximity: bool = true

@onready var hinge_pivot: Node3D = $DoorHingePivot
@onready var proximity_area: Area3D = $InteractionTrigger

var _tween: Tween

func _ready() -> void:
	if proximity_area:
		proximity_area.body_entered.connect(_on_body_entered)
		proximity_area.body_exited.connect(_on_body_exited)

func toggle_door() -> void:
	if is_open:
		close_door()
	else:
		open_door()

func open_door() -> void:
	if is_open:
		return
	is_open = true
	_animate_swing(deg_to_rad(open_angle_deg))
	door_opened.emit()

func close_door() -> void:
	if not is_open:
		return
	is_open = false
	_animate_swing(0.0)
	door_closed.emit()

func _animate_swing(target_y_rot: float) -> void:
	if not hinge_pivot:
		return
	if _tween and _tween.is_valid():
		_tween.kill()
		
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(hinge_pivot, "rotation:y", target_y_rot, swing_duration)

func _on_body_entered(body: Node3D) -> void:
	if auto_open_on_proximity and (body.is_in_group("player") or body.is_in_group("npc")):
		open_door()

func _on_body_exited(body: Node3D) -> void:
	if auto_open_on_proximity:
		# Kiểm tra xem còn ai trong trigger không
		var overlapping = proximity_area.get_overlapping_bodies()
		var anyone_left: bool = false
		for b in overlapping:
			if b != body and (b.is_in_group("player") or b.is_in_group("npc")):
				anyone_left = true
				break
		if not anyone_left:
			close_door()
