# Modern Day Pirates VR - Meta Quest 2 Setup

This project has been converted to work with Meta Quest 2. The right controller is set up to be used as the gun while the left controller handles movement.

## Important Setup Requirements

1. **Godot Engine 4.3 or newer** with Android export templates installed
2. **Android SDK** installed and properly configured in Godot
3. **Meta Quest Developer Hub (MQDH)** for deploying to the headset
4. **SteamVR** or **Oculus Desktop software** properly installed and running
5. **Meta Quest 2** in Developer Mode and connected to your PC

## Complete Setup Guide

### Initial Setup (REQUIRED!)

1. Install Godot Engine 4.3+ and Android export templates
2. Install Android SDK and configure in Godot (Editor > Editor Settings > Export > Android)
3. Enable Developer Mode on your Meta Quest 2 via the Meta Quest mobile app
4. Install SteamVR or Oculus Desktop software and ensure it's running
5. Connect your Quest 2 to your PC via a USB cable
6. Allow USB debugging on the headset when prompted

### OpenXR Configuration

1. In Godot, go to Project > Project Settings
2. Navigate to the XR tab
3. Make sure "OpenXR/Enabled" is set to "true"
4. Make sure "Shaders/Enabled" is set to "true"
5. Apply the settings

### Running the Project in VR

1. Connect your Meta Quest 2 to your PC via USB
2. Start SteamVR or Oculus Desktop software
3. Put on your headset and make sure it's connected to your PC
4. In Godot, press F5 to run the project
5. The game should automatically start in VR mode
6. If you receive a dialog in the headset about allowing the application, select "Allow"

### For PC Testing Only

If you don't have a VR headset connected but want to test the game:
1. The game will automatically fall back to desktop mode
2. You'll control the game using keyboard and mouse:
   - WASD to move
   - Mouse to aim
   - Left click to shoot

## VR Controls

### Right Controller (Gun & UI Interaction)
- **Trigger**: Shoot weapon or interact with UI when laser is pointing at a menu element
- **A Button**: Alternative UI interaction button
- **Laser Pointer**: Aim at UI elements to interact with menus
- **Hand Cursor**: Visual indicator when pointing at interactive UI elements

### Left Controller (Movement)
- **Thumbstick**: Move forward/backward and strafe left/right
- **B Button**: Additional functionality (can be customized)

### UI Interaction
All menus and UI elements (including the Campaign Menu) are now interactable in VR:
1. Point the right controller laser at a UI element
2. When the hand cursor appears, press the trigger to click
3. The UI will respond as if clicked with a mouse

#### Campaign Menu Interaction
The 3D Campaign Menu requires special handling in VR:
1. When you start the game in VR mode, you'll see the campaign map
2. Point your right controller at the map and press the trigger to start a voyage
3. The game will transition to the main gameplay scene, maintaining VR mode
4. If you experience issues with the transition, try pointing directly at the map's center when clicking

#### Troubleshooting Scene Transitions
If you encounter problems when transitioning from the campaign menu to gameplay:
1. Make sure your VR headset is properly connected
2. Try restarting the game and SteamVR/Oculus app
3. Point the laser directly at a clickable element on the map
4. As a last resort, simply pressing the trigger anywhere will start the first voyage

## Exporting for Quest 2

1. Connect your Quest 2 to your PC
2. In Godot, go to Project > Export
3. Select the "Meta Quest 2" preset
4. Click "Export Project"
5. Choose a location to save the APK file
6. Install the APK on your Quest using Meta Quest Developer Hub or SideQuest

## Troubleshooting

If VR mode isn't working:
1. Make sure SteamVR or Oculus Desktop app is running BEFORE starting the game
2. Ensure your Meta Quest 2 is properly connected to your PC via USB
3. Check that OpenXR is enabled in Project Settings
4. Verify that your PC meets the requirements for Oculus Link / Air Link
5. Try restarting the Godot editor and your VR software

## Technical Notes

- The game uses the OpenXR framework for VR compatibility
- The right controller becomes the gun automatically in VR mode
- VR mode is now the default when running the game with VR hardware connected
- Controller inputs are mapped through the openxr_action_map.tres resource

## Support

For issues or questions about the VR implementation, please file an issue on the project repository.