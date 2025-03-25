# System Patterns & Guidelines

## VR Interaction Patterns

### Laser Pointer System
```gdscript
# Controller setup
right_ray.target_position = Vector3(0, 0, -ray_length)
right_ray.collision_mask = 1

# Visual feedback
var normal_ray_color = Color(0, 0.5, 1, 0.6)  # Blue
var hover_ray_color = Color(0, 1, 0, 0.6)     # Green
```

### Button Interactions
1. Physical Setup
- CollisionShape3D for hit detection
- ButtonMesh for visual representation
- Proper collision layers/masks

2. Visual Feedback
```gdscript
# Material handling
material.flags_transparent = true
material.emission_enabled = true
material.emission_energy = 2.0
```

3. Haptic Feedback
```gdscript
controller.trigger_haptic_pulse("haptic", 0.8, 0.15, 0.7, 0.0)
```

## Debug System
```gdscript
print("\n=== Component Initializing ===")
print("Status: " + status)
print("Details:")
print("  Property: " + str(value))
```

## Scene Organization
1. Core Nodes
- XROrigin3D
- XRController3D (Left/Right)
- Visual Elements
- Collision Elements

2. Button Structure
```
Button (StaticBody3D/Area3D)
├── ButtonMesh
├── CollisionShape3D
└── [Optional Effects]
```

## State Management
1. Scene States
```gdscript
var is_changing_scene = false
var _vr_setup_complete = false
```

2. Input Management
```gdscript
if is_changing_scene:
    return
```

## Error Handling
1. Node Validation
```gdscript
if node:
    print("Found node: " + node.name)
else:
    print("ERROR: Node not found!")
```

2. Resource Loading
```gdscript
var texture = load("res://path/to/resource.png")
if texture:
    # Use resource
else:
    print("ERROR: Resource not found!")
```

## Animation Patterns
1. Button Press
```gdscript
var target_pos = original_pos - Vector3(0, press_distance, 0)
mesh.position = original_pos.lerp(target_pos, t)
```

2. Sprite Animation
```gdscript
var frames = SpriteFrames.new()
frames.add_animation("default")
frames.set_animation_loop("default", true)
frames.set_animation_speed("default", 5.0)
```

## Performance Considerations
1. Material Reuse
- Create materials once at initialization
- Store references for reuse

2. Collision Optimization
- Use appropriate collision shapes
- Disable unused collisions
- Proper layer/mask setup

## Code Organization
1. Variable Groups
```gdscript
# Core tracking
var tracking_vars

# VR setup
var vr_vars

# Visual elements
var visual_vars
```

2. Function Order
- Initialization (_ready)
- Process (_process)
- Input handlers
- Core functionality
- Helper functions
- State updates

## Documentation Standards
1. File Header
```gdscript
# Primary scene script for [component]
# Handles [main responsibilities]
```

2. Function Documentation
```gdscript
# Updates [component] based on [conditions]
# Parameters: [description]
# Returns: [description]
func example_function():
```

## Testing Patterns
1. Debug Output
- Component initialization
- State changes
- Error conditions
- Performance metrics

2. Visual Debugging
- Color changes for state
- Position logging
- Collision visualization
