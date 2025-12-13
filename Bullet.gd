# Bullet.gd
extends Area2D

var speed: float = 500.0
var direction: Vector2 = Vector2.RIGHT
var damage: int = 5  # Base damage

func _ready() -> void:
	# this is so the boss can detect it 
	add_to_group("player_bullet")
	
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	
	
	await get_tree().create_timer(3.0).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	
	# destroy if off-screen
	if position.x < -50 or position.x > 1250 or position.y < -50 or position.y > 770:
		queue_free()

func _on_area_entered(area: Area2D):
	
	pass

func _on_body_entered(body: Node2D):
	# hit a mob or boss
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()  # Destroy bullet
