class_name UniformsInterpreter
extends Node


class Line:
	var line_number
	var original_string
	var words
	var tokens = []

	func _init(l, s, w):
		self.line_number = l
		self.original_string = s
		self.words = w


class Token:
	var line_number
	var type  # DATATYPE, VARNAME, HINT, VARVALUE
	var value
	var pos

	func _init(l, t, v, p):
		self.line_number = l
		self.type = t
		self.value = v
		self.pos = p


class Lexer:
	var g = Grammar.new()

	func create(text):
		var regex = RegEx.new()
		regex.compile("uniform ")

		var result = []
		var counter = 1

		for i in text.split("\n"):
			if regex.search(i):
				var words = (
					i
					. replace("=", " = ")
					. replace(":", " : ")
					. replace("(", " ( ")
					. replace(")", " ) ")
					. replace(";", " ; ")
					. replace(",", " , ")
					. replace("  ", " ")
					. split(" ")
				)

				var c = 0
				for w in words:
					if " " in w or w == "":
						words.remove_at(c)
					c += 1

				var line = Line.new(counter, i, words)
				check_words(line)
				result.append(line)
			counter += 1

		return result

	func check_words(l):
		var size = l.words.size()
		var v = []
		var regex = RegEx.new()
		regex.compile("^[0-9.-]*$")
		var pos = 0

		if l.words[0] == "uniform":
			if size > 1:
				if l.words[1] in g.TT_DATATYPES:
					pos += 1
					l.tokens.append(Token.new(l.line_number, "DATATYPE", l.words[1], pos))
					if size > 2:
						pos += 1
						l.tokens.append(Token.new(l.line_number, "VARNAME", l.words[2], pos))
						if size > 3:
							var c = 3
							v = []
							match l.words[c]:
								":":
									for i in range(c + 1, size):
										if l.words[i] == "=":
											for j in range(i + 1, size):
												v.append(l.words[j])
											var val = look_for_values(v)
											for j in range(0, val.size()):
												pos += 1
												l.tokens.append(
													Token.new(
														l.line_number, "VARVALUE", val[j], pos
													)
												)
											break
										elif l.words[i] in g.TT_HINTS:
											pos += 1
											l.tokens.append(
												Token.new(l.line_number, "HINT", l.words[i], pos)
											)
											if (
												l.words[i]
												in [
													"hint_range",
													"hint_roughness",
													"filter",
													"repeat"
												]
											):
												for b in range(i + 1, size):
													if l.words[b] == "=":
														for j in range(b, size):
															v.append(l.words[j])
														var val = look_for_values(v)
														for j in range(0, val.size()):
															pos += 1
															l.tokens.append(
																Token.new(
																	l.line_number,
																	"VARVALUE",
																	val[j],
																	pos
																)
															)
														break
													if regex.search(l.words[b]):
														pos += 1
														l.tokens.append(
															Token.new(
																l.line_number,
																"HINTVALUE",
																l.words[b],
																pos
															)
														)
												break
										else:
											pass
								"=":
									for j in range(c + 1, size):
										v.append(l.words[j])
									var val = look_for_values(v)
									for j in range(0, val.size()):
										pos += 1
										l.tokens.append(
											Token.new(l.line_number, "VARVALUE", val[j], pos)
										)
								";":
									return
								_:
									return

	func look_for_values(v):
		var regex = RegEx.new()
		regex.compile("^[0-9.-]*$")
		var size = v.size()
		var result = []

		if size > 0:
			for i in range(size):
				if regex.search(v[i]) or v[i] == "true" or v[i] == "false":
					result.append(v[i])

		return result


func go(text):
	var l = Lexer.new()
	var result = l.create(text)
	return result
