class_name RoomPicker

# List of all rooms
#
# VAULTDOOR = 1
# ELEVATOR = 2
# LIVING_ROOM = 3
# POWER_GENERATOR = 4
# DINER = 5
# WATER_TREATMENT = 6
# STORAGE_ROOM = 7
# MEDBAY = 8
# SCIENCE_LAB = 9
# OVERSEER_OFFICE = 10
# RADIO_STUDIO = 11
# WEAPON_WORKSHOP = 12
# OUTFIT_WORKSHOP = 13

static var _class_picker: Dictionary = {
	RoomList.VAULTDOOR: VaultDoor,
	RoomList.ELEVATOR: ElevatorShaft,
	RoomList.LIVING_ROOM: LivingRoom,
	RoomList.POWER_GENERATOR: PowerGenerator,
	RoomList.DINER: Diner,
	RoomList.WATER_TREATMENT: WaterTreatment
}


static func pick(room_id: int):
	return _class_picker.get(room_id)
