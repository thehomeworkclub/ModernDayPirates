extends Node3D

@export var left_hand_model: PackedScene = null
@export var right_hand_model: PackedScene = null

func _ready() -> void:
    # Get XR origin
    var xr_origin: Node3D = get_node_or_null("XROrigin3D") if has_node("XROrigin3D") else self

    if xr_origin:
        # Find the controllers
        var left_controller: Node3D = xr_origin.get_node_or_null("LeftController")
        var right_controller: Node3D = xr_origin.get_node_or_null("RightController")

        # Setup left hand
        if left_controller and left_hand_model:
            setup_hand(left_controller, left_hand_model, true)

        # Setup right hand
        if right_controller and right_hand_model:
            setup_hand(right_controller, right_hand_model, false)

func setup_hand(controller: Node3D, hand_model_scene: PackedScene, is_left: bool) -> void:
    # First, clear any existing hand models
    for child in controller.get_children():
        if child.name.begins_with("Hand"):
            child.queue_free()

    # Instantiate the hand model
    var hand_instance: Node3D = hand_model_scene.instantiate()
    hand_instance.name = "Hand" + ("Left" if is_left else "Right")
    controller.add_child(hand_instance)

    # Add and configure the VRHands script
    var hand_script: GDScript = load("res://VRHands.gd")
    if hand_script:
        if not hand_instance.has_node("VRHands"):
            var hand_controller: Node3D = Node3D.new()
            hand_controller.name = "VRHands"
            hand_controller.set_script(hand_script)
            hand_instance.add_child(hand_controller)

            # Configure hand properties
            hand_controller.hand_type = 0 if is_left else 1  # 0 = LEFT, 1 = RIGHT

            # Adjust offset based on your hand model
            if is_left:
                hand_controller.position_offset = Vector3(0.03, -0.03, -0.15)
                hand_controller.rotation_offset = Vector3(-60.0, -90.0, 0.0)  # Pitch forward, rotate inward
            else:
                hand_controller.position_offset = Vector3(-0.03, -0.03, -0.15)
                hand_controller.rotation_offset = Vector3(-60.0, 90.0, 0.0)   # Pitch forward, rotate inward

            print("Hand setup complete for " + ("left" if is_left else "right") + " controller")
