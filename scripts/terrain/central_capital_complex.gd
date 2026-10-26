@tool
class_name CentralCapitalComplex
extends Node3D

# ==============================================================================
# CENTRAL CAPITAL COMPLEX - TRUNG TÂM THỦ PHỦ ĐỈNH VÁT
# Gắn liền với Đại Cao Ốc Mega-Office, Đại Hội Trường 15.000 Chỗ & Quảng Trường
# ==============================================================================

var visual_node: Node3D

func _ready() -> void:
	# Bám chuẩn xác độ cao thảo nguyên (+600m)
	var gh = ModularNatureChunk.get_world_height(global_position.x, global_position.z)
	global_position.y = gh

	if get_node_or_null("CentralCapitalComplex") == null:
		visual_node = CentralCapitalBuilder.build_capital_complex()
		add_child(visual_node)

	# Kết nối chuông phụng vụ khi đến giờ Thánh Lễ (chỉ khi đang chơi)
	if not Engine.is_editor_hint():
		var wm = get_node_or_null("/root/WorldManager")
		if wm:
			wm.liturgy_started.connect(_on_liturgy_started)
			wm.liturgy_ended.connect(_on_liturgy_ended)

	print("[CentralCapital] 🏛️ Khởi tạo thành công Khu Phức Hợp Trung Tâm Đỉnh Vát tại %s" % global_position)

func _on_liturgy_started(day_name: String) -> void:
	print("[CentralCapital] 🔔 CHUÔNG ĐẠI HỘI TRƯỜNG NGÂN VANG (%s 11:40)! Mời toàn thể cư dân về dự Thánh Lễ." % day_name)

func _on_liturgy_ended(_day_name: String) -> void:
	print("[CentralCapital] 🕊️ Bắt đầu Bữa Tiệc Bác Ái Agape tại Quảng Trường Trung Tâm!")
