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

static var _dictionary: Dictionary = {
	RoomList.VAULTDOOR: VaultDoor,
	RoomList.ELEVATOR: Elevator,
	RoomList.LIVING_ROOM: LivingRoom,
	RoomList.POWER_GENERATOR: PowerGenerator,
	RoomList.DINER: Diner,
	RoomList.WATER_TREATMENT: WaterTreatment
}

static func pick(room_id: int):
	return _dictionary.get(room_id)
