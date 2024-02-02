extends CodeEdit


func _ready():
	var g = Grammar.new()
	self.syntax_highlighter = g.get_hl(name)
