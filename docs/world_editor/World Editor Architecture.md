# World Editor Architecture

## 1. Purpose

`Echo World Editor` is a Godot Editor plugin for authoring rooms in Project Echo.

It provides editor-facing tools for creating, selecting, configuring, validating, and baking room-authoring objects. It reuses the existing World Authoring Core and Bake Pipeline rather than reimplementing their domain logic.

The plugin is an authoring interface, not a second runtime or bake framework.

### Implementation status

Milestone 1, **Plugin Foundation**, is implemented:

- `addons/echo_world_editor/` registers an `EditorPlugin` with a display-only dock.
- The dock classifies the edited scene as an authoring room, an unsupported scene, or no scene.
- Scene changes are tracked through the `EditorPlugin.scene_changed` and `scene_closed` signals.
- The dock is registered with `add_dock()` and freed by the plugin on disable.

The dock builds on Godot's `EditorDock` class, which is marked experimental in Godot 4.7 and may change in future engine versions.

See `docs/world_editor/implementation/01_Plugin_Foundation_Verification.md` for the verification record.

## 2. Goals

- Provide a convenient 2D authoring workflow inside Godot Editor.
- Reuse existing brush, marker, connection-point, validation, and bake implementations.
- Separate editor interaction from room data and bake logic.
- Support built-in and project-specific brush types.
- Keep editor configuration centralized and independent of hard-coded values.
- Preserve normal Godot scene editing, saving, undo, and redo behavior where applicable.

## 3. Non-goals for the initial implementation

- Building a standalone level editor.
- Replacing Godot's Scene, Inspector, or 2D Viewport.
- Moving Bake Pipeline logic into the plugin.
- Implementing a general-purpose third-party plugin marketplace or dynamic module loader.
- Implementing world generation.
- Changing runtime room architecture or the meaning of existing room data.
- Supporting arbitrary external extensions before the built-in workflow is stable.

## 4. Architectural boundaries

The system is divided into three conceptual layers.

```text
┌────────────────────────────────────────────┐
│              Godot Editor                  │
│                                            │
│  Echo World Editor plugin                  │
│  ├── UI / Dock / toolbar                    │
│  ├── Viewport interaction                  │
│  ├── Tool system                           │
│  ├── Brush registry                        │
│  ├── Editor context                        │
│  └── Editor configuration                  │
└─────────────────────┬──────────────────────┘
					  │ uses
┌─────────────────────▼──────────────────────┐
│           World Authoring Core             │
│                                            │
│  Brushes / markers / connection points     │
│  Brush collection                          │
│  Semantic data                              │
│  Validators                                │
│  Bake Pipeline                             │
└─────────────────────┬──────────────────────┘
					  │ produces
┌─────────────────────▼──────────────────────┐
│              Runtime artifacts             │
│                                            │
│  Runtime Room scene (.tscn)                │
│  Room data (.tres)                         │
│  TileSet / theme-applied visuals            │
└────────────────────────────────────────────┘
```

### 4.1 EditorPlugin responsibility

The plugin is responsible for:

- Registering and unregistering editor UI and editor integrations.
- Providing an authoring Dock and, when needed, toolbar controls.
- Determining which scene is currently being edited.
- Handling user interaction in the 2D viewport.
- Creating, selecting, moving, and configuring authoring objects.
- Displaying previews and authoring overlays.
- Managing editor-facing tool and brush registration.
- Calling Core validation and bake entry points.
- Presenting validation and bake reports.

### 4.2 World Authoring Core responsibility

Core remains responsible for:

- Brush and marker data models.
- Connection-point data model and compatibility rules.
- Collecting authoring objects from a room.
- Converting authoring objects into semantic room data.
- Validating room data and authoring constraints.
- Building runtime room scenes and resources.
- Applying themes and producing bake artifacts.

The plugin must not duplicate these rules. If a rule is needed by both editor UI and baking, it belongs in Core or in a shared domain layer.

### 4.3 Runtime responsibility

Runtime artifacts must not depend on editor-only classes or plugin availability. A baked room must remain loadable and usable when the editor plugin is disabled.

## 5. Important terminology

### Tool

A Tool defines an interaction mode in the editor: selection, brush placement, transformation, and similar operations.

Examples:

- `SelectTool`
- `BrushTool`
- `TransformTool`

A Tool handles user input and coordinates editing operations. It is not itself a room object.

### Brush / authoring object

A Brush is an authoring object placed in the editable room. It carries domain data consumed by the World Authoring Core.

Examples include:

- `PlatformBrush`
- `WallBrush`
- `BackgroundBrush`
- gameplay marker brushes
- connection-point authoring objects

A Brush is not the same thing as a Tool. The Brush Tool may create several different brush types.

### Descriptor

A descriptor is editor-facing metadata describing how a brush type is presented and created: stable identifier, display name, category, icon, scene or class reference, and optional editor capabilities.

A descriptor should not become a second source of domain truth. Domain properties remain on the brush/data model.

## 6. Tool and brush architecture

The initial conceptual structure:

```text
EchoWorldEditorPlugin
├── EditorContext
├── EditorSettings
├── EditorDock
├── ToolController
│   ├── SelectTool
│   ├── BrushTool
│   └── TransformTool
└── BrushRegistry
	├── PlatformBrush descriptor
	├── WallBrush descriptor
	├── BackgroundBrush descriptor
	├── Marker brush descriptors
	└── Connection point descriptor
```

Do not implement all of these classes in the Foundation milestone. Introduce abstractions only when a concrete step needs them.

### 6.1 Extension principle

The editor should allow additional brush types to be registered without modifying the central UI for every new type.

For the first version, support registration of built-in and project-local brush descriptors through a controlled API.

Do not implement dynamic code loading, third-party package management, or a complex extension lifecycle in the initial release.

A future custom brush should be able to provide:

- Stable identifier.
- Display name and category.
- Icon or fallback icon.
- Brush class or creation factory.
- Optional editor-specific preview/configuration behavior.
- Any required validation or bake integration through Core contracts.

The editor must not assume that every brush is a platform, wall, or background brush.

## 7. Configuration

Editor settings are distinct from game/runtime settings.

Initial configuration candidates:

- Cell size (initial default: 32 × 32, subject to the project's authoritative world setting).
- Grid visibility.
- Grid snapping.
- Brush preview visibility.
- Marker preview visibility.
- Optional visual preferences.

The editor should obtain the authoritative cell size from the existing project/world configuration when that is the intended source of truth. Avoid introducing a second independent cell-size value that can silently disagree with `WorldSettings`.

If an override is supported later, define its precedence and validation explicitly.

Changing editor grid settings must not mutate existing room geometry, semantic data, TileSet resources, or runtime artifacts.

## 8. Scene editing and persistence

The plugin should create and edit the same authoring objects that the existing collector and Bake Pipeline understand.

Prefer Godot editor APIs for scene modifications so changes participate in the editor's undo/redo system and are saved as ordinary scene changes.

The plugin must:

- Avoid modifying unrelated nodes.
- Avoid editing baked runtime scenes when an authoring scene is expected.
- Clearly identify unsupported or invalid active scenes.
- Avoid silently creating duplicate authoring roots or duplicate objects.
- Respect ownership and scene persistence rules for nodes created by editor tools.

The exact authoring-scene identification rule must be based on existing project conventions, not guessed from a scene filename.

## 9. Undo/redo

All user-visible scene mutations performed by tools should be integrated with Godot's editor undo/redo facilities.

Examples:

- Create brush.
- Delete brush.
- Move brush.
- Change brush properties, where practical.

Transient UI state (active tool, selected palette item, hover preview) does not need scene undo history.

## 10. Validation and bake integration

The plugin calls existing Core entry points and presents their results.

- Validation rules remain in Core.
- Bake steps remain in Core.
- The plugin may initiate validation or baking and display reports.
- The plugin must not silently bypass fatal validation errors.
- Bake output paths and overwrite behavior must follow existing project conventions.

## 11. Testing strategy

Use automated tests for deterministic, editor-independent logic:

- Settings defaults and validation.
- Brush descriptor and registry behavior.
- Tool state transitions, where they can be isolated.
- Existing Core collection, validation, and bake behavior.

Use Godot Editor integration/manual checks for:

- Plugin enable/disable lifecycle.
- Dock registration/removal.
- Active scene changes.
- Viewport input and drawing.
- Inspector integration.
- Undo/redo behavior.
- Saving and reopening edited authoring scenes.

Do not force editor UI tests into ordinary unit tests if the Godot editor environment makes them brittle. Record repeatable manual test steps.

## 12. Initial implementation order

1. Plugin Foundation.
2. Editor Configuration.
3. Tool System.
4. Brush Registry and Extension API.
5. Semantic Brush Editing.
6. Gameplay Marker Editing.
7. Connection Point Editing.
8. Validation UI.
9. Bake Integration.

The sequence may be adjusted when implementation reveals dependencies, but Core/domain logic must remain outside the plugin.

## 13. Architectural acceptance criteria

The architecture is considered respected when:

- The plugin can be disabled without breaking runtime scenes or Core tests.
- Existing Core classes remain usable without EditorPlugin.
- The plugin does not duplicate collection, validation, or bake logic.
- New brush types can be registered without rewriting central editor UI.
- Editor settings do not silently alter runtime data.
- Scene edits are saved as normal Godot scene changes and support undo/redo where applicable.
