# TrackerMob.gd
extends RigidBody2D

@onready var detection_area = $Area2D
@onready var sprite = $Sprite2D

var health: int = 3 
var player: Node2D = null
var is_tracking: bool = true
var tracking_duration: float = 2.5
var tracking_timer: float = 0.0
var wander_speed: float = 150.0
var track_speed: float = 180.0
var time_alive: float = 0.0
const MAX_LIFETIME: float = 15.0


# Connects signals, finds the player
func _ready() -> void:
	if detection_area:
		detection_area.area_entered.connect(_on_area_entered)
	
	player = get_tree().get_first_node_in_group("player")
	tracking_timer = tracking_duration
	gravity_scale = 0


# tracks the player for a few seconds then wanders off 
func _physics_process(delta: float) -> void:
	time_alive += delta
	
	if time_alive > MAX_LIFETIME:
		queue_free()
		return
	
	if not player or not is_instance_valid(player):
		return
	
	if is_tracking:
		tracking_timer -= delta
		
		if tracking_timer <= 0:
			is_tracking = false
			var away_from_center = (global_position - Vector2(600, 360)).normalized()
			linear_velocity = away_from_center * wander_speed
	
	if is_tracking:
		var direction_to_player = (player.global_position - global_position).normalized()
		linear_velocity = direction_to_player * track_speed
	else:
		if linear_velocity.length() < 50:
			var random_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
			linear_velocity = random_direction * wander_speed


# removes the mob when it exits the screen area
func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()


# Damages the player on contact 
func _on_area_entered(area: Area2D):
	if area.is_in_group("player"):
		area.take_damage(1)
		queue_free()


# reduces health when hit by bullets and flashes red
func take_damage(amount: int):
	health -= amount
	print("Tracker took ", amount, " damage! HP: ", health)
	
	if sprite:
		sprite.modulate = Color(2, 0.5, 0.5)
		await get_tree().create_timer(0.1).timeout
		if health > 0:
			sprite.modulate = Color.WHITE
	
	if health <= 0:
		queue_free()
