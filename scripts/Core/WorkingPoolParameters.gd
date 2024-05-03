class_name WorkingPoolParameters


var _sizes: Dictionary = {}


func append_positions(size: int = 1, positions: Array = []):
	_sizes[size] = positions


func _from_markers(size: int, markers_parent: Node):
	var positions = []
	for marker in markers_parent.get_children():
		positions.append(marker.position)
	
	append_positions(size, positions)


static func _default():
	var parameters = WorkingPoolParameters.new()
	
	var y = 0.095
	
	parameters.append_positions(1, [
		Vector3(0.33, y, 0),
		Vector3(0.66, y, 0)
	])

	parameters.append_positions(2, [
		Vector3(1.2, y, 0),
		Vector3(2.4, y, 0),
		Vector3(3.6, y, 0),
		Vector3(4.8, y, 0)
	])
	
	parameters.append_positions(3, [
		Vector3(1.3, y, 0),
		Vector3(2.6, y, 0),
		Vector3(3.9, y, 0),
		Vector3(5.1, y, 0),
		Vector3(6.4, y, 0),
		Vector3(7.7, y, 0)
	])
	
	return parameters
