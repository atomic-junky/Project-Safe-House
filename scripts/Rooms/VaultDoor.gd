extends Room

class_name VaultDoor


var meshes = {
	2: MeshLink._meshes.VAULTDOOR
}


func _constructor():
	max_size = 2

	for key in meshes:
		var el = meshes[key]

		var working_pool_param = WorkingPoolParameters.new()
		working_pool_param.append_positions(
			key, MeshLink.get_spots(el.name)
		)

		working_spots = WorkingPool.new(working_pool_param)


var room_name: String = "Vault Door"