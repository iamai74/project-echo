# Combat Architecture

> **Status:** In Progress
>
> **Last Updated:** 2026-11-06
>
> **Related:**
> - [actor.md](actor.md)
> - [components.md](components.md)
> - [state-machine.md](state-machine.md)
> - [resources.md](resources.md)
> - [resources-catalog.md](resources-catalog.md)

---

# Purpose

This document describes the combat architecture used in Project Echo.

Combat is a modular, data-driven pipeline composed of reusable components coordinated by an Actor and its state machine. The architecture separates:

- combat configuration;
- runtime attack data;
- attack execution;
- damage resolution.

---

# Combat Overview

```text
Configuration       WeaponData → AttackDefinition
        │
        ▼
Runtime Execution   WeaponComponent → AttackData → HitboxComponent
        │
        ▼
Combat Resolution   HurtboxComponent → Actor → HealthComponent → Hurt/Dead state
```

Configuration Resources describe attacks. `WeaponComponent` executes them. The target Actor resolves the outcome.

---

# Combat Flow

```mermaid
sequenceDiagram

participant State as Attack State
participant Weapon as WeaponComponent
participant Data as WeaponData
participant Definition as AttackDefinition
participant Hitbox
participant Hurtbox
participant Actor as Target Actor
participant Health as HealthComponent

State->>Weapon: start_attack(LIGHT)
Weapon->>Data: get_attack(LIGHT)
Data-->>Weapon: AttackDefinition
Weapon->>Weapon: create AttackData
Note over Weapon: STARTUP
Weapon->>Hitbox: activate(AttackData)
Note over Weapon: ACTIVE
Hitbox->>Hurtbox: receive_hit(AttackData)
Hurtbox-->>Actor: hit_received(AttackData)
Actor->>Health: take_damage(AttackData)
Actor->>Actor: apply knockback
Actor->>State: start("Hurt") or "Dead"
Weapon->>Hitbox: deactivate()
Note over Weapon: RECOVERY → IDLE
```

---

# Pipeline

## 1. Attack Request

Combat begins when an Actor requests an attack.

Sources:

- player input through `PlayerState` helpers;
- enemy AI states;
- direct scripted calls to `Actor.attack`.

`Actor.attack(type)` delegates to `WeaponComponent.start_attack(type)` when a weapon is present.

## 2. Attack Selection

`WeaponComponent` owns a `WeaponData` resource. `WeaponData.initialize()` builds a map from `AttackType` to `AttackDefinition`.

```gdscript
func get_attack(type: AttackType.Type) -> AttackDefinition
func get_attack_types() -> Array[AttackType.Type]
```

If the requested type has no definition, `start_attack` logs an error and does nothing.

## 3. Attack Definition

`AttackDefinition` is the configuration resource for one attack.

```gdscript
class_name AttackDefinition
extends Resource

@export_group("Damage")
@export var damage: int = 10
@export var knockback_force: float = 150.0
@export var attack_type: AttackType.Type

@export_group("Timing")
@export var startup: float = 0.08
@export var active: float = 0.10
@export var recovery: float = 0.12

@export_group("Animation")
@export var animation_name: StringName

@export_group("Hitbox")
@export var hitbox_offset: Vector2
@export var hitbox_size: Vector2 = Vector2(32, 24)
```

`animation_name` is declared but not yet consumed by the implemented combat pipeline.

## 4. Runtime Attack

`WeaponComponent` creates one `AttackData` when the attack starts, before the `STARTUP` phase completes.

```gdscript
class_name AttackData
extends RefCounted

var damage: int
var knockback_force: float
var source: Node
var direction: Vector2
```

`AttackData` is a runtime payload, not a Resource. It transports attack information through the pipeline and is treated as immutable after creation.

## 5. Attack Phases

`WeaponComponent` runs an internal phase machine:

```text
IDLE
  ↓ start_attack
STARTUP   (startup seconds)
  ↓
ACTIVE    (active seconds; hitbox enabled)
  ↓
RECOVERY  (recovery seconds; hitbox disabled)
  ↓
IDLE
```

On entering `ACTIVE`, the component:

- mirrors `hitbox_offset.x` by the Actor's facing direction;
- sets the hitbox position;
- resizes a `RectangleShape2D` or `CapsuleShape2D`;
- calls `HitboxComponent.activate(AttackData)`.

On leaving `ACTIVE`, it deactivates the hitbox.

`interrupt_attack()` immediately deactivates the hitbox and returns to `IDLE`.

## 6. Hit Detection

`HitboxComponent` starts with monitoring disabled.

`activate(attack_data)`:

- sets `active = true`;
- enables monitoring;
- clears the per-attack `hit_targets` set;
- checks already-overlapping areas.

For each overlapping `HurtboxComponent` it:

- ignores its own Actor;
- skips targets already hit during this activation;
- calls `HurtboxComponent.receive_hit(attack_data)`;
- emits `hit_target`.

The hitbox never applies damage.

## 7. Damage Reception

`HurtboxComponent.receive_hit(attack_data)`:

- if invulnerable, emits `damage_blocked` and stops;
- otherwise emits `hit_received(attack_data)`.

It does not apply damage or knockback itself.

Damage flow:

```text
HurtboxComponent.hit_received
        ↓
Actor._on_hit_received
        ↓
HealthComponent.take_damage(attack)
```

## 8. Damage Processing

`HealthComponent` owns health state:

- clamps health at zero;
- emits `damaged` and `health_changed`;
- emits `died` when health reaches zero;
- supports healing and max-health changes.

Health is modified only inside `HealthComponent`.

## 9. Hit Reaction

`Actor._on_hit_received` performs the reaction:

1. call `health.take_damage(attack)`;
2. apply knockback if `attack.knockback_force > 0`;
3. if still alive, start the `"Hurt"` state;
4. if dead, the `HealthComponent.died` signal starts `"Dead"`.

Knockback is applied directly to `velocity` by `Actor`:

```gdscript
velocity += attack.direction * attack.knockback_force
```

The hurt states manage invulnerability:

- `PlayerHurtState` locks input and sets the hurtbox invulnerable;
- `EnemyHurtState` sets the hurtbox invulnerable;
- both clear invulnerability on exit.

## 10. Recovery

When the hurt state finishes:

```text
Hurt
 ├──► Idle
 ├──► Move
 └──► Fall
```

Death leads to `Dead`, whose current implementation calls `Actor.die()` and frees the Actor.

---

# Combat Participants

## State Machine

- decides when attacks occur;
- enters attack and hurt states.

It does not calculate damage.

## WeaponComponent

- selects `AttackDefinition`;
- creates `AttackData`;
- runs attack timing;
- positions and activates the hitbox.

## WeaponData

Configuration resource owning an `Array[AttackDefinition]`. It contains no runtime attack state.

## AttackDefinition

Shared configuration for one attack type.

## AttackData

Runtime payload for one attack instance. Not saved or shared beyond that attack.

## HitboxComponent

Offensive `Area2D`. Detects hurtboxes and forwards `AttackData`.

## HurtboxComponent

Defensive `Area2D`. Applies invulnerability rules and forwards accepted hits.

## Actor

Applies damage, knockback and state transitions after a hit.

## HealthComponent

Owns health, damage, healing and death.

## Hurt State

Controls reaction timing and invulnerability.

---

# Attack Types

```text
LIGHT
HEAVY
JUMP
DASH
SPECIAL
```

`AttackType` represents gameplay intent and is independent from input bindings and animation names.

Not every type is currently configured in every weapon resource, and there is no dash state.

---

# Configuration vs Runtime

| Object | Purpose | Lifetime |
|--------|---------|----------|
| `WeaponData` | Weapon configuration and attack set | Project asset |
| `AttackDefinition` | Single attack configuration | Project asset |
| `AttackData` | Runtime attack payload | One attack |

---

# Ownership

```text
Actor
├── StateMachine
├── WeaponComponent
│   └── HitboxComponent
├── HurtboxComponent
└── HealthComponent
```

Configuration:

```text
WeaponComponent → WeaponData → AttackDefinition[]
```

Runtime:

```text
WeaponComponent → AttackData
```

---

# Design Principles

- Keep attack configuration inside `AttackDefinition`.
- Keep weapon configuration inside `WeaponData`.
- Treat `AttackData` as immutable.
- Apply damage only inside `HealthComponent`.
- Let States decide when to attack.
- Let components perform the work.

---

# Current Limitations

- `AttackDefinition.animation_name` is not used yet.
- `AttackData.direction` comes from `Actor.facing_direction` at attack start and does not update during the attack.
- There is no hit cooldown beyond the per-activation `hit_targets` set.
- There is no block, parry or hit-stop system.
- There is no damage type or resistance model.
- The player has no dash state, although `DASH` exists as an attack type.
- `PlayerJumpAttackState` is incomplete.

---

# Anti-Patterns

Avoid:

- applying damage inside `WeaponComponent` or `HitboxComponent`;
- modifying health outside `HealthComponent`;
- storing runtime state inside Resources;
- coupling combat logic to specific Actor subclasses;
- mixing gameplay calculations with animation timing.

---

# Related Documents

- [Actor](actor.md)
- [Components](components.md)
- [State Machine](state-machine.md)
- [Resources](resources.md)
- [Resources Catalog](resources-catalog.md)
