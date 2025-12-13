# Gear.gd
extends Area2D

# How much the coin is worth
@export var gear_value: int = 15

func _ready() -> void:
	# to detect player collision
	self.area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D):
	# see if player touched it
	if area.is_in_group("player"):
		# Give gears to the main game
		var main = get_tree().get_first_node_in_group("main")
		if main:
			main.add_gears(gear_value)
		queue_free() #remove after touching
