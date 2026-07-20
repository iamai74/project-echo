# AI Architecture

> **Last Updated:** 2026-07-20
>
> **Related**
>
> - actor.md
> - components.md
> - state-machine.md
> - combat-architecture.md
> - glossary.md

---

# Purpose

This document describes the AI architecture used for gameplay Actors in Project Echo.

AI is implemented as a State Machine-driven behaviour system.

The architecture reuses the same principles as Player control:

- Actor owns Components;
- State Machine controls behaviour;
- Components provide capabilities;
- States decide what the Actor should do.

---

# Overview

Enemy AI follows the same architectural model as other gameplay Actors.

```text
Enemy Actor

		│

		▼

State Machine

		│

		▼

AI States

		│

		▼

Components
```

AI does not directly control gameplay systems.

Instead, it selects behaviour through States.

---

# Core Principles

AI in Project Echo follows these principles:

- Use the same State Machine architecture as Player.
- Separate decision making from execution.
- Keep AI states small and focused.
- Use Components for reusable capabilities.
- Avoid enemy-specific gameplay logic inside Components.

---

# Enemy as Actor

Enemies are implemented as Actors.

An Enemy owns:

```text
Enemy
│
├── State Machine
├── HealthComponent
├── HurtboxComponent
├── HitboxComponent
├── DetectionComponent
└── WeaponComponent
```

The Actor itself does not contain behaviour logic.

Behaviour is implemented through States.

---

# AI State Machine

AI behaviour is represented as States.

Example:

```text
Idle

↓

Patrol

↓

Chase

↓

Attack

↓

Hurt

↓

Death
```

The State Machine is responsible for:

- entering states;
- exiting states;
- processing state updates;
- handling transitions.

---

# Current AI States

## IdleState

Purpose:

Wait state when no action is required.

Possible transitions:

```text
Idle

↓

Patrol
```

or

```text
Idle

↓

Chase
```

---

## PatrolState

Purpose:

Move between predefined points or follow a patrol direction.

Responsibilities:

- choose movement direction;
- control patrol timing;
- detect transition conditions.

Does not handle:

- target detection;
- attacking.

---

## ChaseState

Purpose:

Move toward a detected target.

Responsibilities:

- calculate desired movement direction;
- maintain distance from target;
- decide when to attack.

Example:

```text
Target detected

↓

Chase

↓

Target in attack range

↓

Attack
```

---

## AttackState

Purpose:

Execute an attack.

The same combat architecture is used as for the Player.

Flow:

```text
AttackState

↓

WeaponComponent

↓

AttackDefinition

↓

AttackData

↓

Combat Pipeline
```

AI decides **when** to attack.

Combat system decides **how** damage is applied.

---

# Detection System

Detection is implemented through `DetectionComponent`.

Its responsibility is identifying possible targets.

Detection does not decide behaviour.

Example:

```text
DetectionComponent

		↓

Target Found

		↓

State Machine Transition

		↓

ChaseState
```

---

# Target Acquisition

AI uses target information provided by Components.

Example:

```text
DetectionComponent

↓

Current Target

↓

ChaseState

↓

Movement Direction
```

The State does not search the world directly.

---

# AI Decision Flow

A typical enemy decision cycle:

```text
Detection

↓

Target Available?

↓

No
 |
 ▼
Patrol


Yes
 |
 ▼
Chase


Distance Check

↓

Attack Range?

↓

Yes

↓

Attack
```

---

# AI and Combat Separation

AI decides:

- when to attack;
- which behaviour to use;
- when to chase;
- when to retreat *(future)*.

Combat decides:

- hit detection;
- damage;
- knockback;
- health changes.

Example:

Correct:

```text
AI

↓

AttackState

↓

WeaponComponent

↓

Combat Pipeline
```

Incorrect:

```text
AI

↓

Enemy.health -= damage
```

---

# Components Used by AI

## DetectionComponent

Provides:

- target detection;
- target information.

---

## Movement System

Provides:

- movement execution.

AI decides direction.

Movement system performs movement.

---

## WeaponComponent

Provides:

- attack execution.

AI chooses when to use it.

---

## HealthComponent

Provides:

- health management;
- death state.

AI does not manage health directly.

---

# State Transition Examples

## Player Detected

```text
Patrol

↓

DetectionComponent detects Player

↓

ChaseState
```

---

## Player In Range

```text
ChaseState

↓

Distance Check

↓

AttackState
```

---

## Enemy Hit

```text
Any State

↓

Damage Received

↓

HurtState
```

---

## Enemy Dead

```text
Any State

↓

HealthComponent

↓

DeathState
```

---

# Extension Points

The current architecture allows future expansion.

Possible future additions:

- ranged attacks;
- enemy abilities;
- retreat behaviour;
- tactical positioning;
- group behaviour;
- boss AI;
- perception systems.

These should be implemented through new States and Components rather than expanding existing Actors.

---

# Best Practices

✔ Reuse the same State Machine architecture.

✔ Keep AI logic inside States.

✔ Keep detection separate from decision making.

✔ Use Components for capabilities.

✔ Let Combat handle combat.

✔ Let Movement handle movement.

---

# Anti-Patterns

Avoid:

❌ Putting AI decisions inside Components.

❌ Making Enemy subclasses with duplicated behaviour.

❌ Directly changing health from AI.

❌ Mixing detection and attack logic.

❌ Creating one large EnemyController class.

---

# Decision Summary

AI in Project Echo is implemented as a State Machine-driven system.

Enemies are Actors.

States define behaviour.

Components provide capabilities.

Detection provides information.

Combat remains independent from AI decisions.

This architecture allows Player and Enemy systems to share the same gameplay foundation while keeping behaviour modular and extensible.

---

# Related Documents

- Actor
- Components
- State Machine
- Combat Architecture
- Resources
- Glossary
