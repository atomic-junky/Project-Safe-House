@tool
extends EditorPlugin

const SceneMap = preload("scene_map.gd")
const SceneMapEditor = preload("editor/scene_map_editor.gd")
const ScenePalette = preload("scene_palette.gd")
const ScenePaletteInspector = preload("editor/palette/scene_palette_inspector.gd")

var scene_map_editor: SceneMapEditor
var scene_palette_inspector: ScenePaletteInspector


func _enter_tree() -> void:
	# Adding custom types appears to be broken, especially for resources; using "class_name" instead.
	# This does remove the ability to disable these types in the plugin manager.
	add_custom_type("SceneMap", "Node3D", SceneMap, preload("scene_map.svg"))
	add_custom_type("ScenePalette", "Resource", ScenePalette, preload("scene_palette.svg"))
	print("loading...")

	scene_palette_inspector = ScenePaletteInspector.new()
	add_inspector_plugin(scene_palette_inspector)

	scene_map_editor = preload("editor/scene_map_editor.tscn").instantiate()
	scene_map_editor.plugin = self
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_SIDE_RIGHT, scene_map_editor)
	scene_map_editor.hide()


func _exit_tree() -> void:
	print("unloading...")
	remove_control_from_container(
		EditorPlugin.CONTAINER_SPATIAL_EDITOR_SIDE_RIGHT, scene_map_editor
	)
	scene_map_editor.plugin = null
	scene_map_editor.free()
	scene_map_editor = null

	remove_inspector_plugin(scene_palette_inspector)

	# Also disabled due to issues registering custom types via plugin.
	remove_custom_type("ScenePalette")
	remove_custom_type("SceneMap")


func _edit(object: Object) -> void:
	if object is SceneMap:
		scene_map_editor.edit(object)
		scene_map_editor.show()


func _handles(object: Object) -> bool:
	return object is SceneMap


func _make_visible(visible: bool) -> void:
	if visible:
		scene_map_editor.show()
	else:
		scene_map_editor.edit(null)
		scene_map_editor.hide()


func _forward_3d_gui_input(camera: Camera3D, event: InputEvent) -> int:
	return scene_map_editor.handle_spatial_input(camera, event)
