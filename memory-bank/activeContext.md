# Active Development Context

## Current Focus
We have successfully implemented a VR rifle system with physical reloading mechanics optimized for use with a gunstock. The system allows for realistic magazine removal and insertion using physical hand movements. Currently, two rifle models (M16A1 and AK-74) are implemented with proper magazines, muzzle flashes, and recoil animations.

Next goal: Expand the rifle system to include 5 additional rifle types using the same physical reloading framework.

Key implementation details:
- Base rifle functionality in BaseRifleGun.gd for inheritance
- Physical reloading using controller position tracking
- Properly scaled magazines with scale factor 15
- Generous detection margins for easier VR interaction:
  - Detachment threshold: 0.3 meters perpendicular distance
  - Reattachment detection radius: 0.2 meters from magazine well
- Simplified two-state system (ATTACHED_TO_GUN and DETACHED)
- Visual toggling of magazines with duplicated models for hand attachment

## VR Positioning Reference
- Campaign menu VR position: Vector3(10.954, -7.596, 4.236)
- Level1 XROrigin3D editor position: Vector3(2.45716, 16.3239, 85.035)
- Camera height: 1.8
- Ray length: 10.0
- Button press distance: 0.03

## Performance Optimizations
VR performance considerations remain important, especially as we add more weapon models:

1. Runtime optimizations:
   - Disabled expensive rendering features (SDFGI, SSIL)
   - Reduced shadow quality and draw distance
   - Implemented LOD (Level of Detail) support
   - Optimized mesh instance properties

2. Resource optimization tools:
   - performance_optimizer.gd for runtime scene optimization
   - optimize_resources.gd for editor-time asset optimization

3. Key performance settings:
   - Target FPS: 90 (VR standard)
   - Physics tick rate: 60
   - Texture size limit: 1024px

## Recently Completed
1. VR Rifle System
   - Physical reloading with magazine detachment/reattachment
   - Realistic weapon models and magazines
   - Single bullet firing system that overrides base gun system
   - Subtle muzzle flash effects
   - Haptic feedback on both controllers
   - Recoil animations
   - Support for automatic and semi-automatic firing modes

2. Core System Integration
   - XR controller integration for interaction
   - Ray casting for precise VR interaction
   - Animation system for visual feedback
   - Haptic feedback for tactile confirmation

## Next Steps
1. Rifle System Expansion:
   - Add 5 more rifle types using the same framework
   - Ensure proper magazine model positioning for each gun
   - Balance weapon attributes (damage, fire rate, recoil, etc.)
   - Create bullet models for each caliber
   - Implement unique recoil patterns

2. Gameplay Integration:
   - Connect rifle system with enemy damage system
   - Implement ammo pickup/management
   - Balance gameplay around different weapon types
   - Add haptic feedback variation for different weapons

## Active Considerations
- Maintain consistent interaction patterns across all rifle types
- Keep performance optimization in mind - monitor frame rate with multiple weapons
- Ensure magazine models are properly positioned for each new rifle
- Balance reload difficulty across different weapon types
- Design weapon attributes to encourage use of different rifles

## Documentation Status
- Rifle system fully documented in VR_RIFLE_SYSTEM.md
- Magazine positioning documented in .clinerules
- Interaction patterns established
- Debug logging implemented
