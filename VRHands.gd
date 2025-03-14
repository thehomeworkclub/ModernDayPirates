extends Node3D

enum HandType { LEFT, RIGHT }

@export var hand_type: HandType = HandType.RIGHT
@export var position_offset: Vector3 = Vector3(0.0, -0.03, -0.15)
@export var rotation_offset: Vector3 = Vector3(-60.0, 0.0, 0.0)
@export var hide_on_grip: bool = false
@export var point_on_trigger: bool = true

var controller: XRController3D = null
var animation_player: AnimationPlayer = null
var is_gripping: bool = false
var trigger_value: float = 0.0

func _ready() -> void:
    if get_parent() is XRController3D:
        controller = get_parent()

        if controller:
            var controller_name: String = controller.name.to_lower()
            if "left" in controller_name:
                hand_type = HandType.LEFT
            elif "right" in controller_name:
                hand_type = HandType.RIGHT

            controller.button_pressed.connect(_on_button_pressed)
            controller.button_released.connect(_on_button_released)
            controller.input_float_changed.connect(_on_input_float_changed)

            animation_player = find_child("AnimationPlayer", true)
            apply_offsets()
            print("VR Hand initialized for " + ("LEFT" if hand_type == HandType.LEFT else "RIGHT") + " hand")

func _process(_delta: float) -> void:
    apply_offsets()
    if animation_player and point_on_trigger:
        update_hand_pose()

func apply_offsets() -> void:
    global_position = get_parent().global_position

    var local_offset: Vector3 = position_offset
    if hand_type == HandType.LEFT:
        local_offset.x = -local_offset.x

    position = local_offset

    var rotational_offset: Vector3 = Vector3(
        deg_to_rad(rotation_offset.x),
        deg_to_rad(rotation_offset.y),
        deg_to_rad(rotation_offset.z)
    )

    if hand_type == HandType.LEFT:
        rotational_offset.y = -rotational_offset.y
        rotational_offset.z = -rotational_offset.z

    var parent_basis: Basis = get_parent().global_transform.basis
    var pitch_rot: Basis = Basis(Vector3(1, 0, 0), rotational_offset.x)
    var yaw_rot: Basis = Basis(Vector3(0, 1, 0), rotational_offset.y)
    var roll_rot: Basis = Basis(Vector3(0, 0, 1), rotational_offset.z)

    var rotation_matrix: Basis = pitch_rot * yaw_rot * roll_rot
    global_transform.basis = parent_basis * rotation_matrix

func update_hand_pose() -> void:
    if not animation_player:
        return

    if hide_on_grip and is_gripping:
        visible = false
        return
    else:
        visible = true
        if point_on_trigger and trigger_value > 0.0:
            if animation_player.has_animation("point"):
                animation_player.set_blend_time("idle", "point", 0.1)
                animation_player.play("point")
                animation_player.seek(trigger_value, true)
            elif animation_player.has_animation("idle"):
                animation_player.play("idle")

func _on_button_pressed(button_name: String) -> void:
    match button_name:
        "grip_click":
            is_gripping = true
            if animation_player and animation_player.has_animation("grip"):
                animation_player.play("grip")
        "trigger_click":
            pass

func _on_button_released(button_name: String) -> void:
    match button_name:
        "grip_click":
            is_gripping = false
            if animation_player and animation_player.has_animation("idle"):
                animation_player.play("idle")
        "trigger_click":
            pass

func _on_input_float_changed(input_name: String, value: float) -> void:
    match input_name:
        "trigger":
            trigger_value = value
        "grip":
            pass
