# Editor Configuration

## 1. Purpose

Define how Echo World Editor stores and accesses editor-specific settings.

Settings control authoring interaction and presentation. They must not silently change runtime room data or game configuration.

## 2. Configuration ownership

The editor should have one clear source for each setting.

In particular, the project already has world-level configuration (including the world cell size). Before introducing an editor override, inspect the existing `WorldSettings` and related code.

Preferred rule:

- If a value is a world/domain invariant, read it from the existing WorldSettings.
- If a value is an editor preference, store it in Editor settings.
- If an editor override is truly required, define explicit precedence and validation.

Do not maintain two unrelated values for the same cell size.

## 3. Initial settings

| Setting | Initial default | Kind |
|---|---:|---|
| Grid visible | true | Editor preference |
| Snap to grid | true | Editor preference |
| Brush preview visible | true | Editor preference |
| Marker preview visible | true | Editor preference |
| Grid cell size | Read from WorldSettings (currently 32 × 32) | Domain configuration |
| Grid appearance | Project/editor default | Editor preference |

Additional settings should be added only when a real workflow needs them.

## 4. Resource model

A `WorldEditorSettings` Resource is a possible representation for typed settings.

Before implementing it, decide whether the resource is:

- A project-level resource committed to version control; or
- A user/editor preference stored outside shared project content.

These have different collaboration semantics. Team-wide authoring rules should be shared; personal visual preferences generally should not be forced on every contributor.

Avoid creating a settings Resource solely to wrap a few values if Godot editor settings or an existing project configuration is a better fit.

## 5. Validation

Settings should be validated at load or update time.

Examples:

- Cell dimensions must be positive.
- Grid display and snapping must not assume square cells unless the project contract guarantees that.
- Missing settings should fall back to safe defaults.
- Invalid values should produce a clear warning and safe fallback.

## 6. Runtime isolation

Changing editor preferences must not:

- Move existing brushes.
- Resize rooms.
- Rewrite semantic data.
- Change collision geometry.
- Change TileSet definitions.
- Modify baked runtime artifacts.

Changing the authoritative world cell size is a project-level migration/configuration decision, not an ordinary visual editor preference.

## 7. Acceptance criteria

- Each setting has a documented owner and default.
- There is no accidental duplicate source of truth for cell size.
- Settings can be read by editor tools through one stable access point.
- Missing or invalid settings fail safely.
- Editor preferences do not mutate runtime content.
