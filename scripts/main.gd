extends Node

const DEF_CANVAS = "res://material/def_canvas_item.gdshader"
const DEF_SPATIAL = "res://material/def_spatial.gdshader"

const SAMPLER_PATHS = {
	1: "res://textures/simple.tres",
	2: "res://textures/animated.tres",
	3: "res://textures/gradient.tres",
	4: "res://textures/noise.tres",
	5: "res://textures/normal.tres",
}

var img_ok = preload("res://theme/ok.png")
var img_fail = preload("res://theme/alert.png")
var default_canvas = load(DEF_CANVAS)
var default_spatial = load(DEF_SPATIAL)

var interpreter = UniformsInterpreter.new()
var uniforms_ui = UniformsUI.new()

var current_file_path = null
var uniforms = []
var sel = 0  # 0 = canvas_item, 1 = spatial
var target_mode = 0
var modified = false
var auto_rotate = true
var rot = Vector3(randf_range(-0.3, 0.3), randf_range(-0.3, 0.3), randf_range(-0.3, 0.3))

@onready var canvas = $ui/canvas_item
@onready var ball = $ui/canvas_item/sv/ball
@onready var target_icon = $ui/icon
@onready var target_spatial_cube = $ui/canvas_item/sv/cube
@onready var target_spatial_mesh = $ui/canvas_item/sv/cam/cam_mesh
@onready var code_window = $ui/code_window
@onready var code = $ui/code_window/ctl/vbox/hbox2/code
@onready var debug_label = $ui/code_window/ctl/vbox/hbox3/hbox/debug
@onready var warning = $ui/code_window/ctl/vbox/hbox3/hbox/warning
@onready var target_label = $ui/code_window/ctl/vbox/hbox3/target
@onready var mode_label = $ui/code_window/ctl/vbox/hbox3/mode
@onready var side_panel = $ui/code_window/ctl/vbox/hbox2/vbox
@onready var uniforms_panel = $ui/code_window/ctl/vbox/hbox2/vbox/vbox/scroll/vbox
@onready var flip_faces_button = $ui/code_window/ctl/vbox/hbox2/vbox/vbox2/scroll/vbox/HBoxContainer/check
@onready var panel_button = $ui/code_window/ctl/vbox/VBoxContainer/hbox4/panel
@onready var save_button = $ui/code_window/ctl/vbox/VBoxContainer/hbox4/save
@onready var open_window = $ui/code_window/open_window
@onready var save_window = $ui/code_window/save_window


func _ready():
	check_user_dir()
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
	ball.rotate_x(rot.x * delta)
	ball.rotate_y(rot.y * delta)
	ball.rotate_z(rot.z * delta)

	if auto_rotate:
		change_rot()
		target_spatial_cube.rotate_x(rot.x * delta)
		target_spatial_cube.rotate_y(rot.y * delta)
		target_spatial_cube.rotate_z(rot.z * delta)


func run():
	set_shader_type()

	if code.text != "":
		if sel == 0:
			target_spatial_mesh.visible = false
			if target_mode == 0:
				target_icon.visible = true
				target_icon.material.shader.set_code(code.text)
				target_label.text = "Target: Sprite"
			else:
				target_icon.visible = false
				canvas.material.shader.set_code(code.text)
				target_label.text = "Target: Viewport"
		else:
			if target_mode == 0:
				target_icon.visible = true
				target_spatial_mesh.visible = false
				target_spatial_cube.material.shader.set_code(code.text)
				target_label.text = "Target: Cube"
			else:
				target_icon.visible = false
				target_spatial_mesh.visible = true
				target_spatial_mesh.mesh.material.shader.set_code(code.text)
				target_label.text = "Target: Camera mesh"

	update_uniforms_interpreter()


func change_rot():
	# Once in a while, pick a new random spin.
	if randi_range(0, 1000) == 1000:
		rot = Vector3(randf_range(-0.3, 0.3), randf_range(-0.3, 0.3), randf_range(-0.3, 0.3))


func clear_shaders_from_objects():
	target_icon.material.shader.set_code(default_canvas.get_code())
	canvas.material.shader.set_code(default_canvas.get_code())
	target_spatial_mesh.mesh.material.shader.set_code(default_spatial.get_code())
	target_spatial_cube.material.shader.set_code(default_spatial.get_code())


func save(path):
	current_file_path = path
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(code.text)
	modified = false


func open(path):
	target_mode = 0
	uniforms_ui.flush()
	uniforms_ui.passive_flush()

	code.text = load(path).get_code()
	modified = false
	current_file_path = path


func retarget():
	clear_shaders_from_objects()
	if target_mode == 0:
		target_mode = 1
		target_spatial_cube.set_flip_faces(false)
		flip_faces_button.set_pressed(true)
	else:
		target_mode = 0
		flip_faces_button.set_pressed(false)


func update_uniforms_interpreter():
	if code.text != "":
		uniforms = interpreter.go(code.text)

	uniforms_ui.register_lines(uniforms)
	update_uniforms_ui()


func update_uniforms_ui():
	for child in uniforms_panel.get_children():
		child.queue_free()

	var keys = uniforms_ui.items.keys()
	keys.sort_custom(func(a, b): return a.naturalnocasecmp_to(b) < 0)
	for key in keys:
		var control = uniforms_ui.items[key].draw()
		uniforms_panel.add_child(control)


func set_shader_type():
	clear_shaders_from_objects()
	var regex_spatial = RegEx.new()
	var regex_canvas_item = RegEx.new()
	regex_spatial.compile("shader_type *spatial")
	regex_canvas_item.compile("shader_type *canvas_item")

	if regex_canvas_item.search(code.text):
		sel = 0
		mode_label.text = "Canvas item mode"
		flip_faces_button.set_disabled(true)
	elif regex_spatial.search(code.text):
		sel = 1
		mode_label.text = "Spatial mode"
		flip_faces_button.set_disabled(false)


func check_user_dir():
	copy_dir("res://shaders/examples/", "user://shaders/")
	save_window.set_root_subfolder("user://shaders")
	open_window.set_root_subfolder("user://shaders")


func copy_dir(source: String, destination: String):
	DirAccess.make_dir_recursive_absolute(destination)
	var source_dir = DirAccess.open(source)

	for filename in source_dir.get_files():
		if not FileAccess.file_exists(destination + filename):
			source_dir.copy(source + filename, destination + filename)


func replace_line_value(stn, line):
	var text = code.get_line(line - 1)
	var head = text.split("=")[0] if "=" in text else text.split(";")[0]
	code.set_line(line - 1, head + "= " + stn)
	code.grab_focus()


func _on_target_pressed():
	retarget()
	run()


func _on_sending_line_to_update(stn, line):
	replace_line_value(stn, line)


func _on_sending_bool_to_update(stn, line):
	replace_line_value(stn, line)


func _on_sending_mouse_pos_to_update(varname, pos):
	uniforms_ui.set_passive_ui_state(varname, pos)

	if sel == 0:
		canvas.material.set_shader_parameter(varname, pos)
	elif target_mode == 0:
		target_spatial_cube.material.set_shader_parameter(varname, pos)
	else:
		target_spatial_mesh.mesh.material.set_shader_parameter(varname, pos)


func _on_sending_sampler_to_update(varname, sampler):
	uniforms_ui.set_passive_ui_state(varname, sampler)

	var texture = null
	if sampler in SAMPLER_PATHS:
		texture = load(SAMPLER_PATHS[sampler])
	elif sampler == 6:
		texture = ImageTexture.create_from_image(get_viewport().get_texture().get_image())
	elif sampler != 0:
		return

	if sel == 0:
		canvas.material.set_shader_parameter(varname, texture)
	elif target_mode == 0:
		target_spatial_cube.material.set_shader_parameter(varname, texture)
	else:
		target_spatial_mesh.mesh.material.set_shader_parameter(varname, texture)


func _on_panel_pressed():
	side_panel.visible = not side_panel.visible
	panel_button.text = "Hide panel" if side_panel.visible else "Show panel"


func _on_open_window_file_selected(path):
	open(path)

	var shader_name = path.replace("user://shaders/", "").replace(".gdshader", "")
	code_window.set_title("Godot Shaders Sketchbook [ %s ]" % shader_name)
	save_button.set_disabled(false)
	run()


func _on_open_pressed():
	if modified:
		$ui/code_window/open_confirm.visible = true
	else:
		_on_open_confirm_confirmed()


func _on_open_confirm_confirmed():
	open_window.visible = not open_window.visible


func _on_save_as_pressed():
	save_window.visible = not save_window.visible
	if save_window.visible and current_file_path != null:
		save_window.set_current_path(current_file_path)


func _on_save_window_file_selected(path):
	save(path)
	save_button.set_disabled(false)


func _on_new_pressed():
	if modified:
		$ui/code_window/new_confirm.visible = true
	else:
		_on_new_confirm_confirmed()


func _on_new_confirm_confirmed():
	save_button.set_disabled(true)
	clear_shaders_from_objects()
	open(DEF_CANVAS if sel == 0 else DEF_SPATIAL)
	run()


func _on_check_toggled(toggled_on):
	auto_rotate = toggled_on


func _on_fog_toggled(toggled_on):
	$env.environment.set_fog_enabled(toggled_on)


func _on_color_item_selected(index):
	$env.environment.set_tonemapper(index)


func _on_spin_box_value_changed(value):
	code.add_theme_font_size_override("font_size", value)


func _on_code_text_changed():
	modified = true
	run()
	debug_label.update_debug()


func _on_about_pressed():
	$ui/code_window/about.visible = true


func _on_error_raised(line_number):
	warning.texture = img_fail
	code.clear_executing_lines()
	code.set_line_as_executing(line_number - 1, true)


func _on_ok_raised():
	warning.texture = img_ok
	code.clear_executing_lines()


func _on_save_pressed():
	modified = false
	if current_file_path != null:
		save(current_file_path)


func _on_flip_z_toggled(toggled_on):
	if sel == 1:
		if target_mode == 0:
			target_spatial_cube.set_flip_faces(toggled_on)
		else:
			target_spatial_mesh.mesh.set_flip_faces(not toggled_on)
