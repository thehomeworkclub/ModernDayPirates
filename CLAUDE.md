# CLAUDE.md - Agent Guidelines for Juice Game Project

## Project Overview
- 3D boat defense game built with Godot Engine/GDScript
- Player controls a boat with gun to defend against enemy waves
- Round-based progression with increasing difficulty

## Development Commands
- Open project: `godot -e .` (or open Godot Engine and select project)
- Run game: F5 in Godot Editor or `godot --path .`
- Export game: Use Export menu in Godot Editor

## Code Style Guidelines
- Use GDScript's typing system: `func shoot() -> void:`
- Properties with `@export` for inspector exposure
- Node references with `@onready var node = $Path/To/Node`
- Follow existing naming conventions:
  - snake_case for variables and functions
  - PascalCase for classes/nodes
  - ALL_CAPS for constants
- Signal connections via code using connect()
- Object cleanup with queue_free()
- Avoid deep nesting of conditionals
- Keep function responsibilities focused

## Project Structure
- Scripts (.gd) correspond to scene files (.tscn)
- GameManager serves as central game controller
- Enemy spawning handled by dedicated EnemySpawner
- Use existing patterns when adding new functionality