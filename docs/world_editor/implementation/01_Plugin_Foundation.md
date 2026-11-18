# Implementation Plan 01 — Plugin Foundation

## 1. Goal

Create the smallest working Echo World Editor plugin and verify its lifecycle and integration with Godot Editor.

At the end of this plan:

- Godot recognizes the plugin.
- It can be enabled and disabled from Project Settings.
- It adds an `Echo World Editor` Dock.
- It can identify the currently edited authoring scene using an explicit project rule.
- It updates its context when the edited scene changes.
- It does not modify room contents.

## 2. Scope

### In scope

- Plugin directory and configuration.
- Main `EditorPlugin` class.
- Minimal Dock scene/script.
- Editor context for active scene information.
- Enable/disable lifecycle.
- Basic manual verification.

### Out of scope

- Brush Registry.
- Tool System.
- Mouse/viewport drawing.
- Brush creation or manipulation.
- Marker and connection-point UI.
- Custom Inspector.
- Validation UI.
- Bake button or Bake Pipeline execution.
- Full settings UI.

## 3. Pre-implementation repository inspection

Before coding, inspect the current repository and identify:

1. Existing `addons/` conventions.
2. Godot version and plugin API compatibility.
3. Existing authoring room root type and scene conventions.
4. How an authoring scene is distinguished from runtime scenes.
5. Existing `WorldSettings` location and cell-size source.
6. Existing class names and paths for brushes, markers, and connection points.

Do not invent paths or class names. Reuse the actual project conventions.

## 4. Suggested initial structure

```text
addons/
└── echo_world_editor/
    ├── plugin.cfg
    ├── plugin.gd
    ├── core/
    │   └── editor_context.gd
    └── ui/
        ├── editor_dock.tscn
        └── editor_dock.gd
```

Keep the structure minimal. Add files only when required by the implementation.

## 5. Steps

### Step 1 — Create plugin skeleton

Tasks:

- Create `addons/echo_world_editor/`.
- Add `plugin.cfg` with a clear plugin name, description, author/project attribution if appropriate, version, and script entry point.
- Add the main script extending `EditorPlugin`.
- Ensure the entry point path matches the actual file layout.

Acceptance:

- Godot detects the plugin in Project Settings → Plugins.
- No parse or resource loading errors occur.

### Step 2 — Implement lifecycle

Tasks:

- Implement `_enter_tree()` for registering plugin-owned editor elements.
- Implement `_exit_tree()` for unregistering/freeing those elements.
- Keep registration and cleanup symmetrical.
- Avoid persistent scene modifications during plugin activation.

Acceptance:

- Plugin can be enabled and disabled repeatedly.
- No duplicate Dock or stale editor controls remain.
- No errors appear in the editor output.

### Step 3 — Add minimal Dock

Tasks:

- Create a simple Dock titled `Echo World Editor`.
- Initially show a short placeholder message and, optionally, active scene status.
- Add it using the appropriate Godot 4 EditorPlugin Dock API.
- Remove it correctly when the plugin is disabled.

Acceptance:

- Dock appears in the editor when enabled.
- Dock disappears when disabled.
- Editor layout remains usable.
- No authoring scene content is changed.

### Step 4 — Implement Editor Context

Tasks:

- Create a small context object or service that reports the current edited scene/root and whether it satisfies the project's authoring-scene rule.
- Use the appropriate Godot editor API for the edited scene.
- Do not assume the edited scene is always the currently running scene or the filesystem-selected scene.
- Keep context detection separate from UI presentation.
- Define behavior when no scene is open or the active scene is unsupported.

Acceptance:

- Context distinguishes no scene, supported authoring scene, and unsupported scene.
- Dock displays a useful status.
- Detection follows actual project conventions discovered in Step 0.

### Step 5 — Handle scene changes

Tasks:

- Subscribe to the appropriate editor scene-change notification/signal for the project's Godot version.
- Refresh context when the edited scene changes.
- Disconnect signals or release references correctly on plugin shutdown.
- Avoid unnecessary polling.

Acceptance:

- Switching between two authoring scenes updates the context.
- Switching to a non-authoring scene shows unsupported status.
- Closing the current scene clears the context.
- No stale node references are retained.

### Step 6 — Manual integration verification

Run the plugin in Godot Editor and verify:

1. Enable plugin.
2. Confirm Dock appears.
3. Open an authoring room.
4. Confirm context identifies it.
5. Open a different authoring room.
6. Confirm context updates.
7. Open an unrelated scene.
8. Confirm unsupported status.
9. Close scenes.
10. Disable plugin.
11. Re-enable plugin.
12. Restart Godot and repeat basic checks.

## 6. Testing

Automated tests are appropriate for any context classification logic that can be separated from editor APIs.

The following require Godot Editor integration/manual checks:

- Plugin discovery.
- Dock registration/removal.
- Edited-scene notifications.
- Enable/disable and restart behavior.

Record the tested Godot version and exact manual steps.

## 7. Definition of Done

- [ ] Plugin is discoverable and enabled through Godot Project Settings.
- [ ] Plugin lifecycle is clean and symmetrical.
- [ ] Dock appears and disappears correctly.
- [ ] Active edited scene is detected using a documented project rule.
- [ ] Context refreshes on scene changes.
- [ ] Unsupported/no-scene states are handled.
- [ ] No scene content is modified by enabling the plugin.
- [ ] No stale editor references or duplicate controls remain.
- [ ] Manual verification is recorded.
- [ ] Relevant tests pass.

## 8. Implementation constraints

- Do not implement brush registration in this milestone.
- Do not add a generic framework before it is needed.
- Do not move Core classes into the add-on directory.
- Do not duplicate room-authoring or bake logic.
- Use Godot's editor APIs rather than modifying editor internals.
- Preserve existing project naming and folder conventions.
