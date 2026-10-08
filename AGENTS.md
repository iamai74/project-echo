# Project Echo — AI Agent Instructions

## 1. Project Overview

Project Echo is a 2D roguelite/metroidvania game built with Godot 4 and GDScript.

The project is currently in an early development/prototype phase, but it is being built around a deliberate long-term architecture.

The project prioritizes:

- clear separation of responsibilities
- composition over inheritance
- data-driven systems
- reusable runtime systems
- deterministic and testable logic
- explicit architectural decisions
- avoiding unnecessary coupling between systems

Do not treat the current prototype code as permission to introduce shortcuts that conflict with the intended architecture.

---

## 2. Source of Truth

Before making architectural or non-trivial implementation changes, inspect the relevant documentation in `docs/`.

Documentation is the project's source of truth for:

- architecture
- system responsibilities
- technical decisions
- project structure
- gameplay systems
- world generation and authoring
- development conventions

Prefer existing documentation and established patterns over inventing a new approach.

If implementation and documentation disagree:

1. determine whether the implementation or documentation is stale;
2. do not silently introduce a third interpretation;
3. update the relevant documentation when the architectural decision changes.

Documentation should describe concepts and responsibilities, not become a copy of the source code.

---

## 3. Architecture Principles

### Composition over inheritance

Prefer composition and small focused components over deep inheritance hierarchies.

When adding functionality to an existing gameplay entity, first consider whether it belongs in:

- a component
- a resource
- a service/system
- a state
- an existing processing pipeline

Do not create a new base class merely to share a small amount of functionality.

### Separation of concerns

Each system should have one clear responsibility.

Do not mix:

- authoring logic with runtime logic
- semantic data with presentation
- configuration with processing
- validation with mutation
- generation with runtime behaviour
- editor-only functionality with runtime functionality

### Data-driven design

When behaviour depends on configuration or content, prefer Godot `Resource`-based data rather than hard-coded values.

Reusable domain concepts should generally have explicit data types instead of unstructured dictionaries.

### Explicit dependencies

Prefer explicit dependencies and clear interfaces.

Avoid hidden global state and implicit communication when a direct dependency or well-defined system interface is appropriate.

---

## 4. Godot / GDScript

The project uses Godot 4 and GDScript.

Follow the project's existing `.editorconfig` and `.gdlintrc` configuration.

General rules:

- Use typed GDScript where practical.
- Prefer explicit return types.
- Prefer explicit variable types for non-trivial code.
- Use `class_name` for reusable domain types where appropriate.
- Keep one primary class per script.
- Keep scripts focused on one responsibility.
- Follow existing naming and directory conventions.
- Do not introduce third-party dependencies without explicit approval.

Do not rewrite working code merely to apply a personal coding style.

Consistency with the existing project is more important than stylistic preference.

---

## 5. Repository Structure

The repository currently contains major areas such as:

- `addons/` — Godot editor addons
- `assets/` — source and game assets
- `autoload/` — autoload/singleton systems
- `docs/` — architecture and technical documentation
- `resources/` — reusable Godot resources/data
- `scenes/` — Godot scenes
- `scripts/` — GDScript implementation

Before creating a new directory or moving existing files, inspect the current project structure and relevant documentation.

Do not introduce a new organizational convention if an existing one already solves the problem.

---

## 6. Runtime vs Authoring

Project Echo distinguishes between editor/world-authoring functionality and runtime functionality.

Do not move editor/baking responsibilities into runtime classes simply because doing so appears convenient.

In particular:

- authoring objects should remain lightweight;
- semantic authoring data should not contain runtime rendering logic;
- baking should produce runtime-ready artifacts;
- runtime systems should not depend on editor-only functionality.

When unsure whether code belongs to authoring, baking, or runtime, inspect the relevant world architecture documentation before implementing it.

---

## 7. World Architecture

The world system is based on semantic data and a bake pipeline.

Important concepts include:

- semantic brushes
- semantic cells/layers
- room data
- room database
- bake pipeline
- bake steps
- bake processors
- validation
- runtime room generation
- themes

These concepts have intentionally separate responsibilities.

Do not collapse them into a single "world generator" or "room builder" abstraction.

### Semantic authoring

Semantic brushes are authoring objects.

They should describe authoring intent rather than perform baking.

A semantic brush should not:

- perform bake operations;
- know about the bake pipeline;
- perform tile-size conversion;
- directly construct runtime TileMap content.

### Baking

Baking converts authoring information into validated, runtime-oriented data/artifacts.

Bake steps should remain composable and focused.

Prefer extending the existing bake pipeline with a new step/processor rather than adding special-case logic to an unrelated step.

### Validation

Validation is separate from mutation/building.

Current validation concepts include:

- `DuplicateCellValidator`
- `SemanticCellValidator`
- `SemanticOverlapValidator`
- `TopologyValidator`

Do not bypass validators by making the builder silently repair invalid semantic data unless that behaviour is explicitly part of the architecture.

---

## 8. Rooms

Rooms have a distinction between:

- semantic/world data
- runtime representation
- visual theme

The runtime room should contain the information required to run the room without requiring the authoring pipeline.

Room construction and theme application are separate responsibilities.

Do not make a biome/theme responsible for changing semantic collision topology.

---

## 9. Themes

Themes are visual/content configuration applied to already-defined room data.

A room should be reusable across different biome themes.

Theme application should primarily determine visual representation from existing room/semantic coordinates.

Do not encode room topology or gameplay semantics into a biome theme.

When working on themes, preserve the separation between:

- room/semantic data
- TileSet
- theme configuration
- effects configuration

Do not combine these into one resource unless the architecture explicitly changes.

---

## 10. Gameplay Architecture

The project uses a component-oriented gameplay architecture.

Important existing concepts include:

- `Actor`
- `HealthComponent`
- `HitboxComponent`
- `HurtboxComponent`
- state machines
- weapon/combat systems

Player and enemy entities should share common actor-level functionality where appropriate.

Avoid creating separate implementations of fundamentally identical gameplay concepts merely because they currently belong to different actors.

At the same time, do not force unrelated behaviour into `Actor` simply because both Player and Enemy inherit from it.

---

## 11. State Machines

State machines are used to isolate mutually exclusive actor behaviours.

When adding behaviour that is naturally state-dependent:

1. determine whether it belongs in an existing state;
2. if not, consider whether a new state is appropriate;
3. keep state transitions explicit;
4. avoid embedding large state machines inside a single actor script.

Do not bypass the established state-machine architecture with ad-hoc boolean combinations unless there is a clear architectural reason.

---

## 12. Resources

Godot `Resource` types are used for reusable configuration and domain data.

Prefer dedicated resource types for important domain concepts.

Avoid large untyped dictionaries when a stable domain model is appropriate.

When introducing a new `Resource`:

- define its responsibility clearly;
- keep it data-oriented;
- avoid putting unrelated behaviour into it;
- document important architectural relationships.

---

## 13. Changes to Architecture

For a non-trivial architectural change:

1. Inspect the relevant documentation.
2. Inspect the existing implementation.
3. Identify the current responsibility boundaries.
4. Propose the smallest coherent change.
5. Update documentation if the architecture changes.
6. Implement the change.
7. Run the relevant validation/tests/checks.

Do not make broad refactors while implementing an unrelated feature.

Avoid "while I'm here" architectural rewrites unless they are required to complete the requested task.

---

## 14. Testing and Validation

When implementing a change, verify the result using the strongest available project checks.

Prefer:

1. unit tests;
2. project-specific validators;
3. Godot parser/editor validation;
4. build/import checks;
5. targeted runtime testing.

Do not consider code complete merely because it looks syntactically correct.

If a required check cannot be executed, report that explicitly rather than claiming the change was verified.

---

## 15. Working With Existing Code

Before modifying a system:

- search for all references to the affected class/function/resource;
- inspect callers and consumers;
- understand how data flows through the system;
- check relevant documentation;
- preserve existing public contracts unless the task explicitly requires changing them.

Avoid speculative abstractions.

Prefer a small change that fits the current architecture over a theoretically more generic solution.

---

## 16. Generated and Baked Artifacts

Do not manually edit generated/baked files when the source data or pipeline is the intended source of truth.

If an artifact is generated by a tool or pipeline:

1. identify its source;
2. modify the source or generator;
3. regenerate the artifact;
4. verify the resulting artifact.

Do not introduce generated files as a second competing source of truth.

---

## 17. Git

Keep changes focused.

A commit should ideally represent one coherent change.

Do not:

- modify unrelated files;
- reformat large parts of the project unnecessarily;
- remove existing functionality without a reason;
- overwrite user changes;
- reset or discard changes you did not create.

Before considering a task complete, inspect the final diff.

The final diff should contain only changes necessary for the requested task.

---

## 18. Documentation Changes

When an implementation changes an architectural decision, update the corresponding documentation.

Follow the project's documentation principles:

- one document, one responsibility;
- architecture before implementation;
- document decisions rather than experiments;
- keep documentation synchronized with the actual architecture.

Do not create documentation for every individual class or function unless there is a specific reason.

---

## 19. Agent Behaviour

The agent should behave as a development assistant working inside an existing codebase, not as an isolated code generator.

Before implementing a non-trivial task:

- understand the existing architecture;
- search before creating;
- reuse existing abstractions where appropriate;
- preserve established conventions;
- avoid unnecessary changes.

When requirements are ambiguous and the ambiguity affects architecture or correctness, ask for clarification rather than guessing.

When the intent is clear and the change is local, proceed without unnecessary questions.

Never claim that a task is completed or verified if the corresponding work/check was not actually performed.

---

## 20. Priority of Rules

When making implementation decisions, use this priority order:

1. Explicit user/task requirements.
2. Established architectural decisions in `docs/`.
3. Local `AGENTS.md` instructions.
4. This root `AGENTS.md`.
5. Existing project conventions.
6. General engineering best practices.

If two architectural rules appear to conflict, do not silently choose one. Investigate the relevant documentation and surface the conflict.

---

## 21. Keep This File Small

This file defines project-wide rules.

Do not turn it into the complete Project Echo architecture documentation.

Detailed system-specific rules belong in:

- `docs/`
- more specific `AGENTS.md` files in relevant directories
- Architecture Decision Records when appropriate

The goal of this file is to give an AI agent enough context to work safely in the repository and know where to look for deeper information.
