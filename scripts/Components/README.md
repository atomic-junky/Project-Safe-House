# Component System

This directory contains the modular component classes used throughout Project Safe House.

## Overview

Components are small, focused, reusable behaviors that can be attached to entities (Rooms, Dwellers, etc.). They follow Godot 4's node-based architecture and the composition over inheritance principle.

## Core Concepts

### Component Base Class

All components inherit from `Component.gd`:

```gdscript
class_name MyComponent extends Component

func _initialize() -> void:
    super._initialize()
    # Component setup code

func _update(delta: float) -> void:
    # Per-frame logic

func _physics_update(delta: float) -> void:
    # Physics frame logic

func _cleanup() -> void:
    # Cleanup when removed
```

### Component Lifecycle

1. **Creation**: Component is instantiated
2. **Attachment**: Added as child to entity
3. **Initialization**: `_ready()` → `_initialize()` called
4. **Active**: `_update()` and `_physics_update()` called each frame
5. **Cleanup**: `_cleanup()` called when removed

## Available Components

### Room Components

#### WorkspaceComponent
Manages dweller work positions in a room.

**Key Features:**
- Tracks work spots and assignments
- Manages dweller registration/unregistration
- Handles workspace capacity

**Usage:**
```gdscript
var workspace = WorkspaceComponent.new()
workspace.setup_working_pool(working_pool_params)
room.add_child(workspace)

# Register a dweller
workspace.register_dweller(dweller, room_size)

# Check if full
if workspace.is_full(room_size):
    print("No more work spots!")
```

**Signals:**
- `dweller_assigned(dweller)` - When dweller starts working
- `dweller_removed(dweller)` - When dweller leaves
- `workspace_full()` - All spots taken
- `workspace_available()` - Spots now available

#### ProductionComponent
Handles resource production (power, water, food, etc.).

**Key Features:**
- Configurable production cycles
- Efficiency multipliers based on dweller stats
- Production progress tracking

**Usage:**
```gdscript
var production = ProductionComponent.new()
production.resource_type = "Power"
production.base_production_rate = 10.0
production.production_cycle_time = 5.0
room.add_child(production)

# Start production
production.start_production()

# Connect to production events
production.production_completed.connect(_on_production_complete)
```

**Signals:**
- `production_completed(resource_type, amount)` - Cycle complete
- `production_started(resource_type)` - Production begins

#### UpgradeComponent
Manages room level progression and benefits.

**Key Features:**
- Room level tracking (1-3)
- Upgrade cost calculation
- Level-based bonuses

**Usage:**
```gdscript
var upgrade = UpgradeComponent.new()
upgrade.max_level = 3
upgrade.base_upgrade_cost = 100
room.add_child(upgrade)

# Upgrade room
if upgrade.can_upgrade():
    var cost = upgrade.get_upgrade_cost()
    if player_has_caps(cost):
        upgrade.upgrade()
        
# Get bonuses
var production_bonus = upgrade.get_level_bonus()  # 0.0 - 0.5
```

**Signals:**
- `upgraded(new_level)` - Room leveled up
- `max_level_reached()` - Reached max level

#### VisualComponent
Handles room visual representation and mesh management.

**Key Features:**
- Mesh selection by room size
- Room node reference management
- Visual updates

**Usage:**
```gdscript
var visual = VisualComponent.new()
visual.setup_meshes(mesh_dictionary)
room.add_child(visual)

# Update visuals
visual.set_size(2)  # 2-tile room
visual.set_room_node(scene_node)

# Get position
var pos = visual.get_global_position()
```

**Signals:**
- `visual_updated()` - Visual changed

### Dweller Components

#### MovementComponent
Handles pathfinding, navigation, and movement.

**Key Features:**
- A* pathfinding
- Smooth movement
- Facing direction updates
- Matrix position tracking

**Usage:**
```gdscript
var movement = MovementComponent.new()
dweller.add_child(movement)

# Calculate path
var path = movement.calculate_path(start_pos, end_pos)
movement.set_path(path)

# Move to position
movement.move_to_position(delta, target_position)
```

**Signals:**
- `destination_reached()` - Arrived at target
- `movement_started()` - Started moving
- `path_updated(path)` - New path calculated

#### WorkComponent
Manages dweller work assignments and productivity.

**Key Features:**
- Room assignment tracking
- Work state management
- Productivity calculation based on stats

**Usage:**
```gdscript
var work = WorkComponent.new()
dweller.add_child(work)

# Assign to room
work.assign_to_room(room)

# Start working
work.start_work()

# Check productivity
var efficiency = work.productivity  # 0.0 - 1.0+
```

**Signals:**
- `work_started(room)` - Began working
- `work_stopped(room)` - Stopped working
- `productivity_changed(value)` - Productivity updated

## Creating Custom Components

### Step 1: Extend Component Base
```gdscript
class_name HealthComponent extends Component

signal health_changed(current: int, max: int)
signal died

@export var max_health: int = 100
var current_health: int = max_health
```

### Step 2: Implement Lifecycle Methods
```gdscript
func _initialize() -> void:
    super._initialize()
    current_health = max_health
    health_changed.emit(current_health, max_health)

func _update(delta: float) -> void:
    # Regeneration, status effects, etc.
    pass
```

### Step 3: Add Public Methods
```gdscript
func take_damage(amount: int) -> void:
    current_health = max(0, current_health - amount)
    health_changed.emit(current_health, max_health)
    
    if current_health <= 0:
        died.emit()

func heal(amount: int) -> void:
    current_health = min(max_health, current_health + amount)
    health_changed.emit(current_health, max_health)
```

### Step 4: Use in Entity
```gdscript
func _setup_components() -> void:
    var health = HealthComponent.new()
    health.max_health = 100
    add_child(health)
    
    health.died.connect(_on_dweller_died)
```

## Best Practices

### 1. Single Responsibility
Each component should handle one specific behavior:
✅ `ProductionComponent` - Only production
✅ `WorkspaceComponent` - Only work spots
❌ `RoomComponent` - Don't do everything

### 2. Communicate via Signals
Components should be loosely coupled:
```gdscript
# Good - Use signals
production.production_completed.connect(_on_production_done)

# Avoid - Direct coupling
production.owner.update_resources()  # Don't do this
```

### 3. Use Export Variables
Make components configurable in editor:
```gdscript
@export var base_production_rate: float = 10.0
@export_enum("Power", "Water", "Food") var resource_type: String = "Power"
```

### 4. Handle Edge Cases
```gdscript
func get_work_position(dweller: Dweller, room_size: int) -> Vector3:
    if not working_pool:
        push_warning("WorkingPool not initialized")
        return Vector3.ZERO
    return working_pool.get_position(room_size, dweller)
```

### 5. Document Your Components
```gdscript
class_name MyComponent extends Component
## Brief description of what this component does.
##
## More detailed explanation of the component's purpose,
## how it works, and when to use it.
```

## Component Patterns

### Pattern 1: Optional Components
```gdscript
# Get component if it exists
var production = room.get_component(ProductionComponent)
if production:
    production.start_production()
```

### Pattern 2: Component Dependencies
```gdscript
# WorkComponent depends on MovementComponent
func _initialize() -> void:
    super._initialize()
    movement = entity.get_component(MovementComponent)
    if not movement:
        push_error("WorkComponent requires MovementComponent")
```

### Pattern 3: Component Events
```gdscript
# Chain component events
workspace.dweller_assigned.connect(_on_dweller_assigned)

func _on_dweller_assigned(dweller):
    if production:
        production.update_efficiency([dweller.strength])
```

## Testing Components

### Unit Test Example
```gdscript
extends GutTest

func test_production_component():
    var component = ProductionComponent.new()
    component.resource_type = "Power"
    component.base_production_rate = 10.0
    
    add_child_autofree(component)
    component._initialize()
    
    component.start_production()
    assert_true(component.is_producing)
```

## Future Components

Planned components for future implementation:

- **StatsComponent** - SPECIAL stats for dwellers
- **NeedsComponent** - Hunger, happiness, health
- **InventoryComponent** - Equipment and items
- **RadiationComponent** - Radiation damage/resistance
- **TrainingComponent** - Skill progression
- **DefenseComponent** - Combat and defense
- **MoraleComponent** - Morale and happiness

## See Also

- [Architecture Documentation](../ARCHITECTURE.md)
- [Migration Guide](../MIGRATION_GUIDE.md)
- [Room Entity](../scripts/Core/RoomEntity.gd)
- [Dweller Entity](../scripts/Core/DwellerEntity.gd)
