extends MeshInstance3D

# References
var player: Node = null
var health_icons: Array = []

# Icon resources
@onready var full_heart = preload("res://art/fullheart.png")
@onready var empty_heart = preload("res://art/emptyheart.png")

# UI settings
@export var max_health_display: int = 10
@export var heart_size: Vector2 = Vector2(50, 50)
@export var heart_spacing: float = 10.0
@export var heart_start_position: Vector2 = Vector2(20, 20)

# UI container
var ui_container: Node3D

func _ready():
	# Set unique name for easier reference
	name = "InfoBoard"
	
	# Add to group for easier finding
	add_to_group("InfoBoard")
	
	print("DEBUG: InfoBoard script attached to: " + name)
	print("DEBUG: InfoBoard global position: " + str(global_position))
	
	# Create UI container
	ui_container = Node3D.new()
	ui_container.name = "UIContainer"
	add_child(ui_container)
	
	# Position the UI container in front of the board
	ui_container.position = Vector3(0, 0, -0.5)  # Increased offset to make it more visible
	
	# Find the player
	call_deferred("_setup_references")
	
	# Create test hearts to verify visibility
	print("DEBUG: Creating test health icons")
	create_health_display(5, 10)  # Initial test display

func _setup_references():
	# Get player reference
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		player = players[0]
		print("DEBUG: InfoBoard found player with health: " + str(player.health) + "/" + str(player.max_health))
		# Create initial health display
		create_health_display(player.health, player.max_health)
	else:
		print("DEBUG: InfoBoard - Player not found, will retry in 1 second")
		await get_tree().create_timer(1.0).timeout
		_setup_references()

func create_health_display(current_health: int, max_health: int):
	print("DEBUG: InfoBoard - Creating health display - Current: ", current_health, " Max: ", max_health)
	
	# Clear any existing health icons
	for icon in health_icons:
		if is_instance_valid(icon):
			icon.queue_free()
	health_icons.clear()
	
	# Determine how many hearts to show (capped at max_health_display)
	var hearts_to_show = min(max_health, max_health_display)
	
	# Create health icons
	for i in range(hearts_to_show):
		var sprite = Sprite3D.new()
		sprite.name = "HealthIcon_" + str(i)
		
		# Set texture based on current health
		if i < current_health:
			sprite.texture = full_heart
		else:
			sprite.texture = empty_heart
		
		if sprite.texture == null:
			print("ERROR: Texture not loaded for heart icon " + str(i))
			continue
		
		# Configure sprite properties for maximum visibility
		sprite.pixel_size = 0.01  # Increased size
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sprite.no_depth_test = true
		sprite.double_sided = true
		sprite.shaded = false
		sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
		sprite.alpha_antialiasing_mode = BaseMaterial3D.ALPHA_ANTIALIASING_OFF
		
		# Position horizontally with better spacing
		var x_offset = -0.45 + (i * 0.08)  # Adjusted for better visibility
		sprite.position = Vector3(x_offset, 0.25, -0.6)  # Positioned more in front
		
		# Add to UI container
		ui_container.add_child(sprite)
		health_icons.append(sprite)
		
		print("DEBUG: Created heart icon " + str(i) + " at position " + str(sprite.position))
	
	print("DEBUG: InfoBoard - Created " + str(health_icons.size()) + " health icons")

func update_health_display(current_health: int):
	print("DEBUG: InfoBoard - Updating health display to " + str(current_health))
	
	# Update existing icons
	for i in range(health_icons.size()):
		if i < current_health:
			health_icons[i].texture = full_heart
		else:
			health_icons[i].texture = empty_heart

# Function to be called from Player when health changes
func on_player_health_changed(current_health: int, max_health: int):
	print("DEBUG: InfoBoard - Health changed notification received: " + str(current_health) + "/" + str(max_health))
	
	if health_icons.size() == 0 or health_icons.size() != min(max_health, max_health_display):
		# If we don't have the right number of icons, recreate the display
		create_health_display(current_health, max_health)
	else:
		# Otherwise just update existing icons
		update_health_display(current_health)
