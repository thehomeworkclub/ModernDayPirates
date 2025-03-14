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

# 2D UI container
var canvas_layer: CanvasLayer
var container: Control

func _ready():
	# Set unique name for easier reference
	name = "InfoBoard"
	add_to_group("InfoBoard")
	print("DEBUG: InfoBoard2D script attached to: " + name)
	
	# Create a CanvasLayer for 2D UI
	canvas_layer = CanvasLayer.new()
	canvas_layer.name = "InfoBoardCanvas"
	canvas_layer.layer = 10  # Set high layer to ensure visibility
	add_child(canvas_layer)
	
	# Create container
	container = Control.new()
	container.name = "HealthContainer"
	container.size = Vector2(get_viewport().size)
	container.position = Vector2(20, 20)  # Position in top-left
	canvas_layer.add_child(container)
	
	print("DEBUG: Created 2D UI container")
	
	# Find the player after a short delay
	call_deferred("_setup_references")
	
	# Create test hearts to verify visibility
	print("DEBUG: Creating test health icons")
	create_health_display(5, 10)

func _setup_references():
	await get_tree().create_timer(0.5).timeout  # Give time for scene to initialize
	
	# Get player reference
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		player = players[0]
		print("DEBUG: InfoBoard2D found player with health: " + str(player.health) + "/" + str(player.max_health))
		create_health_display(player.health, player.max_health)
	else:
		print("DEBUG: InfoBoard2D - Player not found, will retry")
		await get_tree().create_timer(1.0).timeout
		_setup_references()

func create_health_display(current_health: int, max_health: int):
	print("DEBUG: InfoBoard2D - Creating health display - Current: ", current_health, " Max: ", max_health)
	
	# Clear any existing health icons
	for icon in health_icons:
		if is_instance_valid(icon):
			icon.queue_free()
	health_icons.clear()
	
	# Determine how many hearts to show
	var hearts_to_show = min(max_health, max_health_display)
	
	# Create health icons (2D texture rects)
	for i in range(hearts_to_show):
		var heart = TextureRect.new()
		heart.name = "HealthIcon_" + str(i)
		
		# Set texture based on current health
		if i < current_health:
			heart.texture = full_heart
		else:
			heart.texture = empty_heart
		
		if heart.texture == null:
			print("ERROR: Texture not loaded for heart icon " + str(i))
			continue
			
		# Set size and position
		heart.expand = true
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		heart.size = Vector2(32, 32)
		heart.position = Vector2(i * (heart.size.x + 5), 0)
		
		# Add to container
		container.add_child(heart)
		health_icons.append(heart)
		
		print("DEBUG: Created 2D heart icon " + str(i) + " at position " + str(heart.position))
	
	print("DEBUG: InfoBoard2D - Created " + str(health_icons.size()) + " health icons")

func update_health_display(current_health: int):
	print("DEBUG: InfoBoard2D - Updating health display to " + str(current_health))
	
	# Update existing icons
	for i in range(health_icons.size()):
		if i < current_health:
			health_icons[i].texture = full_heart
		else:
			health_icons[i].texture = empty_heart

# Function to be called from Player when health changes
func on_player_health_changed(current_health: int, max_health: int):
	print("DEBUG: InfoBoard2D - Health changed notification received: " + str(current_health) + "/" + str(max_health))
	
	if health_icons.size() == 0 or health_icons.size() != min(max_health, max_health_display):
		# If we don't have the right number of icons, recreate the display
		create_health_display(current_health, max_health)
	else:
		# Otherwise just update existing icons
		update_health_display(current_health)
