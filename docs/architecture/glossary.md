# Glossary

> **Status:** In Progress
>
> **Last Updated:** 2026-11-06
>
> **Related:**
> - [overview.md](overview.md)
> - [actor.md](actor.md)
> - [components.md](components.md)
> - [state-machine.md](state-machine.md)
> - [combat-architecture.md](combat-architecture.md)
> - [resources.md](resources.md)
> - [../world/overview.md](../world/overview.md)

---

# Purpose

This document defines the architectural terminology used throughout Project Echo.

Documentation should use these definitions consistently. When a new architectural concept is introduced, add it here rather than redefining it in multiple places.

---

# A

## Actor

An active gameplay entity that participates in the game world.

`Actor` extends `CharacterBody2D`, owns components and a state machine, and delegates gameplay mechanics to them.

Implemented subclasses: `Player`, `Enemy`, `Walker`, `Runner`, `Heavy`.

---

## ActorData

A `Resource` containing actor configuration: health, movement speed, jump velocity, gravity, coyote time, jump count and jump hold force.

---

## AttackData

A runtime payload object representing one attack instance.

Implemented as `RefCounted`. It carries damage, knockback, source and direction through the combat pipeline.

`AttackData` is not a Resource and is not saved.

---

## AttackDefinition

A `Resource` describing one attack: damage, knockback, attack type, startup/active/recovery timing, animation name and hitbox configuration.

---

## AttackType

An enum representing attack intent:

```text
LIGHT
HEAVY
JUMP
DASH
SPECIAL
```

`AttackType` is independent from input bindings and animation names.

---

# B

## Bake

The process of converting an authored room scene into validated, runtime-ready data.

Bake produces `RoomData`, a generated runtime room scene and a themed default artifact.

See [Bake Pipeline](../world/bake-pipeline.md).

## BakePipeline

The ordered runner that executes `BakeStep` instances against a `RoomBakeContext`.

## BakeProcessor

A processor that converts one semantic brush type into semantic cells. Registered processors: `PlatformBakeProcessor`, `WallBakeProcessor`, `BackgroundBakeProcessor`.

## BakeStep

One composable stage of the bake pipeline. Steps can stop the pipeline through the shared `BakeReport`.

## BakeValidator

A validation stage that inspects semantic data without mutating it. Implemented: `DuplicateCellValidator`, `SemanticOverlapValidator`, `TopologyValidator`, `SemanticCellValidator`.

---

# C

## Combat Pipeline

The ordered systems that resolve an attack:

```text
WeaponComponent
→ AttackData
→ HitboxComponent
→ HurtboxComponent
→ Actor
→ HealthComponent
→ Hurt/Dead state
```

## Component

A reusable gameplay module responsible for one capability.

Implemented: `HealthComponent`, `WeaponComponent`, `HitboxComponent`, `HurtboxComponent`, `DetectionComponent`, `InputComponent`.

Components are owned by an Actor (or by its weapon node, for hitboxes).

## ConnectionData

A `Resource` describing a room connection: `id`, `side`, `position` and `size`.

The baked representation of the architectural ConnectionPoint concept. `RoomData.connections` is currently always empty because no authoring or baking path exists.

## ConnectionPoint

The architectural concept of an explicit room exit, recorded in ADR-007. Implemented in baked data as `ConnectionData`.

---

# D

## Detection

The process of identifying gameplay targets. Implemented by `DetectionComponent`, which currently detects only `Player`.

---

# G

## Gameplay Intent

A high-level gameplay action requested by a system, such as `AttackType.LIGHT`.

Intent describes **what** should happen, independent of input and implementation.

---

# H

## Hitbox

The offensive collision area used to detect attacks. Implemented by `HitboxComponent`.

Hitboxes forward `AttackData`; they never apply damage.

## Hurtbox

The defensive collision area that receives attacks. Implemented by `HurtboxComponent`.

Hurtboxes apply invulnerability rules and emit `hit_received`; they do not apply damage.

---

# R

## Resource

A serializable Godot object used for configuration or baked data.

Resources describe data; runtime systems operate on it.

## Room

A designer-authored gameplay area and the smallest unit of future world generation. A room has authored, baked and runtime representations.

## RoomData

A `Resource` containing the baked semantic layout of a room:

```text
version
bounds
platforms
walls
background
connections
```

See [Room Data](../world/room-data.md).

## Runtime Data

Temporary data created during execution and not stored as a project asset. Example: `AttackData`.

## Runtime Room

The generated scene instantiated during gameplay. Current structure:

```text
RuntimeRoom
└── Semantic
    └── Tiles (TileMapLayer)
```

---

# S

## Semantic Brush

An `@tool` authoring node describing intended room content. Brush types include platform, wall, background, enemy spawn, loot spawn and marker/volume base types.

Brushes describe intent; they do not bake or construct runtime content.

## Semantic Cell

A baked logical cell describing gameplay meaning rather than appearance.

`SemanticCell` stores `position`, `shape`, `corners` and `flags`. `BackgroundCell` stores `position`.

## Semantic Layer

A layer of semantic data. Authoring uses `SpatialLayer`, `MarkerLayer` and `VolumeLayer`. Baked spatial types are `PLATFORM`, `WALL` and `BACKGROUND`.

## Semantic Room Data

`SemanticRoomData`, the in-memory result of processing brushes before conversion to `RoomData`.

## State

A unit of Actor behaviour. Implemented states include `Idle`, `Move`, `Jump`, `Fall`, `Attack`, `Patrol`, `Chase`, `Hurt` and `Dead`.

## StateMachine

The node that owns States, tracks the current State and performs transitions.

---

# T

## Theme

A visual configuration mapping semantic cells to tiles. A theme does not change topology or gameplay meaning.

## ThemeApplyer

The runtime class that maps `RoomData` cells onto a runtime room's `TileMapLayer` using a `ThemeInfo`.

## ThemeBuilder

The runner for the theme build steps. It is separate from `BakePipeline`.

## ThemeInfo

A `Resource` containing the theme TileSet path and resolved `TilePack`/`TileId` collections for platforms, walls and background.

## TileId

A serializable reference to a tile: `source_id` plus `atlas_coords`.

## TilePack

A `Resource` grouping resolved `TileId` variants by tile type (single, top, bottom, corner variants and so on).

See [Themes](../world/themes.md).

---

# W

## WeaponData

A `Resource` describing a weapon: name, icon and an array of `AttackDefinition` resources. It maps `AttackType` to `AttackDefinition` at runtime.

## World

Currently an autoload exposing `WorldSettings`. World generation, biomes and streaming are planned, not implemented.

## World Authoring

The editor-side process of creating rooms with semantic brushes and baking them into runtime data.

## World Generator

The planned system that assembles baked rooms into a playable world.

---

# Architectural Model

Project Echo separates gameplay into layers:

```text
Configuration Resources
        ↓
Runtime Objects
        ↓
Gameplay Systems
        ↓
Gameplay Result
```

Configuration Resources describe gameplay. Runtime objects participate in it. Gameplay systems coordinate outcomes.

---

# Design Principles

- Actors own components and state machines.
- Components implement capabilities.
- States coordinate gameplay flow.
- Resources describe configuration and baked data.
- Runtime data transports information during execution.
- Runtime rooms are generated during bake.
- Themes affect appearance, not topology.
- The world generator is planned and must consume baked rooms rather than rebuild them.

---

# Related Documents

- [Architecture Overview](overview.md)
- [Actor](actor.md)
- [Components](components.md)
- [State Machine](state-machine.md)
- [Combat Architecture](combat-architecture.md)
- [Resources](resources.md)
- [World Architecture](../world/overview.md)
