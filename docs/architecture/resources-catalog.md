# Resources Catalog

> **Last Updated:** 2026-07-20
>
> **Related**
>
> - resources.md
> - combat-architecture.md
> - world/room-data.md

---

# Purpose

This document provides a complete catalog of the data objects used throughout Project Echo.

It serves as a reference for gameplay and world configuration Resources, as well as runtime data objects that participate in the project's architecture.

Architectural principles are described in **resources.md**.

---

# Catalog Overview

| Object | Category | Runtime Owner | Lifetime | Status |
|----------|----------|---------------|----------|--------|
| WeaponData | Gameplay Resource | WeaponComponent | Project Asset | ✅ |
| AttackDefinition | Gameplay Resource | WeaponComponent | Project Asset | ✅ |
| RoomData | World Resource | RuntimeRoom | Project Asset | ✅ |
| AttackData | Runtime Data (`RefCounted`) | Combat Pipeline | Runtime | ✅ |
| EnemyData | Gameplay Resource | Enemy | Project Asset | 🚧 Planned |
| AbilityData | Gameplay Resource | AbilityComponent | Project Asset | 🚧 Planned |
| ItemData | Gameplay Resource | Inventory | Project Asset | 🚧 Planned |
| LootTable | Gameplay Resource | Loot System | Project Asset | 🚧 Planned |
| BiomeData | World Resource | World Generator | Project Asset | 🚧 Planned |

---

# Resource Relationships

## Combat

```text
WeaponComponent
        │
        ▼
WeaponData
        │
        ▼
AttackDefinition
        │
        ▼
AttackData (Runtime)
```

## World

```text
RuntimeRoom
        │
        ▼
RoomData
```

---

# Gameplay Resources

## WeaponData

### Purpose

Describes a weapon and the attacks available to it.

### Runtime Owner

- WeaponComponent

### Contains

- weapon_name
- icon
- attacks

### Public API

```gdscript
get_attack(type)

get_attack_types()
```

### Notes

- Contains no gameplay logic.
- Stores references to AttackDefinition resources.
- Shared by all instances of the same weapon.

---

## AttackDefinition

### Purpose

Describes a single attack.

### Runtime Owner

- WeaponComponent

### Contains

#### Damage

- damage
- knockback_force
- attack_type

#### Timing

- startup
- active
- recovery

#### Animation

- animation_name

#### Hitbox

- hitbox_offset
- hitbox_size

### Notes

- Immutable during gameplay.
- Defines attack behaviour.
- Shared between weapon instances.

---

# World Resources

## RoomData

### Purpose

Stores metadata describing a room.

### Runtime Owner

- RuntimeRoom

### Contains

Typical examples include:

- room identifier
- room type
- difficulty
- allowed biomes
- tags

### Notes

- Generated during the Bake process.
- Consumed by the World Generator.
- Contains metadata only.
- Never stores runtime state.

---

# Runtime Data

## AttackData *(RefCounted)*

### Purpose

Represents one attack instance during gameplay.

### Runtime Owner

- Combat Pipeline

### Contains

- damage
- knockback_force
- source
- direction

### Notes

Unlike the other objects in this document:

- AttackData is **not** a Resource.
- It is implemented as `RefCounted`.
- It exists only during a single attack.
- It is immutable after creation.
- It is never serialized as a project asset.

---

# Planned Resources

## EnemyData

Configuration describing enemy properties.

**Status:** Planned

---

## AbilityData

Configuration describing player or enemy abilities.

**Status:** Planned

---

## ItemData

Configuration describing collectible items.

**Status:** Planned

---

## LootTable

Configuration describing loot generation.

**Status:** Planned

---

## BiomeData

Configuration describing biome-specific generation settings.

**Status:** Planned

---

# Lifetime Comparison

| Object | Created | Destroyed |
|---------|----------|-----------|
| WeaponData | Editor | Project Shutdown |
| AttackDefinition | Editor | Project Shutdown |
| RoomData | Bake Process | Project Shutdown |
| AttackData | Attack Start | Attack End |

---

# Design Rules

Every Resource should:

- contain configuration only;
- avoid gameplay logic;
- avoid runtime state;
- be reusable;
- expose editable properties through the Inspector.

Runtime payload objects should remain separate from configuration Resources.

---

# Decision Summary

Project Echo separates configuration from runtime execution.

Configuration is represented by Godot Resources.

Runtime gameplay data is represented by lightweight runtime objects such as `AttackData`.

Maintaining this separation improves modularity, reusability and maintainability across the project.

---

# Related Documents

- Resources
- Combat Architecture
- Room Data
