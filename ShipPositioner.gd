extends Node3D

# This script manages a large area in front of the player
# where enemy ships will randomly position themselves

# Size of the area (will be determined by target plane size)
var width: float = 40.0  # Default width (X-axis)
var depth: float = 30.0  # Default depth (Z-axis)
@export var min_distance_from_player: float = 20.0  # Minimum distance from player

# Internal variables
var target_positions = []
var player_boat = null
var target_plane = null
var plane_orientation = Vector3.FORWARD  # Default plane orientation

func _ready():
	# Find the player's boat
	var boats = get_tree().get_nodes_in_group("Player")
	if boats.size() > 0:
		player_boat = boats[0]
		print("DEBUG: Found player boat at ", player_boat.global_position)
	
	# Immediately hide any target plane that might exist
	var existing_plane = get_tree().current_scene.get_node_or_null("TargetPlane")
	if existing_plane:
		existing_plane.visible = false
	
	# First look for a node named "TargetPlane" in the scene
	target_plane = existing_plane
	
	# If not found, create a new plane node
	if not target_plane:
		# Create a new target plane
		create_target_plane()
	else:
		# If found, use its properties
		connect_to_existing_plane()
		
	# Force the plane to be invisible
	if target_plane:
		target_plane.visible = false
	
	print("ShipPositioner: Ready - ships will move to random positions in the target area")
	print("Area extends from X: ", global_position.x - width/2, " to ", global_position.x + width/2)
	print("Area extends from Z: ", global_position.z - depth/2, " to ", global_position.z + depth/2)

func connect_to_existing_plane():
	# Get the size of the existing plane
	if target_plane is MeshInstance3D and target_plane.mesh is PlaneMesh:
		var plane_mesh = target_plane.mesh as PlaneMesh
		width = plane_mesh.size.x
		depth = plane_mesh.size.y
	else:
		# If not a mesh or not a plane mesh, use default values
		width = 40.0
		depth = 30.0
	
	# Get the orientation of the plane
	if target_plane.rotation.y != 0:
		# Adjust for orientation
		plane_orientation = target_plane.global_transform.basis.z
	
	# Use the plane's position
	global_position = target_plane.global_position
	
	# Make the plane invisible in-game, but leave it visible in editor
	if Engine.is_editor_hint():
		# Make the plane semi-transparent in editor for visualization
		if target_plane is MeshInstance3D:
			var material = StandardMaterial3D.new()
			material.albedo_color = Color(0.0, 0.5, 1.0, 0.2)
			material.emission_enabled = true
			material.emission = Color(0.0, 0.5, 1.0, 0.1)
			material.emission_energy = 0.2
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			
			# Apply the material
			if target_plane.get_surface_override_material_count() > 0:
				target_plane.set_surface_override_material(0, material)
			else:
				# If it doesn't have surface materials, set mesh material
				if target_plane.mesh:
					target_plane.mesh.material = material
	else:
		# Make invisible in-game
		target_plane.visible = false
	
	print("Connected to existing target plane at ", global_position)

func create_target_plane():
	# Create a new target plane
	target_plane = MeshInstance3D.new()
	target_plane.name = "TargetPlane"
	
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(width, depth)
	target_plane.mesh = plane_mesh
	
	# Create material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.0, 0.5, 1.0, 0.2)
	material.emission_enabled = true
	material.emission = Color(0.0, 0.5, 1.0, 0.1)
	material.emission_energy = 0.2
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	plane_mesh.material = material
	
	# Position in front of the player
	if player_boat:
		# Check if player is at origin (which suggests it hasn't been positioned yet)
		if player_boat.global_position == Vector3.ZERO:
			print("WARNING: Player boat at origin (0,0,0), using scene transform value")
			# Use the transform from the scene as fallback
			var player_node = get_tree().current_scene.get_node_or_null("Player")
			if player_node and player_node.transform:
				target_plane.global_position = Vector3(0, 0.1, player_node.transform.origin.z + min_distance_from_player)
			else:
				target_plane.global_position = Vector3(0, 0.1, -10.0 + min_distance_from_player)
		else:
			target_plane.global_position = Vector3(0, 0.1, player_boat.global_position.z + min_distance_from_player)
	else:
		target_plane.global_position = Vector3(0, 0.1, -10.0)  # Default position
	
	# Add to scene
	get_tree().current_scene.add_child(target_plane)
	
	# Make it invisible in-game
	target_plane.visible = false
	
	# Update our position to match
	global_position = target_plane.global_position

func get_random_position() -> Vector3:
	# Generate a random position within the area
	var x = global_position.x + randf_range(-width/2, width/2)
	var z = global_position.z + randf_range(-depth/2, depth/2)
	
	# Consider rotation if the plane is rotated
	if plane_orientation != Vector3.FORWARD:
		# Transform the position based on plane orientation
		var local_pos = Vector3(x - global_position.x, 0, z - global_position.z)
		var transformed = target_plane.global_transform.basis * local_pos
		return target_plane.global_position + transformed
	
	# Return global position
	return Vector3(x, 0, z)

func get_non_overlapping_position(min_distance: float = 5.0) -> Vector3:
	# Try to find a position that doesn't overlap with existing ships
	var max_attempts = 30  # Increase max attempts to find a good spot
	var position = Vector3.ZERO
	
	# First try: prioritize wider distribution by splitting the plane into zones
	var num_zones_x = 8  # More zones for better distribution
	var num_zones_z = 5
	var zones = []
	
	# Create a grid of zones
	for x in range(num_zones_x):
		for z in range(num_zones_z):
			zones.append(Vector2(x, z))
			
	# Shuffle the zones to get random order
	zones.shuffle()
	
	# Try to find a position in an unused zone first
	for zone in zones:
		# Calculate zone boundaries
		var zone_width = width / num_zones_x
		var zone_depth = depth / num_zones_z
		
		var zone_min_x = (zone.x * zone_width) - (width / 2) + global_position.x
		var zone_max_x = zone_min_x + zone_width
		var zone_min_z = (zone.y * zone_depth) - (depth / 2) + global_position.z
		var zone_max_z = zone_min_z + zone_depth
		
		# Check if zone already has a position
		var zone_used = false
		for pos in target_positions:
			if pos.x >= zone_min_x && pos.x <= zone_max_x && pos.z >= zone_min_z && pos.z <= zone_max_z:
				zone_used = true
				break
				
		if not zone_used:
			# Generate position in this zone
			var x = randf_range(zone_min_x, zone_max_x)
			var z = randf_range(zone_min_z, zone_max_z)
			position = Vector3(x, 0, z)
			
			# Add to used positions
			target_positions.append(position)
			
			# Create a debug marker in debug mode
			if OS.is_debug_build():
				create_position_marker(position)
				
			return position
	
	# Second try: use traditional approach with minimum distance check
	for i in range(max_attempts):
		position = get_random_position()
		
		# Check distance from all used positions
		var valid = true
		for pos in target_positions:
			if position.distance_to(pos) < min_distance:
				valid = false
				break
				
		if valid:
			target_positions.append(position)
			
			# Create a debug marker if it's a debug build
			if OS.is_debug_build():
				create_position_marker(position)
				
			return position
	
	# If we still couldn't find a non-overlapping position, return any position
	position = get_random_position()
	target_positions.append(position)
	
	# Create a debug marker if it's a debug build
	if OS.is_debug_build():
		create_position_marker(position)
		
	return position

func create_position_marker(position: Vector3) -> void:
	# Create a small marker at the position for debugging
	var marker = MeshInstance3D.new()
	marker.name = "PositionMarker"
	
	# Create a small sphere
	var sphere = SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	marker.mesh = sphere
	
	# Create material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.5, 0.0, 0.5)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.5, 0.0, 0.3)
	material.emission_energy = 0.5
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sphere.material = material
	
	# Set position slightly above plane 
	marker.global_position = Vector3(position.x, position.y + 0.5, position.z)
	
	# Add to scene
	get_tree().current_scene.add_child(marker)

func clear_used_position(position: Vector3) -> void:
	# When a ship is destroyed, remove its position from the used list
	for i in range(target_positions.size()):
		if target_positions[i].distance_to(position) < 2.0:
			target_positions.remove_at(i)
			break
	
	# Also remove any debug markers at this position
	for child in get_tree().current_scene.get_children():
		if child.name == "PositionMarker" && child.global_position.distance_to(position) < 2.0:
			child.queue_free()
			break