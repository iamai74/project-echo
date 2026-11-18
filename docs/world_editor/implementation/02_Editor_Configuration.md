# Implementation Plan 02 — Editor Configuration

## 1. Goal

Introduce a clear, reliable source for Echo World Editor settings and make those settings available to editor components.

At the end of this plan:

- Editor tools can read settings through one access point.
- Editor preferences have safe defaults.
- The grid uses the project's authoritative world cell size.
- Editor preferences are persisted using an intentional storage strategy.
- Changing preferences does not mutate room/runtime data.

## 2. Scope

### In scope

- Inspect existing WorldSettings and project configuration.
- Define ownership of each initial setting.
- Implement settings access.
- Persist editor-only preferences.
- Validate values and provide fallbacks.
- Connect the Dock to a minimal settings presentation if appropriate.

### Out of scope

- Full settings panel design.
- Per-tool advanced configuration.
- Runtime/gameplay settings.
- Changing the project's world cell size.
- Grid drawing and viewport snapping implementation (these belong to the relevant tool/grid milestones).

## 3. Pre-implementation inspection

Before implementation:

1. Locate the existing `WorldSettings` resource and its cell-size property.
2. Identify how it is loaded or accessed by the project.
3. Check whether Godot EditorSettings, project settings, or a project Resource is already used for editor configuration.
4. Decide which settings should be shared in version control and which are personal editor preferences.

Do not create a second cell-size source without an explicit migration/override design.

## 4. Initial setting ownership

| Setting | Owner | Initial behavior |
|---|---|---|
| Cell size | Existing WorldSettings | Read-only source for editor grid |
| Grid visible | Editor preference | Default true |
| Snap to grid | Editor preference | Default true |
| Brush preview visible | Editor preference | Default true |
| Marker preview visible | Editor preference | Default true |

The storage mechanism must reflect collaboration needs:

- Use project configuration/resources for shared authoring rules.
- Use editor-local settings for personal display preferences.
- Do not commit personal preferences unintentionally.

## 5. Steps

### Step 1 — Define setting ownership

Tasks:

- Document each setting and its source of truth.
- Confirm cell size is read from existing WorldSettings.
- Choose persistence mechanism for personal preferences.
- Record any settings intentionally deferred.

Acceptance:

- No setting has ambiguous ownership.
- There is no duplicate independent cell-size value.

### Step 2 — Implement settings access

Tasks:

- Introduce a small settings provider/service owned by the plugin, or a Resource if that fits the selected persistence strategy.
- Expose typed access to the initial preferences.
- Provide defaults when no saved preference exists.
- Keep the API small; do not build a generic configuration framework.

Acceptance:

- Plugin components obtain settings through one documented access point.
- Missing settings produce valid defaults.

### Step 3 — Read authoritative cell size

Tasks:

- Read cell size from the existing WorldSettings mechanism.
- Handle missing or invalid world settings safely.
- Preserve support for non-square dimensions if the Core model supports them.
- Do not copy the value into a second editable setting.

Acceptance:

- Editor reports the same cell size as WorldSettings.
- Invalid/missing values produce a clear diagnostic and safe behavior.

### Step 4 — Persist editor preferences

Tasks:

- Implement loading and saving using the selected Godot-supported mechanism.
- Keep personal preferences separate from shared project resources unless the project explicitly wants shared defaults.
- Avoid writing settings on every frame or unnecessary UI update.
- Reset to defaults when stored data is missing or invalid.

Acceptance:

- Preferences survive editor restart.
- No unintended project files are modified.
- Defaults are restored safely after invalid/missing configuration.

### Step 5 — Minimal settings presentation

Tasks:

- Expose the initial preferences through a simple Dock section or appropriate editor settings UI.
- Do not build a large custom settings interface.
- Ensure displayed values reflect the actual provider values.
- Defer visual grid implementation to the Grid/Tool milestone.

Acceptance:

- User can inspect/change the initial editor preferences.
- Changes are reflected by the settings provider.
- No room scene or runtime resource is modified.

### Step 6 — Verification

Verify:

1. Default values on first enable.
2. Cell size matches WorldSettings.
3. Change grid visibility and snapping preferences.
4. Restart Godot.
5. Confirm preferences persist.
6. Remove or invalidate stored preference data and confirm fallback.
7. Confirm no authoring scene or runtime artifact changed.

## 6. Testing

Automated tests:

- Default values.
- Validation and fallback behavior.
- Settings provider behavior.
- Cell-size resolution logic, using a testable abstraction where practical.

Manual editor checks:

- Persistence across restart.
- Settings UI interaction.
- No unintended project file changes.

## 7. Definition of Done

- [ ] Ownership of each setting is documented.
- [ ] Existing WorldSettings remains authoritative for cell size.
- [ ] No duplicate cell-size source is introduced.
- [ ] Editor preferences have safe defaults.
- [ ] Preferences persist using the chosen mechanism.
- [ ] Invalid/missing values fail safely.
- [ ] Settings are accessible through one stable API.
- [ ] Editor preference changes do not mutate room/runtime data.
- [ ] Tests and manual verification pass.

## 8. Implementation constraints

- Do not introduce a generic settings framework.
- Do not change WorldSettings schema as part of this task unless inspection proves it necessary and the change is separately justified.
- Do not implement viewport grid rendering or snapping here.
- Do not store personal preferences in shared project resources by default.
