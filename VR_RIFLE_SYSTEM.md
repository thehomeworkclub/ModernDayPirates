# VR Rifle System Implementation

This document describes the implementation of the rifle system for Modern Day Pirates VR game.

## Overview

The rifle system extends the existing VR gun framework with realistic rifle-specific behaviors including:
- Magazine-based ammo system with physical reloading
- Rifle-specific properties (fire rate, damage, accuracy, recoil)
- Automatic/semi-automatic firing modes
- Model-specific visual representation using imported 3D models

## Architecture

The system follows this inheritance pattern:

```
Gun.gd (Base Gun Class)
└── BaseRifleGun.gd (Common Rifle Functionality)
    ├── M16A1Gun.gd (M16A1 Specific Implementation)
    ├── AK74Gun.gd (AK-74 Specific Implementation)
    └── [Additional Rifle Implementations]
```

## Implemented Rifles

### M16A1 (Standard Starting Rifle)
- **Properties**:
  - Fire Rate: 0.15 seconds
  - Damage: 2 per shot
  - Magazine Size: 30 rounds
  - Reload Time: 0.5 seconds
  - Accuracy: 0.9 (90%)
  - Recoil: 0.2
  - Firing Mode: Automatic
- **Visual Components**:
  - M16A1.fbx model
  - STANAG 5.56mm magazine attached to proper position
  - Proper alignment of magazine in magazine well

### AK-74
- **Properties**:
  - Fire Rate: 0.1 seconds (faster than M16A1)
  - Damage: 3 per shot (higher damage)
  - Magazine Size: 30 rounds
  - Reload Time: 0.5 seconds
  - Accuracy: 0.85 (85%, less accurate)
  - Recoil: 0.25 (more recoil)
  - Firing Mode: Automatic
- **Visual Components**:
  - AK-74.fbx model
  - 5.45mm AK magazine attached to proper position
  - Proper alignment of magazine in magazine well

## Planned Rifle Implementations
- SCAR-L (Tactical rifle with balanced stats)
- HK416 (High-precision rifle with better accuracy)
- MP5 (Submachine gun with faster fire rate but lower damage)
- Mosin Nagant (Bolt-action rifle with high damage but slow fire rate)

## How To Add a New Rifle

1. **Create a New Script**:
   - Create a new script that extends BaseRifleGun.gd
   - Set rifle-specific properties in the _ready() function
   - Example:
   ```gdscript
   extends "res://BaseRifleGun.gd"
   
   func _ready() -> void:
       gun_type = "new_rifle_type"
       fire_rate = 0.2
       bullet_damage = 2
       magazine_size = 25
       reload_time = 0.5
       accuracy = 0.95
       recoil = 0.15
       automatic = true
       
       super._ready()
   ```

2. **Create the Scene**:
   - Create a new scene that uses your script
   - Add the rifle model as a child of a Model node
   - Set appropriate scale and orientation
   - Add a Muzzle node for bullet spawning
   - Example scene structure:
   ```
   NewRifle (Node3D with NewRifleGun.gd script)
   ├── Model (Node3D, scaled appropriately)
   │   └── RifleModel (MeshInstance3D or imported scene)
   └── Muzzle (Node3D, positioned at barrel end)
   ```

3. **Add to VRGunController**:
   - Add your new rifle to the available_guns dictionary in VRGunController.gd
   - Example:
   ```gdscript
   var available_guns = {
       "m16a1": preload("res://M16A1Gun.tscn"),
       "ak74": preload("res://AK74Gun.tscn"),
       "new_rifle": preload("res://NewRifleGun.tscn")
   }
   ```

## Integration with VR

The rifle system integrates with the VR system through:
- Right controller trigger for firing
- Primary button (usually X on Oculus) for switching weapons
- Haptic feedback when shooting and switching weapons
- Automatic hiding of menu laser pointers when using rifles

## Physical Reloading System

The rifles implement a physical reloading system designed for use with a VR gunstock:

### Magazine States
The magazine can be in one of three states:
1. **ATTACHED_TO_GUN**: Magazine is attached to the rifle
2. **ATTACHED_TO_HAND**: Magazine is removed and held by left controller
3. **BEING_INSERTED**: Magazine is being inserted back into the rifle

### Reloading Process
1. **Detaching the Magazine**:
   - When the left controller moves away from the "line" of the right controller
   - This simulates moving the left hand away from the stock to grab a new magazine
   - The magazine visually detaches from the gun and attaches to the left controller
   - Haptic feedback provides tactile confirmation

2. **Attaching the Magazine**:
   - When the left controller (with magazine) is brought close to the magazine well position
   - The magazine will visually reattach to the gun
   - Haptic feedback on both controllers confirms the insertion
   - Reload timer starts to simulate locking the magazine in place

3. **Empty Magazine Handling**:
   - When the gun runs out of ammo, the magazine automatically detaches
   - User must perform the physical reloading motion to insert a new magazine
   - No automatic reloading - physical action is required

### Detection Algorithm
- Uses vector mathematics to detect when left controller moves off the right controller's "firing line"
- Calculates perpendicular distance between controllers to detect removal
- Uses proximity detection to determine when magazine is being reinserted
- Provides appropriate haptic feedback for each stage of the process

## Balancing Tips

When creating new rifles, consider these balancing principles:
- Higher damage → Lower fire rate
- Higher accuracy → Lower damage
- Faster reload → Smaller magazine
- Higher recoil → Higher damage

## Technical Details

### Input Handling
- Rifles use the right controller trigger for firing
- Semi-automatic rifles fire on each trigger press
- Automatic rifles fire while trigger is held
- Primary button cycles through available rifles

### Shooting Implementation
- Bullet instances are created at the Muzzle position
- Direction is determined by the controller orientation
- Accuracy affects random spread applied to bullets
- Recoil is implemented as both visual animation and haptic feedback

### Single Bullet System
- Each rifle fires exactly one bullet per trigger pull:
  - Custom firing implementation that overrides the base Gun.gd behavior
  - Prevents multiple bullets being fired (unlike the base gun system)
  - Minimal spread application tailored specifically for rifles
  - Accurate simulation of single-shot and automatic rifle fire

### Recoil Animation System
- Each gun has a custom recoil animation:
  - **Visual Recoil**: Gun model moves back and tilts upward
  - **Animation Parameters**: 
    - M16A1: Moderate recoil with 0.1 rad rotation
    - AK-74: Stronger recoil with 0.15 rad rotation
  - **Duration**: 0.2 seconds (fast recovery)
  - **Easing**: Initial quick movement followed by smooth return

### Haptic Feedback
- Both controllers receive haptic feedback when firing
- Feedback properties scale with the gun's recoil value:
  - **Right Controller**: Strong primary feedback
  - **Left Controller**: Weaker supporting feedback
  - **Intensity**: 0.5-1.0 based on recoil property
  - **Duration**: 0.1-0.3 seconds based on recoil property

### Performance Considerations
- Gun models use LOD (Level of Detail) for better VR performance
- Controller position smoothing improves stability for aiming
- When aiming is critical for gameplay, lower the smoothing_speed value

### Bullet System
- Each gun fires properly shaped bullets matching their ammunition type:
  - **M16A1**: 5.56mm sized bullets with moderate damage
  - **AK-74**: 5.45mm sized bullets with higher damage
- Bullets feature:
  - Realistic bullet shape with pointed head and cylindrical body
  - Proper orientation along flight path (pointing in direction of travel)
  - Visual trails for better visibility
  - Proper collision detection
  - Slight bullet drop for realism
  - Progressive deceleration over distance

### Muzzle Flash System
- Extremely subtle, realistic muzzle flash effects:
  - Tiny orange-red particle-based fire emission (radius of 0.002)
  - Minimal light glow effect (1/10 of original size)
  - Almost imperceptible omni light for environment illumination
  - Very short duration (0.08 seconds)
  - Deep orange-red color scheme for realistic rifle fire
  - Reduced particle count (8 particles vs. original 20)
  - Automatically created/destroyed with each shot

### Magazine Positioning
The magazine positioning for rifles has been carefully adjusted to fit in the magazine wells:

#### M16A1 Magazine
```
[node name="Magazine" type="Node3D" parent="Model"]
transform = Transform3D(-15, 0, -2.26494e-06, 0, 15, 0, 2.26494e-06, 0, -15, 0, -1.2, 0)
```

#### AK-74 Magazine
```
[node name="Magazine" type="Node3D" parent="Model"]
transform = Transform3D(15, 0, 0, 0, 15, 0, 0, 0, 15, 0, -1.5, 0)
```

### Known Limitations
- Shell ejection animations not yet implemented
- Magazine removal/insertion animations are basic and could be enhanced
- Bolt manipulation for chamber checking not implemented
