@tool

class_name Logger

enum Levels {
	TRACE,
	DEBUG,
	INFO,
	WARN,
	ERROR,
	FATAL
}

static var LEVEL: Levels = Levels.INFO


static func log_msg(level: Levels, text: String) -> void:
	if level < LEVEL:
		return
	
	var now = Time.get_datetime_string_from_system()
	var message = "{date} [{level}] {text}".format({"date": now, "level": Levels.keys()[level], "text": text})
	
	return print(message)

static func trace(text: String) -> void:
	return log_msg(Levels.TRACE, text)

static func debug(text: String) -> void:
	return log_msg(Levels.DEBUG, text)

static func info(text: String) -> void:
	return log_msg(Levels.INFO, text)

static func warn(text: String) -> void:
	return log_msg(Levels.WARN, text)

static func error(text: String) -> void:
	return log_msg(Levels.ERROR, text)

static func fatal(text: String) -> void:
	return log_msg(Levels.FATAL, text)

