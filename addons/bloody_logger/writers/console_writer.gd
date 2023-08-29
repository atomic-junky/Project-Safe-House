extends Writer
## Default console writer that just calls "print" to output to "Output" tab

func write(level: int, msg: String) -> void:
    if !_filter(level):
        return

    print(_parse_as_template(level, msg))


func write_stack(level: int, msg: String) -> void:
    if !_filter(level):
        return

    print(_add_stack_trace(_parse_as_template(level, msg), 3))
