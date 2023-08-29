@tool
extends BloodyLogger

func _ready() -> void:
	Logger.clear_writers()
	Logger.add_writer(BloodyLogger.default_console_writer())
	Logger.add_writer(BloodyLogger.default_error_file_writer())
