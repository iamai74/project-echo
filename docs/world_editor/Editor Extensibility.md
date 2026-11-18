# Editor Extensibility

## 1. Purpose

This document defines the intended extension direction for Echo World Editor.

It is a set of requirements and constraints, not a finalized public API specification. Concrete interfaces should be designed when the Brush Registry milestone is implemented and validated against real brush types.

## 2. Extension use cases

The editor should support:

1. Built-in brush types maintained with Project Echo.
2. Project-specific brush types used by this game.
3. Future editor tools that provide new interaction modes.
4. Optional editor-specific presentation for a brush without moving domain logic into the plugin.

Examples of possible future brushes:

- Trap brush.
- Boss spawn brush.
- Biome-specific authoring brush.
- Special interaction marker.

## 3. Brush descriptor

The registry should register a descriptor rather than making the UI depend on hard-coded brush classes.

A descriptor may eventually contain:

- Stable identifier.
- Display name.
- Category.
- Icon or fallback icon.
- Brush class or factory.
- Optional preview provider.
- Optional editor-inspector customization hook.

The descriptor is editor metadata. It must not duplicate brush domain properties such as position, dimensions, marker payload, or semantic traits.

## 4. Registration requirements

The registry should support:

- Registering built-in descriptors during plugin initialization.
- Registering project-local descriptors through a documented entry point.
- Looking up a descriptor by stable identifier.
- Enumerating descriptors by category.
- Detecting duplicate identifiers.
- Reporting invalid registrations clearly.
- Clearing/unregistering registrations when the plugin is disabled, where registration lifetime requires it.

Registration must be deterministic. Do not rely on arbitrary filesystem scan order.

## 5. Creation and editing

The Brush Tool should work with registered brush descriptors, not a hard-coded list of concrete brush types.

The created object must still be a normal authoring object understood by the World Authoring Core.

A project-specific brush should not require changes to:

- The central Dock layout.
- The generic Brush Tool.
- The collector, unless the new domain type genuinely requires Core support.
- Existing built-in brush implementations.

If a new brush requires new bake behavior, that behavior must be implemented in Core, not hidden inside the editor extension.

## 6. Tool extensibility

Tool extensibility is a later capability than brush registration.

The initial release may use a fixed set of built-in tools. The architecture should avoid preventing future tool registration, but a general-purpose Tool Registry is not required until a real custom tool is needed.

## 7. Explicit non-goals

Do not implement initially:

- Dynamic loading of arbitrary external scripts.
- A package manager for brush extensions.
- Version negotiation between independently distributed extensions.
- Remote extension discovery.
- Arbitrary executable callbacks from resource data.
- A complex dependency injection framework.

## 8. Acceptance criteria for the future Registry milestone

- Built-in brushes are registered through the same mechanism as project-local brushes.
- The UI discovers available brushes from the registry.
- Duplicate or invalid registrations produce actionable errors.
- Adding a project-specific brush does not require editing generic Brush Tool UI code.
- Created objects remain compatible with existing Core collection and bake contracts.
