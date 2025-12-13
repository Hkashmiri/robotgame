extends Area2D
var max_health: int = 3
var current_health: int = max_health

signal health_changed(new_health: int)
signal died
# ----------------------------------------------------

var is_invincible: bool = false
var has_armor = false
var invincibility_duration: float = 0.8 
var has_weapon: bool = false
const BULLET_SCENE = preload("res://Bullet.tscn")
var can_shoot: bool = true
var shoot_cooldown: float = 0.3  

@export var speed: int = 400
@export var boost_factor: int = 4
@export_range(0, 1, 0.05, "suffix:s", "or_greater")
var boost_time: float = 0.2
@export_range(0, 5, 0.1, "suffix:s", "or_greater")
var boost_cooldown_time: float = 2
@export_color_no_alpha
var boost_color: Color = Color(1, 0.5, 1)
var is_boost: bool = false
var is_cooldown: bool = false
var timer_boost := Timer.new()
var timer_cooldown := Timer.new()
var screen_size: Vector2i

var kinetic_constraint_active: bool = false
const SLOWDOWN_DURATION: float = 1.0 
const SLOWDOWN_FACTOR: float = 0.75 
var slowdown_timer: float = 0.0
var current_speed: float = 0.0

const SCREEN_WIDTH = 1200.0
const SCREEN_HEIGHT = 720.0

func _ready() -> void:
	hide()
	screen_size = get_viewport_rect().size
	current_speed = speed 
	health_changed.emit(max_health)
	add_child(timer_boost)
	timer_boost.wait_time = boost_time
	timer_boost.one_shot = true
	timer_boost.connect("timeout", boost_timer_timeout)
	add_child(timer_cooldown)
	timer_cooldown.wait_time = boost_cooldown_time
	timer_cooldown.one_shot = true
	timer_cooldown.connect("timeout", cooldown_timer_timeout)



func _process(delta: float) -> void:
	if slowdown_timer > 0:
		slowdown_timer -= delta
		if slowdown_timer <= 0:
			current_speed = speed 
	var velocity: Vector2 = Vector2.ZERO
	
	# input handling
	if Input.is_action_pressed("move_right"):
		velocity.x += 1
	if Input.is_action_pressed("move_left"):
		velocity.x -= 1
	if Input.is_action_pressed("move_down"):
		velocity.y += 1
	if Input.is_action_pressed("move_up"):
		velocity.y -= 1
	if has_weapon and can_shoot:
		if Input.is_action_pressed("ui_accept") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			shoot()
		
	if Input.is_action_pressed("accelerate"):
		if not is_boost and not is_cooldown:
			timer_boost.start()
			timer_cooldown.start()
			is_boost = true
			is_cooldown = true
	var main = get_tree().get_first_node_in_group("main")
	if main:
		has_weapon = main.weapon_unlocked
		print("Player weapon status: ", has_weapon)
		$Sprite2D.modulate = boost_color
			# Ensure $BoostSound is set up
	if $BoostSound: $BoostSound.play() 
	if kinetic_constraint_active:
				slowdown_timer = SLOWDOWN_DURATION
				current_speed = speed * SLOWDOWN_FACTOR

	if velocity.length() > 0:
		velocity = velocity.normalized() * current_speed

	if is_boost:
		velocity *= boost_factor

	position += velocity * delta
	position.x = clamp(position.x, 0, SCREEN_WIDTH)
	position.y = clamp(position.y, 0, SCREEN_HEIGHT)

func take_damage(amount: int):
	
	print("take_damage called: current_health=", current_health, " max_health=", max_health, " has_armor=", has_armor)
	
	#  checks if player is already invincible
	if is_invincible:
		return 
	
	if has_armor:
		has_armor = false
		print("Armor blocked the hit!")
		modulate = Color(1, 1, 1)
		
		var tween = create_tween()
		tween.tween_property(self, "modulate", Color(1, 1, 1, 0.5), 0.1)
		tween.tween_property(self, "modulate", Color(1, 1, 1, 1.0), 0.1)
		
		return  
	# apply damage and check for death
	current_health -= amount
	health_changed.emit(current_health) # Update the HUD
	if current_health <= 0:
		died.emit()
		var collision_shape = find_child("CollisionShape2D") 
		if collision_shape:
			collision_shape.set_deferred("disabled", true)
		
		return
	is_invincible = true
	modulate = Color(1, 0.4, 0.4, 0.5) 
	
	get_tree().create_timer(invincibility_duration).timeout.connect(reset_invincibility)

func reset_invincibility():
	is_invincible = false
	if has_armor:
		modulate = Color(0.7, 0.7, 1.0)  # Blue if has armor
	elif not is_boost:
		modulate = Color.WHITE 
		
func boost_timer_timeout() -> void:
	is_boost = false
	if not is_invincible:
		modulate = Color.WHITE
	print("Boost time out")


func cooldown_timer_timeout() -> void:
	is_cooldown = false
	if not is_invincible and not is_boost:
		modulate = Color.WHITE
	print("Cooldown time out")


#  when an enemy hits the player 
func _on_body_entered(body: Node2D) -> void:
	pass

# reset the player when starting a new game
func start(pos):
	current_speed = speed #reset speed for new game
	position = pos
	show()
	var collision_shape = find_child("CollisionShape2D")
	if collision_shape:
		collision_shape.set_deferred("disabled", false)
	current_health = max_health
	is_invincible = false
	modulate = Color.WHITE

	is_boost = false
	is_cooldown = false

func _on_mob_timer_timeout() -> void:
	pass 
	#creates bullet to use for stage 5 
func shoot():
	can_shoot = false
	var bullet = BULLET_SCENE.instantiate()
	get_parent().add_child(bullet)
	bullet.global_position = global_position
	var mouse_pos = get_global_mouse_position()
	bullet.direction = (mouse_pos - global_position).normalized()
	bullet.rotation = bullet.direction.angle()
	var main = get_tree().get_first_node_in_group("main")
	if main and main.weapon_upgraded:
		bullet.damage = 10 
	else:
		bullet.damage = 5  
	
	
	get_tree().create_timer(shoot_cooldown).timeout.connect(_reset_shoot_cooldown)

func _reset_shoot_cooldown():
	can_shoot = true
