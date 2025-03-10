extends Node

# This script creates random target positions for enemies
# Simple implementation that should work reliably

# Size of the target area
var width: float = 40.0
var depth: float = 30.0 
var distance_from_player: float = 25.0

# Track assigned positions
var used_positions = []
var player_boat = null

func _ready():
	print("SimpleEnemyTargeter: Ready!")
	
	# Find player boat
	var boats = get_tree().get_nodes_in_group("Player")
	if boats.size() > 0:
		player_boat = boats[0]
		print("Found player boat at: ", player_boat.global_position)

# Called by enemies to get a position
func get_target_position() -> Vector3:
	# Position the target area in front of the player
	var area_center = Vector3.ZERO
	if player_boat:
		area_center = Vector3(player_boat.global_position.x, 0, player_boat.global_position.z + distance_from_player)
	else:
		area_center = Vector3(0, 0, -10)
	
	# Generate a random position within a grid
	var grid_size = 5
	var cell_width = width / grid_size
	var cell_depth = depth / grid_size
	
	# Try to find an unused cell
	var available_cells = []
	for x in range(grid_size):
		for z in range(grid_size):
			var cell_center_x = area_center.x - (width/2) + (x * cell_width) + (cell_width/2)
			var cell_center_z = area_center.z - (depth/2) + (z * cell_depth) + (cell_depth/2)
			var cell_center = Vector3(cell_center_x, 0, cell_center_z)
			
			# Check if cell is used
			var cell_used = false
			for pos in used_positions:
				if pos.distance_to(cell_center) < cell_width:
					cell_used = true
					break
					
			if not cell_used:
				available_cells.append(cell_center)
	
	# If we have available cells, pick one randomly
	var position
	if available_cells.size() > 0:
		available_cells.shuffle()
		position = available_cells[0]
		
		# Add some randomness within the cell
		position.x += randf_range(-cell_width/4, cell_width/4)
		position.z += randf_range(-cell_depth/4, cell_depth/4)
	else:
		# Fall back to a fully random position
		position = Vector3(
			area_center.x + randf_range(-width/2, width/2),
			0,
			area_center.z + randf_range(-depth/2, depth/2)
		)
	
	# Remember this position
	used_positions.append(position)
	
	# Create a visual marker for debugging
	create_debug_marker(position)
	
	print("New target position: ", position)
	return position

func create_debug_marker(position):
	var marker = MeshInstance3D.new()
	marker.name = "TargetMarker"
	
	# Add to group for easier reference
	marker.add_to_group("TargetMarker")
	
	# Create a small sphere mesh
	var sphere = SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	marker.mesh = sphere
	
	# Create orange glowing material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.5, 0.0, 0.8)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.3, 0.0, 0.5) 
	material.emission_energy = 2.0
	sphere.material = material
	
	# Set position
	marker.global_position = position
	
	# Add to scene
	get_tree().current_scene.add_child(marker)

func clear_position(position):
	# Remove position when enemy is destroyed
	for i in range(used_positions.size()):
		if used_positions[i].distance_to(position) < 5.0:
			used_positions.remove_at(i)
			break
			
	# Also remove any debug markers
	var markers = get_tree().get_nodes_in_group("TargetMarker")
	for marker in markers:
		if marker.global_position.distance_to(position) < 5.0:
			marker.queue_free()
			break