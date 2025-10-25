extends Node2D

#var scene = load("res://MyNode.tscn")
#
#func _ready() -> void:
	#print(scene)
	#var instance = scene.instantiate()
	#add_child(instance)
var mynode = MyNode.new()

func _ready() -> void:
	add_child(mynode)
