class_name CompositeState
extends State


var _active: bool = false


func _process(delta):
    if _active:
        _do(delta)


func do() -> void:
    _active = true
    _enter()
    await completed
    _exit()
    _active = false


func _get_node():
    return get_parent().node