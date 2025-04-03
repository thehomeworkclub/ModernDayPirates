# System Patterns

## VR Rifle System

### Rifle Inheritance Pattern
```
Gun.gd (Base Gun Class)
└── BaseRifleGun.gd (Common Rifle Functionality)
    ├── M16A1Gun.gd (M16A1 Specific Implementation)
    ├── AK74Gun.gd (AK-74 Specific Implementation)
    └── [Additional Rifle Implementations]
```

### Magazine System
- Two-state management: ATTACHED_TO_GUN and DETACHED
- Visibility toggling for magazine models
- Duplicate models for hand-attached magazines
- Standard scale factor: 15 for all magazine models
- Positioning must be configured per gun model

### Physical Reloading
1. Detection Thresholds:
   - Detachment threshold: 0.3 meters perpendicular distance
   - Reattachment detection radius: 0.2 meters from magazine well
   - Detachment cooldown: 0.5 seconds

2. Controller Mathematics:
   - Vector projection for perpendicular distance calculation
   - Global position distance for magazine well proximity

3. Haptic Feedback:
   - Detach: 0.5 intensity, 0.1s duration on left controller
   - Reattach: 0.7 intensity, 0.2s duration on both controllers

### Recoil Animation
- Animation-based pattern with AnimationPlayer
- Consistent naming: "recoil" animation
- Parameters vary by weapon:
  - Position offset: Vector3(0, 0, 0.05) backward movement
  - Rotation: -0.1 to -0.15 radians (weapon dependent)
  - Duration: 0.2 seconds
  - Easing: 0.5 ease-out, 2.0 ease-in

### Bullet System
- Single bullet per shot
- Minimal spread based on accuracy
- Damage values set per gun
- Realistic caliber-matching bullets

## Level Architecture

### Wave Spawning Pattern
- Center-based spawn system using wave_center position
- Global variable configuration for enemy counts and types
- Separate spawn patterns per level
- Boss wave triggers after standard waves

### Enemy Hierarchy
- Base Enemy class for common functionality
- Specialized enemy types:
  - Melee: Close-range combat
  - Ranged: Distance attacks
  - Boss: Special mechanics
  - Summoner: Creates additional enemies

### Player Mechanics
- Health system with immunity frames
- Movement speed constant: 5.0
- Jump velocity: 4.5
- Collision-based damage system
- Group-based identification ("player")

## VR Interaction

### Controller Interaction
- Right controller: Primary weapon control
- Left controller: Magazine handling and support
- Trigger button for firing
- Perpendicular movement for magazine removal
- Proximity-based magazine insertion

### Ray Casting
- Length: 10.0 units
- Collision masks properly configured
- Visual feedback via laser effects

## Shop Interface Layout

### Currency Display
- Location: Top of shop interface at y=-1.45
- Viewport size: 1000x120 pixels
- Spacing between currencies: 100 pixels
- Left/Right margins: 40 pixels
- Currency numbers use size 64 font with outline size 16

### Item Box Labels
Level Numbers:
- Position relative to box: (x, y+0.03, z+0.06)
- Font size: 48
- Outline size: 8
- Pixel size: 0.002

Price Labels:
- Position relative to box: (x, y-0.03, z+0.06)
- Font size: 32
- Outline size: 8
- Pixel size: 0.0015

### Shop Background
- Transform: 11.312, -2.381, -9.427
- Scale: 12.346 for both x and y
- Pixel size: 0.001
