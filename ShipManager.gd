extends Node

# ShipManager handles ship spawning and targeting
# It creates invisible planes for spawn and target positions

# Configure spawning area
var spawn_width: float = 50.0
var spawn_depth: float = 20.0
var spawn_distance_from_player: float = 100.0

# Configure target area
var target_width: float = 40.0
var target_depth: float = 30.0
var target_distance_from_player: float = 25.0

# Internal variables
var player_boat = null
var spawn_plane = null
var target_plane = null
var used_target_positions = []
var spawn_plane_material = null
var target_plane_material = null

# Set to true to see the planes in debug mode
var debug_visible_planes: bool = false

func _ready():
	print("ShipManager initialized!")
	
	# Find player boat
	var boats = get_tree().get_nodes_in_group("Player")
	if boats.size() > 0:
		player_boat = boats[0]
		print("Found player boat at: ", player_boat.global_position)
	
	# Create the invisible planes
	create_planes()
	
	# Hide any existing target planes in the scene
	var existing_planes = get_tree().get_nodes_in_group("TargetPlane")
	for plane in existing_planes:
		if plane != spawn_plane and plane != target_plane:
			plane.visible = false
			print("Hidden existing plane: ", plane.name)

func create_planes():
	# Create the spawn plane
	spawn_plane = create_plane("SpawnPlane", spawn_width, spawn_depth, Color(0.0, 0.2, 1.0, 0.2))
	spawn_plane.add_to_group("SpawnPlane")
	
	# Create the target plane
	target_plane = create_plane("TargetPlane", target_width, target_depth, Color(1.0, 0.2, 0.0, 0.2))
	target_plane.add_to_group("TargetPlane")
	
	# Position the planes - spawn plane far away, target plane closer
	if player_boat:
		spawn_plane.global_position = Vector3(0, 0.1, player_boat.global_position.z + spawn_distance_from_player)
		target_plane.global_position = Vector3(0, 0.1, player_boat.global_position.z + target_distance_from_player)
	else:
		spawn_plane.global_position = Vector3(0, 0.1, 70.0)
		target_plane.global_position = Vector3(0, 0.1, 0.0)
	
	# Make planes invisible in game mode unless debugging
	spawn_plane.visible = debug_visible_planes
	target_plane.visible = debug_visible_planes
	
	# Add to scene
	get_tree().current_scene.add_child(spawn_plane)
	get_tree().current_scene.add_child(target_plane)
	
	print("Created planes - spawn at Z: ", spawn_plane.global_position.z, 
		  ", target at Z: ", target_plane.global_position.z)

func create_plane(name: String, width: float, depth: float, color: Color) -> MeshInstance3D:
	var plane = MeshInstance3D.new()
	plane.name = name
	
	# Create mesh
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(width, depth)
	plane.mesh = plane_mesh
	
	# Create material
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = Color(color.r, color.g, color.b, 0.3)
	material.emission_energy = 0.5
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	plane_mesh.material = material
	
	if name == "SpawnPlane":
		spawn_plane_material = material
	else:
		target_plane_material = material
	
	return plane

# Track used spawn positions to avoid overlap
var used_spawn_positions = []
var last_spawn_time = 0
var spawn_batch_id = 0

# Called by enemies to get a spawn position
func get_spawn_position() -> Vector3:
	if not spawn_plane:
		return Vector3(0, 0, 70)
	
	# Check if this is a new batch based on time
	var current_time = Time.get_ticks_msec()
	if current_time - last_spawn_time > 500:  # If more than 500ms since last spawn, consider it a new batch
		spawn_batch_id += 1
		print("New spawn batch: ", spawn_batch_id)
		# Clear previous batch positions to ensure each batch uses different positions
		used_spawn_positions.clear()
	
	last_spawn_time = current_time
	
	# Try to find a non-overlapping position
	var spawn_pos = Vector3.ZERO
	var max_attempts = 15
	var min_distance = 8.0  # Increased minimum distance
	
	for i in range(max_attempts):
		# Generate random position
		spawn_pos = Vector3(
			spawn_plane.global_position.x + randf_range(-spawn_width/2, spawn_width/2),
			0,
			spawn_plane.global_position.z + randf_range(-spawn_depth/2, spawn_depth/2)
		)
		
		# Check if too close to other spawn positions
		var valid = true
		for pos in used_spawn_positions:
			if spawn_pos.distance_to(pos) < min_distance:
				valid = false
				break
				
		if valid:
			break
	
	# Remember this spawn position
	used_spawn_positions.append(spawn_pos)
	
	print("Ship will spawn at: ", spawn_pos, " (batch ", spawn_batch_id, ")")
	return spawn_pos

# Track batches for target positions too
var target_batch_id = 0
var last_target_time = 0
var batch_used_cells = []

# Called by enemies to get a target position
func get_target_position() -> Vector3:
	if not target_plane:
		return Vector3(0, 0, 0)
	
	# Check if this is a new batch based on time
	var current_time = Time.get_ticks_msec()
	if current_time - last_target_time > 500:  # If more than 500ms since last target, new batch
		target_batch_id += 1
		print("New target batch: ", target_batch_id)
		# Clear batch tracking
		batch_used_cells.clear()
	
	last_target_time = current_time
	
	# Use a grid-based approach for better distribution
	var grid_size = 5
	var cell_width = target_width / grid_size
	var cell_depth = target_depth / grid_size
	
	# Try to find an unused cell
	var available_cells = []
	for x in range(grid_size):
		for z in range(grid_size):
			var cell_id = x * grid_size + z
			
			# Skip if this cell was already used in this batch
			if batch_used_cells.has(cell_id):
				continue
				
			var cell_center_x = target_plane.global_position.x - (target_width/2) + (x * cell_width) + (cell_width/2)
			var cell_center_z = target_plane.global_position.z - (target_depth/2) + (z * cell_depth) + (cell_depth/2)
			var cell_center = Vector3(cell_center_x, 0, cell_center_z)
			
			# Check if cell is too close to used positions
			var cell_used = false
			for pos in used_target_positions:
				if pos.distance_to(cell_center) < cell_width * 0.8:  # Reduced overlap threshold
					cell_used = true
					break
					
			if not cell_used:
				available_cells.append({"position": cell_center, "cell_id": cell_id})
	
	# If we have available cells, pick one randomly
	var position
	if available_cells.size() > 0:
		available_cells.shuffle()
		var chosen_cell = available_cells[0]
		position = chosen_cell.position
		
		# Remember this cell is used for this batch
		batch_used_cells.append(chosen_cell.cell_id)
		
		# Add some randomness within the cell
		position.x += randf_range(-cell_width/4, cell_width/4)
		position.z += randf_range(-cell_depth/4, cell_depth/4)
	else:
		# Fall back to a fully random position with spacing check
		var valid_position = false
		var attempts = 0
		
		while !valid_position && attempts < 15:
			position = Vector3(
				target_plane.global_position.x + randf_range(-target_width/2, target_width/2),
				0,
				target_plane.global_position.z + randf_range(-target_depth/2, target_depth/2)
			)
			
			# Check if too close to other positions
			valid_position = true
			for pos in used_target_positions:
				if position.distance_to(pos) < 5.0:
					valid_position = false
					break
					
			attempts += 1
	
	# Remember this position
	used_target_positions.append(position)
	
	# Create a visual marker for debugging
	if debug_visible_planes:
		create_debug_marker(position)
	
	print("Ship will target: ", position, " (batch ", target_batch_id, ")")
	return position

func create_debug_marker(position):
	var marker = MeshInstance3D.new()
	marker.name = "TargetMarker"
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

func clear_target_position(position):
	# Remove position when enemy is destroyed
	for i in range(used_target_positions.size()):
		if used_target_positions[i].distance_to(position) < 5.0:
			used_target_positions.remove_at(i)
			print("Cleared target position: ", position)
			break
			
	# Also remove any debug markers
	var markers = get_tree().get_nodes_in_group("TargetMarker")
	for marker in markers:
		if marker.global_position.distance_to(position) < 5.0:
			marker.queue_free()
			break
			
	# Keep the used_target_positions array from growing too large
	if used_target_positions.size() > 40:
		# Remove oldest positions
		var to_remove = used_target_positions.size() - 30
		for i in range(to_remove):
			used_target_positions.remove_at(0)
		print("Cleaned up target positions array, removed ", to_remove, " old positions")