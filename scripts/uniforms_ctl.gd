extends Control

signal user_entered_values(values)
signal user_entered_mouse_pos(varname, flag, pos)
signal user_entered_sampler(varname, sampler)
signal user_entered_bool(toggled_on)

var mouse_sim = false


func _ready():
	if has_node("vbox/slider"):
		$vbox/slider.value = float($vbox/hbox/l1.text)
	if has_node("vbox/color4"):
		$vbox/color4.set_pick_color(Color(
			float($vbox/hbox/l1.text),
			float($vbox/hbox/l2.text),
			float($vbox/hbox/l3.text),
			float($vbox/hbox/l4.text)
		))
	if has_node("vbox/color3"):
		$vbox/color3.set_pick_color(Color(
			float($vbox/hbox/l1.text),
			float($vbox/hbox/l2.text),
			float($vbox/hbox/l3.text)
		))


func _input(event):
	if event is InputEventMouseMotion and mouse_sim:
		var pos = get_viewport().get_mouse_position()
		$vbox/hbox/l1.text = str(pos.x)
		$vbox/hbox/l2.text = str(pos.y)
		user_entered_mouse_pos.emit($vbox/label.text, mouse_sim, pos)


func set_label(stn):
	$vbox/label.text = stn


func set_values(values):
	if has_node("vbox/bool"):
		$vbox/bool.button_pressed = values[0] == "true"
	elif not has_node("vbox/option"):
		var fields = $vbox/hbox.get_children()
		for i in mini(values.size(), fields.size()):
			fields[i].text = values[i]


func restore(d):
	if has_node("vbox/option") and d.get($vbox/label.text) != null:
		$vbox/option.select(d.get($vbox/label.text))


func set_hints(values):
	if not has_node("vbox/slider"):
		return

	$vbox/slider.visible = true
	if values.size() > 0:
		$vbox/slider.set_min(float(values[0]))
	if values.size() > 1:
		$vbox/slider.set_max(float(values[1]))
	if values.size() > 2:
		$vbox/slider.set_step(float(values[2]))


func values_changed(_new_text):
	var regex = RegEx.new()
	regex.compile("^[0-9.-]*$")

	var result = []
	for field in $vbox/hbox.get_children():
		result.append(field.text if regex.search(field.text) else "0")

	user_entered_values.emit(result)


func _on_slider_value_changed(_value_changed):
	# drag_ended pasa un bool, no el valor; lo leemos del propio slider.
	$vbox/hbox/l1.text = str($vbox/slider.value)
	values_changed(null)


func _on_color_color_changed():
	if has_node("vbox/color4"):
		var color = $vbox/color4.get_pick_color()
		$vbox/hbox/l1.text = str(color.r)
		$vbox/hbox/l2.text = str(color.g)
		$vbox/hbox/l3.text = str(color.b)
		$vbox/hbox/l4.text = str(color.a)
	elif has_node("vbox/color3"):
		var color = $vbox/color3.get_pick_color()
		$vbox/hbox/l1.text = str(color.r)
		$vbox/hbox/l2.text = str(color.g)
		$vbox/hbox/l3.text = str(color.b)
	values_changed(null)


func _on_mouse_toggled(toggled_on):
	mouse_sim = toggled_on


func _on_option_item_selected(index):
	user_entered_sampler.emit($vbox/label.text, index)


func _on_bool_toggled(toggled_on):
	user_entered_bool.emit(toggled_on)
