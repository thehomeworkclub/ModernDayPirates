# VR Rifle System Implementation

This document describes the implementation of the rifle system for Modern Day Pirates VR game.

## Overview

The rifle system extends the existing VR gun framework with realistic rifle-specific behaviors including:
- Magazine-based ammo system with reloading
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
  - Reload Time: 2.5 seconds
  - Accuracy: 0.9 (90%)
  - Recoil: 0.2
  - Firing Mode: Automatic
- **Visual**: Uses M16A1.fbx model from VRFPS_Kit

### AK-74
- **Properties**:
  - Fire Rate: 0.1 seconds (faster than M16A1)
  - Damage: 3 per shot (higher damage)
  - Magazine Size: 30 rounds
  - Reload Time: 3.0 seconds (longer reload)
  - Accuracy: 0.85 (85%, less accurate)
  - Recoil: 0.25 (more recoil)
  - Firing Mode: Automatic
- **Visual**: Uses AK-74.fbx model from VRFPS_Kit

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
       reload_time = 2.0
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
- Recoil will be implemented as visual feedback and aim adjustment

### Performance Considerations
- Gun models use LOD (Level of Detail) for better VR performance
- Controller position smoothing improves stability for aiming
- When aiming is critical for gameplay, lower the smoothing_speed value

### Known Limitations
- Current implementation uses simplified collision for bullets
- Visual recoil and muzzle flash effects are not yet implemented
- Reload animations will be added in future updates
