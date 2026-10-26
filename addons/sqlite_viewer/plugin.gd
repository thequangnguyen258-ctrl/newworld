@tool
extends EditorPlugin

# ==============================================================================
# SQLITE VIEWER EDITOR PLUGIN - GODOT 4.6.2
# Đăng ký Bảng Điều Khiển SQLite trực quan trên Main Screen của Godot Editor.
# ==============================================================================

const MainPanel = preload("res://addons/sqlite_viewer/sqlite_viewer_panel.gd")

var main_panel_instance: Control

func _enter_tree() -> void:
	main_panel_instance = MainPanel.new()
	main_panel_instance.name = "SQLiteViewer"
	
	# Thêm vào Editor Main Screen (Cùng hàng với 2D, 3D, Script, Game)
	EditorInterface.get_editor_main_screen().add_child(main_panel_instance)
	_make_visible(false)
	print("[SQLiteViewerPlugin] 🗄️ SQLite Viewer Dock đã kích hoạt thành công!")

func _exit_tree() -> void:
	if main_panel_instance:
		main_panel_instance.queue_free()
	print("[SQLiteViewerPlugin] 🗄️ SQLite Viewer Dock đã ngừng hoạt động.")

func _has_main_screen() -> bool:
	return true

func _make_visible(visible: bool) -> void:
	if main_panel_instance:
		main_panel_instance.visible = visible
		if visible and main_panel_instance.has_method("_refresh_tables_and_view"):
			main_panel_instance._refresh_tables_and_view()

func _get_plugin_name() -> String:
	return "SQLite Viewer"

func _get_plugin_icon() -> Texture2D:
	return EditorInterface.get_base_control().get_theme_icon("Database", "EditorIcons")
