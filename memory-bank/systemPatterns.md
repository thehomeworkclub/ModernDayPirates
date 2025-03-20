# System Patterns

## Core Architecture

### VR Integration Layer
```mermaid
flowchart TD
    XR[OpenXR Interface] --> Origin[XR Origin]
    Origin --> Camera[XR Camera]
    Origin --> Controllers[XR Controllers]
    Controllers --> RayCasts[Ray Casting System]
    Controllers --> Haptics[Haptic Feedback]
```

### Menu Interaction System
```mermaid
flowchart TD
    Input[Controller Input] --> RaySystem[Ray Casting System]
    RaySystem --> Collision[Collision Detection]
    Collision --> ButtonSystem[Button System]
    ButtonSystem --> Animation[Animation]
    ButtonSystem --> Haptics[Haptic Feedback]
    ButtonSystem --> GameState[Game State]
```

## Design Patterns

### Observer Pattern
- Controller events trigger button interactions
- Button states notify animation and haptic systems
- Scene changes notify game manager

### State Management
- Button press states tracked via dictionaries
- Animation states managed through timers
- Scene transition states prevent multiple triggers

### Command Pattern (Button System)
```mermaid
flowchart LR
    Input[Controller Input] --> Command[Button Command]
    Command --> Action[Execute Action]
    Action --> |Start Voyage|GameManager
    Action --> |Quit Game|System
```

## Key Components

### Button System
- Physical button meshes
- Collision areas for interaction
- Animation system for visual feedback
- Haptic feedback integration

### Ray Casting System
- Visual laser beams
- Collision detection
- Interactive dot visualization
- Separate left/right controller handling

### Scene Management
```mermaid
flowchart TD
    Menu[Campaign Menu] --> |Voyage Selected|Game[Game Scene]
    Menu --> |Quit|Exit[Exit Game]
    Game --> |Game Over|Menu
```

## Technical Patterns

### Animation Management
- Timer-based animations
- Lerp-based position interpolation
- State tracking for multi-stage animations

### Input Handling
- Controller button mapping
- Ray casting for precise interaction
- Collision group system for categorization

### VR Optimization
- Static environment for performance
- Optimized collision shapes
- Careful mesh instance management

## Data Structures

### Voyage Configuration
```mermaid
flowchart TD
    Voyage[Voyage Data] --> Name[Name]
    Voyage --> Difficulty[Difficulty Level]
    Voyage --> SpawnRate[Enemy Spawn Rate]
    Voyage --> Speed[Enemy Speed]
    Voyage --> Health[Enemy Health]
```

### Button State Management
```mermaid
flowchart TD
    ButtonState[Button State] --> Position[Original Position]
    ButtonState --> Animation[Animation Timer]
    ButtonState --> Active[Active Status]
    ButtonState --> Hovering[Hover State]
