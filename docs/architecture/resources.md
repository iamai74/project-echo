# Resources

> **Last Updated:** 2026-07-20
>
> **Related**
>
> - resources-catalog.md
> - actor.md
> - components.md
> - combat-architecture.md
> - world/room-data.md
> - ADR-004 — Store RoomData as a Godot Resource

---

# Purpose

This document defines how **Godot Resources** are used throughout Project Echo.

Resources are the primary mechanism for storing gameplay configuration.

They separate static project data from runtime behaviour, allowing gameplay systems to remain modular, reusable and data-driven.

---

# What is a Resource?

A Resource is a serializable data object that describes gameplay configuration.

Resources do not execute gameplay logic.

Instead, runtime systems read Resources and use them to perform gameplay behaviour.

Examples include:

- WeaponData
- AttackDefinition
- RoomData

---

# Design Goals

Resources are used to:

- separate data from code;
- make gameplay configurable;
- reduce hardcoded values;
- simplify balancing;
- improve reusability;
- expose editable properties in the Godot Inspector.

---

# Core Principles

Project Echo follows a strict separation between:

```text
Configuration

↓

Runtime Execution

↓

Gameplay Result
```

Resources belong to the **Configuration** layer.

Components and States belong to the **Runtime Execution** layer.

---

# Responsibilities

Resources are responsible for describing gameplay objects.

Typical information includes:

- gameplay parameters;
- metadata;
- timing values;
- references to assets;
- designer-authored configuration.

Resources should be deterministic.

The same input should always produce the same configuration.

---

# Non-Responsibilities

Resources should **never** be responsible for:

- gameplay logic;
- AI;
- physics;
- state transitions;
- timers;
- runtime state;
- scene ownership.

Those responsibilities belong to runtime systems.

---

# Configuration vs Runtime

Project Echo explicitly separates configuration from runtime objects.

```text
Configuration

WeaponData

AttackDefinition

RoomData

↓

Runtime

WeaponComponent

AttackData

RuntimeRoom
```

Resources describe behaviour.

Runtime objects execute behaviour.

---

# Lifetime

Resources typically exist for the entire lifetime of the project.

They are:

- saved as project assets;
- loaded when needed;
- shared by multiple runtime objects;
- reused across scenes.

Runtime objects are created and destroyed during gameplay.

---

# Ownership

Resources never own gameplay systems.

Instead, gameplay systems reference Resources.

Example:

```text
Actor
│
└── WeaponComponent
		│
		▼
	WeaponData
			│
			▼
	AttackDefinition
```

Example:

```text
RuntimeRoom
		│
		▼
	RoomData
```

Resources have no knowledge of who owns them.

---

# Immutability

Resources should generally be treated as immutable during gameplay.

Configuration should not change while the game is running.

Good:

```text
WeaponData

damage = 20
```

Bad:

```text
WeaponData

current_combo = 2
```

Current combo is runtime state.

It belongs inside WeaponComponent.

---

# Runtime Data

Not every gameplay data object is a Resource.

Example:

```text
AttackData
```

AttackData is implemented as a `RefCounted` runtime object.

Its purpose is transporting combat information during a single attack.

Unlike Resources:

- it is created at runtime;
- it is short-lived;
- it is never saved as an asset.

This distinction keeps configuration separate from gameplay execution.

---

# Resource Categories

Project Echo currently uses three conceptual categories.

## Gameplay Configuration

Describes gameplay behaviour.

Examples:

- WeaponData
- AttackDefinition

---

## World Configuration

Describes authored world content.

Examples:

- RoomData

---

## Runtime Data

Temporary gameplay objects created during execution.

Examples:

- AttackData *(RefCounted, not a Resource)*

Although Runtime Data is not implemented as a Godot Resource, it follows the same architectural goal of separating data from behaviour.

---

# Data Ownership

The following rule should always be respected.

Configuration belongs to Resources.

Runtime state belongs to runtime systems.

Example:

Configuration:

```text
AttackDefinition

damage

startup

active

recovery
```

Runtime:

```text
WeaponComponent

current_attack

attack_timer

combo_index
```

---

Configuration:

```text
RoomData

difficulty

allowed_biomes

tags
```

Runtime:

```text
RuntimeRoom

visited

doors_open

enemies_alive
```

---

# Communication

Resources do not communicate with gameplay systems.

They expose data only.

Components decide how that data is interpreted.

---

# Design Principles

## Data-Driven Architecture

Gameplay behaviour should be defined through configuration rather than hardcoded values.

---

## Reusability

The same Resource should be reusable by multiple gameplay objects.

---

## Separation of Concerns

Resources describe.

Components execute.

States coordinate.

Actors own.

---

## Inspector-Friendly

Whenever practical, gameplay configuration should be editable through the Godot Inspector.

---

# Best Practices

- Store only configuration inside Resources.
- Keep Resources immutable during gameplay.
- Prefer typed Resources over generic dictionaries.
- Avoid runtime state inside Resources.
- Keep Resources focused on a single responsibility.
- Expose designer-editable values through exported properties.

---

# Anti-Patterns

Avoid:

- storing timers inside Resources;
- storing current gameplay state;
- implementing gameplay logic inside Resources;
- referencing scene instances from Resources;
- creating circular Resource dependencies;
- using Resources as global managers.

---

# Future Extensions

New gameplay systems should follow the same architectural principles.

Possible future Resources include:

- EnemyData
- AbilityData
- ItemData
- LootTable
- BiomeData

Each Resource should remain focused on configuration only.

---

# Decision Summary

Resources are the configuration layer of Project Echo.

They describe gameplay but never execute it.

Runtime systems own behaviour.

Maintaining a clear separation between configuration and runtime execution is one of the fundamental architectural principles of the project.

---

# Related Documents

- Resources Catalog
- Combat Architecture
- Actor
- Components
- Room Data
- ADR-004
