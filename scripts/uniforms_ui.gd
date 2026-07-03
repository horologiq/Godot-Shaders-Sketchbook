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

	const SCENES = {
		"float": preload("res://scenes/float.tscn"),
		"int": preload("res://scenes/int.tscn"),
		"vec2": preload("res://scenes/vec2.tscn"),
		"vec3": preload("res://scenes/vec3.tscn"),
		"vec4": preload("res://scenes/vec4.tscn"),
		"bool": preload("res://scenes/bool.tscn"),
		"sampler2D": preload("res://scenes/sampler2d.tscn"),
	}

	# Samplers fed by the engine, so no picker for them.
	const PASSIVE_SAMPLER_HINTS = [
		"hint_screen_texture", "hint_depth_texture", "hint_normal_roughness_texture",
	]

	var line_obj
	var passive_ui_state

	func _init(l, pas):
		line_obj = l
		passive_ui_state = pas

	func draw():
		if line_obj.tokens.is_empty():
			return null

		var datatype = line_obj.tokens[0].value
		var control

		match datatype:
			"float", "int", "vec2", "vec3", "vec4":
				control = SCENES[datatype].instantiate()
				control.user_entered_values.connect(
					on_user_entered_values.bind(line_obj.line_number)
				)
				if datatype == "vec2":
					control.user_entered_mouse_pos.connect(on_user_entered_mouse_pos)
			"bool":
				control = SCENES[datatype].instantiate()
				control.user_entered_bool.connect(
					on_user_entered_bool.bind(line_obj.line_number)
				)
			"sampler2D":
				for t in line_obj.tokens:
					if t.type == "HINT" and t.value in PASSIVE_SAMPLER_HINTS:
						return null
				control = SCENES[datatype].instantiate()
				control.user_entered_sampler.connect(on_user_entered_sampler)
			_:
				return null

		if line_obj.tokens.size() > 1:
			control.set_label(str(line_obj.tokens[1].value))

			var values = []
			var hints = []
			for t in line_obj.tokens:
				if t.type == "VARVALUE":
					values.append(t.value)
				elif t.type == "HINTVALUE":
					hints.append(t.value)

			control.set_values(values)
			control.restore(passive_ui_state)
			if hints.size() > 0:
				control.set_hints(hints)

		return control

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
	var lines_dic = {}

	for l in lines:
		var lhash = str(l.line_number)
		for tok in l.tokens:
			if tok.type == "DATATYPE":
				lhash += tok.value
		lines_dic[lhash] = l

	items.clear()

	for key in lines_dic:
		var item = ItemUI.new(lines_dic[key], passive_ui_state)
		item.p_sending_line_to_update.connect(_on_sending_line_to_update)
		item.p_sending_bool_to_update.connect(_on_sending_bool_to_update)
		item.p_sending_mouse_pos_to_update.connect(_on_sending_mouse_pos_to_update)
		item.p_sending_sampler_to_update.connect(_on_sending_sampler_to_update)
		items[key] = item


func _on_sending_line_to_update(values, line):
	var stn = ""
	var parts = []
	for value in values:
		parts.append(str(value))

	match values.size():
		1:
			stn = parts[0] + ";"
		2, 3, 4:
			stn = "vec%d(%s);" % [values.size(), ", ".join(parts)]

	sending_line_to_update.emit(stn, line)


func _on_sending_bool_to_update(toggled_on, line):
	sending_bool_to_update.emit(str(toggled_on) + ";", line)


func _on_sending_mouse_pos_to_update(varname, flag, pos):
	if flag:
		sending_mouse_pos_to_update.emit(varname, pos)


func _on_sending_sampler_to_update(varname, sampler):
	sending_sampler_to_update.emit(varname, sampler)
