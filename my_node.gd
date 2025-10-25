extends Sprite2D
class_name MyNode

var x = 200
var y = 200

func _ready() -> void:
	texture = load("res://icon.svg")
	position = Vector2(x, y)
