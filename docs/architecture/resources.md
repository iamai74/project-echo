# Resources

> **Status:** In Progress
>
> **Last Updated:** 2026-11-06
>
> **Related:**
> - [resources-catalog.md](resources-catalog.md)
> - [actor.md](actor.md)
> - [components.md](components.md)
> - [combat-architecture.md](combat-architecture.md)
> - [world/room-data.md](../world/room-data.md)
> - [world/themes.md](../world/themes.md)
> - [ADR-004 — Store RoomData as a Godot Resource](../adr/ADR-004-room-data-as-resource.md)

---

# Purpose

This document defines how **Godot Resources** are used throughout Project Echo.

Resources separate static project data from runtime behaviour, allowing gameplay and world systems to remain modular, reusable and data-driven.

---

# What is a Resource?

A Resource is a serializable data object. Resources describe data; they do not execute gameplay logic.

Current examples include:

- `ActorData`
- `WeaponData`
- `AttackDefinition`
- `RoomData`
- `ThemeInfo`
- `WorldSettings`

Runtime systems read Resources and use them to perform behaviour.

---

# Design Goals

Resources are used to:

- separate data from code;
- make configuration editable in the Godot Inspector;
- reduce hardcoded values;
- simplify balancing;
- improve reusability;
- preserve baked world data between runs.

---

# Core Separation

Project Echo separates data from execution:

```text
Configuration / Baked Data

        ↓

Runtime Execution

        ↓

Gameplay Result
```

Resources belong to the data layer. Components, states, builders and applyers belong to the runtime execution layer.

---

# Responsibilities

Resources describe gameplay or world data. Typical contents include:

- gameplay parameters;
- timing values;
- asset references;
- semantic room data;
- theme tile mappings;
- world settings;
- designer-authored configuration.

Baked Resources such as `RoomData` and `ThemeInfo` are produced by pipelines and should be regenerated from their sources.

---

# Non-Responsibilities

Resources should never own:

- gameplay logic;
- AI decisions;
- physics processing;
- state transitions;
- timers;
- runtime state;
- scene ownership.

Those responsibilities belong to runtime systems.

---

# Resource Categories

Project Echo currently uses five conceptual categories.

## Gameplay Configuration

Describes actor and combat behaviour.

Examples:

- `ActorData` — health, movement, jump and gravity parameters;
- `WeaponData` — weapon identity and available attacks;
- `AttackDefinition` — damage, timing, animation and hitbox configuration.

---

## World Settings

Global world configuration.

Example:

- `WorldSettings` — currently exposes `tile_size` (default `32`);
- exposed at runtime through the `World` autoload as `World.settings`.

`World.settings.tile_size` is used by authoring brushes to convert pixel positions and sizes into grid coordinates.

---

## Baked World Data

Produced by the room bake pipeline and consumed by runtime room construction and theme application.

Examples:

- `RoomData`;
- `SemanticCell`;
- `BackgroundCell`;
- `ConnectionData`.

`RoomData` is stored as a project asset and describes the validated semantic layout of a room. It contains no runtime gameplay state.

---

## Theme Data

Produced by the theme build pipeline and used to apply visual representation to baked room data.

Examples:

- `ThemeInfo` — TileSet path plus platform, wall and background tile mappings;
- `TilePack` — tile variants for one category (`platform` or `walls`);
- `ThemeTileAssets` — loaded asset names before TileSet construction;
- `TileAssetsPack` — variant names grouped by tile type;
- `TileId` — a source ID and atlas coordinate pair.

Theme data must not encode room topology or gameplay semantics.

---

## Runtime Data

Temporary objects created during execution. Most are not Godot Resources.

Examples:

- `AttackData` — `RefCounted` combat payload;
- `SemanticRoomData` — in-memory semantic room during bake;
- `SpatialTopology` — computed shape and corner data;
- `SpatialLayer`, `MarkerLayer`, `VolumeLayer` — in-memory semantic layers;
- `BakeReport`, `ThemeBuildReport` — pipeline diagnostics;
- `InputCommand`, `Command` — input intent.

These objects follow the same data/behaviour separation as Resources even when they are not serialized.

---

# Configuration vs Runtime

```text
Configuration / Baked Data

ActorData
WeaponData
AttackDefinition
RoomData
ThemeInfo

        ↓

Runtime

Actor
WeaponComponent
AttackData
RuntimeRoom
ThemeApplyer
```

Resources describe data. Runtime objects execute behaviour.

---

# Ownership

Resources do not own gameplay systems. Gameplay systems reference Resources.

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
        └── AttackDefinition
```

```text
Runtime room construction
        │
        ▼
RoomData
```

```text
ThemeApplyer
        │
        ├── ThemeInfo
        └── RoomData
```

A Resource has no knowledge of who uses it.

---

# Immutability

Resources should generally be treated as immutable during gameplay.

Good:

```text
ActorData

max_health = 5
move_speed = 220.0
```

Bad:

```text
ActorData

current_health = 3
```

Current health belongs to `HealthComponent`.

Baked data such as `RoomData` and `ThemeInfo` is also immutable at runtime. Regenerating it is a bake/build operation, not a gameplay operation.

---

# Runtime Data

Not every data object is a Resource.

`AttackData`, for example, is a `RefCounted` object created when `WeaponComponent.start_attack()` begins an attack. It transports:

- `damage`;
- `knockback_force`;
- `source`;
- `direction`.

It is short-lived and never saved as a project asset.

---

# Communication

Resources do not communicate with gameplay systems. They expose data only.

Components, states and builders decide how that data is interpreted.

---

# Design Principles

## Data-Driven Architecture

Gameplay and world behaviour should be defined through configuration and baked data rather than hardcoded values.

## Reusability

The same Resource should be reusable by multiple runtime objects.

## Separation of Concerns

Resources describe. Components execute. States coordinate. Actors own. Bake steps transform. Theme building and application remain separate.

## Inspector-Friendly

Whenever practical, configuration should be editable through the Godot Inspector.

---

# Best Practices

- Store only configuration or baked data inside Resources.
- Keep Resources immutable during gameplay.
- Prefer typed Resources over generic dictionaries.
- Avoid runtime state inside Resources.
- Keep Resources focused on one responsibility.
- Regenerate baked Resources from their pipelines.
- Keep theme data separate from room topology.

---

# Anti-Patterns

Avoid:

- storing timers or current gameplay state in Resources;
- implementing gameplay logic inside Resources;
- treating generated Resources as a second source of truth;
- putting theme asset layout into `RoomData`;
- creating circular Resource dependencies;
- using Resources as global managers.

---

# Planned Resources

Possible future Resources include:

- `EnemyData`;
- `AbilityData`;
- `ItemData`;
- `LootTable`;
- `BiomeData`;
- a room database Resource or registry.

Each should remain focused on its domain data.

---

# Decision Summary

Resources are the data layer of Project Echo.

They describe gameplay, world and theme data but never execute it. Runtime systems own behaviour. Baked Resources are generated by the world and theme pipelines and consumed at runtime.

---

# Related Documents

- [Resources Catalog](resources-catalog.md)
- [Combat Architecture](combat-architecture.md)
- [Actor](actor.md)
- [Components](components.md)
- [Room Data](../world/room-data.md)
- [Themes](../world/themes.md)
- [ADR-004](../adr/ADR-004-room-data-as-resource.md)
