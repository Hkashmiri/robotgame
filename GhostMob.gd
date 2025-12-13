# GhostMob.gd
extends RigidBody2D

@onready var detection_area = $Area2D
@onready var sprite = $Sprite2D

var health: int = 2 
var is_visible_to_player: bool = true
var fade_timer: float = 0.0
const VISIBLE_DURATION: float = 2.0
const INVISIBLE_DURATION: float = 2.5
var time_in_state: float = 0.0
var time_alive: float = 0.0  #life sapan
const MAX_LIFETIME: float = 20.0  # deis after 20 secs

func _ready() -> void:
	if detection_area:
		detection_area.area_entered.connect(_on_area_entered)
	
	gravity_scale = 0
	is_visible_to_player = true
	time_in_state = 0.0
	sprite.modulate = Color(0.9, 0.9, 0.9, 0.8)

func _process(delta: float) -> void:
	time_alive += delta  # track their lifespan
	
	# removed if too old
	if time_alive > MAX_LIFETIME:
		queue_free()
		return
	
	time_in_state += delta
	
	if is_visible_to_player and time_in_state >= VISIBLE_DURATION:
		fade_out()
	elif not is_visible_to_player and time_in_state >= INVISIBLE_DURATION:
		fade_in()
	
	if is_visible_to_player:
		var target_alpha = 0.8
		sprite.modulate.a = lerp(sprite.modulate.a, target_alpha, delta * 5.0)
	else:
		var target_alpha = 0.15
		sprite.modulate.a = lerp(sprite.modulate.a, target_alpha, delta * 5.0)

func fade_out():
	is_visible_to_player = false
	time_in_state = 0.0

func fade_in():
	is_visible_to_player = true
	time_in_state = 0.0

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()

func _on_area_entered(area: Area2D):
	if area.is_in_group("player") and is_visible_to_player:
		print("Ghost mob hit player while visible!")
		area.take_damage(1)
		queue_free()
	elif area.is_in_group("player") and not is_visible_to_player:
		print("Ghost mob passed through player while invisible!")
		

func take_damage(amount: int):
	health -= amount
	print("Ghost took ", amount, " damage! HP: ", health)
	
	if sprite:
		sprite.modulate = Color(2, 0.5, 0.5)
		await get_tree().create_timer(0.1).timeout
		if health > 0 and is_visible_to_player:
			sprite.modulate = Color(0.9, 0.9, 0.9, 0.8)
		elif health > 0:
			sprite.modulate = Color(0.9, 0.9, 0.9, 0.15)
	
	if health <= 0:
		queue_free()
