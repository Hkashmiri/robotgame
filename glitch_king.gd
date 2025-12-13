# GlitchKing.gd
extends CharacterBody2D

signal boss_defeated

const SCREEN_WIDTH = 1200.0
const SCREEN_HEIGHT = 720.0

# Boss stats
var max_health: int = 50
var current_health: int = max_health

# Movement
var move_speed: float = 100.0
var current_target: Vector2
var move_timer: float = 0.0
const MOVE_INTERVAL: float = 3.0  #change direction every 3 seconds

# weak point system
@onready var weak_point = $WeakPoint
var weak_point_open: bool = false
var weak_point_timer: float = 0.0
const WEAK_POINT_OPEN_TIME: float = 3.0
const WEAK_POINT_CLOSED_TIME: float = 7.0

# spawn mobs
@onready var mob_spawn_timer = $MobSpawnTimer
const MOB_SCENE = preload("res://mob.tscn") 

func _ready() -> void:
	# it starts at center
	global_position = Vector2(SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2)
	pick_new_target()
	# hides weak point initially
	weak_point.hide()
	weak_point.monitoring = false
	weak_point_timer = WEAK_POINT_CLOSED_TIME
	
	# weak point collision
	weak_point.area_entered.connect(_on_weak_point_hit)
	
	# starts spawning mobs
	mob_spawn_timer.wait_time = 5.0  # spawns them every 5 seconds
	mob_spawn_timer.start()
	mob_spawn_timer.timeout.connect(_spawn_minion)
	print("Glitch King spawned with ", max_health, " HP")

func _physics_process(delta: float) -> void:
	# Movement AI
	move_timer += delta
	if move_timer >= MOVE_INTERVAL:
		pick_new_target()
		move_timer = 0.0
	var direction = (current_target - global_position).normalized()#moves toward target
	velocity = direction * move_speed
	move_and_slide()
	weak_point_timer -= delta
	if weak_point_open and weak_point_timer <= 0:
		close_weak_point()
	elif not weak_point_open and weak_point_timer <= 0:
		open_weak_point()

func pick_new_target():
	# picks random position on screen 
	var margin = 150.0
	var x = randf_range(margin, SCREEN_WIDTH - margin)
	var y = randf_range(margin, SCREEN_HEIGHT - margin)
	current_target = Vector2(x, y)
	print("Boss moving to: ", current_target)

func open_weak_point():
	weak_point_open = true
	weak_point_timer = WEAK_POINT_OPEN_TIME
	weak_point.show()
	weak_point.monitoring = true
	modulate = Color(1, 0.5, 0.5)#makes him flash red ewhen hit
	print("Weak point OPENED!")

func close_weak_point():
	weak_point_open = false
	weak_point_timer = WEAK_POINT_CLOSED_TIME
	weak_point.hide()
	weak_point.monitoring = false
	modulate = Color.WHITE
	print("Weak point CLOSED!")

func _on_weak_point_hit(area: Area2D):
	if area.is_in_group("player_bullet"): #saying it got it 
		take_damage(5)  # Basic weapon damage
		area.queue_free() 

func take_damage(amount: int):
	current_health -= amount
	print("Boss took ", amount, " damage! HP: ", current_health, "/", max_health)
	
	# Flash white when hit
	modulate = Color(2, 2, 2)
	await get_tree().create_timer(0.1).timeout
	modulate = Color(1, 0.5, 0.5) if weak_point_open else Color.WHITE
	if current_health <= 0:
		die()

func die():
	print("GLITCH KING DEFEATED!")
	boss_defeated.emit()
	queue_free()

func _spawn_minion():
	# Spawn a small mob to distract player
	var mob = MOB_SCENE.instantiate()
	get_parent().add_child(mob)
	# Spawn near the boss
	mob.global_position = global_position + Vector2(randf_range(-100, 100), randf_range(-100, 100))
	# Give it random velocity
	var direction = randf_range(0, TAU)
	mob.linear_velocity = Vector2(cos(direction), sin(direction)) * 150
	print("Boss spawned minion!")
