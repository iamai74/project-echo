# Glossary

> **Last Updated:** 2026-07-20
>
> **Related**
>
> - overview.md
> - actor.md
> - components.md
> - state-machine.md
> - combat-architecture.md
> - resources.md
> - world/world-architecture-overview.md

---

# Purpose

This document defines the architectural terminology used throughout Project Echo.

All documentation should use these definitions consistently.

Whenever a new architectural concept is introduced, it should first be added to this glossary.

---

# A

## Actor

An active gameplay entity that participates in the game world.

Actors own Components and are coordinated by a State Machine.

Examples:

- Player
- Enemy
- NPC *(future)*

---

## AttackData

A runtime payload object representing a single attack instance.

Implemented as `RefCounted`.

AttackData transports combat information through the Combat Pipeline.

---

## AttackDefinition

A configuration Resource describing a single attack.

It defines gameplay parameters such as damage, timing, animation and hitbox configuration.

---

## AttackType

A gameplay identifier representing the intent of an attack.

Current values include:

- LIGHT
- HEAVY
- JUMP
- DASH
- SPECIAL

AttackType is independent from player input, animations and weapon implementation.

---

# B

## Bake

The process of converting authored room scenes into optimized runtime assets.

Bake validates room data and generates assets used during gameplay.

---

# C

## Combat Pipeline

The ordered sequence of systems responsible for resolving an attack.

Current pipeline:

```text
AttackState

↓

WeaponComponent

↓

WeaponData

↓

AttackDefinition

↓

AttackData

↓

HitboxComponent

↓

HurtboxComponent

↓

HealthComponent

↓

HurtState
```

---

## Component

A reusable gameplay module responsible for one specific capability.

Examples:

- HealthComponent
- WeaponComponent
- HitboxComponent
- HurtboxComponent
- DetectionComponent

Components are owned by Actors.

---

## Configuration Resource

A Godot Resource that stores gameplay configuration.

Configuration Resources are project assets and remain immutable during gameplay.

Examples:

- WeaponData
- AttackDefinition
- RoomData

---

## Connection Point

A predefined location where two Runtime Rooms may be connected during procedural generation.

---

# D

## Detection

The process of identifying gameplay targets.

Usually implemented by DetectionComponent.

---

# G

## Gameplay Intent

A high-level gameplay action requested by a gameplay system.

Gameplay Intent describes **what** should happen rather than **how** it is implemented.

Examples:

- AttackType.LIGHT
- AttackType.HEAVY

Gameplay Intent keeps gameplay systems independent from input bindings, animation names and weapon implementation.

---

# H

## Hitbox

The offensive collision area responsible for detecting successful attacks.

Hitboxes never apply damage directly.

---

## Hurtbox

The defensive collision area responsible for receiving attacks.

Hurtboxes validate incoming attacks before forwarding them to the HealthComponent.

---

# R

## Resource

A serializable Godot object used to store gameplay configuration.

Resources describe gameplay.

Runtime systems execute gameplay.

---

## Room

A designer-authored gameplay area that serves as a building block for procedural world generation.

---

## RoomData

A configuration Resource containing metadata describing a Room.

---

## Runtime Data

Temporary gameplay data created during execution.

Runtime Data is not stored as project assets.

Example:

- AttackData

---

## Runtime Object

An object that exists only while the game is running.

Examples:

- RuntimeRoom
- WeaponComponent
- HealthComponent
- AttackData

---

## Runtime Room

The optimized runtime representation of an authored Room.

Runtime Rooms are generated during the Bake process and consumed by the World Generator.

---

# S

## Semantic Tile

A logical tile representing gameplay meaning rather than visual appearance.

Semantic Tiles allow different biome themes to share the same gameplay layout.

---

## State

Represents what an Actor is currently doing.

Examples:

- Idle
- Move
- Jump
- Attack
- Hurt

---

## State Machine

The system responsible for coordinating Actor behaviour through transitions between States.

---

# W

## WeaponData

A configuration Resource describing a weapon and the attacks it provides.

WeaponData owns references to AttackDefinition resources.

---

## World Authoring

The process of creating gameplay rooms, metadata and generation information inside the editor before gameplay.

World Authoring includes:

- room creation;
- semantic tile placement;
- bake process;
- metadata generation.

---

## World Generator

The system responsible for assembling Runtime Rooms into a playable world according to generation rules.

---

# Architectural Model

Project Echo separates gameplay into several architectural layers.

```text
Configuration

↓

Runtime Objects

↓

Gameplay Systems

↓

Gameplay Result
```

Configuration Resources describe gameplay.

Runtime Objects execute gameplay.

Gameplay Systems coordinate gameplay.

---

# Design Principles

The following conventions are used consistently throughout the project.

- Actors own Components.
- Components implement gameplay behaviour.
- States coordinate gameplay flow.
- Resources describe gameplay configuration.
- Runtime Data transports gameplay information.
- Runtime Rooms are generated during Bake.
- World Generator assembles Runtime Rooms into playable worlds.

---

# Document Convention

All architectural documents should use the terminology defined in this glossary.

Whenever a new architectural concept is introduced, it should first be defined here before being referenced elsewhere.

---

# Related Documents

- Overview
- Actor
- Components
- State Machine
- Combat Architecture
- Resources
- World Architecture
