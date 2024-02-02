class_name UniformsUI
extends Node

signal sending_line_to_update(stn, line)
signal sending_mouse_pos_to_update(varname, pos)
signal sending_sampler_to_update(varname, sampler)
signal sending_bool_to_update(stn, line)

var items = {}
var passive_ui_state = {}

class ItemUI:
	signal p_sending_line_to_update(values, line)
	signal p_sending_mouse_pos_to_update(varname, flag, pos)
	signal p_sending_sampler_to_update(varname, sampler)
	signal p_sending_bool_to_update(toggled_on, line)

	var line_obj
	var control
	var passive_ui_state

	var sampler2d_scene = load("res://scenes/sampler2d.tscn")
	var vec2_scene = load("res://scenes/vec2.tscn")
	var vec3_scene = load("res://scenes/vec3.tscn")
	var vec4_scene = load("res://scenes/vec4.tscn")
	var float_scene = load("res://scenes/float.tscn")
	var int_scene = load("res://scenes/int.tscn")
	var bool_scene = load("res://scenes/bool.tscn")

	func _init(l, pas):
		self.line_obj = l
		self.passive_ui_state = pas

	func draw():
		var v
		var values = []
		var hints = []

		if line_obj.tokens.size() > 0:
			if line_obj.tokens[0].value == "vec4":
				v = vec4_scene.instantiate()
				v.user_entered_values.connect(on_user_entered_values.bind(line_obj.line_number))
			elif line_obj.tokens[0].value == "vec3":
				v = vec3_scene.instantiate()
				v.user_entered_values.connect(on_user_entered_values.bind(line_obj.line_number))
			elif line_obj.tokens[0].value == "vec2":
				v = vec2_scene.instantiate()
				v.user_entered_values.connect(on_user_entered_values.bind(line_obj.line_number))
				v.user_entered_mouse_pos.connect(on_user_entered_mouse_pos)
			elif line_obj.tokens[0].value == "float":
				v = float_scene.instantiate()
				v.user_entered_values.connect(on_user_entered_values.bind(line_obj.line_number))
			elif line_obj.tokens[0].value == "int":
				v = int_scene.instantiate()
				v.user_entered_values.connect(on_user_entered_values.bind(line_obj.line_number))
			elif line_obj.tokens[0].value == "bool":
				v = bool_scene.instantiate()
				v.user_entered_bool.connect(on_user_entered_bool.bind(line_obj.line_number))
			elif line_obj.tokens[0].value == "sampler2D":
				for t in line_obj.tokens:
					if t.type == "HINT":
						if (
							t.value == "hint_screen_texture"
							or t.value == "hint_depth_texture"
							or t.value == "hint_normal_roughness_texture"
						):
							return v
				v = sampler2d_scene.instantiate()
				v.user_entered_sampler.connect(on_user_entered_sampler)

			else:
				return v

			if line_obj.tokens.size() > 1:
				v.set_label(str(line_obj.tokens[1].value))

				for i in len(line_obj.tokens):
					if line_obj.tokens[i].type == "VARVALUE":
						values.append(line_obj.tokens[i].value)
					elif line_obj.tokens[i].type == "HINTVALUE":
						hints.append(line_obj.tokens[i].value)

				v.set_values(values)
				v.restore(passive_ui_state)

				if hints.size() > 0:
					v.set_hints(hints)

		return v

	func on_user_entered_values(values, line):
		p_sending_line_to_update.emit(values, line)

	func on_user_entered_bool(toggled_on, line):
		p_sending_bool_to_update.emit(toggled_on, line)

	func on_user_entered_mouse_pos(varname, flag, pos):
		p_sending_mouse_pos_to_update.emit(varname, flag, pos)

	func on_user_entered_sampler(varname, sampler):
		p_sending_sampler_to_update.emit(varname, sampler)


func flush():
	items = {}


func passive_flush():
	passive_ui_state = {}


func set_passive_ui_state(varname, value):
	passive_ui_state[varname] = value


func register_lines(lines):
	var lhash
	var lines_dic = {}

	for l in lines:
		lhash = str(l.line_number)
		for tok in l.tokens:
			if tok.type == "DATATYPE":
				lhash += tok.value

		lines_dic[lhash] = l

	items.clear()

	for l in lines_dic:
		items[l] = ItemUI.new(lines_dic[l], passive_ui_state)
		items[l].p_sending_line_to_update.connect(_on_sending_line_to_update)
		items[l].p_sending_bool_to_update.connect(_on_sending_bool_to_update)
		items[l].p_sending_mouse_pos_to_update.connect(_on_sending_mouse_pos_to_update)
		items[l].p_sending_sampler_to_update.connect(_on_sending_sampler_to_update)


func _on_sending_line_to_update(values, line):
	var stn: String

	if values.size() == 1:
		stn = str(values[0]) + ";"
	elif values.size() == 2:
		stn = "vec2(" + str(values[0]) + ", " + str(values[1]) + ");"
	elif values.size() == 3:
		stn = "vec3(" + str(values[0]) + ", " + str(values[1]) + ", " + str(values[2]) + ");"
	elif values.size() == 4:
		stn = (
			"vec4("
			+ str(values[0])
			+ ", "
			+ str(values[1])
			+ ", "
			+ str(values[2])
			+ ", "
			+ str(values[3])
			+ ");"
		)

	sending_line_to_update.emit(stn, line)


func _on_sending_bool_to_update(toggled_on, line):
	var stn = str(toggled_on) + ";"
	sending_bool_to_update.emit(stn, line)


func _on_sending_mouse_pos_to_update(varname, flag, pos):
	if flag == true:
		sending_mouse_pos_to_update.emit(varname, pos)


func _on_sending_sampler_to_update(varname, sampler):
	sending_sampler_to_update.emit(varname, sampler)
