## 2026-11-14

- Marker and connection point pipeline fully implemented:
  - `room-data.md`: version 2 schema with `room_bounds`, `geometry_bounds`, `markers`, `connections`; v1 compatibility documented
  - `connection-points.md`: authoring with `ConnectionPointBrush`, baking with `BakeConnectionsStep`, validation with three new validators
  - `bake-pipeline.md`: 10 steps including `bake_markers` and `bake_connections`; 7 validators including the three new ones
  - `world-authoring.md`: both `MarkerBrush` and `ConnectionPointBrush` listed as implemented
  - `semantic-tiles.md`: marker layer uses `MarkerData` and `MarkerType.Value`
  - `resources-catalog.md`: added `MarkerData`, `MarkerType`, `ConnectionSide`, `RoomBounds`, `GeometryBounds` entries
  - `README.md`: status updated
  - `CHANGELOG.md`: this entry
  - `implementation plan`: status changed from `Proposal` to `Implemented`
- Specified a planned `@tool RoomAuthoring` root that owns `room_bounds: Rect2i` in grid cells as the only logical room-size source.
- Separated the planned `RoomData.room_bounds` (logical playable rectangle) from `RoomData.geometry_bounds` (platform-plus-wall extent); the legacy `bounds` field is planned to keep geometry semantics through read-only version 1 loading.
- Defined the marker placement point as the lower-edge midpoint of its top-left cell at `(16, 32)` for a 32px tile.
- Required explicit, room-local, unique connection IDs with no bake-time generation.
- Required disabled brushes to remain collected but be skipped by every bake and validation consumer, with the spatial filter owned by the `BakeProcessor` implementations.
- Updated `docs/world/world-authoring.md`, `docs/world/room-architecture.md`, `docs/world/room-data.md`, `docs/world/connection-points.md` and `docs/world/semantic-tiles.md` with the planned contracts and current limitations.

## 2026-11-07

- Added the project-local coverage runner under `test/tools/coverage/` with JSON, LCOV, text and HTML reports.
- Recorded the reproducible post-Phase 1 baseline: 71.5% measured across all source files, 75.6% target scope.
- Documented the coverage command, scope, outputs and gate policy; Phase 0 is complete.
- Added coverage regression gate support (informational by default).

## 2026-11-06

- Refreshed the documentation index and project status.
- Aligned the architecture overview, actor, components, state machine, combat, AI and glossary documents with the current implementation.
- Documented current prototype limitations explicitly instead of describing planned behaviour as complete.
- Updated the project structure and resource catalogs.
- Reworked the world documentation: overview, room architecture, room data, semantic tiles, authoring and bake pipeline.
- Added `docs/world/themes.md` covering theme assets, the theme build pipeline and theme application.
- Updated connection-point and world-generation documentation to reflect implemented data types versus planned systems.
- Fixed stale cross-document links and aligned ADR terminology with the baked `ConnectionData` type.

## 2026-07-17

- Added documentation structure.
- Added Architecture Overview.
- Started World Authoring documentation.
