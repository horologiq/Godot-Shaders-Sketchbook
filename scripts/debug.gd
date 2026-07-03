extends Label

signal error_found(line_number)
signal ok

var line_number = 0
var error_count = 0


func _ready():
	update_debug()


func update_debug():
	var file = FileAccess.open("user://logs/output.log", FileAccess.READ)
	text = check_error(file.get_as_text())

	if line_number != null:
		error_found.emit(line_number)
	else:
		ok.emit()


func check_error(content):
	var expr
	var counter = 0

	for line in content.split("\n"):
		if line.begins_with("E"):
			counter += 1
			line_number = int(extract_line(line))
			expr = "Line " + str(line_number)

		if line.begins_with("USER SHADER ERROR:"):
			expr += ":" + line.trim_prefix("USER SHADER ERROR:")

	if counter > error_count:
		error_count += 1
		return expr

	line_number = null
	return "No errors found"


func extract_line(stn):
	var regex = RegEx.new()
	regex.compile("(\\d+)")
	return regex.search(stn).get_string()
