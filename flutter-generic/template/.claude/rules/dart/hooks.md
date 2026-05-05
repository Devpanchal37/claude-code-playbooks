---
paths:
  - "**/*.dart"
---
# Dart/Flutter Hooks

> This file extends [common/hooks.md](../common/hooks.md) with Dart/Flutter specific content.

## Recommended PostToolUse Hooks

Run these automatically after Dart files are written or edited:

### Format on Write

```json
{
  "type": "PostToolUse",
  "matcher": "Write|Edit",
  "command": "dart format ."
}
```

### Analyze on Write

```json
{
  "type": "PostToolUse",
  "matcher": "Write|Edit",
  "command": "flutter analyze --no-fatal-infos"
}
```

### Auto-fix Lints

```json
{
  "type": "PostToolUse",
  "matcher": "Write",
  "command": "dart fix --apply"
}
```

## Stop Hook: Verify Tests Pass

Run tests when session ends to catch regressions:

```json
{
  "type": "Stop",
  "command": "flutter test"
}
```

## hooks.json Example

See `hooks/hooks.json` in this starter kit for a ready-to-use configuration.

## Notes

- `dart format` enforces the official Dart style (no configuration needed)
- `flutter analyze` catches null-safety issues, unused imports, and lint violations
- Run `dart fix --apply` to auto-resolve fixable warnings
- For large projects, scope analyze to changed files: `dart analyze lib/features/auth/`
