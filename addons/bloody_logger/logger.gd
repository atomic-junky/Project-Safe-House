extends Node
class_name BloodyLogger

enum {
	TRACE = 0,
	DEBUG = 1,
	INFO = 2,
	WARN = 3,
	ERROR = 4,
	FATAL = 5,
}

var _state := {
	writers = [],
}

# Default console writer
static func default_console_writer() -> Writer:
	var node := Writer.new()
	var script := load("res://addons/bloody_logger/writers/console_writer.gd")
	node.set_script(script)
	return node

# Default file writer to file
static func default_error_file_writer(file_name := "error") -> Writer:
	var node := Writer.new()
	var script := \
		load("res://addons/bloody_logger/writers/error_file_writer.gd")
	node.set_script(script)
	node.filename = file_name
	node.min_level = ERROR
	return node

# Add new writer
func add_writer(writer: Writer) -> void:
	assert(writer != null)
	_state.writers.append(writer)

# Remove all writers
func clear_writers() -> void:
	_state.writers.clear()


func trace(msg: String) -> void:
	write(TRACE, msg)


func trace_stack(msg: String) -> void:
	write_stack(TRACE, msg)


func debug(msg: String) -> void:
	write(DEBUG, msg)


func debug_stack(msg: String) -> void:
	write_stack(DEBUG, msg)


func info(msg: String) -> void:
	write(INFO, msg)


func info_stack(msg: String) -> void:
	write(INFO, msg)


func warn(msg: String) -> void:
	write(WARN, msg)


func warn_stack(msg: String) -> void:
	write_stack(WARN, msg)


func error(msg: String) -> void:
	write(ERROR, msg)


func error_stack(msg: String) -> void:
	write_stack(ERROR, msg)


func fatal(msg: String) -> void:
	write(FATAL, msg)


func fatal_stack(msg: String) -> void:
	write_stack(FATAL, msg)


func write(severity: int, msg: String) -> void:
	for item in _state.writers:
		var writer := item as Writer
		writer.write(severity, msg)


func write_stack(severity: int, msg: String) -> void:
	for item in _state.writers:
		var writer := item as Writer
		writer.write_stack(severity, msg)
