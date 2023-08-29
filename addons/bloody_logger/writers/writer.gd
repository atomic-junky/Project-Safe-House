extends Node
class_name Writer
## Please extend this file for custom loggers

var template := "{YYYY}-{MM}-{DD} ({TMZ}) {hh}:{mm}:{ss}.{mmm} [{level}] {msg}"
var min_level := BloodyLogger.TRACE
var max_level := BloodyLogger.FATAL


func _ready() -> void:
    assert(min_level <= max_level)


func write(level: int, msg: String) -> void:
    pass


func write_stack(level: int, msg: String) -> void:
    pass


func _filter(level: int) -> bool:
    return min_level <= level && level <= max_level


# You may want to override this function to parse custom values from template
# or if you don't want stuff like timezone to be calculated at all
func _parse_as_template(level: int, msg: String) -> String:
    var timedate := Time.get_datetime_dict_from_system()
    var timezone := Time.get_time_zone_from_system()

    return template.format({
        "level" = _string_level(level),
        "YYYY" = timedate.year,
        "MM" = "%02d" % timedate.month,
        "YY" = timedate.year % 100,
        "DD" = "%02d" % timedate.day,
        "TMZ" = Time.get_offset_string_from_offset_minutes(timezone.bias),
        "hh" = "%02d" % timedate.hour,
        "mm" = "%02d" % timedate.minute,
        "ss" = "%02d" % timedate.second,
        "mmm" = "%03d" % (int(Time.get_unix_time_from_system()) * 1000 % 1000),
        "msg" = msg,
    })

# Adds stack trace print to output
func _add_stack_trace(processed_template: String, skip := 0) -> String:
    var stack := get_stack()
    assert(stack.size() >= skip)

    var index := skip
    while index < stack.size():
        processed_template += "\n\t%s:%s at line %d" % \
            [stack[index].source, stack[index].function, stack[index].line]
        index += 1

    return processed_template

# Converts severity integer to its string name
func _string_level(level: int) -> String:
    match level:
        BloodyLogger.TRACE:
            return "TRACE"
        BloodyLogger.DEBUG:
            return "DEBUG"
        BloodyLogger.INFO:
            return "INFO"
        BloodyLogger.WARN:
            return "WARN"
        BloodyLogger.ERROR:
            return "ERROR"
        BloodyLogger.FATAL:
            return "FATAL"
        _:
            push_error("Unknown level: %d" % level)
            return ""
