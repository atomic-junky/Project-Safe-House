extends Writer
## Default file writer that limits output to at least error messages

var _mutex := Mutex.new()
var _file: FileAccess
var _counter := 0

var size_limit := 1024 * 1024 * 1024 # 1 GiB
var filename: String:
    get:
        # will return "file" in case of "file012.log" and "file.log"
        if _counter == 0:
            return filename.get_basename()
        else:
            var no_ext := filename.get_basename()
            return no_ext.substr(0, no_ext.length() - 3)
    set(value):
        if value.length() == 0:
            push_warning("Empty filename")
            return

        var with_ext := value + \
            ("" if _counter == 0 else "%03d" % _counter) + ".log"
        filename = value + ".log"
        if !FileAccess.file_exists(with_ext):
            _file = FileAccess.open(with_ext, FileAccess.WRITE)
        else:
            _file = FileAccess.open(with_ext, FileAccess.READ_WRITE)
            _file.seek_end()

        _check_file_size()


func write(level: int, msg: String) -> void:
    if !_filter(level):
        return

    var parsed := _parse_as_template(level, msg)

    _mutex.lock()
    for line in parsed.split("\n"):
        _file.store_line(line)

    _check_file_size()
    _mutex.unlock()


func write_stack(level: int, msg: String) -> void:
    if !_filter(level):
        return

    _mutex.lock()
    var parsed := _add_stack_trace(_parse_as_template(level, msg), 3)
    for line in parsed.split("\n"):
        _file.store_line(line)

    _check_file_size()
    _mutex.unlock()

# Checks whether it should move to another file
func _check_file_size() -> void:
    if _file != null && _file.get_length() < size_limit:
        return

    _counter += 1
    self.filename = self.filename
