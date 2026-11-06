# Resources Catalog

> **Last Updated:** 2026-11-06
>
> **Related:**
> - [resources.md](resources.md)
> - [combat-architecture.md](combat-architecture.md)
> - [world/room-data.md](../world/room-data.md)
> - [world/themes.md](../world/themes.md)

---

# Purpose

This document catalogs the data objects used throughout Project Echo.

It is a reference for gameplay configuration, baked world data, theme data, world settings and runtime data objects. Architectural principles are described in [resources.md](resources.md).

---

# Catalog Overview

| Object | Category | Runtime Owner | Lifetime | Status |
|----------|----------|---------------|----------|--------|
| `ActorData` | Gameplay Resource | `Actor` | Project asset | ✅ |
| `WeaponData` | Gameplay Resource | `WeaponComponent` | Project asset | ✅ |
| `AttackDefinition` | Gameplay Resource | `WeaponComponent` | Project asset | ✅ |
| `RoomData` | Baked World Resource | Runtime room / world systems | Project asset | ✅ |
| `SemanticCell` | Baked World Resource | `RoomData` | Project asset | ✅ |
| `BackgroundCell` | Baked World Resource | `RoomData` | Project asset | ✅ |
| `ConnectionData` | Baked World Resource | `RoomData` | Project asset | ✅ (data type only) |
| `ThemeInfo` | Theme Resource | `ThemeApplyer` | Project asset | ✅ |
| `TilePack` | Theme Resource | `ThemeInfo` | Project asset | ✅ |
| `ThemeTileAssets` | Theme Resource | `ThemeBuilder` | Build artifact | ✅ |
| `TileAssetsPack` | Theme Resource | `ThemeTileAssets` | Build artifact | ✅ |
| `TileId` | Theme Resource | `TilePack`, `ThemeInfo` | Project asset | ✅ |
| `WorldSettings` | World Configuration | `World` autoload | Project asset | ✅ |
| `AttackData` | Runtime Data (`RefCounted`) | Combat pipeline | Runtime | ✅ |
| `SemanticRoomData` | Runtime Data (`RefCounted`) | Bake pipeline | Bake run | ✅ |
| `SpatialLayer` | Runtime Data (`RefCounted`) | `SemanticRoomData` | Bake run | ✅ |
| `MarkerLayer` | Runtime Data (`RefCounted`) | `SemanticRoomData` | Bake run | Planned authoring/bake |
| `VolumeLayer` | Runtime Data (`RefCounted`) | `SemanticRoomData` | Bake run | Planned authoring/bake |
| `SpatialTopology` | Runtime Data (`RefCounted`) | Semantic cells | Bake run | ✅ |
| `BakeReport` | Runtime Data (`RefCounted`) | Bake pipeline | Bake run | ✅ |
| `ThemeBuildReport` | Runtime Data (`RefCounted`) | Theme builder | Build run | ✅ |
| `EnemyData` | Gameplay Resource | `Enemy` | Project asset | 🚧 Planned |
| `AbilityData` | Gameplay Resource | Ability system | Project asset | 🚧 Planned |
| `ItemData` | Gameplay Resource | Inventory | Project asset | 🚧 Planned |
| `LootTable` | Gameplay Resource | Loot system | Project asset | 🚧 Planned |
| `BiomeData` | World Resource | World generator | Project asset | 🚧 Planned |

---

# Resource Relationships

## Gameplay

```text
Actor
  │
  ├── ActorData
  ├── HealthComponent
  ├── HurtboxComponent
  ├── StateMachine
  └── WeaponComponent
          │
          ├── WeaponData
          │       └── AttackDefinition
          └── AttackData (runtime)
```

## Room Bake

```text
Authored Room Scene
        │
        ▼
SemanticRoomData
        │
        ▼
RoomData ──────────────► RuntimeRoom scene
        │
        └── ConnectionData
```

## Theme

```text
Theme JSON + PNG slices
        │
        ▼
ThemeTileAssets
        │
        ▼
TileSet + ThemeInfo
        │
        ├── TilePack (platforms)
        ├── TilePack (walls)
        └── Array[TileId] (background)
```

---

# Gameplay Resources

## ActorData

### Purpose

Describes actor-level movement and health configuration.

### Runtime Owner

- `Actor` (exported as `data`).

### Contains

| Property | Type | Default |
|----------|------|---------|
| `max_health` | `int` | `5` |
| `move_speed` | `float` | `220.0` |
| `jump_velocity` | `float` | `-420.0` |
| `gravity` | `float` | `1200.0` |
| `coyote_time` | `float` | `0.1` |
| `max_jumps` | `int` | `2` |
| `jump_hold_force` | `float` | `0.3` |

### Notes

- `Actor._initialize_components()` passes `max_health` to `HealthComponent`.
- `Actor` reads movement, jump and gravity values directly.
- No runtime state is stored in the Resource.

---

## WeaponData

### Purpose

Describes a weapon and the attacks available to it.

### Runtime Owner

- `WeaponComponent`.

### Contains

- `weapon_name: String`;
- `icon: Texture2D`;
- `attacks: Array[AttackDefinition]`.

### Public API

```gdscript
initialize() -> void
get_attack(type: AttackType.Type) -> AttackDefinition
get_attack_types() -> Array[AttackType.Type]
```

### Notes

- `initialize()` builds the internal attack map from `attacks`.
- `WeaponComponent._ready()` calls `weapon_data.initialize()`.
- Contains no gameplay logic beyond lookup.
- Shared by all instances of the same weapon.

---

## AttackDefinition

### Purpose

Describes a single attack.

### Runtime Owner

- `WeaponComponent`.

### Contains

| Group | Property | Type |
|-------|----------|------|
| Damage | `damage` | `int` |
| Damage | `knockback_force` | `float` |
| Damage | `attack_type` | `AttackType.Type` |
| Timing | `startup` | `float` |
| Timing | `active` | `float` |
| Timing | `recovery` | `float` |
| Animation | `animation_name` | `StringName` |
| Hitbox | `hitbox_offset` | `Vector2` |
| Hitbox | `hitbox_size` | `Vector2` |

### Notes

- Immutable during gameplay.
- `WeaponComponent` uses `hitbox_offset` and `hitbox_size` when entering the active phase.
- `animation_name` is configured but not currently consumed by the combat component.

---

## AttackType

`AttackType.Type` identifies attack intent:

```text
LIGHT
HEAVY
JUMP
DASH
SPECIAL
```

Current player input and enemy states use `LIGHT`. `DASH` also exists as an input command and state transition target, but no player dash state scene is currently present.

---

# World Settings

## WorldSettings

### Purpose

Global world configuration exposed through the `World` autoload.

### Runtime Owner

- `World` autoload (`World.settings`).

### Contains

- `tile_size: int = 32`.

### Notes

- Authoring brushes use `World.settings.tile_size` to convert pixel position/size into grid coordinates.
- `TileSetBuildStep` currently uses a separate hardcoded `TILE_SIZE := 32` rather than reading `WorldSettings`.

---

# Baked World Resources

## RoomData

### Purpose

Stores the validated semantic layout of a baked room.

### Runtime Owner

- Runtime room construction, `ThemeApplyer`, and future world systems.

### Contains

| Property | Type |
|----------|------|
| `version` | `int` |
| `bounds` | `Rect2i` |
| `platforms` | `Array[SemanticCell]` |
| `walls` | `Array[SemanticCell]` |
| `background` | `Array[BackgroundCell]` |
| `connections` | `Array[ConnectionData]` |

### Notes

- Generated by `RoomDataBuilder` during `BuildRuntimeRoomStep`.
- `bounds` is computed from platform and wall cells only.
- `connections` is currently an empty array; connection authoring/baking is not implemented.
- Consumed by `ThemeApplyer` to place background, platform and wall tiles.
- Never stores runtime state.

See [room-data.md](../world/room-data.md) for details.

---

## SemanticCell

### Purpose

Describes one platform or wall cell.

### Contains

- `position: Vector2i`;
- `shape: CellShape.Value`;
- `corners: CellCorner.Value`;
- `flags: int`.

### Notes

- `shape` and `corners` are copied from `SpatialTopology` during baking.
- `flags` is present but not currently populated.

---

## BackgroundCell

### Purpose

Describes one background cell.

### Contains

- `position: Vector2i`.

---

## ConnectionData

### Purpose

Describes a possible room connection.

### Contains

- `id: StringName`;
- `side: Side` — `TOP`, `BOTTOM`, `RIGHT`, `LEFT`;
- `position: Vector2i`;
- `size: Vector2i`.

### Notes

- The data type exists and is stored on `RoomData`.
- No authoring brush, bake step or connection validator currently produces or validates connections.

See [connection-points.md](../world/connection-points.md).

---

# Theme Resources

## ThemeInfo

### Purpose

Maps baked room data to TileSet tiles.

### Runtime Owner

- `ThemeApplyer`; loaded by `ApplyDefaultThemeStep` during bake.

### Contains

- `tileset: StringName` — resource path to the built TileSet;
- `platforms: TilePack`;
- `walls: TilePack`;
- `background: Array[TileId]`.

### Notes

- Written to `resources/themes/<theme>/<theme>_theme.tres`.
- The default theme is loaded from `res://resources/themes/default/default_theme.tres`.

---

## TilePack

### Purpose

Stores tile variants for one category.

### Contains

An `Array[TileId]` for each tile type:

```text
single, single_all,
single_top, single_bottom, single_left, single_right,
top, bottom, left, right, full,
top_left, top_right, bottom_left, bottom_right
```

### Notes

- Used for platforms and walls.
- `ThemeApplyer` selects a key from the cell's shape and corner, then picks a random variant.

---

## ThemeTileAssets

### Purpose

Holds loaded theme asset names before TileSet construction.

### Contains

- `platforms: TileAssetsPack`;
- `walls: TileAssetsPack`;
- `background: Array[String]`.

### Notes

- Produced by `ThemeAssetsLoadStep`.
- Saved to `resources/themes/<theme>/<theme>_tile_assets.tres`.

---

## TileAssetsPack

### Purpose

Holds asset variant names grouped by tile type.

### Contains

The same fifteen tile-type arrays as `TilePack`, but each entry is a `String` variant name.

---

## TileId

### Purpose

Identifies one tile inside a built TileSet.

### Contains

- `source_id: int`;
- `atlas_coords: Vector2i`.

### Public API

```gdscript
static at_source(source_id: int, atlas_coords: Vector2i) -> TileId
```

### Notes

- Produced by `TileSetBuildStep`.
- Consumed by `ThemeApplyer`.
- Serialized as part of `ThemeInfo`.

See [themes.md](../world/themes.md).

---

# Runtime Data

## AttackData *(RefCounted)*

### Purpose

Represents one attack instance during gameplay.

### Created By

- `WeaponComponent.start_attack()`.

### Contains

- `damage: int`;
- `knockback_force: float`;
- `source: Node`;
- `direction: Vector2`.

### Notes

- Not a Resource.
- Short-lived.
- Created at attack start and reused through the attack's phases.
- Never serialized.

---

## SemanticRoomData *(RefCounted)*

### Purpose

In-memory semantic room data used during baking.

### Contains

- `spatial_layers: SpatialLayer`;
- `markers: MarkerLayer`;
- `volumes: VolumeLayer`.

### Notes

- Created by `InitSemanticDataStep`.
- Not saved directly; `RoomDataBuilder` converts it into `RoomData`.

---

## SpatialLayer *(RefCounted)*

### Purpose

Stores semantic spatial cells grouped by `SpatialType`:

```text
PLATFORM
WALL
BACKGROUND
```

### Public API

```gdscript
add_cells(type, cells)
add_cell(type, cell) -> bool
set_cells(type, cells)
get_cells(type) -> Array[SemanticSpatialCell]
```

---

## MarkerLayer / VolumeLayer *(RefCounted)*

### Purpose

Store marker and volume authoring data.

### Status

- Marker types: `ENEMY_SPAWN`, `LOOT_SPAWN`, `CHECKPOINT`.
- Volume types: `MUSIC_ZONE`, `LIGHT_ZONE`.
- Base brush classes exist (`MarkerBrush`, `VolumeBrush`), but no concrete marker/volume brushes or bake processors are registered yet.
- These layers are not written into `RoomData`.

---

## SpatialTopology *(RefCounted)*

### Purpose

Stores computed topology for a platform or wall cell.

### Contains

- `shape: CellShape.Value`;
- `corner: CellCorner.Value`.

### Notes

- Produced by `PostBakeTopologyProcessor`.
- Validated by `TopologyValidator` and `SemanticCellValidator`.

---

## BakeReport / ThemeBuildReport *(RefCounted)*

### Purpose

Collect issues produced during a bake or theme build.

### Notes

- Group issues by issue type.
- Track severity (`WARNING`, `ERROR`, `FATAL`).
- A fatal issue stops the pipeline.

---

# Planned Resources

## EnemyData

Configuration describing enemy properties.

**Status:** Planned. Current enemies share `ActorData`, `WeaponData` and `AttackDefinition`.

## AbilityData

Configuration describing player or enemy abilities.

**Status:** Planned.

## ItemData

Configuration describing collectible items.

**Status:** Planned.

## LootTable

Configuration describing loot generation.

**Status:** Planned.

## BiomeData

Configuration describing biome-specific generation settings.

**Status:** Planned.

---

# Lifetime Comparison

| Object | Created | Destroyed |
|---------|----------|-----------|
| `ActorData` | Editor | Project shutdown |
| `WeaponData` | Editor | Project shutdown |
| `AttackDefinition` | Editor | Project shutdown |
| `RoomData` | Bake process | Project shutdown |
| `ThemeInfo` | Theme build | Project shutdown |
| `AttackData` | Attack start | Attack end |
| `SemanticRoomData` | Bake run | Bake run end |

---

# Design Rules

Every Resource should:

- contain configuration or baked data only;
- avoid gameplay logic;
- avoid runtime state;
- be reusable;
- expose editable properties through the Inspector.

Runtime payload objects should remain separate from configuration and baked Resources.

---

# Related Documents

- [Resources](resources.md)
- [Combat Architecture](combat-architecture.md)
- [Room Data](../world/room-data.md)
- [Themes](../world/themes.md)
