# ADR-003 — Actor as the Base Gameplay Entity

> **Status:** Accepted
>
> **Date:** 2026-07-19
>
> **Related:**
> - architecture/overview.md
> - architecture/actor.md
> - architecture/components.md
> - architecture/state-machine.md

---

# Context

Project Echo contains multiple gameplay entities that participate in the game world.

Examples include:

- Player
- Enemy
- Bosses
- NPCs
- Interactive Objects (future)

Although these entities differ in behavior, they share a significant amount of common functionality.

Examples:

- health management;
- state transitions;
- movement;
- damage processing;
- animation;
- interaction with gameplay systems.

The project required a common abstraction that defines what it means to be an active gameplay entity.

---

# Problem

There are several possible approaches.

## Independent Implementations

Each gameplay entity owns its own implementation.

Example:

```text
Player

Enemy

NPC

Boss
```

Every class implements movement, combat, health, state management and communication independently.

This quickly leads to duplicated code and inconsistent behavior.

---

## Deep Character Hierarchy

```text
Character

├── Player

├── Enemy

└── NPC
```

This reduces some duplication but usually results in increasingly specialized subclasses as gameplay grows.

---

## Shared Base Gameplay Entity

A single gameplay entity coordinates common systems while individual actors provide their own behavior.

```text
Actor

├── Player

├── Enemy

├── NPC

└── Boss
```

The project needed to choose one of these approaches.

---

# Decision

Project Echo introduces **Actor** as the fundamental gameplay entity.

Every gameplay object capable of participating in gameplay should inherit from Actor.

Actor defines the common architecture shared by all gameplay entities.

It is responsible for coordinating reusable systems while avoiding gameplay-specific implementation.

---

# Responsibilities

Actor is responsible for:

- owning gameplay components;
- owning the State Machine;
- coordinating component lifecycle;
- exposing shared gameplay interfaces;
- providing access to configuration resources;
- managing actor-level events.

Actor is **not** responsible for implementing gameplay mechanics.

Gameplay functionality belongs inside dedicated components.

---

# Rationale

## Shared Foundation

Most gameplay entities require the same architectural building blocks.

Examples:

- HealthComponent
- WeaponComponent
- HurtboxComponent
- HitboxComponent
- StateMachine

Providing these through a common Actor greatly simplifies the architecture.

---

## Consistency

Every gameplay entity follows the same lifecycle.

Example:

```text
Spawn

↓

Initialize Components

↓

Gameplay

↓

Death

↓

Cleanup
```

This consistency makes systems easier to understand and extend.

---

## Reusable Gameplay Systems

Components should never distinguish between Player and Enemy unless absolutely necessary.

Example:

HealthComponent should simply operate on its owning Actor.

The same implementation works everywhere.

---

## Extensibility

Future gameplay entities can reuse the same architecture without introducing additional complexity.

Examples:

- Merchant
- Companion
- Summoned Creature
- Boss
- Training Dummy
- Interactive Mechanism

---

# Actor Ownership

Each Actor owns:

```text
Actor

├── Components

├── State Machine

├── Configuration Resources

└── Visual Representation
```

Components should not exist independently from an Actor.

Actor coordinates them throughout their lifecycle.

---

# Architectural Rules

Actor should:

- coordinate systems;
- expose shared interfaces;
- initialize components;
- provide access to common functionality;
- remain lightweight.

Actor should **not**:

- implement combat logic;
- calculate damage;
- implement AI;
- implement inventory logic;
- directly manage UI;
- implement procedural generation.

These responsibilities belong to dedicated systems.

---

# Alternatives Considered

## Independent Gameplay Classes

Advantages:

- Very simple initially.
- No shared abstraction.

Disadvantages:

- Massive code duplication.
- Inconsistent gameplay behavior.
- Difficult maintenance.

Rejected.

---

## Character Base Class

Advantages:

- Suitable for character-only games.

Disadvantages:

- Does not naturally support future non-character gameplay entities.
- Blurs architectural responsibilities.

Rejected.

Actor represents a more general gameplay abstraction.

---

# Consequences

## Positive

- Unified gameplay architecture.
- Consistent lifecycle.
- Reusable gameplay systems.
- Reduced duplication.
- Simplified future expansion.

---

## Trade-offs

Actor becomes a central architectural concept.

Its responsibilities must remain carefully controlled to avoid turning it into a "God Object."

Gameplay systems should continue living inside components rather than migrating into Actor over time.

---

# Future Considerations

Future gameplay entities should inherit from Actor whenever they actively participate in gameplay.

If a future entity does not require components, state management or gameplay interaction, inheritance from Actor should be reconsidered.

The existence of Actor does not imply that every Node in the project must become an Actor.

Only gameplay entities should inherit from it.

---

# Decision Summary

Actor is the foundational gameplay entity of Project Echo.

Inheritance defines identity.

Components define capabilities.

Actor coordinates those capabilities without implementing them.

---

# Decision Snapshot

**Chosen**

Actor as the base gameplay entity.

**Reason**

Provide a common architectural foundation for all gameplay entities.

**Benefits**

- Unified gameplay lifecycle.
- Reusable systems.
- Consistent architecture.
- Simplified maintenance.

**Revisit When**

The project fundamentally changes its gameplay architecture.

---

# Related Documents

- Architecture Overview
- Actor
- Components
- State Machine
- Resources
