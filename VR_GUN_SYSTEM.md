# VR Gun System Implementation Guide

This document outlines how to implement and use the VR gun system in Modern Day Pirates.

## Overview

The VR gun system replaces the menu-focused laser pointers with more game-appropriate gun models in level scenes. This system:

- Uses the right controller direction for aiming (compatible with gun stocks)
- Automatically hides menu-focused visual elements in level scenes
- Provides a smoother, stabilized aiming experience for VR
- Maintains the same underlying input mechanisms

## Components Created

1. **VRGunController.gd** - Script that manages gun positioning, aiming, and firing
2. **VRGunModel.tscn** - A placeholder gun model with proper scaling and node setup
3. **level_template.tscn** - A template scene with VR gun system properly set up

## Implementation in Level Scenes

### Option 1: Using level_template.tscn (Recommended for New Levels)

1. Create a new scene by duplicating `level_template.tscn`
2. Rename the scene to your level name (e.g., `level2.tscn`)
3. Customize the scene with your specific level elements
4. Save the scene

### Option 2: Updating Existing Levels

To update existing level scenes to use the VR gun system:

1. Add the VRGunController.gd script to your XROrigin3D node:
```gdscript
[node name="VRGunController" type="Node3D" parent="XROrigin3D"]
script = ExtResource("path_to_VRGunController_script")
gun_scene = ExtResource("path_to_VRGunModel_or_Gun_scene")
bullet_scene = ExtResource("path_to_bullet_scene") # Optional
```

2. If your level has a script, ensure it includes:
   - VR initialization (`xr_interface.initialize()` and `get_viewport().use_xr = true`)
   - Performance optimizations for VR

## How the System Works

1. The VRGunController script initializes at runtime and:
   - Creates a gun instance based on the configured gun_scene
   - Hides the laser pointers and controller models
   - Sets up shooting mechanics

2. During gameplay:
   - The gun position follows the right controller with smoothing
   - Aiming direction is based on where the right controller is pointing
   - Trigger input (>0.8) fires the gun
   - Haptic feedback is provided when shooting

3. For gun stocks:
   - The system is designed with gun stock usage in mind
   - Smoothing parameters can be adjusted in the VRGunController script:
     - `smoothing_speed`: Higher = faster response to controller movement
     - `controller_smoothing`: Lower = more stable aiming

## Tips for Level Design with VR Guns

1. **Player Positioning**: 
   - Set the XROrigin3D position appropriately in the scene editor
   - Current level1 position: Vector3(2.45716, 16.3239, 53.035)

2. **Enemy Placement**:
   - Position enemies where they can be naturally targeted
   - Consider the player's height and field of view in VR

3. **Performance**:
   - The VR gun system includes performance optimizations
   - Additional level-specific optimizations may be needed

## Future Improvements

- Replace the placeholder gun model with final art assets
- Implement different gun types with unique visuals and behaviors
- Add visual effects for muzzle flash and impact
- Enhance haptic feedback
