@tool
class_name DictionaryResource extends Resource

# Dictionary of strings to the type of its value
@export var type_hints: BasicDictionaryResource

var store: Dictionary


func _get_property_list() -> Array[Dictionary]:
	var ret: Array[Dictionary] = []

	if type_hints == null:
		return ret

	for typename in type_hints.value.keys():
		var type: int = typeof(type_hints.value[typename])
		var default_value: Variant = type_hints.value[typename]
		var stored_value: Variant = null if not store.has(typename) else store[typename]
		# var value: Variant = default_value if stored_value == null else stored_value
		var value := stored_value
		var packed_keys: PackedStringArray = PackedStringArray(type_hints.value.keys())
		var joint_keys: String = ",".join(packed_keys)
		(
			ret
			. append(
				{
					"name": typename,
					"type": type,
					"value": value,
					"hint": PROPERTY_HINT_ENUM,
					"hint_string": joint_keys,
					"usage": PROPERTY_USAGE_DEFAULT,
				}
			)
		)

	return ret


func _set(prop_name: StringName, val) -> bool:
	store[prop_name] = val  # is this needed?
	notify_property_list_changed()
	return true


func _get(prop_name: StringName):
	return store.get(prop_name)
