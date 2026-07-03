extends CodeEdit


func _ready():
	syntax_highlighter = Grammar.new().get_hl(name)
