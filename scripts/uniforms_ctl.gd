extends Control

signal user_entered_values(values)
signal user_entered_mouse_pos(varname, flag, pos)
signal user_entered_sampler(varname, sampler)
signal user_entered_bool(toggled_on)

var mouse_sim = false


func _ready():
	if self.has_node("vbox/slider"):
		$vbox/slider.value = float($vbox/hbox/l1.text)
	if self.has_node("vbox/color4"):
		$vbox/color4.set_pick_color(
			Color(
				float($vbox/hbox/l1.text),
				float($vbox/hbox/l2.text),
				float($vbox/hbox/l3.text),
				float($vbox/hbox/l4.text)
			)
		)
	if self.has_node("vbox/color3"):
		$vbox/color3.set_pick_color(
			Color(float($vbox/hbox/l1.text), float($vbox/hbox/l2.text), float($vbox/hbox/l3.text))
		)


func _input(event):
	if event is InputEventMouseMotion and mouse_sim == true:
		$vbox/hbox/l1.text = str(get_viewport().get_mouse_position().x)
		$vbox/hbox/l2.text = str(get_viewport().get_mouse_position().y)
		user_entered_mouse_pos.emit(
			$vbox/label.text, mouse_sim, get_viewport().get_mouse_position()
		)


func set_label(stn):
	$vbox/label.text = stn


func set_values(values):
	if not self.has_node("vbox/option") and not self.has_node("vbox/bool"):
		if values.size() > 0:
			$vbox/hbox/l1.text = values[0]
		if values.size() > 1:
			$vbox/hbox/l2.text = values[1]
		if values.size() > 2:
			$vbox/hbox/l3.text = values[2]
		if values.size() > 3:
			$vbox/hbox/l4.text = values[3]
	elif self.has_node("vbox/bool"):
		match values[0]:
			"true":
				$vbox/bool.button_pressed = true
			"false":
				$vbox/bool.button_pressed = false
			_:
				$vbox/bool.button_pressed = false


func restore(d):
	if self.has_node("vbox/option"):
		if d.get($vbox/label.text) != null:
			$vbox/option.select(d.get($vbox/label.text))


func set_hints(values):
	if self.has_node("vbox/slider"):
		$vbox/slider.visible = true

		if values.size() > 0:
			$vbox/slider.set_min(float(values[0]))
		if values.size() > 1:
			$vbox/slider.set_max(float(values[1]))
		if values.size() > 2:
			$vbox/slider.set_step(float(values[2]))


func _on_slider_value_changed(value):
	$vbox/hbox/l1.text = str($vbox/slider.value)
	values_changed(null)


func _on_color_color_changed():
	if self.has_node("vbox/color4"):
		$vbox/hbox/l1.text = str($vbox/color4.get_pick_color().r)
		$vbox/hbox/l2.text = str($vbox/color4.get_pick_color().g)
		$vbox/hbox/l3.text = str($vbox/color4.get_pick_color().b)
		$vbox/hbox/l4.text = str($vbox/color4.get_pick_color().a)
	elif self.has_node("vbox/color3"):
		$vbox/hbox/l1.text = str($vbox/color3.get_pick_color().r)
		$vbox/hbox/l2.text = str($vbox/color3.get_pick_color().g)
		$vbox/hbox/l3.text = str($vbox/color3.get_pick_color().b)
	values_changed(null)


func values_changed(_new_text):
	var regex = RegEx.new()
	regex.compile("^[0-9.-]*$")

	var result = []

	for i in $vbox/hbox.get_children():
		if regex.search(i.text):
			result.append(i.text)
		else:
			result.append("0")

	user_entered_values.emit(result)


func _on_mouse_toggled(toggled_on):
	if toggled_on:
		mouse_sim = true
	else:
		mouse_sim = false


func _on_option_item_selected(index):
	user_entered_sampler.emit($vbox/label.text, index)


func _on_bool_toggled(toggled_on):
	user_entered_bool.emit(toggled_on)
