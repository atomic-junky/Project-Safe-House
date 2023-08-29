<!-- LTeX: language=en-US -->

# Blender Helper

Godot 4 Import Plugins for Blender

## Plugins
- Blender Helper PackedScene
	- import the **Blender file** as a **PackedScene**
		- **Mesh** as a **MeshInstance**
		- **Empty Object** as a **Node3D**
		- Numbers for unique names are removed
	- options
		- Apply Modifiers: Import with Blender's modifiers active (Mirror, ...)
- Blender Helper MeshLibrary
	- import the **Blender file** as a **MeshLibrary** for a **GridMap**
	- **Mesh** for every Object
		- Name is the path to the Object
		- Numbers for unique names are removed
	- options
		- Apply Modifiers: Import with Blender Modifiers (Mirror, ...)
		- Create Collision: Create convex collision shapes

## Tested
- Godot 4 Alpha 3 for Windows
- Linux or macOS are not tested
	- please create an issue if you encounter a problem
	- please create an issue if you know where blender is usually located

## Installation
- Install Plugins
	- [Official Guide](https://docs.godotengine.org/en/stable/tutorials/plugins/editor/installing_plugins.html)
- Make **Blender** available (one of the following)
	- Install in default location
		- Blender default location or Steam (C:)
	- Change **ProjectSettings/Editor/Import/Blender Path** to the location of your **Blender Executable**
		- Activate **Advanced Settings** to see the setting
	- Add to system path
