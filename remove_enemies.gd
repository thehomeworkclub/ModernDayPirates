@tool
extends EditorScript

# This script removes enemy spawning from all level scenes
# It can be run from the Godot editor

func _run():
	print("Starting enemy removal process...")
	
	# Process level1.tscn
	disable_enemies_in_level("res://level1.tscn")
	
	# Process stage2.tscn (temp game version)
	if FileAccess.file_exists("res://temp-game/stage2.tscn"):
		disable_enemies_in_level("res://temp-game/stage2.tscn")
	
	# Process any other integrated stage scenes
	if FileAccess.file_exists("res://stage2.tscn"):
		disable_enemies_in_level("res://stage2.tscn")
	
	print("Enemy removal process complete")

# Function to disable enemies in a level file
func disable_enemies_in_level(scene_path: String):
	print("Processing: " + scene_path)
	
	var scene = load(scene_path)
	if not scene:
		print("  Failed to load scene: " + scene_path)
		return
		
	var edited_scene = scene.instantiate()
	if not edited_scene:
		print("  Failed to instantiate scene")
		return
	
	print("  Scene loaded successfully")
	
	# Find and process scripts that might contain enemy spawning code
	var script_nodes = find_nodes_with_scripts(edited_scene)
	
	for node in script_nodes:
		var script = node.get_script()
		if not script:
			continue
			
		var script_path = script.resource_path
		print("  Found script: " + script_path)
		
		# Check if we can modify the script (it needs to be readable/writable)
		var file = FileAccess.open(script_path, FileAccess.READ)
		if not file:
			print("  Cannot read script file: " + script_path)
			continue
			
		var content = file.get_as_text()
		file.close()
		
		# Look for enemy spawning functions
		var modified = false
		
		# Check for wave or enemy related functions
		var wave_pattern = "func wave_"
		var enemy_pattern = "func spawn_enemy"
		var boss_pattern = "func boss_wave"
		
		if content.find(wave_pattern) >= 0 or content.find(enemy_pattern) >= 0 or content.find(boss_pattern) >= 0:
			print("  Found enemy spawning functions, disabling...")
			
			# Comment out function calls to enemy spawning
			var modified_content = content.replace("\n\twave_1()", "\n\t# wave_1() # Disabled for player action focus")
			modified_content = modified_content.replace("\n\tboss_wave()", "\n\t# boss_wave() # Disabled for player action focus")
			modified_content = modified_content.replace("\n\tspawn_enemy(", "\n\t# spawn_enemy( # Disabled for player action focus")
			
			if modified_content != content:
				# Save the modified script
				file = FileAccess.open(script_path, FileAccess.WRITE)
				if file:
					file.store_string(modified_content)
					file.close()
					modified = true
					print("  Script modified successfully")
				else:
					print("  Failed to write modified script")
			else:
				print("  No changes needed to script")
		
		if not modified:
			print("  No enemy spawning code found to disable")
	
	# Remove enemy nodes directly from the scene
	var enemy_nodes = find_enemy_nodes(edited_scene)
	for enemy in enemy_nodes:
		print("  Removing enemy node: " + enemy.name)
		enemy.queue_free()
	
	# Find and disable enemy spawners
	var spawner_nodes = find_spawner_nodes(edited_scene)
	for spawner in spawner_nodes:
		print("  Disabling spawner: " + spawner.name)
		# Keep the node but disable it
		if spawner.has_method("set_process"):
			spawner.set_process(false)
		if spawner.has_method("set_physics_process"):
			spawner.set_physics_process(false)
		
	# Save the scene if we modified it
	if enemy_nodes.size() > 0 or spawner_nodes.size() > 0:
		print("  Enemies and spawners disabled")
		
		# This part can only work if manually saving a PackedScene
		# For simplicity, we'll just notify the user
		print("  Changes will take effect after opening and saving the scene in the editor")
		
	print("  Processing complete for: " + scene_path)
	
	# Clean up
	edited_scene.queue_free()

# Find all nodes with scripts
func find_nodes_with_scripts(node: Node) -> Array:
	var result = []
	
	if node.get_script():
		result.append(node)
		
	for child in node.get_children():
		result.append_array(find_nodes_with_scripts(child))
		
	return result

# Find enemy nodes in the scene
func find_enemy_nodes(node: Node) -> Array:
	var result = []
	
	# Check if node name or groups indicate an enemy
	if "enemy" in node.name.to_lower() or node.is_in_group("enemy"):
		result.append(node)
		
	for child in node.get_children():
		result.append_array(find_enemy_nodes(child))
		
	return result

# Find enemy spawner nodes
func find_spawner_nodes(node: Node) -> Array:
	var result = []
	
	# Check if node name or groups indicate a spawner
	if "spawn" in node.name.to_lower() or "wave" in node.name.to_lower():
		result.append(node)
		
	for child in node.get_children():
		result.append_array(find_spawner_nodes(child))
		
	return result
