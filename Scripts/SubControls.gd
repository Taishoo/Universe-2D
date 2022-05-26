extends Node2D

onready var parent: KinematicBody2D = get_parent()
onready var trails: Particles2D = parent.get_node("Particles")
onready var label: Label = parent.get_node("Label")

func _ready() -> void:
	label.text = parent.get_name()
	trails.emitting = Global.show_trail
	label.visible = Global.show_name

func _physics_process(_delta) -> void:
	trails.emitting = Global.show_trail
	label.visible = Global.show_name


