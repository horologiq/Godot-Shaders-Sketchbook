class_name UniformsInterpreter
extends RefCounted


class Line:
	var line_number
	var original_string
	var words
	var tokens = []

	func _init(l, s, w):
		line_number = l
		original_string = s
		words = w


class Token:
	var line_number
	var type  # DATATYPE, VARNAME, HINT, HINTVALUE or VARVALUE
	var value
	var pos

	func _init(l, t, v, p):
		line_number = l
		type = t
		value = v
		pos = p


class Lexer:
	# Hints whose arguments should be captured as HINTVALUE tokens.
	const HINTS_WITH_VALUES = ["hint_range", "hint_roughness", "filter", "repeat"]

	var g = Grammar.new()
	var number_regex = RegEx.new()

	func _init():
		number_regex.compile("^[0-9.-]*$")

	func create(text):
		var result = []
		var counter = 1

		for raw_line in text.split("\n"):
			if "uniform " in raw_line:
				var words = (raw_line
					.replace("=", " = ")
					.replace(":", " : ")
					.replace("(", " ( ")
					.replace(")", " ) ")
					.replace(";", " ; ")
					.replace(",", " , ")
					.split(" ", false))

				var line = Line.new(counter, raw_line, words)
				check_words(line)
				result.append(line)
			counter += 1

		return result

	func check_words(l):
		var size = l.words.size()

		if l.words[0] != "uniform" or size < 2 or not l.words[1] in g.TT_DATATYPES:
			return

		var pos = 1
		l.tokens.append(Token.new(l.line_number, "DATATYPE", l.words[1], pos))
		if size < 3:
			return

		pos += 1
		l.tokens.append(Token.new(l.line_number, "VARNAME", l.words[2], pos))
		if size < 4:
			return

		match l.words[3]:
			"=":
				append_value_tokens(l, l.words.slice(4), pos)
			":":
				check_hints(l, pos)

	func check_hints(l, pos):
		var size = l.words.size()

		for i in range(4, size):
			if l.words[i] == "=":
				append_value_tokens(l, l.words.slice(i + 1), pos)
				return

			if l.words[i] in g.TT_HINTS:
				pos += 1
				l.tokens.append(Token.new(l.line_number, "HINT", l.words[i], pos))

				if not l.words[i] in HINTS_WITH_VALUES:
					continue

				for b in range(i + 1, size):
					if l.words[b] == "=":
						append_value_tokens(l, l.words.slice(b), pos)
						break
					if number_regex.search(l.words[b]):
						pos += 1
						l.tokens.append(Token.new(l.line_number, "HINTVALUE", l.words[b], pos))
				return

	func append_value_tokens(l, words, pos):
		for value in look_for_values(words):
			pos += 1
			l.tokens.append(Token.new(l.line_number, "VARVALUE", value, pos))

	func look_for_values(words):
		var result = []
		for word in words:
			if number_regex.search(word) or word == "true" or word == "false":
				result.append(word)
		return result


func go(text):
	return Lexer.new().create(text)
