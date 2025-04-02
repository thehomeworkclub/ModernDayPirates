# System Patterns

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

## Shop Interface Layout

## Currency Display
- Location: Top of shop interface at y=-1.45
- Viewport size: 1000x120 pixels
- Spacing between currencies: 100 pixels
- Left/Right margins: 40 pixels
- Currency numbers use size 64 font with outline size 16

## Item Box Labels
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

## Shop Background
- Transform: 11.312, -2.381, -9.427
- Scale: 12.346 for both x and y
- Pixel size: 0.001
