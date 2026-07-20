# ADR-002 — Composition over Inheritance

> **Status:** Accepted
>
> **Date:** 2026-07-19
>
> **Related:**
> - architecture/overview.md
> - architecture/actor.md
> - architecture/components.md

---

# Context

Project Echo is designed as a long-term game project expected to grow continuously throughout development.

The game will introduce a large number of gameplay systems, including:

- combat;
- AI;
- status effects;
- inventory;
- abilities;
- procedural world generation;
- bosses;
- interactive objects.

Many of these systems will be shared across multiple gameplay entities.

Maintaining a deep inheritance hierarchy would make extending and maintaining the project increasingly difficult over time.

---

# Problem

Gameplay functionality can generally be organized using one of two approaches:

## Inheritance-Based Design

Behavior is added by creating increasingly specialized subclasses.

Example:

```text
Actor
 ├── Character
 │    ├── Player
 │    ├── Enemy
 │    │     ├── FlyingEnemy
 │    │     ├── RangedEnemy
 │    │     └── BossEnemy
 │    └── NPC
```

As gameplay evolves, inheritance trees tend to grow deeper and responsibilities become tightly coupled.

---

## Composition-Based Design

Behavior is assembled from independent reusable components.

Example:

```text
Actor

├── HealthComponent
├── WeaponComponent
├── HurtboxComponent
├── HitboxComponent
├── StateMachine
└── DetectionComponent
```

Actors differ primarily by the components they own and the configuration provided to those components.

The project needed to choose one architectural approach.

---

# Decision

Project Echo adopts **Composition over Inheritance** as a core architectural principle.

Gameplay behavior should be assembled through reusable components instead of expanding inheritance hierarchies.

Inheritance remains acceptable only where it represents a true "is-a" relationship.

Examples:

- Player is an Actor.
- Enemy is an Actor.
- Boss is an Enemy (when appropriate).

Gameplay functionality should **never** be introduced solely by creating additional subclasses.

---

# Rationale

Composition provides several advantages for Project Echo.

## Reusability

A component can be reused by any Actor.

Examples:

- HealthComponent
- WeaponComponent
- DetectionComponent
- StatusEffectComponent
- InventoryComponent

No component should assume who owns it.

---

## Flexibility

Gameplay entities can be assembled without introducing new inheritance levels.

For example:

Enemy A

```text
Health
Weapon
Detection
State Machine
```

Enemy B

```text
Health
Weapon
Detection
State Machine
FlyingComponent
```

The existing architecture remains unchanged.

---

## Maintainability

Each component owns a single responsibility.

Changes to one gameplay system should have minimal impact on unrelated systems.

---

## Testability

Reusable components can be tested independently from complete gameplay entities.

---

## Scalability

As the project grows, new gameplay systems can be introduced by creating new components rather than expanding the inheritance tree.

---

# Architectural Guidelines

Components should:

- own one gameplay responsibility;
- expose a clean public API;
- remain reusable;
- avoid assumptions about their owner;
- avoid knowledge of unrelated systems.

Components should **not**:

- control world generation;
- directly manage UI;
- create other components;
- implement unrelated gameplay systems.

---

# Alternatives Considered

## Deep Inheritance

Advantages:

- Simple for very small projects.
- Easy to understand initially.

Disadvantages:

- Tight coupling.
- Large fragile class hierarchies.
- Difficult reuse.
- Increasing maintenance cost.

Rejected.

---

## Pure ECS

Advantages:

- Excellent scalability.
- High flexibility.
- Data-oriented architecture.

Disadvantages:

- Significantly increases architectural complexity.
- Less aligned with Godot's node-based workflow.
- Adds unnecessary overhead for the current project scope.

Rejected for the current project.

Future migration remains possible if requirements change.

---

# Consequences

## Positive

- Highly reusable gameplay systems.
- Better separation of concerns.
- Easier maintenance.
- Simpler extension of gameplay mechanics.
- Cleaner ownership model.
- Reduced duplication.

---

## Trade-offs

Composition introduces additional objects and requires clear communication between components.

The project accepts this complexity in exchange for long-term maintainability.

---

# Future Considerations

Future systems should continue following this principle.

Examples include:

- inventory;
- abilities;
- buffs;
- debuffs;
- dialogue;
- interaction;
- crafting.

Whenever possible, new gameplay mechanics should be implemented as reusable components rather than additional subclasses.

---

# Decision Summary

Project Echo treats gameplay behavior as a composition of independent systems.

Inheritance defines identity.

Composition defines capabilities.

---

# Decision Snapshot

**Chosen**

Composition over Inheritance

**Reason**

Reusable gameplay architecture.

**Benefits**

- Better maintainability.
- High reuse.
- Flexible gameplay entities.
- Cleaner separation of responsibilities.

**Revisit When**

The project adopts a fundamentally different architectural paradigm (for example, ECS).

---

# Related Documents

- Architecture Overview
- Actor
- Components
- State Machine
