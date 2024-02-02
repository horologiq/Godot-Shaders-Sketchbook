extends Node

var dir_canvas = "res://shaders/canvas_item/"
var dir_spatial = "res://shaders/spatial/"
var def_canvas = "res://material/def_canvas_item.gdshader"
var def_spatial = "res://material/def_canvas_item.gdshader"
var img_ok = load("res://theme/ok.png")
var img_fail = load("res://theme/alert.png")
var default_canvas = load(def_canvas)
var default_spatial = load(def_spatial)

var interpreter = UniformsInterpreter.new()
var uniforms_ui = UniformsUI.new()

var current_file_path = null
var sel = 0
var target_mode = 0
var array_dir = []
var uniforms
var code_ok = true
var modified_flag = false
var rotation = true
var rotx = randf_range(-0.3, 0.3)
var roty = randf_range(-0.3, 0.3)
var rotz = randf_range(-0.3, 0.3)

@onready var canvas = $ui/canvas_item
@onready var target_spatial_cube = $ui/canvas_item/sv/cube
@onready var target_spatial_mesh = $ui/canvas_item/sv/cam/cam_mesh
@onready var code = $ui/code_window/ctl/vbox/hbox2/code
@onready var debug_label = $ui/code_window/ctl/vbox/hbox3/debug
@onready var side_panel = $ui/code_window/ctl/vbox/hbox2/vbox
@onready var uniforms_panel = $ui/code_window/ctl/vbox/hbox2/vbox/vbox/scroll/vbox
@onready var warning = $ui/code_window/ctl/vbox/hbox3/warning
@onready var target_button = $ui/code_window/ctl/vbox/VBoxContainer/hbox4/target
@onready var panel_button = $ui/code_window/ctl/vbox/VBoxContainer/hbox4/panel
@onready var open_window = $ui/code_window/open_window
@onready var save_window = $ui/code_window/save_window


func _ready():
	warning.texture = img_ok
	debug_label.connect("ok", _on_ok_raised)
	debug_label.connect("error_found", _on_error_raised)
	uniforms_ui.sending_line_to_update.connect(_on_sending_line_to_update)
	uniforms_ui.sending_bool_to_update.connect(_on_sending_bool_to_update)
	uniforms_ui.sending_mouse_pos_to_update.connect(_on_sending_mouse_pos_to_update)
	uniforms_ui.sending_sampler_to_update.connect(_on_sending_sampler_to_update)
	clear_shaders_from_objects()
	run()


func _process(delta):
	$ui/canvas_item/sv/ball.rotate_x(rotx * delta)
	$ui/canvas_item/sv/ball.rotate_y(roty * delta)
	$ui/canvas_item/sv/ball.rotate_z(rotz * delta)

	if rotation == true:
		change_rot()
		target_spatial_cube.rotate_x(rotx * delta)
		target_spatial_cube.rotate_y(roty * delta)
		target_spatial_cube.rotate_z(rotz * delta)


func run():
	set_shader_type()

	if code.text != "" and sel == 0:
		canvas.material.shader.set_code(code.text)
	elif code.text != "" and sel == 1:
		if target_mode == 0:
			target_spatial_mesh.visible = false
			target_spatial_cube.material.shader.set_code(code.text)
		elif target_mode == 1:
			target_spatial_mesh.visible = true
			target_spatial_mesh.mesh.material.shader.set_code(code.text)

	update_uniforms_interpreter()


func change_rot():
	var r = randi_range(0, 1000)
	if r == 1000:
		rotx = randf_range(-0.3, 0.3)
		roty = randf_range(-0.3, 0.3)
		rotz = randf_range(-0.3, 0.3)


func clear_shaders_from_objects():
	canvas.material.shader.set_code(default_canvas.get_code())
	target_spatial_mesh.mesh.material.shader.set_code(default_spatial.get_code())
	target_spatial_cube.material.shader.set_code(default_spatial.get_code())


func save(path):
	current_file_path = path
	var content = code.text
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(content)
	modified_flag = false


func open(path):

	target_mode = 0
	uniforms_ui.flush()
	uniforms_ui.passive_flush()

	var sh = load(path)
	code.text = sh.get_code()
	modified_flag = false
	current_file_path = path



func retarget():
	clear_shaders_from_objects()
	if target_mode == 0:
		target_mode = 1
	elif target_mode == 1:
		target_mode = 0


func update_uniforms_interpreter():
	if code.text != "" && sel == 0:
		uniforms = interpreter.go(code.text)
	elif code.text != "" && sel == 1:
		uniforms = interpreter.go(code.text)

	uniforms_ui.register_lines(uniforms)

	update_uniforms_ui()


func update_uniforms_ui():
	for i in uniforms_panel.get_children():
		i.queue_free()

	var keys = uniforms_ui.items.keys()
	keys.sort_custom(func(a, b): return a.naturalnocasecmp_to(b) < 0)
	for key in keys:
		var l = uniforms_ui.items[key].draw()
		uniforms_panel.add_child(l)


func set_shader_type():
	clear_shaders_from_objects()
	var regex_spatial = RegEx.new()
	var regex_canvas_item = RegEx.new()
	regex_spatial.compile("shader_type *spatial")
	regex_canvas_item.compile("shader_type *canvas_item")
	if regex_canvas_item.search(code.text):
		sel = 0
		$ui/code_window/ctl/vbox/hbox3/mode.text = "Canvas item mode"
		target_button.set_disabled(true)
	elif regex_spatial.search(code.text):
		sel = 1
		$ui/code_window/ctl/vbox/hbox3/mode.text = "Spatial mode"
		target_button.set_disabled(false)


func _on_target_pressed():
	retarget()
	run()


func _on_sending_line_to_update(stn, line):
	var t = code.get_line(line - 1)
	var v
	if "=" in t:
		v = t.split("=")
	else:
		v = t.split(";")
	code.set_line(line - 1, v[0] + "= " + stn)
	code.grab_focus()


func _on_sending_bool_to_update(stn, line):
	var t = code.get_line(line - 1)
	var v
	if "=" in t:
		v = t.split("=")
	else:
		v = t.split(";")
	code.set_line(line - 1, v[0] + "= " + stn)
	code.grab_focus()


func _on_sending_mouse_pos_to_update(varname, pos):
	uniforms_ui.set_passive_ui_state(varname, pos)

	if sel == 0:
		canvas.material.set_shader_parameter(varname, pos)
	elif sel == 1:
		if target_mode == 0:
			target_spatial_cube.material.set_shader_parameter(varname, pos)
		if target_mode == 1:
			target_spatial_mesh.mesh.material.set_shader_parameter(varname, pos)


func _on_sending_sampler_to_update(varname, sampler):
	var s

	uniforms_ui.set_passive_ui_state(varname, sampler)

	match sampler:
		0:
			s = null
		1:
			s = load("res://textures/simple.tres")
		2:
			s = load("res://textures/animated.tres")
		3:
			s = load("res://textures/gradient.tres")
		4:
			s = load("res://textures/noise.tres")
		5:
			s = load("res://textures/normal.tres")
		6:
			var img = get_viewport().get_texture().get_image()
			s = ImageTexture.create_from_image(img)
		_:
			return

	if sel == 0:
		canvas.material.set_shader_parameter(varname, s)
	elif sel == 1:
		if target_mode == 0:
			target_spatial_cube.material.set_shader_parameter(varname, s)
		elif target_mode == 1:
			target_spatial_mesh.mesh.material.set_shader_parameter(varname, s)


func _on_panel_pressed():
	if side_panel.visible:
		panel_button.text = "Show panel"
		side_panel.visible = false
	else:
		panel_button.text = "Hide panel"
		side_panel.visible = true


func _on_open_window_file_selected(path):
	open(path)

	$ui/code_window.set_title("Godot Shaders Sketchbook " + "[ " + path.replace("res://shaders/", "").replace(".gdshader","") + " ]")
	$ui/code_window/ctl/vbox/VBoxContainer/hbox4/save.set_disabled(false)
	run()


func _on_open_pressed():
	if modified_flag == true:
		$ui/code_window/open_confirm.visible = true
	else:
		_on_open_confirm_confirmed()
		


func _on_open_confirm_confirmed():
	if open_window.visible:
		open_window.visible = false
	else:
		open_window.visible = true
	


func _on_save_as_pressed():
	if save_window.visible:
		save_window.visible = false
	else:
		save_window.visible = true
		if current_file_path != null:
			save_window.set_current_path(current_file_path)
			
			



func _on_save_window_file_selected(path):
	save(path)
	$ui/code_window/ctl/vbox/VBoxContainer/hbox4/save.set_disabled(false)


func _on_new_pressed():
	if modified_flag == true:
		$ui/code_window/new_confirm.visible = true
	else:
		_on_new_confirm_confirmed()


func _on_new_confirm_confirmed():
	$ui/code_window/ctl/vbox/VBoxContainer/hbox4/save.set_disabled(true)
	if sel == 0:
		open(def_canvas)
	elif sel == 1:
		open(def_spatial)


func _on_check_toggled(toggled_on):
	rotation = toggled_on


func _on_fog_toggled(toggled_on):
	$env.environment.set_fog_enabled(toggled_on)


func _on_color_item_selected(index):
	$env.environment.set_tonemapper(index)


func _on_spin_box_value_changed(value):
	code.add_theme_font_size_override("font_size", value)


func _on_code_text_changed():
	modified_flag = true
	run()
	debug_label.update_debug()


func _on_about_pressed():
	$ui/code_window/about.visible = true


func _on_error_raised(line_number):
	code_ok = false
	if sel == 0:
		warning.texture = img_fail
		code.clear_executing_lines()
		code.set_line_as_executing(line_number - 1, true)
	elif sel == 1:
		warning.texture = img_fail
		code.clear_executing_lines()
		code.set_line_as_executing(line_number - 1, true)


func _on_ok_raised():
	code_ok = true
	warning.texture = img_ok
	code.clear_executing_lines()


func _on_save_pressed():
	modified_flag = false
	if current_file_path != null:
		print(current_file_path)
