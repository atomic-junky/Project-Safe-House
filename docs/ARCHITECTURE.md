# Project Safe House - Refactored Architecture

## Overview

This document describes the refactored modular architecture of Project Safe House, following Godot 4+ best practices and game development principles.

## Architecture Principles

### 1. Composition Over Inheritance
Instead of deep inheritance hierarchies, we use **component-based composition**:
- Entities (Rooms, Dwellers) are composed of modular components
- Each component handles a single responsibility
- Components can be mixed and matched for different entity types

### 2. Separation of Concerns
Game logic is separated into specialized **managers**:
- **RoomManager**: Room placement, removal, and visual updates
- **DwellerManager**: Dweller lifecycle and room assignment
- **ElevatorManager**: Elevator network management
- **BuildManager**: Build mode and construction

### 3. Data-Driven Design
Static data is stored in **Resource** classes:
- **RoomData**: Defines room type properties (costs, meshes, stats)
- Resources are reusable and editable in the Godot editor

## Core Systems

### Component System

#### Base Component Class
```gdscript
Component extends Node
```
All components inherit from this base class, providing:
- `_initialize()`: Setup logic
- `_update(delta)`: Frame updates
- `_physics_update(delta)`: Physics updates
- `_cleanup()`: Cleanup on removal

#### Room Components
- **WorkspaceComponent**: Manages dweller work spots and assignments
- **ProductionComponent**: Handles resource production (power, water, food)
- **UpgradeComponent**: Manages room level progression and benefits
- **VisualComponent**: Handles room mesh and visual representation

#### Dweller Components
- **MovementComponent**: Pathfinding, navigation, and movement
- **WorkComponent**: Work assignment and productivity
- **StatsComponent**: (Future) SPECIAL stats management
- **NeedsComponent**: (Future) Hunger, happiness, health

### Entity System

#### RoomEntity
```gdscript
RoomEntity extends Node
```
A modular room that uses components instead of inheritance:
- Initialized with a **RoomData** resource
- Adds components based on room type
- Delegates behavior to components
- No room-specific logic in the entity itself

Example: PowerGenerator is now just a RoomEntity with:
- WorkspaceComponent (for workers)
- ProductionComponent (for power generation)
- UpgradeComponent (for level progression)
- VisualComponent (for mesh display)

#### DwellerEntity
```gdscript
DwellerEntity extends Node3D
```
A modular dweller that uses components:
- MovementComponent for pathfinding and travel
- WorkComponent for room assignments
- Components handle behavior instead of monolithic class

### Manager System

#### RoomManager
Handles all room-related operations:
- Adding/removing rooms from the vault
- Updating room visuals in the scene
- Validating build locations
- Coordinating with Matrix for grid management

#### DwellerManager
Manages dweller lifecycle:
- Spawning and removing dwellers
- Room assignments
- Drag & drop selection
- Tracking all active dwellers

#### ElevatorManager
Manages elevator networks:
- Detecting connected elevator shafts
- Creating/removing elevator platforms
- Updating network connections
- Handling platform references

#### BuildManager
Handles build mode:
- Enabling/disabling build mode
- Showing valid build locations
- Processing room construction
- Creating room instances

### Controller Layer

#### ShelterController
```gdscript
ShelterController extends Node3D
```
The main controller that:
- Initializes and owns all managers
- Handles input events
- Coordinates between managers
- Sets up initial vault state
- Does NOT contain game logic (that's in managers)

## Migration Strategy

### Old System → New System

#### Rooms
**Before:**
```gdscript
class PowerGenerator extends Room:
    var meshes = {...}
    var room_name = "Power Generator"
```

**After:**
```gdscript
var room_data = RoomData.new()
room_data.room_name = "Power Generator"
room_data.meshes = {...}

var room = RoomEntity.new(room_data)
room.add_child(ProductionComponent.new())
```

#### Dwellers
**Before:**
```gdscript
class Dweller extends ShelterEntity:
    var assigned_room
    func path_to_room(room):
        # 50 lines of logic
```

**After:**
```gdscript
class DwellerEntity extends Node3D:
    var movement: MovementComponent
    var work: WorkComponent
    
    func path_to_room(room):
        work.assign_to_room(room)
        movement.calculate_path(...)
```

## Benefits

### 1. Maintainability
- Each component/manager has a single responsibility
- Easy to locate and fix bugs
- Clear boundaries between systems

### 2. Reusability
- Components can be reused across different entity types
- Managers can be used in different contexts
- Resources are shareable

### 3. Testability
- Components can be tested in isolation
- Managers have clear interfaces
- Less coupled code

### 4. Scalability
- Easy to add new room types (just configure RoomData)
- Easy to add new dweller behaviors (just add components)
- Easy to extend managers with new features

### 5. Performance
- Components can be optimized individually
- Managers can batch operations
- Clear update loops

## Godot 4+ Best Practices

✅ **Composition over inheritance** - Using components instead of deep class hierarchies
✅ **Signals for communication** - Loose coupling between systems
✅ **Resources for data** - Data-driven design with RoomData
✅ **Node components** - Following Godot's node-based architecture
✅ **Typed GDScript** - Using type hints for better performance and IDE support
✅ **Export variables** - Configurable properties in the editor
✅ **Clear naming** - Descriptive names for classes, methods, and variables
✅ **Documentation** - Inline documentation for all classes and methods

## Next Steps

1. Convert all existing room types to use RoomEntity + components
2. Create RoomData resources for each room type
3. Update Dweller.gd to fully use DwellerEntity
4. Migrate remaining Shelter.gd code to managers
5. Add tests for components and managers
6. Update scene files to use new architecture
7. Add more components as needed (StatsComponent, NeedsComponent, etc.)

## File Structure

```
scripts/
├── Components/          # Reusable component classes
│   ├── Component.gd           # Base component
│   ├── WorkspaceComponent.gd
│   ├── ProductionComponent.gd
│   ├── UpgradeComponent.gd
│   ├── VisualComponent.gd
│   ├── MovementComponent.gd
│   └── WorkComponent.gd
├── Core/               # Core entity classes
│   ├── RoomEntity.gd         # Component-based room
│   ├── DwellerEntity.gd      # Component-based dweller
│   └── ShelterController.gd  # Main controller
├── Managers/           # Specialized managers
│   ├── RoomManager.gd
│   ├── DwellerManager.gd
│   ├── ElevatorManager.gd
│   └── BuildManager.gd
└── Resources/          # Data resources
    └── RoomData.gd
```

## Conclusion

This refactored architecture provides a solid foundation for Project Safe House, following modern game development practices and making the codebase more maintainable, testable, and scalable.
