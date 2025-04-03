# Technical Context & Architecture

## VR Framework
- OpenXR implementation via Godot 4.x
- XRServer for interface management
- XROrigin3D for spatial reference
- XRController3D for input handling

## Core Systems

### VR Interaction
```
XROrigin3D
├── XRCamera3D
├── XRController3DLeft
│   ├── RayCastLeft
│   ├── LaserBeamLeft
│   └── LaserDotLeft
└── XRController3DRight
    ├── RayCastRight
    ├── LaserBeamRight
    └── LaserDotRight
```

### VR Rifle System Architecture
```
Gun.gd (Base Gun Class)
└── BaseRifleGun.gd (Common Rifle Functionality)
    ├── M16A1Gun.gd (M16A1 Implementation)
    ├── AK74Gun.gd (AK-74 Implementation)
    └── [Additional Rifle Implementations]
```

### Physical Reloading System
```gdscript
# Key Components in BaseRifleGun.gd
enum MagazineState { ATTACHED_TO_GUN, DETACHED }
var magazine_state = MagazineState.ATTACHED_TO_GUN
var magazine_node: Node3D = null
var magazine_original_transform: Transform3D
var hand_magazine_position = Vector3(0, 0, 0.05)
var magazine_detection_distance: float = 0.2
var debug_distance: float = 0.0
var detachment_cooldown: float = 0.0
```

### Physics-Based Detection
```gdscript
# Vector projection for perpendicular distance calculation
var right_forward = -right_controller.global_transform.basis.z.normalized()
var right_to_left = left_controller.global_position - right_controller.global_position
var parallel_component = right_to_left.dot(right_forward) * right_forward
var perpendicular_component = right_to_left - parallel_component
var perp_distance = perpendicular_component.length()
```

### Magazine Switching Logic
```gdscript
# Visual toggling approach
func hide_gun_magazine(hide: bool) -> void:
    if magazine_node:
        for child in magazine_node.get_children():
            child.visible = !hide

# Duplicate model creation
func create_hand_magazine_model(parent: Node3D) -> void:
    if magazine_node.get_child_count() > 0:
        var magazine_model = magazine_node.get_child(0).duplicate()
        parent.add_child(magazine_model)
```

## Scene Management
- Scene tree organization for VR
- Node hierarchies for interaction
- Signal connections for events

## Input Processing
1. Controller Input
```gdscript
button_pressed.connect(_on_controller_button_pressed)
```

2. Ray Casting
```gdscript
RayCast3D
├── target_position (0, 0, -10)
├── collision_mask
└── collision detection
```

## Animation Systems
1. Recoil Animation
```gdscript
var animation_player = $AnimationPlayer
animation_player.stop()
animation_player.play("recoil")
```

2. Animation Definitions
```
"recoil" animation parameters:
- Position keyframes:
  - 0.0s: Vector3(0, 0, -0.2)
  - 0.05s: Vector3(0, 0, -0.15)
  - 0.2s: Vector3(0, 0, -0.2)
- Rotation keyframes:
  - 0.0s: Vector3(0, 0, 0)
  - 0.05s: Vector3(-0.1 to -0.15, 0, 0)
  - 0.2s: Vector3(0, 0, 0)
- Transitions: 0.5, 2.0, 1.0
```

## Haptic Feedback System
```gdscript
# Apply to right controller (stronger feedback)
if right_controller:
    right_controller.trigger_haptic_pulse("haptic", intensity, duration, 1.0, 0.0)

# Apply to left controller (weaker supporting feedback)
if left_controller:
    left_controller.trigger_haptic_pulse("haptic", intensity * 0.6, duration * 0.8, 0.8, 0.0)
```

## Single Bullet System
```gdscript
# Override the shoot method completely
func shoot() -> void:
    # Decrease ammo
    current_ammo -= 1
    
    # Create minimal spread
    var spread = (1.0 - accuracy) * 0.05
    var random_spread = Vector3(
        randf_range(-spread, spread),
        randf_range(-spread, spread),
        0
    )
    
    # Create a single bullet instance
    var bullet = bullet_scene.instantiate()
    bullet.direction = direction + random_spread
    bullet.damage = bullet_damage
    
    # Position at muzzle
    bullet.global_position = muzzle.global_position
```

## Magazine Positioning
```gdscript
# M16A1 Magazine
Transform3D(-15, 0, -2.26494e-06, 0, 15, 0, 2.26494e-06, 0, -15, 0, -1.2, 0)

# AK-74 Magazine
Transform3D(15, 0, 0, 0, 15, 0, 0, 0, 15, 0, -1.5, 0)
```

## UI Elements
```
3DCampaignMenu
├── Buttons
│   ├── StartButton
│   ├── ShopButton
│   └── ExitButton
├── MapDisplay
│   └── AnimatedSprite3D
├── DifficultyRange
└── Flags
```

## Material System
```gdscript
StandardMaterial3D
├── flags_transparent
├── albedo_color
├── emission_enabled
├── emission
└── emission_energy
```

## Collision System
1. Layer Setup
```
Layer 1: Default (Buttons)
```

2. Shapes
```
CollisionShape3D
├── BoxShape3D
└── CylinderShape3D
```

## Resource Management
1. Texture Loading
```gdscript
load("res://path/to/texture.png")
```

2. Material Management
- Creation at initialization
- Reference storage
- Property updates

## Debug Infrastructure
1. Console Output
- Hierarchical formatting
- Status reporting
- Error tracking

2. Visual Debugging
- Color state indication
- Position validation
- Collision visualization

## Performance Considerations
1. Resource Loading
- Load on startup
- Cache references
- Proper cleanup

2. Collision Optimization
- Appropriate shapes
- Layer/mask setup
- Disabled when unused

## Integration Points
1. Rifle Integration
- Multiple rifle types through inheritance
- Common base functionality in BaseRifleGun.gd
- Weapon-specific parameters in child classes
- Magazine positioning customized per weapon

2. Gameplay Systems
- Character VR controls
- Enemy AI in VR
- Wave spawning
- Combat mechanics

3. Shop System
- Menu integration
- Resource management
- State persistence

## Technical Debt Management
1. Current Status
- Clean implementation
- Well-documented
- Modular design

2. Future Considerations
- Scale for additional features
- Performance optimization
- System expansion

## Testing Framework
1. Debug Modes
- Verbose logging
- Visual indicators
- State tracking

2. Error Handling
- Graceful degradation
- User feedback
- Recovery procedures
