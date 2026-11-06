# AI Architecture

> **Status:** In Progress
>
> **Last Updated:** 2026-11-06
>
> **Related:**
> - [actor.md](actor.md)
> - [components.md](components.md)
> - [state-machine.md](state-machine.md)
> - [combat-architecture.md](combat-architecture.md)
> - [glossary.md](glossary.md)

---

# Purpose

This document describes the AI architecture used for enemy Actors in Project Echo.

Enemy AI is a state-machine-driven behaviour system. It reuses the same Actor, component and state architecture as the player:

- the Actor owns components;
- the state machine controls behaviour;
- components provide capabilities;
- states decide what the Actor should do.

---

# Overview

```text
Enemy Actor
     │
     ▼
State Machine
     │
     ▼
Enemy States
     │
     ▼
Components
```

AI does not directly manipulate health or world state. Decisions are expressed as state transitions; actions are executed through Actor and component APIs.

---

# Enemy as Actor

An Enemy owns:

```text
Enemy
├── StateMachine
├── HealthComponent
├── HurtboxComponent
├── WeaponComponent
│   └── HitboxComponent
└── DetectionComponent
```

Base `Enemy` also provides:

```gdscript
func get_target_position() -> Vector2
func is_attacking() -> bool
func _on_attack_finished(attack: AttackDefinition) -> void
```

Implemented enemy prototypes:

- `Walker`
- `Runner`
- `Heavy`

They currently share the same state setup and detection callbacks.

---

# AI States

Current enemy state set:

```text
Idle
Patrol
Chase
Move
Fall
Attack
Hurt
Dead
```

## Idle

Stops horizontal movement. Transitions to `Fall` when airborne.

The base implementation has no direct transition to `Patrol` or `Chase`.

## Patrol

Moves within a configurable `patrol_distance` around the position where patrol started. Reverses direction at walls or at the patrol limit. Transitions to `Fall` when airborne.

## Chase

Moves toward `DetectionComponent.get_target_position()`.

- if no target is available, transitions to `Patrol`;
- if the target is within attack range, transitions to `Attack`;
- otherwise moves horizontally toward the target.

Attack range is derived from the configured light attack:

```text
abs(hitbox_offset.x) + hitbox_size.x * 0.5
```

## Move

Placeholder movement state. Transitions to `Fall` when airborne.

## Fall

Transitions to `Idle` on landing.

## Attack

Starts a light attack. Transitions when `WeaponComponent.attack_finished` is forwarded to the state machine.

## Hurt

Sets the hurtbox invulnerable. Transitions back to `Idle`, `Move` or `Fall` after recovery.

## Dead

Calls `Actor.die()`.

---

# Detection

Detection is implemented by `DetectionComponent`, an `Area2D` that detects a `Player` hurtbox.

Signals:

```gdscript
signal player_detected(player: Player)
signal player_lost
```

API:

```gdscript
func get_target_position() -> Vector2
```

`get_target_position()` returns `Vector2.INF` when no player is tracked.

Detection only identifies the player. It is not a general multi-target perception system.

---

# Detection-to-Behaviour Wiring

Base `Enemy` connects:

```text
DetectionComponent.player_detected → Enemy._on_player_detected → _on_detection_success
DetectionComponent.player_lost     → Enemy._on_player_lost     → _on_detection_lost
```

In the base `Enemy`, `_on_detection_success()` and `_on_detection_lost()` are empty.

`Walker`, `Runner` and `Heavy` override them:

```text
detection success → Chase
detection lost    → Patrol
```

The intended architecture is detection → state transition. The base class wiring is therefore incomplete, and behaviour depends on the concrete prototype.

---

# AI Decision Flow

```text
Detection
    ↓
Target available?
    ├── No  → Patrol / Idle
    └── Yes → Chase
                ↓
          In attack range?
                ├── No  → keep chasing
                └── Yes → Attack
```

The current implementation does not include search, retreat, flanking or group behaviour.

---

# AI and Combat Separation

AI decides:

- when to attack;
- when to chase;
- when to patrol.

Combat decides:

- hit detection;
- damage;
- knockback;
- health changes.

Correct:

```text
AI state → WeaponComponent → HitboxComponent → HurtboxComponent → HealthComponent
```

Incorrect:

```text
AI → enemy.health -= damage
```

---

# Components Used by AI

## DetectionComponent

Provides target detection and target position.

## WeaponComponent

Executes attacks. AI chooses when to call `Actor.attack`.

## HealthComponent

Provides health and death signals. AI does not modify health directly.

## Movement

There is no `MovementComponent` yet. Enemy states call `Actor.move(direction)` directly.

---

# Current Limitations

- Detection only recognises `Player`.
- Base `Enemy` detection callbacks are no-ops.
- `Idle` does not automatically transition to `Patrol`.
- `_try_start_patrol()` in `Walker`, `Runner` and `Heavy` only starts patrol when the enemy has moved since the previous physics frame, and skips if the position is unchanged. A stationary enemy can remain in `Idle`.
- `EnemyState.has_movement_input()` always returns `false`, so shared transitions based on movement input do not apply to enemies.
- There is no pathfinding, navigation, line-of-sight check or target memory.
- There is no ranged attack, retreat or group behaviour.
- `Walker`, `Runner` and `Heavy` currently differ only by their scenes and data, not by behaviour script.

---

# Extension Points

Future AI work should extend the existing architecture:

- new states for search, ranged attacks, retreat or abilities;
- richer perception components;
- navigation/pathfinding services;
- boss-specific state sets;
- group coordination.

New behaviour should be introduced through states and components rather than a single large enemy controller.

---

# Best Practices

- Reuse the same state machine architecture.
- Keep AI decisions inside states.
- Keep detection separate from decision making.
- Use components for capabilities.
- Let combat handle combat.
- Let Actor movement APIs handle movement.

---

# Anti-Patterns

Avoid:

- putting AI decisions inside components;
- duplicating behaviour across enemy subclasses;
- directly changing health from AI;
- mixing detection and attack logic;
- creating one large `EnemyController`.

---

# Related Documents

- [Actor](actor.md)
- [Components](components.md)
- [State Machine](state-machine.md)
- [Combat Architecture](combat-architecture.md)
- [Glossary](glossary.md)
