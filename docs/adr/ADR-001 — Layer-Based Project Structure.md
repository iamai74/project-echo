# ADR-001 — Layer-Based Project Structure

> **Status:** Accepted
>
> **Date:** 2026-07-19
>
> **Related:**
> - architecture/overview.md
> - architecture/project-structure.md

---

# Context

Project Echo is a long-term game development project built around reusable gameplay systems rather than isolated gameplay features.

The project architecture already includes shared concepts such as:

- Actor
- Components
- Resources
- State Machine
- Combat Pipeline
- World Generation

These systems are intended to be reused by multiple gameplay entities, including the player, enemies, NPCs, and future interactive objects.

Choosing an appropriate project structure early is important because changing it later would require significant refactoring and negatively impact maintainability.

---

# Problem

There are two common ways to organize a game project:

## Feature-Based Structure

Example:

```text
features/

	player/

	enemy/

	combat/

	inventory/
```

Each feature contains its own scenes, scripts, resources, animations, and assets.

---

## Layer-Based Structure

Example:

```text
actors/

components/

resources/

systems/

world/

ui/
```

Each directory represents a technical responsibility rather than a gameplay feature.

The project needed to adopt one approach as the primary organizational model.

---

# Decision

Project Echo adopts a **Layer-Based Project Structure**.

The project is organized by architectural responsibility rather than gameplay feature.

Example:

```text
project/

	actors/

	components/

	resources/

	systems/

	world/

	ui/

	autoload/
```

Each directory has a clearly defined purpose.

Reusable systems are grouped together regardless of which gameplay feature uses them.

---

# Rationale

Project Echo is fundamentally built around reusable gameplay systems.

Examples include:

- HealthComponent
- WeaponComponent
- HurtboxComponent
- HitboxComponent
- StateMachine
- DetectionComponent

These systems are intentionally designed to work with multiple Actor types.

Organizing the project by architectural layer naturally reflects this design.

This approach also makes responsibilities easier to understand.

For example:

- all reusable components are located in one place;
- all configuration Resources are stored together;
- global systems remain separated from gameplay entities;
- world generation remains isolated from combat systems.

This organization supports the long-term goal of creating a maintainable and extensible architecture.

---

# Alternatives Considered

## Feature-Based Organization

Advantages:

- Easy to navigate in small projects.
- Related files are physically close together.
- Often used in UI-heavy applications.

Disadvantages for Project Echo:

- Encourages duplication of reusable systems.
- Makes shared gameplay components harder to discover.
- Blurs architectural boundaries.
- Scales poorly when systems become highly interconnected.

Because Project Echo is centered around reusable gameplay architecture rather than isolated gameplay features, this approach was rejected.

---

# Consequences

## Positive

- Clear architectural boundaries.
- High discoverability of reusable systems.
- Reduced duplication.
- Better scalability as the project grows.
- Consistent dependency direction.
- Easier onboarding for future contributors.

---

## Trade-offs

Developers working on a single gameplay feature may occasionally navigate across multiple directories.

This is considered an acceptable trade-off in exchange for improved architectural clarity.

---

# Future Considerations

This decision may be revisited if the project evolves toward a significantly different architecture, such as:

- ECS (Entity Component System)
- large-scale multiplayer
- plugin-oriented architecture

At the current scale and long-term vision of Project Echo, a layer-based structure is considered the most appropriate solution.

---

# Decision Summary

Project Echo organizes the project by **architectural responsibility** instead of **gameplay feature**.

This decision reinforces the project's core architectural principles:

- Composition over inheritance
- Reusable gameplay systems
- Explicit ownership
- Separation of data and logic
- Clear dependency direction

---

# Related Documents

- Architecture Overview
- Project Structure
- Components
- Actor
- Resources

## Decision Snapshot

**Chosen:** Layer-Based Project Structure

**Reason:** Reusable gameplay architecture.

**Benefits:**
- Better scalability.
- Clear responsibilities.
- Improved discoverability.

**Revisit When:**
The project fundamentally changes its architectural paradigm.
