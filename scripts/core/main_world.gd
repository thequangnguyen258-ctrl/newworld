@tool
class_name MainWorld
extends Node3D

# ==============================================================================
# MAIN WORLD - TÂN THẾ GIỚI (100% THIÊN NHIÊN NGUYÊN BẢN / PURE NATURE)
# Non nước hữu tình: Cao nguyên 600m, Vách đá giật cấp, Đại thác nước & Biển mây
# Bầu trời Anime Toon Shading & Chu kỳ Ngày - Đêm 24 Giờ hoàn chỉnh
# ==============================================================================

@onready var hud: HUDOverlay = get_node_or_null("HUDOverlay")

func _ready() -> void:
	print("[MainWorld] 🌿 Chào mừng đến với Tân Thế Giới - Bản Đồ Thiên Nhiên Nguyên Bản Hùng Vĩ!")
	if not Engine.is_editor_hint():
		call_deferred("_load_saved_game")

func _load_saved_game() -> void:
	var save_manager := get_node_or_null("/root/SaveManager")
	var player := get_node_or_null("Player")
	var world_manager := get_node_or_null("/root/WorldManager")
	if save_manager != null and player != null and world_manager != null:
		save_manager.load_game(player, world_manager)
