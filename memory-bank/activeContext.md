# Active Development Context

## Current Focus
New game levels have been pulled from GitHub, found in the temp-game/ directory. These levels need to be integrated into the main game, including:
- Level system with wave-based enemy spawning
- Player character with movement and combat mechanics
- Enemy types including melee, ranged, and boss enemies
- Global variable system for level configuration
=======>>>>>>> REPLACE

# Active Development Context

## Current Focus
The VR campaign menu system is now complete with all core functionality implemented and working as expected. The menu provides a solid foundation for the rest of the game's VR interaction systems.

Asset integration is underway, with cargo ship meshes and textures imported from the temp-game directory into a dedicated cargo_ships/ folder in the main project. Initial integration has surfaced an important consideration: VR camera position must be properly coordinated with ship positioning in scenes to avoid placing the player inside or below ships.

Important VR positioning:
- Campaign menu VR position: Vector3(10.954, -7.596, 4.236)
- Level1 XROrigin3D editor position: Vector3(2.45716, 16.3239, 53.035)

Key finding: Editor-defined XROrigin3D positions should be preserved rather than overridden in scripts. This ensures that carefully positioned camera elements remain where placed in the 3D editor.

## Performance Optimizations

VR performance issues were identified when integrating the cargo ship models. These have been addressed through:

1. Runtime optimizations:
   - Disabled expensive rendering features (SDFGI, SSIL)
   - Reduced shadow quality and draw distance
   - Implemented LOD (Level of Detail) support
   - Optimized mesh instance properties (GI mode, shadow casting)

2. Resource optimization tools:
   - Created performance_optimizer.gd for runtime scene optimization
   - Added optimize_resources.gd for editor-time asset optimization
   - Implemented automatic mesh instance optimization

3. Key performance settings:
   - Configurable optimization levels (LOW, MEDIUM, HIGH)
   - Target FPS: 90 (VR standard)
   - Physics tick rate: 60
   - Texture size limit: 1024px

## Recently Completed
1. VR Menu System
- Complete menu functionality
- Campaign selection interface
- Visual feedback systems

2. Core Systems
- VR environment initialization
- Controller setup
- Scene management
- Game state handling

3. New Additions (to be integrated)
- Level scenes (level1.tscn, stage2.tscn)
- Enemy system with multiple types:
  - Melee enemies
  - Ranged enemies
  - Boss enemies
  - Summoner enemies
- Player character system
- Wave-based spawning system
- Global variable configuration for levels

## Current Development Stage
Priority tasks for integrating the new game levels:
1. Adapt player character system for VR
2. Integrate enemy systems with VR interaction
3. Implement wave spawning system in VR environment
4. Connect level progression with campaign menu
5. Ensure shop system works with new gameplay mechanics

## Technical Foundation
- OpenXR integration is working properly
- VR interaction patterns are established
- Collision system is well-tested
- Debug systems are in place
- Scene transitions are handled

## Next Steps
1. Level Integration:
   - Convert standard character controls to VR
   - Adapt enemy AI for VR combat
   - Implement VR-compatible wave spawning
   - Set up level transitions

2. Gameplay Systems:
   - VR movement and combat mechanics
   - Enemy behavior in VR space
   - Wave management
   - Level progression

## Active Considerations
- Maintain consistent VR interaction patterns established in menu
- Keep performance optimization in mind for future scaling
- Continue using established debug logging patterns
- Follow same code organization structure

## Documentation Status
- Menu system fully documented
- Debug outputs implemented
- Code comments up to date
- Progress tracking current
