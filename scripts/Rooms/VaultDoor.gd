extends Room

class_name VaultDoor


var meshes = {
	2: MeshLink._meshes.VAULTDOOR
}


func _constructor():
	max_size = 2


var room_name: String = "Vault Door"