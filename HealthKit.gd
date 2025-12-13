# HealthKit.gd
extends Area2D

# How much health this kit restores
@export var heal_amount: int = 1

func _ready():
	# Connect the body_entered signal when the scene is initialized
	# This ensures the _on_body_entered function runs when something enters this Area2D
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D):
	# Check if the colliding body is the player group (assuming you grouped the Player)
	if body.is_in_group("player"):
		# Check if the player is actually missing health
		if body.current_health < body.max_health:
			# Apply heal amount, ensuring it doesn't exceed max_health
			body.current_health = min(body.current_health + heal_amount, body.max_health)
			
			# Emit the signal you set up in player.gd to update the HUD display
			body.health_changed.emit(body.current_health)
			
			print("Player healed. New health: ", body.current_health)
			
			# Remove the health kit from the scene tree once used
			queue_free()
