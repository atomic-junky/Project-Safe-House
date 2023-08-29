@tool
extends "../editor.gd"

func get_plugin() -> EditorImportPlugin:
	return preload("./import.gd").new()
