extends Control

signal shop_closed(gears_spent, new_chassis_level, new_propulsion_level, new_weapon_unlocked, new_weapon_upgraded)

# Shop Pricing 
const ARMOR_PRICE = 50 
const CHASSIS_BASE_PRICE = 50
const PROPULSION_BASE_PRICE = 75
const WEAPON_UNLOCK_PRICE = 200

#current Shop State  
var player_gears: int = 0
var current_stage: int = 0
var chassis_level: int = 0
var propulsion_level: int = 0
var weapon_unlocked: bool = false
var weapon_upgraded: bool = false
var gears_spent_this_visit: int = 0

# Node References
var gear_display
var chassis_button
var propulsion_button
var weapon_button
var continue_button
var dialogue_label
var shopkeeper_sprite
var armor_button
var is_initialized: bool = false


func _ready():
	print("=== SHOP _ready() CALLED ===")
	process_mode = Node.PROCESS_MODE_ALWAYS

	#node references with  paths
	gear_display = get_node_or_null("GearDisplay")
	chassis_button = get_node_or_null("UpgradePanel/ChassisButton")
	propulsion_button = get_node_or_null("UpgradePanel/PropulsionButton")
	weapon_button = get_node_or_null("UpgradePanel/WeaponButton")
	armor_button = get_node_or_null("UpgradePanel/ArmorButton") 
	continue_button = get_node_or_null("ContinueButton")
	dialogue_label = get_node_or_null("ShopkeeperDialogue")
	shopkeeper_sprite = get_node_or_null("ShopkeeperSprite")
	
	print("Node check:")
	print("  gear_display: ", gear_display != null)
	print("  chassis_button: ", chassis_button != null)
	print("  propulsion_button: ", propulsion_button != null)
	print("  weapon_button: ", weapon_button != null)
	
	print("  armor_button: ", armor_button != null)
	print("  continue_button: ", continue_button != null)
	print("  dialogue_label: ", dialogue_label != null)
	print("  shopkeeper_sprite: ", shopkeeper_sprite != null)
	#connects the buttons 
	if chassis_button:
		chassis_button.pressed.connect(_on_chassis_button_pressed)
		
	if armor_button:
		armor_button.pressed.connect(_on_armor_button_pressed) 
		
	if propulsion_button:
		propulsion_button.pressed.connect(_on_propulsion_button_pressed)
	if weapon_button:
		weapon_button.pressed.connect(_on_weapon_button_pressed)
	if continue_button:
		continue_button.pressed.connect(_on_continue_button_pressed)
		set_button_tooltips()
	print("=== SHOP _ready() COMPLETE ===")


func initialize_shop(gears: int, stage: int, c_lvl: int, p_lvl: int, w_unlocked: bool,w_upgraded: bool ):
	print("=== initialize_shop() CALLED ===")
	print("  Gears: ", gears, " Stage: ", stage)
	
	if is_initialized:
		print("  Already initialized, skipping")
		return
	
	# Wait for nodes to be ready
	if not gear_display:
		print("  Nodes not ready, waiting...")
		await get_tree().create_timer(0.1).timeout
	
	is_initialized = true
	player_gears = gears
	current_stage = stage
	chassis_level = c_lvl
	propulsion_level = p_lvl
	weapon_unlocked = w_unlocked
	weapon_upgraded = w_upgraded 
	gears_spent_this_visit = 0
	
	
	update_ui()
	

	if dialogue_label:
		if current_stage == 5:
			dialogue_label.text = "The final battle awaits! I'm equipping you with a weapon.\nYou can upgrade it for extra firepower if you've got the gears!"
		if current_stage == 4:
			dialogue_label.text = "Heads up! The incoming swarm is utilizing stealth technology; \nthey'll flicker and vanish. Stay on your guard!"
		if current_stage == 3:
			dialogue_label.text = "Heads up! The incoming swarm are like stalkers, they love to follwo you."
		
		if current_stage == 2:
			dialogue_label.text = "That seemed too easy, \n these next clankers wont be so gear up!"
		
		else:
			dialogue_label.text = "Welcome to Clanker's Junkyard, Traveller! Take a look at my wares. I can lend you some gears but look out for some on the battlefield."
	
	print("=== Shop initialized successfully! ===")
func update_ui():
	if not gear_display or not chassis_button:
		print("WARNING: UI nodes not ready in update_ui()")
		return
	
	var chassis_price = CHASSIS_BASE_PRICE * (chassis_level + 1)
	var propulsion_price = PROPULSION_BASE_PRICE * (propulsion_level + 1)
	

	gear_display.text = "Gears: %d" % player_gears  
	
	if chassis_level < 3:
		chassis_button.text = "CHASSIS LVL %d -> %d (%d G)" % [chassis_level, chassis_level + 1, chassis_price]
		chassis_button.disabled = player_gears < chassis_price  # FIX: use player_gears
	else:
		chassis_button.text = "CHASSIS MAX LEVEL"
		chassis_button.disabled = true
	
	
	if propulsion_level < 3:
		propulsion_button.text = "PROPULSION LVL %d -> %d (%d G)" % [propulsion_level, propulsion_level + 1, propulsion_price]
		propulsion_button.disabled = player_gears < propulsion_price  # FIX: use player_gears
	else:
		propulsion_button.text = "PROPULSION MAX LEVEL"
		propulsion_button.disabled = true

	if weapon_button:
		if current_stage < 5:
			weapon_button.text = "WEAPON (Not Available)"
			weapon_button.disabled = true
		elif current_stage == 5 and not weapon_upgraded:
			weapon_button.text = "UPGRADE WEAPON -> HEAVY (%d G)" % WEAPON_UNLOCK_PRICE
			weapon_button.disabled = player_gears < WEAPON_UNLOCK_PRICE
		else:
			weapon_button.text = "HEAVY WEAPON EQUIPPED"
			weapon_button.disabled = true
	if armor_button:
		armor_button.text = "ARMOR SHIELD (%d G)" % ARMOR_PRICE
		
		var main = get_tree().get_first_node_in_group("main")  
		var player_node = null
		var already_has_armor = false
		
		if main:
			player_node = main.player
			if player_node:
				already_has_armor = player_node.has_armor
		
#was trying to see where the problem was 
		print("DEBUG - Armor button check:")
		print("  player_gears: ", player_gears)
		print("  ARMOR_PRICE: ", ARMOR_PRICE)
		print("  already_has_armor: ", already_has_armor)
		print("  Can afford: ", player_gears >= ARMOR_PRICE)
		
		armor_button.disabled = (player_gears < ARMOR_PRICE) or already_has_armor
		print("  Final disabled state: ", armor_button.disabled)
	

	if gears_spent_this_visit == 0:
		continue_button.text = "SKIP (No Purchase)"
		continue_button.disabled = false
	else:
		continue_button.text = "CONTINUE"
		continue_button.disabled = false
	
	print("UI updated. Gears: ", player_gears) 
	
#explanations
func set_button_tooltips():
	if chassis_button:
		chassis_button.tooltip_text = "Increases your maximum health by 1.\n(Chassis Level +1)"
	if propulsion_button:
		propulsion_button.tooltip_text = "Increases your movement speed by 50.\n(Propulsion Level +1)"
	if weapon_button:
		weapon_button.tooltip_text = "Unlocks a basic weapon to fight back against enemies.\nRequired to defeat the final boss."
	if armor_button: 
		armor_button.tooltip_text = "Grants a temporary energy shield that absorbs the next hit without affecting your health."



func _on_armor_button_pressed():
	if player_gears >= ARMOR_PRICE:
		player_gears -= ARMOR_PRICE
		gears_spent_this_visit += ARMOR_PRICE
		
		# Give the player armor
		var main = get_tree().get_first_node_in_group("main")
		if main and main.player:
			main.player.has_armor = true
			#mMake player glow blue
			main.player.modulate = Color(0.7, 0.7, 1.0)  
		
		if dialogue_label:
			dialogue_label.text = "Shield activated! It will absorb one hit."
		update_ui()
		
		
func _on_chassis_button_pressed():
	var cost = CHASSIS_BASE_PRICE * (chassis_level + 1)
	if player_gears >= cost:
		player_gears -= cost
		gears_spent_this_visit += cost
		chassis_level += 1
		if dialogue_label:
			dialogue_label.text = "A sturdier frame! You'll survive the next breach."
		update_ui()
		
func _on_propulsion_button_pressed():
	var cost = PROPULSION_BASE_PRICE * (propulsion_level + 1)
	if player_gears >= cost:  
		player_gears -= cost  
		gears_spent_this_visit += cost 
		propulsion_level += 1
		if dialogue_label:
			dialogue_label.text = "Faster propulsion! Can't catch what you can't see."
		update_ui()

func _on_weapon_button_pressed():
	if current_stage == 5 and not weapon_upgraded and player_gears >= WEAPON_UNLOCK_PRICE:
		player_gears -= WEAPON_UNLOCK_PRICE
		gears_spent_this_visit += WEAPON_UNLOCK_PRICE
		weapon_upgraded = true
		if dialogue_label:
			dialogue_label.text = "Weapon upgraded to Heavy Cannon! Double damage - this'll shred the Glitch King!"
		update_ui()

func _on_continue_button_pressed():
	print("Emitting shop_closed signal...")
	shop_closed.emit(
		gears_spent_this_visit,  
		chassis_level,
		propulsion_level,
		weapon_unlocked,
		weapon_upgraded)
	queue_free()
