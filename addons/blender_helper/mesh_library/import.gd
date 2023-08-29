@tool
extends "../import.gd"

func _get_resource_type() -> String:
	return "MeshLibrary"

func _get_save_extension() -> String:
	return "meshlib"

func _get_import_options(path: String, preset_index: int)  -> Array:
	var opts := super._get_import_options(path, preset_index)
	opts.append({"name": "create_collision", "default_value": false})
	return opts

func convert_scene(node: Node, options: Dictionary) -> Resource:
	var mesh_library = MeshLibrary.new()
	conv("", node, mesh_library, options["create_collision"])
	return mesh_library

func conv(path: String, node: Node, mesh_library: MeshLibrary, shapes: bool) -> void:
	for c in node.get_children():
		var name := path + String(c.name)
		var mesh := c as MeshInstance3D
		if mesh != null:
			var id := name.hash() & 0xFFFF #limit to 16 bit positiv interger
			var ids = mesh_library.get_item_list()
			while ids.has(id):
				id = (id + 1) & 0xFFFF
			mesh_library.create_item(id)
			mesh_library.set_item_mesh(id, mesh.mesh)
			mesh_library.set_item_name(id, name)
			if shapes:
				var shape = mesh.mesh.create_convex_shape(true, true)
				mesh_library.set_item_shapes(id, [shape, Transform3D.IDENTITY])
		conv(name, c, mesh_library, shapes)
