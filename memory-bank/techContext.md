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

### UI Elements
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

### Material System
```gdscript
StandardMaterial3D
├── flags_transparent
├── albedo_color
├── emission_enabled
├── emission
└── emission_energy
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
├── target_position
├── collision_mask
└── collision detection
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

## Animation Systems
1. Button Animation
- Position-based tweening
- State-based transitions
- Duration control

2. Sprite Animation
- Frame-based animation
- Atlas textures
- Loop control

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

## Future Integration Points
1. Shop System
- Menu integration
- Resource management
- State persistence

2. Gameplay Systems
- Scene transitions
- State management
- Resource handling

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
