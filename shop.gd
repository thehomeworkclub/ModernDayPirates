extends Node3D

# Button state tracking
var buttons = {}
var button_original_positions = {}
var button_press_distance = 0.05
var button_press_duration = 0.15
var active_buttons = {}
var hovering_buttons = {}
var is_changing_scene = false

# Controller references
var right_controller: XRController3D = null
var left_controller: XRController3D = null
var right_ray: RayCast3D = null
var left_ray: RayCast3D = null
var right_laser_dot: MeshInstance3D = null
var left_laser_dot: MeshInstance3D = null
var ray_length = 10.0
var normal_ray_color = Color(0, 0.5, 1, 0.6)  # Blue
var hover_ray_color = Color(0, 1, 0, 0.6)     # Green

var _vr_setup_complete = false
var vr_position = Vector3(10.954, -7.596, 4.236)
var vr_look_at = Vector3(10.954, -7.596, 4.236)
var vr_camera_height = 1.8

func _ready() -> void:
    print("\n=== Shop Scene Initializing ===")
    
    if not _vr_setup_complete:
        setup_vr_environment()
        setup_controllers()
        setup_back_button()
    
    print("\n=== Setup Complete ===")
    print("VR Debug: XR Interface Active = " + str(XRServer.primary_interface != null))

func _process(delta: float) -> void:
    if not _vr_setup_complete:
        return
    
    update_laser_pointers()
    update_button_hover_states()
    update_button_animations(delta)

func setup_controllers() -> void:
    print("\n=== Setting up VR Controllers ===")
    right_controller = $XROrigin3D/XRController3DRight
    left_controller = $XROrigin3D/XRController3DLeft

    if right_controller:
        print("Found right controller: " + str(right_controller.name))
        right_controller.button_pressed.connect(_on_right_controller_button_pressed)
        print("Connected right controller button signal")

        right_ray = right_controller.get_node("RayCastRight")
        if right_ray:
            print("Found right raycast")
            right_ray.target_position = Vector3(0, 0, -ray_length)
            right_ray.collide_with_bodies = true
            right_ray.collide_with_areas = false

        right_laser_dot = right_controller.get_node("LaserDotRight")
        if right_laser_dot:
            print("Found right laser dot")

    if left_controller:
        print("Found left controller: " + str(left_controller.name))
        left_controller.button_pressed.connect(_on_left_controller_button_pressed)
        print("Connected left controller button signal")

        left_ray = left_controller.get_node("RayCastLeft")
        if left_ray:
            print("Found left raycast")
            left_ray.target_position = Vector3(0, 0, -ray_length)
            left_ray.collide_with_bodies = true
            left_ray.collide_with_areas = false

        left_laser_dot = left_controller.get_node("LaserDotLeft")
        if left_laser_dot:
            print("Found left laser dot")

func setup_back_button() -> void:
    print("\n=== Setting up Back Button ===")
    var back_button = StaticBody3D.new()
    back_button.name = "BackButton"
    back_button.add_to_group("button")
    back_button.collision_layer = 1
    back_button.collision_mask = 1
    add_child(back_button)
    
    # Position the button in front of the player
    back_button.position = Vector3(11.0, -7.0, 2.0)
    
    # Create visual mesh
    var mesh = MeshInstance3D.new()
    var box = BoxMesh.new()
    box.size = Vector3(0.3, 0.15, 0.05)
    mesh.mesh = box
    mesh.name = "ButtonMesh"
    
    # Apply material
    var material = StandardMaterial3D.new()
    material.albedo_color = Color(0.2, 0.2, 0.8) # Blue color
    material.roughness = 0.4
    mesh.material_override = material
    back_button.add_child(mesh)
    
    # Create collision shape
    var collision = CollisionShape3D.new()
    var shape = BoxShape3D.new()
    shape.size = Vector3(0.3, 0.15, 0.05)
    collision.shape = shape
    back_button.add_child(collision)
    
    # Store button reference
    buttons["BackButton"] = mesh
    button_original_positions["BackButton"] = mesh.position
    print("Back button setup complete")

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

func _on_right_controller_button_pressed(button_name: String) -> void:
    print("\nRight Controller Button Event: " + button_name)
    if is_changing_scene:
        return

    if button_name == "trigger_click":
        if right_ray and right_ray.is_colliding():
            var collider = right_ray.get_collider()
            if collider and collider.is_in_group("button"):
                press_button(collider.name, "right")

func _on_left_controller_button_pressed(button_name: String) -> void:
    print("\nLeft Controller Button Event: " + button_name)
    if is_changing_scene:
        return

    if button_name == "trigger_click":
        if left_ray and left_ray.is_colliding():
            var collider = left_ray.get_collider()
            if collider and collider.is_in_group("button"):
                press_button(collider.name, "left")

func press_button(button_name: String, controller: String) -> void:
    print("\nButton Press Handler:")
    print("Button: " + button_name + " | Controller: " + controller)

    if button_name in buttons:
        print("Valid button found: " + button_name)
        
        # Start button press animation
        active_buttons[button_name] = {
            "timer": 0.0,
            "pressing": true,
            "controller": controller
        }
        
        # Apply haptic feedback
        if controller == "right" and right_controller:
            right_controller.trigger_haptic_pulse("haptic", 0.8, 0.15, 0.7, 0.0)
        elif controller == "left" and left_controller:
            left_controller.trigger_haptic_pulse("haptic", 0.8, 0.15, 0.7, 0.0)
        
        # Handle specific button actions
        if button_name == "BackButton":
            print("Back button pressed - Returning to menu")
            is_changing_scene = true
            get_tree().change_scene_to_file("res://3dcampaignmenu.tscn")

func update_laser_pointers() -> void:
    # Update right controller laser
    if right_ray and right_laser_dot:
        if right_ray.is_colliding():
            var collision_point = right_ray.get_collision_point()
            right_laser_dot.global_position = collision_point
            right_laser_dot.visible = true
            
            var collider = right_ray.get_collider()
            if collider and collider.is_in_group("button"):
                print_debug("Right ray hit button: " + collider.name)
        else:
            right_laser_dot.visible = false

    # Update left controller laser
    if left_ray and left_laser_dot:
        if left_ray.is_colliding():
            var collision_point = left_ray.get_collision_point()
            left_laser_dot.global_position = collision_point
            left_laser_dot.visible = true
            
            var collider = left_ray.get_collider()
            if collider and collider.is_in_group("button"):
                print_debug("Left ray hit button: " + collider.name)
        else:
            left_laser_dot.visible = false

func update_button_hover_states() -> void:
    # Clear previous hover states
    hovering_buttons.clear()

    # Check right controller
    if right_ray and right_ray.is_colliding():
        var collider = right_ray.get_collider()
        if collider and collider.is_in_group("button"):
            hovering_buttons[collider.name] = "right"

    # Check left controller
    if left_ray and left_ray.is_colliding():
        var collider = left_ray.get_collider()
        if collider and collider.is_in_group("button"):
            hovering_buttons[collider.name] = "left"

func update_button_animations(delta: float) -> void:
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
