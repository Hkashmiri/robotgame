# Portal.gd
extends Area2D

signal teleport

@onready var sprite = $Sprite2D
@onready var animation_player = $AnimationPlayer

var is_active: bool = false

func _ready():
	modulate.a = 0.0
	body_entered.connect(_on_body_entered)
	fade_in()

func fade_in():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 1.5)
	tween.finished.connect(_on_fade_in_complete)

func _on_fade_in_complete():
	is_active = true
	if animation_player and animation_player.has_animation("pulse"):
		animation_player.play("pulse")

func _on_body_entered(body: Node2D):
	print("SOMETHING TOUCHED PORTAL: ", body.name)
	print("Is it in player group? ", body.is_in_group("player"))
	
	if is_active and body.is_in_group("player"):
		print("Player entered portal! Teleporting...")
		is_active = false 
		
		
		if animation_player:
			animation_player.stop()
		
	
		teleport_player(body)

func teleport_player(player: Node2D):
	var flash_tween = create_tween()
	flash_tween.tween_property(self, "modulate", Color.WHITE, 0.1)
	flash_tween.tween_property(self, "modulate", Color(0.5, 0.8, 1.0), 0.1)
	player.set_process(false)
	create_screen_fade()
	await get_tree().create_timer(0.5).timeout
	teleport.emit()
	queue_free()

func create_screen_fade():
	var fade_rect = ColorRect.new()
	fade_rect.color = Color.BLACK
	fade_rect.color.a = 0.0
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100 
	get_tree().root.add_child(canvas_layer)
	canvas_layer.add_child(fade_rect)
	var fade_tween = create_tween()
	fade_tween.tween_property(fade_rect, "color:a", 1.0, 0.5)
