class_name CompositeState
extends State


var _active: bool = false


func _process(delta):
    if _active:
        _do(delta)


func do() -> void:
    _enter()
    _active = true
    await completed
    _active = false
    _exit()


func _get_node():
    return get_parent().node