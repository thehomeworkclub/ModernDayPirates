extends Node3D

# Cargo Ship Loader
# Example script demonstrating how to load cargo ship meshes at runtime

# Paths to mesh files
const SHIP_PATHS = {
	"covered_boat": "res://cargo_ships/meshes/Covered Boat.fbx",
	"crane": "res://cargo_ships/meshes/Crane.fbx",
	"deck_crane": "res://cargo_ships/meshes/DeckCrane.fbx",
	"dry_cargo": "res://cargo_ships/meshes/Dry_Cargo.fbx",
	"dry_cargo_ship": "res://cargo_ships/meshes/Dry_Cargo_Ship.fbx",
	"dry_cargo_ship_1": "res://cargo_ships/meshes/Dry_Cargo_Ship_1.fbx",
	"lifebuoy": "res://cargo_ships/meshes/lifebuoy.fbx",
	"uncovered_boat": "res://cargo_ships/meshes/Uncovered Boat.fbx"
}

# Default VR position from .clinerules for the campaign menu
const VR_POSITION = Vector3(10.954, -7.596, 4.236)

# Note on VR player positioning in levels:
# - In level1.tscn, XROrigin3D is positioned through the editor at (2.45716, 16.3239, 53.035)
# - When adding ships to levels, ensure the ship is placed
#   sufficiently below the XROrigin3D position to avoid the player spawning
#   inside or under a ship
# - Always preserve editor-defined XROrigin3D positions rather than 
#   overriding them in scripts

# Example ship configurations - position relative to VR position, scale, rotation
const SHIP_CONFIGS = {
	"dry_cargo_ship": {
		"position": Vector3(5, -10, 10),
		"scale": Vector3(1, 1, 1),
		"rotation": Vector3(0, deg_to_rad(45), 0)
	},
	"crane": {
		"position": Vector3(15, -8, 15),
		"scale": Vector3(1, 1, 1),
		"rotation": Vector3(0, 0, 0)
	}
}

# Called when the node enters the scene tree for the first time
func _ready():
	print_verbose("Cargo Ship Loader initializing...")
	# Example: Load a specific ship
	load_ship("dry_cargo_ship")
	
	# Example: Load all ships (commented out for performance)
	# load_all_ships()

# Load a specific ship by key
func load_ship(ship_key: String) -> MeshInstance3D:
	if not SHIP_PATHS.has(ship_key):
		print_verbose("Ship key not found: " + ship_key)
		return null
		
	print_verbose("Loading ship: " + ship_key)
	
	# Create mesh instance
	var ship_instance = MeshInstance3D.new()
	ship_instance.name = ship_key.capitalize()
	
	# Load the mesh
	var ship_mesh = load(SHIP_PATHS[ship_key])
	if ship_mesh == null:
		print_verbose("Failed to load mesh: " + SHIP_PATHS[ship_key])
		return null
		
	ship_instance.mesh = ship_mesh
	
	# Apply configuration if available
	if SHIP_CONFIGS.has(ship_key):
		var config = SHIP_CONFIGS[ship_key]
		ship_instance.position = VR_POSITION + config.position
		ship_instance.scale = config.scale
		ship_instance.rotation = config.rotation
	else:
		# Default position if no config exists
		ship_instance.position = VR_POSITION + Vector3(10, 0, 10)
	
	# Add to scene
	add_child(ship_instance)
	
	print_verbose("Ship loaded: " + ship_key)
	return ship_instance

# Load all ships (may impact performance)
func load_all_ships() -> void:
	print_verbose("Loading all ships...")
	for ship_key in SHIP_PATHS.keys():
		load_ship(ship_key)
	print_verbose("All ships loaded")

# Create collision shape for a ship
func add_collision_to_ship(ship_instance: MeshInstance3D) -> void:
	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	
	# Create approximate box based on mesh bounds
	# Note: In a real implementation, you'd calculate actual bounds
	box_shape.extents = Vector3(2, 2, 5)
	collision_shape.shape = box_shape
	
	# Create static body to hold collision
	var static_body = StaticBody3D.new()
	static_body.name = ship_instance.name + "Body"
	static_body.add_child(collision_shape)
	ship_instance.add_child(static_body)
	
	print_verbose("Added collision to: " + ship_instance.name)
