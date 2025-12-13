
extends Node
#exported mob scenes 
@export var mob_scene: PackedScene
@export var tracker_mob_scene: PackedScene
@export var ghost_mob_scene: PackedScene
# Scene references
const SHEPHERD_BOT_SCENE = preload("res://ShepherdBot.tscn")
const ORB_SCENE = preload("res://Orb.tscn")
const SHOP_SCENE = preload("res://Shop.tscn") 
const SHOPKEEPER_SCENE = preload("res://Shopkeeper.tscn")
const GEAR_SCENE = preload("res://Gear.tscn")

const GLITCH_KING_SCENE = preload("res://GlitchKing.tscn")


# -game state variables
var score: int
var highest_score: int = 0
var player_gears: int = 100 
var chassis_level: int = 0
var propulsion_level: int = 0
var weapon_unlocked: bool = false
var weapon_upgraded: bool = false 
var player_max_health: int = 3 # Base health
var player_speed: int = 300# Base speed

enum GameMode { STAGE, ENDLESS }
var current_mode: GameMode = GameMode.STAGE
var current_stage_goal: String = "ORB_COLLECTION" 
var goal_value: int = 20 
var current_stage: int = 1 # tracks the current stage number
var orbs_collected: int = 0
var current_portal = null
@onready var player = $Player
@onready var hud = $HUD #

const SCREEN_WIDTH = 1200.0
const SCREEN_HEIGHT = 720.0

var game_time: float = 0.0

const INITIAL_SAFE_MARGIN = 50.0
const INITIAL_SPEED = 5.0
const ACCEL_SPEED = 15.0
var current_shrink_rate: float = 0.0
var safe_margin: float = INITIAL_SAFE_MARGIN
var is_shrinking: bool = false
var shepherd_bot_spawned: bool = false

const START_SHRINK_TIME = 5.0
const ACCELERATE_SHRINK_TIME = 15.0
const ACTIVATE_CONSTRAINT_TIME = 20.0

# 
# initializes the game when the scene loads, connects player signals to HUD
func _ready() -> void:
	if player:
		player.health_changed.connect(hud.update_health_display)
		player.died.connect(game_over)
		update_player_stats()
		hud.update_health_display(player.max_health)
	pass

# Runs every frame
func _process(delta: float) -> void:
	# --- SCORCHED EARTH LOGIC ---
	# Only run logic if the MobTimer is active (game has started)
	# NOTE: You may want to restrict the shrinking logic to ENDLESS mode only.
	if not $MobTimer.is_stopped():
		game_time += delta
		
		# 1. Progression Triggers
		if game_time >= START_SHRINK_TIME and not is_shrinking:
			current_shrink_rate = INITIAL_SPEED
			is_shrinking = true
			
		if game_time >= ACCELERATE_SHRINK_TIME and current_shrink_rate == INITIAL_SPEED:
			current_shrink_rate = ACCEL_SPEED
			
		if game_time >= ACTIVATE_CONSTRAINT_TIME and player and not player.kinetic_constraint_active:
			player.kinetic_constraint_active = true
			
		if game_time >= 5.0 and not shepherd_bot_spawned:
			spawn_shepherd_bot()
			shepherd_bot_spawned = true

		# 2. Boundary Update & Check
		if is_shrinking:
			safe_margin = max(0.0, safe_margin - current_shrink_rate * delta)
			check_player_boundary()


# # handles collision when boosting
func _on_player_hit(body: Node2D) -> void:
	if $Player.is_boost:
		print("Enemy got hit!")
		$HitSound.play()
		score += 10
		$HUD.update_score(score)
		body.modulate = Color(0.5, 0, 0)
		body.gravity_scale = 1


# Called when the player loses, triggered by player.died signal
func game_over():
	$Player.hide()
	var collision_shape = $Player.find_child("CollisionShape2D")
	if collision_shape:
		collision_shape.set_deferred("disabled", true)

	$ScoreTimer.stop()
	$MobTimer.stop()
	$HUD.show_game_over()
	$GameMusic.stop()


	if is_instance_valid(current_portal):
		current_portal.queue_free()
		current_portal = null
	if score > highest_score:
		highest_score = score
		$HUD.update_highest_score(highest_score)


# starts a new game
func new_game():
	#Reset Progression Variables 
	current_mode = GameMode.STAGE
	orbs_collected = 0
	current_stage = 1 
	goal_value = 5
	game_time = 0.0
	safe_margin = INITIAL_SAFE_MARGIN
	is_shrinking = false
	shepherd_bot_spawned = false
	current_shrink_rate = 0.0
	if player:
		player.kinetic_constraint_active = false
		player.current_health = player_max_health 
		player.show()
		$HUD.update_health_display(player.current_health)
		
	score = 0
	$Player.start($StartPosition.position)
	$HUD.update_score(score)	 
	$HUD.show_message("Ready?")
	get_tree().call_group("mobs", "queue_free")
	get_tree().call_group("orbs", "queue_free")
	$StartTimer.start()

#counts the orbs 
func increment_orbs(amount: int = 1):
	orbs_collected += amount
	var orbs_remaining = goal_value - orbs_collected
	if orbs_remaining > 0:
		$HUD.update_score(orbs_remaining) 
	else:
		$HUD.update_score(0)
	print("Orbs collected: ", orbs_collected, " / ", goal_value)
	if current_stage_goal == "ORB_COLLECTION" and orbs_collected >= goal_value:
		current_stage_goal = "COMPLETE"
		stage_complete()
func stage_complete():
	$MobTimer.stop()
	print("Stage Complete! Clanker Keeper is arriving...")
	call_deferred("_spawn_shopkeeper_safely")

# Spawns the shopkeeper NPC who walks in 
func _spawn_shopkeeper_safely():
	if not is_instance_valid(current_portal) and SHOPKEEPER_SCENE:
		current_portal = SHOPKEEPER_SCENE.instantiate()
		add_child(current_portal)
		var margin = 50.0
		var spawn_x = SCREEN_WIDTH + margin # Spawn just off the right edge
		var spawn_y = randf_range(100.0, SCREEN_HEIGHT - 100.0)
		current_portal.global_position = Vector2(spawn_x, spawn_y)#
		if current_portal.has_method("update_dialogue"):
			current_portal.update_dialogue(current_stage)
		current_portal.open_shop.connect(_transition_to_shop)
		print("Clanker Keeper spawned at: ", current_portal.global_position)


# Hides gameplay elements and prepares to load the shop 
func _transition_to_shop():
	print("Transitioning to Shop...")
	if hud.has_node("OrbCountLabel2"):
		hud.get_node("OrbCountLabel2").hide()
	if hud.has_node("HighestScoreLabel"):
		hud.get_node("HighestScoreLabel").hide()
	if hud.has_node("ScoreLabel"):
		hud.get_node("HighestScoreLabel").hide()
	$Player.hide()
	$MobTimer.stop()
	get_tree().call_group("mobs", "queue_free")
	if is_instance_valid(current_portal):
		current_portal.queue_free()
		current_portal = null
	var shop_instance = SHOP_SCENE.instantiate()
	call_deferred("_complete_shop_transition", shop_instance)
	
	# initializes it with player's current stats
func _complete_shop_transition(shop_instance):
	get_tree().root.add_child(shop_instance)
	shop_instance.shop_closed.connect(_on_shop_closed)
	shop_instance.initialize_shop(
		player_gears,
		current_stage,
		chassis_level,
		propulsion_level,
		weapon_unlocked,
		weapon_upgraded 
	)
	get_tree().paused = true
	
	print("Shop initialized with state: Gears:", player_gears, " C", chassis_level, " P", propulsion_level)

# Receives upgraded stats from shop, deducts gears
func _on_shop_closed(gears_spent: int, new_chassis_level: int, new_propulsion_level: int, new_weapon_unlocked: bool, new_weapon_upgraded: bool):
	print("--- Shop Closed ---")
	chassis_level = new_chassis_level
	propulsion_level = new_propulsion_level
	weapon_unlocked = new_weapon_unlocked
	weapon_upgraded = new_weapon_upgraded
	player_gears -= gears_spent
	update_player_stats()
	print("New Game State: Gears:", player_gears, " Health:", player_max_health, " Speed:", player_speed)
	hud.get_node("ScoreLabel").show()
	get_tree().paused = false
	advance_stage()

# updates player's max health and speed based on purchased upgrades
func update_player_stats():
	player_max_health = 3 + chassis_level
	player_speed = 300 + (propulsion_level * 50)
	
	if player:
		player.max_health = player_max_health
		player.speed = player_speed
		
	print("Player stats updated: Health:", player_max_health, " Speed:", player_speed)

#progresses to the next stage, awards gears, resets variables
func advance_stage():
	current_stage += 1
	orbs_collected = 0 
	current_stage_goal = "ORB_COLLECTION"
	
	var stage_reward = 0
	match current_stage - 1:
		1: stage_reward = 50
		2: stage_reward = 0 
		3: stage_reward = 75
		4: stage_reward = 100
	
	if stage_reward > 0:
		player_gears += stage_reward
		print("Stage Complete! Earned ", stage_reward, " gears!")
	
	if current_stage == 5:
		weapon_unlocked = true
		current_stage_goal = "BOSS_FIGHT"  
		print("WEAPON UNLOCKED! Entering final battle...")

	match current_stage:
		1: goal_value = 5
		2: goal_value = 10
		3: goal_value = 12
		4: goal_value = 15
		5: goal_value = 0 
	game_time = 0.0
	safe_margin = INITIAL_SAFE_MARGIN
	is_shrinking = false
	shepherd_bot_spawned = false
	current_shrink_rate = 0.0
	if player:
		player.kinetic_constraint_active = false
		player.current_health = player.max_health
		player.health_changed.emit(player.current_health)
		player.show()
	
	print("Advancing to Stage ", current_stage)
	print("Player starting with: ", player.current_health, "/", player.max_health, " health")
	
	# spawn boss if Stage 5
	if current_stage == 5:
		$HUD.show_message("FINAL BATTLE!")
		call_deferred("spawn_boss")  
	else:
		$HUD.show_message("STAGE %d START" % current_stage)
	
	$StartTimer.start()
	pass 



# triggers every 0.5 sec and instantiates a mob or orb
func _on_mob_timer_timeout() -> void:
	var spawn_roll = randf()
	
	if spawn_roll < 0.70:# 70% mob spawning
		var spawn_path_location = get_node("MobSpawnPath/MobSpawnLocation")
		spawn_path_location.progress_ratio = randf()
		var spawn_position = spawn_path_location.position
		
		var mob_instance
		
		# Determine which mob type to spawn based on current stage
		if current_stage == 2:
			# stage 2: regular mobs + Tracker mobs
			if tracker_mob_scene and randf() < 0.23: # 30% tracker
				mob_instance = tracker_mob_scene.instantiate()
			else:
				mob_instance = mob_scene.instantiate()
		
		elif current_stage == 3:
			var mob_type = randf() 
			if ghost_mob_scene and mob_type < 0.60:  # 60% ghost
				mob_instance = ghost_mob_scene.instantiate()
			elif tracker_mob_scene and mob_type < 0.75:  # 15% tracker 
				mob_instance = tracker_mob_scene.instantiate()
			else:  #  (fallback)
				mob_instance = mob_scene.instantiate()
		
		elif current_stage >= 4:
			# Stage 4: All three mob types
			var mob_type = randf()
			if ghost_mob_scene and mob_type < 0.25:
				mob_instance = ghost_mob_scene.instantiate()
			elif tracker_mob_scene and mob_type < 0.40:
				mob_instance = tracker_mob_scene.instantiate()
			else:
				mob_instance = mob_scene.instantiate()
		
		else:
			# Only regular mobs
			mob_instance = mob_scene.instantiate()
		mob_instance.position = spawn_position
		
		if mob_instance.get_script() != tracker_mob_scene:
			var direction = spawn_path_location.rotation + PI / 2
			direction += randf_range(-PI / 4, PI / 4)
			mob_instance.rotation = direction
			var velocity = Vector2(randf_range(150.0, 250.0), 0.0)
			mob_instance.linear_velocity = velocity.rotated(direction)
		add_child(mob_instance)
	elif spawn_roll < 0.90 and ORB_SCENE: 
		var orb_instance = ORB_SCENE.instantiate()
		var margin = 100.0
		var random_x = randf_range(margin, SCREEN_WIDTH - margin)
		var random_y = randf_range(margin, SCREEN_HEIGHT - margin)
		orb_instance.position = Vector2(random_x, random_y)
		add_child(orb_instance)
	
	elif GEAR_SCENE:
		var gear_instance = GEAR_SCENE.instantiate()
		var margin = 100.0
		var random_x = randf_range(margin, SCREEN_WIDTH - margin)
		var random_y = randf_range(margin, SCREEN_HEIGHT - margin)
		gear_instance.position = Vector2(random_x, random_y)
		add_child(gear_instance)
		print("Spawned a gear at ", gear_instance.position)

func _on_start_timer_timeout() -> void:
	$MobTimer.start()
	$GameMusic.play()

# checks if player has moved outside safe boundaries and triggers game over
func check_player_boundary():
	if not player: return
	var player_pos = player.global_position
	if (player_pos.x < safe_margin or player_pos.x > (SCREEN_WIDTH - safe_margin) or
		player_pos.y < safe_margin or player_pos.y > (SCREEN_HEIGHT - safe_margin)):
		game_over()

func add_gears(amount: int):
	player_gears += amount
	print("Collected ", amount, " gears! Total: ", player_gears)

func spawn_shepherd_bot():
	var shepherd_bot = SHEPHERD_BOT_SCENE.instantiate()
	add_child(shepherd_bot)
	var spawn_pos = Vector2(50, SCREEN_HEIGHT / 2.0)
	shepherd_bot.global_position = spawn_pos
	
func spawn_boss():
	if not GLITCH_KING_SCENE:
		push_error("Glitch King scene not found!")
		return
	$MobTimer.stop()
	get_tree().call_group("mobs", "queue_free")
	
	var boss = GLITCH_KING_SCENE.instantiate()
	add_child(boss)
	boss.boss_defeated.connect(_on_boss_defeated)
	print("GLITCH KING SPAWNED!")

func _on_boss_defeated():
	print("YOU WIN! GLITCH KING DEFEATED!")
	$MobTimer.stop()
	$GameMusic.stop()
	$HUD.show_message("VICTORY!\nThe Glitch King has been deleted!")
	await get_tree().create_timer(3.0).timeout
	$HUD.show_message("Game Complete!\nPress START to play again")
