@tool
extends EditorPlugin

const paths = preload("./paths.gd")

var plugin: EditorImportPlugin

func _enter_tree():
	plugin = get_plugin()
	add_import_plugin(plugin)
	if not ProjectSettings.has_setting(paths.setting_path):
		ProjectSettings.set_setting(paths.setting_path, "")
	ProjectSettings.set_initial_value(paths.setting_path, "")

func _exit_tree():
	if ProjectSettings.has_setting(paths.setting_path):
		ProjectSettings.set_setting(paths.setting_path, null)
	remove_import_plugin(plugin)
	plugin = null

func get_plugin() -> EditorImportPlugin:
	push_error("get_plugin not overwritten")
	return null
