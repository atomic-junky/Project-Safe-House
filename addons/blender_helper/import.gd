@tool
extends EditorImportPlugin

var paths := preload("./paths.gd")

enum Preset {
	DEFAULT
}

func _get_import_order() -> int:
	return IMPORT_ORDER_DEFAULT

func _get_importer_name() -> String:
	return "antonWetzel.importHelper.blender." + _get_resource_type()

func _get_option_visibility(path: String, option_name: StringName, options: Dictionary) -> bool:
	return true

func _get_preset_count()  -> int:
	return Preset.size()

func _get_preset_name(preset_index: int) -> String:
	match preset_index:
		Preset.DEFAULT:
			return "Default"
		_:
			return "Unknown"

func _get_priority() -> float:
	return 1.0

func _get_recognized_extensions() -> PackedStringArray:
	return PackedStringArray(["blend"])

func _get_visible_name() -> String:
	return "Import Helper Blender " + _get_resource_type()

func get_file_as_buffer(path: String) -> PackedByteArray:
	var file =  FileAccess.open(path, FileAccess.READ)
	var content = file.get_buffer(file.get_length())
	return content

func get_file_name(path: String) -> String:
	return path.get_file().split(".")[0]

func remove_file(path: String) -> int:
	var dir = DirAccess.open("res://")
	if dir == null:
		return FAILED
	return dir.remove(path)


func _import(source_file: String, save_path: String, options: Dictionary, platform_variants: Array, gen_files: Array) -> int:
	#I think source_file should be named source_path because it is not a File but a path (String)
	var global_file = ProjectSettings.globalize_path(source_file)
	var res := convert_resource(source_file, global_file, options)
	return ResourceSaver.save(res,save_path + "." + _get_save_extension())

func _get_import_options(path: String, preset_index: int)  -> Array:
	return [
		{"name": "open_editor", "default_value": 0, "property_hint": PROPERTY_HINT_ENUM, "hint_string": "No,Blocking"},
		{"name": "apply_modifiers", "default_value": true},
	]

func convert_scene(node: Node, options: Dictionary) -> Resource:
	push_error("convert_scene not overwritten")
	return null

func convert_resource(source_file: String, global_file: String, options: Dictionary) -> Resource:
	var blender = get_blender_command()
	if blender == "":
		return null
	match  options["open_editor"]:
		0:
			pass
		1:
			OS.execute(blender, [global_file])
	# Doc can be found here: https://docs.blender.org/api/current/bpy.ops.export_scene.html
	var python_expr = "import bpy;import sys;bpy.ops.export_scene.gltf(" + \
		"filepath='" + global_file.get_basename() + ".glb'," + \
		"export_apply=" + ("True" if options["apply_modifiers"] else "False") + ")"
	if OS.execute(blender, [global_file, "--background", "--python-expr", python_expr]) != OK:
		return null
	var state := GLTFState.new()
	var doc := GLTFDocument.new()
	var temp_file := source_file.get_basename() + ".glb"
	var content := get_file_as_buffer(temp_file)
	remove_file(temp_file)
	doc.append_from_buffer(content, "", state)
	var node := doc.generate_scene(state)
	node.name = get_file_name(source_file)
	cleanup(node)
	return convert_scene(node, options)

func cleanup(node: Node) -> void:

	#recursive for whole tree
	for c in node.get_children():
		cleanup(c)

	#remove digits from blenders unique names
	var name := String(node.name)
	var i := name.length() - 1
	while i > 1:
		var d := name[i]
		if not ('0' <= d and d <= '9'):
			break
		i = i - 1
	node.name = name.substr(0, i + 1)

	#replace ImportMeshInstance with MeshInstance
	var x := node as ImporterMeshInstance3D
	if x != null:
		var c := MeshInstance3D.new()
		c.name = x.name
		c.mesh = x.mesh.get_mesh()
		c.skin = x.skin
		c.transform = x.transform
		x.replace_by(c)
		x.free()


func get_blender_command() -> String:
	if not ProjectSettings.has_setting(paths.setting_path):
		push_error("missing blender path setting, please reactivate the plugin")
		return ""
	var locations : Array[String] = [ProjectSettings.get(paths.setting_path)]
	match OS.get_name():
		"Windows":
			for version in range(10):
				locations.append("C:/Program Files/BLender Foundation/Blender 3." + str(version) + "/blender.exe")
			locations.append("C:/Program Files (x86)/Steam/steamapps/common/Blender/blender.exe")
		"iOS":
			pass
		"Linux":
			locations.append("/usr/bin/blender")

	for location in locations:
		if FileAccess.file_exists(location):
			return location

	var ending := ""
	var sep = ":"
	if OS.get_name() == "Windows":
		ending = ".exe"
		sep = ";"

	for location in OS.get_environment("path").split(sep):
		location = location.trim_suffix("\n")
		if location.length() == 0:
			continue
		location += "/blender" + ending
		if FileAccess.file_exists(location):
			return location
	push_error("could not find blender in system path or " + JSON.new().stringify(locations))
	return ""
