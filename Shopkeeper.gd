# Shopkeeper.gd
extends Area2D

signal open_shop

@onready var animated_sprite = $AnimatedSprite2D 
@onready var dialogue_label = $DialogueLabel

var dialogue_shown: bool = false
var text_to_show: String = "Great job getting past them, little unit.\nI can carry you to the next sector,\njust interact with me again to begin your journey."

var speed: float = 150.0 
var is_moving: bool = true 
const STOPPING_X_POSITION: float = 1000.0

func update_dialogue(stage_number: int) -> void:
	
	match stage_number:
		1:
			text_to_show = "Great job getting past them, little unit.\nI can carry you to the next sector,\njust interact with me again to begin your journey."
		2:
			text_to_show = "A formidable performance! The enemies \n get faster now. Heres a hint: \nUse Spacebar to do a hyper jump"
		3:
			text_to_show = "Stage 3! You must be a true warrior. \nI've restocked all my goods, take a look."
		4:
			text_to_show = "You're deep in enemy territory now. \nTrust me, you need every scrap \nof power you can buy."
		5:
			
			text_to_show = "Better be strapped"

func _ready():
	animated_sprite.play("run left") 
	
	dialogue_label.hide()

func _process(delta: float):
	if is_moving:
		var velocity = Vector2.LEFT * speed
		global_position += velocity * delta
		if global_position.x <= STOPPING_X_POSITION:
			is_moving = false
			global_position.x = STOPPING_X_POSITION 
			
			animated_sprite.play("idle left")    
			print("Clanker Keeper has stopped and is ready.")
		   
	pass
func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		if is_moving:
			return 
			
		if not dialogue_shown:
			dialogue_label.text = text_to_show
			dialogue_label.show()
			dialogue_shown = true
			
		else:
			print("Player entered the shopkeeper! Opening Shop...")
			set_deferred("monitoring", false) 
			set_deferred("visible", false)
			open_shop.emit()

func _on_area_entered(area: Area2D):
	if area.is_in_group("player"):
		if is_moving:
			return 
			
		if not dialogue_shown:
			dialogue_label.text = text_to_show
			dialogue_label.show()
			dialogue_shown = true
			
		else:
			print("Player entered the shopkeeper! Opening Shop...")
			set_deferred("monitoring", false) #
			set_deferred("visible", false)   
			open_shop.emit()
