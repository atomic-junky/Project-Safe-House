@tool
extends "../import.gd"

func _get_resource_type() -> String:
	return "PackedScene"

func _get_save_extension() -> String:
	#return "scn"
	return "tscn" # binary has a problem with the cache

func convert_scene(node: Node, options: Dictionary) -> Resource:
	var packed_scene = PackedScene.new()
	packed_scene.pack(node)
	return packed_scene
