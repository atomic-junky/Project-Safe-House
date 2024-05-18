class_name EPIdleState
extends State


@export var moving_state: EPMovingState

var _idle_exit: bool = false
var _in_cooldown: bool = true


func _enter(_msg={}) -> void:
    _idle_exit = false
    _in_cooldown = true

    if node._current_elevator:
        await node._current_elevator.open
    
    await get_tree().create_timer(2.0).timeout
    _in_cooldown = false


func _do(_delta: float) -> void:
    if _idle_exit:
        return

    if !_in_cooldown and node._can_go() and (node.is_full() or node._current_elevator.is_empty()):
        _exit()

        _idle_exit = true


func _exit() -> void:
    await get_tree().create_timer(1.0).timeout

    parent.transition_to(moving_state)