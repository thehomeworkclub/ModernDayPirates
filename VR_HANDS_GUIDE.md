# VR Hand Integration Guide

## Overview
This guide explains how to set up virtual hands for your VR controllers in your Godot 4 boat defense game.

## Step 1: Set Up Your VR Scene

Make sure your VR scene has the following structure:
```
XROrigin3D
├── LeftController (XRController3D)
├── RightController (XRController3D)
└── Camera3D
```

## Step 2: Add Hand Models

You have two options:

### Use the simple hand model provided
The VRHand.tscn can be used as a basic reference. It's a simple blocky hand model that can be used for testing or as a placeholder.

### Use existing skeletal hands
You already have a skeletal hand model (`l_hand_skeletal_lowres.fbx`). You'll need to create a scene using this model:

1. Right-click in the FileSystem panel
2. Select "New Scene"
3. Add a Node3D as the root
4. Add the FBX as a child (or add a MeshInstance3D and assign the mesh)
5. Add the HandModel.gd script to this root node
6. Set is_left_hand=true for the left hand scene, and create a mirrored version for the right hand

## Step 3: Implement in your Main VR Scene

1. Add the VRHandSetup.gd script to your main VR scene (the one containing XROrigin3D)
2. In the Inspector, assign your left and right hand model scenes to the appropriate properties:
   - Left Hand Model: Your left hand scene
   - Right Hand Model: Your right hand scene
3. Save the scene

## Step 4: Test and Adjust

1. Run your game in VR mode
2. Observe the hand positions and rotations
3. If the hands aren't positioned correctly, adjust the following properties in the VRHands nodes:
   - Position Offset: Changes the position relative to the controller
   - Rotation Offset: Changes the rotation in degrees (pitch, yaw, roll)

### Troubleshooting Hand Positioning

If your hands aren't positioned correctly:

1. Make small adjustments to the position_offset and rotation_offset values
2. For position_offset:
   - X: left/right (negative is toward thumb)
   - Y: up/down (negative is down)
   - Z: forward/back (negative is forward)
3. For rotation_offset:
   - X: pitch (rotation around X axis)
   - Y: yaw (rotation around Y axis)
   - Z: roll (rotation around Z axis)

## Step 5: Optimize for Your Specific Controllers

Different VR controllers may require different offset values. The defaults are set for Oculus Touch controllers. If you're using a different controller type, you might need to adjust these values:

For Valve Index controllers:
```gdscript
# Left Hand
position_offset = Vector3(0.01, -0.02, -0.08)
rotation_offset = Vector3(-5.0, 0.0, 0.0)

# Right Hand
position_offset = Vector3(-0.01, -0.02, -0.08)
rotation_offset = Vector3(-5.0, 0.0, 0.0)
```

For HTC Vive controllers:
```gdscript
# Left Hand
position_offset = Vector3(0.03, -0.04, -0.10)
rotation_offset = Vector3(-25.0, 0.0, 0.0)

# Right Hand
position_offset = Vector3(-0.03, -0.04, -0.10)
rotation_offset = Vector3(-25.0, 0.0, 0.0)
```

## Hand Animations

The hands support simple animations for pointing and gripping. To implement:

1. Add an AnimationPlayer to your hand model scenes
2. Create animations named "idle", "point", and "grip"
3. The VRHands.gd script will automatically trigger these animations based on controller input

## Using the Existing Skeletal Hand Model

Since your project already has `l_hand_skeletal_lowres.fbx`, you can create a scene that uses this model:

1. Create a new scene with a Node3D root
2. Import the hand model as a child
3. Attach the HandModel.gd script to the root
4. Set up an AnimationPlayer with the necessary animations
5. Duplicate the scene and configure for the right hand (mirror X scale)
