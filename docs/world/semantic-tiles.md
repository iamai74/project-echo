# Semantic Tiles

> **Status:** In Progress
>
> **Last Updated:** 2026-11-06
>
> **Related:**
> - [room-architecture.md](room-architecture.md)
> - [room-data.md](room-data.md)
> - [world-authoring.md](world-authoring.md)
> - [bake-pipeline.md](bake-pipeline.md)
> - [ADR-006 — Introduce a Semantic Tile Layer](../adr/ADR-006-semantic-tile-layer.md)

---

# Purpose

Semantic data separates gameplay meaning from visual representation.

A visual tile does not determine gameplay behaviour. The same semantic layout can receive different visual themes without changing room topology.

---

# Motivation

Identical-looking tiles may represent different gameplay meanings, while different visual themes may present the same gameplay structure.

Semantic data exists so that:

- gameplay and collision do not depend on art;
- themes can change visuals without rebuilding gameplay;
- room analysis and validation can reason about meaning;
- world generation can consume gameplay structure rather than tile appearance.

---

# Semantic Model

Current semantic authoring data is held in `SemanticRoomData`:

```text
SemanticRoomData
├── spatial_layers : SpatialLayer
├── markers        : MarkerLayer
└── volumes        : VolumeLayer
```

`SemanticRoomData` is a runtime `RefCounted` object used during baking. It is not saved directly.

---

# Spatial Layers

`SpatialLayer` groups cells by `SpatialType`:

```gdscript
enum SpatialType {
    PLATFORM,
    WALL,
    BACKGROUND
}
```

Current bake support:

| Spatial type | Brush | Processor | Baked into `RoomData` |
|--------------|-------|-----------|------------------------|
| `PLATFORM` | `PlatformBrush` | `PlatformBakeProcessor` | `platforms` |
| `WALL` | `WallBrush` | `WallBakeProcessor` | `walls` |
| `BACKGROUND` | `BackgroundBrush` | `BackgroundBakeProcessor` | `background` |

Platform and wall cells are topology cells. Background cells currently store only a position.

---

# Spatial Cells

## SemanticSpatialCell

Base cell type:

```gdscript
class_name SemanticSpatialCell
extends RefCounted

var cell: Vector2i
```

## SemanticSpatialTopologyCell

Adds computed topology:

```gdscript
class_name SemanticSpatialTopologyCell
extends SemanticSpatialCell

var topology: SpatialTopology
```

## SemanticSpatialPlatformCell

Adds platform traits:

```gdscript
class_name SemanticSpatialPlatformCell
extends SemanticSpatialTopologyCell

enum Trait {
    ONE_WAY,
    BREAKABLE,
}

var traits: Array[Trait] = []
```

Traits are currently carried through baking but are not yet consumed by runtime gameplay.

---

# Topology

`SpatialTopology` describes the cell's relationship to its neighbours:

```gdscript
class_name SpatialTopology
extends RefCounted

var shape: CellShape.Value
var corner: CellCorner.Value
```

## CellShape

```gdscript
enum Value { SINGLE, TOP, BOTTOM, LEFT, RIGHT, FULL }
```

## CellCorner

```gdscript
enum Value {
    TOP_LEFT,
    TOP_RIGHT,
    BOTTOM_LEFT,
    BOTTOM_RIGHT,
    TOP,
    BOTTOM,
    LEFT,
    RIGHT,
    ALL,
    NO
}
```

Topology is computed by `PostBakeTopologyProcessor` for `PLATFORM` and `WALL` layers only. It is then validated by `TopologyValidator` and `SemanticCellValidator`.

The resulting shape and corner are copied into `SemanticCell` in `RoomData`.

---

# Brushes

Semantic brushes are the authoring interface for semantic data.

```gdscript
@tool
class_name SemanticBrush
extends Node2D
```

Common properties:

- `enabled`;
- `size: Vector2i`;
- `priority: int`.

The brush converts its pixel position and size into grid coordinates using `World.settings.tile_size`.

## Brush types

```gdscript
enum BrushType {
    UNKNOWN,
    PLATFORM,
    WALL,
    BACKGROUND,
    ENEMY_SPAWN,
    LOOT_SPAWN,
}
```

Implemented brushes:

- `PlatformBrush` — supports `ONE_WAY` and `BREAKABLE` traits;
- `WallBrush`;
- `BackgroundBrush`.

`MarkerBrush` and `VolumeBrush` exist as base classes, but no concrete marker/volume brushes or bake processors are registered yet.

Brushes are `@tool` nodes for editor visualization only. They do not bake, construct runtime tiles or apply themes.

---

# Markers and Volumes

The semantic model reserves layers for:

## MarkerLayer

```gdscript
enum MarkerType {
    ENEMY_SPAWN,
    LOOT_SPAWN,
    CHECKPOINT
}
```

## VolumeLayer

```gdscript
enum VolumeType {
    MUSIC_ZONE,
    LIGHT_ZONE
}
```

Runtime marker data is `SemanticMarker { position, properties }`.

Runtime volume data is `SemanticVolume { polygon, properties }`.

Neither layer is currently baked into `RoomData`.

---

# Authoring to Runtime Flow

```text
Authored brushes
        │
        ▼
BrushCollector
        │
        ▼
SemanticRoomData
        │
        ├── PlatformBakeProcessor
        ├── WallBakeProcessor
        └── BackgroundBakeProcessor
        │
        ▼
PostBakeTopologyProcessor
        │
        ▼
Validators
        │
        ▼
RoomData
```

---

# Current Limitations

- Only spatial `PLATFORM`, `WALL` and `BACKGROUND` data is baked.
- Marker and volume data have model types but no authoring/bake path.
- Platform traits are not yet used at runtime.
- Semantic data does not yet describe entities, hazards or scripted events.

---

# Related Documents

- [Room Architecture](room-architecture.md)
- [Room Data](room-data.md)
- [World Authoring](world-authoring.md)
- [Bake Pipeline](bake-pipeline.md)
- [ADR-006](../adr/ADR-006-semantic-tile-layer.md)
