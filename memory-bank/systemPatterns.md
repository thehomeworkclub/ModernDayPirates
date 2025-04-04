# System Patterns

## Shop System Architecture

### Shop Tab Organization
```
Shop System
├── Bronze Shop (Weapons)
│   └── Gun Selection with fixed prices
├── Silver Shop (Direct Stat Boosts)
│   └── +10% per level or +1 health per level
└── Gold Shop (Percentage Multipliers)
    └── x1.05 multiplier per level (multiplicative)
```

### Upgrade Calculation Pattern
1. Base Stats: 
   - Initial values set in GameManager (health, damage, speed, etc.)

2. Direct Boosts (Silver Shop):
   - Formula: base_stat + (level-1) * increment_value
   - Example: extra_damage = (level-1) * 0.1 (10% per level)
   - Health Special Case: extra_health = (level-1) * 1.0 (1 heart per level)

3. Percentage Multipliers (Gold Shop):
   - Formula: (base_stat + direct_boost) * percentage_multiplier
   - Percentage Calculation: pow(1.05, level-1) (5% compounding per level)
   - Example: damage = (1.0 + extra_damage) * percent_damage_increase

4. Price Scaling:
   - Formula: BASE_PRICE * pow(CURVE_FACTOR, level-1)
   - Constants: BASE_PRICE = 10, CURVE_FACTOR = 1.5
   - Results in exponential price growth

### Shop UI Pattern
- Currency Display: Top of screen, persistent across tabs
- Tab Selection: Top row of clickable buttons
- Item Display: Grid of 6 items (2x3) with:
  - Level number display (Label3D)
  - Price/description label (PriceLabel)
  - Visual differentiation for maxed items (green text)
- Bronze Shop: Checkmarks for selected weapons
- Silver/Gold Shops: Numeric upgrade levels with effect descriptions

### Shop-GameManager Integration
- Upgrades stored in GameManager dictionaries:
  - bronze_upgrade_levels (gun selection)
  - silver_upgrade_levels (direct boosts)
  - gold_upgrade_levels (percentage multipliers)
- GameManager.update_player_stats() recalculates all stats
- Persistence throughout gameplay sessions
- Reset only triggered on player death via reset_upgrade_levels()

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

### Shop Items
Bronze Shop (Weapons):
- Fixed prices: 50-300 bronze
- Selection indicator: "✓" with "EQUIPPED" text in green
- Mutually exclusive selection (only one active)

Silver Shop (Direct Boosts):
- Level indicator: Numeric value (1-10)
- Description format: "+X% [Stat]" or "+X Health"
- Price formula: BASE_PRICE * pow(CURVE_FACTOR, level-1)

Gold Shop (Multipliers):
- Level indicator: Numeric value (1-10)
- Description format: "xX.XX [Stat]" (e.g., "x1.15 Damage")
- Multiplier calculation: pow(1.05, level-1)

## Health and Damage System

### Player-Boat Health System
- Total health: 10 hearts base + upgrades
- Bidirectional synchronization between boat and gun display
- Health display appears on gun side for VR visibility
- Heart textures: fullheart.png and emptyheart.png
- Heart spacing: 0.05 units
- Heart scale: 0.05 units
- Health calculation: (base_health + extra_health) * percent_health_increase
- Display rounding: Only show full hearts (10.0 health = 10 hearts)

### Bomb Damage Mechanics
- Bomb detection via Area3D collision groups
- Default bomb damage: 3 hearts
- Bombs can be shot down by bullets in mid-air
- Explosion effects created with ColorRect fade
- Explosion timer: 0.5 seconds

### Death Sequence
- Dark red screen fade (full-screen ColorRect with Color(0.5, 0, 0))
- Fade duration: 2.0 seconds
- Process continues during pause (process_mode = PROCESS_MODE_ALWAYS)
- Game reset to round 1 on death
- Automatic return to campaign menu after fade
- Ensures GameManager resets game state properly
- No complex UI elements for clean VR experience

### Enemy Combat Systems

#### Enemy Bullet System
- Uses M16A1Bullet.tscn model scaled at 5x for visibility
- Custom red material (Color(1.0, 0.2, 0.0) with emission)
- Straight-line trajectory toward player
- Set as EnemyBullet group for collision filtering
- Collision layer 16, mask 1 (player only)
- Uses customized EnhancedBullet.gd script for straight movement
- Bullet damage: Scales with game difficulty

#### Enemy Spawning System
- Batch-based enemy spawning with 2 enemies per wave
- 5 waves per round as defined in GameParameters
- Refined wave progression tracking
- Spawn threshold: 3 active enemies for next batch
- Batch timer: 2.0 seconds between batches
- 2.0 second delay between waves
- Wave completion detection systems:
  - Direct explicit enemy tracking in spawned_enemies list
  - Force-check mechanism for handling race conditions
  - Explicit removal via remove_from_tracking system
- Enemy position validation to prevent overlaps
- Min spawn distance between enemies: 25.0 units

#### Wave and Round Management
- GameManager.complete_wave() handles wave progression
- Waves per round: 5 (configured in GameParameters.gd)
- Enemies per wave: 2 (configured in GameParameters.gd)
- Wave completion flow:
  1. All enemies for wave must be spawned
  2. All enemies must be defeated (count_active_enemies() == 0)
  3. Next wave begins after 2-second delay
  4. After 5 waves, round is complete
- Each defeated enemy adds to enemy_kill_count
- Teleport to shop when kill count reaches threshold
