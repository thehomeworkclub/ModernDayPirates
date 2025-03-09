# CLAUDE.md - Agent Guidelines for Modern Day Pirates

## Project Overview
- 3D boat defense game built with Godot Engine 4.3/GDScript
- Player controls a boat with weapons to defend against enemy waves
- Campaign-based progression with shop upgrades and currency system

## Development Commands
- Open project: `godot -e .` (or open Godot Engine and select project)
- Run game: F5 in Godot Editor or `godot --path .`
- Debug mode: Add `-d` flag to `godot` command
- Export game: Use Export menu in Godot Editor (see export_presets.cfg)

## Code Style Guidelines
- Use GDScript's typing system: `func shoot() -> void:`
- Properties with `@export` for inspector exposure
- Node references with `@onready var node = $Path/To/Node`
- Naming conventions:
  - snake_case for variables and functions
  - PascalCase for classes/nodes/scenes
  - ALL_CAPS for constants
- Signal connections via code using connect()
- Object cleanup with queue_free()
- Debug logging with print("DEBUG: ...")
- Keep functions focused on single responsibility

## Project Structure
- Game state management:
  - GameManager.gd: Core game logic and progression
  - CurrencyManager.gd: In-game economy
  - ShipManager.gd: Ship positioning and management
- Modular architecture with signals for inter-component communication
- Scene/script pairs (.tscn/.gd) for all game entities
- Model assets in Container/ directory
- EnemySpawner handles wave generation and difficulty scaling