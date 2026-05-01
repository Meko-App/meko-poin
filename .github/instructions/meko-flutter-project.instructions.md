---
description: "Use when modifying Flutter/Dart code in the meko_poin project. Covers architecture, SQLite conventions, UI behavior, and safe change practices for this codebase."
name: "Meko Flutter Project Conventions"
applyTo: ["lib/**/*.dart", "test/**/*.dart"]
---
# Meko Flutter Project Conventions

## Architecture and file placement

- Keep the current layered structure:
- `lib/models`: data entities and `fromMap`/`toMap` mapping.
- `lib/services`: repositories and database access logic.
- `lib/views`: UI pages/components/forms/tables.
- `lib/utils`: shared helpers (validators, colors, hashing helpers).
- Do not move features into a new architecture (Provider/BLoC/Riverpod/Clean Architecture) unless explicitly requested.
- Keep changes local to the relevant feature folder (for example, update table components under the same dashboard module).

## Data and database rules

- Keep SQLite table naming consistent with existing schema (`Data_*`).
- Keep database map keys in snake_case to match table columns (for example `user_id`, `created_at`).
- Preserve `DateTime` storage format as ISO-8601 strings via `toIso8601String()` unless a migration requires otherwise.
- When adding or changing schema:
- Update `DatabaseHelper` create/migration logic in one coherent change.
- Preserve backward compatibility for existing local data.
- Never add destructive database reset behavior in app startup code unless explicitly asked.

## Repository and async behavior

- Prefer repository methods for CRUD/query behavior; UI should not issue raw SQL directly.
- Use `await` with explicit `Future<T>` return types and null-safe handling.
- Keep query behavior explicit (`where`, `whereArgs`, `limit`, ordering) and avoid hidden side effects.
- Reuse `DatabaseHelper.instance` patterns already used in this codebase.

## UI and state management conventions

- Follow the current StatefulWidget + `setState` pattern for local screen state.
- Before calling `setState`, `Navigator`, or `ScaffoldMessenger` after async work, guard with `mounted` checks.
- Reuse existing visual system first:
- colors from `CustomColors`.
- Inter typography conventions already used by existing widgets.
- Keep component decomposition style used in dashboard modules (header/sidebar/content/forms/tables).
- Keep existing menu/content flow behavior intact unless the task explicitly asks to redesign UX.

## Validation, messages, and formatting

- Reuse `Validators` and existing validation patterns before introducing new validators.
- Match the language of nearby user-facing strings (project currently mixes Indonesian and English by feature).
- Keep date/number formatting aligned with current usage (`intl`, locale-aware formatting where already used).

## Imports and dependency discipline

- Prefer existing package imports for app modules (for example `package:meko_poin/...`) when touching files that already use them.
- Avoid introducing new dependencies unless necessary; if needed, explain why and update `pubspec.yaml` minimally.
- Do not edit generated/build artifacts or platform dependency outputs unless explicitly requested (for example `build/`, `ios/Pods/`, `macos/Pods/`).

## Quality and safety checks

- Keep changes minimal and focused; avoid broad refactors outside the requested scope.
- Run/consider `flutter analyze` for Dart changes and address relevant issues introduced by the change.
- For behavior changes, add or update tests when practical (unit tests for repositories/utils, widget tests for UI behavior).
- Preserve existing public method signatures unless the task requires API changes.
