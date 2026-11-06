# Bake Pipeline

> **Last Updated:** 2026-11-06
>
> **Related:**
> - [world-authoring.md](world-authoring.md)
> - [overview.md](overview.md)
> - [room-architecture.md](room-architecture.md)
> - [room-data.md](room-data.md)
> - [semantic-tiles.md](semantic-tiles.md)
> - [themes.md](themes.md)
> - [../architecture/resources.md](../architecture/resources.md)

---

# Purpose

The bake pipeline converts an authored room scene into validated, runtime-ready data.

It moves expensive content processing from gameplay runtime into the authoring stage.

---

# Pipeline

`BakePipeline` runs an ordered list of `BakeStep` objects against a `RoomBakeContext`.

Default order:

```text
CollectBrushesStep
→ InitSemanticDataStep
→ BakeSemanticLayerStep
→ PostProcessStep
→ ValidateStep
→ BuildRuntimeRoomStep
→ ApplyDefaultThemeStep
→ SaveRoomDataStep
```

The pipeline stops before running a step when:

- the report already contains a fatal issue;
- the next step returns `false` from `can_run_with_errors()`.

---

# Context

`RoomBakeContext` carries data between steps:

```gdscript
class_name RoomBakeContext
extends RefCounted

var room: Node
var brushes: BrushCollection
var semantic_data: SemanticRoomData
var report: BakeReport
var runtime_room_data: RoomData
var runtime_room: Node2D
```

A `BakeReport` groups issues by issue type and tracks severity. Fatal issues stop the pipeline.

---

# Steps

## 1. CollectBrushesStep

**ID:** `collect_brushes`

Recursively collects every `SemanticBrush` in the room scene using `BrushCollector`.

Brushes are grouped into a `BrushCollection` by `SemanticBrush.BrushType`. Brushes that return `UNKNOWN` are ignored.

Output: `context.brushes`.

---

## 2. InitSemanticDataStep

**ID:** `init_semantic_data`

Creates an empty `SemanticRoomData` containing:

- `SpatialLayer`;
- `MarkerLayer`;
- `VolumeLayer`.

Output: `context.semantic_data`.

---

## 3. BakeSemanticLayerStep

**ID:** `bake_semantic_layer`

Looks up processors in `BakeProcessorRegistry` and runs each registered processor against the brushes of its brush type.

Currently registered processors:

| Brush type | Processor | Output layer |
|------------|-----------|--------------|
| `PLATFORM` | `PlatformBakeProcessor` | `PLATFORM` |
| `WALL` | `WallBakeProcessor` | `WALL` |
| `BACKGROUND` | `BackgroundBakeProcessor` | `BACKGROUND` |

Processor behavior:

- `PlatformBakeProcessor` creates one `SemanticSpatialPlatformCell` per grid cell, copies platform traits, and reports overlapping platform cells as `BRUSH_OVERLAP` errors.
- `WallBakeProcessor` creates one `SemanticSpatialTopologyCell` per grid cell.
- `BackgroundBakeProcessor` creates one `SemanticSpatialCell` per grid cell.

Marker and volume brush types are declared but no processors are registered for them.

---

## 4. PostProcessStep

**ID:** `post_process`

Runs `PostBakeTopologyProcessor` on the `PLATFORM` and `WALL` layers.

For each cell, it checks the four direct neighbours and computes:

- `CellShape.Value`;
- `CellCorner.Value`.

Output: each platform/wall cell receives a `SpatialTopology`.

---

## 5. ValidateStep

**ID:** `validate`

Runs the validators in order:

1. `DuplicateCellValidator`;
2. `SemanticOverlapValidator`;
3. `TopologyValidator`;
4. `SemanticCellValidator`.

## Validators

### DuplicateCellValidator

Checks that no cell position appears more than once within the `PLATFORM`, `WALL` or `BACKGROUND` layer.

Reports `BRUSH_OVERLAP` errors.

### SemanticOverlapValidator

Checks that no platform cell overlaps a wall cell.

Reports `BRUSH_OVERLAP` errors.

### TopologyValidator

Checks that every platform/wall cell has topology data and that its shape and corner match the expected values derived from its neighbours.

Reports `SEMANTIC_CONFLICT` errors.

### SemanticCellValidator

Checks:

- the shape is acceptable for the layer;
- the corner is acceptable for the layer;
- the shape/corner combination is valid;
- platform traits are in range.

Reports `SEMANTIC_CONFLICT` errors.

Validation does not repair invalid data. Invalid rooms should fail the bake.

---

## 6. BuildRuntimeRoomStep

**ID:** `build_runtime_room`

Runs `RoomDataBuilder` and `RuntimeRoomBuilder`.

`RoomDataBuilder`:

- copies platform and wall cells into `RoomData`;
- converts background cells to `BackgroundCell`;
- computes `bounds` from platform and wall cells;
- leaves `connections` empty.

`RuntimeRoomBuilder` creates:

```text
RuntimeRoom (Node2D)
└── Semantic (Node2D)
    └── Tiles (TileMapLayer)
```

It does not create tiles.

Outputs:

- `context.runtime_room_data`;
- `context.runtime_room`.

---

## 7. ApplyDefaultThemeStep

**ID:** `apply_default_theme`

Loads the default theme from:

```text
res://resources/themes/default/default_theme.tres
```

and runs `ThemeApplyer.apply(runtime_room, theme, runtime_room_data)`.

This step only applies visuals. It does not change `RoomData` or topology.

If the runtime room or `RoomData` is missing, or the default theme cannot be loaded, it reports a fatal error.

The default theme is currently built separately through the theme build pipeline. See [themes.md](themes.md).

---

## 8. SaveRoomDataStep

**ID:** `save_room_data`

Saves:

```text
res://scenes/rooms/<room_basename>/<room_basename>_room_data.tres
res://scenes/rooms/<room_basename>/<room_basename>_runtime.tscn
```

The directory is derived from the authored room scene's file basename.

The runtime room is packed as a `PackedScene` and saved as a project asset.

---

# Input and Output

## Input

```text
Room Scene
├── Semantic brushes
│   ├── PlatformBrush
│   ├── WallBrush
│   └── BackgroundBrush
└── Authoring-only nodes
```

## Output

```text
scenes/rooms/<room_name>/
├── <room_name>_room_data.tres
└── <room_name>_runtime.tscn
```

The baked runtime scene contains TileMapLayer cells only after theme application. It does not contain actors or gameplay objects.

---

# Error Handling

The pipeline fails early on fatal issues.

Examples:

- missing semantic data;
- missing runtime room when applying a theme;
- invalid default theme path;
- failed save operation.

Validation errors do not automatically abort unless escalated to fatal. They remain in the report and should be fixed at the authoring source.

---

# Runtime Flow

```text
World Generator (planned)
   │
   ▼
Room selection
   │
   ▼
Instantiate baked RuntimeRoom
   │
   ▼
Apply/select theme (biome) (planned)
   │
   ▼
Playable room
```

Runtime does not repeat brush collection, processing or validation.

---

# Separation of Responsibilities

## Authoring

- create room layout with semantic brushes;
- provide gameplay meaning;
- keep visuals separate.

## Bake

- collect and convert brushes;
- compute topology;
- validate;
- build `RoomData` and runtime scene structure;
- apply default theme;
- save artifacts.

## Runtime

- instantiate baked rooms;
- assemble the world;
- run gameplay.

---

# Current Limitations

- Room database update is not implemented.
- Incremental bake and batch bake tooling are not implemented.
- Marker and volume data are not baked.
- Connections are not authored or baked.
- The default theme is always applied during bake; biome-driven theme selection is planned.
- The pipeline currently relies on debug/test drivers rather than a finished editor integration.

---

# Related Documents

- [World Authoring](world-authoring.md)
- [World Overview](overview.md)
- [Room Architecture](room-architecture.md)
- [Room Data](room-data.md)
- [Semantic Tiles](semantic-tiles.md)
- [Themes](themes.md)
