# Migration Guide: Old to New Architecture

This guide explains how to migrate from the old inheritance-based system to the new component-based architecture.

## Overview

The project is being refactored from:
- **Inheritance-based** → **Component-based** composition
- **God classes** → **Specialized managers**
- **Hard-coded** → **Data-driven** with resources

## Quick Reference

### Old Way vs New Way

#### Creating a Room

**OLD:**
```gdscript
class_name PowerGenerator extends Room

var meshes: Dictionary = {
    1: MeshLink._meshes.POWER_1L,
    2: MeshLink._meshes.POWER_2L,
    3: MeshLink._meshes.POWER_3L
}
var room_name: String = "Power Generator"

func _constructor() -> void:
    var params: WorkingPoolParameters = WorkingPoolParameters._default()
    working_spots = WorkingPool.new(params)
```

**NEW:**
```gdscript
# Create room data resource
var room_data = RoomData.new()
room_data.room_id = "power_generator"
room_data.room_name = "Power Generator"
room_data.category = "Production"
room_data.meshes = {
    1: MeshLink._meshes.POWER_1L,
    2: MeshLink._meshes.POWER_2L,
    3: MeshLink._meshes.POWER_3L
}

# Create room with components
var room = RoomEntity.new(room_data)

# Add production component
var production = ProductionComponent.new()
production.resource_type = "Power"
production.base_production_rate = 10.0
room.add_child(production)
```

#### Managing Rooms

**OLD:**
```gdscript
# In Shelter.gd (god class with 290 lines)
func _update_rooms() -> void:
    shelter_map.clear()
    # 50+ lines of room management logic...
```

**NEW:**
```gdscript
# In RoomManager (specialized, ~120 lines)
func update_room_visuals() -> void:
    # Focused room visualization logic
    
# In ShelterController (coordination only)
func _on_room_added(room: RoomEntity) -> void:
    room_manager.update_room_visuals()
    elevator_manager.update_networks()
```

## Step-by-Step Migration

### 1. Migrating a Room Type

#### Step 1: Create RoomData Resource
```gdscript
# In RoomFactory.gd or separate resource file
static func create_power_generator_data() -> RoomData:
    var data = RoomData.new()
    data.room_id = "power_generator"
    data.room_name = "Power Generator"
    data.description = "Generates power for the vault"
    data.category = "Production"
    data.max_size = 3
    data.build_cost = 100
    data.requires_power = false
    data.max_workers = 6
    data.primary_stat = "Strength"
    data.meshes = {
        1: MeshLink._meshes.POWER_1L,
        2: MeshLink._meshes.POWER_2L,
        3: MeshLink._meshes.POWER_3L
    }
    return data
```

#### Step 2: Add Required Components
```gdscript
static func create_power_generator() -> RoomEntity:
    var data = create_power_generator_data()
    var room = RoomEntity.new(data)
    
    # Production component for power generation
    var production = ProductionComponent.new()
    production.resource_type = "Power"
    production.base_production_rate = 10.0
    production.production_cycle_time = 5.0
    room.add_child(production)
    room.production = production
    
    # Workspace component is added automatically by RoomEntity
    
    return room
```

#### Step 3: Update Factory
```gdscript
# In RoomFactory.gd
static func create_room(room_type: int) -> Node:
    match room_type:
        RoomList.POWER_GENERATOR:
            return create_power_generator()  # Now returns new-style room
```

#### Step 4: Test
- The Matrix and existing code will work with both old and new rooms
- Test room placement, dweller assignment, and production
- Verify visual updates and networking

### 2. Migrating Shelter Logic

#### Identify Responsibilities
Look at the old Shelter.gd and identify separate concerns:
- **Room management** → RoomManager
- **Dweller management** → DwellerManager
- **Elevator networks** → ElevatorManager
- **Build mode** → BuildManager
- **Input handling** → ShelterController (coordination only)

#### Extract to Manager
**Before:**
```gdscript
# In Shelter.gd
func _update_elevator_networks() -> void:
    var new_networks = _get_elevator_networks()
    # 50 lines of elevator management...
```

**After:**
```gdscript
# In ElevatorManager.gd
func update_networks() -> void:
    var new_networks = _get_elevator_networks()
    # Same logic, but in a specialized class

# In ShelterController.gd
func _on_room_added(room: RoomEntity) -> void:
    elevator_manager.update_networks()  # Just delegate
```

### 3. Adding New Components

To add new behavior to rooms or dwellers:

#### Step 1: Create Component
```gdscript
class_name StorageComponent extends Component

signal storage_changed(current: int, max: int)

@export var max_storage: int = 100
var current_storage: int = 0

func add_items(amount: int) -> bool:
    if current_storage + amount > max_storage:
        return false
    current_storage += amount
    storage_changed.emit(current_storage, max_storage)
    return true

func remove_items(amount: int) -> bool:
    if current_storage - amount < 0:
        return false
    current_storage -= amount
    storage_changed.emit(current_storage, max_storage)
    return true
```

#### Step 2: Add to Entity
```gdscript
static func create_storage_room() -> RoomEntity:
    var data = create_storage_room_data()
    var room = RoomEntity.new(data)
    
    # Add storage component
    var storage = StorageComponent.new()
    storage.max_storage = 100
    room.add_child(storage)
    room.storage = storage  # Optional: add property for easy access
    
    return room
```

#### Step 3: Use Component
```gdscript
# Somewhere in game logic
var room = get_room_at(x, y)
var storage = room.get_component(StorageComponent)
if storage:
    storage.add_items(10)
```

## Common Patterns

### Pattern 1: Component Communication via Signals
```gdscript
# In ProductionComponent
signal production_completed(resource_type: String, amount: float)

# In room or manager
production.production_completed.connect(_on_production_completed)

func _on_production_completed(resource_type: String, amount: float):
    Global.add_resource(resource_type, amount)
```

### Pattern 2: Manager Communication
```gdscript
# Managers use signals to communicate
room_manager.room_added.connect(_on_room_added)

func _on_room_added(room: RoomEntity):
    elevator_manager.update_networks()
    dweller_manager.refresh_assignments()
```

### Pattern 3: Duck Typing for Compatibility
```gdscript
# Matrix accepts both old and new rooms
func add_room(room, positions: Array[Vector2]) -> bool:
    # Works with both Room and RoomEntity
    room._matrix = self
    # Uses duck typing - if it has the property, it works
```

## Testing Your Migration

### 1. Unit Testing Components
```gdscript
# Test a component in isolation
func test_production_component():
    var production = ProductionComponent.new()
    production.resource_type = "Power"
    production.base_production_rate = 10.0
    production.start_production()
    
    # Wait for production cycle
    await get_tree().create_timer(production.production_cycle_time).timeout
    
    # Check production completed
    assert(production.production_progress == 0.0)
```

### 2. Integration Testing
```gdscript
# Test room with components
func test_power_generator():
    var room = RoomFactory.create_power_generator()
    assert(room.production != null)
    assert(room.workspace != null)
    
    # Test production
    room.production.start_production()
    assert(room.production.is_producing)
```

### 3. Backward Compatibility Testing
```gdscript
# Ensure old code still works
func test_old_room_in_matrix():
    var matrix = Matrix.new(10, 10)
    var old_room = PowerGenerator.new()  # Old style
    
    matrix.add_room(old_room, [Vector2(0, 0)])
    assert(matrix.get_room_at(0, 0) == old_room)
```

## Migration Checklist

For each room type:
- [ ] Create RoomData resource
- [ ] Identify required components
- [ ] Create factory method
- [ ] Update RoomFactory.create_room()
- [ ] Test in isolation
- [ ] Test in game
- [ ] Update any room-specific references

For the shelter:
- [ ] Identify all responsibilities
- [ ] Create/update appropriate manager
- [ ] Move logic to manager
- [ ] Update controller to delegate
- [ ] Test functionality

## Troubleshooting

### "Property not found" errors
- Check if you're using a property that doesn't exist on both old and new classes
- Use duck typing: `if room.has("property")` before accessing

### Components not working
- Ensure components are added as children: `room.add_child(component)`
- Check component is initialized: wait for `_ready()` or call `_initialize()`

### Signals not connecting
- Verify signal exists on component
- Connect after component is added to tree
- Use `callable` syntax: `component.signal_name.connect(method)`

## Next Steps

1. Start with least complex rooms (LivingRoom, Diner)
2. Move to production rooms (PowerGenerator, WaterTreatment)
3. Handle special rooms (ElevatorShaft, VaultDoor)
4. Migrate dweller behavior
5. Clean up old code

## Resources

- See `ARCHITECTURE.md` for system overview
- Check `RoomFactory.gd` for examples
- Review components in `scripts/Components/`
- Study `ShelterController.gd` for manager usage
