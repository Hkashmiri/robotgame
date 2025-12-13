# mob.gd
extends RigidBody2D

@onready var detection_area = $Area2D
@onready var sprite = $Sprite2D  # Make sure you have this

var health: int = 2  # Mobs take 2 hits to die (or 1 if you want)

func _ready() -> void:
	if detection_area:
		detection_area.area_entered.connect(_on_area_entered)
	
	gravity_scale = 0

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()

func _on_area_entered(area: Area2D):
	if area.is_in_group("player"):
		area.take_damage(1)
		queue_free()

func take_damage(amount: int):
	health -= amount
	print("Mob took ", amount, " damage! HP remaining: ", health)
	# Flash red
	if sprite:
		sprite.modulate = Color(2, 0.5, 0.5)  
		await get_tree().create_timer(0.1).timeout
		
		if health > 0:
			sprite.modulate = Color.WHITE 
	if health <= 0:
		die()

func die():
	print("Mob destroyed!")
	queue_free()
