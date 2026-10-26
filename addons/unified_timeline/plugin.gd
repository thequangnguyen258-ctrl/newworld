@tool
extends EditorPlugin

# ==============================================================================
# ADDON: UNIFIED TIMELINE (DÒNG THỜI GIAN THỐNG NHẤT) - GODOT 4.6.2
# Quản lý dòng thời gian thế giới đơn điệu luôn chảy về phía trước.
# Tự động nạp singleton UnifiedTimelineServer và kết nối đồng bộ cơ sở dữ liệu.
# ==============================================================================

const AUTOLOAD_NAME: String = "UnifiedTimelineServer"
const SERVER_PATH: String = "res://addons/unified_timeline/unified_timeline_server.gd"

func _enter_tree() -> void:
	if not ProjectSettings.has_setting("autoload/" + AUTOLOAD_NAME):
		add_autoload_singleton(AUTOLOAD_NAME, SERVER_PATH)
	print("[UnifiedTimelinePlugin] ⏳ Addon Dòng Thời Gian Thống Nhất đã kích hoạt thành công!")

func _exit_tree() -> void:
	remove_autoload_singleton(AUTOLOAD_NAME)
	print("[UnifiedTimelinePlugin] ⏳ Addon Dòng Thời Gian Thống Nhất đã ngừng hoạt động.")
