extends CanvasLayer

signal start_game
@onready var health_bar = $HealthBar # Assuming you added a ProgressBar named HealthBar
@onready var orb_count_label = $OrbCountLabel # Assuming you added a Label named OrbCountLabel
# ----------------------------------------------------

# called when the node entersc the scene tree for the first time.
func _ready() -> void:
	$MenuMusic.play()
	if is_instance_valid(health_bar):
		health_bar.max_value = 3 # match the player's max_health
		health_bar.value = 3
		
func _process(_delta: float) -> void:
	pass


#  updates the health bar visual
func update_health_display(new_health: int):
	if is_instance_valid(health_bar):
		health_bar.value = new_health

# update the orb counter
func update_orb_count(collected: int, goal: int):
	if is_instance_valid(orb_count_label):
		orb_count_label.text = str(collected) + " / " + str(goal) + " Orbs"

# Shows the message 'ready?' and starts the message timer
func show_message(text):
	$Message.text = text
	$Message.show()
	$MessageTimer.start()


func show_game_over():
	show_message("Game Over")
	await $MessageTimer.timeout

	$Message.text = "Angry Robots"
	$Message.show()

	
	await get_tree().create_timer(1.0).timeout
	$StartButton.show() 
	$MenuMusic.play()

# updates the score label 
func update_score(orbs_remaining):
	if orbs_remaining > 0:
		$ScoreLabel.text = str(orbs_remaining) + " orbs left to collect"

func update_highest_score(score):
	$HighestScoreLabel.text = "Highest score: " + str(score)

func _on_message_timer_timeout() -> void:
	$Message.hide()

func _on_start_button_pressed() -> void:
	$StartButton.hide()
	$MenuMusic.stop()
	$ClickSound.play()
	start_game.emit()
