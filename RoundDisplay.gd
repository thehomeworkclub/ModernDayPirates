extends Node3D

# Icon textures
var wave_icon_texture = null
var round_icon_texture = null

# Display nodes
var wave_icon: Sprite3D
var round_icon: Sprite3D
var wave_label: Label3D
var round_label: Label3D

# Display settings
var icon_spacing = 0.15  # Space between icons
var icon_scale = 0.56    # Size of each icon (reduced to 3/4 of previous size)
var label_offset_x = 0.02  # Minimal offset for text (flush with icon edge)
var label_offset_y = 0.02  # Minimal offset for text (flush with icon edge)

func _ready() -> void:
	# Load textures
	wave_icon_texture = load("res://art/waveicon.png")
	if wave_icon_texture == null:
		push_error("Failed to load waveicon.png")
		return
		
	round_icon_texture = load("res://art/roundicon.png")
	if round_icon_texture == null:
		push_error("Failed to load roundicon.png")
		return
	
	# Create icons and labels
	setup_display()
	
	# Update the display immediately
	update_display()

func _process(_delta: float) -> void:
	# Update the display
	update_display()

func setup_display() -> void:
	# MANUAL POSITIONING GUIDE:
	# To adjust positions, modify these values:
	# - transform.origin.x: Controls horizontal position (+ moves right)
	# - transform.origin.y: Controls vertical position (+ moves up)
	# - transform.origin.z: Controls depth position (+ moves horizontally after rotation)
	# - scale: Controls size of icons
	# - rotation: Controls orientation (in radians)
	
	# Create wave icon (first)
	wave_icon = Sprite3D.new()
	wave_icon.texture = wave_icon_texture
	wave_icon.pixel_size = 0.005
	wave_icon.scale = Vector3(icon_scale, icon_scale, icon_scale)
	wave_icon.transform.origin.x = -0.05  # Bring much closer to gun
	wave_icon.transform.origin.y = 0  # Same height
	wave_icon.transform.origin.z = 0  # First position
	wave_icon.shaded = false
	wave_icon.double_sided = true
	wave_icon.no_depth_test = false  # Enable depth testing for proper occlusion
	wave_icon.fixed_size = false
	add_child(wave_icon)
	
	# Create wave label - top-right corner of the icon
	wave_label = Label3D.new()
	wave_label.font_size = 8  # Smaller text
	wave_label.modulate = Color(1, 1, 1)  # White color
	wave_label.outline_modulate = Color(0, 0, 0)
	wave_label.outline_size = 1  # Smaller outline for sharper text
	wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	wave_label.transform.origin.x = -0.05 + label_offset_x  # Top-right corner
	wave_label.transform.origin.y = 0  # Top of icon
	wave_label.transform.origin.z = 0  # Same z position as wave icon
	wave_label.pixel_size = 0.003  # Smaller pixel size for sharper text
	wave_label.no_depth_test = false  # Enable depth testing for proper occlusion
	add_child(wave_label)
	
	# Create round icon (second)
	round_icon = Sprite3D.new()
	round_icon.texture = round_icon_texture
	round_icon.pixel_size = 0.005
	round_icon.scale = Vector3(icon_scale, icon_scale, icon_scale)
	round_icon.transform.origin.x = -0.05  # Bring much closer to gun
	round_icon.transform.origin.y = 0  # Same height
	round_icon.transform.origin.z = icon_spacing  # Positioned behind the wave icon
	round_icon.shaded = false
	round_icon.double_sided = true
	round_icon.no_depth_test = false  # Enable depth testing for proper occlusion
	round_icon.fixed_size = false
	add_child(round_icon)
	
	# Create round label - top-right corner of the icon
	round_label = Label3D.new()
	round_label.font_size = 8  # Smaller text
	round_label.modulate = Color(0, 0, 0)  # Black color
	round_label.outline_modulate = Color(1, 1, 1)
	round_label.outline_size = 1  # Smaller outline for sharper text
	round_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	round_label.transform.origin.x = 0 - label_offset_x  # Top-right corner
	round_label.transform.origin.y = 0  # Top of icon
	round_label.transform.origin.z = icon_spacing  # Same z position as round icon
	round_label.pixel_size = 0.003  # Smaller pixel size for sharper text
	round_label.no_depth_test = false  # Enable depth testing for proper occlusion
	add_child(round_label)
	
	# Make icons flat against the side of the gun (90 degrees rotation)
	# For VR right-hand controller, we rotate around Y-axis to make them flat against the side
	var rotation_angle = PI/2  # 90 degrees rotation
	round_icon.rotation.y = rotation_angle
	round_label.rotation.y = rotation_angle
	wave_icon.rotation.y = rotation_angle
	wave_label.rotation.y = rotation_angle
	
func update_display() -> void:
	if GameManager.has_method("get"):
		# Update round display
		round_label.text = str(GameManager.current_round)
		
		# Update wave display if available
		if GameManager.get("current_wave") != null and GameManager.get("game_parameters") != null:
			var total_waves = GameManager.game_parameters.waves_per_round
			var current_wave = GameManager.waves_completed_in_round + 1
			if current_wave > total_waves:
				current_wave = total_waves
			
			# Enhanced debug output
			print("ROUNDDISPLAY: Displaying wave " + str(current_wave) + "/" + str(total_waves) +
				", GameManager reports waves_completed_in_round: " + str(GameManager.waves_completed_in_round))
			
			wave_label.text = str(current_wave) + "/" + str(total_waves)
		else:
			wave_label.text = "1/5"
	else:
		round_label.text = "1"
		wave_label.text = "1/5"
