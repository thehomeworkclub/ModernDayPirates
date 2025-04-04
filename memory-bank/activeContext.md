# Active Development Context

## Current Focus
We have successfully implemented a comprehensive VR weapons system with physical reloading mechanics optimized for use with a gunstock. The system allows for realistic magazine removal and insertion using physical hand movements. Seven different weapon models are now implemented with proper magazines, muzzle flashes, and recoil animations.

We have also implemented boat-based gameplay with enemy ships that shoot bombs at the player's boat. The health system shows damage on both the player UI and directly on the gun as a row of 10 hearts. This has now been enhanced with a wave and round tracker display on the right side of the gun, using custom icons with text indicators that match the heart display style.

Recently, we've enhanced the shop system to include persistent upgrades across game sessions, with three distinct shop tabs offering different types of upgrades. The system saves both currencies and upgrade levels between shop visits, only resetting if the player dies.

The completed weapon arsenal includes:
1. M16A1 (Assault rifle - default)
2. AK-74 (Assault rifle)
3. SCAR-L (Tactical rifle with balanced stats)
4. HK416 (High-precision rifle with better accuracy)
5. MP5 (Submachine gun with faster fire rate but lower damage)
6. Mosin Nagant (Bolt-action rifle with high damage but slow fire rate)
7. Model 1897 (Shotgun with pellet spread and 2-shell magazine)

Each weapon has unique handling characteristics, animations, and mechanics while maintaining a consistent reloading system.

Key implementation details:
- Base rifle functionality in BaseRifleGun.gd for inheritance
- Physical reloading using controller position tracking
- Properly scaled magazines with scale factor 15
- Generous detection margins for easier VR interaction:
  - Detachment threshold: 0.3 meters perpendicular distance
  - Reattachment detection radius: 0.2 meters from magazine well
- Simplified two-state system (ATTACHED_TO_GUN and DETACHED)
- Visual toggling of magazines with duplicated models for hand attachment

## Shop System Upgrade
We've implemented a three-tab shop system with persistent upgrades:

1. Bronze Shop (Weapons):
   - Functions as a weapon selector with varying prices (50-300 bronze)
   - Each weapon can be purchased with bronze currency
   - Visual indicators show equipped weapons with a green checkmark
   - Selected weapon persists between levels until player death

2. Silver Shop (Direct Stat Boosts):
   - Six different direct upgrades that add base stats:
     - Extra Silver (+10% per level)
     - Faster Bullets (+10% per level)
     - Extra Bronze (+10% per level) 
     - Extra Damage (+10% per level)
     - Faster Fire Rate (+10% per level)
     - Extra Health (+1 heart per level)
   - Each level increases cost according to progression formula
   - UI shows current bonus and next upgrade cost
   - Maxed upgrades display in green

3. Gold Shop (Percentage Multipliers):
   - Six multiplier upgrades applied after direct stat boosts:
     - Bronze Bonus (x1.05 per level, multiplicative)
     - Silver Bonus (x1.05 per level, multiplicative)
     - Gold Bonus (x1.05 per level, multiplicative)
     - Damage Boost (x1.05 per level, multiplicative)
     - Fire Rate Boost (x1.05 per level, multiplicative)
     - Health Boost (x1.05 per level, multiplicative)
   - UI shows current multiplier value with clear labels
   - Exponential growth with each level (multiplicative stacking)

All shop upgrades persist between waves and only reset on player death.

## VR Positioning Reference
- Campaign menu VR position: Vector3(10.954, -7.596, 4.236)
- Level1 XROrigin3D editor position: Vector3(2.45716, 16.3239, 85.035)
- Shop VR position: Vector3(11.312, -2.381, -9.427)
- Camera height: 1.8
- Ray length: 10.0
- Button press distance: 0.03
- RoundDisplay position: Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0.1, 0.04, -0.05)
- Wave/Round icon spacing: 0.15 (horizontally aligned via z-axis after rotation)

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

## HUD Elements
The game features several HUD elements attached to the player's view and gun:

1. Health Display (Left side of gun):
   - Row of heart icons showing current health (maximum 10)
   - Uses fullheart.png and emptyheart.png
   - Properly occluded behind gun model
   - Shows upgrade-based max health from shop purchases

2. Wave/Round Display (Right side of gun):
   - Custom icons for wave and round indicators (waveicon.png and roundicon.png)
   - Text labels positioned in corner of each icon
   - Wave counter shows current/total (e.g., "1/5") in white text
   - Round counter shows current round number in black text
   - Icons horizontally aligned using z-axis spacing after rotation
   - Proper depth testing ensures they're not visible through the gun
   - Position can be adjusted via RoundDisplay.gd variables:
     - Icon scale: 0.56
     - Icon spacing: 0.15
     - Label offset: Vector2(0.02, 0.02)

## Recently Completed
1. Shop System with Persistent Upgrades
   - Implemented three-tab shop with bronze, silver, and gold sections
   - Created gun selection system in bronze tab
   - Added stat upgrades in silver tab (direct boosts)
   - Added multiplier upgrades in gold tab (percentage boosts)
   - Ensured all upgrades persist between shop visits
   - Proper shop integration with GameManager for tracking states
   - Fixed UI to show current upgrade levels and effects
   - Implemented price scaling for higher level upgrades
   - Connected shop upgrades to in-game combat effects
   - Enhanced GameManager to handle all stat calculations

2. Wave Spawning System Improvements
   - Fixed wave progression and enemy spawning mechanics
   - Implemented proper 5-wave rounds with 2 enemies per wave
   - Fixed issue where killing one enemy would remove all enemies
   - Fixed issue where rounds were ending prematurely after 1 wave
   - Improved wave completion detection with better tracking
   - Added reliable force-check mechanism for wave transitions
   - Removed double-counting of enemy kills in GameManager
   - Fixed enemy count tracking with explicit remove_from_tracking system

3. Enemy Weapons and Health System Improvements
   - Upgraded enemy bullets to use M16A1Bullet.tscn model scaled at 5x
   - Added red coloration to enemy bullets for visual distinction
   - Fixed health system to maintain exactly 10 maximum health
   - Implemented a proper death sequence with dark red fade overlay
   - Added system to restart game at round 1 after player death
   - Fixed bidirectional health synchronization between boat and gun display
   - Improved bomb collision detection with player boat

4. VR Weapons System Expansion
   - Added 5 new weapon types with diverse characteristics:
     - SCAR-L: Tactical rifle with balanced stats (damage: 3, accuracy: 0.92)
     - HK416: High-precision rifle (damage: 3, accuracy: 0.95, low recoil: 0.15)
     - MP5: Submachine gun (damage: 1, fast fire rate: 0.08, lower accuracy: 0.85)
     - Mosin Nagant: Bolt-action rifle (high damage: 8, excellent accuracy: 0.98, 5-round magazine)
     - Model 1897: Shotgun (fires 8 pellets per shot, spread pattern, 2-shell magazine)
   - Implemented weapon switching via keyboard number keys (1-7) for debugging
   - Fixed ghost magazine issue when switching weapons
   - Added proper textured models for all weapons with appropriate UIDs

## Next Steps
1. Gameplay Integration:
   - Add more enemy types to challenge different weapon strategies
   - Implement ammo pickup/management
   - Further balance gameplay around different weapon types and upgrades
   - Add visual effects for upgraded weapons (enhanced effects based on level)
   - Expand weapon unlocking with achievement-based progression

2. Quality of Life Improvements:
   - Implement weapon selection via VR controllers (not just keyboard)
   - Add visual indicator for current selected weapon
   - Create weapon rack for in-game selection
   - Refine magazine positioning for optimal usability
   - Add shop tutorials or help indicators

## Active Considerations
- Maintain consistent interaction patterns across all rifle types
- Keep performance optimization in mind - monitor frame rate with multiple weapons
- Ensure magazine models are properly positioned for each new rifle
- Balance reload difficulty across different weapon types
- Design weapon attributes to encourage use of different rifles
- Balance shop upgrade costs and effects for proper gameplay progression

## Documentation Status
- Rifle system fully documented in VR_RIFLE_SYSTEM.md
- Magazine positioning documented in .clinerules
- Interaction patterns established
- Debug logging implemented
- Shop upgrade system now implemented and documented
