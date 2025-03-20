[Previous content remains the same until update_laser_pointers()]

func update_button_hover_states():
    # Clear previous hover states
    hovering_buttons.clear()
    
    # Check right controller
    if right_ray and right_ray.is_colliding():
        var collider = right_ray.get_collider()
        if collider and collider.is_in_group("button"):
            hovering_buttons[collider.name] = "right"
            print_verbose("Right hovering: " + collider.name)

    # Check left controller
    if left_ray and left_ray.is_colliding():
        var collider = left_ray.get_collider()
        if collider and collider.is_in_group("button"):
            hovering_buttons[collider.name] = "left"
            print_verbose("Left hovering: " + collider.name)

func update_button_animations(delta):
    var buttons_to_remove = []
    for button_name in active_buttons.keys():
        var button_info = active_buttons[button_name]
        button_info.timer += delta

        if button_info.timer <= button_press_duration:
            var t = button_info.timer / button_press_duration
            var button_mesh = buttons[button_name]
            var original_pos = button_original_positions[button_name]

            if button_info.pressing:
                var target_pos = original_pos - Vector3(0, button_press_distance, 0)
                button_mesh.position = original_pos.lerp(target_pos, t)
            else:
                var current_pos = button_mesh.position
                var target_pos = original_pos
                button_mesh.position = current_pos.lerp(target_pos, t)
        else:
            if not button_info.pressing:
                buttons_to_remove.append(button_name)
                buttons[button_name].position = button_original_positions[button_name]
            else:
                button_info.pressing = false
                button_info.timer = 0

    for button_name in buttons_to_remove:
        active_buttons.erase(button_name)

func press_button(button_name: String, controller: String):
    print("\nButton Press Handler:")
    print("Button: " + button_name + " | Controller: " + controller)
    
    if button_name in buttons:
        print("Valid button found")
        
        # Start button press animation
        active_buttons[button_name] = {
            "timer": 0.0,
            "pressing": true,
            "controller": controller
        }
        print("Started button animation")

        # Apply haptic feedback
        if controller == "right" and right_controller:
            print("Right controller haptic")
            right_controller.trigger_haptic_pulse("haptic", 0.8, 0.15, 0.7, 0.0)
        elif controller == "left" and left_controller:
            print("Left controller haptic")
            left_controller.trigger_haptic_pulse("haptic", 0.8, 0.15, 0.7, 0.0)

        # Handle button actions
        match button_name:
            "ShopButton":
                print("Shop button pressed - Opening shop")
                # TODO: Implement shop functionality
            "StartButton":
                print("Start button pressed - Starting voyage")
                _on_voyage_selected(current_campaign)
            "ExitButton":
                print("Exit button pressed - Forcing quit")
                OS.kill(OS.get_process_id())
            _:
                print("ERROR: Unknown button: " + button_name)
    else:
        print("ERROR: Invalid button name: " + button_name)

func setup_vr_environment() -> void:
    print("\n=== Setting up VR Environment ===")
    var xr_interface = XRServer.find_interface("OpenXR")
    if xr_interface:
        print("Found OpenXR interface, initializing...")
        xr_interface.initialize()
        get_viewport().use_xr = true
        _vr_setup_complete = true

        var origin = $XROrigin3D if has_node("XROrigin3D") else null
        if origin:
            print("Found XR Origin, setting position: " + str(vr_position))
            origin.position = vr_position
            if origin.has_node("XRCamera3D"):
                var camera = origin.get_node("XRCamera3D")
                print("Setting camera height: " + str(vr_camera_height))
                camera.position.y = vr_camera_height
                camera.look_at(vr_look_at)
            else:
                print("ERROR: XRCamera3D not found!")
        else:
            print("ERROR: XROrigin3D not found!")
    else:
        print("ERROR: OpenXR interface not found!")

func setup_interactive_buttons():
    print("\nSetting up interactive buttons...")
    # Look for buttons directly in the scene
    for child in get_children():
        if "Button" in child.name:
            print("Processing button: " + child.name)
            
            # Ensure the node is in the button group
            if not child.is_in_group("button"):
                print("Adding " + child.name + " to button group")
                child.add_to_group("button")
            else:
                print(child.name + " already in button group")
            
            # Get the button mesh
            var button_mesh = child.get_node("ButtonMesh")
            if button_mesh:
                print("Found button mesh for: " + child.name)
                buttons[child.name] = button_mesh
                button_original_positions[child.name] = button_mesh.position
            else:
                print("ERROR: No ButtonMesh found for " + child.name)

            # Verify collision shape
            var collision = child.get_node("CollisionShape3D")
            if collision:
                print("Found collision shape for " + child.name)
            else:
                print("ERROR: No CollisionShape3D found for " + child.name)

func _on_voyage_selected(voyage_num: int) -> void:
    if is_changing_scene:
        print("Scene already changing, ignoring selection")
        return

    print("\n=== Starting Voyage " + str(voyage_num) + " ===")
    is_changing_scene = true

    # Update current campaign
    current_campaign = voyage_num
    print("Setting campaign to: " + str(current_campaign))
    update_indicators()

    # Get voyage data
    var voyage = voyage_data[voyage_num]
    print("Loading voyage settings:")
    print("Name: " + voyage["name"])
    print("Difficulty: " + voyage["difficulty"])
    print("Enemy Spawn Rate: " + str(voyage["enemy_spawn_rate"]))
    print("Enemy Speed: " + str(voyage["enemy_speed"]))
    print("Enemy Health: " + str(voyage["enemy_health"]))

    # Configure game settings
    GameManager.set_voyage(voyage_num, voyage["difficulty"])
    GameManager.enemy_spawn_rate = voyage["enemy_spawn_rate"]
    GameManager.enemy_speed = voyage["enemy_speed"]
    GameManager.enemy_health = voyage["enemy_health"]

    print("Starting campaign...")
    GameManager.start_campaign()

func update_indicators() -> void:
    print("\n=== Updating Campaign Indicators ===")
    if difficulty_sprite and flag_sprite:
        # Calculate frame sizes
        var difficulty_texture = difficulty_sprite.texture
        var difficulty_frame_width = difficulty_texture.get_width() / 5
        var difficulty_frame_height = difficulty_texture.get_height()
        print("Difficulty frame size: " + str(difficulty_frame_width) + "x" + str(difficulty_frame_height))

        var flag_texture = flag_sprite.texture
        var flag_frame_width = flag_texture.get_width() / 5
        var flag_frame_height = flag_texture.get_height()
        print("Flag frame size: " + str(flag_frame_width) + "x" + str(flag_frame_height))

        # Update indicators
        difficulty_sprite.region_enabled = true
        difficulty_sprite.region_rect = Rect2(
            (current_campaign - 1) * difficulty_frame_width,
            0,
            difficulty_frame_width,
            difficulty_frame_height
        )
        print("Set difficulty region: " + str(difficulty_sprite.region_rect))

        flag_sprite.region_enabled = true
        flag_sprite.region_rect = Rect2(
            (current_campaign - 1) * flag_frame_width,
            0,
            flag_frame_width,
            flag_frame_height
        )
        print("Set flag region: " + str(flag_sprite.region_rect))
    else:
        print("ERROR: Missing sprite references!")
        if not difficulty_sprite:
            print("Difficulty sprite not found!")
        if not flag_sprite:
            print("Flag sprite not found!")

func set_campaign(campaign_num: int) -> void:
    if campaign_num < 1 or campaign_num > 5:
        print("ERROR: Invalid campaign number: " + str(campaign_num))
        return

    print("\n=== Switching to Campaign " + str(campaign_num) + " ===")
    current_campaign = campaign_num
    
    # Update visuals
    update_campaign_map()
    update_indicators()

func update_campaign_map() -> void:
    print("\n=== Updating Campaign Map ===")
    if current_campaign in campaign_sprites:
        var sprite_node = $MapDisplay/AnimatedSprite3D
        if sprite_node:
            var texture = campaign_sprites[current_campaign]
            print("Loading campaign " + str(current_campaign) + " texture")

            # Set up animation frames
            var frames = SpriteFrames.new()
            frames.remove_animation("default")
            frames.add_animation("default")
            frames.set_animation_loop("default", true)
            frames.set_animation_speed("default", 5.0)

            # Calculate frame dimensions
            var frame_width = texture.get_width() / 6  # 6 frames per animation
            var frame_height = texture.get_height()
            print("Frame size: " + str(frame_width) + "x" + str(frame_height))

            # Add frames to animation
            for i in range(6):
                var atlas = AtlasTexture.new()
                atlas.atlas = texture
                atlas.region = Rect2(i * frame_width, 0, frame_width, frame_height)
                frames.add_frame("default", atlas)
                print("Added frame " + str(i + 1))

            # Update and play animation
            sprite_node.sprite_frames = frames
            sprite_node.play()
            print("Started map animation")
        else:
            print("ERROR: AnimatedSprite3D not found in MapDisplay!")
    else:
        print("ERROR: Campaign " + str(current_campaign) + " sprite not found!")
