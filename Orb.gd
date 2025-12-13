# Orb.gd
extends Area2D

func _ready() -> void:
	add_to_group("orbs")
	self.area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D):
	#check if the player touched it
	if area.is_in_group("player"):
		# increment the orb count
		get_tree().get_first_node_in_group("main").increment_orbs(1)
		queue_free()
