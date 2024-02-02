extends Label

signal error_found(line_number)
signal ok(line_number)

@export var line_number = 0
@export var error_type = 0

var error_count = 0


func _ready():
	update_debug()


func update_debug():
	var file = FileAccess.open("user://logs/output.log", FileAccess.READ)
	var content = file.get_as_text()
	text = check_error(content)

	if line_number != null:
		error_found.emit(line_number)
	else:
		ok.emit()


func check_error(c):
	var list = c.split("\n")

	var expr
	var counter = 0

	for i in list:
		if i.left(1) == "E":
			counter += 1

			line_number = int(extract_line(i))
			expr = ("Line " + str(line_number))

		if i.left(18) == "USER SHADER ERROR:":
			error_type = clean_error(i, "USER SHADER ERROR:")
			expr += (": " + error_type)

	if counter > error_count:
		error_count += 1
		return expr

	line_number = null
	return "No errors found"


func extract_line(stn):
	var regex = RegEx.new()
	regex.compile("(\\d+)")
	var result = regex.search(stn)

	return result.get_string()


func clean_error(string: String, removal: String):
	var length = removal.length()
	var i = 0

	while i < string.length() - length:
		var piece = ""
		var j = i

		while j < i + length:
			piece += string[j]
			j += 1

		if piece == removal:
			return string.substr(0, j - length) + string.substr(j)

		i += 1

	return string
