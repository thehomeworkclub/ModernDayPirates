# Cargo Ship Assets

This directory contains cargo ship meshes and textures imported from the temp-game/Cargo_Ships directory.

## Contents

### Meshes
- Covered Boat.fbx
- Crane.fbx
- DeckCrane.fbx
- DeckCrane1.fbx
- Dry_Cargo.fbx
- Dry_Cargo1.fbx
- Dry_Cargo2.fbx
- Dry_Cargo3.fbx
- Dry_Cargo4.fbx
- Dry_Cargo_Ship.fbx
- Dry_Cargo_Ship_1.fbx
- Dry_Cargo_Ship_2.fbx
- lifebuoy.fbx
- Uncovered Boat.fbx

### Textures
- Tex_256Gradient.png

## Usage in Godot

To use these meshes in your Godot project:

1. Import the FBX files using Godot's built-in importer
2. Create a new MeshInstance3D node in your scene
3. Assign the imported mesh to the MeshInstance3D
4. Apply materials and textures as needed

### Example Code

```gdscript
# Create a new MeshInstance3D node
var ship_instance = MeshInstance3D.new()
ship_instance.name = "CargoShip"

# Load the mesh
var ship_mesh = load("res://cargo_ships/meshes/Dry_Cargo_Ship.fbx")
ship_instance.mesh = ship_mesh

# Add to scene
add_child(ship_instance)
```

## Integration with VR

When using these ships in VR scenes, consider:
- Performance optimization for VR rendering
- Proper scaling relative to the player's VR position
- Collision shapes for VR interaction
- LOD (Level of Detail) for performance optimization

## Default Position

According to the .clinerules file, the standard VR position is:
```
Vector3(10.954, -7.596, 4.236)
```

Adjust ship positions relative to this VR position for proper scaling and visibility.
